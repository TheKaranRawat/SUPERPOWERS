-- Mouse button 5 (XBUTTON2, usually the "forward" side button)
-- Priority: Heal, then Alert, then Sleep (first one the selected unit can use)
local WM_XBUTTONDOWN = (MouseEvents and MouseEvents.XButtonDown) or 523  -- 0x020B
local XBUTTON2       = 2

-- Actions to try, highest priority first
local ACTION_PRIORITY = { "MISSION_HEAL", "MISSION_ALERT", "MISSION_SLEEP" }

-- Look up the action IDs once (the same actions the Unit Panel buttons use)
local ACTION_IDS = {}
for i = 0, #GameInfoActions do
    local action = GameInfoActions[i]
    if action then
        for _, wanted in ipairs(ACTION_PRIORITY) do
            if action.Type == wanted or action.MissionType == wanted then
                ACTION_IDS[wanted] = i
            end
        end
    end
end

local function HealAlertOrSleepSelectedUnit()
    local pPlayer = Players[Game.GetActivePlayer()]
    if not pPlayer or not pPlayer:IsTurnActive() then return false end

    local pUnit = UI.GetHeadSelectedUnit()
    if not pUnit or pUnit:GetOwner() ~= Game.GetActivePlayer() then return false end

    for _, name in ipairs(ACTION_PRIORITY) do
        local id = ACTION_IDS[name]
        if id and Game.CanHandleAction(id) then
            -- Multiplayer-safe: same path the Unit Panel buttons use
            Game.HandleAction(id)
            return true
        end
    end

    return false
end

local function OnInput(uiMsg, wParam, lParam)
    if uiMsg == WM_XBUTTONDOWN then
        -- Which X button is in the high word of wParam (Lua 5.1 has no bit ops)
        local whichButton = math.floor(wParam / 65536) % 65536
        if whichButton == XBUTTON2 then
            return HealAlertOrSleepSelectedUnit()  -- true = input consumed
        end
    end
    return false
end

ContextPtr:SetInputHandler(OnInput)