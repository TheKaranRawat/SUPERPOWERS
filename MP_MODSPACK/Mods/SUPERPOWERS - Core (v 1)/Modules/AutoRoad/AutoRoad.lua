--------------------------------------------------------------------------------
-- AutoRoadNetwork.lua  (Civ 5 / BNW)
--
-- * After ROAD_TECH, builds roads from the capital to other cities of the same
--   landmass (max MAX_CAPITAL_ROADS roads, kept MIN_ROAD_SEPARATION apart).
-- * A newly founded / captured city is linked to its nearest land-connected city.
-- * After RAILROAD_TECH all managed roads are upgraded to railroads.
-- * Each city is also linked to the nearest foreign city / city-state within
--   FOREIGN_ROAD_DISTANCE tiles (same landmass, not at war, civ met).
-- * Runs once every TURN_INTERVAL turns per player (staggered by player ID).
--
-- Multiplayer safety:
--   - Only GameEvents (synchronised gameplay events) are used, no UI/Events.
--   - No randomness, no active-player checks, no pairs() on decision paths.
--   - All ordering (cities, neighbours, ties) is deterministic.
--   - State is persisted via Modding.OpenSaveData (identical on every machine).
--------------------------------------------------------------------------------

local CONFIG = {
    TURN_INTERVAL                  = 3,      -- run every N turns (per player)
    STAGGER_BY_PLAYER              = true,   -- spread players over different turns

    ROAD_TECH                      = "TECH_THE_WHEEL",  -- "" or false = no requirement
    RAILROAD_TECH                  = "TECH_RAILROAD",   -- "" or false = no requirement

    MAX_CAPITAL_ROADS              = 4,      -- max roads leaving the capital
    MIN_ROAD_SEPARATION            = 4,      -- min hex distance between a new capital-road
                                             -- destination and existing capital roads
    MAX_ROAD_DISTANCE              = 20,     -- max hex distance between the two cities
    MAX_DETOUR                     = 8,      -- path may be at most this much longer than straight line

    NEW_CITY_ROADS_NEED_ROAD_TECH  = true,   -- new/conquered city roads wait for ROAD_TECH
    NEAREST_CANDIDATES             = 3,      -- how many nearest cities to try for a new city
    MAX_PENDING_RETRIES            = 3,      -- failed attempts before a new city is given up on

    -- keeping the road network tidy (no spaghetti)
    ROUTE_REUSE_COST               = 0.15,   -- cost of a tile that already has a road (normal tile = 1+)
    PARALLEL_ROAD_PENALTY          = 4,      -- extra cost for a NEW road tile next to an unrelated road
    MAX_ROUTE_DETOUR               = 20,     -- how far off the straight line existing roads may be followed
    HEURISTIC_WEIGHT               = 0.6,    -- lower = finds road-reusing paths more reliably (slower)
    CAPITAL_ROADS_MAY_SHARE_TILES  = true,   -- capital roads may reuse each other's tiles

    -- performance limits
    MAX_SEARCH_NODES               = 800,    -- A* node budget per path search
    MAX_SEARCHES_PER_PASS          = 3,      -- path searches per player per run
    MAX_NEW_CAPITAL_ROADS_PER_PASS = 1,

    -- roads from each of your cities to the nearest foreign city / city-state
    FOREIGN_ROADS_ENABLED          = true,
    FOREIGN_ROAD_DISTANCE          = 12,     -- max hex distance to the foreign city
    FOREIGN_INCLUDE_MAJORS         = true,   -- link to other civs' cities
    FOREIGN_INCLUDE_CITY_STATES    = true,   -- link to city-state cities
    FOREIGN_REQUIRE_PEACE          = true,   -- no foreign roads to civs you are at war with
    FOREIGN_CANDIDATES             = 2,      -- how many nearest foreign cities to try
    FOREIGN_RETRY_TURNS            = 15,     -- wait this long before retrying a city with no road
    MAX_NEW_FOREIGN_ROADS_PER_PASS = 1,

    REPAIR_PILLAGED_ROADS          = true,   -- re-fix pillaged/missing tiles on managed roads
    ALLOW_NEUTRAL_TERRITORY        = true,   -- may roads cross unowned plots?
    APPLY_TO_HUMANS                = true,
    APPLY_TO_AI                    = true,
    USE_SAVE_DATA                  = true,
    DEBUG                          = false,
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local SAVE_PREFIX = "AUTOROADNET_P"
local ROUTE_NONE_RANK, ROUTE_ROAD_RANK, ROUTE_RAIL_RANK = 0, 1, 2

-- RouteTypes is not a global in Civ 5; route IDs come from GameInfoTypes
local ROUTE_ROAD     = GameInfoTypes["ROUTE_ROAD"] or 0
local ROUTE_RAILROAD = GameInfoTypes["ROUTE_RAILROAD"] or 1

local function Log(...)
    if CONFIG.DEBUG then print("[AutoRoadNetwork]", ...) end
end

local function ResolveTech(name)
    if name == nil or name == false or name == "" then return false end -- no requirement
    local id = GameInfoTypes[name]
    if id == nil then
        print("[AutoRoadNetwork] ERROR: unknown tech '" .. tostring(name) .. "' - feature disabled")
        return nil
    end
    return id
end

-- false = no requirement, nil = invalid (disabled), number = tech ID
local ROAD_TECH_ID = ResolveTech(CONFIG.ROAD_TECH)
local RAIL_TECH_ID = ResolveTech(CONFIG.RAILROAD_TECH)

local function HasTech(player, techID)
    if techID == false then return true end
    if techID == nil then return false end
    local team = Teams[player:GetTeam()]
    return team ~= nil and team:GetTeamTechs():HasTech(techID)
end

local function RouteRank(routeType)
    if routeType == ROUTE_RAILROAD then return ROUTE_RAIL_RANK end
    if routeType == ROUTE_ROAD then return ROUTE_ROAD_RANK end
    return ROUTE_NONE_RANK
end

local mapW = nil
local function MapWidth()
    if mapW == nil then mapW = Map.GetGridSize() end
    return mapW
end

local function KeyOf(x, y) return y * MapWidth() + x end
local function XYOf(key)
    local w = MapWidth()
    local x = key % w
    return x, (key - x) / w
end

local function IsEligible(player)
    if player == nil or not player:IsAlive() then return false end
    if player:IsBarbarian() or player:IsMinorCiv() then return false end
    if player:IsHuman() then return CONFIG.APPLY_TO_HUMANS end
    return CONFIG.APPLY_TO_AI
end

local function Split(s, sep)
    local out = {}
    if s == nil or s == "" then return out end
    local pos = 1
    while true do
        local a, b = string.find(s, sep, pos, true)
        if not a then
            out[#out + 1] = string.sub(s, pos)
            break
        end
        out[#out + 1] = string.sub(s, pos, a - 1)
        pos = b + 1
    end
    return out
end

--------------------------------------------------------------------------------
-- State (per player):  { capID, links = {{cid, kind "C"/"N", rail, path={keys}}},
--                        pending = {{cid, tries}} }
--------------------------------------------------------------------------------
local saveDB = nil
if CONFIG.USE_SAVE_DATA and Modding and Modding.OpenSaveData then
    local ok, db = pcall(Modding.OpenSaveData)
    if ok then saveDB = db end
end

local States = {}

local function LoadState(pid)
    local st = { capID = -1, links = {}, pending = {}, foreignTry = {} }
    if saveDB then
        local ok, raw = pcall(saveDB.GetValue, SAVE_PREFIX .. pid)
        if ok and raw and raw ~= "" then
            local sec = Split(tostring(raw), "#")
            st.capID = tonumber(sec[1]) or -1
            local recs = Split(sec[2] or "", ";")
            for i = 1, #recs do
                local f = Split(recs[i], ":")
                local cid = tonumber(f[1])
                if cid and f[2] then
                    local path = {}
                    local keys = Split(f[4] or "", ",")
                    for k = 1, #keys do
                        local n = tonumber(keys[k])
                        if n then path[#path + 1] = n end
                    end
                    st.links[#st.links + 1] = { cid = cid, kind = f[2], rail = (f[3] == "1"), path = path, other = tonumber(f[5]) or -1 }
                end
            end
            local pend = Split(sec[3] or "", ";")
            for i = 1, #pend do
                local f = Split(pend[i], ":")
                local cid = tonumber(f[1])
                if cid then st.pending[#st.pending + 1] = { cid = cid, tries = tonumber(f[2]) or 0 } end
            end
            local ft = Split(sec[4] or "", ";")
            for i = 1, #ft do
                local f = Split(ft[i], ":")
                local cid, turn = tonumber(f[1]), tonumber(f[2])
                if cid and turn then st.foreignTry[cid] = turn end
            end
        end
    end
    return st
end

local function GetState(pid)
    local st = States[pid]
    if st == nil then
        st = LoadState(pid)
        States[pid] = st
    end
    return st
end

local function SaveState(pid)
    if not saveDB then return end
    local st = States[pid]
    if st == nil then return end
    local parts = {}
    for i = 1, #st.links do
        local l = st.links[i]
        parts[#parts + 1] = l.cid .. ":" .. l.kind .. ":" .. (l.rail and 1 or 0) .. ":" .. table.concat(l.path, ",") .. ":" .. (l.other or -1)
    end
    local pend = {}
    for i = 1, #st.pending do
        pend[#pend + 1] = st.pending[i].cid .. ":" .. st.pending[i].tries
    end
    local ft = {}
    for cid, turn in pairs(st.foreignTry) do ft[#ft + 1] = cid .. ":" .. turn end
    local raw = st.capID .. "#" .. table.concat(parts, ";") .. "#" .. table.concat(pend, ";")
                .. "#" .. table.concat(ft, ";")
    pcall(saveDB.SetValue, SAVE_PREFIX .. pid, raw)
end

-- Drops bookkeeping for lost cities / changed capital. Returns true if changed.
local function ValidateState(player, st)
    local dirty = false
    local capital = player:GetCapitalCity()
    local capID = capital and capital:GetID() or -1
    if st.capID ~= capID then
        for i = #st.links, 1, -1 do
            if st.links[i].kind == "C" then table.remove(st.links, i) end
        end
        st.capID = capID
        dirty = true
    end
    for i = #st.links, 1, -1 do
        if player:GetCityByID(st.links[i].cid) == nil then
            table.remove(st.links, i)
            dirty = true
        end
    end
    for i = #st.pending, 1, -1 do
        if player:GetCityByID(st.pending[i].cid) == nil then
            table.remove(st.pending, i)
            dirty = true
        end
    end
    for cid in pairs(st.foreignTry) do
        if player:GetCityByID(cid) == nil then
            st.foreignTry[cid] = nil
            dirty = true
        end
    end
    return dirty
end

local function FindLink(st, cid, kind)
    for i = 1, #st.links do
        local l = st.links[i]
        if l.cid == cid and l.kind == kind then return i end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Path finding (A*, land only, bounded)
--------------------------------------------------------------------------------
local function StepCost(plot, key, pid, blocked, goalKey, allowedOwner)
    if key == goalKey then return 1 end
    if blocked and blocked[key] then return nil end
    if plot:IsWater() or plot:IsImpassable() then return nil end
    if plot.IsMountain and plot:IsMountain() then return nil end
    if plot.IsNaturalWonder and plot:IsNaturalWonder() then return nil end
    local owner = plot:GetOwner()
    if owner ~= pid and owner ~= allowedOwner then
        if owner >= 0 then return nil end                       -- foreign territory
        if not CONFIG.ALLOW_NEUTRAL_TERRITORY then return nil end
    end
    if plot:IsCity() then return CONFIG.ROUTE_REUSE_COST end                       -- own city (has a route)
    if RouteRank(plot:GetRouteType()) > ROUTE_NONE_RANK then return CONFIG.ROUTE_REUSE_COST end -- reuse roads
    local cost = 1
    if plot:IsHills() then cost = cost + 1 end
    if plot:GetFeatureType() >= 0 then cost = cost + 1 end
    return cost
end

-- returns ordered array of plot keys (start..goal) or nil
local function FindPath(pid, sx, sy, gx, gy, blocked, allowedOwner)
    local startKey, goalKey = KeyOf(sx, sy), KeyOf(gx, gy)
    if startKey == goalKey then return nil end
    local direct = Map.PlotDistance(sx, sy, gx, gy)
    local maxTotal = direct + CONFIG.MAX_DETOUR
    local maxTotalRoute = direct + math.max(CONFIG.MAX_DETOUR, CONFIG.MAX_ROUTE_DETOUR)
    local hw = CONFIG.HEURISTIC_WEIGHT

    -- road tiles (not cities) adjacent to a plot; cached per search
    local roadNeighbors = {}
    local function NearRoads(nk, nx, ny)
        local r = roadNeighbors[nk]
        if r then return r end
        r = {}
        for d = 0, 5 do
            local rp = Map.PlotDirection(nx, ny, d)
            if rp and not rp:IsCity() and RouteRank(rp:GetRouteType()) > ROUTE_NONE_RANK then
                local rx, ry = rp:GetX(), rp:GetY()
                r[#r + 1] = { k = KeyOf(rx, ry), x = rx, y = ry }
            end
        end
        roadNeighbors[nk] = r
        return r
    end

    local hKey, hF, hSeq, n, seq = {}, {}, {}, 0, 0
    local function less(i, j)
        if hF[i] ~= hF[j] then return hF[i] < hF[j] end
        return hSeq[i] < hSeq[j]
    end
    local function swap(i, j)
        hKey[i], hKey[j] = hKey[j], hKey[i]
        hF[i], hF[j] = hF[j], hF[i]
        hSeq[i], hSeq[j] = hSeq[j], hSeq[i]
    end
    local function push(k, f)
        n = n + 1; seq = seq + 1
        hKey[n], hF[n], hSeq[n] = k, f, seq
        local i = n
        while i > 1 do
            local p = math.floor(i / 2)
            if less(i, p) then swap(i, p); i = p else break end
        end
    end
    local function pop()
        local k = hKey[1]
        hKey[1], hF[1], hSeq[1] = hKey[n], hF[n], hSeq[n]
        hKey[n], hF[n], hSeq[n] = nil, nil, nil
        n = n - 1
        local i = 1
        while true do
            local l = i * 2
            local r = l + 1
            local s = i
            if l <= n and less(l, s) then s = l end
            if r <= n and less(r, s) then s = r end
            if s == i then break end
            swap(i, s); i = s
        end
        return k
    end

    local g, from, closed = { [startKey] = 0 }, {}, {}
    push(startKey, direct * hw)
    local expanded = 0

    while n > 0 do
        local cur = pop()
        if not closed[cur] then
            if cur == goalKey then
                local rev, k = {}, cur
                while k do rev[#rev + 1] = k; k = from[k] end
                local path = {}
                for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
                return path
            end
            closed[cur] = true
            expanded = expanded + 1
            if expanded > CONFIG.MAX_SEARCH_NODES then return nil end

            local cx, cy = XYOf(cur)
            for dir = 0, 5 do
                local np = Map.PlotDirection(cx, cy, dir)
                if np then
                    local nx, ny = np:GetX(), np:GetY()
                    local nk = KeyOf(nx, ny)
                    if not closed[nk] then
                        local dToGoal = Map.PlotDistance(nx, ny, gx, gy)
                        local onRoute = RouteRank(np:GetRouteType()) > ROUTE_NONE_RANK
                        local lim = onRoute and maxTotalRoute or maxTotal
                        if Map.PlotDistance(sx, sy, nx, ny) + dToGoal <= lim then
                            local cost = StepCost(np, nk, pid, blocked, goalKey, allowedOwner)
                            if cost then
                                -- a NEW road tile running beside an unrelated road is penalised
                                if not onRoute and nk ~= goalKey and CONFIG.PARALLEL_ROAD_PENALTY > 0 then
                                    local near = NearRoads(nk, nx, ny)
                                    for r = 1, #near do
                                        if near[r].k ~= cur and Map.PlotDistance(near[r].x, near[r].y, cx, cy) > 1 then
                                            cost = cost + CONFIG.PARALLEL_ROAD_PENALTY
                                            break
                                        end
                                    end
                                end
                                local ng = g[cur] + cost
                                if g[nk] == nil or ng < g[nk] then
                                    g[nk] = ng
                                    from[nk] = cur
                                    push(nk, ng + dToGoal * hw)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Building / upgrading
--------------------------------------------------------------------------------
local function IsAtWarWith(player, otherPid)
    local other = Players[otherPid]
    return other ~= nil and Teams[player:GetTeam()]:IsAtWar(other:GetTeam())
end

-- foreign owner whose tiles this link may touch right now (nil if none / at war)
local function LinkAllowedOwner(player, l)
    local o = l.other
    if o == nil or o < 0 then return nil end
    if IsAtWarWith(player, o) then return nil end
    return o
end

local function ApplyRoute(path, routeType, pid, repair, allowedOwner)
    local want = RouteRank(routeType)
    for i = 1, #path do
        local x, y = XYOf(path[i])
        local plot = Map.GetPlot(x, y)
        if plot and not plot:IsCity() then
            local owner = plot:GetOwner()
            if owner == pid or owner < 0 or owner == allowedOwner then
                if RouteRank(plot:GetRouteType()) < want then
                    -- missing or lower-tier route: (re)build it
                    plot:SetRouteType(routeType)
                    if plot.SetRoutePillaged then plot:SetRoutePillaged(false) end
                elseif repair and plot.IsRoutePillaged and plot:IsRoutePillaged() then
                    plot:SetRoutePillaged(false)
                end
            end
        end
    end
end

-- Repairs pillaged tiles and rebuilds missing routes on all managed roads.
local function RepairLinks(player, pid, st)
    if not CONFIG.REPAIR_PILLAGED_ROADS then return end
    for i = 1, #st.links do
        local l = st.links[i]
        local routeType = l.rail and ROUTE_RAILROAD or ROUTE_ROAD
        ApplyRoute(l.path, routeType, pid, true, LinkAllowedOwner(player, l))
    end
end

local function CommitLink(player, pid, st, cid, kind, path, otherOwner)
    local routeType = ROUTE_ROAD
    local isRail = false
    if HasTech(player, RAIL_TECH_ID) then
        routeType = ROUTE_RAILROAD
        isRail = true
    end
    ApplyRoute(path, routeType, pid, false, otherOwner)
    local old = FindLink(st, cid, kind)
    if old then table.remove(st.links, old) end
    st.links[#st.links + 1] = { cid = cid, kind = kind, rail = isRail, path = path, other = otherOwner or -1 }
end

local function UpgradeLinks(player, pid, st)
    if not HasTech(player, RAIL_TECH_ID) then return false end
    local dirty = false
    for i = 1, #st.links do
        local l = st.links[i]
        if not l.rail then
            local allowed = LinkAllowedOwner(player, l)
            if l.other >= 0 and allowed == nil then
                -- at war with the foreign owner: try again later
            else
                ApplyRoute(l.path, ROUTE_RAILROAD, pid, false, allowed)
                l.rail = true
                dirty = true
            end
        end
    end
    return dirty
end

--------------------------------------------------------------------------------
-- Linking logic
--------------------------------------------------------------------------------
local function SortCands(a, b)
    if a.d ~= b.d then return a.d < b.d end
    return a.id < b.id
end

-- returns "linked", "failed" or "nobudget"
local function TryLinkNearest(player, pid, st, city, budget)
    local cx, cy = city:GetX(), city:GetY()
    local myID = city:GetID()
    local area = city:Plot():GetArea()
    local cands = {}
    for other in player:Cities() do
        local oid = other:GetID()
        if oid ~= myID and other:Plot():GetArea() == area then
            local d = Map.PlotDistance(cx, cy, other:GetX(), other:GetY())
            if d <= CONFIG.MAX_ROAD_DISTANCE then
                cands[#cands + 1] = { x = other:GetX(), y = other:GetY(), d = d, id = oid }
            end
        end
    end
    table.sort(cands, SortCands)

    local limit = math.min(#cands, CONFIG.NEAREST_CANDIDATES)
    for i = 1, limit do
        if budget.searches <= 0 then return "nobudget" end
        budget.searches = budget.searches - 1
        local path = FindPath(pid, cx, cy, cands[i].x, cands[i].y, nil)
        if path then
            CommitLink(player, pid, st, myID, "N", path)
            Log("player", pid, "linked city", myID, "to nearest city", cands[i].id)
            return "linked"
        end
    end
    return "failed"
end

local function ProcessPending(player, pid, st, budget, onlyCid)
    local dirty = false
    local i = 1
    while i <= #st.pending do
        local p = st.pending[i]
        if onlyCid == nil or p.cid == onlyCid then
            local city = player:GetCityByID(p.cid)
            if city == nil then
                table.remove(st.pending, i); dirty = true
            else
                if budget.searches <= 0 then break end
                local result = TryLinkNearest(player, pid, st, city, budget)
                if result == "linked" then
                    table.remove(st.pending, i); dirty = true
                elseif result == "nobudget" then
                    break
                else
                    p.tries = p.tries + 1
                    dirty = true
                    if p.tries >= CONFIG.MAX_PENDING_RETRIES then
                        table.remove(st.pending, i)
                    else
                        i = i + 1
                    end
                end
            end
        else
            i = i + 1
        end
    end
    return dirty
end

local function TooCloseToCapitalRoads(st, cx, cy)
    for i = 1, #st.links do
        local l = st.links[i]
        if l.kind == "C" then
            for k = 1, #l.path do
                local x, y = XYOf(l.path[k])
                if Map.PlotDistance(x, y, cx, cy) < CONFIG.MIN_ROAD_SEPARATION then
                    return true
                end
            end
        end
    end
    return false
end

local function BuildCapitalLinks(player, pid, st, budget)
    local capital = player:GetCapitalCity()
    if capital == nil then return false end

    local count = 0
    local blocked = {}
    local capKey = KeyOf(capital:GetX(), capital:GetY())
    for i = 1, #st.links do
        local l = st.links[i]
        if l.kind == "C" then
            count = count + 1
            for k = 1, #l.path do
                if l.path[k] ~= capKey then blocked[l.path[k]] = true end
            end
        end
    end
    if count >= CONFIG.MAX_CAPITAL_ROADS then return false end

    local capX, capY = capital:GetX(), capital:GetY()
    local capID = capital:GetID()
    local area = capital:Plot():GetArea()

    local cands = {}
    for city in player:Cities() do
        local id = city:GetID()
        if id ~= capID and city:Plot():GetArea() == area and not FindLink(st, id, "C") then
            local x, y = city:GetX(), city:GetY()
            local d = Map.PlotDistance(capX, capY, x, y)
            if d <= CONFIG.MAX_ROAD_DISTANCE and not TooCloseToCapitalRoads(st, x, y) then
                cands[#cands + 1] = { x = x, y = y, d = d, id = id }
            end
        end
    end
    table.sort(cands, SortCands)

    local dirty = false
    local built = 0
    for i = 1, #cands do
        if built >= CONFIG.MAX_NEW_CAPITAL_ROADS_PER_PASS or count >= CONFIG.MAX_CAPITAL_ROADS then break end
        if budget.searches <= 0 then break end
        local c = cands[i]
        -- an earlier road built this pass may have made this city too close
        if not TooCloseToCapitalRoads(st, c.x, c.y) then
            budget.searches = budget.searches - 1
            local path = FindPath(pid, capX, capY, c.x, c.y,
                                  (not CONFIG.CAPITAL_ROADS_MAY_SHARE_TILES) and blocked or nil)
            if path then
                CommitLink(player, pid, st, c.id, "C", path)
                for k = 1, #path do
                    if path[k] ~= capKey then blocked[path[k]] = true end
                end
                count = count + 1
                built = built + 1
                dirty = true
                Log("player", pid, "capital road to city", c.id)
            end
        end
    end
    return dirty
end

local function SortForeign(a, b)
    if a.d ~= b.d then return a.d < b.d end
    if a.owner ~= b.owner then return a.owner < b.owner end
    return a.id < b.id
end

-- all foreign cities (majors / city-states) we are allowed to connect to
local function CollectForeignCities(player, pid)
    local list = {}
    local myTeamID = player:GetTeam()
    local myTeam = Teams[myTeamID]
    local maxID = ((GameDefines and GameDefines.MAX_CIV_PLAYERS) or 63) - 1
    for oid = 0, maxID do
        if oid ~= pid then
            local other = Players[oid]
            if other and other:IsAlive() and not other:IsBarbarian() then
                local isMinor = other:IsMinorCiv()
                if (isMinor and CONFIG.FOREIGN_INCLUDE_CITY_STATES)
                   or (not isMinor and CONFIG.FOREIGN_INCLUDE_MAJORS) then
                    local otherTeamID = other:GetTeam()
                    local met = (otherTeamID == myTeamID) or myTeam:IsHasMet(otherTeamID)
                    local war = (otherTeamID ~= myTeamID) and myTeam:IsAtWar(otherTeamID)
                    if met and not (CONFIG.FOREIGN_REQUIRE_PEACE and war) then
                        for city in other:Cities() do
                            list[#list + 1] = {
                                x = city:GetX(), y = city:GetY(), id = city:GetID(),
                                owner = oid, area = city:Plot():GetArea(),
                            }
                        end
                    end
                end
            end
        end
    end
    return list
end

local function BuildForeignLinks(player, pid, st, budget)
    local turn = Game.GetGameTurn()
    local todo = {}
    for city in player:Cities() do
        local id = city:GetID()
        if not FindLink(st, id, "F") then
            local last = st.foreignTry[id]
            if last == nil or turn - last >= CONFIG.FOREIGN_RETRY_TURNS then
                todo[#todo + 1] = city
            end
        end
    end
    if #todo == 0 then return false end

    local foreign = CollectForeignCities(player, pid)
    local dirty = false
    local built = 0

    for i = 1, #todo do
        if built >= CONFIG.MAX_NEW_FOREIGN_ROADS_PER_PASS or budget.searches <= 0 then break end
        local city = todo[i]
        local id = city:GetID()
        local cx, cy = city:GetX(), city:GetY()
        local area = city:Plot():GetArea()

        local cands = {}
        for j = 1, #foreign do
            local f = foreign[j]
            if f.area == area then
                local d = Map.PlotDistance(cx, cy, f.x, f.y)
                if d <= CONFIG.FOREIGN_ROAD_DISTANCE then
                    cands[#cands + 1] = { x = f.x, y = f.y, d = d, id = f.id, owner = f.owner }
                end
            end
        end
        table.sort(cands, SortForeign)

        local linked, exhausted = false, false
        local limit = math.min(#cands, CONFIG.FOREIGN_CANDIDATES)
        for k = 1, limit do
            if budget.searches <= 0 then
                exhausted = true
                break
            end
            budget.searches = budget.searches - 1
            local c = cands[k]
            local path = FindPath(pid, cx, cy, c.x, c.y, nil, c.owner)
            if path then
                CommitLink(player, pid, st, id, "F", path, c.owner)
                Log("player", pid, "city", id, "linked to foreign city", c.id, "of player", c.owner)
                linked = true
                break
            end
        end

        if linked then
            built = built + 1
            dirty = true
        elseif not exhausted then
            st.foreignTry[id] = turn   -- nothing found: cool down before retrying
            dirty = true
        end
    end
    return dirty
end

--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------
local function RunPass(pid)
    local player = Players[pid]
    if not IsEligible(player) or player:GetNumCities() < 1 then return end
    local st = GetState(pid)
    local dirty = ValidateState(player, st)
    local budget = { searches = CONFIG.MAX_SEARCHES_PER_PASS }

    local hasRoad = HasTech(player, ROAD_TECH_ID)
    if hasRoad or not CONFIG.NEW_CITY_ROADS_NEED_ROAD_TECH then
        if ProcessPending(player, pid, st, budget, nil) then dirty = true end
    end
    if hasRoad and player:GetNumCities() >= 2 then
        if BuildCapitalLinks(player, pid, st, budget) then dirty = true end
    end
    if hasRoad and CONFIG.FOREIGN_ROADS_ENABLED then
        local fbudget = { searches = CONFIG.MAX_SEARCHES_PER_PASS }
        if BuildForeignLinks(player, pid, st, fbudget) then dirty = true end
    end
    if UpgradeLinks(player, pid, st) then dirty = true end
    RepairLinks(player, pid, st)

    if dirty then SaveState(pid) end
end

local function OnPlayerDoTurn(pid)
    local turn = Game.GetGameTurn()
    local offset = CONFIG.STAGGER_BY_PLAYER and pid or 0
    if (turn + offset) % CONFIG.TURN_INTERVAL ~= 0 then return end
    RunPass(pid)
end

local function HandleNewCity(pid, x, y)
    local player = Players[pid]
    if not IsEligible(player) then return end
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city == nil or player:GetNumCities() < 2 then return end

    local st = GetState(pid)
    ValidateState(player, st)
    local cid = city:GetID()

    local queued = false
    for i = 1, #st.pending do
        if st.pending[i].cid == cid then queued = true; break end
    end
    if not queued then st.pending[#st.pending + 1] = { cid = cid, tries = 0 } end

    if HasTech(player, ROAD_TECH_ID) or not CONFIG.NEW_CITY_ROADS_NEED_ROAD_TECH then
        local budget = { searches = CONFIG.NEAREST_CANDIDATES }
        ProcessPending(player, pid, st, budget, cid)
    end
    SaveState(pid)
end

local function Safe(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then print("[AutoRoadNetwork] ERROR: " .. tostring(err)) end
    end
end

local function OnCityFounded(pid, x, y)
    HandleNewCity(pid, x, y)
end

-- (oldOwner, isCapital, x, y, newOwner, population, isConquest)
local function OnCityCaptured(oldOwner, isCapital, x, y, newOwner)
    HandleNewCity(newOwner, x, y)
end

GameEvents.PlayerDoTurn.Add(Safe(OnPlayerDoTurn))
GameEvents.PlayerCityFounded.Add(Safe(OnCityFounded))
GameEvents.CityCaptureComplete.Add(Safe(OnCityCaptured))

print("[AutoRoadNetwork] loaded")