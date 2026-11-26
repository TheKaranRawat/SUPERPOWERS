print("RangeDisplay: file start")

if not Vector2 then
    Vector2 = function(x, y) return { x = x, y = y } end
end
if not Vector4 then
    Vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end
end

local STYLE = "FireRangeBorder"
local COLOR = Vector4(1, 0.3, 0.3, 1)
local HIGHLIGHT_OWN_TILE = true    -- extra highlight on the unit's own tile (land/sea ranged)
local INCLUDE_NONCOMBAT = true     -- count workers/settlers etc. as targets
local DEBUG = false

-- Aircraft
local AIR_STYLE = "FireRangeBorder"
local AIR_COLOR = Vector4(1, 0, 0, 1)
local AIR_RING_ONLY = false                      -- true = only the outer ring of hexes
local AIR_TARGET_STYLE = "ValidFireTargetBorder" -- verify this style exists (see notes)
local AIR_TARGET_COLOR = Vector4(1, 0.9, 0, 1)   -- yellow
local AIR_SELECT_DELAY = 2                       -- frames to wait after selection
local AIR_DIRTY_DELAY = 1                        -- frames to wait after other updates

local RANGE_MODE = InterfaceModeTypes.INTERFACEMODE_RANGE_ATTACK
local SELECT_MODE = InterfaceModeTypes.INTERFACEMODE_SELECTION

local g_weSetMode = false
local g_ownTileShown = false
local g_gameCheckBroken = false

local g_airShown = false
local g_airSig = nil
local g_airWait = 0
local g_airForce = false

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function GetUnitRange(unit)
    if unit.Range then return unit:Range() end
    if unit.GetRange then return unit:GetRange() end
    return 0
end

local function IsAirUnit(unit)
    return unit ~= nil and unit.GetDomainType ~= nil
        and unit:GetDomainType() == DomainTypes.DOMAIN_AIR
end

local function IsRangedUnit(unit)
    if not unit then return false end
    local ranged
    if unit.IsRanged then
        ranged = unit:IsRanged()
    elseif unit.GetBaseRangedCombatStrength then
        ranged = unit:GetBaseRangedCombatStrength() > 0
    else
        ranged = false
    end
    return ranged and GetUnitRange(unit) > 0
end

local function CanShowFor(unit)
    if unit.IsEmbarked and unit:IsEmbarked() then return false end
    if unit.IsOutOfAttacks and unit:IsOutOfAttacks() then return false end
    if unit.CanMove and not unit:CanMove() then return false end
    return true
end

------------------------------------------------------------
-- Target detection
------------------------------------------------------------
local function TileHasTarget(unit, plot)
    local px, py = plot:GetX(), plot:GetY()

    -- Preferred: the game's own check
    if unit.CanRangeStrikeAt and not g_gameCheckBroken then
        local ok, res = pcall(unit.CanRangeStrikeAt, unit, px, py, true, INCLUDE_NONCOMBAT)
        if ok then
            return res and true or false
        end
        g_gameCheckBroken = true
        print("RangeDisplay: CanRangeStrikeAt failed, using fallback: " .. tostring(res))
    end

    -- Fallback: visible enemy unit or enemy city
    if plot.IsVisibleEnemyUnit and plot:IsVisibleEnemyUnit(unit:GetOwner()) then
        return true
    end
    if plot.IsEnemyCity and plot:IsEnemyCity(unit) then
        return true
    end
    return false
end

local function HasTargetInRange(unit)
    local x, y, range = unit:GetX(), unit:GetY(), GetUnitRange(unit)
    local team = Game.GetActiveTeam()

    for dx = -range, range do
        for dy = -range, range do
            local plot = Map.PlotXYWithRangeCheck(x, y, dx, dy, range)
            if plot and not (plot:GetX() == x and plot:GetY() == y) then
                if plot:IsVisible(team, false) and TileHasTarget(unit, plot) then
                    return true
                end
            end
        end
    end
    return false
end

------------------------------------------------------------
-- Aircraft circle + targets
------------------------------------------------------------
local function ClearAirRange(force)
    if g_airShown or force then
        g_airShown = false
        g_airSig = nil
        if Events.ClearHexHighlightStyle then
            Events.ClearHexHighlightStyle(AIR_STYLE)
            if AIR_TARGET_STYLE ~= AIR_STYLE then
                Events.ClearHexHighlightStyle(AIR_TARGET_STYLE)
            end
        end
    end
end

local function HighlightPlot(px, py, color, style)
    local hex = ToHexFromGrid(Vector2(px, py))
    local ok, err = pcall(Events.SerialEventHexHighlight, hex, true, color, style)
    if not ok then
        print("RangeDisplay: air highlight failed: " .. tostring(err))
    end
    return ok
end

