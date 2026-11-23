-- NewCityRule
-- Author: Lincoln_lyf
-- Edited by Tokata
-- Optimized pass: cached IDs, single turn handler, write-only-on-change,
-- nil guards, no UI-side events (multiplayer safe).
-- Fix pass: safe capital locator, stale capital-only buildings cleared,
-- integer-only math, single founding handler, per-player values hoisted.
--------------------------------------------------------------
include( "UtilityFunctions.lua" )

--==========================================================================================
-- Config
--==========================================================================================
local DEBUG = false
-- SetCityLevelbyDistance used to run only when a human founds a city.
-- Set to true if it was meant to refresh every turn (costs more per turn).
local DISTANCE_EACH_TURN = false

local function dprint(...)
	if DEBUG then print(...) end
end

--==========================================================================================
-- Cached lookups (resolved ONCE at load, not per city per turn)
--==========================================================================================
local civGermany  = GameInfoTypes["CIVILIZATION_GERMANY"]
local civChina    = GameInfoTypes["CIVILIZATION_CHINA"]
local civVenice   = GameInfoTypes["CIVILIZATION_VENICE"]

local polReligiousPolitics = GameInfoTypes["POLICY_RELIGIOUS_POLITICS"]
local polCapitalism        = GameInfoTypes["POLICY_CAPITALISM"]
local polMonarchy          = GameInfoTypes["POLICY_MONARCHY"]
local polAristocracy       = GameInfoTypes["POLICY_ARISTOCRACY"]

local bPalace   = GameInfoTypes["BUILDING_PALACE"]
local bLocator  = GameInfoTypes["BUILDING_CAPITAL_LOCATOR"]

local bTown   = GameInfoTypes["BUILDING_CITY_SIZE_TOWN"]
local bSizes  = {  -- index = size level 1..6
	GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],
	GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],
	GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],
	GameInfoTypes["BUILDING_CITY_SIZE_XL"],
	GameInfoTypes["BUILDING_CITY_SIZE_XXL"],
	GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],
}
-- minimum population for each size level (same index as bSizes)
local SIZE_MIN_POP = { 6, 15, 26, 40, 60, 80 }

local bTradManpower   = GameInfoTypes["BUILDING_TRADITION_MANPOWER"]
local bTradFood       = GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"]
local bPuppetGov      = GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"]       -- (sic)
local bPuppetGovFull  = GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"]  -- (sic)

local bFaithPolitics  = GameInfoTypes["BUILDING_FAITH_RELIGIOUS_POLITICS"]
local bTradeToScience = GameInfoTypes["BUILDING_TRADE_TO_SCIENCE"]
local bArtOfWar       = GameInfoTypes["BUILDING_TB_ART_OF_WAR"]
local bGermanProd     = GameInfoTypes["BUILDING_TB_CONVERTS_LAND_BARBARIANS"]

local YIELD_PRODUCTION = YieldTypes.YIELD_PRODUCTION

--==========================================================================================
-- Helpers
--==========================================================================================

-- SetNumRealBuilding marks the city dirty and forces yield recalculation.
-- Only call it when the value actually changes. Reading the real-building
-- count is stateless, so this is safe across save/load and between clients.
local function SetBuilding(city, buildingID, count)
	if buildingID == nil then return end
	if city:GetNumRealBuilding(buildingID) ~= count then
		city:SetNumRealBuilding(buildingID, count)
	end
end

-- Returns 0 for "town" (< 6 pop), otherwise 1..6
local function GetSizeLevel(pop)
	for i = #SIZE_MIN_POP, 1, -1 do
		if pop >= SIZE_MIN_POP[i] then
			return i
		end
	end
	return 0
end

-- Calls the external SetCityLevelbyDistance defensively (it lives outside this file).
local function SafeSetCityLevelByDistance(player, city)
	if SetCityLevelbyDistance == nil then return end
	local ok, err = pcall(SetCityLevelbyDistance, player, city)
	if not ok then
		print("NewCityRule: SetCityLevelbyDistance failed: " .. tostring(err))
	end
end

