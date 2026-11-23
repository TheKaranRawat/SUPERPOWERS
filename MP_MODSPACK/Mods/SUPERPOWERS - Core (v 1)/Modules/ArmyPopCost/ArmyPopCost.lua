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
-- EXCLUSIONS (case-insensitive; must otherwise match the DB Type exactly)
---------------------------------------------------------------
local EXCLUDED_UNITS = {
    "UNIT_SCOUT",
    -- "UNIT_WORKBOAT",
}

local EXCLUDED_UNITCLASSES = {
    -- "UNITCLASS_ARCHER",
}

local EXCLUDED_DOMAINS = {
    -- "DOMAIN_AIR",
}
---------------------------------------------------------------

local function ToSet(list)
    local set = {}
    for _, name in ipairs(list) do
        set[string.upper(name)] = true
    end
    return set
end

local excludedUnits   = ToSet(EXCLUDED_UNITS)
local excludedClasses = ToSet(EXCLUDED_UNITCLASSES)
local excludedDomains = ToSet(EXCLUDED_DOMAINS)

---------------------------------------------------------------
-- PREBUILT LOOKUP: chargedTypes[unitTypeID] = true if charged.
-- Built once at load from the database, so it is identical on
-- every client and costs nothing at runtime.
---------------------------------------------------------------
local chargedTypes = {}

for row in GameInfo.Units() do
    local isMilitary = (row.Combat or 0) > 0 or (row.RangedCombat or 0) > 0
    if isMilitary
       and not excludedUnits[row.Type]
       and not (row.Class  and excludedClasses[row.Class])
       and not (row.Domain and excludedDomains[row.Domain]) then
        chargedTypes[row.ID] = true
    end
end

local MIN_POP_TO_TRAIN = POP_COST + MIN_CITY_POP

-- Only human players are affected (IsHuman is synced across clients)
local function IsAffectedPlayer(player)
    return player ~= nil and player:IsHuman()
end

---------------------------------------------------------------
-- Charge population after a unit is created
---------------------------------------------------------------
local function OnCityTrained(playerID, cityID, unitID, bGold, bFaithOrCulture)
    if not APPLY_TO_PURCHASED and (bGold or bFaithOrCulture) then return end

    local player = Players[playerID]
    if not IsAffectedPlayer(player) then return end

    local unit = player:GetUnitByID(unitID)
    if unit == nil then return end

    local unitType = unit:GetUnitType()
    if not chargedTypes[unitType] then return end

    local city = player:GetCityByID(cityID)
    if city == nil then return end

    local deduct = math.min(POP_COST, city:GetPopulation() - MIN_CITY_POP)
    if deduct <= 0 then return end

    city:ChangePopulation(-deduct, true)  -- true = reassign citizens automatically

    if SHOW_NOTIFICATION then
        -- Wrapped in pcall: a display problem must never interrupt gameplay logic.
        pcall(function()
            local unitName = Locale.ConvertTextKey(GameInfo.Units[unitType].Description)
            local text = string.format("%s lost %d population from training a %s.",
                                       city:GetName(), deduct, unitName)
            player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
                                   text, "Population lost",
                                   city:GetX(), city:GetY(), -1)
        end)
    end
end

---------------------------------------------------------------
-- Block training/buying if the city is too small.
-- This fires very often (every build-list refresh, AI checks),
-- so the cheapest checks come first.
---------------------------------------------------------------
local function OnCityCanTrain(playerID, cityID, unitType)
    if not chargedTypes[unitType] then return true end

    local player = Players[playerID]
    if not IsAffectedPlayer(player) then return true end

    local city = player:GetCityByID(cityID)
    if city == nil then return true end

    return city:GetPopulation() >= MIN_POP_TO_TRAIN
end

GameEvents.CityTrained.Add(OnCityTrained)

-- Don't register the hot-path handler at all if it isn't needed
if BLOCK_IF_TOO_SMALL then
    GameEvents.CityCanTrain.Add(OnCityCanTrain)
end