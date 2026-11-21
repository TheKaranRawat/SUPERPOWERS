-- MilitaryPopCost.lua
-- Human players lose population in a city whenever it creates a military unit.

---------------------------------------------------------------
-- CONFIG
---------------------------------------------------------------
local POP_COST            = 1      -- population removed per military unit
local MIN_CITY_POP        = 1      -- a city never drops below this size
local BLOCK_IF_TOO_SMALL  = true   -- hide units from the build list if the city can't afford the pop
local APPLY_TO_PURCHASED  = true   -- also charge when the unit is bought with gold/faith
local SHOW_NOTIFICATION   = true   -- tell the player when pop is deducted
---------------------------------------------------------------

-- Cache: is this unit type a military unit?
local militaryCache = {}

local function IsMilitaryType(unitType)
    local cached = militaryCache[unitType]
    if cached ~= nil then return cached end

    local info = GameInfo.Units[unitType]
    local result = false
    if info then
        result = ((info.Combat or 0) > 0 or (info.RangedCombat or 0) > 0)
    end
    militaryCache[unitType] = result
    return result
end

-- Only human players are affected
local function IsAffectedPlayer(playerID)
    local player = Players[playerID]
    return player ~= nil and player:IsHuman() and not player:IsBarbarian()
end

-- Charge population after a unit is created
local function OnCityTrained(playerID, cityID, unitID, bGold, bFaithOrCulture)
    if not IsAffectedPlayer(playerID) then return end
    if not APPLY_TO_PURCHASED and (bGold or bFaithOrCulture) then return end

    local player = Players[playerID]
    local unit   = player:GetUnitByID(unitID)
    if unit == nil or not IsMilitaryType(unit:GetUnitType()) then return end

    local city = player:GetCityByID(cityID)
    if city == nil then return end

    local pop    = city:GetPopulation()
    local deduct = math.min(POP_COST, pop - MIN_CITY_POP)
    if deduct <= 0 then return end

    city:ChangePopulation(-deduct, true)  -- true = reassign citizens automatically

    if SHOW_NOTIFICATION and playerID == Game.GetActivePlayer() then
        local unitInfo = GameInfo.Units[unit:GetUnitType()]
        local unitName = Locale.ConvertTextKey(unitInfo.Description)
        local text = string.format("%s lost %d population from training a %s.",
                                   city:GetName(), deduct, unitName)
        Events.GameplayAlertMessage(text)
    end
end

-- Prevent training/buying if the city is too small to pay the cost
local function OnCityCanTrain(playerID, cityID, unitType)
    if not BLOCK_IF_TOO_SMALL then return true end
    if not IsAffectedPlayer(playerID) then return true end
    if not IsMilitaryType(unitType) then return true end

    local city = Players[playerID]:GetCityByID(cityID)
    if city == nil then return true end

    return (city:GetPopulation() - POP_COST) >= MIN_CITY_POP
end

GameEvents.CityTrained.Add(OnCityTrained)
GameEvents.CityCanTrain.Add(OnCityCanTrain)