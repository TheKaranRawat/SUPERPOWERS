-- Policy_FreeBuildingClass
-- Author: Machiavelli
-- DateCreated: 5/23/2012 6:10:34 PM
--------------------------------------------------------------
-------------
-- Purpose: -
-------------
-- This lua supports the new Policy_FreeBuildingClass* tables
--
------------
-- Design: -
------------
-- Buildings are added when:
-- Whenever a new policy is adopted every city gets all policy buildings.
-- When a new city is founded or captured, it gets all policy buildings.
-- There is special code for handling capital only buildings,
--
-- Buildings are removed when:
-- Each turn at the start of the turn all buildings which are granted by
-- blocked policies and do not have IsRemovedWhenPolicyBlocked == false
-- are removed.
--
-------------------
-- How to expand: -
-------------------
-- If you want to support new xml tables (such as adding a building in 
-- coastal cities) you will need to write code in two spots.
--
-- 1) "Add new Policy_FreeBuilding tables here"
-- Marks the location where you will need to add buildings.  Use the
-- city state code but with a different test in the initial if statement
-- and change the GameInfo table to the new xml table.
--
-- 2) "Remove new Policy_FreeBuilding tables here"
-- Marks the location where you will need to remove buildings.  Use the
-- city state code but with a different test in the initial if statement
-- and change the GameInfo table to the new xml table.
--
------------------------------
-- Known bugs / limitations: -
------------------------------
-- 1) Switching back and forth between mutually exclusive policy branches
-- without adopting a new policy will not enable the newly unblocked policy
-- buildings.
-- 
-----------------------------------------------------
-- Notes to self: How this should have been written -
-----------------------------------------------------
-- 1) Lists of buildings to add/remove should be built once
-- 2) Than used to call addListOfBuildings(cityID, list)
--
-- 1) The end turn check should test to see if the previous player is in anarchy.
-- 2) Only remove buildings if the previous player is in anarchy.

--------------------
-- Private helper functions
--------------------
function GetBuildingTypeFromClass(buildingClass, civilizationTypeID)
	-- Assume it is the default building
	local buildingType = GameInfo.BuildingClasses[buildingClass].DefaultBuilding;

	-- See if this civilization has a unique building for this building class
	for row in GameInfo.Civilization_BuildingClassOverrides() do
		if (GameInfoTypes[row.CivilizationType] == civilizationTypeID and row.BuildingClassType == buildingClass) then
			-- This civilization has a unique building
			buildingType = row.BuildingType;
			return buildingType;
		end
	end

	return buildingType;
end

--------------------
-- functions that add buildings
--------------------
function AddPolicyBuildingsToCity(playerID, cityID)
	local player = Players[playerID];
	local city = player:GetCityByID(cityID);
	local policyID;
	local buildingType;

	------------------------------------------------
	-- Add buildings for Policy_FreeBuildingClass --
	------------------------------------------------
	for row in GameInfo.Policy_FreeBuildingClass() do
		policyID = GameInfoTypes[row.PolicyType];

		if (player:HasPolicy(policyID) and not player:IsPolicyBlocked(policyID)) then
			buildingType = GetBuildingTypeFromClass(row.BuildingClassType, player:GetCivilizationType());
			city:SetNumRealBuilding(GameInfoTypes[buildingType], 1);
		end
	end
	----------------------------------------------------------
	-- Add buildings for Policy_FreeBuildingClassCityStates --
	----------------------------------------------------------
	if(Players[city:GetOriginalOwner()]:IsMinorCiv()) then
		for row in GameInfo.Policy_FreeBuildingClassCityStates() do
			policyID = GameInfoTypes[row.PolicyType];

			if (player:HasPolicy(policyID) and not player:IsPolicyBlocked(policyID)) then
				buildingType = GetBuildingTypeFromClass(row.BuildingClassType, player:GetCivilizationType());
				city:SetNumRealBuilding(GameInfoTypes[buildingType], 1);
			end
		end
	end
	---------------------------------------------
	-- Add new Policy_FreeBuilding tables here --
	---------------------------------------------
end

