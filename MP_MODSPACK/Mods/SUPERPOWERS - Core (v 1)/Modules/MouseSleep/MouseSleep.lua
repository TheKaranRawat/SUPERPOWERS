-- Mouse button 5 (XBUTTON2, usually the "forward" side button) = Alert, or Sleep if Alert isn't available
local WM_XBUTTONDOWN = (MouseEvents and MouseEvents.XButtonDown) or 523  -- 0x020B
local XBUTTON2       = 2

-- Look up the action IDs once (the same actions the Unit Panel buttons use)
local ALERT_ACTION_ID, SLEEP_ACTION_ID
for i = 0, #GameInfoActions do
    local action = GameInfoActions[i]
    if action then
        local name = action.Type or action.MissionType
        if name == "MISSION_ALERT" or action.MissionType == "MISSION_ALERT" then
            ALERT_ACTION_ID = i
        elseif name == "MISSION_SLEEP" or action.MissionType == "MISSION_SLEEP" then
            SLEEP_ACTION_ID = i
        end
    end
end

local function AlertOrSleepSelectedUnit()
    local pPlayer = Players[Game.GetActivePlayer()]
    if not pPlayer or not pPlayer:IsTurnActive() then return false end

    local pUnit = UI.GetHeadSelectedUnit()
    if not pUnit or pUnit:GetOwner() ~= Game.GetActivePlayer() then return false end

    -- Prefer Alert when the unit can actually use it
    if ALERT_ACTION_ID and Game.CanHandleAction(ALERT_ACTION_ID) then
        -- Multiplayer-safe: same path the Unit Panel buttons use
        Game.HandleAction(ALERT_ACTION_ID)
        return true
    end

    -- Otherwise (settlers, workers, aircraft, etc.) put it to sleep
    if SLEEP_ACTION_ID and Game.CanHandleAction(SLEEP_ACTION_ID) then
        Game.HandleAction(SLEEP_ACTION_ID)
        return true
    end

    return false
end

local function OnInput(uiMsg, wParam, lParam)
    if uiMsg == WM_XBUTTONDOWN then
        -- Which X button is in the high word of wParam (Lua 5.1 has no bit ops)
        local whichButton = math.floor(wParam / 65536) % 65536
        if whichButton == XBUTTON2 then
            return AlertOrSleepSelectedUnit()  -- true = input consumed
        end
    end
    return false
end

ContextPtr:SetInputHandler(OnInput)