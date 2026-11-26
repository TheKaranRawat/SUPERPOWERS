-- AIUnitThrottle.lua
local DEBUG                 = true   -- set false for release (no log output, no counting)
local INTERVAL              = 3
local COUNT_CITY_STATE_WARS = true
local ONLY_IN_OWN_BORDERS   = true

local Players, Teams, GameInfo, Game = Players, Teams, GameInfo, Game
local MAX_CIV          = GameDefines.MAX_CIV_PLAYERS
local ACTIVITY_MISSION = ActivityTypes.ACTIVITY_MISSION

local function Log(...)
    if DEBUG then print("[AIThrottle]", ...) end
end

local THROTTLE = {}
local loaded = 0
for _, typeName in ipairs({
    "UNIT_WORKER", "UNIT_WORKBOAT", "UNIT_SCOUT",
    "UNIT_ARCHAEOLOGIST", "UNIT_CARAVAN", "UNIT_CARGO_SHIP",
}) do
    local info = GameInfo.Units[typeName]
    if info then
        THROTTLE[info.ID] = true
        loaded = loaded + 1
    else
        Log("WARNING: unit type not found, skipped:", typeName)
    end
end

-- One-time startup report
Log("Loaded. Throttled unit types:", loaded, "| interval:", INTERVAL,
    "| own-borders only:", tostring(ONLY_IN_OWN_BORDERS))

local function IsAtWar(player)
    local team = Teams[player:GetTeam()]
    if team.GetAtWarCount then
        return team:GetAtWarCount(not COUNT_CITY_STATE_WARS) > 0
    end
    local myTeam = player:GetTeam()
    for i = 0, MAX_CIV - 1 do
        local other = Players[i]
        if other:IsAlive() and other:GetTeam() ~= myTeam
           and (COUNT_CITY_STATE_WARS or not other:IsMinorCiv())
           and team:IsAtWar(other:GetTeam()) then
            return true
        end
    end
    return false
end

function AIThrottle_PlayerDoTurn(playerID)
    local player = Players[playerID]
    if not player:IsAlive() or player:IsHuman()
       or player:IsBarbarian() or player:IsMinorCiv() then return end
    if player:GetNumUnits() == 0 then return end

    local turn = Game.GetGameTurn()

    if IsAtWar(player) then
        Log("Turn", turn, "| player", playerID, "- at war, full processing")
        return
    end

    local candidates, frozen, onMission, outsideBorders = 0, 0, 0, 0

    for unit in player:Units() do
        if THROTTLE[unit:GetUnitType()] then
            candidates = candidates + 1
            if (turn + unit:GetID()) % INTERVAL ~= 0 then
                if unit:GetActivityType() == ACTIVITY_MISSION then
                    onMission = onMission + 1
                elseif ONLY_IN_OWN_BORDERS and unit:GetPlot():GetOwner() ~= playerID then
                    outsideBorders = outsideBorders + 1
                else
                    unit:SetMoves(0)
                    frozen = frozen + 1
                end
            end
        end
    end

    Log("Turn", turn, "| player", playerID,
        "| throttle-type units:", candidates,
        "| frozen:", frozen,
        "| skipped (on mission):", onMission,
        "| skipped (outside borders):", outsideBorders)
end

GameEvents.PlayerDoTurn.Add(AIThrottle_PlayerDoTurn)
Log("PlayerDoTurn hook registered")