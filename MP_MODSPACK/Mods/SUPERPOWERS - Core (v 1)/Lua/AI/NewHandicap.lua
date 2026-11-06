-- New Handicap (optimized for performance + multiplayer determinism)
--
-- Design rules used throughout:
--   * Every game-event handler must give identical results on every client, so:
--       - no pairs() over Players (numeric loops in ascending ID order instead)
--       - no caches whose value depends on *when* they were filled (caches are
--         keyed on game state, so a reloaded/rejoining client gets the same answer)
--       - nothing is spawned or killed while iterating a live unit list
--   * Cheapest checks run first; DB lookups happen once at load, not per call.
--   * Missing DB entries never crash the script (original crashed at load if
--     any promotion/unit name was absent).

include("UtilityFunctions.lua")

local CONFIG = {
	-- Cache "final upgrade" unit type resolution per player (keyed on tech count).
	-- Set to false if your GetUpgradeUnit() depends on anything besides techs.
	CacheEscortUnitTypes = true,

	-- Optional safety valve: stop spawning free escorts once an AI owns this many
	-- military units. nil = unlimited (original behaviour).
	MaxMilitaryForFreeEscorts = nil,
}

local handicap = Game:GetHandicapType()
local MAX_MAJOR = (GameDefines and GameDefines.MAX_MAJOR_CIVS) or 22

---------------------------------------------------------------------
-- CACHES (all resolved once at load)
---------------------------------------------------------------------

local PROMO_NAMES = {
	Ranged = "PROMOTION_ARCHERY_COMBAT", CitySiege = "PROMOTION_CITY_SIEGE",
	LandAOE = "PROMOTION_SPLASH_DAMAGE", HitandRun = "PROMOTION_HITANDRUN",
	Heli = "PROMOTION_HELI_ATTACK", NavalHR = "PROMOTION_NAVAL_HIT_AND_RUN",
	NavalRanged = "PROMOTION_NAVAL_RANGED_SHIP", Sub = "PROMOTION_SUBMARINE_COMBAT",
	CapitalShip = "PROMOTION_NAVAL_CAPITAL_SHIP", Carrier = "PROMOTION_CARRIER_UNIT",
	SSBN = "PROMOTION_CARGO_IX", Bomber = "PROMOTION_STRATEGIC_BOMBER",
	AirAttack = "PROMOTION_AIR_ATTACK",
	Coll1 = "PROMOTION_COLLATERAL_DAMAGE_1", Coll2 = "PROMOTION_COLLATERAL_DAMAGE_2", Coll3 = "PROMOTION_COLLATERAL_DAMAGE_3",
	Barrage1 = "PROMOTION_BARRAGE_1", Barrage2 = "PROMOTION_BARRAGE_2", Barrage3 = "PROMOTION_BARRAGE_3",
	FireSup1 = "PROMOTION_FIRESUPPORT_UNIT_1", FireSup2 = "PROMOTION_FIRESUPPORT_UNIT_2",
	Sunder1 = "PROMOTION_SUNDER_1", Sunder2 = "PROMOTION_SUNDER_2", Sunder3 = "PROMOTION_SUNDER_3",
	AOE1 = "PROMOTION_CLUSTER_ROCKET_1", AOE2 = "PROMOTION_CLUSTER_ROCKET_2",
	CapArmor1 = "PROMOTION_ARMOR_BATTLESHIP_1", CapArmor2 = "PROMOTION_ARMOR_BATTLESHIP_2",
	Napalm1 = "PROMOTION_NAPALMBOMB_1", Napalm2 = "PROMOTION_NAPALMBOMB_2", Napalm3 = "PROMOTION_NAPALMBOMB_3",
	DestroySup1 = "PROMOTION_DESTROY_SUPPLY_1", DestroySup2 = "PROMOTION_DESTROY_SUPPLY_2",
	AirBomb1 = "PROMOTION_AIR_BOMBARDMENT_1", AirBomb2 = "PROMOTION_AIR_BOMBARDMENT_2", AirBomb3 = "PROMOTION_AIR_BOMBARDMENT_3",
	AirTarget1 = "PROMOTION_AIR_TARGETING_1", AirTarget2 = "PROMOTION_AIR_TARGETING_2", AirTarget3 = "PROMOTION_AIR_TARGETING_3",
	AIHitandRun = "PROMOTION_RANGE_REDUCE", AIRange = "PROMOTION_RANGE",
	SetUp = "PROMOTION_MUST_SET_UP", Embark = "PROMOTION_EMBARKATION",
}

