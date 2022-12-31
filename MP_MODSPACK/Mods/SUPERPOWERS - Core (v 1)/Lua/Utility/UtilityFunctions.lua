-- UtilityFunctions
-- Author: linco
-- DateCreated: 2/13/2016 11:16:01 AM
--------------------------------------------------------------





------------------------------------------------Players Functions------------------------------------------------------

function GetPlayerByCivilization(civilizationType)--------------Get Player by civilizationType
	for _, pPlayer in pairs(Players) do
		if pPlayer:GetCivilizationType() == civilizationType then 
			return pPlayer
		end
	end
end




-------------If two players are AT WAR?

function PlayersAtWar(iPlayer,ePlayer)
	local iTeam = Teams[iPlayer:GetTeam()];
	local eTeamIndex = ePlayer:GetTeam();
	if iTeam:IsAtWar(eTeamIndex) then
	   return true;
	else
	   return false;
	end
end


---------If the AI player is at war with Human?

function PlayerAtWarWithHuman(player) 
	local CurrentPlayerTeam = Teams[player:GetTeam()]
	
	for playerID,HumanPlayer in pairs(Players) do
		if HumanPlayer:IsHuman() then
			
			
			local HumanPlayerTeamIndex = HumanPlayer:GetTeam()
			
			if CurrentPlayerTeam:IsAtWar(HumanPlayerTeamIndex) then
				print ("Human is at war with this AI!")
			   return true
			else
			   return false
			end
			
			break
		end	
	end	
end





---------If the AI has the chance to become the Boss?
function AICanBeBoss (player)

local WorldCityTotal = Game.GetNumCities() 
local WorldPopTotal = Game.GetTotalPopulation()

local AICityCount = player:GetNumCities()
local AIPopCount = player:GetTotalPopulation()
local AITourismOutput = player:GetTourism()

--print ("World Cities Count:"..WorldCityTotal)
--print ("World Population Count:"..WorldPopTotal)
--

	if player:IsHuman() then
		return false
	end
	
	if player:IsBarbarian() or player:IsMinorCiv() then
		print ("Minors are Not available!")
    	return
	end	
		
		
	if AICityCount <= 1 or AIPopCount <= 1 or AITourismOutput <= 1 then  
		return false
	end
	
	

	if AICityCount >= 16 or AICityCount >= WorldCityTotal/10 or AIPopCount >= WorldPopTotal/10 or AITourismOutput > 600 then
		print ("This AI can become a Boss!")
		return true
	else	
		return false
	end
end




--
-----------Are the two players in different continents?
--function PlayersInDifferentContinets (iPlayer,pPlayer)
--
--
--
--
--end

-----------------------------------------------Plot Functions------------------------------------------------------


function PlotIsVisibleToHuman(plot) --------------------Is the plot can be seen by Human
	for playerID,HumanPlayer in pairs(Players) do
		if HumanPlayer:IsHuman() then
		   local HumanPlayerTeamIndex = HumanPlayer:GetTeam()
		   if plot:IsVisible(HumanPlayerTeamIndex) then
		   
		   	    print ("Human can see this plot! So stop Cheating!")	
		   		return true
			else
				print ("Human CANNOT see this plot! Let's Cheat!")
			    return false
			end
			
			break
		   
		end
	end
end





function isFriendlyCity(pUnit, pCity)--------------Is the plot a Friendly City?
	  local bFriendly = (pCity:GetTeam() == pUnit:GetTeam())
	--  bFriendly = (bFriendly and not pCity:IsPuppet())
	  bFriendly = (bFriendly and not pCity:IsResistance())
	  bFriendly = (bFriendly and not pCity:IsRazing())
	  bFriendly = (bFriendly and not (pCity:IsOccupied() and not pCity:IsNoOccupiedUnhappiness()))
	  return bFriendly
end






------------------------------------------------Military/Unit Functions------------------------------------------------------