local function DrawAirRange(unit, force)
    local x, y, range = unit:GetX(), unit:GetY(), GetUnitRange(unit)
    if range <= 0 then ClearAirRange(true) return end

    local team = Game.GetActiveTeam()
    local rangeTiles, targetTiles, seen = {}, {}, {}

    for dx = -range, range do
        for dy = -range, range do
            local plot = Map.PlotXYWithRangeCheck(x, y, dx, dy, range)
            if plot then
                local px, py = plot:GetX(), plot:GetY()
                local key = px .. "," .. py
                if not seen[key] then
                    seen[key] = true
                    local isOwn = (px == x and py == y)
                    local inRing = (not AIR_RING_ONLY) or Map.PlotDistance(x, y, px, py) == range
                    if inRing then
                        rangeTiles[#rangeTiles + 1] = { px, py }
                    end
                    if not isOwn and plot:IsVisible(team, false) and TileHasTarget(unit, plot) then
                        targetTiles[#targetTiles + 1] = { px, py }
                    end
                end
            end
        end
    end

    -- Signature: only redraw when something actually changed
    local parts = { unit:GetID(), x, y, range }
    for _, t in ipairs(targetTiles) do parts[#parts + 1] = t[1] .. ":" .. t[2] end
    local sig = table.concat(parts, "|")
    if not force and g_airShown and sig == g_airSig then return end

    ClearAirRange(true)
    g_airSig = sig

    for _, t in ipairs(rangeTiles) do
        if not HighlightPlot(t[1], t[2], AIR_COLOR, AIR_STYLE) then return end
        g_airShown = true
    end
    for _, t in ipairs(targetTiles) do
        if not HighlightPlot(t[1], t[2], AIR_TARGET_COLOR, AIR_TARGET_STYLE) then break end
        g_airShown = true
    end
    if DEBUG then
        print("RangeDisplay: air range drawn, targets = " .. #targetTiles)
    end
end

local function ProcessAirRefresh()
    local force = g_airForce
    g_airForce = false
    local unit = UI.GetHeadSelectedUnit()
    if IsAirUnit(unit) and unit:GetOwner() == Game.GetActivePlayer() then
        DrawAirRange(unit, force)
    else
        ClearAirRange(false)
    end
end

local HAVE_UPDATE = ContextPtr ~= nil and ContextPtr.SetUpdate ~= nil

local function RequestAirRefresh(force, delay)
    if force then g_airForce = true end
    if HAVE_UPDATE then
        if g_airWait < delay then g_airWait = delay end
    else
        ProcessAirRefresh()
    end
end

if HAVE_UPDATE then
    ContextPtr:SetUpdate(function()
        if g_airWait > 0 then
            g_airWait = g_airWait - 1
            if g_airWait == 0 then ProcessAirRefresh() end
        end
    end)
end

------------------------------------------------------------
-- Own tile highlight (land/sea ranged mode)
------------------------------------------------------------
local function ClearOwnTile()
    if g_ownTileShown then
        g_ownTileShown = false
        if Events.ClearHexHighlightStyle then
            Events.ClearHexHighlightStyle(STYLE)
        end
    end
end

local function ShowOwnTile(unit)
    if not HIGHLIGHT_OWN_TILE then return end
    local hex = ToHexFromGrid(Vector2(unit:GetX(), unit:GetY()))
    local ok, err = pcall(Events.SerialEventHexHighlight, hex, true, COLOR, STYLE)
    if ok then
        g_ownTileShown = true
    else
        print("RangeDisplay: own tile highlight failed: " .. tostring(err))
    end
end

------------------------------------------------------------
-- Ranged attack mode
------------------------------------------------------------
local function EnterRangeMode(unit)
    local ok, err = pcall(UI.SetInterfaceMode, RANGE_MODE)
    if not ok then
        print("RangeDisplay: SetInterfaceMode failed: " .. tostring(err))
        return
    end
    g_weSetMode = true
    ShowOwnTile(unit)
    if DEBUG then print("RangeDisplay: entered range mode") end
end

local function LeaveRangeMode()
    ClearOwnTile()
    if g_weSetMode then
        g_weSetMode = false
        if UI.GetInterfaceMode() == RANGE_MODE then
            UI.SetInterfaceMode(SELECT_MODE)
        end
    end
end

------------------------------------------------------------
-- Events
------------------------------------------------------------
Events.UnitSelectionChanged.Add(function(playerID, unitID, i, j, k, isSelected)
    g_airWait = 0
    g_airForce = false
    ClearAirRange(true)
    LeaveRangeMode()
    if not isSelected then return end
    if playerID ~= Game.GetActivePlayer() then return end

    local unit = Players[playerID]:GetUnitByID(unitID)
    if not unit then return end

    -- Aircraft: red circle + targets only, never ranged attack mode
    if IsAirUnit(unit) then
        RequestAirRefresh(true, AIR_SELECT_DELAY)
        return
    end

    if not Players[playerID]:IsTurnActive() then return end
    if not IsRangedUnit(unit) or not CanShowFor(unit) then return end

    if HasTargetInRange(unit) then
        EnterRangeMode(unit)
    elseif DEBUG then
        print("RangeDisplay: no target in range, staying in normal mode")
    end
end)

-- Keep the aircraft display in sync (rebase, enemy moves into/out of range)
Events.SerialEventUnitInfoDirty.Add(function()
    local unit = UI.GetHeadSelectedUnit()
    if IsAirUnit(unit) then
        RequestAirRefresh(not g_airShown, AIR_DIRTY_DELAY)
    elseif g_airShown then
        ClearAirRange(false)
    end
end)

Events.InterfaceModeChanged.Add(function(oldMode, newMode)
    if newMode ~= RANGE_MODE then
        ClearOwnTile()
        g_weSetMode = false
    end
end)

print("RangeDisplay: file loaded")