-- A table (not ~50 locals) avoids Lua's 60-upvalue-per-function limit.
local P = {}
for key, name in pairs(PROMO_NAMES) do
	P[key] = GameInfoTypes[name]
end

-- Build an array of IDs, silently dropping any that don't exist in the DB.
local function IDList(...)
	local t, n = {}, 0
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then n = n + 1; t[n] = v end
	end
	return t
end

local LIST = {
	Bomber      = IDList(P.Napalm1, P.Napalm2, P.Napalm3, P.DestroySup1, P.DestroySup2),
	AirAttack   = IDList(P.AirBomb1, P.AirBomb2, P.AirBomb3, P.AirTarget1, P.AirTarget2, P.AirTarget3),
	CapitalShip = IDList(P.AOE1, P.AOE2, P.CapArmor1, P.CapArmor2),
	NavalRanged = IDList(P.Sunder1, P.Sunder2, P.Coll1, P.Coll2),
	NavalRangedLate = IDList(P.Coll3, P.Sunder3, P.AIRange),
	LandAOE     = IDList(P.AOE1, P.AOE2),
	HitandRun   = IDList(P.Sunder1, P.Sunder2, P.AIHitandRun),
	Heli        = IDList(P.Sunder1, P.Sunder2, P.Sunder3, P.AIRange),
	CitySiege   = IDList(P.Coll1),
	CitySiegeLate = IDList(P.Coll2, P.Coll3),
	Barrage     = IDList(P.Barrage1, P.Barrage2),
	BarrageLate = IDList(P.Barrage3, P.FireSup1, P.FireSup2),
}

local ConsumerResID    = GameInfoTypes["RESOURCE_CONSUMER"]
local ElectricityResID = GameInfoTypes["RESOURCE_ELECTRICITY"]
local ManPowerResID    = GameInfoTypes["RESOURCE_MANPOWER"]

local UNIT_WORKER      = GameInfoTypes["UNIT_WORKER"]
local UNIT_SETTLER     = GameInfoTypes["UNIT_SETTLER"]
local UNITCLASS_WORKER = GameInfoTypes["UNITCLASS_WORKER"]
local UNITCLASS_SETTLER = GameInfoTypes["UNITCLASS_SETTLER"]
local CIV_VENICE       = GameInfoTypes["CIVILIZATION_VENICE"]
local CIV_ENGLAND      = GameInfoTypes["CIVILIZATION_ENGLAND"]
local TECH_FUSION      = GameInfoTypes["TECH_NUCLEAR_FUSION"]

-- Unit AI types (works whether the DLL exposes them as globals or via UnitAITypes)
local AI_SETTLE      = UnitAITypes and UnitAITypes.UNITAI_SETTLE      or UNITAI_SETTLE
local AI_MISSILE_AIR = UnitAITypes and UnitAITypes.UNITAI_MISSILE_AIR or UNITAI_MISSILE_AIR
local AI_ATTACK_AIR  = UnitAITypes and UnitAITypes.UNITAI_ATTACK_AIR  or UNITAI_ATTACK_AIR
local AI_DEFENSE_AIR = UnitAITypes and UnitAITypes.UNITAI_DEFENSE_AIR or UNITAI_DEFENSE_AIR
local AI_ATTACK_SEA  = UnitAITypes and UnitAITypes.UNITAI_ATTACK_SEA  or UNITAI_ATTACK_SEA
local AI_ASSAULT_SEA = UnitAITypes and UnitAITypes.UNITAI_ASSAULT_SEA or UNITAI_ASSAULT_SEA
local AI_ATTACK      = UnitAITypes and UnitAITypes.UNITAI_ATTACK      or UNITAI_ATTACK
local AI_FAST_ATTACK = UnitAITypes and UnitAITypes.UNITAI_FAST_ATTACK or UNITAI_FAST_ATTACK

