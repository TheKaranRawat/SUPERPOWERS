-- UtilityFunctions (optimized for performance + multiplayer determinism)
-- Original author: linco
--
-- MP RULES THIS FILE FOLLOWS (keep following them in callers):
--   * No Game.GetActivePlayer(), math.random, os.clock/os.time, or UI-only state in gameplay logic.
--   * Iterate players with an explicit numeric loop (fixed order on every client).
--   * Cache only DB-derived data (identical on all clients). Never cache game state
--     (humans, wars, happiness...) across calls: players can drop / be replaced by AI mid-game.

local DEBUG = false -- set true only for local testing; print() is slow (file I/O) and the
                    -- string concatenation in its arguments is evaluated even if you ignore it.

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS

------------------------------------------------------------------------------
-- Cached DB ids (looked up once at load instead of on every call)
------------------------------------------------------------------------------
local RES_CONSUMER        = GameInfoTypes["RESOURCE_CONSUMER"]
local RES_ELECTRICITY     = GameInfoTypes["RESOURCE_ELECTRICITY"]
local ERA_MODERN          = GameInfoTypes["ERA_MODERN"]

local POLICY_IRON_CURTAIN = GameInfoTypes["POLICY_IRON_CURTAIN"]
local POLICY_TREATY_ORG   = GameInfoTypes["POLICY_TREATY_ORGANIZATION"]
local POLICY_DICTATORSHIP = GameInfoTypes["POLICY_DICTATORSHIP_PROLETARIAT"]
local POLICY_REPRESENTATION = GameInfoTypes["POLICY_REPRESENTATION"]
local POLICY_POLICE_STATE = GameInfoTypes["POLICY_POLICE_STATE"]

local CIV_POLYNESIA = GameInfoTypes["CIVILIZATION_POLYNESIA"]
local CIV_ENGLAND   = GameInfoTypes["CIVILIZATION_ENGLAND"]
local CIV_VENICE    = GameInfoTypes["CIVILIZATION_VENICE"]
local CIV_PERSIA    = GameInfoTypes["CIVILIZATION_PERSIA"]

local FEATURE_FOREST = FeatureTypes.FEATURE_FOREST
local FEATURE_MARSH  = FeatureTypes.FEATURE_MARSH
local FEATURE_JUNGLE = FeatureTypes.FEATURE_JUNGLE

local RES_NUTMEG, RES_CLOVES, RES_PEPPER =
	GameInfoTypes.RESOURCE_NUTMEG, GameInfoTypes.RESOURCE_CLOVES, GameInfoTypes.RESOURCE_PEPPER

------------------------------------------------------------------------------
-- Players
------------------------------------------------------------------------------

-- DEPRECATE [COMBAT]
function PlayersAtWar(iPlayer, ePlayer)
	return Teams[iPlayer:GetTeam()]:IsAtWar(ePlayer:GetTeam())
end

-- DEPRECATE [COMBAT]
-- BEHAVIOUR CHANGE: the old version only looked at the FIRST human found and returned
-- immediately. In MP that made the result depend on slot order. Now true if at war with ANY human.
function PlayerAtWarWithHuman(player)
	local team = Teams[player:GetTeam()]
	for i = 0, MAX_MAJOR - 1 do
		local human = Players[i]
		if human ~= nil and human:IsHuman() and human:IsAlive() and team:IsAtWar(human:GetTeam()) then
			return true
		end
	end
	return false
end

function AICanBeBoss(player)
	-- cheapest checks first, and world totals only if we actually need them
	if player:IsHuman() or player:IsBarbarian() or player:IsMinorCiv() then
		return false -- (old code returned nil for minors)
	end

	local cities = player:GetNumCities()
	if cities <= 1 then return false end
	local pop = player:GetTotalPopulation()
	if pop <= 1 then return false end
	local tourism = player:GetTourism()
	if tourism <= 1 then return false end

	if cities >= 16 or tourism > 600 then return true end
	if cities >= Game.GetNumCities() / 10 or pop >= Game.GetTotalPopulation() / 10 then
		return true
	end
	return false
