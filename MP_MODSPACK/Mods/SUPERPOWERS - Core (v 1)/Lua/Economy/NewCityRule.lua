-- NewCityRule
-- Author: Lincoln_lyf
-- Edited by Tokata
-- Optimized pass: cached IDs, single turn handler, write-only-on-change,
-- nil guards, no UI-side events (multiplayer safe).
--------------------------------------------------------------
include( "UtilityFunctions.lua" )

--==========================================================================================
-- Debug logging (print() every city every turn is slow; keep off in release)
--==========================================================================================
local DEBUG = false
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

--==========================================================================================
-- City size buildings
--==========================================================================================
function CitySetSize(city, player, cityPop)
	if player == nil or city == nil or cityPop < 1 then
		return
	end

	-- Venice: purchased city-states aren't flagged as puppets (engine bug workaround)
	if civVenice ~= nil and player:GetCivilizationType() == civVenice then
		if not city:IsCapital() then
			SetBuilding(city, bPuppetGovFull, 1)
			SetBuilding(city, bPuppetGov, 0)
		end
	end

	local level = GetSizeLevel(cityPop)

	-- Size buildings are cumulative: level N => buildings 1..N present, rest absent
	SetBuilding(city, bTown, (level == 0) and 1 or 0)
	for i = 1, #bSizes do
		SetBuilding(city, bSizes[i], (level >= i) and 1 or 0)
	end

	-- Monarchy: manpower = level-1 from Medium (pop 15) upward (15->1 ... 80->5)
	local manpower = 0
	if polMonarchy ~= nil and level >= 2 and player:HasPolicy(polMonarchy) then
		manpower = level - 1
	end
	SetBuilding(city, bTradManpower, manpower)

	-- Aristocracy: growth bonus for towns only
	local food = 0
	if polAristocracy ~= nil and level == 0 and player:HasPolicy(polAristocracy) then
		food = 1
	end
	SetBuilding(city, bTradFood, food)
end

--==========================================================================================
-- Policy per-turn effects (human only, applied on capital)
--==========================================================================================
function SetPolicyPerTurnEffects(player)
	local pCity = player:GetCapitalCity()
	if pCity == nil then return end

	if polReligiousPolitics ~= nil and player:HasPolicy(polReligiousPolitics) then
		local faithToHappiness = math.floor(0.1 * player:GetTotalFaithPerTurn())
		if faithToHappiness < 0 then faithToHappiness = 0 end
		SetBuilding(pCity, bFaithPolitics, faithToHappiness)
		dprint("Faith to Happiness:", faithToHappiness)
	end

	if polCapitalism ~= nil and player:HasPolicy(polCapitalism) then
		local routes = player:GetNumInternationalTradeRoutesUsed()
		if routes < 0 then routes = 0 end
		SetBuilding(pCity, bTradeToScience, routes)
		dprint("Science from trade routes:", routes)
	end
end

--==========================================================================================
-- China's UA
--==========================================================================================
function SetGoldenAgeBonus(player)
	local pCity = player:GetCapitalCity()
	if pCity == nil then return end
	SetBuilding(pCity, bArtOfWar, player:IsGoldenAge() and 1 or 0)
end

--==========================================================================================
-- Germany's UA
-- NOTE: yield is read with the building already in place. If BUILDING_TB_CONVERTS_LAND_BARBARIANS
-- itself modifies PRODUCTION, you'd get feedback; the original zeroed it first, which avoided that
-- but forced two recalcs per city per turn. If it only gives culture/science this is fine.
--==========================================================================================
function SetProductionToCulture(player)
	for city in player:Cities() do
		local rate = math.floor(city:GetYieldRate(YieldTypes.YIELD_PRODUCTION) / 50)
		if rate < 0 then rate = 0 end
		SetBuilding(city, bGermanProd, rate)
		dprint("German city", city:GetName(), "rate", rate)
	end
end

--==========================================================================================
-- Single PlayerDoTurn handler (was two separate handlers on the same event)
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

	if not isMinor then
		-- Civ UAs (all non-minor players, AI included, as in the original)
		local civ = player:GetCivilizationType()
		if civ == civGermany then
			SetProductionToCulture(player)
		elseif civ == civChina then
			SetGoldenAgeBonus(player)
		end

		-- Policy effects (human only, as in the original)
		if player:IsHuman() then
			SetPolicyPerTurnEffects(player)
		end
	end

	-- City size buildings (everyone incl. city-states). pcall so one bad city
	-- can't abort the loop and leave the rest of the player's cities unprocessed.
	for city in player:Cities() do
		local pop = city:GetPopulation()
		if pop >= 1 then
			local ok, err = pcall(CitySetSize, city, player, pop)
			if not ok then
				print("NewCityRule: CitySetSize failed: " .. tostring(err))
			end
		end
	end
end
GameEvents.PlayerDoTurn.Add(NewCitySystem)

-- Apply immediately on founding so new cities don't wait for next turn.
-- (Captured cities are picked up by the per-turn pass.)
function CitySizeOnFounded(playerID, x, y)
	local player = Players[playerID]
	if player == nil or player:IsBarbarian() then return end
	local plot = Map.GetPlot(x, y)
	local city = plot and plot:GetPlotCity()
	if city then
		CitySetSize(city, player, city:GetPopulation())
	end
end
GameEvents.PlayerCityFounded.Add(CitySizeOnFounded)

print("New City Rule Check Pass!")