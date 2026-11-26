-- GroupMove.lua : Ctrl+drag or Alt+drag box-select, right-click group dispatch,
-- hex highlight, alert-on-arrival and optional control groups.
--
-- MULTIPLAYER SAFETY
--  * UI side only. The script never sets unit positions or any game state.
--  * Every order (move, alert) goes through the engine's networked order
--    calls, one unit at a time, exactly like a manual order, so every client
--    receives the same commands.
--  * Orders are only issued while it is the player's turn, and only for the
--    active player's own units.
--  * Reads of other players' information are limited to what the player can
--    already see (destination tiles are only chosen from visible tiles).
--  * State is kept per player, so hotseat turn changes can't mix up units.
--
-- PERFORMANCE
--  * No polling. Everything runs from input, selection or unit events.
--  * The per-frame callback is only installed while there is deferred work
--    (a highlight redraw or a trip check) and removes itself afterward.
--  * Refreshes are coalesced to at most one per frame, and the highlight is
--    only redrawn when the set of occupied tiles actually changed.
--  * Mouse moves cost one comparison unless a box is being dragged.
--  * Unit events from other players' turns are ignored (they fire constantly
--    and none of our units can change then).
--  * Trip checks are throttled to one per CHECK_INTERVAL seconds, and a
--    throttled check stays pending so nothing is missed.
--  * Plain unit-movement events only refresh the highlight, never the preview.
--
-- NETWORK MULTIPLAYER
--  * The wait for an order to register is longer (ORDER_WAIT_TICKS_MP) since
--    orders take a network round trip. A late order is never sent twice: the
--    trip check re-sends at most once per unit per turn.
--  * Only tiles the player has seen (visible, or revealed for the last-resort
--    fallback and the preview) are ever examined when picking destinations.
--
-- ORDER PACING
--  * Orders are sent one unit per frame, and the next unit is only ordered once the
--    previous one shows that its order registered (otherwise it is re-sent).
--
-- MULTI-TURN TRIPS
--  * A dispatch creates a "trip" (state.moveTrack) that is independent of the
--    selection. It survives turn changes and survives you selecting other units.
--  * On every check, a trip unit that is not at its destination and has no
--    running mission (the engine dropped its order, e.g. because a friendly
--    unit blocked the tile it wanted to end its turn on) gets its move order
--    re-sent, at most once per turn. If it keeps failing it is sent to a free
--    tile near the original target, and after MAX_RETRIES turns without any
--    progress it is given up on.
--  * Left-clicking a unit that is part of a trip lights up its destination hex.
--  * Right-clicking with such a unit selected detaches it from the trip: it
--    heads to the clicked hex on its own, an alert says so, and the rest of
--    the group carries on to the original objective.
--  * When every trip unit has arrived (or been given up), the arrived military
--    units are put on alert and the trip ends.
--
-- The script keeps its own "logical" group (state.selected). The engine may
-- only be able to highlight one unit at a time, so the group is NOT read back
-- from the engine's selection; it is set by box select / recall and cleared
-- when YOU pick something else (engine-driven selection changes are ignored).

-- Speculative: some builds define Vector2 in this helper. If it isn't there,
-- the call fails harmlessly and the script uses fallbacks.
pcall(include, "MathHelpers")

----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local MAX_GROUPS       = 9
local KEY_1            = 49    -- virtual-key code for '1'
local DRAG_THRESHOLD   = 6     -- pixels before a press becomes a drag
local MILITARY_ONLY    = true  -- box-select skips workers, settlers, etc.
local REQUIRE_BOTH     = false -- false: Ctrl OR Alt alone starts a box select
                               -- true: both must be held together
local CLICK_CANCELS    = true  -- a plain left click deselects a multi-unit group
local ALERT_AFTER_MOVE = true  -- put units on alert when the group finishes moving
local SPREAD_UNITS     = true  -- units from different tiles get different destinations
local SPREAD_RADIUS    = 4     -- how far from the clicked hex to look for free tiles
local MAX_TRACK_TURNS  = 30    -- stop watching a dispatched group after this many turns
local MAX_RETRIES      = 4     -- turns a unit may stay stuck (no progress) before it is given up on
local ORDER_WAIT_TICKS  = 20    -- frames to wait for proof that an order registered before moving on
local ORDER_WAIT_TICKS_MP = 90  -- same, in network multiplayer, where an order takes a network round trip
local CHECK_INTERVAL   = 0.25   -- seconds between trip checks (needs os.clock; otherwise one per frame)
local MAX_SEND_ATTEMPTS = 1    -- times one order is sent in a row (1 = never repeat a failed order;
                               -- the once-per-turn check on later turns still tries again)
local RELAX_RADIUS     = 2     -- if no normal free tile works, any tile this close to the target is allowed
local KEEP_GROUP_SELECTED  = false -- true: re-select the whole group in the engine after ordering it.
                                   -- false: leave the engine selection empty (the group stays selected
                                   -- inside the script and is still highlighted). This avoids the game's
                                   -- auto-cycle jumping between units that already have orders.