function GetCivSpecificUnit(player, sUnitClass)
	  local sUnitType = nil
	  local sCivType = GameInfo.Civilizations[player:GetCivilizationType()].Type
	
	  for pOverride in GameInfo.Civilization_UnitClassOverrides{CivilizationType = sCivType, UnitClassType = sUnitClass} do
	    sUnitType = pOverride.UnitType
	    break
	  end
	
	  if (sUnitType == nil) then
	    sUnitType = GameInfo.UnitClasses[sUnitClass].DefaultUnit
	  end
	
	  return sUnitType
end



function GetUpgradeUnit(player, sUnitType)
	  local sNewUnitClass = GameInfo.Units[sUnitType].GoodyHutUpgradeUnitClass
	
	  if (sNewUnitClass ~= nil) then
	    local sUpgradeUnitType = GetCivSpecificUnit(player, sNewUnitClass)
	
	    if (sUpgradeUnitType ~= nil and Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[GameInfo.Units[sUpgradeUnitType].PrereqTech])) then
	      return sUpgradeUnitType
	    end
	  end
	
	  return nil
end





--
--function GetUnitPurchaseGoldCost(player, unitID)
--	if player == nil or unitID == nil then
--		return
--	end	
--	
--	local sUnitType = GetCivSpecificUnit(player, unitID)   	
--    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
--	
--	
--	local unit = GameInfo.Units[sUnitType]
--	
--	local productionCost = unit.Cost
--	if productionCost > 1 then	
--		local UnitGoldCost = (productionCost * GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION ) ^ GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT
--		print ("Unit Gold Cost:"..UnitGoldCost)
--	end
--	return UnitGoldCost
--end
--


function SatelliteLaunchEffects(unit,city,player)
	
	if not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID) then 
		return 
	end
	
	if player:GetNumCities() < 1 then
		return
	end
	
	if unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_SPUTNIK then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_SPUTNIK"],1)	
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RECONNAISSANCE then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RECONNAISSANCE"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RECONNAISSANCE_SMALL"],1)		
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_GPS then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_GPS"],1)		
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_APOLLO11 then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_APOLLO11"],1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_HUBBLE then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_HUBBLE"],1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_WEATHER then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_WEATHER"],1)		
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_TIANGONG then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_TIANGONG"],1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ECCM then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_ECCM"],1)	
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ENVIRONMENT then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_ENVIRONMENT"],1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ANTIFALLOUT then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_ANTIFALLOUT"],1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RESOURCEPLUS then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RESOURCEPLUS"],1)		
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ORBITAL_STRIKE then
		local pPlot = city
		if pPlot~= nil then
			city:GetCityIndexPlot()
			player:InitUnit(GameInfo.Units.UNIT_ORBITAL_STRIKE.ID, pPlot:GetX(), pPlot:GetY(),UNITAI_MISSILE_AIR)
			print ("Rods from God built!")
		end	
	end
	

	
	
	SatelliteEffectsGlobal(unit)
	
	unit:Kill()
	
	print ("Satellite unit removed and its effect is ON!")
	
end-----------function END




