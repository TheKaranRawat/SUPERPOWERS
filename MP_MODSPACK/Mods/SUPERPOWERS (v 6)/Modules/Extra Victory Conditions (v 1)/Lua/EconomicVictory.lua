-- EconomicVictory
-- Author: Stephen
-- DateCreated: 6/14/2014 9:40:58 PM
--------------------------------------------------------------

-- Global Tables
g_EVCEconomicGold = {};
g_EVCEconomicGPTStreak = {};
g_EVCMapNumLuxResources = {};

-- Global Variables
g_EVCEconomicVicotryWon = false;
g_EVCGoldTarget = 10000000;
g_EVCGPTTarget = 10000;

-- Economic Variables
local iStreakTarget = 20;
local tPlayerLuxResources = {};
local iTargetLuxResources = 0;

-- Persistent Data
local db = Modding.OpenSaveData();

-- Check to see if the victory is enabled
local economicVictory = GameInfo.Victories["VICTORY_ECONOMIC"];
local bVictoryEnabled = true;
if db.GetValue("EVC_VICTORY_"..economicVictory.ID) == 0 then
	bVictoryEnabled = false;
end
-- bVictoryEnabled is true by default, to make it compatible with previous version saves

-- Populates the global variables when the game starts or is reloaded
function InitializeEconomicVictoryProgress()
	if bVictoryEnabled then
		GetAmassedGold();
		GetGPTStreakData();
		GetMapResources();

		-- Adjust victory requirements based on difficulty level
		local iHandicapID = GameInfo.HandicapInfos[Game:GetHandicapType()].ID;
		if iHandicapID > 3 then
			local iGPTModifier = (iHandicapID - 3)*50 --GameInfo.HandicapInfos[Game:GetHandicapType()].AIWorkRateModifier;
			g_EVCGPTTarget = g_EVCGPTTarget + iGPTModifier;
			g_EVCGoldTarget = g_EVCGoldTarget + (iHandicapID - 3)*5000;
		end
	end
end

Events.SequenceGameInitComplete.Add(InitializeEconomicVictoryProgress);

-- Calculates Economic Victory progress at the start of each players' turn
function CalculateEconomicVictoryProgress(iPlayer)
	if bVictoryEnabled then
		GetAmassedGold();
		GetGPTStreak(iPlayer);
		GetPlayerResources();

		-- Recalculates resources on the map to account for city-state resources (turn 1) and to catch any changes (such as merchant city-states conquered)
		if (Game.GetElapsedGameTurns() == 1) or (Game.GetElapsedGameTurns() % 10 == 0) then
			iTargetLuxResources = 0;
			GetMapResources();
		end

		-- Determines if the current player has won, and declares them the victor
		-- if they have met the conditions
		local pPlayer = Players[iPlayer];
		--print("Testing for Economic Victory");
		if not pPlayer:IsMinorCiv() and iPlayer ~= 63 then
			--print("Player "..iPlayer.." Gold: "..(g_EVCEconomicGold[iPlayer] or "nil"));
			--print("Player "..iPlayer.." GPT Streak: "..(g_EVCEconomicGPTStreak[iPlayer] or "nil"));
			--print("Player "..iPlayer.." Luxuries: "..(tPlayerLuxResources[iPlayer] or "nil"));
			if (g_EVCEconomicGold[iPlayer] >= g_EVCGoldTarget and g_EVCEconomicGPTStreak[iPlayer] >= iStreakTarget and tPlayerLuxResources[iPlayer] >= iTargetLuxResources) then
				--print("Economic Victory Declared!");
				g_EVCEconomicVicotryWon = true;
				Game.SetWinner(pPlayer:GetTeam(), GameInfo.Victories["VICTORY_ECONOMIC"].ID);
			end
		end
	end
end

GameEvents.PlayerDoTurn.Add(CalculateEconomicVictoryProgress);

function GetAmassedGold()
	--print("GetAmassedGold fires");

	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayer];

		if not pPlayer:IsMinorCiv() and pPlayer:IsEverAlive() then
			local iGold = pPlayer:GetGold();
			--print(pPlayer:GetName().." Gold: "..iGold);

			g_EVCEconomicGold[iPlayer] = iGold;
		end
	end
end

function GetGPTStreak(iPlayer)
	--print("GetGPTStreak fires");

	local pPlayer = Players[iPlayer];

	if not pPlayer:IsMinorCiv() and pPlayer:IsEverAlive() then
		--print(pPlayer:GetName().." GPT: "..pPlayer:CalculateGoldRate());

		local streak = g_EVCEconomicGPTStreak[iPlayer];
		if (streak ~= nil) then
			if (pPlayer:CalculateGoldRate() >= g_EVCGPTTarget) then
				g_EVCEconomicGPTStreak[iPlayer] = streak + 1;
			else
				g_EVCEconomicGPTStreak[iPlayer] = 0;
			end
		else
			g_EVCEconomicGPTStreak[iPlayer] = 0;
		end
	end

	SetGPTStreakData(iPlayer);
end

-- Populates the GPT Streak table using saved data
function GetGPTStreakData()
	--print("GetGPTStreakData fires");

	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayer];

		if pPlayer:IsEverAlive() and Game.GetElapsedGameTurns() > 0 then
			g_EVCEconomicGPTStreak[iPlayer] = db.GetValue("EVC_GPT_"..iPlayer) or 0;
			--print(pPlayer:GetName().." GPT Streak: "..g_EVCEconomicGPTStreak[iPlayer]);
		else
			g_EVCEconomicGPTStreak[iPlayer] = 0;
		end
	end
end

-- Saves the data from the GPT Streak table
function SetGPTStreakData(iPlayer)
	--print("SetGPTStreakData fires");

	local pPlayer = Players[iPlayer];

	if not pPlayer:IsMinorCiv() and pPlayer:IsEverAlive() then
		local iStreak = g_EVCEconomicGPTStreak[iPlayer];
		db.SetValue("EVC_GPT_"..iPlayer, iStreak);
	end
end

function GetMapResources()
	--print("GetMapResources fires");
	for pResource in GameInfo.Resources() do
		local iResource = pResource.ID;
		local iResourceCount = Map.GetNumResources(iResource);
		if (iResourceCount > 0) then
			if (pResource.ResourceClassType == "RESOURCECLASS_LUXURY") then
				g_EVCMapNumLuxResources[iResource] = iResourceCount;
				iTargetLuxResources = iTargetLuxResources + 1;
			end
		end
	end
	--print("Target Luxes: "..iTargetLuxResources);
end

function GetPlayerResources()
	--print("GetPlayerResources fires");

	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		
		local pPlayer = Players[iPlayer];

		if pPlayer:IsEverAlive() then
			tPlayerLuxResources[iPlayer] = 0;

			for k,v in pairs(g_EVCMapNumLuxResources) do
				local iResource = k;
				if pPlayer:GetNumResourceTotal(iResource, true) > 0 then
					tPlayerLuxResources[iPlayer] = tPlayerLuxResources[iPlayer] + 1;
				end
			end
			--print(pPlayer:GetName().." Luxes: "..tPlayerLuxResources[iPlayer]);
		end
	end
end