-- Carrier data
local UNIT_MISTRAL = GameInfoTypes["UNIT_FRANCE_MISTRAL"]
local UNIT_TIGER   = GameInfoTypes["UNIT_FRANCE_EUROCOPTER_TIGER"]
local U_CARRIER = GameInfoTypes["UNIT_CARRIER"]
local U_NIMITZ  = GameInfoTypes["UNIT_AMERICAN_NIMITZ"]
local U_NUCLEAR = GameInfoTypes["UNIT_NUCLEAR_CARRIER"]
local U_SUPER   = GameInfoTypes["UNIT_SUPER_CARRIER"]

local UNIT_CARRIER_TYPES = {}   -- nil-safe (original errored at load if any name was missing)
for _, id in ipairs({ U_CARRIER or -1, U_NIMITZ or -1, U_NUCLEAR or -1, U_SUPER or -1 }) do
	if id ~= -1 then UNIT_CARRIER_TYPES[id] = true end
end

local AIR = {
	Zero      = GameInfoTypes["UNIT_JAPANESE_ZERO"],
	Jet       = GameInfoTypes["UNIT_CARRIER_FIGHTER_JET"],
	Adv       = GameInfoTypes["UNIT_CARRIER_FIGHTER_ADV"],
	Harrier   = GameInfoTypes["UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER"],
	HarrierAdv = GameInfoTypes["UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV"],
}