--==========================================================================================
-- CAPITAL LOCATOR (human only: guards against the unwanted capital-move bug)
--
-- Rules:
--  * The locator city is a city the player OWNS and ORIGINALLY founded.
--  * A locator left on a captured city (original owner is someone else) is ignored
--    and removed, so it can never pull the Palace onto a conquered city.
--  * If the player has no valid locator city (old save, original capital lost),
--    adopt the CURRENT capital instead of stripping the Palace.
--  * Give the Palace first, remove it from the others after, so the player
--    never has a moment without a capital.
--==========================================================================================
local function EnsureCapitalLocator(player)
	if bPalace == nil or bLocator == nil then return end

	local playerID = player:GetID()
	local locatorCity = nil

	for city in player:Cities() do
		if city:GetNumRealBuilding(bLocator) > 0 then
			if locatorCity == nil and city:GetOriginalOwner() == playerID then
				locatorCity = city
			else
				-- Foreign (captured) or duplicate locator: remove it
				SetBuilding(city, bLocator, 0)
			end
		end
	end

	if locatorCity == nil then
		local cap = player:GetCapitalCity()
		if cap ~= nil then
			SetBuilding(cap, bLocator, 1)
			dprint("NewCityRule: no valid locator, adopted current capital", cap:GetName())
		end
		return
	end

	local locatorID = locatorCity:GetID()
	SetBuilding(locatorCity, bPalace, 1)          -- give first
	for city in player:Cities() do                -- then remove from the rest
		if city:GetID() ~= locatorID then
			SetBuilding(city, bPalace, 0)
		end
	end
end

-- Other scripts that legitimately move the capital (e.g. a "New Palace" building)
-- should call this so the locator follows the capital instead of undoing the move:
--     NewCityRule_MoveCapitalLocator(player, newCapitalCity)
function NewCityRule_MoveCapitalLocator(player, newCapital)
	if player == nil or newCapital == nil or bLocator == nil then return end
	SetBuilding(newCapital, bLocator, 1)
	local newID = newCapital:GetID()
	for city in player:Cities() do
		if city:GetID() ~= newID then
			SetBuilding(city, bLocator, 0)
		end
	end
end

--==========================================================================================
-- Per-human-player founding pass
--==========================================================================================
function SetCityPerTurnEffects(player)
	if player:GetNumCities() <= 0 then return end

	if player:IsHuman() then
		EnsureCapitalLocator(player)
	end

	for city in player:Cities() do
		dprint("Get the city:", city:GetName())
		SafeSetCityLevelByDistance(player, city)
	end
end

--==========================================================================================
-- City size buildings
-- ctx is built once per player per turn (see BuildContext)
--==========================================================================================
local function CitySetSize(city, cityPop, ctx)
	-- Venice: purchased city-states aren't flagged as puppets (engine bug workaround)
	-- NOTE: the building stays if another civ later captures the city.
	if ctx.isVenice and not city:IsCapital() then
		SetBuilding(city, bPuppetGovFull, 1)
		SetBuilding(city, bPuppetGov, 0)
	end

	local level = GetSizeLevel(cityPop)

	-- Size buildings are cumulative: level N => buildings 1..N present, rest absent
	SetBuilding(city, bTown, (level == 0) and 1 or 0)
	for i = 1, #bSizes do
		SetBuilding(city, bSizes[i], (level >= i) and 1 or 0)
	end

	-- Monarchy: manpower = level-1 from Medium (pop 15) upward (15->1 ... 80->5)
	local manpower = 0
	if ctx.hasMonarchy and level >= 2 then
		manpower = level - 1
	end
	SetBuilding(city, bTradManpower, manpower)

	-- Aristocracy: growth bonus for towns only
	local food = 0
	if ctx.hasAristocracy and level == 0 then
		food = 1
	end
	SetBuilding(city, bTradFood, food)
end

local function BuildContext(player, civ, isMinor, isHuman, capital)
	local isChina   = (not isMinor) and civChina ~= nil and civ == civChina
	local isGermany = (not isMinor) and civGermany ~= nil and civ == civGermany
	return {
		player          = player,
		isGermany       = isGermany,
		isVenice        = civVenice ~= nil and civ == civVenice,
		hasMonarchy     = polMonarchy ~= nil and player:HasPolicy(polMonarchy),
		hasAristocracy  = polAristocracy ~= nil and player:HasPolicy(polAristocracy),
		-- Capital-only buildings exist for humans (policies) and China (golden age)
		clearCapitalOnly = (not isMinor) and (isHuman or isChina),
		distanceEachTurn = DISTANCE_EACH_TURN and isHuman,
		capitalID       = capital and capital:GetID() or -1,
	}
end

--==========================================================================================
-- Capital-only effects (applied on the capital; cleared everywhere else)
--==========================================================================================
-- Human policies. Also resets to 0 when the policy is no longer held.
local function SetPolicyPerTurnEffects(player, pCity)
	if polReligiousPolitics ~= nil then
		local faithToHappiness = 0
		if player:HasPolicy(polReligiousPolitics) then
			-- integer-safe (no 0.1 float multiply)
			faithToHappiness = math.floor(player:GetTotalFaithPerTurn() / 10)
			if faithToHappiness < 0 then faithToHappiness = 0 end
		end
		SetBuilding(pCity, bFaithPolitics, faithToHappiness)
		dprint("Faith to Happiness:", faithToHappiness)
	end

	if polCapitalism ~= nil then
		local routes = 0
		if player:HasPolicy(polCapitalism) then
			routes = player:GetNumInternationalTradeRoutesUsed()
			if routes < 0 then routes = 0 end
		end
		SetBuilding(pCity, bTradeToScience, routes)
		dprint("Science from trade routes:", routes)
	end
