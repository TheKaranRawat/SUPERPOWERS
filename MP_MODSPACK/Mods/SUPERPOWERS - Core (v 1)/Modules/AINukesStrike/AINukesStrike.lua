--==========================================================
-- AI Nuclear Retaliation (with fading top-of-screen banner)
--
-- When an AI loses a city to a human (or another AI), it
-- announces a strike, then tries to nuke the captor's cities
-- on the following turn. Banners are drawn by the matching
-- .xml file (same name, same folder).
--
-- Add BOTH files to your mod as InGameUIAddin content, ONCE.
--
-- MULTIPLAYER DESIGN
--  * Game logic only uses synced state (events, units, cities,
--    teams). No randomness, no os/time calls, no pairs() over
--    hash tables, nothing that depends on the local player.
--  * All banner/UI work is local-only and is isolated behind
--    pcall, so a UI problem can never change what the game
--    logic does on one machine but not another.
--  * Pending strikes are saved into the savegame, so a
--    reloaded/rejoined client resumes exactly where the
--    others are instead of diverging.
--
-- PERFORMANCE DESIGN
--  * PlayerDoTurn exits after one table lookup unless that AI
--    has a strike pending.
--  * Unit/city scans only happen on the turn a strike runs.
--  * The per-frame UI update only exists while a banner is
--    visible, and only touches controls while fading/sliding.
--==========================================================
include("IconSupport")

------------------------- CONFIG -------------------------
local MAX_NUKES_PER_STRIKE = 4    -- 1 city lost = 1 nuke ... 4+ cities = 4 nukes
local RETRY_DELAY          = 5    -- turns to wait after an abandoned strike
local MAX_RETRIES          = 10   -- stop retrying after this many
local MAX_PREP_ATTEMPTS    = 3    -- max rebase turns before giving up for now
local REBASE_RANGE_MULT    = 2    -- air rebase range = unit range * this
local AI_VS_AI             = true -- AI also retaliates against AI captors
local AI_ALERT_ONLY_IF_MET = true -- AI-vs-AI banners only for players who have met either civ

-- Banner switches (the strikes themselves are unaffected by these)
local SHOW_PREPARING_BANNER   = false  -- "is preparing a nuclear strike" popup
local SHOW_DETONATION_BANNER  = false  -- "nuclear detonation over ..." popup

-- Banner look (positions are in pixels, measured from the TOP of the screen)
local POSITION_X       = "center" -- horizontal placement: "left", "center" or "right"
local OFFSET_X         = 0        -- extra horizontal nudge in px (+ = right, - = left)
local OFFSET_Y         = 80       -- gap between the top of the screen and the banner
local EDGE_MARGIN      = 24       -- gap to the screen edge when POSITION_X is left/right
local SLIDE_IN         = true     -- also slide down from above the screen while fading in
local FADE_IN_TIME     = 0.8      -- seconds to fade in
local HOLD_TIME        = 4.0      -- seconds fully visible
local FADE_OUT_TIME    = 1.0      -- seconds to fade out
local BACKDROP_ALPHA   = 0.75     -- maximum opacity of the dark backdrop
local BANNER_W         = 420      -- must match the Size in the XML
local BANNER_H         = 410      -- must match the Size in the XML
local DETONATION_DELAY = 1.0      -- seconds to wait after detonation before measuring pop loss
local MAX_QUEUE        = 6        -- queued banners (oldest dropped beyond this)
local CUSTOM_ATLAS     = "AI_NUKE_ICON_ATLAS" -- optional native 256px atlas
local SAVE_KEY         = "AINukesStrike_State_v1"
-----------------------------------------------------------

local PHASE_ALERT = 1   -- waiting to (re)announce
local PHASE_ACT   = 2   -- announced; launch / rebase on this turn

local PlotDistance = Map.PlotDistance
local mathFloor, mathMax, mathMin = math.floor, math.max, math.min

-- Synced game-logic state (saved with the game, see Persist/LoadState)
local captures = {}         -- [aiID] = cities lost (capped)
local plans    = {}         -- [aiID] = { phase, turn, target, remaining, preps, retries, cityKey }

-- Local, UI-only state (never read by game logic)
local pendingStrikes = {}   -- launched nukes waiting to detonate
local knownReal, knownRealCount = {}, 0
local HAS_DETONATION_EVENT = (GameEvents.NuclearDetonation ~= nil)
local ANY_BANNERS = SHOW_PREPARING_BANNER or SHOW_DETONATION_BANNER