function SatelliteEffectsGlobal(unit)

	if not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID) then 
		return 
	end


	if unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_WEATHER then
		print ("Satellite Effects Global:Weather Control!")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)		
		
			if plot:GetFeatureType() == FeatureTypes.NO_FEATURE and not plot:IsHills() and not plot:IsMountain() then
				if plot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					local pPlotX = plot:GetX()
					local pPlotY = plot:GetY()
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, 2)
				end	
			end	
		end	
		
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ENVIRONMENT then
		print ("Satellite Effects Global:Environment Transform!")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)		
	
		
			if plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if plot:GetFeatureType() == FeatureTypes.NO_FEATURE and not plot:IsHills() and not plot:IsMountain() then
					local pPlotX = plot:GetX()
					local pPlotY = plot:GetY()
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, 1)
				end	
			end	
			
			if plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW and not plot:IsMountain() then
				local pPlotX = plot:GetX()
				local pPlotY = plot:GetY()
				if plot:IsHills() then 
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, 2)
				else	
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, 1)
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, 1)	
				end			
			end	
				
		end	
		
		

	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ANTIFALLOUT then
		print ("Satellite Effects Global:Remove Fallout!")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)		

			if plot:GetFeatureType() == FeatureTypes.FEATURE_FALLOUT then
				plot:SetFeatureType(-1)
			end	
		end	
	

	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RESOURCEPLUS then
		print ("Satellite Effects Global:Resource Bonus")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)		

			if plot:GetNumResource() >= 2 and not plot:IsCity() then
			------------------If you only change the resource amount on the plot, the player's resource quantity will not change! You must remove then add the improvement to make the change!
				 if plot:GetResourceType() == GameInfoTypes.RESOURCE_IRON or plot:GetResourceType() == GameInfoTypes.RESOURCE_COAL or plot:GetResourceType() == GameInfoTypes.RESOURCE_ALUMINUM or plot:GetResourceType() == GameInfoTypes.RESOURCE_URANIUM then
					plot:SetImprovementType (-1)	
					plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_MINE.ID)	
					
				 elseif plot:GetResourceType() == GameInfoTypes.RESOURCE_OIL then
					plot:SetImprovementType (-1)
				 	if plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_WELL.ID) then
				 		plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_WELL.ID)	
				 	elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID) then
				 		plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID) 	
				 	end	
				 				 
				 end
				 
				plot:ChangeNumResource (4)
					
			
			end	
		end	

	else
		print ("Satellite Effects Global:Player! ")
		for playerID,player in pairs(Players) do
			if player ~= nil and player:GetNumCities() > 0 and not player:IsMinorCiv() and not player:IsBarbarian() then  
				local CapitalCity = player:GetCapitalCity()
				if unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_GPS then
					CapitalCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_GPS_SMALL"],1)
				elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_GPS then
					CapitalCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RECONNAISSANCE_SMALL"],1)	
				elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_APOLLO11 then
					player:SetNumFreeTechs(1)
				elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_HUBBLE then
					  local pPlot = CapitalCity				  
					  local NewUnit = player:InitUnit(GameInfoTypes.UNIT_SCIENTIST, pPlot:GetX(), pPlot:GetY(), UNITAI_SCIENTIST)	
	   				  NewUnit:JumpToNearestValidPlot()
	   			elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_TIANGONG then
				      local pPlot = CapitalCity				  
					  local NewUnit = player:InitUnit(GameInfoTypes.UNIT_ENGINEER, pPlot:GetX(), pPlot:GetY(), UNITAI_ENGINEER)	
	   				  NewUnit:JumpToNearestValidPlot()	
				end	
			end
		end	
	end
	
	
	
end-----------function END































----------------------------------City Functions----------------------------





-----------International Immigration Counter Check
function CheckMoveOutCounter(MoveOutPlayerID,MoveInPlayerID)

	local MoveOutPlayer = Players[MoveOutPlayerID]-----------This nation's population tries to move out
	local MoveInPlayer = Players[MoveInPlayerID]-----------Move to this nation
	
	if MoveOutPlayer == nil or MoveInPlayer == nil then
		print ("No players")
		return
	end


	local MoveOutPlayerName = MoveOutPlayer:GetName()
	print ("Move Out Player:"..MoveOutPlayerName)
	local MoveInPlayerName = MoveInPlayer:GetName()
	print ("Move In Player:"..MoveInPlayerName)
	
	local MoveOutTeam = Teams[MoveOutPlayer:GetTeam()]
	local MoveInTeam = Teams[MoveInPlayer:GetTeam()]

	local MoveOutCounterBase = MoveInPlayer:GetInfluenceLevel(MoveOutPlayerID)
	local MoveOutCounterMod = 1
	
	print ("Move Out Counter by the Influence Base:"..MoveOutCounterBase)