end

------------------------------------------------------------------------------
-- Plots
------------------------------------------------------------------------------

-- DEPRECATE [COMBAT]
-- BEHAVIOUR CHANGE: true if ANY human's team can see the plot (old code: first human only).
function PlotIsVisibleToHuman(plot)
	for i = 0, MAX_MAJOR - 1 do
		local human = Players[i]
		if human ~= nil and human:IsHuman() and human:IsAlive() and plot:IsVisible(human:GetTeam()) then
			return true
		end
	end
	return false
end

-- DEPRECATE [NO USE DETECTED]
function isFriendlyCity(pUnit, pCity)
	return pCity:GetTeam() == pUnit:GetTeam()
		and not pCity:IsResistance()
		and not pCity:IsRazing()
		and not (pCity:IsOccupied() and not pCity:IsNoOccupiedUnhappiness())
end

------------------------------------------------------------------------------
-- Units (results come from the static DB, so they are safe to memoize)
------------------------------------------------------------------------------
local civUnitCache = {} -- [civType][unitClass] = unitType or false

function GetCivSpecificUnit(player, sUnitClass)
	local civID = player:GetCivilizationType()
	local byClass = civUnitCache[civID]
	if byClass == nil then
		byClass = {}
		civUnitCache[civID] = byClass
	end

	local cached = byClass[sUnitClass]
	if cached ~= nil then
		return cached or nil
	end

	local sCivType = GameInfo.Civilizations[civID].Type
	local sUnitType = nil
	for row in GameInfo.Civilization_UnitClassOverrides{ CivilizationType = sCivType, UnitClassType = sUnitClass } do
		sUnitType = row.UnitType
		break
	end
	if sUnitType == nil then
		local class = GameInfo.UnitClasses[sUnitClass]
		sUnitType = class and class.DefaultUnit or nil
	end

	byClass[sUnitClass] = sUnitType or false
	return sUnitType
end

function GetUpgradeUnit(player, sUnitType)
	local info = GameInfo.Units[sUnitType]
	if info == nil or info.GoodyHutUpgradeUnitClass == nil then return nil end

	local sUpgrade = GetCivSpecificUnit(player, info.GoodyHutUpgradeUnitClass)
	if sUpgrade == nil then return nil end

	local prereq = GameInfo.Units[sUpgrade].PrereqTech
	if prereq == nil or Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[prereq]) then
		return sUpgrade
	end
	return nil
end

------------------------------------------------------------------------------
-- International immigration
-- Returns a number (0 where the old code returned nil on bad input).
------------------------------------------------------------------------------
function CheckMoveOutCounter(MoveOutPlayerID, MoveInPlayerID)
	local outP, inP = Players[MoveOutPlayerID], Players[MoveInPlayerID]
	if outP == nil or inP == nil then return 0 end

	-- Early exits before doing any of the expensive modifier work
	local base = inP:GetInfluenceLevel(MoveOutPlayerID)
	if base <= 0 then return 0 end

	local inHappy = inP:GetExcessHappiness()
	if inHappy <= 0 or inP:GetNumResourceAvailable(RES_CONSUMER, true) <= 0 then return 0 end
	if inP:GetCurrentEra() >= ERA_MODERN and inP:GetNumResourceAvailable(RES_ELECTRICITY, true) <= 0 then return 0 end
	if PlayersAtWar(outP, inP) then return 0 end

	local mod = 1

	-- Diplomacy
	if Teams[inP:GetTeam()]:IsAllowsOpenBordersToTeam(outP:GetTeam()) then mod = mod + 1 end
	if outP:IsDenouncedPlayer(MoveInPlayerID) or inP:IsDenouncedPlayer(MoveOutPlayerID) then mod = mod - 0.5 end
	if outP:IsDoF(MoveInPlayerID) then mod = mod + 0.5 end

	-- Religion
	local inReligion = inP:GetReligionCreatedByPlayer()
	if inReligion ~= nil and inReligion > 0 and outP:HasReligionInMostCities(inReligion) then
		mod = mod + 1
	end

	-- Happiness (human only)
	if inP:IsHuman() then
		if inHappy > 150 then mod = mod + 0.5
		elseif inHappy > 100 then mod = mod + 0.25
		elseif inHappy <= 20 then mod = mod - 0.5
		elseif inHappy <= 50 then mod = mod - 0.25
		end
	end

	if outP:IsHuman() then
		local outHappy = outP:GetExcessHappiness()
		-- FIX (please verify intent): the old code tested MoveInPlayer's happiness in the
		-- middle branches of this move-OUT block (copy/paste slip). Now uses outP throughout.
		if outHappy >= 150 then mod = mod - 0.5
		elseif outHappy > 100 then mod = mod - 0.25
		elseif outHappy <= 0 then mod = mod + 0.5
		elseif outHappy <= 20 then mod = mod + 0.25
		end
	end

	-- Ideology
	if outP:HasPolicy(POLICY_IRON_CURTAIN) then mod = mod - 0.5 end
	if inP:HasPolicy(POLICY_TREATY_ORG) then mod = mod + 0.5 end

	if mod < 0 then mod = 0 end
	local result = mod * base
	if DEBUG then print("MoveoutCounterFinal: " .. result) end
	return result
