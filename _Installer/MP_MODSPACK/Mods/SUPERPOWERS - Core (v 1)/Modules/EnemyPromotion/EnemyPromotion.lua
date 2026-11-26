-- Grants PROMOTION_ENEMY_WAR_FURY to every military unit an AI city trains or buys. Gives 30% combat strength vs units/cities

local PROMO_ID = GameInfoTypes.PROMOTION_ENEMY_WAR_FURY
if PROMO_ID == nil then return end   -- DB entry failed to load; do nothing

local function IsMilitary(unit)
    if not unit:IsCombatUnit() then return false end
    local info = GameInfo.Units[unit:GetUnitType()]
    return info ~= nil and (info.Combat > 0 or info.RangedCombat > 0)
end

local function OnCityTrained(playerID, cityID, unitID)
    local player = Players[playerID]
    if player:IsHuman() then return end

    local unit = player:GetUnitByID(unitID)
    if unit and IsMilitary(unit) then
        -- Enemy (AI) military unit: grant War Fury (+25% combat strength).
        unit:SetHasPromotion(PROMO_ID, true)
    end
end

GameEvents.CityTrained.Add(OnCityTrained)