end

-- China's UA
local function SetGoldenAgeBonus(player, pCity)
	SetBuilding(pCity, bArtOfWar, player:IsGoldenAge() and 1 or 0)
end

--==========================================================================================
-- Per-city work for one player's turn (called through pcall so one bad city
-- can't abort the loop and leave the rest of the player's cities unprocessed)
--
-- Germany's UA: yield is read with the building already in place. If
-- BUILDING_TB_CONVERTS_LAND_BARBARIANS itself modifies PRODUCTION you'd get
-- feedback (count oscillating turn to turn). If it only gives culture/science
-- this is fine. Identical on every client, so it is a balance issue, not a desync.
--==========================================================================================
local function ProcessCity(city, ctx)
	-- Stale capital-only buildings (old capital after a capture/move, lost policy)
	if ctx.clearCapitalOnly and city:GetID() ~= ctx.capitalID then
		SetBuilding(city, bFaithPolitics, 0)
		SetBuilding(city, bTradeToScience, 0)
		SetBuilding(city, bArtOfWar, 0)
	end

	if ctx.isGermany then
		local rate = math.floor(city:GetYieldRate(YIELD_PRODUCTION) / 50)
		if rate < 0 then rate = 0 end
		SetBuilding(city, bGermanProd, rate)
		dprint("German city", city:GetName(), "rate", rate)
	end

	local pop = city:GetPopulation()
	if pop >= 1 then
		CitySetSize(city, pop, ctx)
	end

	if ctx.distanceEachTurn then
		SafeSetCityLevelByDistance(ctx.player, city)
	end
end

--==========================================================================================
-- Single PlayerDoTurn handler
--==========================================================================================
function NewCitySystem(playerID)
	local player = Players[playerID]
	if player == nil or player:IsBarbarian() or not player:IsAlive() then
		return
	end
	if player:GetNumCities() <= 0 then
		return
	end

	local isMinor = player:IsMinorCiv()
	local isHuman = player:IsHuman()
	local civ     = player:GetCivilizationType()
	local capital = player:GetCapitalCity()

	local ctx = BuildContext(player, civ, isMinor, isHuman, capital)

	if not isMinor and capital ~= nil then
		-- Civ UAs (all non-minor players, AI included, as in the original)
		if civChina ~= nil and civ == civChina then
			SetGoldenAgeBonus(player, capital)
		end
		-- Policy effects (human only, as in the original)
		if isHuman then
			SetPolicyPerTurnEffects(player, capital)
		end
	end

	-- Everyone incl. city-states
	for city in player:Cities() do
		local ok, err = pcall(ProcessCity, city, ctx)
		if not ok then
			print("NewCityRule: ProcessCity failed: " .. tostring(err))
		end
	end
end
GameEvents.PlayerDoTurn.Add(NewCitySystem)

--==========================================================================================
-- Single founding handler (was two separate handlers on PlayerCityFounded).
-- Applies immediately so new cities don't wait for next turn.
-- (Captured cities are picked up by the per-turn pass.)
--==========================================================================================
function OnCityFounded(playerID, x, y)
	local player = Players[playerID]
	if player == nil or player:IsBarbarian() then return end

	local plot = Map.GetPlot(x, y)
	local city = plot and plot:GetPlotCity()
	if city == nil then return end

	-- Human: mark the original capital, then run the capital/distance pass
	if player:IsHuman() then
		if city:IsOriginalCapital() then
			SetBuilding(city, bLocator, 1)
			dprint("Marked with Capital label!")
		end
		SetCityPerTurnEffects(player)
		dprint("Human's New city founded!")
	end

	-- Size buildings right away
	local pop = city:GetPopulation()
	if pop >= 1 then
		local isMinor = player:IsMinorCiv()
		local ctx = BuildContext(player, player:GetCivilizationType(), isMinor,
			player:IsHuman(), player:GetCapitalCity())
		local ok, err = pcall(CitySetSize, city, pop, ctx)
		if not ok then
			print("NewCityRule: CitySetSize (founded) failed: " .. tostring(err))
		end
	end
end
GameEvents.PlayerCityFounded.Add(OnCityFounded)

print("New City Rule Check Pass!")