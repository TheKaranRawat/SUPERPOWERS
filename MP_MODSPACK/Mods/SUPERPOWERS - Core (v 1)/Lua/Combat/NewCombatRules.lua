-- New Combat Rules (optimized)
-- Changes vs. original: IDs cached once at load, no global leaks, debug prints
-- behind a flag, building-destruction tables, per-player notifications instead
-- of Events.GameplayAlertMessage (MP-safe), no API calls on possibly-dead units.

include( "UtilityFunctions.lua" )

----------------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------------
local DEBUG                 = false  -- print() writes to lua.log (disk I/O); keep off in release
local ENABLE_AI_CITY_CAPTURE = true  -- see note: this branch was unreachable in the original

local function dprint(...)
	if DEBUG then print(...) end
end

----------------------------------------------------------------------------
-- Cached IDs (resolved once at load, not on every combat)
----------------------------------------------------------------------------
local StgBomberID       = GameInfoTypes["PROMOTION_STRATEGIC_BOMBER"]
local EMPBomberID       = GameInfoTypes["PROMOTION_EMP_ATTACK"]
local NapalmBomb1ID     = GameInfoTypes["PROMOTION_NAPALMBOMB_1"]
local NapalmBomb2ID     = GameInfoTypes["PROMOTION_NAPALMBOMB_2"]
local NapalmBomb3ID     = GameInfoTypes["PROMOTION_NAPALMBOMB_3"]
local AirSiege1ID       = GameInfoTypes["PROMOTION_AIR_SIEGE_1"]
local AirSiege2ID       = GameInfoTypes["PROMOTION_AIR_SIEGE_2"]
local AirSiege3ID       = GameInfoTypes["PROMOTION_AIR_SIEGE_3"]
local AirTarget1ID      = GameInfoTypes["PROMOTION_AIR_TARGETING_1"]
local AirTarget2ID      = GameInfoTypes["PROMOTION_AIR_TARGETING_2"]
local AirTarget3ID      = GameInfoTypes["PROMOTION_AIR_TARGETING_3"]
local CarrierFighterID  = GameInfoTypes["PROMOTION_CARRIER_FIGHTER"]
local AirTargetCarrierID= GameInfoTypes["PROMOTION_CARRIER_FIGHTER_SIEGE_2"]
local SPForce2ID        = GameInfoTypes["PROMOTION_SP_FORCE_2"]
local KnightID          = GameInfoTypes["PROMOTION_KNIGHT_COMBAT"]
local TankID            = GameInfoTypes["PROMOTION_TANK_COMBAT"]
local AntiAirID         = GameInfoTypes["PROMOTION_ANTI_AIR"]
local DestroyerID       = GameInfoTypes["PROMOTION_DESTROYER_COMBAT"]
local CruiserID         = GameInfoTypes["PROMOTION_NAVAL_RANGED_CRUISER"]
local NuclearArtilleryID= GameInfoTypes["PROMOTION_NUCLEAR_ARTILLERY"]
local PillageFreeID     = GameInfoTypes["PROMOTION_CITY_PILLAGE_FREE"]

local BombShelterID     = GameInfoTypes["BUILDING_BOMB_SHELTER"]
local TechComputersID   = GameInfoTypes["TECH_COMPUTERS"]

local UnitBazookaID     = GameInfoTypes["UNIT_BAZOOKA"]
local UnitMirage2000ID  = GameInfoTypes["UNIT_FRANCE_MIRRAGE2000"]
local UnitTempCaptureID = GameInfoTypes["UNIT_ROMAN_LEGION"]

local CombatFighterID   = GameInfoTypes["UNITCOMBAT_FIGHTER"]
local CombatGunID       = GameInfoTypes["UNITCOMBAT_GUN"]