------------------------------------------Player is not able to accept--------------------
	
	
	if MoveInPlayer:GetExcessHappiness() <= 0 or MoveInPlayer:GetNumResourceAvailable(GameInfoTypes["RESOURCE_CONSUMER"], true) <= 0  then
		MoveOutCounterBase = 0
		print ("The Player is unhappy or No Resources!"..MoveOutCounterBase)
	end
	
	if MoveInPlayer:GetCurrentEra() >= GameInfo.Eras["ERA_MODERN"].ID and MoveInPlayer:GetNumResourceAvailable(GameInfoTypes["RESOURCE_ELECTRICITY"], true) <= 0  then
		MoveOutCounterBase = 0
		print ("The Player is lacking of ELECTRICITY!"..MoveOutCounterBase)
	end
	
	
------------------------------------------Diplomacy Modifier--------------------	
	if PlayersAtWar(MoveOutPlayer,MoveInPlayer) then
		MoveOutCounterBase = 0 
		print ("At War! No Immigration:"..MoveOutCounterBase)
	end
	
	if MoveInTeam:IsAllowsOpenBordersToTeam(MoveOutPlayer:GetTeam()) then
		MoveOutCounterMod = MoveOutCounterMod + 1
		print ("Open Borders +100% "..MoveOutCounterMod)
	end
		
	if MoveOutPlayer:IsDenouncedPlayer(MoveInPlayerID) or MoveInPlayer:IsDenouncedPlayer(MoveOutPlayerID) then
		MoveOutCounterMod = MoveOutCounterMod -0.5
		print ("Denouncing! -50% "..MoveOutCounterMod)
	end
	
	if MoveOutPlayer:IsDoF(MoveInPlayerID) then
		MoveOutCounterMod = MoveOutCounterMod + 0.5
		print ("DOF! +50% "..MoveOutCounterMod)
	end
	
	
------------------------------------------Religion Modifier--------------------------------		
	if MoveInPlayer:GetReligionCreatedByPlayer() ~= nil and MoveInPlayer:GetReligionCreatedByPlayer() > 0 then
		local MoveInPlayerReligion = MoveInPlayer:GetReligionCreatedByPlayer()		
--		print ("MoveInPlayerReligion:"..MoveInPlayerReligion)
		if MoveOutPlayer:HasReligionInMostCities(MoveInPlayerReligion) then
			MoveOutCounterMod = MoveOutCounterMod + 1
			print ("Same Religion +100%"..MoveOutCounterMod)	
		end
	end	
		
		
------------------------------------------Happiness Modifier--------------------------------			
		
	if MoveInPlayer:IsHuman() then

		if MoveInPlayer:GetExcessHappiness() > 150 then
			MoveOutCounterMod = MoveOutCounterMod + 0.5
		elseif MoveInPlayer:GetExcessHappiness() <= 150 and MoveInPlayer:GetExcessHappiness()> 100 then
			MoveOutCounterMod = MoveOutCounterMod + 0.25
		elseif MoveInPlayer:GetExcessHappiness()<= 50 and MoveInPlayer:GetExcessHappiness() > 20 then
			MoveOutCounterMod = MoveOutCounterMod - 0.25
		elseif MoveInPlayer:GetExcessHappiness()<= 20 and MoveInPlayer:GetExcessHappiness() > 0 then
			MoveOutCounterMod = MoveOutCounterMod - 0.5	
		elseif MoveInPlayer:GetExcessHappiness()<= 0 then
			MoveOutCounterMod = 0
		end	
		
		print ("Human Move in Special Mod  "..MoveOutCounterMod)	
	end		
		
		
	if MoveOutPlayer:IsHuman() then
		
		if MoveOutPlayer:GetExcessHappiness() >= 150 then
			MoveOutCounterMod = MoveOutCounterMod - 0.5
		elseif MoveInPlayer:GetExcessHappiness() <= 150 and MoveInPlayer:GetExcessHappiness()> 100 then
			MoveOutCounterMod = MoveOutCounterMod - 0.25
		elseif MoveInPlayer:GetExcessHappiness() <= 20 and MoveInPlayer:GetExcessHappiness() > 0 then
			MoveOutCounterMod = MoveOutCounterMod + 0.25
		elseif MoveOutPlayer:GetExcessHappiness() <= 0 then
			MoveOutCounterMod = MoveOutCounterMod + 0.5
		end	
		
		print ("Human Move out Special Mod  "..MoveOutCounterMod)	
	end	
	
	
