-- ReligiousVictory
-- Author: Stephen
-- DateCreated: 6/12/2014 9:25:15 PM
--------------------------------------------------------------

-- Global Tables
g_EVCReligiousSpread = {};
g_EVCReligiousFollowers = {};
g_EVCReligiousHolyCities = {};

-- Global Variables
g_EVCMaxFollowers = 0;
g_EVCMaxHolyCities = 0;
g_EVCReligiousVictoryWon = false;

-- Persistent Data
local db = Modding.OpenSaveData();

-- Check to see if the victory is enabled
local religiousVictory = GameInfo.Victories["VICTORY_RELIGIOUS"];
local bVictoryEnabled = true;
if db.GetValue("EVC_VICTORY_"..religiousVictory.ID) == 0 then
	bVictoryEnabled = false;
end
-- bVictoryEnabled is true by default, to make it compatible with previous version saves

-- Populates the global variables when the game starts or is reloaded
function InitializeReligiousVictoryProgress()
	if bVictoryEnabled then
		GetReligionSpread();
		GetReligionFollowers();
		GetReligionHolyCities();

		local eWorldSize = Map.GetWorldSize();
		local worldSize = GameInfo.Worlds[eWorldSize];
		g_EVCMaxFollowers = round(worldSize.EstimatedNumCities*6*0.7) + 20;
		g_EVCMaxHolyCities = worldSize.MaxActiveReligions;
	end
end

Events.SequenceGameInitComplete.Add(InitializeReligiousVictoryProgress);

-- Calculates Religious Victory progress at the start of each players' turn
function CalculateReligiousVictoryProgress(iPlayer)
	if bVictoryEnabled then
		GetReligionSpread();
		GetReligionFollowers();
		GetReligionHolyCities();

		-- Determines if the current player has won, and declares them the victor
		-- if they have met the conditions
		local pPlayer = Players[iPlayer];
		if pPlayer:HasCreatedReligion() then
			local eReligion = pPlayer:GetReligionCreatedByPlayer();
			--print("Testing for Religious Victory");
			--print("Player "..iPlayer.." Spread: "..g_EVCReligiousSpread[eReligion]);
			--print("Player "..iPlayer.." Followers: "..g_EVCReligiousFollowers[eReligion]);
			--print("Player "..iPlayer.." Holy Cities: "..g_EVCReligiousHolyCities[eReligion]);
			if ((g_EVCReligiousSpread[eReligion] >= 70) and (g_EVCReligiousFollowers[eReligion] >= g_EVCMaxFollowers) and (g_EVCReligiousHolyCities[eReligion] == g_EVCMaxHolyCities)) then
				--print("Religious Victory Declared!");
				g_EVCReligiousVictoryWon = true;
				Game.SetWinner(pPlayer:GetTeam(), GameInfo.Victories["VICTORY_RELIGIOUS"].ID);
			end
		end
	end
end

GameEvents.PlayerDoTurn.Add(CalculateReligiousVictoryProgress);

-- Updates the spread table with the new percentages for each religion
function GetReligionSpread()
	--print("GetReligionSpread fires");

	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayerLoop];

		if pPlayer:IsEverAlive() then
			if pPlayer:HasCreatedReligion() then
				
				local eReligion = pPlayer:GetReligionCreatedByPlayer();
				--local religion = GameInfo.Religions[eReligion];
				--print(religion.Description);
				local iCitiesFollowing = Game.GetNumCitiesFollowing(eReligion);
				--print("Cities Following: "..iCitiesFollowing);
				local iTotalCities = Game.GetNumCities();
				--print("Total Cities: "..iTotalCities);
				local fSpread = round((iCitiesFollowing/iTotalCities)*100);
				--print("Spread: "..fSpread);

				g_EVCReligiousSpread[eReligion] = fSpread;
			end
		end
	end
end

-- Updates the followers table with the new numbers for each religion
function GetReligionFollowers()
	--print("GetReligionFollowers fires");

	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayerLoop];

		if pPlayer:IsEverAlive() then
			if pPlayer:HasCreatedReligion() then
				
				local eReligion = pPlayer:GetReligionCreatedByPlayer();
				--local religion = GameInfo.Religions[eReligion];
				--print(religion.Description);
				local iFollowers = CalculateReligionFollowers(eReligion);
				--print("Followers: "..iFollowers);

				g_EVCReligiousFollowers[eReligion] = iFollowers;

			end
		end
	end
end

function CalculateReligionFollowers(eReligion)
	--print("CalculateReligionFollowers fires");

	local followers = 0;

	-- Cycle through the major players
	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayerLoop];

		if pPlayer:IsEverAlive() then
			for  pCity in pPlayer:Cities() do
					if pCity ~= nil then
						followers = followers + pCity:GetNumFollowers(eReligion);
					else
						--print("Player "..pPlayer:GetName().." has a nil city");
					end
			end
		end
	end

	-- Cycle through the city states
	for iPlayerLoop=GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS-1, 1 do 

		local pPlayer = Players[iPlayerLoop];

		if pPlayer:IsEverAlive() then
			for  pCity in pPlayer:Cities() do
					if pCity ~= nil then
						followers = followers + pCity:GetNumFollowers(eReligion);
					else
						--print("Player "..pPlayer:GetName().." has a nil city");
					end
			end
		end
	end

	return followers;
end

function GetReligionHolyCities()
	--print("GetReligionHolyCities fires");

	local tHolyCities = {};

	local worldSize = GameInfo.Worlds[Map.GetWorldSize()];
	local iMaxHolyCities = worldSize.MaxActiveReligions;

	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayerLoop];

		if pPlayer:IsEverAlive() then
			if pPlayer:HasCreatedReligion() then
				
				local eReligion = pPlayer:GetReligionCreatedByPlayer();
				--local religion = GameInfo.Religions[eReligion];
				--print(religion.Description);
				local pHolyCity = Game.GetHolyCityForReligion(eReligion, iPlayerLoop);
				if pHolyCity ~= nil then
					tHolyCities[eReligion] = Game.GetHolyCityForReligion(eReligion, iPlayerLoop);
					--print("Holy City: "..Game.GetHolyCityForReligion(eReligion, iPlayerLoop):GetName());
				else -- If a religion has no Holy City (most likely due to an inquisitor), then the Holy City requirement must be reduced
					iMaxHolyCities = iMaxHolyCities - 1;
				end

			end
		end
	end

	for k,v in pairs(tHolyCities) do
	
		local eReligion = k;
		local iControlledHolyCities = 0;
		
		for key,val in pairs(tHolyCities) do
			
			local holyCity = val;

			if (eReligion == holyCity:GetReligiousMajority()) then
				iControlledHolyCities = iControlledHolyCities + 1;
			end
		end

		g_EVCReligiousHolyCities[eReligion] = iControlledHolyCities;
	end

	if iMaxHolyCities < worldSize.MaxActiveReligions then
		g_EVCMaxHolyCities = iMaxHolyCities;
	end
end

-- Handy function (borrowed) for rounding numbers, so we can turn floats into integers
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end