-- Cache which unit types are nukes (done once at load)
local nukeTypes = {}
for row in GameInfo.Units() do
    if (row.NukeDamageLevel and row.NukeDamageLevel > 0)
       or row.Type == "UNIT_ATOMIC_BOMB"
       or row.Type == "UNIT_NUCLEAR_MISSILE" then
        nukeTypes[row.ID] = true
    end
end

----------------------------------------------------------
-- Persistence (keeps every client's logic state identical
-- across save/load and rejoin). Safe no-op if unavailable.
----------------------------------------------------------
local function Persist()
    pcall(function()
        local db = Modding.OpenSaveData()
        local parts = {}
        for id = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
            local c, p = captures[id], plans[id]
            if c or p then
                parts[#parts + 1] = table.concat({
                    id, c or 0,
                    p and p.phase or 0, p and p.turn or 0, p and p.target or -1,
                    p and p.remaining or 0, p and p.preps or 0, p and p.retries or 0,
                    (p and p.cityKey) or "",
                }, ",")
            end
        end
        db.SetValue(SAVE_KEY, table.concat(parts, ";"))
    end)
end

local function LoadState()
    pcall(function()
        local db = Modding.OpenSaveData()
        local s = db.GetValue(SAVE_KEY)
        if not s or s == "" then return end
        for rec in string.gmatch(s, "[^;]+") do
            local f = {}
            for v in string.gmatch(rec .. ",", "([^,]*),") do f[#f + 1] = v end
            local id = tonumber(f[1])
            if id and id >= 0 then
                local c = tonumber(f[2]) or 0
                if c > 0 then captures[id] = c end
                local phase, target = tonumber(f[3]) or 0, tonumber(f[5]) or -1
                if phase > 0 and target >= 0 then
                    plans[id] = { phase = phase, turn = tonumber(f[4]) or 0, target = target,
                                  remaining = tonumber(f[6]) or 0, preps = tonumber(f[7]) or 0,
                                  retries = tonumber(f[8]) or 0,
                                  cityKey = (f[9] and f[9] ~= "") and f[9] or nil }
                end
            end
        end
    end)
end
LoadState()

----------------------------------------------------------
-- Generic helpers
----------------------------------------------------------
local function CivName(pPlayer)
    return Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription())
end

local function CityName(key, fallback)
    if key then return Locale.ConvertTextKey(key) end
    return fallback
end

-- Civ's own "real population" figure (pop^2.8 * 1000), with a fallback formula
local function RealPop(city)
    local ok, v = pcall(city.GetRealPopulation, city)
    if ok and v then return v end
    return mathFloor(city:GetPopulation() ^ 2.8) * 1000
end

