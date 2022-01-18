-- Civ 6 Style City Names
-- Core Functions
--=======================================================================================================================
-- Functions
--=======================================================================================================================
-- GetRandom
------------------------------------------------------------------------------------------------------------------------
function GetRandom(lower, upper)
	return Game.Rand((upper + 1) - lower, "") + lower
end
------------------------------------------------------------------------------------------------------------------------
-- Shuffle
------------------------------------------------------------------------------------------------------------------------
local function Shuffle(t)
  local n = #t -- gets the length of the table 
  while n > 1 do -- only run if the table has more than 1 element
    local k = math.random(1,n) -- get a random number
    t[n], t[k] = t[k], t[n]
    n = n - 1
 end
 return t
end
------------------------------------------------------------------------------------------------------------------------
-- CollectCityNames
-- This function compiles a list of all city names possible based off existing civs in the game
-- It is possible to exclude a specific player's cities.
------------------------------------------------------------------------------------------------------------------------
function CollectCityNames(iPlayerToExclude)

	if not(iPlayerToExclude) then iPlayerToExclude = -1 end
	local tPlayerNames = {}
	local tCityNames = {}

	for iPlayer, pPlayer in pairs(Players) do

		if iPlayer ~= iPlayerToExclude and not(pPlayer:IsMinorCiv()) and not(pPlayer:IsBarbarian()) then

			tPlayerNames[iPlayer] = {}
			if GameInfo.Civilizations[pPlayer:GetCivilizationType()] then
				local sCivType = GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type
				local sQuery = "CivilizationType = '" .. sCivType .. "'"

				for tRow in GameInfo.Civilization_CityNames(sQuery) do
					 table.insert(tCityNames, tRow.CityName)
					 table.insert(tPlayerNames[iPlayer], tRow.CityName)
				end
			end
		end
	end

	local tShuffledNames = {}
	while #tShuffledNames < #tCityNames do
		for iPlayer, pPlayer in pairs(Players) do

			if tPlayerNames[iPlayer] and #tPlayerNames[iPlayer] > 0 then
				table.insert(tShuffledNames, Locale.ConvertTextKey(tPlayerNames[iPlayer][#tPlayerNames[iPlayer]]))
				tPlayerNames[iPlayer][#tPlayerNames[iPlayer]] = nil
			end

		end		
	end

	return tShuffledNames
end
------------------------------------------------------------------------------------------------------------------------
-- GrabRandomName_Weighted
------------------------------------------------------------------------------------------------------------------------
function GrabRandomName_Weighted(tCityNames)
	
	local iEligible = 5 -- How many of the top unused names are eligible?
	local iRemaining = #tCityNames - tCityNames.Used
	if iEligible > iRemaining then iEligible = iRemaining end

	local tPool = {}

	for iKey, tName in ipairs(tCityNames) do
		if not(tName.Used) then
			for iNum = 1, iEligible do
				table.insert(tPool, iKey)
			end
			iEligible = iEligible - 1
		end
		if iEligible < 1 then break end
	end

	local iFinalKey = tPool[GetRandom(1, #tPool)]

	return iFinalKey
end
------------------------------------------------------------------------------------------------------------------------
-- CompileNameList
------------------------------------------------------------------------------------------------------------------------
function CompileNameList(iPlayer)

	local pPlayer = Players[iPlayer]
	local sCivType = GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type
	print(sCivType)
	local sQuery = "CivilizationType = '" .. sCivType .. "'"

	local tCityNames = {}
	tCityNames.Used = 1

	for tRow in GameInfo.Civilization_CityNames(sQuery) do
		table.insert(tCityNames, 
			{
				Name = tRow.CityName,
				Used = false,
			}
		)
	end

	-- The Capital ALWAYS comes first
	pPlayer:AddCityName(Locale.ConvertTextKey(tCityNames[1].Name))
	tCityNames[1].Used = true

	-- Then keep adding cities while there are more cities to add.
	while tCityNames.Used < #tCityNames do
	
		local iKey = GrabRandomName_Weighted(tCityNames)
		local sName = Locale.ConvertTextKey(tCityNames[iKey].Name)

		tCityNames[iKey].Used = true
		pPlayer:AddCityName(sName)

		tCityNames.Used = tCityNames.Used + 1
	end

	-- Now add ALL THE CITIES (foreign)
	for iNum, sCity in ipairs(g_tShuffledNames) do
		pPlayer:AddCityName(sCity)
	end

end
--=======================================================================================================================
-- Initialise
--=======================================================================================================================
for iPlayer, pPlayer in pairs(Players) do
	if pPlayer:IsEverAlive() and not(pPlayer:IsMinorCiv()) and not(pPlayer:IsBarbarian()) then
		if pPlayer:GetNumCityNames() < 0 then
			print("City Lists have already been randomised: Aborting")
			return 
		end
	end
end

print("Randomising City Lists")
g_tShuffledNames = CollectCityNames()

for iPlayer, pPlayer in pairs(Players) do
	if pPlayer:IsEverAlive() and not(pPlayer:IsMinorCiv()) and not(pPlayer:IsBarbarian()) then
		CompileNameList(iPlayer)
	end
end
--=======================================================================================================================
--=======================================================================================================================