function AddPolicyBuildingsToCapital(playerID)
	local player = Players[playerID];
	local capital = player:GetCapitalCity();
	local policyID;
	local buildingType;

	for row in GameInfo.Policy_FreeBuildingClassCapital() do
		policyID = GameInfoTypes[row.PolicyType];

		if (player:HasPolicy(policyID) and not player:IsPolicyBlocked(policyID)) then
			-- Determine what buildingType to give them based on the buildingClass
			buildingType = GetBuildingTypeFromClass(row.BuildingClassType, player:GetCivilizationType());
			-- Give the city the building
			capital:SetNumRealBuilding(GameInfoTypes[buildingType], 1);
		end
	end
end

--------------------
-- functions that call the building adders
--------------------
function PolicyBuildingOnCityFound(playerID, iX, iY)
	-- Args are: playerID and cityID
	AddPolicyBuildingsToCity(playerID, Map.GetPlot(iX, iY):GetPlotCity():GetID());
end
GameEvents.PlayerCityFounded.Add(PolicyBuildingOnCityFound);

function PolicyBuildingOnCityCapture(oldPlayerID, bCapital, iX, iY, newPlayerID, conquest, conquest2)
	local oldPlayer = Players[oldPlayerID];
	local newPlayer = Players[newPlayerID];
	
	
----------- SP Bug fix, it may crash the game for certain AI's behavior!------------
	
	if not oldPlayer:IsHuman() or not newPlayer:IsHuman()  then	
		print ("SP PolicyFreeBuilding Bug Fix!")
		return
	end
	
	
	local city =  Map.GetPlot(iX, iY):GetPlotCity();

	-- If the old player just lost their capital, they will need to have their capital-only policy buildings replaced
	if(bCapital and oldPlayer:IsAlive() and not oldPlayer:IsMinorCiv() and not oldPlayer:IsBarbarian()) then
		AddPolicyBuildingsToCapital(oldPlayerID);
	end

	-- If the new player just recovered their capital, they will need to have their capital-only policy buildings moved
	if newPlayer:GetCapitalCity():GetID() == city:GetID() then
		local policyID;
		local buildingType;
		local buildingTypeID;
		-- Remove capital only buildings from the new player's cities
		for cityToRemove in newPlayer:Cities() do
			for row in GameInfo.Policy_FreeBuildingClassCapital() do
				policyID = GameInfoTypes[row.PolicyType];
				-- Only remove the building if the player has the policy, but it is disabled
				if(newPlayer:HasPolicy(policyID)) then
					-- Determine what buildingType to remove based on the buildingClass
					buildingType = GetBuildingTypeFromClass(row.BuildingClassType, newPlayer:GetCivilizationType());
					buildingTypeID = GameInfoTypes[buildingType];

					-- If the city has the building, remove it
					if(cityToRemove:IsHasBuilding(buildingTypeID)) then
						-- Remove any specialists from the building
						while(cityToRemove:GetNumSpecialistsInBuilding(buildingTypeID) > 0) do
							cityToRemove:DoTask(TaskTypes.TASK_REMOVE_SPECIALIST, 1, buildingTypeID, playerID); --The second arg doesn't seem to do anything, don't know what the forth arg does
						end
						-- Remove the building
						cityToRemove:SetNumRealBuilding(GameInfoTypes[buildingType], 0);
					end
				end
			end
		end
		-- Add back the capital-only policy buildings
		AddPolicyBuildingsToCapital(newPlayerID);
	end

	-- Add the new player's policy buildings to the city they just captured
	AddPolicyBuildingsToCity(newPlayerID, city:GetID());
end
GameEvents.CityCaptureComplete.Add(PolicyBuildingOnCityCapture);

function PolicyBuildingOnAdoptPolicy(playerID, policyTypeID)
	AddPolicyBuildingsToCapital(playerID);

	for city in Players[playerID]:Cities() do
		AddPolicyBuildingsToCity(playerID, city:GetID());
	end
end
GameEvents.PlayerAdoptPolicy.Add(PolicyBuildingOnAdoptPolicy);
GameEvents.PlayerAdoptPolicyBranch.Add(PolicyBuildingOnAdoptPolicy);

