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
--  * Selecting a trip unit yourself takes it out of the trip (manual control).
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
local ORDER_WAIT_TICKS  = 20    -- frames to wait for proof that an order registered before re-sending it
local MAX_SEND_ATTEMPTS = 3    -- times one order is sent before it is left for the next turn
local HIGHLIGHT        = true  -- light up the hex under every unit in the group
local HL_COLOR         = { 1.0, 0.9, 0.5, 1.0 }   -- r, g, b, a (0 to 1)
local HL_STYLE         = nil   -- optional highlight style name passed to the game
local DEBUG            = true  -- writes key events to Lua.log
local DEBUG_VERBOSE    = false -- also logs routine events (can be noisy)

local function Log(msg)
    if DEBUG then print("GroupMove: " .. msg) end
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
                        if not bestDist or d < bestDist then best, bestDist = p, d end
                    end
                end
            end
        end
        if best then return best end
    end
    return nil
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
            for id in pairs(s.selected) do
                local u = player:GetUnitByID(id)
                if u and not u:IsDelayedDeath() then UI.SelectUnit(u) end
            end
        elseif sn.headID then
            local u = player:GetUnitByID(sn.headID)
            if u and not u:IsDelayedDeath() then UI.SelectUnit(u) end
        end
    end)
    guard = false
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
        elseif tick - e.tick >= ORDER_WAIT_TICKS then
            done = true
            local act = ActivityTypes and unit:GetActivityType() or "?"
            if e.attempts < MAX_SEND_ATTEMPTS then
                resend = true
                Log("unit " .. e.id .. " showed no response to its order (activity "
                    .. tostring(act) .. "), resending")
            else
                Log("unit " .. e.id .. " ignored " .. e.attempts
                    .. " orders (activity " .. tostring(act) .. "), leaving it for the next turn")
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

    if moveCheckDirty then
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

    if hlDirty then
        local force = hlForce
        hlDirty, hlForce = false, false
        refreshing = true
        local ok, err = pcall(RefreshHighlights, force)
        refreshing = false
        if not ok then
            hlAvailable = false
            Log("hex highlight error, disabled: " .. tostring(err))
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

    -- Orders are paced one frame at a time, so keep running while any are pending
    if current or orderQueue[1] then InstallUpdate() end
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
    if force then hlForce = true end
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

-- Keep the highlight and the trip check up to date as units move. Both
-- hooks do nothing unless a highlight or a watched trip is active.
if Events.SerialEventUnitInfoDirty then
    Events.SerialEventUnitInfoDirty.Add(function()
        if refreshing or checking then return end
        if litCount > 0 then QueueRefresh(false) end
        if moveTrackActive then QueueMoveCheck() end
    end)
end
if Events.ActivePlayerTurnStart then
    Events.ActivePlayerTurnStart.Add(function()
        -- A new turn is when blocked units need their orders re-sent. This also
        -- covers hotseat: the new active player gets their own trip and highlight.
        DropAllOrders()
        moveTrackActive = GetState(Game.GetActivePlayer()).moveTrack ~= nil
        if litCount > 0 then QueueRefresh(true) end
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
-- picked (Shift adds instead). A unit the user picks this way also leaves
-- any trip it was on, so the trip never fights a manual order.
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
        if s.moveTrack then s.moveTrack.dest[unitID] = nil end
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
        for pi = 1, #pool do
            if not taken[pi] then
                local e = pool[pi]
                if DomainOk(e.p, lead) then
                    local score = Map.PlotDistance(c.x, c.y, e.x, e.y) + e.ring
                    if not bestScore or score < bestScore then
                        best, bestScore, bestIdx = e.p, score, pi
                    end
                end
            end
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


    local keep = {}
    for _, e in ipairs(units) do keep[e.id] = true end
    s.selected = keep

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
            EnqueueOrder({ kind = "move", id = e.id, x = dx, y = dy,
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
    if not head then return false end
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
        return false

    elseif uiMsg == MSG_RUP then
        if not rDown then return false end
        rDown = false
        local x, y = UIManager:GetMousePos()
        if math.abs(x - rStartX) > DRAG_THRESHOLD
           or math.abs(y - rStartY) > DRAG_THRESHOLD then
            return false
        end
        if not HasGroupSelected() then
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
        return DispatchMove(plot, UIManager:GetAlt(), UIManager:GetShift(), UIManager:GetControl())

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
    if uiMsg == MSG_MOVE and not boxing then return false end

    local ok, result = pcall(InputHandlerImpl, uiMsg, wParam)
    if ok then return result end
    Log("ERROR in input handler: " .. tostring(result))
    guard, boxing, dragging, clickTracking, rDown = false, false, false, false, false
    pcall(HideBox)
    return false
end
ContextPtr:SetInputHandler(InputHandler)