------------------------------------------Ideology Modifier--------------------------------		
--	if MoveOutPlayer:GetCurrentEra() >= 5 then
--		local MoveOutIdeology = MoveOutPlayer:GetLateGamePolicyTree()
--	    local MoveInIdeology = MoveInPlayer:GetLateGamePolicyTree()
--	    local PreferedIdeology = MoveOutPlayer:GetPublicOpinionPreferredIdeology() 
--	    
--	    if MoveOutIdeology == MoveInIdeology then
--	    	MoveOutCounterMod = MoveOutCounterMod + 0.25
--	    	print ("Same Ideology +25%"..MoveOutCounterMod)	
--	    else
--	    	if PreferedIdeology > -1 and PreferedIdeology == MoveInIdeology then
--	    		MoveOutCounterMod = MoveOutCounterMod
--	    		print ("Different Ideology but preferred -25%"..MoveOutCounterMod)		
--	    	else
--	    		MoveOutCounterMod = MoveOutCounterMod - 0.25
--	    		print ("Different Ideology -25%"..MoveOutCounterMod)		
--	    	end 	    	
--	    end
--	end
	
	if MoveOutPlayer:HasPolicy(GameInfoTypes["POLICY_IRON_CURTAIN"]) then
		MoveOutCounterMod = MoveOutCounterMod - 0.5
		print ("Iron Curtain -50%"..MoveOutCounterMod)	
	end
	
	if MoveInPlayer:HasPolicy(GameInfoTypes["POLICY_TREATY_ORGANIZATION"]) then
		MoveOutCounterMod = MoveOutCounterMod + 0.5
		print ("Freedom of Speech +50%"..MoveOutCounterMod)	
	end
	
	
	if MoveOutCounterMod < 0 then
		MoveOutCounterMod = 0
	end
	
	local MoveoutCounterFinal = MoveOutCounterMod * MoveOutCounterBase
	
	
	print ("MoveoutCounterFinal:"..MoveoutCounterFinal)	
	
	return MoveoutCounterFinal

end---------function end











------------Set City Level by Distance (used in city founding or else)

