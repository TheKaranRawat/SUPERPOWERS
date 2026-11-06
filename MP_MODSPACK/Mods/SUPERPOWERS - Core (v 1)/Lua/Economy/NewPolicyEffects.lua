-- NewPolicyEffects (optimized / hardened)
-- Changes vs original:
--  * All functions local (no global namespace collisions)
--  * Database IDs cached once at load via GameInfoTypes
--  * Nil-safety for cities, players, missing DB entries
--  * SetNumRealBuilding only called when the value actually changes
--  * Table-driven manpower / city hall logic
--  * print() gated behind DEBUG

local DEBUG = false
local HUMAN_ONLY = true -- set false to apply PolicyAdopted effects to AI too

local function dprint(...)
	if DEBUG then print(...) end
end

---------------------------------------------------------------------
-- Cached lookups (resolved once at load)
---------------------------------------------------------------------
local POLICY_MILITARISM              = GameInfoTypes["POLICY_MILITARISM"]
local POLICY_CITIZENSHIP             = GameInfoTypes["POLICY_CITIZENSHIP"]
local POLICY_DICTATORSHIP_PROLETARIAT = GameInfoTypes["POLICY_DICTATORSHIP_PROLETARIAT"]
local POLICY_REPRESENTATION          = GameInfoTypes["POLICY_REPRESENTATION"]
local POLICY_MONARCHY                = GameInfoTypes["POLICY_MONARCHY"]
local POLICY_ARISTOCRACY             = GameInfoTypes["POLICY_ARISTOCRACY"]

local UNIT_WORKER          = GameInfoTypes["UNIT_WORKER"]
local UNIT_BRAZILIAN_LABOR = GameInfoTypes["UNIT_BRAZILIAN_LABOR"]
local CIV_BRAZIL           = GameInfoTypes["CIVILIZATION_BRAZIL"]
local CIV_ROME             = GameInfoTypes["CIVILIZATION_ROME"]

local B_CITY_SIZE_TOWN = GameInfoTypes["BUILDING_CITY_SIZE_TOWN"]
local B_TRADITION_FOOD_GROWTH = GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"]
local B_TRADITION_MANPOWER = GameInfoTypes["BUILDING_TRADITION_MANPOWER"]
local B_REPRESENTATION_CULTURE = GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"]

local B_CONSTABLE      = GameInfoTypes["BUILDING_CONSTABLE"]
local B_ROMAN_SENATE   = GameInfoTypes["BUILDING_ROMAN_SENATE"]
local B_SHERIFF_OFFICE = GameInfoTypes["BUILDING_SHERIFF_OFFICE"]
local B_POLICE_STATION = GameInfoTypes["BUILDING_POLICE_STATION"]
local B_PROCURATORATE  = GameInfoTypes["BUILDING_PROCURATORATE"]

