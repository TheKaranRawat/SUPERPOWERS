-- AIUnitThrottle.lua
-- Add to the mod's files with VFS import, and register it as an InGameUIAddin.

local INTERVAL              = 4      -- process each throttled unit once per N turns
local COUNT_CITY_STATE_WARS = true   -- does a war with a city-state count as "at war"?
local ONLY_IN_OWN_BORDERS   = true   -- never freeze units out in the wild

local Players, Teams, GameInfo, Game = Players, Teams, GameInfo, Game
local MAX_CIV          = GameDefines.MAX_CIV_PLAYERS
local ACTIVITY_MISSION = ActivityTypes.ACTIVITY_MISSION

-- Build the lookup once at load: [unitTypeID] = true
local THROTTLE = {}
for _, typeName in ipairs({
    "UNIT_WORKER", "UNIT_WORKBOAT", "UNIT_SCOUT",
    "UNIT_ARCHAEOLOGIST", "UNIT_CARAVAN", "UNIT_CARGO_SHIP",
}) do
    local info = GameInfo.Units[typeName]
    if info then THROTTLE[info.ID] = true end
end

local function IsAtWar(player)
    local team = Teams[player:GetTeam()]
    -- Fast path: engine-side count, no Lua loop (barbarians are not counted)
    if team.GetAtWarCount then
        return team:GetAtWarCount(not COUNT_CITY_STATE_WARS) > 0
    end
    -- Fallback loop
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
    -- Cheapest rejections first
    if not player:IsAlive() or player:IsHuman()
       or player:IsBarbarian() or player:IsMinorCiv() then return end
    if player:GetNumUnits() == 0 or IsAtWar(player) then return end

    local turn = Game.GetGameTurn()
    for unit in player:Units() do
        if THROTTLE[unit:GetUnitType()]
           and (turn + unit:GetID()) % INTERVAL ~= 0              -- stagger
           and unit:GetActivityType() ~= ACTIVITY_MISSION then    -- idle only
            if not ONLY_IN_OWN_BORDERS or unit:GetPlot():GetOwner() == playerID then
                unit:SetMoves(0)
            end
        end
    end
end

GameEvents.PlayerDoTurn.Add(AIThrottle_PlayerDoTurn)