end

------------------------------------------------------------------------------
-- City level by distance from capital
------------------------------------------------------------------------------
local CITY_HALL = {
	GameInfoTypes["BUILDING_CITY_HALL_LV1"], GameInfoTypes["BUILDING_CITY_HALL_LV2"],
	GameInfoTypes["BUILDING_CITY_HALL_LV3"], GameInfoTypes["BUILDING_CITY_HALL_LV4"],
	GameInfoTypes["BUILDING_CITY_HALL_LV5"],
}
local POLICE_STATE = {
	[2] = GameInfoTypes["BUILDING_POLICE_STATE_LV2"], [3] = GameInfoTypes["BUILDING_POLICE_STATE_LV3"],
	[4] = GameInfoTypes["BUILDING_POLICE_STATE_LV4"], [5] = GameInfoTypes["BUILDING_POLICE_STATE_LV5"],
}
local PUPPET      = GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"]
local PUPPET_FULL = GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"]
local CONSTABLE   = GameInfoTypes["BUILDING_CONSTABLE"]
local SENATE      = GameInfoTypes["BUILDING_ROMAN_SENATE"]
local SHERIFF     = GameInfoTypes["BUILDING_SHERIFF_OFFICE"]
local POLICE_STN  = GameInfoTypes["BUILDING_POLICE_STATION"]
local PROCURATE   = GameInfoTypes["BUILDING_PROCURATORATE"]
local REPRESENT_CULTURE = GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"]
local SATRAPS_COURT     = GameInfoTypes["BUILDING_SATRAPS_COURT"]

-- Every building this function owns. Anything not requested for a city is forced to 0,
-- except ids marked KEEP (player-buildable office for that level, left untouched).
local MANAGED = {
	CITY_HALL[1], CITY_HALL[2], CITY_HALL[3], CITY_HALL[4], CITY_HALL[5],
	PUPPET, PUPPET_FULL, CONSTABLE, SENATE, SHERIFF, POLICE_STN, PROCURATE,
	POLICE_STATE[2], POLICE_STATE[3], POLICE_STATE[4], POLICE_STATE[5],
}
local KEEP = -1

-- Which office buildings each level leaves alone (identical to the old hand-written branches)
local LEVEL_KEEP = {
	[1] = {},
	[2] = { CONSTABLE, SENATE },
	[3] = { SHERIFF },
	[4] = { POLICE_STN },
	[5] = { PROCURATE },
}

-- SetNumRealBuilding forces a city recalculation, so only call it when the value changes.
local function SetBuilding(city, id, n)
	if city:GetNumRealBuilding(id) ~= n then
		city:SetNumRealBuilding(id, n)
	end
end