-- Highest size first; first match wins (same precedence as original if/elseif)
local MANPOWER_BY_SIZE = {
	{ GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"], 5 },
	{ GameInfoTypes["BUILDING_CITY_SIZE_XXL"],    4 },
	{ GameInfoTypes["BUILDING_CITY_SIZE_XL"],     3 },
	{ GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],  2 },
	{ GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"], 1 },
}

local CITY_HALL = {
	GameInfoTypes["BUILDING_CITY_HALL_LV1"],
	GameInfoTypes["BUILDING_CITY_HALL_LV2"],
	GameInfoTypes["BUILDING_CITY_HALL_LV3"],
	GameInfoTypes["BUILDING_CITY_HALL_LV4"],
	GameInfoTypes["BUILDING_CITY_HALL_LV5"],
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
-- Only touch the city if the value differs (each Set can trigger a yield recalc)
local function SetReal(city, buildingID, count)
	if buildingID and city:GetNumRealBuilding(buildingID) ~= count then
		city:SetNumRealBuilding(buildingID, count)
	end
end

---------------------------------------------------------------------
-- Militarism: reduce city resistance time
---------------------------------------------------------------------
local function OnCityCaptured(oldPlayerID, iCapital, iX, iY, newPlayerID, bConquest, iGreatWorksPresent, iGreatWorksXferred)
	if not POLICY_MILITARISM then return end

	local newPlayer = Players[newPlayerID]
	if newPlayer == nil or newPlayer:IsBarbarian() or newPlayer:IsMinorCiv() then
		return
	end
	if not newPlayer:HasPolicy(POLICY_MILITARISM) then
		return
	end

	local pPlot = Map.GetPlot(iX, iY)
	local pCity = pPlot and pPlot:GetPlotCity()
	if pCity == nil then return end -- city may have been razed

	local turns = pCity:GetResistanceTurns()
	if turns <= 0 then return end

	local delta = 0

	-- Small cities: remove one turn of resistance per pop (clamped to actual turns)
	local pop = pCity:GetPopulation()
	if pop < 6 then
		delta = -math.min(pop, turns)
	end

	-- Then halve what's left (rounded same way as original)
	local remaining = turns + delta
	if remaining > 1 then
		delta = delta + math.floor(-remaining * 0.5 + 0.5)
	end

	if delta ~= 0 then
		dprint("Militarism resistance change:", delta)
		pCity:ChangeResistanceTurns(delta)
	end
end
GameEvents.CityCaptureComplete.Add(OnCityCaptured)

---------------------------------------------------------------------
-- Citizenship: free Worker when a new city is founded
---------------------------------------------------------------------
local function FreeUnitNewCity(iPlayerID, iX, iY)
	if not POLICY_CITIZENSHIP then return end

	local player = Players[iPlayerID]
	if player == nil or not player:HasPolicy(POLICY_CITIZENSHIP) then
		return
	end

	local unitType = UNIT_WORKER
	if CIV_BRAZIL and UNIT_BRAZILIAN_LABOR and player:GetCivilizationType() == CIV_BRAZIL then
		unitType = UNIT_BRAZILIAN_LABOR
	end
	if not unitType then return end

	local newUnit = player:InitUnit(unitType, iX, iY, UnitAITypes.UNITAI_WORKER)
	if newUnit then
		newUnit:JumpToNearestValidPlot()
	end
end
GameEvents.PlayerCityFounded.Add(FreeUnitNewCity)

---------------------------------------------------------------------
-- Policy adoption effects
---------------------------------------------------------------------
local function FasterFoodGrowth(player)
	if not B_CITY_SIZE_TOWN then return end
	for city in player:Cities() do
		if city:IsHasBuilding(B_CITY_SIZE_TOWN) then
			city:ChangeFood(city:GrowthThreshold())
			SetReal(city, B_TRADITION_FOOD_GROWTH, 1)
			dprint("Aristocracy Growth Bonus!")
		end
	end
end

local function AddAdditionalManpower(player)
	for city in player:Cities() do
		for i = 1, #MANPOWER_BY_SIZE do
			local entry = MANPOWER_BY_SIZE[i]
			if entry[1] and city:IsHasBuilding(entry[1]) then
				SetReal(city, B_TRADITION_MANPOWER, entry[2])
				break
			end
		end
	end
end

local function ReducePolicyCost(player)
	for city in player:Cities() do
		if not city:IsPuppet() and not city:IsCapital() then
			SetReal(city, B_REPRESENTATION_CULTURE, 1)
			dprint("Player has the Representation policy!")
		end
	end
end

-- Downgrade each city's City Hall by one level (and its law-enforcement building)
local function ChangeACBuildings(player)
	local isRome = (CIV_ROME ~= nil and player:GetCivilizationType() == CIV_ROME)

	for city in player:Cities() do
		-- Find current city hall level (2..5), same precedence as original
		local level
		for i = 2, 5 do
			local id = CITY_HALL[i]
			if id and city:IsHasBuilding(id) then
				level = i
				break
			end
		end

		if level then
			if level == 2 then
				if B_CONSTABLE and city:IsHasBuilding(B_CONSTABLE) then
					SetReal(city, B_CONSTABLE, 0)
					SetReal(city, B_ROMAN_SENATE, 0)
				end

			elseif level == 3 then
				if B_SHERIFF_OFFICE and city:IsHasBuilding(B_SHERIFF_OFFICE) then
					SetReal(city, B_SHERIFF_OFFICE, 0)
					if isRome then
						SetReal(city, B_CONSTABLE, 0)
						SetReal(city, B_ROMAN_SENATE, 1)
					else
						SetReal(city, B_CONSTABLE, 1)
					end
				end

			elseif level == 4 then
				if B_POLICE_STATION and city:IsHasBuilding(B_POLICE_STATION) then
					SetReal(city, B_POLICE_STATION, 0)
					SetReal(city, B_SHERIFF_OFFICE, 1)
				end

			elseif level == 5 then
				if B_PROCURATORATE and city:IsHasBuilding(B_PROCURATORATE) then
					SetReal(city, B_PROCURATORATE, 0)
					SetReal(city, B_POLICE_STATION, 1)
				end
			end

			-- Exactly one hall level (level-1) remains
			for i = 1, 5 do
				SetReal(city, CITY_HALL[i], (i == level - 1) and 1 or 0)
			end
			dprint("AC building changed!")
		end
	end
end

-- Dispatch table: policyID -> handler (skips entries missing from the database)
local PolicyHandlers = {}
if POLICY_DICTATORSHIP_PROLETARIAT then PolicyHandlers[POLICY_DICTATORSHIP_PROLETARIAT] = ChangeACBuildings end
if POLICY_REPRESENTATION           then PolicyHandlers[POLICY_REPRESENTATION]           = ReducePolicyCost end
if POLICY_MONARCHY                 then PolicyHandlers[POLICY_MONARCHY]                 = AddAdditionalManpower end
if POLICY_ARISTOCRACY              then PolicyHandlers[POLICY_ARISTOCRACY]              = FasterFoodGrowth end

local function PolicyAdoptedEffects(playerID, policyID)
	if policyID == nil then return end

	local handler = PolicyHandlers[policyID]
	if handler == nil then return end -- most policies exit here, cheaply

	local player = Players[playerID]
	if player == nil then return end
	if HUMAN_ONLY and not player:IsHuman() then return end
	if player:GetNumCities() < 1 then return end

	handler(player)
end
GameEvents.PlayerAdoptPolicy.Add(PolicyAdoptedEffects)

print("New Policy Effects Check Pass!")