-- Resolve a list of building type names to IDs once. Missing names are skipped
-- instead of crashing the whole script.
local function BuildingIDs(names)
	local ids = {}
	for _, name in ipairs(names) do
		local id = GameInfoTypes[name]
		if id then
			ids[#ids + 1] = id
		else
			print("NewCombatRules: unknown building " .. name)
		end
	end
	return ids
end

-- Priority order = order of destruction (first one found is removed)
local SiegeLv1Buildings = BuildingIDs({
	"BUILDING_MILITARY_BASE", "BUILDING_SHIPYARD", "BUILDING_ARSENAL", "BUILDING_BARRACKS",
})
local SiegeLv2Buildings = BuildingIDs({
	"BUILDING_FUSION_PLANT", "BUILDING_NUCLEAR_PLANT_EXTEND", "BUILDING_NUCLEAR_PLANT",
	"BUILDING_COAL_PLANT_EXTEND", "BUILDING_COAL_PLANT", "BUILDING_WIND_PLANT",
	"BUILDING_HYDRO_PLANT", "BUILDING_OIL_PLANT", "BUILDING_GAS_PLANT", "BUILDING_TIDAL_PLANT",
})
local SiegeLv3Buildings = BuildingIDs({
	"BUILDING_SPACESHIP_FACTORY", "BUILDING_FACTORY",
	"BUILDING_STEEL_MILL", "BUILDING_OIL_REFINERY",
	"BUILDING_MINGING_FACTORY", "BUILDING_INLAND_CANAL", "BUILDING_METAL_FACTORY",
})

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------
local function HasPromo(pUnit, iPromo)
	return iPromo ~= nil and pUnit:IsHasPromotion(iPromo)
end

-- Removes the first real (non-free) building found in the list.
local function DestroyFirstBuilding(pCity, idList)
	for i = 1, #idList do
		local id = idList[i]
		if pCity:GetNumRealBuilding(id) > 0 then
			pCity:SetNumRealBuilding(id, 0)
			return true
		end
	end
	return false
end

-- Per-player notification. Unlike Events.GameplayAlertMessage (local UI event that
-- shows on EVERY client in MP), this only reaches the intended player.
local function Notify(pPlayer, sKey, x, y, ...)
	if pPlayer and pPlayer:IsHuman() then
		local text = Locale.ConvertTextKey(sKey, ...)
		pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, text, x, y)
	end
end

----------------------------------------------------------------------------
-- Air sweep: fighters damage AA / destroyer / cruiser defenders
----------------------------------------------------------------------------
local function DoAirSweep(pAttackingPlayer, pAttackingUnit, pDefendingPlayer, pDefendingUnit, x, y)
	if not (HasPromo(pDefendingUnit, AntiAirID) or HasPromo(pDefendingUnit, DestroyerID) or HasPromo(pDefendingUnit, CruiserID)) then
		return
	end

	local myDamage = pAttackingUnit:GetRangeCombatDamage(pDefendingUnit, nil, false)
	local theirDamage
	if pDefendingUnit:IsRanged() then
		-- NOTE: original passed pDefendingUnit as its own target here (typo); fixed to attacker.
		theirDamage = math.floor(pDefendingUnit:GetRangeCombatDamage(pAttackingUnit, nil, false) * 0.5)
	else
		theirDamage = math.floor(myDamage * 0.25)
	end

	-- Decide outcomes from numbers BEFORE applying damage, so we never query a unit that just died.
	local attName = pAttackingUnit:GetName()
	local defName = pDefendingUnit:GetName()
	local attDead = (pAttackingUnit:GetDamage() + theirDamage) >= pAttackingUnit:GetMaxHitPoints()
	local defDead = (pDefendingUnit:GetDamage() + myDamage)    >= pDefendingUnit:GetMaxHitPoints()

	pDefendingUnit:ChangeDamage(myDamage, pAttackingPlayer)
	pAttackingUnit:ChangeDamage(theirDamage, pDefendingPlayer)

	if attDead then
		Notify(pAttackingPlayer, "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_BY_ENEMY",    x, y, attName)
		Notify(pDefendingPlayer, "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_ENEMY_FIGHTER", x, y, attName)
		return
	end

	pAttackingUnit:ChangeExperience(4)
	Notify(pAttackingPlayer, "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_TO_ENEMY", x, y, tostring(myDamage), defName)

	if defDead then
		Notify(pAttackingPlayer, "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_ENEMY_AA",   x, y, defName)
		Notify(pDefendingPlayer, "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_AA_KILLED_BY_ENEMY", x, y, defName)
	else
		pDefendingUnit:ChangeExperience(2)
		Notify(pDefendingPlayer, "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_BY_ENEMY", x, y, defName, tostring(myDamage))
	end

	dprint("Air Sweep damage dealt/received:", myDamage, theirDamage)
end