local RIGHT_DRAG_DISPATCHES = true  -- true: hold right button, move to a hex, release = group goes to the
                                    -- hex you release on (like the game's hold-to-preview move).
                                    -- false: a right-drag longer than DRAG_THRESHOLD is passed to the engine
local DESELECT_AFTER_ORDER = true -- true: the group is deselected (highlight off, nothing selected in the
                                  -- game) as soon as you send it; the units keep travelling on their own
local PREVIEW          = true  -- show where the group would end up under the mouse (needs HIGHLIGHT)
local PREVIEW_MODE     = "always"  -- "always": whenever a group is selected
                                   -- "hold": only while the right mouse button is held
local PREVIEW_COLOR    = { 0.5, 0.8, 1.0, 1.0 }   -- r, g, b, a (0 to 1)
local HIGHLIGHT        = true  -- light up the hex under every unit in the group
local HL_COLOR         = { 1.0, 0.9, 0.5, 1.0 }   -- r, g, b, a (0 to 1)
local HL_STYLE         = nil   -- optional highlight style name passed to the game
local SHOW_DEST        = true  -- selecting a single unit that is on a group trip lights its destination hex
                               -- (needs HIGHLIGHT)
local DEST_COLOR       = { 0.4, 1.0, 0.4, 1.0 }   -- r, g, b, a (0 to 1)
local DEBUG            = true  -- writes key events to Lua.log
local DEBUG_VERBOSE    = false -- also logs routine events (can be noisy)

local function Log(msg)
    if DEBUG then print("GroupMove: " .. msg) end
end

-- On-screen alert (the same message line the game uses for gameplay alerts).
-- Falls back to the log if the event isn't available in this build.
local function Alert(msg)
    local shown = false
    if Events and Events.GameplayAlertMessage then
        shown = pcall(Events.GameplayAlertMessage, msg)
    end
    if shown then
        Log(msg)
    else
        print("GroupMove: " .. msg)
    end
end

local function UnitDisplayName(unit)
    local ok, name = pcall(function() return Locale.ConvertTextKey(unit:GetNameKey()) end)
    if ok and name and name ~= "" then return name end
    return "Unit " .. unit:GetID()
end

-- Seconds, if the game exposes a clock. Without one, trip checks are simply
-- not throttled (CHECK_GAP is 0).
local function Now()
    if os and os.clock then return os.clock() end
    return 0
end
local CHECK_GAP = (os and os.clock) and CHECK_INTERVAL or 0

-- Frames to wait for an order to register: longer in network multiplayer
local orderWait = nil
local function OrderWait()
    if not orderWait then
        local ok, mp = pcall(function() return Game.IsNetworkMultiPlayer() end)
        orderWait = (ok and mp) and ORDER_WAIT_TICKS_MP or ORDER_WAIT_TICKS
        Log("order wait is " .. orderWait .. " frames" .. ((ok and mp) and " (multiplayer)" or ""))
    end
    return orderWait
end

----------------------------------------------------------------
-- Cached message ids
----------------------------------------------------------------
local MSG_LDOWN = MouseEvents.LButtonDown
local MSG_LUP   = MouseEvents.LButtonUp
local MSG_RDOWN = MouseEvents.RButtonDown
local MSG_RUP   = MouseEvents.RButtonUp
local MSG_MOVE  = MouseEvents.MouseMove
local MSG_KEY   = KeyEvents.KeyDown

----------------------------------------------------------------
-- State (kept per player so hotseat turn changes can't mix up unit IDs)
----------------------------------------------------------------
local state = {}               -- state[playerID] = { groups, selected, moveTrack }

local function GetState(playerID)
    local s = state[playerID]
    if not s then
        s = { groups = {}, selected = {} }
        for n = 1, MAX_GROUPS do s.groups[n] = {} end
        state[playerID] = s
    end
    return s
end

local guard    = false         -- true while WE change the engine's selection
local boxing   = false         -- a modifier-held press is in progress
local dragging = false         -- passed the drag threshold
local startX, startY = 0, 0    -- screen position at mouse-down
local startHexX, startHexY     -- hex under cursor at mouse-down (fallback)

local clickTracking = false    -- plain left press that may become a cancel-click
local clickX, clickY = 0, 0    -- screen position of that press

local rDown = false            -- right button currently held
local rStartX, rStartY = 0, 0  -- screen position at right mouse-down

local userAction = false       -- true for one frame after a left click or key press

local function CountSet(set, limit)
    local count = 0
    for _ in pairs(set) do
        count = count + 1
        if limit and count >= limit then break end
    end
    return count
end

-- True when two or more units are in the logical group
local function HasGroupSelected()
    return CountSet(GetState(Game.GetActivePlayer()).selected, 2) >= 2
end

-- Orders can only be issued on the player's own turn
local function CanIssueOrders(player)
    if player.IsTurnActive and not player:IsTurnActive() then return false end
    return true
end

-- True while the active player can act. Other players' turns fire unit events
-- constantly, but none of our own units can change then, so event handlers
-- use this to skip all work.
local function IsMyTurn()
    return CanIssueOrders(Players[Game.GetActivePlayer()])
end

----------------------------------------------------------------
-- Hex highlight (visual only)
----------------------------------------------------------------
-- Draws the game's hex overlay under each grouped unit. If the game's Vector2,
-- Vector4 or ToHexFromGrid are missing, small built-in versions are used.
local hlAvailable = nil         -- nil = untested, true = works, false = off
local litHex = {}               -- litHex[key] = hex position currently lit
local litCount = 0
local hlColor = nil

local function MakeVec2(x, y)
    if Vector2 then return Vector2(x, y) end
    return { x = x, y = y }
end

local function MakeVec4(x, y, z, w)
    if Vector4 then return Vector4(x, y, z, w) end
    return { x = x, y = y, z = z, w = w }
end

-- Plot grid coordinates to the hex coordinates the highlight event expects
local function MakeHex(gx, gy)
    if ToHexFromGrid then return ToHexFromGrid(MakeVec2(gx, gy)) end
    return { x = gx - (gy - (gy % 2)) / 2, y = gy }
end

local function SetHexHighlight(hex, on, color)
    if HL_STYLE then
        Events.SerialEventHexHighlight(hex, on, color, HL_STYLE)
    else
        Events.SerialEventHexHighlight(hex, on, color)
    end
end

local function CheckHighlight()
    if hlAvailable == nil then
        if not HIGHLIGHT then
            hlAvailable = false
        elseif not (Events and Events.SerialEventHexHighlight) then
            hlAvailable = false
            Log("hex highlight unavailable: Events.SerialEventHexHighlight is missing")
        else
            hlAvailable = true
            hlColor = MakeVec4(HL_COLOR[1], HL_COLOR[2], HL_COLOR[3], HL_COLOR[4])
            local substituted = {}
            if not Vector2 then substituted[#substituted + 1] = "Vector2" end
            if not Vector4 then substituted[#substituted + 1] = "Vector4" end
            if not ToHexFromGrid then substituted[#substituted + 1] = "ToHexFromGrid" end
            if #substituted > 0 then
                Log("hex highlight available, using built-in versions of: " .. table.concat(substituted, ", "))
            else
                Log("hex highlight available")
            end
        end
    end
    return hlAvailable
end

-- Redraws the highlight. Unless forced, nothing happens when the set of
-- occupied tiles is unchanged. A forced refresh redraws everything, which
-- also repairs tiles the game may have cleared itself after a selection change.
local function RefreshHighlights(force)
    if not CheckHighlight() then return end

    local pid = Game.GetActivePlayer()
    local s = GetState(pid)

    local want, wantCount = {}, 0
    if CountSet(s.selected, 2) >= 2 then
        local player = Players[pid]
        for id in pairs(s.selected) do
            local unit = player:GetUnitByID(id)
            if unit and not unit:IsDelayedDeath() then
                local ux, uy = unit:GetX(), unit:GetY()
                local key = ux * 1024 + uy
                if not want[key] then
                    want[key] = { ux, uy }
                    wantCount = wantCount + 1
                end
            end
        end
    end

    if not force and wantCount == litCount then
        local same = true
        for key in pairs(want) do
            if not litHex[key] then same = false break end
        end
        if same then return end
    end

    for _, hex in pairs(litHex) do
        SetHexHighlight(hex, false, hlColor)
    end
    litHex, litCount = {}, 0

    for key, xy in pairs(want) do
        local hex = MakeHex(xy[1], xy[2])
        SetHexHighlight(hex, true, hlColor)
        litHex[key] = hex
        litCount = litCount + 1
    end
    if DEBUG_VERBOSE then Log("highlighted " .. litCount .. " tiles") end
end

-- Destination highlight (visual only). When exactly one unit is selected and
-- it belongs to a dispatched trip, its destination hex is lit in DEST_COLOR.
-- Nothing is drawn for a unit that is not on a trip or has already arrived.
local destLit = nil             -- { key = tile key, hex = hex position } while a destination is lit
local destColor = nil

local function ClearDestHighlight()
    if not destLit then return end
    SetHexHighlight(destLit.hex, false, destColor)
    local lit = litHex[destLit.key]
    if lit then SetHexHighlight(lit, true, hlColor) end    -- don't strip a group highlight
    destLit = nil
end

local function RefreshDestHighlight()
    if not SHOW_DEST or not CheckHighlight() then return end
    if not destColor then
        destColor = MakeVec4(DEST_COLOR[1], DEST_COLOR[2], DEST_COLOR[3], DEST_COLOR[4])
    end

    local pid = Game.GetActivePlayer()
    local s = GetState(pid)
    local t = s.moveTrack

    local wantX, wantY
    if t and CountSet(s.selected, 2) == 1 then
        local id = next(s.selected)
        local d = t.dest[id]
        if d and not t.gaveUp[id] then
            local unit = Players[pid]:GetUnitByID(id)
            if unit and not unit:IsDelayedDeath()
               and not (unit:GetX() == d.x and unit:GetY() == d.y) then
                wantX, wantY = d.x, d.y
            end
        end
    end

    if not wantX then
        ClearDestHighlight()
        return
    end

    local key = wantX * 1024 + wantY
    if destLit and destLit.key == key then return end
    ClearDestHighlight()
    local hex = MakeHex(wantX, wantY)
    SetHexHighlight(hex, true, destColor)
    destLit = { key = key, hex = hex }
    if DEBUG_VERBOSE then Log("destination lit at " .. wantX .. "," .. wantY) end
end

----------------------------------------------------------------
-- Tile helpers (used by destination spreading and by trip re-routing)
----------------------------------------------------------------

-- True if the tile has a unit the player can see on it
local function TileHasVisibleUnit(plot, team)
    for i = 0, plot:GetNumUnits() - 1 do
        local u = plot:GetUnit(i)
        if u then
            local hidden = u.IsInvisible and u:IsInvisible(team, false)
            if not hidden then return true end
        end
    end
    return false
end

-- A free tile that any unit could plausibly stand on. Only tiles the player
-- can currently see are considered, so nothing hidden influences the choice.
local function GenericTileOk(plot, team)
    if plot:IsImpassable() or plot:IsMountain() then return false end
    if not plot:IsVisible(team, false) then return false end
    if plot:IsCity() then return false end
    if TileHasVisibleUnit(plot, team) then return false end
    return true
end

local function DomainOk(plot, unit)
    local d = unit:GetDomainType()
    if d == DomainTypes.DOMAIN_SEA then return plot:IsWater() end
    if d == DomainTypes.DOMAIN_LAND then return not plot:IsWater() end
    return false                            -- air etc.: no spreading
end

-- True if the game can find a path for this unit to the tile (read-only
-- check). If the API is missing or fails, the tile is not rejected.
local function CanReach(unit, plot)
    if not unit.GeneratePath then return true end
    local ok, res = pcall(unit.GeneratePath, unit, plot)
    if not ok then return true end
    return res and true or false
end

-- Finds the free tile closest to the unit among the nearest ring around
-- (cx, cy) that has any. `taken` holds tile keys already promised to others.
local function PickFreeTile(unit, cx, cy, taken)
    local team = Game.GetActiveTeam()
    local ux, uy = unit:GetX(), unit:GetY()
    for r = 0, SPREAD_RADIUS + 2 do
        local best, bestDist
        for x = cx - r, cx + r do
            for y = cy - r, cy + r do
                if Map.PlotDistance(cx, cy, x, y) == r and not taken[x * 1024 + y] then
                    local p = Map.GetPlot(x, y)
                    if p and DomainOk(p, unit) and GenericTileOk(p, team) then
                        local d = Map.PlotDistance(ux, uy, x, y)
                        if (not bestDist or d < bestDist) and CanReach(unit, p) then best, bestDist = p, d end
                    end
                end
            end
        end
        if best then return best end
    end
    return nil
end

----------------------------------------------------------------
-- Destination fallbacks (so an order is only sent where the unit can go)
----------------------------------------------------------------
-- Last resort: ignores visibility, units and cities, and only asks that the
-- unit can path to the tile. Looks at the target itself and the rings
-- around it up to RELAX_RADIUS, nearest ring first.
local function PickRelaxedTile(unit, cx, cy, taken)
    local team = Game.GetActiveTeam()
    local ux, uy = unit:GetX(), unit:GetY()
    for r = 0, RELAX_RADIUS do
        local best, bestDist
        for x = cx - r, cx + r do
            for y = cy - r, cy + r do
                if Map.PlotDistance(cx, cy, x, y) == r and not taken[x * 1024 + y] then
                    local p = Map.GetPlot(x, y)
                    -- revealed tiles only: never probe terrain the player hasn't seen
                    if p and p:IsRevealed(team, false) and DomainOk(p, unit)
                       and not p:IsImpassable() then
                        local d = Map.PlotDistance(ux, uy, x, y)
                        if (not bestDist or d < bestDist) and CanReach(unit, p) then
                            best, bestDist = p, d
                        end
                    end
                end
            end
        end
        if best then return best end
    end
    return nil
end

-- Picks where to really send the unit: the planned tile if it can path there,
-- otherwise a free reachable tile near the target, otherwise any reachable
-- tile within RELAX_RADIUS of the target, otherwise the planned tile anyway.
local function ResolveDestination(unit, plot, tx, ty, taken)
    if CanReach(unit, plot) then return plot end
    local alt = PickFreeTile(unit, tx, ty, taken)
    if alt then return alt end
    alt = PickRelaxedTile(unit, tx, ty, taken)
    if alt then return alt end
    return plot
end

----------------------------------------------------------------
-- Deferred work: highlight redraws, trip checks, paced orders
----------------------------------------------------------------
local hlDirty = false
local hlForce = false
local refreshing = false
local checking = false          -- inside a trip check (its own orders must not re-trigger it)
local moveTrackActive = false   -- a dispatched group is being watched
local moveCheckDirty = false
local lastCheck = -1000         -- Now() of the last trip check (throttle)
local updateInstalled = false

local QueueRefresh              -- forward declarations, assigned below
local OnFrameUpdate
local InstallUpdate
local EnqueueOrder

local function UnitOnMission(unit)
    return ActivityTypes ~= nil
       and unit:GetActivityType() == ActivityTypes.ACTIVITY_MISSION
end

-- Awake (or skipped) with no orders: the engine dropped its mission.
-- Sleeping, fortified, alerted etc. count as "the player took over".
local function UnitIsIdle(unit)
    if not ActivityTypes then return false end
    local a = unit:GetActivityType()
    return a == ActivityTypes.ACTIVITY_AWAKE
        or (ActivityTypes.ACTIVITY_HOLD ~= nil and a == ActivityTypes.ACTIVITY_HOLD)
end

local function MovesLeftOf(unit)
    if unit.MovesLeft then return unit:MovesLeft() end
    if unit.GetMoves then return unit:GetMoves() end
    return 0
end

----------------------------------------------------------------
-- Paced orders
----------------------------------------------------------------
-- The engine's order calls work on the current selection, and a multi-turn
-- move can take longer to register than a one-turn move. Sending a whole group
-- in one burst therefore only reliably moved the first unit. Orders are now
-- sent ONE PER FRAME, and the next one is only sent after the previous unit
-- shows proof that its order registered (it moved, it has a mission, or it
-- spent movement). A unit that shows no proof is re-sent a few times.
-- Every order still goes through the engine's networked order calls.
local orderQueue = {}    -- orders waiting to be sent
local current = nil      -- order that was just sent and awaits proof
local queued = {}        -- queued[unitID] = true while a MOVE for that unit is queued or in flight
local snap = nil         -- the player's selection from before we started changing it
local tick = 0

-- The game enters its "move to" preview when the right button goes down and
-- leaves it when the button comes up. We swallow the button-up when we send a
-- group, so the game never leaves that mode and every unit you cycle to shows
-- its movement prediction. This puts the game back in normal selection mode.
-- With onlyIfMoveMode, any other mode (an attack, a ranged strike...) is left alone.
local function ResetMoveMode(onlyIfMoveMode)
    if not (UI and UI.SetInterfaceMode and InterfaceModeTypes
            and InterfaceModeTypes.INTERFACEMODE_SELECTION) then
        return
    end
    if onlyIfMoveMode then
        local ok, mode = pcall(UI.GetInterfaceMode)
        local moveTo = InterfaceModeTypes.INTERFACEMODE_MOVE_TO
        if not (ok and moveTo ~= nil and mode == moveTo) then return end
    end
    pcall(UI.SetInterfaceMode, InterfaceModeTypes.INTERFACEMODE_SELECTION)
end

local function EnsureSnapshot()
    if snap then return end
    local s = GetState(Game.GetActivePlayer())
    local ok, head = pcall(UI.GetHeadSelectedUnit)
    if not ok then head = nil end
    snap = {
        headID = head and head:GetID() or nil,
        group  = head ~= nil and s.selected[head:GetID()] ~= nil
                 and CountSet(s.selected, 2) >= 2,
    }
end

-- Puts the player's selection back (the group if it was the visible
-- selection, otherwise the single unit that was selected)
local function RestoreSnapshot()
    if not snap then return end
    local sn = snap
    snap = nil
    local pid = Game.GetActivePlayer()
    local player = Players[pid]
    local s = GetState(pid)
    guard = true
    pcall(function()
        UI.ClearSelectionList()
        if sn.group then
            for id in pairs(KEEP_GROUP_SELECTED and s.selected or {}) do
                local u = player:GetUnitByID(id)
                if u and not u:IsDelayedDeath() then UI.SelectUnit(u) end
            end
        elseif sn.headID then
            local u = player:GetUnitByID(sn.headID)
            if u and not u:IsDelayedDeath() then UI.SelectUnit(u) end
        end
    end)
    guard = false
    ResetMoveMode(true)
end

local function DropAllOrders()
    orderQueue, current, queued, snap = {}, nil, {}, nil
end

local function SendOrder(player, e)
    local unit = player:GetUnitByID(e.id)
    if not unit or unit:IsDelayedDeath() then
        if e.kind == "move" then queued[e.id] = nil end
        return
    end
    local plot
    if e.kind == "move" then
        if unit:GetX() == e.x and unit:GetY() == e.y then
            queued[e.id] = nil
            return
        end
        plot = Map.GetPlot(e.x, e.y)
        if not plot then
            queued[e.id] = nil
            return
        end

        -- Never send an order the unit can't path to: re-aim near the target first
        if e.tx then
            local trip = GetState(Game.GetActivePlayer()).moveTrack
            local taken = {}
            if trip then
                for oid, d in pairs(trip.dest) do
                    if oid ~= e.id then taken[d.x * 1024 + d.y] = true end
                end
            end
            local better = ResolveDestination(unit, plot, e.tx, e.ty, taken)
            if better:GetX() ~= plot:GetX() or better:GetY() ~= plot:GetY() then
                Log("unit " .. e.id .. " cannot path to " .. e.x .. "," .. e.y
                    .. ", sending it to " .. better:GetX() .. "," .. better:GetY() .. " instead")
                plot = better
                e.x, e.y = plot:GetX(), plot:GetY()
                if trip and trip.dest[e.id] then
                    trip.dest[e.id].x, trip.dest[e.id].y = e.x, e.y
                end
                if unit:GetX() == e.x and unit:GetY() == e.y then
                    queued[e.id] = nil
                    return
                end
            end
        end
    end

    EnsureSnapshot()
    e.attempts = e.attempts + 1
    guard = true
    local ok, err = pcall(function()
        UI.ClearSelectionList()
        UI.SelectUnit(unit)
        if e.kind == "alert" then
            if not (MissionTypes and MissionTypes.MISSION_ALERT
                    and GameMessageTypes and Game.SelectionListGameNetMessage) then
                error("alert mission or message API not available")
            end
            Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,
                                             MissionTypes.MISSION_ALERT, 0, 0, 0, false, false)
        else
            Game.SelectionListMove(plot, e.alt, e.shift, e.ctrl)
        end
    end)
    guard = false
    if not ok then
        Log("order for unit " .. e.id .. " failed: " .. tostring(err))
        if e.kind == "move" then queued[e.id] = nil end
        return
    end

    e.tick  = tick
    e.key   = unit:GetX() * 1024 + unit:GetY()
    e.moves = MovesLeftOf(unit)
    current = e
    if DEBUG_VERBOSE then
        Log("sent " .. e.kind .. " order to unit " .. e.id .. " (attempt " .. e.attempts .. ")")
    end
end

-- Runs once per frame while orders are pending
local function ProcessOrders()
    local pid = Game.GetActivePlayer()
    local player = Players[pid]
    tick = tick + 1

    -- Still waiting for proof that the last order registered?
    if current then
        local e = current
        local unit = player:GetUnitByID(e.id)
        local done, resend = false, false
        if not unit or unit:IsDelayedDeath() or e.kind == "alert" then
            done = true
        elseif unit:GetX() * 1024 + unit:GetY() ~= e.key
               or UnitOnMission(unit)
               or MovesLeftOf(unit) ~= e.moves then
            done = true
        elseif tick - e.tick >= OrderWait() then
            done = true
            local act = ActivityTypes and unit:GetActivityType() or "?"
            local moves = MovesLeftOf(unit)
            local where = ""
            if e.kind == "move" then
                where = " (unit at " .. unit:GetX() .. "," .. unit:GetY()
                        .. ", target " .. e.x .. "," .. e.y .. ", moves left " .. tostring(moves) .. ")"
            end
            if e.kind == "move" and moves <= 0 then
                Log("unit " .. e.id .. " has no movement left, order not accepted" .. where
                    .. ", leaving it for the next turn")
            elseif e.attempts < MAX_SEND_ATTEMPTS then
                resend = true
                Log("unit " .. e.id .. " showed no response to its order (activity "
                    .. tostring(act) .. ")" .. where .. ", resending")
                if e.kind == "move" and e.tx then
                    -- that tile may be unreachable for this unit: aim at another free
                    -- tile near the original target instead
                    e.tried = e.tried or {}
                    e.tried[e.x * 1024 + e.y] = true
                    local alt = PickFreeTile(unit, e.tx, e.ty, e.tried)
                    if alt then
                        e.x, e.y = alt:GetX(), alt:GetY()
                        local trip = GetState(pid).moveTrack
                        if trip and trip.dest[e.id] then
                            trip.dest[e.id].x, trip.dest[e.id].y = e.x, e.y
                        end
                    end
                end
            else
                Log("unit " .. e.id .. " ignored " .. e.attempts
                    .. " orders (activity " .. tostring(act) .. ")" .. where
                    .. ", leaving it for the next turn")
            end
        end
        if not done then return end
        current = nil
        if resend then
            table.insert(orderQueue, 1, e)
        elseif e.kind == "move" then
            queued[e.id] = nil
        end
    end

    local e = table.remove(orderQueue, 1)
    if e then
        if CanIssueOrders(player) then
            SendOrder(player, e)
        else
            -- Not our turn: drop everything, the trip check re-sends later
            if e.kind == "move" then queued[e.id] = nil end
            for _, o in ipairs(orderQueue) do
                if o.kind == "move" then queued[o.id] = nil end
            end
            orderQueue = {}
        end
    end

    if not current and not orderQueue[1] then RestoreSnapshot() end
end

EnqueueOrder = function(e)
    e.attempts = e.attempts or 0
    if e.kind == "move" then
        for i = #orderQueue, 1, -1 do           -- newest order for a unit wins
            local o = orderQueue[i]
            if o.kind == "move" and o.id == e.id then table.remove(orderQueue, i) end
        end
        queued[e.id] = true
    end
    orderQueue[#orderQueue + 1] = e
    InstallUpdate()
end

----------------------------------------------------------------
-- Destination preview (visual only)
----------------------------------------------------------------
-- With a group selected, lights a hex for every unit around the hex under the
-- mouse, keeping the units' positions relative to each other as they are now.
-- The unit nearest the group's centre sits on the hovered hex. This is only a
-- rough guide: the real dispatch still spreads units over free tiles.
local pvHex = {}                -- pvHex[key] = hex position currently lit for the preview
local pvColor = nil
local pvX, pvY = nil, nil       -- hex under the mouse
local pvDirty = false
local pvBroken = false
local previewOn = false         -- true while mouse moves need to be watched

local function PreviewChanged()
    pvDirty = true
    InstallUpdate()
end

local function ClearPreview()
    for key, hex in pairs(pvHex) do
        SetHexHighlight(hex, false, pvColor)
        local lit = litHex[key]
        if lit then SetHexHighlight(lit, true, hlColor) end   -- don't strip a group highlight
    end
    pvHex = {}
end

local function RefreshPreview()
    if pvBroken then return end
    if not PREVIEW or not CheckHighlight() then
        previewOn = false
        return
    end
    if not pvColor then
        pvColor = MakeVec4(PREVIEW_COLOR[1], PREVIEW_COLOR[2], PREVIEW_COLOR[3], PREVIEW_COLOR[4])
    end

    local pid = Game.GetActivePlayer()
    local s = GetState(pid)
    local grouped = CountSet(s.selected, 2) >= 2
    previewOn = grouped
    if not grouped or (PREVIEW_MODE == "hold" and not rDown) then
        ClearPreview()
        return
    end
    if not pvX then pvX, pvY = UI.GetMouseOverHex() end
    if not pvX or pvX < 0 then
        ClearPreview()
        return
    end

    -- Units as axial hex coordinates (the same conversion MakeHex uses)
    local player = Players[pid]
    local pts, n = {}, 0
    local sumQ, sumR = 0, 0
    for id in pairs(s.selected) do
        local u = player:GetUnitByID(id)
        if u and not u:IsDelayedDeath() then
            local ux, uy = u:GetX(), u:GetY()
            local q = ux - (uy - uy % 2) / 2
            n = n + 1
            pts[n] = { q = q, r = uy, unit = u }
            sumQ, sumR = sumQ + q, sumR + uy
        end
    end
    if n < 2 then
        ClearPreview()
        return
    end

    -- Anchor: the unit closest to the group's centre, so the shape doesn't
    -- jump around as the mouse moves
    local cq, cr = sumQ / n, sumR / n
    local anchor, bestD
    for i = 1, n do
        local dq, dr = pts[i].q - cq, pts[i].r - cr
        local d = (math.abs(dq) + math.abs(dr) + math.abs(dq + dr)) / 2
        if not bestD or d < bestD then anchor, bestD = pts[i], d end
    end

    local hq = pvX - (pvY - pvY % 2) / 2
    local want = {}
    for i = 1, n do
        local r = pvY + (pts[i].r - anchor.r)
        local q = hq + (pts[i].q - anchor.q)
        local gy = math.floor(r + 0.5)
        local gx = math.floor(q + (gy - gy % 2) / 2 + 0.5)
        local plot = Map.GetPlot(gx, gy)
        if plot and plot:IsRevealed(Game.GetActiveTeam(), false)
           and DomainOk(plot, pts[i].unit) then
            want[gx * 1024 + gy] = { gx, gy }
        end
    end

    for key, hex in pairs(pvHex) do
        if not want[key] or litHex[key] then
            SetHexHighlight(hex, false, pvColor)
            local lit = litHex[key]
            if lit then SetHexHighlight(lit, true, hlColor) end
            pvHex[key] = nil
        end
    end
    for key, xy in pairs(want) do
        if not pvHex[key] and not litHex[key] then
            local hex = MakeHex(xy[1], xy[2])
            SetHexHighlight(hex, true, pvColor)
            pvHex[key] = hex
        end
    end
end

----------------------------------------------------------------
-- Trip check
----------------------------------------------------------------
-- Looks after a dispatched group across turns:
--  * units that arrived are left alone
--  * units still travelling (or with an order queued) are left alone
--  * units that stopped short with no orders get their move order re-sent
--    (once per turn); repeated failures re-route them to a free tile near the
--    original target, and units that make no progress for MAX_RETRIES turns
--    are given up on
--  * when nobody is left travelling, arrived military units go on alert and
--    the trip ends
local function CheckMovementComplete()
    local pid = Game.GetActivePlayer()
    local s = GetState(pid)
    local t = s.moveTrack
    if not t then
        moveTrackActive = false
        return
    end

    local player = Players[pid]
    local turn = Game.GetGameTurn()

    if turn - t.turn > MAX_TRACK_TURNS then
        s.moveTrack = nil
        moveTrackActive = false
        Log("stopped watching the group (took too long), selection kept")
        QueueRefresh(true)
        return
    end

    -- Tiles already promised to someone in this trip
    local taken = {}
    for _, d in pairs(t.dest) do taken[d.x * 1024 + d.y] = true end

    local arrived, redo, pending = {}, {}, 0
    for id, d in pairs(t.dest) do
        local unit = player:GetUnitByID(id)
        if not unit or unit:IsDelayedDeath() then
            t.dest[id] = nil
        elseif t.gaveUp[id] then
            -- finished with this one, nothing to do
        elseif unit:GetX() == d.x and unit:GetY() == d.y then
            arrived[#arrived + 1] = unit
        elseif queued[id] then
            pending = pending + 1               -- an order is on its way
        else
            -- any movement since the last check counts as progress
            local key = unit:GetX() * 1024 + unit:GetY()
            if t.pos[id] ~= key then
                t.pos[id] = key
                t.tries[id] = 0
            end

            if UnitOnMission(unit) then
                pending = pending + 1
            elseif UnitIsIdle(unit) then
                pending = pending + 1
                if t.ordered[id] ~= turn and CanIssueOrders(player) then
                    local tries = (t.tries[id] or 0) + 1
                    if tries > MAX_RETRIES then
                        t.gaveUp[id] = true
                        pending = pending - 1
                        Log("giving up on unit " .. id .. ", no progress for " .. MAX_RETRIES .. " turns")
                    else
                        t.tries[id] = tries
                        redo[#redo + 1] = { id = id, unit = unit, d = d, tries = tries }
                    end
                end
            else
                -- fortified, sleeping, on alert...: the player took over
                t.dest[id] = nil
            end
        end
    end

    -- Re-send orders for units whose mission was dropped
    local resent = 0
    for _, r in ipairs(redo) do
        local plot = Map.GetPlot(r.d.x, r.d.y)
        if r.tries >= 2 then
            -- same order failed before: try a free tile near the original target
            local alt = PickFreeTile(r.unit, r.d.tx, r.d.ty, taken)
            if alt then
                plot = alt
                r.d.x, r.d.y = alt:GetX(), alt:GetY()
                taken[r.d.x * 1024 + r.d.y] = true
            end
        end
        if plot then
            t.ordered[r.id] = turn
            EnqueueOrder({ kind = "move", id = r.id, x = plot:GetX(), y = plot:GetY(),
                           tx = r.d.tx, ty = r.d.ty,
                           alt = false, shift = false, ctrl = false })
            resent = resent + 1
        end
    end
    if resent > 0 then Log("re-sending move orders for " .. resent .. " unit(s)") end

    if pending > 0 then return end          -- someone is still on the way

    -- Orders can only be issued on our own turn, so finish then
    if #arrived > 0 and ALERT_AFTER_MOVE and not CanIssueOrders(player) then return end

    -- Everyone has arrived or been given up on: put the military units on
    -- alert where they stopped
    local alertUnits = {}
    if ALERT_AFTER_MOVE then
        for _, unit in ipairs(arrived) do
            if unit:IsCombatUnit() then alertUnits[#alertUnits + 1] = unit end
        end
    end
    if #alertUnits > 0 then EnsureSnapshot() end

    -- Drop the trip units from the logical group
    for id in pairs(t.dest) do s.selected[id] = nil end

    if #alertUnits > 0 then
        -- the engine's selection must not end up showing the finished units
        if snap and snap.headID and t.dest[snap.headID] then snap.headID = nil end
        for _, unit in ipairs(alertUnits) do
            EnqueueOrder({ kind = "alert", id = unit:GetID() })
        end
        Log("setting " .. #alertUnits .. " units to alert")
    else
        local ok, head = pcall(UI.GetHeadSelectedUnit)
        if ok and head and t.dest[head:GetID()] then
            guard = true
            pcall(UI.ClearSelectionList)
            guard = false
        end
    end

    s.moveTrack = nil
    moveTrackActive = false
    Log("movement complete, group cleared")
    QueueRefresh(true)
end

local function ClearUpdateNow() ContextPtr:ClearUpdate() end
local function SetUpdateNow()   ContextPtr:SetUpdate(OnFrameUpdate) end

OnFrameUpdate = function()
    updateInstalled = false
    pcall(ClearUpdateNow)
    userAction = false

    -- Trip checks are throttled to one per CHECK_GAP seconds. A check that is
    -- too early stays pending (and keeps this callback alive, see the end of
    -- the function) so the last unit's arrival is never missed.
    if moveCheckDirty then
        local now = Now()
        if now - lastCheck >= CHECK_GAP then
            lastCheck = now
            moveCheckDirty = false
            checking = true
            local ok, err = pcall(CheckMovementComplete)
            checking = false
            if not ok then
                moveTrackActive = false
                guard = false
                Log("movement check error: " .. tostring(err))
            end
        end
    end

    if hlDirty then
        local force = hlForce
        hlDirty, hlForce = false, false
        refreshing = true
        local ok, err = pcall(RefreshHighlights, force)
        if not ok then
            hlAvailable = false
            Log("hex highlight error, disabled: " .. tostring(err))
        end
        local okd, errd = pcall(RefreshDestHighlight)
        refreshing = false
        if not okd then
            SHOW_DEST = false
            Log("destination highlight error, disabled: " .. tostring(errd))
        end
    end

    if pvDirty then
        pvDirty = false
        refreshing = true
        local ok, err = pcall(RefreshPreview)
        refreshing = false
        if not ok then
            pvBroken = true
            previewOn = false
            Log("destination preview error, disabled: " .. tostring(err))
            pcall(ClearPreview)
        end
    end

    if current or orderQueue[1] then
        local ok, err = pcall(ProcessOrders)
        if not ok then
            Log("order error: " .. tostring(err))
            DropAllOrders()
            guard = false
        end
    end

    -- Orders are paced one frame at a time, and a throttled trip check waits
    -- for its interval, so keep running while either is pending
    if current or orderQueue[1] or moveCheckDirty then InstallUpdate() end
end

-- Installs the per-frame callback once; it removes itself when it has run
InstallUpdate = function()
    if updateInstalled then return end
    updateInstalled = true
    if not pcall(SetUpdateNow) then updateInstalled = false end
end

QueueRefresh = function(force)
    if hlAvailable == false then return end
    hlDirty = true
    if force then
        -- the preview only depends on the selection, which forced refreshes
        -- cover; plain unit-movement refreshes don't need to redo it
        hlForce = true
        pvDirty = true
    end
    InstallUpdate()
end

local function QueueMoveCheck()
    moveCheckDirty = true
    InstallUpdate()
end

-- Marks the next engine selection change as caused by the user
local function MarkUserAction()
    userAction = true
    InstallUpdate()
end

----------------------------------------------------------------
-- Detaching one unit from a running trip
----------------------------------------------------------------
-- Takes the unit out of the trip so the trip check never re-sends its old
-- orders, drops any of its orders still waiting in the queue, and tells the
-- player. The rest of the trip is untouched and keeps its original targets.
-- The unit's NEW order is not sent here: the caller lets the engine handle
-- the right-click as usual.
local function DetachFromTrip(unit)
    local pid = Game.GetActivePlayer()
    local s = GetState(pid)
    local t = s.moveTrack
    local id = unit:GetID()
    if not (t and t.dest[id]) then return false end

    t.dest[id]    = nil
    t.ordered[id] = nil
    t.tries[id]   = nil
    t.gaveUp[id]  = nil
    t.pos[id]     = nil
    queued[id]    = nil
    for i = #orderQueue, 1, -1 do
        local o = orderQueue[i]
        if o.kind == "move" and o.id == id then table.remove(orderQueue, i) end
    end

    local remaining = CountSet(t.dest)
    local name = UnitDisplayName(unit)
    if remaining > 0 then
        Alert(name .. " removed from the group and is moving on its own. "
              .. remaining .. " unit(s) continue to the original objective.")
        QueueMoveCheck()
    else
        Alert(name .. " removed from the group and is moving on its own. The group has no units left.")
        s.moveTrack = nil
        moveTrackActive = false
    end
    QueueRefresh(true)
    return true
end

-- Right-click with a single unit selected: if the game's selected unit is on a
-- group trip, it leaves the trip (the engine then moves it to the clicked hex).
local function TryDetachSelected()
    local pid = Game.GetActivePlayer()
    local t = GetState(pid).moveTrack
    if not t then return end
    if not CanIssueOrders(Players[pid]) then return end

    local ok, head = pcall(UI.GetHeadSelectedUnit)
    if not ok or not head then return end
    if not t.dest[head:GetID()] then return end

    local hx, hy = UI.GetMouseOverHex()
    if not (hx and Map.GetPlot(hx, hy)) then return end

    DetachFromTrip(head)
end

-- Keep the highlight and the trip check up to date as units move. Both
-- hooks do nothing unless a highlight or a watched trip is active.
if Events.SerialEventUnitInfoDirty then
    Events.SerialEventUnitInfoDirty.Add(function()
        if refreshing or checking then return end
        if not IsMyTurn() then return end       -- other players' turns: nothing of ours can change
        if litCount > 0 or destLit then QueueRefresh(false) end
        if moveTrackActive then QueueMoveCheck() end
    end)
end
if Events.ActivePlayerTurnStart then
    Events.ActivePlayerTurnStart.Add(function()
        -- A new turn is when blocked units need their orders re-sent. This also
        -- covers hotseat: the new active player gets their own trip and highlight.
        DropAllOrders()
        moveTrackActive = GetState(Game.GetActivePlayer()).moveTrack ~= nil
        -- (also repaints or clears overlays left by the previous hotseat player)
        if litCount > 0 or destLit or next(pvHex) then QueueRefresh(true) end
        if moveTrackActive then QueueMoveCheck() end
    end)
end

----------------------------------------------------------------
-- Selection tracking (event driven, no polling)
----------------------------------------------------------------
-- Events we cause ourselves are ignored (guard). Selection changes the game
-- makes on its own, such as auto-advancing to the next unit after an order,
-- are ignored too, so they can't silently drop the group. Only a change that
-- follows a left click or key press collapses the group to what the user
-- picked (Shift adds instead). Picking a unit that is on a trip does NOT
-- remove it from the trip: it just lights up its destination (see
-- RefreshDestHighlight). A right-click with it selected detaches it.
local function OnSelectionChanged(playerID, unitID, i, j, k, isSelected)
    if guard then return end
    if playerID ~= Game.GetActivePlayer() then return end
    if not userAction then
        if DEBUG_VERBOSE then
            Log("ignored engine-driven selection change for unit " .. tostring(unitID))
        end
        return
    end
    local s = GetState(playerID)
    if isSelected then
        if UIManager:GetShift() then
            s.selected[unitID] = true
        else
            s.selected = { [unitID] = true }
        end
    elseif s.selected[unitID] and CountSet(s.selected, 2) < 2 then
        s.selected[unitID] = nil
    end
    QueueRefresh(true)
end
if Events.UnitSelectionChanged then
    Events.UnitSelectionChanged.Add(OnSelectionChanged)
end

local function OnUnitDestroyed(playerID, unitID)
    if playerID ~= Game.GetActivePlayer() then return end
    local s = GetState(playerID)
    local wasSelected = s.selected[unitID]
    s.selected[unitID] = nil
    if s.moveTrack then s.moveTrack.dest[unitID] = nil end
    for n = 1, MAX_GROUPS do s.groups[n][unitID] = nil end
    if wasSelected then QueueRefresh(true) end
end
if Events.SerialEventUnitDestroyed then
    Events.SerialEventUnitDestroyed.Add(OnUnitDestroyed)
end

----------------------------------------------------------------
-- Control groups (optional)
----------------------------------------------------------------
local function AssignGroup(n)
    local s = GetState(Game.GetActivePlayer())
    if next(s.selected) == nil then return end
    local g = {}
    for id in pairs(s.selected) do
        g[id] = true
        for m = 1, MAX_GROUPS do            -- a unit belongs to one group only
            if m ~= n then s.groups[m][id] = nil end
        end
    end
    s.groups[n] = g
end

local function RecallGroup(n)
    local pid = Game.GetActivePlayer()
    local s = GetState(pid)
    local g = s.groups[n]
    if next(g) == nil then return false end
    local player = Players[pid]

    guard = true
    UI.ClearSelectionList()
    local recalled = {}
    for id in pairs(g) do
        local unit = player:GetUnitByID(id)
        if unit and not unit:IsDelayedDeath() then
            UI.SelectUnit(unit)
            recalled[id] = true
        else
            g[id] = nil                     -- lazy prune (safe during pairs)
        end
    end
    guard = false

    if next(recalled) == nil then return false end
    s.selected = recalled
    QueueRefresh(true)
    return true
end

----------------------------------------------------------------
-- Selection box visual
----------------------------------------------------------------
local function DrawBox(x1, y1, x2, y2)
    Controls.SelBox:SetOffsetVal(math.min(x1, x2), math.min(y1, y2))
    Controls.SelBox:SetSizeVal(math.abs(x2 - x1), math.abs(y2 - y1))
    Controls.SelBox:SetHide(false)
end

local function HideBox()
    Controls.SelBox:SetHide(true)
end

----------------------------------------------------------------
-- Box select (runs once, on mouse release)
----------------------------------------------------------------
local function Eligible(unit)
    if unit:IsDelayedDeath() then return false end
    if MILITARY_ONLY and not unit:IsCombatUnit() then return false end
    return true
end

-- Screen-space pass. These globals can differ between builds, so the whole
-- pass runs inside a single pcall (see BoxSelect) instead of one per unit.
local function CollectScreen(player, left, top, right, bottom)
    local picked = {}
    for unit in player:Units() do
        if Eligible(unit) then
            local world = HexToWorld(ToHexFromGrid(Vector2(unit:GetX(), unit:GetY())))
            local sx, sy = WorldPositionToScreenXY(world)
            if sx >= left and sx <= right and sy >= top and sy <= bottom then
                picked[#picked + 1] = unit
            end
        end
    end
    return picked
end

-- Fallback: bounding box in hex coordinates (less accurate near the edges)
local function CollectHex(player)
    local picked = {}
    local endHexX, endHexY = UI.GetMouseOverHex()
    if not (startHexX and endHexX) then return picked end
    local xMin, xMax = math.min(startHexX, endHexX), math.max(startHexX, endHexX)
    local yMin, yMax = math.min(startHexY, endHexY), math.max(startHexY, endHexY)
    for unit in player:Units() do
        if Eligible(unit) then
            local ux, uy = unit:GetX(), unit:GetY()
            if ux >= xMin and ux <= xMax and uy >= yMin and uy <= yMax then
                picked[#picked + 1] = unit
            end
        end
    end
    return picked
end

local screenOK = nil           -- nil = untested, true = works, false = use hex box

local function BoxSelect(x1, y1, x2, y2, addToSelection)
    local left,  right  = math.min(x1, x2), math.max(x1, x2)
    local top,   bottom = math.min(y1, y2), math.max(y1, y2)
    local pid = Game.GetActivePlayer()
    local player = Players[pid]

    local picked
    if screenOK ~= false then
        local ok, result = pcall(CollectScreen, player, left, top, right, bottom)
        if ok then
            screenOK = true
            picked = result
        else
            screenOK = false
            Log("screen projection unavailable (" .. tostring(result) .. "), using hex box from now on")
        end
    end
    if not picked then picked = CollectHex(player) end
    Log("box picked " .. #picked .. " units")

    if #picked == 0 then return false end

    local s = GetState(pid)
    guard = true
    if not addToSelection then
        UI.ClearSelectionList()
        s.selected = {}
    end
    for _, unit in ipairs(picked) do
        UI.SelectUnit(unit)
        s.selected[unit:GetID()] = true
    end
    guard = false
    QueueRefresh(true)
    return true
end

----------------------------------------------------------------
-- Group dispatch (runs once per right-click, only with 2+ units selected)
----------------------------------------------------------------

-- Groups units by the tile they start on. Units sharing a tile get the SAME
-- destination (so they travel together); units on different tiles get
-- DIFFERENT destinations. The nearest group takes the clicked hex itself and
-- the others take free tiles around it.
local function AssignDestinations(units, plot)
    local clusters, byKey = {}, {}
    for _, e in ipairs(units) do
        local ux, uy = e.unit:GetX(), e.unit:GetY()
        local key = ux * 1024 + uy
        local c = byKey[key]
        if not c then
            c = { x = ux, y = uy, dist = e.dist, units = {}, dest = plot }
            byKey[key] = c
            clusters[#clusters + 1] = c
        end
        c.units[#c.units + 1] = e
    end
    table.sort(clusters, function(a, b) return a.dist < b.dist end)

    local need = #clusters - 1
    if need <= 0 or not SPREAD_UNITS then return clusters end

    -- Free tiles around the target, nearest rings first
    local team = Game.GetActiveTeam()
    local px, py = plot:GetX(), plot:GetY()
    local pool = {}
    local want = need * 2 + 4
    for r = 1, SPREAD_RADIUS do
        for x = px - r, px + r do
            for y = py - r, py + r do
                if Map.PlotDistance(px, py, x, y) == r then
                    local p = Map.GetPlot(x, y)
                    if p and GenericTileOk(p, team) then
                        pool[#pool + 1] = { p = p, x = x, y = y, ring = r }
                    end
                end
            end
        end
        if #pool >= want then break end
    end

    -- Each group (nearest first) takes the free tile that is close to both
    -- itself and the target, so the formation stays compact
    local taken = {}
    for ci = 2, #clusters do
        local c = clusters[ci]
        local lead = c.units[1].unit
        local best, bestScore, bestIdx
        local unreachable = {}
        while true do
            best, bestScore, bestIdx = nil, nil, nil
            for pi = 1, #pool do
                if not taken[pi] and not unreachable[pi] then
                    local e = pool[pi]
                    if DomainOk(e.p, lead) then
                        local score = Map.PlotDistance(c.x, c.y, e.x, e.y) + e.ring
                        if not bestScore or score < bestScore then
                            best, bestScore, bestIdx = e.p, score, pi
                        end
                    end
                end
            end
            if not best or CanReach(lead, best) then break end
            unreachable[bestIdx] = true         -- no path there, try the next best tile
        end
        if best then
            c.dest = best
            taken[bestIdx] = true
        else
            Log("no free tile for the group starting at " .. c.x .. "," .. c.y .. ", sending it to the target")
        end
    end
    return clusters
end

local function DispatchMove(plot, alt, shift, ctrl)
    local pid = Game.GetActivePlayer()
    local player = Players[pid]
    local s = GetState(pid)

    if not CanIssueOrders(player) then
        Log("dispatch skipped, it is not your turn")
        return false
    end

    local px, py = plot:GetX(), plot:GetY()
    local units = {}
    for id in pairs(s.selected) do
        local unit = player:GetUnitByID(id)
        if unit and not unit:IsDelayedDeath() then
            units[#units + 1] = {
                unit = unit,
                id   = id,
                dist = Map.PlotDistance(unit:GetX(), unit:GetY(), px, py),
            }
        end
    end
    if #units < 2 then
        Log("dispatch skipped, only " .. #units .. " live units in group")
        return false                        -- let the engine handle single units
    end

    -- Nearest units are ordered first so they claim the front tiles
    table.sort(units, function(a, b) return a.dist < b.dist end)

    local ok, clusters = pcall(AssignDestinations, units, plot)
    if not ok then
        Log("destination spread failed (" .. tostring(clusters) .. "), sending everyone to the target")
        clusters = { { dest = plot, units = units } }
    end

    Log("dispatching " .. #units .. " units in " .. #clusters .. " tile group(s) toward " .. px .. "," .. py)


    if DESELECT_AFTER_ORDER then
        -- The trip below keeps looking after the units, so the group itself is
        -- released now: no highlight, and nothing is re-selected when the
        -- orders have gone out.
        s.selected = {}
        snap = snap or {}
        snap.headID, snap.group = nil, false
    else
        local keep = {}
        for _, e in ipairs(units) do keep[e.id] = true end
        s.selected = keep
    end

    -- Start (or extend) the trip: remember where each unit is going so it can
    -- be re-ordered on later turns if the engine drops its mission. Units from
    -- an earlier, still-running trip keep their own destinations.
    local turn = Game.GetGameTurn()
    local t = s.moveTrack
    if not t then
        t = { dest = {}, ordered = {}, tries = {}, gaveUp = {}, pos = {} }
        s.moveTrack = t
    end
    t.turn = turn
    for _, c in ipairs(clusters) do
        local dx, dy = c.dest:GetX(), c.dest:GetY()
        for _, e in ipairs(c.units) do
            t.dest[e.id]   = { x = dx, y = dy, tx = px, ty = py }
            t.ordered[e.id] = turn          -- just ordered, don't re-send this turn
            t.tries[e.id]  = 0
            t.gaveUp[e.id] = nil
            t.pos[e.id]    = nil
            EnqueueOrder({ kind = "move", id = e.id, x = dx, y = dy, tx = px, ty = py,
                           alt = alt, shift = shift, ctrl = ctrl })
        end
    end
    moveTrackActive = true
    QueueMoveCheck()
    QueueRefresh(true)
    return true
end

----------------------------------------------------------------
-- Input
----------------------------------------------------------------
-- True if the unit the game currently has selected belongs to our group.
-- If the player picked a different unit some way we couldn't see (a unit
-- banner, the unit panel), the group is stale and must not hijack right-click.
local function GroupMatchesEngineSelection()
    local ok, head = pcall(UI.GetHeadSelectedUnit)
    if not ok then return true end          -- can't tell, assume it matches
    if not head then return true end        -- nothing selected: the script's group still applies
    return GetState(Game.GetActivePlayer()).selected[head:GetID()] ~= nil
end

local function BoxModifierHeld()
    local ctrl, alt = UIManager:GetControl(), UIManager:GetAlt()
    if REQUIRE_BOTH then return ctrl and alt end
    return ctrl or alt
end

local function InputHandlerImpl(uiMsg, wParam)

    -- Mouse. Without the modifier(s) nothing here is swallowed, so normal
    -- clicks and left-drag map panning behave exactly as before.
    if uiMsg == MSG_LDOWN then
        if BoxModifierHeld() then
            boxing, dragging = true, false
            startX, startY = UIManager:GetMousePos()
            startHexX, startHexY = UI.GetMouseOverHex()
            return true            -- swallow so the map doesn't pan
        end
        boxing = false
        MarkUserAction()
        clickTracking = CLICK_CANCELS and not UIManager:GetShift() and HasGroupSelected()
        if clickTracking then clickX, clickY = UIManager:GetMousePos() end
        return false

    elseif uiMsg == MSG_MOVE then
        if boxing then
            local x, y = UIManager:GetMousePos()
            if not dragging
               and (math.abs(x - startX) > DRAG_THRESHOLD
                    or math.abs(y - startY) > DRAG_THRESHOLD) then
                dragging = true
            end
            if dragging then DrawBox(startX, startY, x, y) end
            return true
        end
        if previewOn then
            -- one comparison per mouse move; the redraw itself waits for the next frame
            local hx, hy = UI.GetMouseOverHex()
            if hx ~= pvX or hy ~= pvY then
                pvX, pvY = hx, hy
                PreviewChanged()
            end
        end
        return false

    elseif uiMsg == MSG_LUP then
        if boxing then
            local wasDragging = dragging
            boxing, dragging = false, false
            HideBox()
            if wasDragging then
                local x, y = UIManager:GetMousePos()
                BoxSelect(startX, startY, x, y, UIManager:GetShift())
            end
            return true
        end

        MarkUserAction()

        -- Plain click (not a drag) while a group is selected: cancel it.
        -- The click still passes through; we only clear if the group is still
        -- the logical selection, so clicking a unit keeps that new selection.
        -- (Units already sent on a trip keep travelling.)
        if clickTracking then
            clickTracking = false
            local x, y = UIManager:GetMousePos()
            if math.abs(x - clickX) <= DRAG_THRESHOLD
               and math.abs(y - clickY) <= DRAG_THRESHOLD
               and HasGroupSelected() then
                guard = true
                UI.ClearSelectionList()
                guard = false
                local s = GetState(Game.GetActivePlayer())
                s.selected = {}
                QueueRefresh(true)
            end
        end
        return false

    -- Right-click: with 2+ units in the group, send them all to the clicked
    -- hex. Right-drags (map panning) and single-unit orders pass through.
    elseif uiMsg == MSG_RDOWN then
        rDown = true
        rStartX, rStartY = UIManager:GetMousePos()
        if PREVIEW_MODE == "hold" then PreviewChanged() end
        -- With a group selected the button-up is ours (it sends the group), so the
        -- button-down is swallowed too. If the game saw the down without the up, it
        -- would stay in its hold-to-preview state and show movement paths for every
        -- unit you select afterwards.
        if HasGroupSelected() and GroupMatchesEngineSelection() then
            return true
        end
        return false

    elseif uiMsg == MSG_RUP then
        if not rDown then return false end
        rDown = false
        if PREVIEW_MODE == "hold" then PreviewChanged() end
        local x, y = UIManager:GetMousePos()
        if not RIGHT_DRAG_DISPATCHES
           and (math.abs(x - rStartX) > DRAG_THRESHOLD
                or math.abs(y - rStartY) > DRAG_THRESHOLD) then
            return false
        end
        if not HasGroupSelected() then
            -- A single unit that is part of a running group trip leaves the
            -- trip here. The click itself passes through, so the engine sends
            -- the unit to the clicked hex on its own.
            TryDetachSelected()
            if DEBUG_VERBOSE then Log("right-click passed to engine, no group selected") end
            return false
        end
        if not GroupMatchesEngineSelection() then
            Log("group dropped: the selected unit is not part of it")
            local s = GetState(Game.GetActivePlayer())
            s.selected = {}
            QueueRefresh(true)
            return false                -- let the engine move the selected unit
        end
        local hx, hy = UI.GetMouseOverHex()
        local plot = hx and Map.GetPlot(hx, hy)
        if not plot then
            Log("right-click ignored, no plot under cursor")
            return false
        end
        local handled = DispatchMove(plot, UIManager:GetAlt(), UIManager:GetShift(), UIManager:GetControl())
        if handled then ResetMoveMode(false) end   -- we ate the button-up, so end the game's move preview
        return handled

    -- Keyboard: Ctrl+1..9 assigns, 1..9 recalls
    elseif uiMsg == MSG_KEY then
        MarkUserAction()
        local n = wParam - KEY_1 + 1
        if n < 1 or n > MAX_GROUPS then return false end
        if UIManager:GetControl() then
            AssignGroup(n)
            return true
        end
        if not UIManager:GetShift() and not UIManager:GetAlt() then
            return RecallGroup(n)
        end
    end

    return false
end

-- Any error is logged and every transient flag is reset, so one failure can
-- never leave the script stuck in a half-finished state.
local function InputHandler(uiMsg, wParam, lParam)
    -- Fast path: mouse moves are by far the most frequent message
    if uiMsg == MSG_MOVE and not boxing and not previewOn then return false end

    local ok, result = pcall(InputHandlerImpl, uiMsg, wParam)
    if ok then return result end
    Log("ERROR in input handler: " .. tostring(result))
    guard, boxing, dragging, clickTracking, rDown = false, false, false, false, false
    pcall(HideBox)
    return false
end
ContextPtr:SetInputHandler(InputHandler)