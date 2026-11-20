-- Mouse button 5 (XBUTTON2, usually the "forward" side button) = Alert
local WM_XBUTTONDOWN = (MouseEvents and MouseEvents.XButtonDown) or 523  -- 0x020B
local XBUTTON2       = 2

local function AlertSelectedUnit()
    local pPlayer = Players[Game.GetActivePlayer()]
    if not pPlayer or not pPlayer:IsTurnActive() then return false end

    local pUnit = UI.GetHeadSelectedUnit()
    if not pUnit or pUnit:GetOwner() ~= Game.GetActivePlayer() then return false end

    -- Alert only applies to military units
    if not pUnit:IsCombatUnit() then return false end

    -- Multiplayer-safe: goes through the net message queue like the Unit Panel does
    Game.SelectionListGameNetMessage(
        GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,
        GameInfoTypes.MISSION_ALERT,
        nil, nil, 0, false, false
    )
    return true
end

local function OnInput(uiMsg, wParam, lParam)
    if uiMsg == WM_XBUTTONDOWN then
        -- Which X button is in the high word of wParam (Lua 5.1 has no bit ops)
        local whichButton = math.floor(wParam / 65536) % 65536
        if whichButton == XBUTTON2 then
            return AlertSelectedUnit()  -- true = input consumed
        end
    end
    return false
end

ContextPtr:SetInputHandler(OnInput)