----------------------------------------------------------------------------
-- Main combat handler
----------------------------------------------------------------------------
function RangedUnitRules(iAttackingPlayer, iAttackingUnit, attackerDamage, attackerFinalDamage, attackerMaxHP, iDefendingPlayer, iDefendingUnit, defenderDamage, defenderFinalDamage, defenderMaxHP, iInterceptingPlayer, iInterceptingUnit, interceptorDamage, plotX, plotY)

	print("New Combat Rules Check Pass!")
	print("COMBAT END FIRED!")
	-- Cheap validation first
	local pAttackingPlayer = Players[iAttackingPlayer]
	if not pAttackingPlayer then return end

	local pDefendingPlayer = Players[iDefendingPlayer]
	if not pDefendingPlayer then return end

	local pAttackingUnit = pAttackingPlayer:GetUnitByID(iAttackingUnit)
	if not pAttackingUnit or pAttackingUnit:IsDead() then return end -- attacker died: no effects

	local pDefendedPlot = Map.GetPlot(plotX, plotY)
	if not pDefendedPlot then return end

	local pDefendingUnit = pDefendingPlayer:GetUnitByID(iDefendingUnit) -- nil when a city was attacked
	local pDefendedCity  = pDefendedPlot:GetPlotCity()                  -- nil if no city on plot

	----------------------------------------------------------------------
	-- AI vs AI: larger AI can take smaller AI's city by ranged attack
	----------------------------------------------------------------------
	local bAttackerHuman = pAttackingPlayer:IsHuman()
	local bDefenderHuman = pDefendingPlayer:IsHuman()

	if not bAttackerHuman and not bDefenderHuman then
		-- NOTE: the original returned early when pDefendingUnit was nil, which made the
		-- capture branch below unreachable (a city attack always has nil defender unit).
		if ENABLE_AI_CITY_CAPTURE and not pDefendingUnit and pDefendedCity and pAttackingUnit:IsRanged() then
			-- cheap checks first, AICanBeBoss last (likely the most expensive call)
			if pDefendedCity:GetDamage() >= 80
				and defenderFinalDamage < pDefendedCity:GetMaxHitPoints()
				and pDefendedCity:GetPopulation() < 15
				and not AICanBeBoss(pDefendingPlayer)
			then
				local pTemp = pAttackingPlayer:InitUnit(UnitTempCaptureID, plotX, plotY, UNITAI_ATTACK)
				if pTemp then pTemp:Kill() end
				dprint("AI ranged unit took another AI's city")
			end
		end
		return
	end

	if pAttackingPlayer:IsBarbarian() then return end -- nothing below applies to barbarians

	local iAttUnitType   = pAttackingUnit:GetUnitType()
	local iAttCombatType = pAttackingUnit:GetUnitCombatType()

	----------------------------------------------------------------------
	-- Strategic bomber vs city: population loss + building destruction
	----------------------------------------------------------------------
	if not pDefendingUnit and pDefendedCity and HasPromo(pAttackingUnit, StgBomberID) then
		local cityPop = pDefendedCity:GetPopulation()

		if cityPop > 1 then
			-- Original had three identical blocks (Lv1/Lv2/Lv3-or-Nuclear), each applying
			-- floor(pop * rate) from the same starting pop. Same result, computed once.
			local levels = 0
			if HasPromo(pAttackingUnit, NapalmBomb1ID) then levels = levels + 1 end
			if HasPromo(pAttackingUnit, NapalmBomb2ID) then levels = levels + 1 end
			if HasPromo(pAttackingUnit, NapalmBomb3ID) or HasPromo(pAttackingUnit, NuclearArtilleryID) then levels = levels + 1 end

			if levels > 0 then
				local rate = (BombShelterID and pDefendedCity:IsHasBuilding(BombShelterID)) and 0.05 or 0.1
				local loss = math.floor(cityPop * rate) * levels
				if loss > 0 then
					pDefendedCity:ChangePopulation(-loss, true)
				end
			end
		end

		if HasPromo(pAttackingUnit, AirSiege1ID) then DestroyFirstBuilding(pDefendedCity, SiegeLv1Buildings) end
		if HasPromo(pAttackingUnit, AirSiege2ID) then DestroyFirstBuilding(pDefendedCity, SiegeLv2Buildings) end
		if HasPromo(pAttackingUnit, AirSiege3ID) then DestroyFirstBuilding(pDefendedCity, SiegeLv3Buildings) end
	end

	----------------------------------------------------------------------
	-- Attack aircraft: damage every unit inside the attacked city
	----------------------------------------------------------------------
	if pDefendedCity and (HasPromo(pAttackingUnit, AirTarget1ID) or HasPromo(pAttackingUnit, AirTargetCarrierID)) then
		local dmg = 20
		if HasPromo(pAttackingUnit, AirTarget2ID) then dmg = dmg + 10 end
		if HasPromo(pAttackingUnit, AirTarget3ID) then dmg = dmg + 10 end

		-- Iterate backwards: units can die (and leave the plot) while we damage them.
		for i = pDefendedPlot:GetNumUnits() - 1, 0, -1 do
			local pFoundUnit = pDefendedPlot:GetUnit(i)
			if pFoundUnit and pFoundUnit:GetOwner() ~= iAttackingPlayer then
				pFoundUnit:ChangeDamage(dmg, pAttackingPlayer)
			end
		end
	end

	----------------------------------------------------------------------
	-- EMP bomber: resistance turns on cities of players with Computers
	-- (original did `return` here for no-tech targets, skipping every rule below)
	----------------------------------------------------------------------
	if pDefendedCity and HasPromo(pAttackingUnit, EMPBomberID) then
		local pTeam = Teams[pDefendingPlayer:GetTeam()]
		if TechComputersID and pTeam:IsHasTech(TechComputersID) then
			pDefendedCity:ChangeResistanceTurns(1)
		end
	end

	----------------------------------------------------------------------
	-- Special forces sabotage
	----------------------------------------------------------------------
	if pDefendedCity and HasPromo(pAttackingUnit, SPForce2ID) then
		pDefendedCity:ChangeResistanceTurns(1)
		if pDefendedCity:GetGarrisonedUnit() == nil then
			pDefendedCity:SetDamage(math.min(250, pDefendedCity:GetMaxHitPoints()))
		end
	end

	----------------------------------------------------------------------
	-- Heavy knight / tank attacking a city lose all moves
	----------------------------------------------------------------------
	if pDefendedCity and (HasPromo(pAttackingUnit, KnightID) or HasPromo(pAttackingUnit, TankID)) then
		if not HasPromo(pAttackingUnit, PillageFreeID) then
			pAttackingUnit:SetMoves(0)
		end
	end

	----------------------------------------------------------------------
	-- Carrier-based aircraft pass EXP to their carrier
	----------------------------------------------------------------------
	if HasPromo(pAttackingUnit, CarrierFighterID) then
		local exp = pAttackingUnit:GetExperience()
		if exp > 0 then
			local pCarrier = pAttackingUnit:GetTransportUnit()
			if pCarrier then
				pCarrier:ChangeExperience(exp)
				pAttackingUnit:SetExperience(0)
			end
		end
	end

	----------------------------------------------------------------------
	-- Fighter air sweep
	----------------------------------------------------------------------
	if (iAttCombatType == CombatFighterID or iAttUnitType == UnitMirage2000ID)
		and pDefendingUnit and not pDefendingUnit:IsDead()
	then
		DoAirSweep(pAttackingPlayer, pAttackingUnit, pDefendingPlayer, pDefendingUnit, plotX, plotY)
	end

	----------------------------------------------------------------------
	-- Special forces (GUN) capture a fully-damaged city
	-- (the original's RECON half of this block was fully commented out)
	----------------------------------------------------------------------
	if iAttCombatType == CombatGunID and pDefendedCity
		and pDefendedCity:GetDamage() >= pDefendedCity:GetMaxHitPoints()
	then
		local pTemp = pAttackingPlayer:InitUnit(UnitTempCaptureID, plotX, plotY, UNITAI_ATTACK)
		if pTemp then pTemp:Kill() end
		pAttackingUnit:SetXY(plotX, plotY)
		dprint("Special Forces took the city")
	end

	----------------------------------------------------------------------
	-- Ranged fire on a nearly-dead city kills population
	----------------------------------------------------------------------
	if pDefendedCity and iAttCombatType ~= CombatFighterID and pAttackingUnit:IsRanged() then
		local iMaxHP = pDefendedCity:GetMaxHitPoints()
		if pDefendedCity:GetDamage() >= iMaxHP - 1 and defenderFinalDamage < iMaxHP then
			local cityPop = pDefendedCity:GetPopulation()
			if cityPop > 1 then
				pDefendedCity:SetPopulation(cityPop - 1, true)

				local pOwner = Players[pDefendedCity:GetOwner()]
				if pOwner and pOwner:IsHuman() then
					local text    = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CITY_POPULATION_LOST_BY_RANGEDFIRE", pAttackingUnit:GetName(), pDefendedCity:GetName())
					local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CITY_POPULATION_LOST_BY_RANGEDFIRE_SHORT")
					pOwner:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, plotX, plotY)
				end
			end
		end
	end

	----------------------------------------------------------------------
	-- One-shot launcher kills itself. Kept LAST so no rule above touches a dead unit.
	----------------------------------------------------------------------
	if iAttUnitType == UnitBazookaID then
		pAttackingUnit:ChangeDamage(100)
	end
end
GameEvents.CombatEnded.Add(RangedUnitRules)

GameEvents.CombatEnded.Add(function(...)
	print("CombatEnded fired:", ...)
end)

--[[
GameEvents.PlayerCityFounded.Add(function(...)
	print("CombatEnded fired:", ...)
end)
]]--

print("New Combat Rules Check Pass!")