--------------------
-- functions for removing buildings
--------------------
function RemoveAllBlockedPolicyBuildings(playerID)
	local player = Players[playerID];
	local capital = player:GetCapitalCity();
	local policyID;
	local buildingType;
	local buildingTypeID;
	
	
	

--	if(not player:IsAlive() or player:IsMinorCiv() or player:IsBarbarian()) then
--		-- Do nothing
		
		
		----------- SP Bug fix, it may crash the game for certain AI's behavior!------------	
	if not player:IsHuman() then
		print ("SP PolicyFreeBuilding Bug Fix!")
	else
		--------------------------------------------------------
		-- Remove any blocked Policy_FreeBuildingClassCapital --
		--------------------------------------------------------
		for row in GameInfo.Policy_FreeBuildingClassCapital() do
			policyID = GameInfoTypes[row.PolicyType];

			-- Only remove the building if the player has the policy, but it is disabled and the building gets removed
			if(player:HasPolicy(policyID) and player:IsPolicyBlocked(policyID)) then
				-- Determine what buildingType to remove based on the buildingClass
				buildingType = GetBuildingTypeFromClass(row.BuildingClassType, player:GetCivilizationType());
				buildingTypeID = GameInfoTypes[buildingType];

				-- If the city has the building, remove it
				if(capital:IsHasBuilding(buildingTypeID)) then
					-- Remove any specialists from the building
					while(capital:GetNumSpecialistsInBuilding(buildingTypeID) > 0) do
						city:DoTask(TaskTypes.TASK_REMOVE_SPECIALIST, 1, buildingTypeID, playerID); --The second arg doesn't seem to do anything, don't know what the forth arg does
					end
					-- Remove the building
--					city:SetNumRealBuilding(GameInfoTypes[buildingType], 0);
				end
			end
		end
		-------------------------------------------------
		for city in player:Cities() do
			-------------------------------------------------
			-- Remove any blocked Policy_FreeBuildingClass --
			-------------------------------------------------
			for row in GameInfo.Policy_FreeBuildingClass() do
				policyID = GameInfoTypes[row.PolicyType];

				if(player:HasPolicy(policyID) and player:IsPolicyBlocked(policyID) and row.IsRemovedWhenPolicyBlocked) then
					buildingType = GetBuildingTypeFromClass(row.BuildingClassType, player:GetCivilizationType());
					if(city:IsHasBuilding(buildingTypeID)) then
						while(city:GetNumSpecialistsInBuilding(buildingTypeID) > 0) do
							city:DoTask(TaskTypes.TASK_REMOVE_SPECIALIST, 1, buildingTypeID, playerID); --The second arg doesn't seem to do anything, don't know what the forth arg does
						end
						city:SetNumRealBuilding(GameInfoTypes[buildingType], 0);
					end
				end
			end
			-----------------------------------------------------------
			-- Remove any blocked Policy_FreeBuildingClassCityStates --
			-----------------------------------------------------------
			if(Players[city:GetOriginalOwner()]:IsMinorCiv()) then
				for row in GameInfo.Policy_FreeBuildingClassCityStates() do
					policyID = GameInfoTypes[row.PolicyType];

					if(player:HasPolicy(policyID) and player:IsPolicyBlocked(policyID) and row.IsRemovedWhenPolicyBlocked) then
						buildingType = GetBuildingTypeFromClass(row.BuildingClassType, player:GetCivilizationType());
						if(city:IsHasBuilding(buildingTypeID)) then
							while(city:GetNumSpecialistsInBuilding(buildingTypeID) > 0) do
								city:DoTask(TaskTypes.TASK_REMOVE_SPECIALIST, 1, buildingTypeID, playerID); --The second arg doesn't seem to do anything, don't know what the forth arg does
							end
							city:SetNumRealBuilding(GameInfoTypes[buildingType], 0);
						end
					end
				end
			end
			------------------------------------------------
			-- Remove new Policy_FreeBuilding tables here --
			------------------------------------------------
		end -- for city in player:Cities() do
	end
end
GameEvents.PlayerDoTurn.Add(RemoveAllBlockedPolicyBuildings);