local function FormatNumber(n)
    local s = tostring(mathFloor(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (out:gsub("^,", ""))
end

local function GetNukes(pPlayer)
    local list = {}
    for unit in pPlayer:Units() do
        if nukeTypes[unit:GetUnitType()] then
            list[#list + 1] = unit
        end
    end
    return list
end

-- Lightweight city list: only what the strike logic needs
local function GetCityList(pPlayer, withInfo)
    local list = {}
    for city in pPlayer:Cities() do
        if withInfo then
            list[#list + 1] = { x = city:GetX(), y = city:GetY(),
                                pop = city:GetPopulation(), nameKey = city:GetNameKey() }
        else
            list[#list + 1] = { x = city:GetX(), y = city:GetY() }
        end
    end
    return list
end

----------------------------------------------------------
-- Banner UI (local only; nothing here may affect game logic)
----------------------------------------------------------
local PH_WAIT, PH_IN, PH_HOLD, PH_OUT = 1, 2, 3, 4
local queue, current, uiPhase, uiTimer = {}, nil, nil, 0
local bannerX, restY, startY = 0, 0, 0
local fadeInTime  = mathMax(FADE_IN_TIME, 0.01)
local fadeOutTime = mathMax(FADE_OUT_TIME, 0.01)

-- IconTextureAtlases has no Type column, so it can't be indexed by name: scan it instead
local function AtlasExists(name)
    for row in GameInfo.IconTextureAtlases() do
        if row.Atlas == name then return true end
    end
    return false
end

local function SetupIcon()
    -- Preferred: a native 256px atlas built from the Manhattan Project art
    if AtlasExists(CUSTOM_ATLAS)
       and IconHookup(0, 256, CUSTOM_ATLAS, Controls.NukeIcon) then
        Controls.NukeIcon:SetSizeVal(256, 256)
        return
    end
    -- Fallback: the game's own Manhattan Project icon (largest size is 128), scaled up
    local proj = GameInfo.Projects["PROJECT_MANHATTAN_PROJECT"]
    if proj then
        IconHookup(proj.PortraitIndex, 128, proj.IconAtlas, Controls.NukeIcon)
    end
    Controls.NukeIcon:SetSizeVal(256, 256)
end
if ANY_BANNERS then pcall(SetupIcon) end   -- an icon problem must never stop the script from loading

-- Smoothstep easing: gentle start and gentle finish
local function Ease(t)
    if t <= 0 then return 0 elseif t >= 1 then return 1 end
    return t * t * (3 - 2 * t)
end

-- One place that moves and fades the banner
local function Apply(alpha, y)
    Controls.Backdrop:SetAlpha(alpha * BACKDROP_ALPHA)
    Controls.NukeIcon:SetAlpha(alpha)
    Controls.BannerText:SetAlpha(alpha)
    Controls.Banner:SetOffsetVal(bannerX, y)
end

local function StartItem()
    -- Resolve position now so resolution changes are respected
    local screenW = UIManager:GetScreenSizeVal()
    if POSITION_X == "left" then
        bannerX = EDGE_MARGIN
    elseif POSITION_X == "right" then
        bannerX = screenW - BANNER_W - EDGE_MARGIN
    else
        bannerX = mathFloor((screenW - BANNER_W) / 2)
    end
    bannerX = bannerX + OFFSET_X
    restY   = OFFSET_Y
    startY  = SLIDE_IN and -BANNER_H or restY

    local ok, text = pcall(current.build)
    Controls.BannerText:SetText(ok and text or "A nuclear strike is underway.")
    Apply(0, startY)                 -- start fully transparent, then reveal
    Controls.Banner:SetHide(false)
    uiPhase, uiTimer = PH_IN, 0
end

local function NextItem()
    current = table.remove(queue, 1)
    if not current then
        uiPhase = nil
        Controls.Banner:SetHide(true)
        ContextPtr:ClearUpdate()     -- no per-frame cost while idle
        return
    end
    uiPhase, uiTimer = PH_WAIT, 0
end

local function OnUpdate(dt)
    uiTimer = uiTimer + (dt or 0)
    if uiPhase == PH_WAIT then
        if uiTimer >= (current.delay or 0) then StartItem() end
    elseif uiPhase == PH_IN then
        local t = uiTimer / fadeInTime
        if t >= 1 then
            Apply(1, restY)
            uiPhase, uiTimer = PH_HOLD, 0
        else
            local e = Ease(t)
            Apply(e, startY + (restY - startY) * e)
        end
    elseif uiPhase == PH_HOLD then
        if uiTimer >= HOLD_TIME then uiPhase, uiTimer = PH_OUT, 0 end
    elseif uiPhase == PH_OUT then
        local t = uiTimer / fadeOutTime
        if t >= 1 then
            Controls.Banner:SetHide(true)
            NextItem()
        else
            Apply(1 - Ease(t), restY)
        end
    end
end

-- Drop everything on screen/queued (local player change, or a UI error)
local function ClearBanners()
    queue, current = {}, nil
    if uiPhase then
        uiPhase = nil
        Controls.Banner:SetHide(true)
        ContextPtr:ClearUpdate()
    end
end

-- If the banner code ever errors, clear it instead of erroring every frame
local function SafeUpdate(dt)
    if not pcall(OnUpdate, dt) then ClearBanners() end
end

local function Enqueue(item)
    if #queue >= MAX_QUEUE then table.remove(queue, 1) end
    queue[#queue + 1] = item
    if not uiPhase then
        NextItem()
        ContextPtr:SetUpdate(SafeUpdate)
    end
end

-- Each client only shows banners to its own local player
local function IsVisibleToLocal(iAI, iTarget)
    local iActive = Game.GetActivePlayer()
    local pActive = Players[iActive]
    if not pActive or not pActive:IsAlive() then return false end
    if iActive == iAI or iActive == iTarget then return true end
    if Players[iTarget]:IsHuman() or not AI_ALERT_ONLY_IF_MET then return true end
    local team = Teams[pActive:GetTeam()]
    return team:IsHasMet(Players[iAI]:GetTeam()) or team:IsHasMet(Players[iTarget]:GetTeam())
end

local function QueuePreparing(iAI, plan)
    if not SHOW_PREPARING_BANNER then return end
    if not IsVisibleToLocal(iAI, plan.target) then return end
    local text = CivName(Players[iAI]) .. " is preparing a nuclear strike after "
                 .. CivName(Players[plan.target]) .. " captured "
                 .. CityName(plan.cityKey, "one of its cities") .. "."
    Enqueue({ delay = 0, build = function() return text end })
end

local function QueueDetonation(rec)
    if not SHOW_DETONATION_BANNER then return end
    if not IsVisibleToLocal(rec.iAI, rec.target) then return end
    Enqueue({
        delay = DETONATION_DELAY,
        build = function()
            -- Measured when the banner is about to show, after the blast has been applied
            local turn = Game.GetGameTurn()
            local key  = rec.x .. "," .. rec.y
            local prev = knownReal[key]
            local before = (prev and prev.turn == turn) and prev.real or rec.realBefore
            local plot = Map.GetPlot(rec.x, rec.y)
            local city = plot and plot:GetPlotCity()
            local after = city and RealPop(city) or 0

            if knownRealCount > 32 then knownReal, knownRealCount = {}, 0 end  -- bounded memory
            if not knownReal[key] then knownRealCount = knownRealCount + 1 end
            knownReal[key] = { turn = turn, real = after }

            return "Nuclear detonation over " .. CityName(rec.toKey, "a city") .. "![NEWLINE]"
                .. "Launched by " .. CivName(Players[rec.iAI]) .. " from "
                .. CityName(rec.fromKey, "a naval unit") .. "[NEWLINE]"
                .. FormatNumber(mathMax(before - after, 0)) .. " lives lost"
        end,
    })
end

-- Game logic calls banners ONLY through this wrapper, so a UI error (or any
-- difference in what each player can see) can never alter the game logic.
local function SafeUI(fn, a, b)
    local ok, err = pcall(fn, a, b)
    if not ok then print("AI Nuclear Retaliation (banner): " .. tostring(err)) end
end

----------------------------------------------------------
-- Strike execution (synced game logic)
----------------------------------------------------------
local function PrunePending(turn)
    for i = #pendingStrikes, 1, -1 do
        if turn - pendingStrikes[i].turn > 5 then table.remove(pendingStrikes, i) end
    end
end

local function ScheduleRetry(iAI, plan, turn)
    plan.retries = plan.retries + 1
    if plan.retries > MAX_RETRIES then
        plans[iAI] = nil
        return
    end
    plan.phase = PHASE_ALERT
    plan.turn  = turn + RETRY_DELAY
    plan.preps = 0
end

local function ExecutePlan(iAI, plan, turn)
    local pAI     = Players[iAI]
    local pTarget = Players[plan.target]

    if not pAI or not pTarget or not pAI:IsAlive() or pAI:GetNumCities() == 0
       or not pTarget:IsAlive()
       or not Teams[pAI:GetTeam()]:IsAtWar(pTarget:GetTeam()) then
        plans[iAI] = nil
        return
    end

    local nukes = GetNukes(pAI)
    if #nukes == 0 then plans[iAI] = nil return end

    local targets = GetCityList(pTarget, true)
    if #targets == 0 then plans[iAI] = nil return end

    PrunePending(turn)

    local remaining = plan.remaining
    local launched  = 0
    local used      = {}
    local assigned  = {}

    -- Pass 1: launch every nuke that already has a target in range
    for n = 1, #nukes do
        if launched >= remaining then break end
        local unit  = nukes[n]
        local range = unit:Range()
        local ux, uy = unit:GetX(), unit:GetY()

        -- Prefer cities with fewer nukes assigned, then higher population
        local best, bestCount, bestPop
        for t = 1, #targets do
            local tc = targets[t]
            if PlotDistance(ux, uy, tc.x, tc.y) <= range then
                local c = assigned[t] or 0
                if not best or c < bestCount or (c == bestCount and tc.pop > bestPop) then
                    best, bestCount, bestPop = t, c, tc.pop
                end
            end
        end

        if best then
            used[n] = true
            local tc = targets[best]

            -- Note the launch city BEFORE the missile leaves
            local fromPlot = Map.GetPlot(ux, uy)
            local fromCity = fromPlot and fromPlot:GetPlotCity()
            local fromKey  = fromCity and fromCity:GetNameKey() or nil
            local realBefore = 0
            if SHOW_DETONATION_BANNER then
                local toPlot = Map.GetPlot(tc.x, tc.y)
                local toCity = toPlot and toPlot:GetPlotCity()
                realBefore = toCity and RealPop(toCity) or 0
            end

            local ok = pcall(unit.PushMission, unit, MissionTypes.MISSION_NUKE, tc.x, tc.y, 0, 0, 1)
            if ok then
                launched = launched + 1
                assigned[best] = (assigned[best] or 0) + 1

                if SHOW_DETONATION_BANNER then
                    local rec = { iAI = iAI, target = plan.target, x = tc.x, y = tc.y,
                                  fromKey = fromKey, toKey = tc.nameKey,
                                  realBefore = realBefore, turn = turn }
                    if HAS_DETONATION_EVENT then
                        pendingStrikes[#pendingStrikes + 1] = rec
                    else
                        SafeUI(QueueDetonation, rec)   -- no detonation event: report on launch
                    end
                end
            end
        end
    end

    -- Pass 2: rebase out-of-range nukes to an AI city that can reach a target
    local need  = remaining - launched
    local moved = 0
    if need > 0 then
        local myCities = GetCityList(pAI, false)
        for n = 1, #nukes do
            if moved >= need then break end
            if not used[n] then
                local unit  = nukes[n]
                local range = unit:Range()
                local rebaseRange = range * REBASE_RANGE_MULT
                local ux, uy = unit:GetX(), unit:GetY()

                local bestBase, bestDist
                for m = 1, #myCities do
                    local mc = myCities[m]
                    if (mc.x ~= ux or mc.y ~= uy)
                       and PlotDistance(ux, uy, mc.x, mc.y) <= rebaseRange then
                        for t = 1, #targets do
                            local d = PlotDistance(mc.x, mc.y, targets[t].x, targets[t].y)
                            if d <= range and (not bestDist or d < bestDist) then
                                bestBase, bestDist = mc, d
                            end
                        end
                    end
                end

                if bestBase then
                    local ok = pcall(unit.PushMission, unit, MissionTypes.MISSION_REBASE,
                                     bestBase.x, bestBase.y)
                    if ok then moved = moved + 1 end
                end
            end
        end
    end

    plan.remaining = remaining - launched
    if plan.remaining <= 0 then
        plans[iAI] = nil
    elseif moved > 0 and plan.preps < MAX_PREP_ATTEMPTS then
        plan.preps = plan.preps + 1
        plan.phase = PHASE_ACT
        plan.turn  = turn + 1
    else
        ScheduleRetry(iAI, plan, turn)
    end
end

----------------------------------------------------------
-- Event handlers
----------------------------------------------------------
local function OnCityCaptured(iOldOwner, bIsCapital, iX, iY, iNewOwner, iPop, bConquest)
    if bConquest == false then return end
    if iOldOwner == iNewOwner then return end

    local pOld = Players[iOldOwner]
    local pNew = Players[iNewOwner]
    if not pOld or not pNew then return end

    if pOld:IsHuman() or pOld:IsMinorCiv() or pOld:IsBarbarian() then return end
    if pNew:IsMinorCiv() or pNew:IsBarbarian() then return end
    if not pNew:IsHuman() and not AI_VS_AI then return end

    local plot = Map.GetPlot(iX, iY)
    local city = plot and plot:GetPlotCity()
    local cityKey = city and city:GetNameKey() or nil

    local count = mathMin((captures[iOldOwner] or 0) + 1, MAX_NUKES_PER_STRIKE)
    captures[iOldOwner] = count

    local plan = plans[iOldOwner]
    if plan then
        plan.remaining = count
        plan.target    = iNewOwner
        plan.cityKey   = cityKey
    else
        plan = { phase = PHASE_ACT, turn = Game.GetGameTurn() + 1, target = iNewOwner,
                 remaining = count, preps = 0, retries = 0, cityKey = cityKey }
        plans[iOldOwner] = plan
        SafeUI(QueuePreparing, iOldOwner, plan)
    end
    Persist()
end

local function OnPlayerDoTurn(iPlayer)
    local plan = plans[iPlayer]
    if not plan then return end                -- fast exit for almost every call

    local turn = Game.GetGameTurn()
    if turn < plan.turn then return end

    if plan.phase == PHASE_ALERT then
        SafeUI(QueuePreparing, iPlayer, plan)  -- retry: announce again, act next turn
        plan.phase = PHASE_ACT
        plan.turn  = turn + 1
    else
        ExecutePlan(iPlayer, plan, turn)
    end
    Persist()
end

local function OnNuclearDetonation(iPlayer, iX, iY)
    for i = 1, #pendingStrikes do
        local rec = pendingStrikes[i]
        if rec.iAI == iPlayer and rec.x == iX and rec.y == iY then
            table.remove(pendingStrikes, i)
            SafeUI(QueueDetonation, rec)
            return
        end
    end
end

GameEvents.CityCaptureComplete.Add(OnCityCaptured)
GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)
if HAS_DETONATION_EVENT and SHOW_DETONATION_BANNER then
    GameEvents.NuclearDetonation.Add(OnNuclearDetonation)
end
if ANY_BANNERS and Events.GameplaySetActivePlayer then
    Events.GameplaySetActivePlayer.Add(ClearBanners)
end