local function ApplyBuildings(city, want)
	for i = 1, #MANAGED do
		local id = MANAGED[i]
		local n = want[id] or 0
		if n ~= KEEP then
			SetBuilding(city, id, n)
		end
	end
end

-- Distance thresholds depend only on map size: compute once.
local baseThresholds = nil
local function GetBaseThresholds()
	if baseThresholds == nil then
		local width = Map.GetGridSize()
		baseThresholds = {
			7,
			math.max(14, math.min(18, width / 8)),
			math.max(26, math.min(30, width / 5)),
			math.max(36, math.min(44, width / 3)),
		}
	end
	return baseThresholds
end

local function GetLevelForDistance(distance, t1, t2, t3, t4)
	if distance <= 1 then return nil end -- NOTE: old code also did nothing for distance 0-1
	if distance <= t1 then return 1 end
	if distance <= t2 then return 2 end
	if distance <= t3 then return 3 end
	if distance <= t4 then return 4 end
	return 5
end

function SetCityLevelbyDistance(player, city)
	if player:GetNumCities() < 1 then return end

	local want = {}

	if city:IsCapital() then
		ApplyBuildings(city, want)
		return
	end

	if city:IsPuppet() then
		if player:GetCivilizationType() == CIV_VENICE then
			want[PUPPET_FULL] = 1 -- Venice: local government with no penalties
		else
			want[PUPPET] = 1
		end
		ApplyBuildings(city, want)

		if not city:IsResistance() then
			if city:GetOrderQueueLength() <= 0 or city:GetProduction() == 0 then
				city:PushOrder(OrderTypes.ORDER_MAINTAIN, 0, -1, 0, false, false) -- let it make gold
			end
		end
		return
	end

	-- Annexed city
	local capital = player:GetCapitalCity()
	if capital == nil then return end -- capital lost: old code would have thrown here

	local plot = city:Plot()
	local distance = Map.PlotDistance(plot:GetX(), plot:GetY(), capital:GetX(), capital:GetY())

	SetBuilding(city, REPRESENT_CULTURE, player:HasPolicy(POLICY_REPRESENTATION) and 1 or 0)

	-- Level thresholds (shifted up one level for England / Dictatorship policy; Polynesia has no Lv4-5)
	local b = GetBaseThresholds()
	local t1, t2, t3, t4 = b[1], b[2], b[3], b[4]
	local civ = player:GetCivilizationType()
	if civ == CIV_POLYNESIA then
		t3, t4 = 999, 999
	elseif civ == CIV_ENGLAND or player:HasPolicy(POLICY_DICTATORSHIP) then
		t1, t2, t3, t4 = t2, t3, t4, 999
	end

	local level = GetLevelForDistance(distance, t1, t2, t3, t4)

	if level ~= nil then
		want[CITY_HALL[level]] = 1
		for _, id in ipairs(LEVEL_KEEP[level]) do want[id] = KEEP end

		if level >= 2 and player:HasPolicy(POLICY_POLICE_STATE) then
			want[POLICE_STATE[level]] = 1
		end

		if level == 1 and civ == CIV_PERSIA then
			want[CITY_HALL[1]] = 0
			SetBuilding(city, SATRAPS_COURT, 1) -- Achaemenid legacy
		end
	end

	-- Indonesia: spice cities (original owner) are corruption free
	local res = plot:GetResourceType()
	if (res == RES_NUTMEG or res == RES_CLOVES or res == RES_PEPPER)
		and player == Players[city:GetOriginalOwner()] then
		want = {} -- everything off, nothing kept
		level = level or 0 -- force apply below
	end

	if level ~= nil then
		ApplyBuildings(city, want)
	end
end

------------------------------------------------------------------------------
-- Misc
------------------------------------------------------------------------------
function RemoveConflictFeatures(plot)
	if plot == nil then return end
	local feature = plot:GetFeatureType()
	if feature == FEATURE_FOREST or feature == FEATURE_MARSH or feature == FEATURE_JUNGLE then
		plot:SetFeatureType(-1)
	end
end

print("UtilityFunctions Check Pass!")