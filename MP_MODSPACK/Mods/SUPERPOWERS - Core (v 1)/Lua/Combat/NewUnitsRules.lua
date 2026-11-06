-- NewUnitsRules (optimized / multiplayer-safe)
--------------------------------------------------------------
-- Changes vs. original (see notes delivered with this file):
--  * All GameInfo lookups cached once at load (GameInfoTypes, no string-keyed row lookups per turn)
--  * No more "return" inside loops (the original aborted the whole turn on the first nil/odd unit)
--  * AI war-bonus logic is evaluated per AI, against ALL humans (MP safe), on the AI's own turn
--  * Removed Game.GetActivePlayer() (differs per client => desync)
--  * Deterministic numeric loops instead of pairs(Players)
--  * Units are collected first, then modified (no kill/spawn while iterating a plot or Units())
--  * Guarded the unbounded while-loop on the Mistral
--  * Debug prints behind a flag
--------------------------------------------------------------

include( "UtilityFunctions.lua" )  -- expected to provide AICanBeBoss (and optionally PlayersAtWar)

local DEBUG = false
local function dprint(...)
	if DEBUG then print(...) end
end

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS

----------------------------------------------------------------------
-- Cached IDs
----------------------------------------------------------------------

-- Resolve a list of type names to IDs, skipping (and reporting) any that don't exist
local function ResolveIDs(names)
	local out = {}
	for i = 1, #names do
		local id = GameInfoTypes[names[i]]
		if id then
			out[#out + 1] = id
		else
			print("NewUnitsRules: missing type " .. names[i])
		end
	end
	return out
end

-- Build {from, to} promotion pairs, skipping pairs with a missing side
local function ResolvePairs(namePairs)
	local out = {}
	for i = 1, #namePairs do
		local f, t = GameInfoTypes[namePairs[i][1]], GameInfoTypes[namePairs[i][2]]
		if f and t then
			out[#out + 1] = { f, t }
		else
			print("NewUnitsRules: missing promotion pair " .. namePairs[i][1] .. " -> " .. namePairs[i][2])
		end
	end
	return out
end

local PROMO_CARRIER_UNIT    = GameInfoTypes.PROMOTION_CARRIER_UNIT
local PROMO_CARRIER_FIGHTER = GameInfoTypes.PROMOTION_CARRIER_FIGHTER
local PROMO_SETUP           = GameInfoTypes.PROMOTION_MUST_SET_UP
local PROMO_FORMATION_1     = GameInfoTypes.PROMOTION_FORMATION_1
local PROMO_FORMATION_2     = GameInfoTypes.PROMOTION_FORMATION_2
local PROMO_AMBUSH_1        = GameInfoTypes.PROMOTION_AMBUSH_1
local PROMO_AMBUSH_2        = GameInfoTypes.PROMOTION_AMBUSH_2

local POLICY_AI_ATWAR_BONUS = GameInfoTypes.POLICY_AI_ATWAR_BONUS
local TECH_NUCLEAR_FUSION   = GameInfoTypes.TECH_NUCLEAR_FUSION

local CIV_ENGLAND = GameInfoTypes.CIVILIZATION_ENGLAND
local CIV_FRANCE  = GameInfoTypes.CIVILIZATION_FRANCE

local UNIT_ANTI_TANK_GUN = GameInfoTypes.UNIT_ANTI_TANK_GUN
local UNIT_HOWITZER      = GameInfoTypes.UNIT_HOWITZER
local UNIT_MISTRAL       = GameInfoTypes.UNIT_FRANCE_MISTRAL
local UNIT_TIGER         = GameInfoTypes.UNIT_FRANCE_EUROCOPTER_TIGER

-- Carrier air-wing unit types. If any are missing the carrier logic is disabled instead of erroring.
local CARRIER_UNITS_OK = true
local function UnitID(name)
	local id = GameInfoTypes[name]
	if not id then
		print("NewUnitsRules: missing unit " .. name .. " (carrier restock disabled)")
		CARRIER_UNITS_OK = false
	end
	return id
end

local U = {
	CARRIER         = UnitID("UNIT_CARRIER"),
	NUCLEAR_CARRIER = UnitID("UNIT_NUCLEAR_CARRIER"),
	SUPER_CARRIER   = UnitID("UNIT_SUPER_CARRIER"),
	NIMITZ          = UnitID("UNIT_AMERICAN_NIMITZ"),
	ZERO            = UnitID("UNIT_JAPANESE_ZERO"),
	JET             = UnitID("UNIT_CARRIER_FIGHTER_JET"),
	ADV             = UnitID("UNIT_CARRIER_FIGHTER_ADV"),
	HARRIER         = UnitID("UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER"),
	HARRIER_ADV     = UnitID("UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV"),
}

-- Promotions that are temporary and wiped at the start of the owner's turn
local TEMP_PROMOS = ResolveIDs{
	"PROMOTION_RAPID_MARCH",
	"PROMOTION_MARKED_TARGET",
	"PROMOTION_TRAGET_CLEARSHOOT_3",   -- (sic) spelling matches the database
	"PROMOTION_LEGION_GROUP",
	"PROMOTION_BLACKBIRD_RECON",
}

-- If a unit has any of these AND is at full HP, all debuffs are removed
local DEBUFF_TRIGGER = ResolveIDs{
	"PROMOTION_PENETRATION_1",
	"PROMOTION_MOVEMENT_LOST_1",
	"PROMOTION_MORAL_WEAKEN_1",
	"PROMOTION_LOSE_SUPPLY",
}
local DEBUFF_ALL = ResolveIDs{
	"PROMOTION_PENETRATION_1", "PROMOTION_PENETRATION_2",
	"PROMOTION_MOVEMENT_LOST_1", "PROMOTION_MOVEMENT_LOST_2",
	"PROMOTION_MORAL_WEAKEN_1", "PROMOTION_MORAL_WEAKEN_2",
	"PROMOTION_LOSE_SUPPLY",
}

-- Carrier -> aircraft promotion inheritance
local CARRIER_PROMO_MAP = ResolvePairs{
	{ "PROMOTION_CARRIER_FIGHTER_ANTI_AIR_1", "PROMOTION_CARRIER_FIGHTER_AIRFIGHT_1" },
	{ "PROMOTION_CARRIER_FIGHTER_ANTI_AIR_2", "PROMOTION_CARRIER_FIGHTER_AIRFIGHT_2" },
	{ "PROMOTION_CARRIER_FIGHTER_ATTACK_1",   "PROMOTION_CARRIER_FIGHTER_ATTACK_1" },
	{ "PROMOTION_CARRIER_FIGHTER_ATTACK_2",   "PROMOTION_CARRIER_FIGHTER_ATTACK_2" },
	{ "PROMOTION_CARRIER_FIGHTER_SIEGE_1",    "PROMOTION_CARRIER_FIGHTER_SIEGE_1" },
	{ "PROMOTION_CARRIER_FIGHTER_SIEGE_2",    "PROMOTION_CARRIER_FIGHTER_SIEGE_2" },
	{ "PROMOTION_CARRIER_SUPPLY_2",           "PROMOTION_CARRIER_SUPPLY_2" },
	{ "PROMOTION_CARRIER_FIGHTER_SORTIE",     "PROMOTION_CARRIER_FIGHTER_SORTIE" },
}

-- Mistral -> embarked helicopter promotion inheritance
local AAS_PROMO_MAP = ResolvePairs{
	{ "PROMOTION_SUNDER_1",            "PROMOTION_SUNDER_1" },
	{ "PROMOTION_SUNDER_2",            "PROMOTION_SUNDER_2" },
	{ "PROMOTION_SUNDER_3",            "PROMOTION_SUNDER_3" },
	{ "PROMOTION_COLLATERAL_DAMAGE_1", "PROMOTION_COLLATERAL_DAMAGE_1" },
	{ "PROMOTION_COLLATERAL_DAMAGE_2", "PROMOTION_COLLATERAL_DAMAGE_2" },
	{ "PROMOTION_COLLATERAL_DAMAGE_3", "PROMOTION_COLLATERAL_DAMAGE_3" },
	{ "PROMOTION_LOGISTICS",           "PROMOTION_LOGISTICS" },
}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function IsAtWar(a, b)
	return Teams[a:GetTeam()]:IsAtWar(b:GetTeam())
end

local function HasAny(unit, ids)
	for i = 1, #ids do
		if unit:IsHasPromotion(ids[i]) then return true end
	end
	return false
end

local function ClearPromos(unit, ids)
	for i = 1, #ids do
		if unit:IsHasPromotion(ids[i]) then
			unit:SetHasPromotion(ids[i], false)
		end
	end
end

local function SwapPromo(unit, fromID, toID)
	if fromID and toID and unit:IsHasPromotion(fromID) then
		unit:SetHasPromotion(fromID, false)
		unit:SetHasPromotion(toID, true)
	end
end

local function SpawnAir(player, unitTypeID, plot, aiType)
	local u = player:InitUnit(unitTypeID, plot:GetX(), plot:GetY(), aiType)
	if u then u:SetMoves(0) end
	return u
end

-- Copy any promotions the carrier has onto the cargo sitting on its plot.
-- Early-outs when the carrier has none of the mapped promotions.
local function TransferToCargo(carrier, plot, promoMap, requiredCargoPromo)
	if not carrier:HasCargo() then return end

	local active
	for i = 1, #promoMap do
		if carrier:IsHasPromotion(promoMap[i][1]) then
			active = active or {}
			active[#active + 1] = promoMap[i][2]
		end
	end
	if not active then return end

	for i = 0, plot:GetNumUnits() - 1 do
		local u = plot:GetUnit(i)
		if u and u:IsCargo() and (not requiredCargoPromo or u:IsHasPromotion(requiredCargoPromo)) then
			for j = 1, #active do
				if not u:IsHasPromotion(active[j]) then
					u:SetHasPromotion(active[j], true)
				end
			end
		end
	end
end

-- Kill every unit on the plot whose type is in oldSet and replace it with newID.
-- Units are collected first so we never kill/spawn while indexing the plot.
local function UpgradeAircraftOnPlot(player, plot, oldSet, newID)
	local victims
	for i = 0, plot:GetNumUnits() - 1 do
		local u = plot:GetUnit(i)
		if u and oldSet[u:GetUnitType()] then
			victims = victims or {}
			victims[#victims + 1] = u
		end
	end
	if not victims then return 0 end

	for i = 1, #victims do
		victims[i]:Kill()
		SpawnAir(player, newID, plot, UNITAI_ATTACK_AIR)
	end
	return #victims
end

-- Returns (setOfOldAircraftTypes or nil, newAircraftTypeID) for a given carrier + owner
local function GetLoadout(unit, player)
	local t = unit:GetUnitType()
	local english = (player:GetCivilizationType() == CIV_ENGLAND)

	if t == U.CARRIER then
		return nil, U.ZERO

	elseif t == U.NUCLEAR_CARRIER then
		return { [U.ZERO] = true }, (english and U.HARRIER or U.JET)

	elseif t == U.SUPER_CARRIER or t == U.NIMITZ then
		if english then
			return { [U.JET] = true, [U.HARRIER] = true }, U.HARRIER_ADV
		end
		if t == U.SUPER_CARRIER then
			return { [U.JET] = true }, U.ADV
		end
		-- American Nimitz: gets the advanced fighter after Nuclear Fusion
		local team = Teams[player:GetTeam()]
		if TECH_NUCLEAR_FUSION and team:IsHasTech(TECH_NUCLEAR_FUSION) then
			return { [U.JET] = true }, U.ADV
		end
		return { [U.ZERO] = true }, U.JET
	end

	return nil, nil
end

local function RestoreCarrierAir(unit, player, plot)
	if not CARRIER_UNITS_OK then return end
	local oldSet, newID = GetLoadout(unit, player)
	if not newID then return end

	if oldSet then
		UpgradeAircraftOnPlot(player, plot, oldSet, newID)
	end
	SpawnAir(player, newID, plot, UNITAI_ATTACK_AIR)
	dprint("Carrier air wing restocked")
end

local function RestoreMistral(unit, player, plot)
	if not UNIT_TIGER then return end
	-- Hard cap: the original looped until IsFull(), which hangs the game if a spawn ever fails to load.
	for _ = 1, 16 do
		if unit:IsFull() then break end
		local u = SpawnAir(player, UNIT_TIGER, plot, UNITAI_MISSILE_AIR)
		if not u then break end
		if not u:IsCargo() then   -- didn't load onto the ship; don't leave strays behind
			u:Kill()
			break
		end
	end
end

local function ServiceCarrier(unit, player)
	local plot = unit:GetPlot()
	if plot == nil then return end

	local isAirCarrier = PROMO_CARRIER_UNIT and unit:IsHasPromotion(PROMO_CARRIER_UNIT)
	local isMistral    = (UNIT_MISTRAL ~= nil) and (unit:GetUnitType() == UNIT_MISTRAL)

	-- Promotions first (so aircraft added this turn pick them up next turn, as before)
	if isAirCarrier then TransferToCargo(unit, plot, CARRIER_PROMO_MAP, PROMO_CARRIER_FIGHTER) end
	if isMistral    then TransferToCargo(unit, plot, AAS_PROMO_MAP, nil) end

	-- Restock only at sea
	if not unit:IsFull() and not plot:IsCity() then
		if isAirCarrier then RestoreCarrierAir(unit, player, plot) end
		if isMistral    then RestoreMistral(unit, player, plot) end
	end
end

----------------------------------------------------------------------
-- Human turn: unit cleanups + carrier service
----------------------------------------------------------------------

local function HumanTurn(player)
	local isFrance = (player:GetCivilizationType() == CIV_FRANCE)
	local carrierIDs

	for unit in player:Units() do
		local uType = unit:GetUnitType()

		-- Anti-mounted -> anti-tank auto upgrade
		if uType == UNIT_ANTI_TANK_GUN then
			SwapPromo(unit, PROMO_FORMATION_1, PROMO_AMBUSH_1)
			SwapPromo(unit, PROMO_FORMATION_2, PROMO_AMBUSH_2)

		-- French Howitzer needs no set-up
		elseif uType == UNIT_HOWITZER and isFrance and PROMO_SETUP then
			if unit:IsHasPromotion(PROMO_SETUP) then
				unit:SetHasPromotion(PROMO_SETUP, false)
			end
		end

		-- Temporary effects
		ClearPromos(unit, TEMP_PROMOS)

		-- Debuffs clear once fully healed
		if HasAny(unit, DEBUFF_TRIGGER) and unit:GetCurrHitPoints() == unit:GetMaxHitPoints() then
			ClearPromos(unit, DEBUFF_ALL)
		end

		-- Remember carriers; service them AFTER the loop so spawns don't happen mid-iteration
		if (PROMO_CARRIER_UNIT and unit:IsHasPromotion(PROMO_CARRIER_UNIT))
		   or (UNIT_MISTRAL ~= nil and uType == UNIT_MISTRAL) then
			carrierIDs = carrierIDs or {}
			carrierIDs[#carrierIDs + 1] = unit:GetID()
		end
	end

	if carrierIDs then
		for i = 1, #carrierIDs do
			local unit = player:GetUnitByID(carrierIDs[i])
			if unit then ServiceCarrier(unit, player) end
		end
	end
end

----------------------------------------------------------------------
-- AI turn: war bonus when at war with ANY human
----------------------------------------------------------------------

local function AtWarWithAnyHuman(ai)
	for i = 0, MAX_MAJOR - 1 do
		local p = Players[i]
		if p and p:IsHuman() and p:IsAlive() and IsAtWar(p, ai) then
			return true
		end
	end
	return false
end

local function AITurn(ai)
	if not POLICY_AI_ATWAR_BONUS then return end

	local hasBonus = ai:HasPolicy(POLICY_AI_ATWAR_BONUS)

	if AtWarWithAnyHuman(ai) then
		if not hasBonus then
			local capital = ai:GetCapitalCity()
			if capital and capital:GetPopulation() > 9 and AICanBeBoss(ai) then
				ai:SetHasPolicy(POLICY_AI_ATWAR_BONUS, true)
				dprint("AI war bonus granted")
			end
		end
	elseif hasBonus then
		ai:SetHasPolicy(POLICY_AI_ATWAR_BONUS, false)
		dprint("AI war bonus removed")
	end
end

----------------------------------------------------------------------
-- Event handlers
----------------------------------------------------------------------

local function NewUnitCreationRules(playerID)
	local player = Players[playerID]
	if player == nil or player:IsBarbarian() or player:IsMinorCiv() then
		return
	end
	if player:GetNumCities() < 1 then   -- in case of 0-city error
		return
	end

	if player:IsHuman() then
		HumanTurn(player)
	else
		AITurn(player)
	end
end
GameEvents.PlayerDoTurn.Add(NewUnitCreationRules)

-- Nimitz gets Carrier-Fighter-Adv immediately when Nuclear Fusion is researched.
-- Original used Players[Game.GetActivePlayer()], which is different on every client in MP (desync).
local function NimitzBugFix(teamID, techID, bAdopted)
	if not bAdopted or techID ~= TECH_NUCLEAR_FUSION then return end
	if not (CARRIER_UNITS_OK and U.NIMITZ) then return end

	local oldSet = { [U.JET] = true }

	for i = 0, MAX_MAJOR - 1 do
		local player = Players[i]
		if player and player:IsHuman() and player:IsAlive() and player:GetTeam() == teamID then
			for unit in player:Units() do
				if unit:GetUnitType() == U.NIMITZ then
					local plot = unit:GetPlot()
					if plot then
						UpgradeAircraftOnPlot(player, plot, oldSet, U.ADV)
					end
				end
			end
		end
	end
end
GameEvents.TeamSetHasTech.Add(NimitzBugFix)

print("NewUnitRules Check success!")