function SetCityLevelbyDistance (player,city)

	
	local WorldSizeLength = Map.GetGridSize()
	local policyID = GameInfo.Policies["POLICY_DICTATORSHIP_PROLETARIAT"].ID
		
	local DistanceLV1 = 7
	print ("DistanceLV1:"..DistanceLV1)
	
	local DistanceLV2 = WorldSizeLength / 8	
	if DistanceLV2 > 18 then
		DistanceLV2 = 18
	elseif DistanceLV2 < 14 then
	   DistanceLV2 = 14
	end
	print ("DistanceLV2:"..DistanceLV2)
	
	
	local DistanceLV3 = WorldSizeLength / 5 	
	if DistanceLV3 > 30 then
	   DistanceLV3 = 30
	elseif DistanceLV3 < 26 then
	   DistanceLV3 = 26
	end
	print ("DistanceLV3:"..DistanceLV3)	 
	       
	local DistanceLV4 = WorldSizeLength / 3 	
	if DistanceLV4 > 44 then
	   DistanceLV4 = 44
	elseif DistanceLV4 < 36 then
	   DistanceLV4 = 36
	end
	print ("DistanceLV4:"..DistanceLV4)


	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_POLYNESIA"] then	
		print ("No Lv 4-5 cities!")
		DistanceLV3 = 999
		DistanceLV4 = 999
	elseif player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ENGLAND"] then
		print ("Lv1 up for all cities!")
		DistanceLV1 = DistanceLV2
		DistanceLV2 = DistanceLV3
		DistanceLV3 = DistanceLV4
		DistanceLV4 = 999
	elseif player:HasPolicy(policyID) then
		print ("Lv1 up for all cities! - Policy Effect!")
		DistanceLV1 = DistanceLV2
		DistanceLV2 = DistanceLV3
		DistanceLV3 = DistanceLV4
		DistanceLV4 = 999
	end
	

	
	
	if player:GetNumCities() > 0 then
		local pCity = player:GetCapitalCity()    
		local CapitalPlot = pCity:Plot() 
		local CapX = CapitalPlot:GetX()
		local CapY = CapitalPlot:GetY()
		
		local policyID = GameInfo.Policies["POLICY_REPRESENTATION"].ID
		local policyBonusID = GameInfo.Policies["POLICY_POLICE_STATE"].ID
		
		
		if city:IsCapital() then
			print ("Capital City!")
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)	
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 	
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 

	
		
		elseif city:IsPuppet() then
		
			if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_VENICE"] then
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],1)	--puppet city has a local government with no Penalties (Venice)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
--					city:SetFocusType(3)
				print("Special Puppet City with no Penalties!")
			else
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],1)	--puppet city has a local government
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			end
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 	
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
		
			if not city:IsResistance() then
				if city:GetOrderQueueLength() <= 0 or city:GetProduction()== 0 then
					city:PushOrder (OrderTypes.ORDER_MAINTAIN, 0, -1, 0, false, false)
					print("Puppet City doing nothing! Let it produce Gold!")
				end
			end
			
			print("Puppet City!")
			
		else
			print("Annexed City, City Hall is built!")			
			local plot = city:Plot() 
			local Distance = Map.PlotDistance (plot:GetX(),plot:GetY(),CapX,CapY)
			
			print ("City's Distance from Capital:"..Distance)
			
			if player:HasPolicy(policyID) then
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"],1)	
			    	print ("Player has the Representation policy!")
			else
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"],0)	  
			end
	
			
			
			if Distance <= DistanceLV1 and Distance > 1 then
		
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],1)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
					
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
					
					if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_PERSIA"] then
				   		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
				   		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATRAPS_COURT"],1)					
						print ("Persia! Achaemenid Legacy!")
					end	
					print("City lv1")
					
					
			
			elseif Distance > DistanceLV1 and Distance <= DistanceLV2  then	
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],1)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],1) 
					print ("Police State!")
				end
				
				print("City lv2")
				
				
				
			elseif Distance > DistanceLV2 and Distance <= DistanceLV3 then	

				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],1)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],1) 
					print ("Police State!")
				end
				
				print("City lv3")
				
				
				
			elseif Distance > DistanceLV3 and Distance <= DistanceLV4 then	
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],1)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],1) 
					print ("Police State!")
				end
				print("City lv4")	
				
				
				
			elseif Distance > DistanceLV4 then	
			
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],1)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],1) 
					print ("Police State!")
				end
				print("City lv5")	
					
			end
			
			
			if plot:GetResourceType() == GameInfoTypes.RESOURCE_NUTMEG or plot:GetResourceType() == GameInfoTypes.RESOURCE_CLOVES or plot:GetResourceType() == GameInfoTypes.RESOURCE_PEPPER then
   				 	if player == Players[city:GetOriginalOwner()]  then

			    	print ("Indonesian first 3 cities free from corruption!")
			    	
			    	city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)	
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 	
					
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0)
				end
			end
				
				
				
		
			
		end

	end


	
	
	
end-------------Function End










----------------------------------Misc----------------------------



function RemoveConflictFeatures (plot)
	if plot == nil then
		return
	end
	
	if plot:GetFeatureType() == FeatureTypes.FEATURE_FOREST or plot:GetFeatureType() == FeatureTypes.FEATURE_MARSH or plot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
	   plot:SetFeatureType(-1)
	   print ("ConflictFeatures Removed!")
	end
end

--
--
-------------Timer Countdown to force AI end turn if freezeed at certain turns
--
--function CountDownForceEndTurn (player)
--
--	if not player:IsHuman() then
--    local x = os.clock()
--    local s = 0
--    for i=1,2000 do s = s + i end
--		print(string.format("AI turn processing elapsed time: %.2f\n", os.clock() - x))
--	end
--	Game.DoControl(GameInfoTypes.CONTROL_FORCEENDTURN)	
--	print ("This AI is taking too long time! So we force it to end its turn!")
--end
--
--


print ("UtilityFunctions Check Pass!")