-- Unit CLASSES of every carrier-like unit. player:GetUnitClassCount() is O(1), so we
-- can skip walking an AI's whole unit list on turns where it owns no carrier at all.
local CARRIER_CLASS_IDS = {}
do
	local seen = {}
	local function addClassOf(unitTypeID)
		if unitTypeID == nil then return end
		local info = GameInfo.Units[unitTypeID]
		if info and info.Class then
			local classID = GameInfoTypes[info.Class]
			if classID ~= nil and not seen[classID] then
				seen[classID] = true
				CARRIER_CLASS_IDS[#CARRIER_CLASS_IDS + 1] = classID
			end
		end
	end
	addClassOf(UNIT_MISTRAL)
	for typeID in pairs(UNIT_CARRIER_TYPES) do addClassOf(typeID) end
end

---------------------------------------------------------------------
-- SMALL HELPERS
---------------------------------------------------------------------

local function HasPromo(unit, id)
	return id ~= nil and unit:IsHasPromotion(id)
end

-- Only call SetHasPromotion when it actually changes something
local function GivePromos(unit, list)
	for i = 1, #list do
		local id = list[i]
		if not unit:IsHasPromotion(id) then
			unit:SetHasPromotion(id, true)
		end
	end
end

local function GivePromo(unit, id)
	if id ~= nil and not unit:IsHasPromotion(id) then
		unit:SetHasPromotion(id, true)
	end
end

local function RemovePromo(unit, id)
	if id ~= nil and unit:IsHasPromotion(id) then
		unit:SetHasPromotion(id, false)
	end
end

-- Delayed kill is safer inside event callbacks (unit isn't torn down mid-callback).
-- If your DLL's Kill() signature differs, change it here only.
local function KillUnit(unit)
	unit:Kill(true, -1)
end

---------------------------------------------------------------------
-- AI ERA BONUS (NOT REGISTERED - kept for reference, original was disabled for desync risk)
---------------------------------------------------------------------

local ERA_POLICIES = {
	[2] = "POLICY_AI_MEDIEVAL", [3] = "POLICY_AI_RENAISSANCE", [4] = "POLICY_AI_INDUSTRY",
	[5] = "POLICY_AI_MODERN",   [6] = "POLICY_AI_WORLDWAR",    [7] = "POLICY_AI_ATOMIC",
	[8] = "POLICY_AI_INFORMATION",
}

function AIEraBonus(iCounter)
	local policyID = ERA_POLICIES[iCounter] and GameInfoTypes[ERA_POLICIES[iCounter]]
	if policyID == nil then return end
	for id = 0, MAX_MAJOR - 1 do
		local player = Players[id]
		if player ~= nil and player:IsAlive() and not player:IsHuman() and player:GetNumCities() > 1 then
			player:SetHasPolicy(policyID, true)
		end
	end
end

---------------------------------------------------------------------
-- AI BONUS WHEN HUMAN EXPANDS
---------------------------------------------------------------------

local CITY_TIERS = {   -- ordered highest -> lowest; first match wins
	{ abs = 36, div = 3,  policy = GameInfoTypes["POLICY_AI_PLAYER_CITIES_30"] },
	{ abs = 30, div = 5,  policy = GameInfoTypes["POLICY_AI_PLAYER_CITIES_20"] },
	{ abs = 22, div = 8,  policy = GameInfoTypes["POLICY_AI_PLAYER_CITIES_10"] },
	{ abs = 12, div = 10, policy = GameInfoTypes["POLICY_AI_PLAYER_CITIES_6"] },
}

local function GiveSettlerIfNeeded(player)
	if UNIT_SETTLER == nil or UNITCLASS_SETTLER == nil then return end
	if player:GetUnitClassCount(UNITCLASS_SETTLER) >= 1 or player:GetCurrentEra() > 6 then return end
	local capital = player:GetCapitalCity()
	if capital == nil then return end
	local newUnit = player:InitUnit(UNIT_SETTLER, capital:GetX(), capital:GetY(), AI_SETTLE)
	if newUnit ~= nil then
		GivePromo(newUnit, P.Embark)
		newUnit:JumpToNearestValidPlot()
	end
end

function AIBonusByPlayer(humanCities, worldCities)
	-- Work out the tier ONCE, not once per AI
	local tierPolicy = nil
	if not (humanCities >= 40 or humanCities >= worldCities / 2) then   -- "unstoppable": no extra help
		for i = 1, #CITY_TIERS do
			local t = CITY_TIERS[i]
			if humanCities >= t.abs or humanCities >= worldCities / t.div then
				tierPolicy = t.policy
				break
			end
		end
	end

	for id = 0, MAX_MAJOR - 1 do   -- fixed ascending order = deterministic
		local player = Players[id]
		if player ~= nil and player:IsAlive() and not player:IsHuman()
			and player:GetCivilizationType() ~= CIV_VENICE then

			GiveSettlerIfNeeded(player)

			if tierPolicy ~= nil and not player:HasPolicy(tierPolicy) and AICanBeBoss(player) then
				player:SetHasPolicy(tierPolicy, true)
			end
		end
	end
end

-- NOTE: GameEvents.PlayerCityFounded passes (playerID, x, y). The original handler used
-- the old Events.SerialEventCityCreated signature (hexPos, playerID, cityID), so it was
-- reading the city's X coordinate as a player ID. If your DLL really passes something
-- else, adjust here.
function AIBonusWhenPlayerExpand(playerID, iX, iY)
	if playerID == nil or playerID >= MAX_MAJOR then return end
	local founder = Players[playerID]
	if founder == nil or not founder:IsHuman() then return end

	local humanCities = founder:GetNumCities()
	if humanCities > 1 then
		AIBonusByPlayer(humanCities, Game.GetNumCities())
	end
end
GameEvents.PlayerCityFounded.Add(AIBonusWhenPlayerExpand)

---------------------------------------------------------------------
-- AI UNITS ASSIST: resources + carrier air-wing resupply
---------------------------------------------------------------------

local function GetCarrierAirUnit(player, uType)
	if uType == U_CARRIER then
		return AIR.Zero
	elseif uType == U_NIMITZ then
		if TECH_FUSION ~= nil and Teams[player:GetTeam()]:IsHasTech(TECH_FUSION) then
			return AIR.Adv
		end
		return AIR.Jet
	elseif uType == U_NUCLEAR then
		if player:GetCivilizationType() == CIV_ENGLAND then return AIR.Harrier end
		return AIR.Jet
	elseif uType == U_SUPER then
		if player:GetCivilizationType() == CIV_ENGLAND then return AIR.HarrierAdv end
		return AIR.Adv
	end
	return nil
end

local function PlayerHasAnyCarrier(player)
	local n = #CARRIER_CLASS_IDS
	if n == 0 then return true end   -- couldn't resolve classes: fall back to scanning
	for i = 1, n do
		if player:GetUnitClassCount(CARRIER_CLASS_IDS[i]) > 0 then return true end
	end
	return false
end

function AIUnitsAssist(playerID)
	if playerID == nil or playerID >= MAX_MAJOR then return end   -- minors / barbarians
	local player = Players[playerID]
	if player == nil or player:IsHuman() or not player:IsAlive() then return end
	if player:GetNumCities() < 1 then return end

	-- Extra resources (AICanBeBoss only evaluated if something is actually needed)
	local needElectricity = ElectricityResID ~= nil and player:GetCurrentEra() >= 5
		and player:GetNumResourceAvailable(ElectricityResID, true) <= 0
	local needManpower = ManPowerResID ~= nil
		and player:GetNumResourceAvailable(ManPowerResID, true) <= 0

	if needElectricity or needManpower then
		if AICanBeBoss(player) then
			if needElectricity then player:ChangeNumResourceTotal(ElectricityResID, 1) end
			if needManpower then player:ChangeNumResourceTotal(ManPowerResID, 1) end
		end
	end

	if ConsumerResID ~= nil and player:GetNumResourceAvailable(ConsumerResID, true) <= 0 then
		player:ChangeNumResourceTotal(ConsumerResID, 2)
	end

	-- Carrier resupply: skip the unit scan entirely when no carrier exists
	if not PlayerHasAnyCarrier(player) then return end

	-- Pass 1: collect (never spawn while iterating the live unit list)
	local types, xs, ys, count = {}, {}, {}, 0
	for unit in player:Units() do
		local uType = unit:GetUnitType()
		if uType == UNIT_MISTRAL or (UNIT_CARRIER_TYPES[uType] and HasPromo(unit, P.Carrier)) then
			if not unit:IsFull() then
				local plot = unit:GetPlot()
				if plot ~= nil and not plot:IsCity() then
					count = count + 1
					types[count] = uType
					xs[count] = plot:GetX()
					ys[count] = plot:GetY()
				end
			end
		end
	end

	-- Pass 2: spawn
	for i = 1, count do
		local uType = types[i]
		if uType == UNIT_MISTRAL then
			if UNIT_TIGER ~= nil then
				for _ = 1, 4 do
					player:InitUnit(UNIT_TIGER, xs[i], ys[i], AI_MISSILE_AIR)
				end
			end
		else
			local airType = GetCarrierAirUnit(player, uType)
			if airType ~= nil then
				player:InitUnit(airType, xs[i], ys[i], AI_ATTACK_AIR)
			end
		end
	end
end
GameEvents.PlayerDoTurn.Add(AIUnitsAssist)

---------------------------------------------------------------------
-- FREE ESCORT UNITS
-- (original globals kept as thin wrappers in case other files call them)
---------------------------------------------------------------------

function AINewUnitSetUp(NewUnit, NewUnitEXP)
	if NewUnit == nil then return end
	NewUnit:SetExperience(NewUnitEXP)
	local domain = NewUnit:GetDomainType()
	if domain == DomainTypes.DOMAIN_LAND or domain == DomainTypes.DOMAIN_SEA then
		NewUnit:JumpToNearestValidPlot()
	end
end

local ESCORT = {
	Air      = { class = "UNITCLASS_TRIPLANE",        exp = 20, ai = AI_DEFENSE_AIR },
	NavalEsc = { class = "UNITCLASS_GALLEASS",        exp = 5,  ai = AI_ATTACK_SEA  },
	NavalHR  = { class = "UNITCLASS_FIRE_SHIP",       exp = 15, ai = AI_ASSAULT_SEA },
	Infantry = { class = "UNITCLASS_SWORDSMAN",       exp = 5,  ai = AI_ATTACK      },
	Mobile   = { class = "UNITCLASS_HORSEMAN",        exp = 10, ai = AI_FAST_ATTACK },
	LandHR   = { class = "UNITCLASS_MEDIEVAL_CHARIOT", exp = 25, ai = AI_FAST_ATTACK },
}

-- Resolving "civ-specific unit -> newest upgrade" walks the DB every call. The answer only
-- changes when the player's techs change, so key the cache on tech count. Because the key
-- is derived from game state (not from "when we last looked"), every client agrees,
-- including ones that load a save mid-turn.
local escortCache = {}

local function ResolveEscortType(player, className)
	local techCount
	if CONFIG.CacheEscortUnitTypes then
		techCount = Teams[player:GetTeam()]:GetTeamTechs():GetNumTechsKnown()
		local perPlayer = escortCache[player:GetID()]
		if perPlayer then
			local entry = perPlayer[className]
			if entry and entry.techCount == techCount then
				return entry.typeID
			end
		end
	end

	local sUnitType = GetCivSpecificUnit(player, className)
	if sUnitType == nil then return nil end

	local guard = 0   -- protects against a cyclic upgrade chain
	local sUpgrade = GetUpgradeUnit(player, sUnitType)
	while sUpgrade ~= nil and guard < 20 do
		sUnitType = sUpgrade
		sUpgrade = GetUpgradeUnit(player, sUnitType)
		guard = guard + 1
	end
	local typeID = GameInfoTypes[sUnitType]

	if CONFIG.CacheEscortUnitTypes then
		local pid = player:GetID()
		escortCache[pid] = escortCache[pid] or {}
		escortCache[pid][className] = { techCount = techCount, typeID = typeID }
	end
	return typeID
end

local function SpawnEscort(unitX, unitY, player, key)
	if unitX == nil or unitY == nil or player == nil then return end

	local cap = CONFIG.MaxMilitaryForFreeEscorts
	if cap ~= nil and player:GetNumMilitaryUnits() >= cap then return end

	local spec = ESCORT[key]
	local typeID = ResolveEscortType(player, spec.class)
	if typeID == nil then return end

	local newUnit = player:InitUnit(typeID, unitX, unitY, spec.ai)
	AINewUnitSetUp(newUnit, player:GetCurrentEra() * spec.exp)
end

function AIForceBuildAirEscortUnits(x, y, player)   SpawnEscort(x, y, player, "Air")      end
function AIForceBuildNavalEscortUnits(x, y, player) SpawnEscort(x, y, player, "NavalEsc") end
function AIForceBuildNavalHRUnits(x, y, player)     SpawnEscort(x, y, player, "NavalHR")  end
function AIForceBuildInfantryUnits(x, y, player)    SpawnEscort(x, y, player, "Infantry") end
function AIForceBuildMobileUnits(x, y, player)      SpawnEscort(x, y, player, "Mobile")   end
function AIForceBuildLandHRUnits(x, y, player)      SpawnEscort(x, y, player, "LandHR")   end

---------------------------------------------------------------------
-- UNIT-COUNT HELPERS
---------------------------------------------------------------------

function UnitIsOutofDate(player, unit)
	local sNewUnitClass = GameInfo.Units[unit:GetUnitType()].GoodyHutUpgradeUnitClass
	return sNewUnitClass ~= nil and player:GetUnitClassCount(sNewUnitClass) >= 1
end

function AIHasTooManySameUnits(player, ThisUnitClass)
	local ratio = math.max(player:GetNumMilitaryUnits() * 0.2, 3)
	-- cheapest test first; result is identical to the original OR chain
	if player:GetUnitClassCount(ThisUnitClass) >= ratio then return true end
	return (AICanBeBoss(player) or PlayerAtWarWithHuman(player)) and true or false
end

---------------------------------------------------------------------
-- AI PROMOTIONS + ESCORTS ON CITY TRAIN
---------------------------------------------------------------------

local function SpawnGroundEscorts(x, y, player)
	SpawnEscort(x, y, player, "Infantry")
	SpawnEscort(x, y, player, "Mobile")
	SpawnEscort(x, y, player, "LandHR")
end

-- Bombers / air attackers: air escort + (naval set if coastal, else ground set)
local function SpawnStrikeEscorts(x, y, player, iCity)
	SpawnEscort(x, y, player, "Air")
	local city = player:GetCityByID(iCity)
	if city ~= nil and city:IsCoastal() then
		SpawnEscort(x, y, player, "NavalEsc")
		SpawnEscort(x, y, player, "NavalHR")
	else
		SpawnGroundEscorts(x, y, player)
	end
end

function AIPromotion(iPlayer, iCity, iUnit, bGold, bFaith)
	if iUnit == nil or iPlayer == nil or iPlayer >= MAX_MAJOR then return end
	local player = Players[iPlayer]
	if player == nil or player:IsHuman() then return end

	local aiCityCount = player:GetNumCities()
	if aiCityCount < 1 then return end

	local unit = player:GetUnitByID(iUnit)
	if unit == nil then return end

	local x, y = unit:GetX(), unit:GetY()
	if x == nil or y == nil then return end

	local unitClass = unit:GetUnitClassType()

	-- Keep worker / siege counts down so AI turns stay fast.
	-- (return after kill: the original kept operating on the dead unit)
	if unit:GetUnitType() == UNIT_WORKER then
		local n = player:GetUnitClassCount(unitClass)
		if n > aiCityCount or n > 20 then
			KillUnit(unit)
			return
		end
	end

	if HasPromo(unit, P.CitySiege) and not PlayerAtWarWithHuman(player) then
		if player:GetUnitClassCount(unitClass) > aiCityCount then
			KillUnit(unit)
			return
		end
	end

	-- Everything below is the difficulty bonus; bail out cheaply when it can't apply
	if handicap < 4 then return end
	local era = player:GetCurrentEra()
	if era <= 1 then return end
	if ManPowerResID == nil or player:GetNumResourceAvailable(ManPowerResID, true) <= 0 then return end

	-- First matching branch wins (same order as the original if/elseif chain)
	if HasPromo(unit, P.Bomber) then
		GivePromos(unit, LIST.Bomber)
		if AIHasTooManySameUnits(player, unitClass) then SpawnStrikeEscorts(x, y, player, iCity) end

	elseif HasPromo(unit, P.AirAttack) then
		GivePromos(unit, LIST.AirAttack)
		if AIHasTooManySameUnits(player, unitClass) then SpawnStrikeEscorts(x, y, player, iCity) end

	elseif HasPromo(unit, P.CapitalShip) then
		GivePromos(unit, LIST.CapitalShip)
		if AIHasTooManySameUnits(player, unitClass) then
			SpawnEscort(x, y, player, "NavalEsc")
			SpawnEscort(x, y, player, "NavalHR")
			SpawnEscort(x, y, player, "Infantry")
			SpawnEscort(x, y, player, "Mobile")
		end

	elseif HasPromo(unit, P.Carrier) then
		if AIHasTooManySameUnits(player, unitClass) then
			SpawnEscort(x, y, player, "NavalEsc")
			SpawnEscort(x, y, player, "NavalHR")
			SpawnEscort(x, y, player, "Air")
			SpawnEscort(x, y, player, "Infantry")
			SpawnEscort(x, y, player, "Mobile")
		end

	elseif HasPromo(unit, P.SSBN) then
		if AIHasTooManySameUnits(player, unitClass) then
			SpawnEscort(x, y, player, "NavalEsc")
			SpawnEscort(x, y, player, "NavalHR")
			SpawnEscort(x, y, player, "Air")
		end

	elseif HasPromo(unit, P.NavalRanged) then
		GivePromos(unit, LIST.NavalRanged)
		if AIHasTooManySameUnits(player, unitClass) then
			SpawnEscort(x, y, player, "NavalEsc")
			SpawnEscort(x, y, player, "NavalHR")
		end
		if era > 4 then GivePromos(unit, LIST.NavalRangedLate) end

	elseif HasPromo(unit, P.LandAOE) then
		GivePromos(unit, LIST.LandAOE)
		RemovePromo(unit, P.SetUp)
		if AIHasTooManySameUnits(player, unitClass) then SpawnGroundEscorts(x, y, player) end

	elseif HasPromo(unit, P.HitandRun) then   -- era > 1 already guaranteed above
		GivePromos(unit, LIST.HitandRun)
		if era > 5 then
			RemovePromo(unit, P.AIHitandRun)
			GivePromo(unit, P.AIRange)
		end

	elseif HasPromo(unit, P.Heli) then
		GivePromos(unit, LIST.Heli)
		if AIHasTooManySameUnits(player, unitClass) then
			SpawnEscort(x, y, player, "Infantry")
			SpawnEscort(x, y, player, "Mobile")
		end

	elseif HasPromo(unit, P.CitySiege) then
		GivePromos(unit, LIST.CitySiege)
		RemovePromo(unit, P.SetUp)
		if era > 3 then GivePromos(unit, LIST.CitySiegeLate) end
		if AIHasTooManySameUnits(player, unitClass) then
			SpawnEscort(x, y, player, "Infantry")
			SpawnEscort(x, y, player, "LandHR")
		end

	else
		local isRanged = HasPromo(unit, P.Ranged)
		local isNavalHR = HasPromo(unit, P.NavalHR)
		local isSub = HasPromo(unit, P.Sub)
		if isRanged or isNavalHR or isSub then
			GivePromos(unit, LIST.Barrage)
			if era > 4 then GivePromos(unit, LIST.BarrageLate) end
			if AIHasTooManySameUnits(player, unitClass) then
				if isRanged then
					SpawnEscort(x, y, player, "Infantry")
				else
					SpawnEscort(x, y, player, "NavalEsc")
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- MINOR CIVS: keep unit counts low
---------------------------------------------------------------------

function MinorNoCombatUnits(iPlayer, iCity, iUnit, bGold, bFaith)
	if iUnit == nil then return end
	local player = Players[iPlayer]
	if player == nil or not player:IsMinorCiv() then return end
	if player:GetNumCities() < 1 then return end

	local unit = player:GetUnitByID(iUnit)
	if unit == nil then return end

	if unit:GetUnitType() == UNIT_WORKER and UNITCLASS_WORKER ~= nil
		and player:GetUnitClassCount(UNITCLASS_WORKER) > 1 then
		KillUnit(unit)
		return
	end
	if unit:IsCombatUnit() and player:GetNumMilitaryUnits() > 3 then
		KillUnit(unit)
	end
end

-- ONE CityTrained listener instead of two (halves per-trained-unit dispatch/Players lookups)
local function OnCityTrained(iPlayer, iCity, iUnit, bGold, bFaith)
	if iPlayer < MAX_MAJOR then
		AIPromotion(iPlayer, iCity, iUnit, bGold, bFaith)
	else
		MinorNoCombatUnits(iPlayer, iCity, iUnit, bGold, bFaith)
	end
end
GameEvents.CityTrained.Add(OnCityTrained)

--print("New Handicap Check Pass!")