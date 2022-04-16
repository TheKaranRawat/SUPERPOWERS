-- New Handicap




include( "UtilityFunctions.lua" )




------------------------------------------------------------AI will catch up if fallen behind------------------------------------------------


function PlayerIntoNewEra(era, playerID) -- AI will get bonus when Human Player entering new Eras

local handicap = Game:GetHandicapType()

--print("handicap="..Game:GetHandicapType())
--print("Player Era="..era)

	local player = Players[playerID]
	
	
		if player == nil then
			print ("No players")
			return
		end
		
		if player:IsMinorCiv()or player:IsBarbarian() then
    		return
		end
		
		


	if handicap > 3 then 	-- Only effective when the difficulty from LV  up
		local iCounter = 0
		if player:IsHuman() then 			
		    iCounter = era			   
		    AIEraBonus(iCounter)	
		    print("Player Enter New Era"..iCounter)	
		end		
	end	
	
	
end --function END

Events.SerialEventEraChanged.Add(PlayerIntoNewEra)



function AIForceImprovements() -- AI will get bouns when entering new Eras	

	


end --function END




function AIEraBonus(iCounter) -- AI will get bouns when entering new Eras	
	print("iCounter="..iCounter)
		
	for playerID,player in pairs(Players) do
		if player == nil then
			print ("No players")
			return
		end
--		local player = Players[iPlayerLoop]

		if (player:GetNumCities() > 1 and not player:IsMinorCiv() and not player:IsBarbarian() and not player:IsHuman()) then  
		
			AIForceImprovements(player)	
			
		
			if (iCounter == 2) then				
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_MEDIEVAL"].ID,true)
  				print ("AI Bonus!-MEDIEVAL")
  			elseif (iCounter == 3) then	
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_RENAISSANCE"].ID,true)   
  				print ("AI Bonus!-RENAISSANCE")				 		
  			elseif (iCounter == 4) then	
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_INDUSTRY"].ID,true)
--  			AIMapVisibility (player)
  				print ("AI Bonus!-INDUSTRY")							
  			elseif (iCounter == 5) then	
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_MODERN"].ID,true)   				
  				print ("AI Bonus!-MODERN")				  									
   			elseif (iCounter == 6) then	
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_WORLDWAR"].ID,true)  		
  				print ("AI Bonus!-WORLDWAR")					
			elseif (iCounter == 7) then	
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_ATOMIC"].ID,true)  		
  				print ("AI Bonus!-ATOMIC")										
			elseif (iCounter == 8) then	
  				player:SetHasPolicy(GameInfo.Policies["POLICY_AI_INFORMATION"].ID,true)	   
  				print ("AI Bonus!-INFORMATION")		 									
			end
		end
	end
	
	
end--function END




----------------------------------------- ------------------Give AI Map visibility so their units won't wander around---Cost too much system resource so canceled		------------------------------------------------
--function AIMapVisibility (player)
--   local AITeamID = player:GetTeam()
--   print ("AI Map Visibility!")
--  	  
--   for i = 0, Map.GetNumPlots()-1, 1 do
--		local plot = Map.GetPlotByIndex(i);
--		plot:ChangeVisibilityCount(AITeamID, 10, -1, true, false);
--		plot:SetRevealed(AITeamID, true);
--		plot:UpdateFog();
--		plot:UpdateVisibility();
--		Game.UpdateFOW(true);
--	end
--end
--


------------------------------------------------------------ Force AI to build improvemnts on resources since they always forget------------------------------------------------

function AIForceImprovements (player)	

	if player == nil then		
		return
	end 
	
	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotLoop)
		local plotOwner = Players[plot:GetOwner()]
		if plotOwner ~= nil then
			if plotOwner == player then
			
				if player:GetCurrentEra() >= 3 and plot:GetTerrainType() == TerrainTypes.TERRAIN_COAST and plot:GetResourceType(-1) == -1 and plot:GetFeatureType()== -1 then
				   plot:SetResourceType(GameInfoTypes.RESOURCE_FISH, 1)
				   plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_FISHFARM_MOD.ID)
				end
				
				if player:GetCurrentEra() >= 5 and plot:GetTerrainType() == TerrainTypes.TERRAIN_OCEAN and plot:GetResourceType(-1) == -1 and plot:GetFeatureType()== -1 then
				   plot:SetResourceType(GameInfoTypes.RESOURCE_NATRUALGAS, 1)
				   plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID)
				end
				
				local plotResource = plot:GetResourceType(-1)
				
				if plotResource ~= -1 and not plot:IsCity() then

					
					if plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_FARM.ID) then	
						RemoveConflictFeatures (plot)
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_FARM.ID)
						
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_MINE.ID) then
						if GameInfoTypes[GameInfo.Resources[plotResource].TechReveal] ~= nil then
							if Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[GameInfo.Resources[plotResource].TechReveal]) then
								RemoveConflictFeatures (plot)
								plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_MINE.ID)
							end
						else
							RemoveConflictFeatures (plot)
							plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_MINE.ID)	
						end
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_QUARRY.ID) then
						RemoveConflictFeatures (plot)
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_QUARRY.ID)					
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_PASTURE.ID) then
						RemoveConflictFeatures (plot)
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_PASTURE.ID)
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_FISHING_BOATS.ID) then
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_FISHING_BOATS.ID)
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_FISHFARM_MOD.ID) then
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_FISHFARM_MOD.ID)
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_PLANTATION.ID) then
						RemoveConflictFeatures (plot)
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_PLANTATION.ID)
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_CAMP.ID) then
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_CAMP.ID)	
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_WELL.ID) and player:GetCurrentEra() >= 5  then
						RemoveConflictFeatures (plot)
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_WELL.ID)	
					elseif plot:CanHaveImprovement (GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID) and player:GetCurrentEra() >= 5 then
						plot:SetImprovementType (GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID)
					end
					print ("AI's Plot with resource but they don't build an improvement on it, so force them to build improvement on resource!")
			  	end 	
			end
		end		
	end

end



------------------------------------------------------------ AI get bonus when human expand!------------------------------------------------


function AIBonusWhenPlayerExpand(vHexPos, playerID, cityID)

local NewPlayer = Players[playerID]
	if NewPlayer == nil then
		print ("No players")
		return
	end 
	
	
	
	if NewPlayer:IsHuman()then		
		local HumanCitycount = NewPlayer:GetNumCities()
		local WorldCityTotal = Game.GetNumCities() 
		print ("WorldCityTotal:"..WorldCityTotal)
		
		
		if HumanCitycount > 1 then
			AIBonusByPlayer (HumanCitycount,WorldCityTotal)
		end
		
	end
end
Events.SerialEventCityCreated.Add(AIBonusWhenPlayerExpand)



function AIBonusByPlayer(HumanCitycount,WorldCityTotal) 

	print ("Human's city count:"..HumanCitycount)
	
	for playerID,player in pairs(Players) do		
		if player == nil then
			print ("No players")
			return
		end
		
		
		
		
		
		if not player:IsMinorCiv() and not player:IsBarbarian() and not player:IsHuman() and not player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_VENICE"] then  
		
			if player:GetUnitClassCount(GameInfo.UnitClasses.UNITCLASS_SETTLER.ID) < 1 and player:GetCurrentEra() <= 6 then
  				local pCity = player:GetCapitalCity()
   				local pPlot = pCity
   				if pPlot~= nil then   				
	   				local SettlerID = GameInfo.Units.UNIT_SETTLER.ID
	   				local NewUnit = player:InitUnit(SettlerID, pPlot:GetX(), pPlot:GetY(),UNITAI_SETTLE)
	   				NewUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_EMBARKATION"].ID, true)
   					NewUnit:JumpToNearestValidPlot()
					print ("AI Bonus!-Human is expending! AI get new settler to fill the map!")
   				end
   				
 
			end
			
			
			if AICanBeBoss (player) then
				print ("AI Bonus!-Only for AI who can fight against Human!")
				if HumanCitycount >= 40 or HumanCitycount >= WorldCityTotal/2 then
					print ("Human is unstopable!!!")
					return
				elseif HumanCitycount >= 36 or HumanCitycount >= WorldCityTotal/3 then
				  	player:SetHasPolicy(GameInfo.Policies["POLICY_AI_PLAYER_CITIES_30"].ID,true)
	  				print ("AI Bonus!-Human has 1/3 world! We must do something!")
				elseif HumanCitycount >= 30 or HumanCitycount >= WorldCityTotal/5 and HumanCitycount < WorldCityTotal/3 then
					player:SetHasPolicy(GameInfo.Policies["POLICY_AI_PLAYER_CITIES_20"].ID,true)
	  				print ("AI Bonus!-Human has 1/5 world! We must do something!")
				elseif HumanCitycount >= 22 or HumanCitycount >= WorldCityTotal/8 and HumanCitycount < WorldCityTotal/5 then
					player:SetHasPolicy(GameInfo.Policies["POLICY_AI_PLAYER_CITIES_10"].ID,true)
	  				print ("AI Bonus!-Human has 1/8 world! We must do something!")
	  			elseif HumanCitycount >= 12 or HumanCitycount >= WorldCityTotal/10 and HumanCitycount < WorldCityTotal/8 then
					player:SetHasPolicy(GameInfo.Policies["POLICY_AI_PLAYER_CITIES_6"].ID,true)
	  				print ("AI Bonus!-Human has 1/10 world! We must do something!")						
				end
			end
		end
	end
end




------------------------------------------------------------ AI will annex the city to recover quikly------------------------------------------------
function AIAutoAnnexCity(hexX, hexY, population, citySize)
	if hexX == nil or hexY ==nil then
		print ("No Plot")
	return
	end	

	local plot = Map.GetPlot(ToGridFromHex(hexX, hexY))
	local city = plot:GetPlotCity();
	
	if city ==nil then
		print ("No cities")
	return
	end
	
	local player = Players[city:GetOwner()]

	
	if player == nil then
		print ("No players")
		return
	end
		
		
	if player:IsHuman() or player:IsMinorCiv()or player:IsBarbarian() then
    	return
	end
	
	
	
  	if player:GetNumCities() < 1 then
		return
	end	
    
	
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_VENICE"] then
    	return
	end
	
	
	if city:IsResistance() and city:GetResistanceTurns() > 3 then
		city:ChangeResistanceTurns(-2)
	end
	
	if city:IsPuppet() then
		if city:GetPopulation() > 6 and not city:IsResistance() then
			city:SetPuppet(false)
			city:SetOccupied(true)
--			city:DoAnnex()
			print("AI Annexes City!")
		end
	end
end

Events.SerialEventCityPopulationChanged.Add(AIAutoAnnexCity)


---------------------------------------------------------------------AI Units Assistance help AI to get required Promotions and restore carrier's aircrafts (TEMP)----------------------------------------------------

function AIUnitsAssist(playerID)
    local player = Players[playerID]
    
    	if player == nil then
			print ("No players")
			return
		end
    
    	if player:IsHuman() then ----------Only for Major AI
    		return 
    	end
    	
    	if player:IsMinorCiv() then
   		 	return 
    	end
    	
    	if player:IsBarbarian() then
    		return 
    	end
    



    
	--    local handicap = Game:GetHandicapType()   	


	
	local CarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_UNIT"].ID
	
	local MissileCarrierID = GameInfo.UnitPromotions["PROMOTION_MISSILE_CARRIER"].ID
	local DroneCarrierID = GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID
	
	local CarrierAircraftID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER"].ID	
	
	local CarrierAirFight1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_AIRFIGHT_1"].ID
	local CarrierAirFight2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_AIRFIGHT_2"].ID
	local CarrierAirAttack1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_ATTACK_1"].ID
	local CarrierAirAttack2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_ATTACK_2"].ID
	local CarrierAirSiege1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_SIEGE_1"].ID	
	local CarrierAirSiege2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_SIEGE_2"].ID	
	
	local AICityCount = player:GetNumCities()
		
	if AICityCount >= 1 then
	
		-----------Give AI additional Resources
		local ConsumerResID = GameInfoTypes["RESOURCE_CONSUMER"]
		local ElectricityResID = GameInfoTypes["RESOURCE_ELECTRICITY"]
		local ManPowerResID = GameInfoTypes["RESOURCE_MANPOWER"]
		
		 
		if player:GetNumResourceAvailable(ElectricityResID,true) <= 0 and player:GetCurrentEra() >= 5 and AICanBeBoss (player) then
			player:ChangeNumResourceTotal(ElectricityResID,1)
			print ("AI get Electricity Supply!")
		end	
		
		if player:GetNumResourceAvailable(ConsumerResID,true) <= 0 then
			player:ChangeNumResourceTotal(ConsumerResID,2)
			print ("AI get Consumer Goods Supply!")
		end	
				
		if player:GetNumResourceAvailable(ManPowerResID,true) <= 0 and AICanBeBoss (player) then
			player:ChangeNumResourceTotal(ManPowerResID,1)
			print ("AI get Manpower Supply!")
		end		
		
				--		
				--		
				--		-----------Force AI to make peace with distant AI other than wasting time
				--		for OtherplayerID,OtherAIPlayer in pairs(Players) do
				--			if not OtherAIPlayer:IsHuman() and not OtherAIPlayer:IsMinorCiv() and not OtherAIPlayer:IsBarbarian() then
				--				if PlayersAtWar (player,OtherAIPlayer) then
				--				
				--					if OtherAIPlayer:IsWillAcceptPeaceWithPlayer (playerID) and not player:IsPeaceBlocked (OtherAIPlayer:GetTeam()) then
				--						Teams[player:GetTeam()]:MakePeace(OtherAIPlayer:GetTeam())
				--						print ("We two AIs have no need to fight! It might be the human's provocation! We should make peace!")
				--					end
				--				
				--				
				--					if and not player:IsPeaceBlocked (OtherAIPlayer:GetTeam()) then
				--						Teams[player:GetTeam()]:MakePeace(OtherAIPlayer:GetTeam())
				--						print ("We two AIs have no need to fight! It might be the human's provocation! We should make peace!")
				--					end
				--					
				--					
				--				end
				--			end	
				--		end
		
		
	
		for unit in player:Units() do
			if unit ~= nil then
			
				local plot = unit:GetPlot()
				
		--------------------------Fix AI turn freeze when moving certain Units (temp method)--this bug has been confirmed since G&K, when AI who is at war moving too many units on map -----maybe I'll find a better method in the future 
	--				if not PlotIsVisibleToHuman(plot) then
	--				 	if unit:IsRanged() and unit:GetDomainType()~= DomainTypes.DOMAIN_AIR then
	--				 		local OriPlotX = plot:GetX()	
	--				 		local OriPlotY = plot:GetY()			 	 
	--						unit:JumpToNearestValidPlot()
	--						unit:SetXY (OriPlotX,OriPlotY)
	----						print ("---------------------BUG Check------------------------------------Unit moved")
	--					end
	--				end
				
				
		------------------------AI Remove Obsolete Units (If force AI to upgrade their units it may cause freezing! so just delete them)

		------------------------AI Force Upgrade Units	----------May cause CTD!!!!!!!!!!!!!!Disabled for safety
	--								
	--				if unit:CanUpgradeRightNow() then
	--					unit:DoCommand(CommandTypes["COMMAND_UPGRADE"])
	--					print ("AI Unit upgraded!")
	--				end	
	--					

				if not PlayerAtWarWithHuman(player) and not PlotIsVisibleToHuman(plot) then
					if unit:CanUpgradeRightNow() then
					
						local ThisUnitType = unit:GetUnitType()
						local ThisUnitClass = unit:GetUnitClassType()
						local sUnitType = GetCivSpecificUnit(player, ThisUnitClass)
   																
						if sUnitType ~= ThisUnitType then
							unit:Kill()	
							print("AI can build new unit of this type, so this old unit is removed!")
						else
							print ("Unique Unit, keep it!")	
						end				
					end
				end
	
				
			    if player:GetCurrentEra() >= 6 then
					if unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_CARAVEL.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SCOUT.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_EXPLORERX.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_MISSIONARY.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_INQUISITOR.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_PROPHET.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SCOUT.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SLOOP_OF_WAR.ID then
					   unit:Kill()	
					   print ("Obselete units outside removed!")
					end			
				end

			
			
						-------	Fix Possible 0 HP Unit Bug (Temp Method)
					--				if unit:GetDamage() >=100 or unit:GetCurrHitPoints() <=0 then
					--					print ("-----------------------BUG Fix-------0HP Unit---------------")
					--					unit:Kill()	
					--				end
					--			
			

				
	
	
					-------------------Remove AI miss-placed units
				if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID) then
					if plot~= nil then
						if plot:GetImprovementType() == nil or plot:GetImprovementType() ~= GameInfo.Improvements["IMPROVEMENT_CITADEL"].ID then
							unit:Kill()	
							print ("AI miss-placed Citidal units Removed!")
						end	
					end
				end
	
					------------------------AI Units Restoring
	
				if unit:GetUnitType() == GameInfoTypes.UNIT_SSBN and not unit:IsFull() then	
				
				    if plot ~= nil and not plot:IsCity() then
				   	    player:InitUnit(GameInfoTypes.UNIT_EMP_BOMBER_AIR, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
						print ("AI:Missile restored!")					    	
				    end
				end		
				
				if unit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL and not unit:IsFull() then	
			
				    if plot ~= nil and not plot:IsCity() then
				   	    player:InitUnit(GameInfoTypes.UNIT_FRANCE_EUROCOPTER_TIGER, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
				   	    player:InitUnit(GameInfoTypes.UNIT_FRANCE_EUROCOPTER_TIGER, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
						player:InitUnit(GameInfoTypes.UNIT_FRANCE_EUROCOPTER_TIGER, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
				   	    player:InitUnit(GameInfoTypes.UNIT_FRANCE_EUROCOPTER_TIGER, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
						print ("AI:Eurocopter restored on AAS!")					    	
				    end
				end	
				
					
				if unit:IsHasPromotion(MissileCarrierID) and not unit:IsFull() then
				
				
								-------------------	Can cause infinite loop for no reason!!!!!!!!For safty Use stupid temp method
					--				 	while not unit:IsFull() do				 	
					--						player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR):SetMoves(0)			
					--						print ("Missile restored!")
					--					end	
				
					if plot ~= nil and not plot:IsCity() then
					
						if unit:GetUnitType() == GameInfoTypes.UNIT_KIROV_BATTLECRUISER then
							player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
							player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
							player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
							player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
							player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
						--	 player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
						--	 player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
						--	 player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
						--	 player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)		
								
						elseif unit:GetUnitType() == GameInfoTypes.UNIT_MISSILE_CRUISER or unit:GetUnitType() == GameInfoTypes.UNIT_KOREAN_SEJONG_CLASS then
							player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
							--	 player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
								
								
							-- elseif unit:GetUnitType() == GameInfoTypes.UNIT_MODERN_DESTROYER then
							--	 player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)			
							-- end

						end
					

					end			 	
						
					--				if unit:IsHasPromotion(DroneCarrierID) and not unit:IsFull() then
					--		
					--				    if plot ~= nil and not plot:IsCity() then
					--				        player:InitUnit(GameInfoTypes.UNIT_UAV, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)				
					--					    print ("AI:UAV restored!")
					--				    end					
					--				end									
					
				end	
				
				if unit:IsHasPromotion(CarrierID) and not unit:IsFull() then
						
					if unit:GetUnitType() == GameInfoTypes.UNIT_CARRIER then
			
						if plot ~= nil and not plot:IsCity() then
						player:InitUnit(GameInfoTypes.UNIT_JAPANESE_ZERO, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)					      
						end
					end   
					
					if unit:GetUnitType() == GameInfoTypes.UNIT_AMERICAN_NIMITZ then
						print ("Found AI Nimitz!")
						local pTeam = Teams[player:GetTeam()]
						if pTeam:IsHasTech(GameInfoTypes["TECH_NUCLEAR_FUSION"]) then
			
							if plot ~= nil and not plot:IsCity() then
								player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)	
							end
							
						else
			
							if plot ~= nil and not plot:IsCity() then
								player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_JET, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)							    
							end
						end	
					end 	
					
					
					if unit:GetUnitType() == GameInfoTypes.UNIT_NUCLEAR_CARRIER then
				
						if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ENGLAND"] then
							print ("Found AI English Nuclear Carrier!")
	
							if plot ~= nil and not plot:IsCity() then
								player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)								 
							end		
						else
							print ("Found AI Normal Nuclear Carrier!")
	
							if plot ~= nil and not plot:IsCity() then
								player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_JET, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)
							end
						end	
					end
					
						
					if unit:GetUnitType() == GameInfoTypes.UNIT_SUPER_CARRIER then	
						if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ENGLAND"] then

							if plot ~= nil and not plot:IsCity() then
								print ("Found AI English Super Carrier!")
								player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)								 
							end			
						else

							if plot ~= nil and not plot:IsCity() then
								print ("Found AI Normal Super Carrier!")
								player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)
							end			
						end				   
					end
					print ("AI:Aircrafts carrier loaded!")
				end
				
			end	
	end
	
	
end
end
	
GameEvents.PlayerDoTurn.Add(AIUnitsAssist)



------------------------------------------------------------ Remove AI Resources Bonus when it is losing------------------------------------------------

function AIRemoveResources(oldPlayerID, iCapital, iX, iY, newPlayerID, bConquest, iGreatWorksPresent, iGreatWorksXferred)
	local NewPlayer = Players[newPlayerID]
	local OldPlayer = Players[oldPlayerID]	
		
	local pPlot = Map.GetPlot(iX, iY)
	local pCity = pPlot:GetPlotCity()
	
	local CityOriginalOwnerID = pCity:GetOriginalOwner() 
 	local CityOriginalOwner = Players[CityOriginalOwnerID] 
	
	if OldPlayer == nil or NewPlayer == nil then
		print ("No players")
		return
	end

	if OldPlayer:GetNumCities()<=1 then
		print ("AI no city left!")-------In case of "complete kill" selected will crash the game 
		return
	end

	if AICanBeBoss (OldPlayer) then
		print ("Not effective with Boss!")
		return
	end


	if not NewPlayer:IsHuman() and not OldPlayer:IsHuman() then
	
	    if OldPlayer == CityOriginalOwner then
			
--			if NewPlayer:GetNumUnits() <= 100 then
--			   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_AI_CHEAT_UNITS_CAPTURING_CITY"],1)
--			   print ("AI Cheating New Units Created!")
--			end
			
			local ConsumerResID = GameInfoTypes["RESOURCE_CONSUMER"]
			local ElectricityResID = GameInfoTypes["RESOURCE_ELECTRICITY"]
			local ManPowerResID = GameInfoTypes["RESOURCE_MANPOWER"]
			
			if OldPlayer:GetNumResourceAvailable(ConsumerResID,true) >= 0 then
				OldPlayer:ChangeNumResourceTotal(ConsumerResID,-15)
			end	
			
			if OldPlayer:GetNumResourceAvailable(ElectricityResID,true) >= 0 then
				OldPlayer:ChangeNumResourceTotal(ElectricityResID,-15)
			end	
			
			if OldPlayer:GetNumResourceAvailable(ManPowerResID,true) >= 0 then
				OldPlayer:ChangeNumResourceTotal(ManPowerResID,-15)
			end	
		
		
			if AICanBeBoss(NewPlayer) then
			
				if pCity:IsCoastal()then
					AIForceBuildNavalEscortUnits (iX, iY, NewPlayer)
					AIForceBuildNavalHRUnits (iX, iY, NewPlayer)
					AIForceBuildInfantryUnits (iX, iY, NewPlayer)
					AIForceBuildNavalEscortUnits (iX, iY, NewPlayer)
					AIForceBuildNavalHRUnits (iX, iY, NewPlayer)
					print ("Coastal city is captured!Offer AI boss more navy to advance!")					
				else
					AIForceBuildInfantryUnits (iX, iY, NewPlayer)
					AIForceBuildMobileUnits (iX, iY, NewPlayer)
					AIForceBuildLandHRUnits	(iX-1, iY-1, NewPlayer)	
					AIForceBuildInfantryUnits (iX+1, iY+1, NewPlayer)
					AIForceBuildMobileUnits (iX+1, iY+1, NewPlayer)
					AIForceBuildLandHRUnits	(iX-1, iY-1, NewPlayer)
					print ("Inland city is captured!Offer AI boss more army to advance!")		
				end			
			end
		
		
			if pCity:GetPopulation() >= 3 then
				for unit in OldPlayer:Units() do
					if unit ~= nil then
					local plot = unit:GetPlot()
					   if plot ~= nil then
						   if not PlotIsVisibleToHuman(plot) then
						   	  unit:Kill()
						   	  print ("Kill Weak AI's units to let AI's war go faster!")
						   end	   	  	
						end	
					end
				end	
			end	
			print ("Defeated AI Remove Resources Bonus so it can die faster and save system's resource!")	
		end
		
		
		
		
	end
end
GameEvents.CityCaptureComplete.Add(AIRemoveResources)







---------------------------------------------------------------------AI Force Promotion and Unitclass Balance----------------------------------------------------

function AIPromotion(iPlayer, iCity, iUnit, bGold, bFaith)
    local player = Players[iPlayer]
    
    
    	if player == nil then
			print ("No players")
			return
		end
    
      	if iUnit == nil then 
    		return 
    	end
    
    	if player:IsHuman() then ----------Only for Major AI
    		return 
    	end
    	
    	if player:IsMinorCiv() then
   		 	return 
    	end
    	
    	if player:IsBarbarian() then
    		return 
    	end
    	

    local handicap = Game:GetHandicapType()
    
    local city = player:GetCityByID(iCity) 
    local plot = city	

	local RangedUnitID = GameInfo.UnitPromotions["PROMOTION_ARCHERY_COMBAT"].ID
	local CitySiegeID = GameInfo.UnitPromotions["PROMOTION_CITY_SIEGE"].ID
	local LandAOEUnitID = GameInfo.UnitPromotions["PROMOTION_SPLASH_DAMAGE"].ID
	
	local HitandRunID = GameInfo.UnitPromotions["PROMOTION_HITANDRUN"].ID
	local HelicopterID = GameInfo.UnitPromotions["PROMOTION_HELI_ATTACK"].ID
	
	local NavalHitandRunID = GameInfo.UnitPromotions["PROMOTION_NAVAL_HIT_AND_RUN"].ID
	local NavalRangedID = GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_SHIP"].ID
	local SubmarineID = GameInfo.UnitPromotions["PROMOTION_SUBMARINE_COMBAT"].ID
	
	local CapitalShipID = GameInfo.UnitPromotions["PROMOTION_NAVAL_CAPITAL_SHIP"].ID
	local CarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_UNIT"].ID
	
	local SSBNID = GameInfo.UnitPromotions["PROMOTION_CARGO_IX"].ID
	
	local BomberID = GameInfo.UnitPromotions["PROMOTION_STRATEGIC_BOMBER"].ID
	local AirAttackID = GameInfo.UnitPromotions["PROMOTION_AIR_ATTACK"].ID

	
	local CollDamageLV1ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_1"].ID
	local CollDamageLV2ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_2"].ID
	local CollDamageLV3ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_3"].ID
		
	local Barrage1ID = GameInfo.UnitPromotions["PROMOTION_BARRAGE_1"].ID
	local Barrage2ID = GameInfo.UnitPromotions["PROMOTION_BARRAGE_2"].ID
	local Barrage3ID = GameInfo.UnitPromotions["PROMOTION_BARRAGE_3"].ID
	
	local FireSupport1ID = GameInfo.UnitPromotions["PROMOTION_FIRESUPPORT_UNIT_1"].ID
	local FireSupport2ID = GameInfo.UnitPromotions["PROMOTION_FIRESUPPORT_UNIT_2"].ID
		
	local Sunder1ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_1"].ID
	local Sunder2ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_2"].ID
	local Sunder3ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_3"].ID
	
	local AOEAttack1ID = GameInfo.UnitPromotions["PROMOTION_CLUSTER_ROCKET_1"].ID
	local AOEAttack2ID = GameInfo.UnitPromotions["PROMOTION_CLUSTER_ROCKET_2"].ID
	local CapitalShipArmor1ID = GameInfo.UnitPromotions["PROMOTION_ARMOR_BATTLESHIP_1"].ID
	local CapitalShipArmor2ID = GameInfo.UnitPromotions["PROMOTION_ARMOR_BATTLESHIP_2"].ID
	
	local NapalmBomb1ID = GameInfo.UnitPromotions["PROMOTION_NAPALMBOMB_1"].ID
	local NapalmBomb2ID = GameInfo.UnitPromotions["PROMOTION_NAPALMBOMB_2"].ID
	local NapalmBomb3ID = GameInfo.UnitPromotions["PROMOTION_NAPALMBOMB_3"].ID
	local DestroySupply1ID = GameInfo.UnitPromotions["PROMOTION_DESTROY_SUPPLY_1"].ID
	local DestroySupply2ID = GameInfo.UnitPromotions["PROMOTION_DESTROY_SUPPLY_2"].ID
	
	local AirBomb1ID = GameInfo.UnitPromotions["PROMOTION_AIR_BOMBARDMENT_1"].ID
	local AirBomb2ID = GameInfo.UnitPromotions["PROMOTION_AIR_BOMBARDMENT_2"].ID
	local AirBomb3ID = GameInfo.UnitPromotions["PROMOTION_AIR_BOMBARDMENT_3"].ID
	local AirTarget1ID = GameInfo.UnitPromotions["PROMOTION_AIR_TARGETING_1"].ID
	local AirTarget2ID = GameInfo.UnitPromotions["PROMOTION_AIR_TARGETING_2"].ID
	local AirTarget3ID = GameInfo.UnitPromotions["PROMOTION_AIR_TARGETING_3"].ID
		
	local AIHitandRunID = GameInfo.UnitPromotions["PROMOTION_RANGE_REDUCE"].ID
	local AIRangeID = GameInfo.UnitPromotions["PROMOTION_RANGE"].ID
	
	local SetUpID = GameInfo.UnitPromotions["PROMOTION_MUST_SET_UP"].ID
	
	local MilitiaUnitID = GameInfo.UnitPromotions["PROMOTION_MILITIA_COMBAT"].ID
	
	
	local SatelliteID = GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID
		
	local AICityCount = player:GetNumCities()	
	
	
	if AICityCount < 1 then
		return
	end	
	

	local unit = player:GetUnitByID(iUnit)
	
	if unit == nil then
		return
	end	
	
	
	local unitX = unit:GetX()
	local unitY = unit:GetY()
	
	if unitX == nil or unitY == nil then
		return
	end	
	
	local ThisUnitClass = unit:GetUnitClassType()
	
	
	if unit:GetUnitType() == GameInfoTypes.UNIT_WORKER then
	   if player:GetUnitClassCount(ThisUnitClass) > AICityCount or player:GetUnitClassCount(ThisUnitClass) > 20 then
	    	unit:Kill()	
	    	print ("Major Civ removed too many workers to let the turn goes faster!")
	   end	
	end


	if unit:IsHasPromotion(MilitiaUnitID) and not PlayerAtWarWithHuman(player) then	   
	   if player:GetUnitClassCount(ThisUnitClass) > AICityCount then
	   	  unit:Kill()
	   	  print ("Reduce AI Militia units' number when not at war with Human to let the turn goes faster!")	
	   end	  
	end	
	
	
	if unit:IsHasPromotion(SatelliteID) and player:GetCurrentEra() >= 6 then
		local city = player:GetCapitalCity()
		SatelliteLaunchEffects (unit,city,player)
		SatelliteEffectsGlobal(unit)
		print ("AI has built a Satellite Unit!")		
	end



	if handicap >= 4 and player:GetCurrentEra() > 1 and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"],true) > 0 and not PlotIsVisibleToHuman(plot) then 

		if unit:IsHasPromotion(BomberID) then
	       unit:SetHasPromotion(NapalmBomb1ID, true)
		   unit:SetHasPromotion(NapalmBomb2ID, true)	
		   unit:SetHasPromotion(NapalmBomb3ID, true)
		   unit:SetHasPromotion(DestroySupply1ID, true)
		   unit:SetHasPromotion(DestroySupply2ID, true)
		   
		   
		   ------------------------Force AI build escort units!	
		   if AIHasTooManySameUnits(player,ThisUnitClass) then	   	   
		  	   AIForceBuildAirEscortUnits (unitX, unitY, player)
		  	  if city:IsCoastal() then
				   AIForceBuildNavalEscortUnits (unitX, unitY, player)
				   AIForceBuildNavalHRUnits (unitX, unitY, player)
			  else
			  	 AIForceBuildInfantryUnits (unitX, unitY, player)   
				 AIForceBuildMobileUnits (unitX, unitY, player) 
				 AIForceBuildLandHRUnits (unitX, unitY, player) 
		  	  end
		   end
		   
		   
		   
		   
		elseif unit:IsHasPromotion(AirAttackID) then
			unit:SetHasPromotion(AirBomb1ID, true)
			unit:SetHasPromotion(AirBomb2ID, true)	
			unit:SetHasPromotion(AirBomb3ID, true)	
			unit:SetHasPromotion(AirTarget1ID, true)
			unit:SetHasPromotion(AirTarget2ID, true)
			unit:SetHasPromotion(AirTarget3ID, true)	
			
		   

		   ------------------------Force AI build escort units!		
		   if AIHasTooManySameUnits(player,ThisUnitClass) then	   	   	   	   
		  	  AIForceBuildAirEscortUnits (unitX, unitY, player)
		  	  if city:IsCoastal() then
				   AIForceBuildNavalEscortUnits (unitX, unitY, player)
				   AIForceBuildNavalHRUnits (unitX, unitY, player)
			  else
			  	 AIForceBuildInfantryUnits (unitX, unitY, player)   
				 AIForceBuildMobileUnits (unitX, unitY, player) 
				 AIForceBuildLandHRUnits (unitX, unitY, player) 
		  	  end
		   end		   
				   
				   
		   
		elseif unit:IsHasPromotion(CapitalShipID) then
		
			
		   unit:SetHasPromotion(AOEAttack1ID, true)
		   unit:SetHasPromotion(AOEAttack2ID, true)
		   unit:SetHasPromotion(CapitalShipArmor1ID, true)
		   unit:SetHasPromotion(CapitalShipArmor2ID, true)
		   
		   
		   ------------------------Force AI build escort units!	
		   if AIHasTooManySameUnits(player,ThisUnitClass) then	   	   		   	  
			   AIForceBuildNavalEscortUnits (unitX, unitY, player)
			   AIForceBuildNavalHRUnits (unitX, unitY, player)
			   AIForceBuildInfantryUnits (unitX, unitY, player)   
			   AIForceBuildMobileUnits (unitX, unitY, player) 
		   end
		   
		   
		elseif unit:IsHasPromotion(CarrierID) then		   
		   
		   ------------------------Force AI build escort units!	
		   if AIHasTooManySameUnits(player,ThisUnitClass) then	   	   		   	  
			   AIForceBuildNavalEscortUnits (unitX, unitY, player)
			   AIForceBuildNavalHRUnits (unitX, unitY, player)
			   AIForceBuildAirEscortUnits (unitX, unitY, player)
			   AIForceBuildInfantryUnits (unitX, unitY, player)   
			   AIForceBuildMobileUnits (unitX, unitY, player) 
		   end
		   
		   
		 elseif unit:IsHasPromotion(SSBNID) then
		 
		 ------------------------Force AI build escort units!	
		   if AIHasTooManySameUnits(player,ThisUnitClass) then	   	   		   	  
			   AIForceBuildNavalEscortUnits (unitX, unitY, player)
			   AIForceBuildNavalHRUnits (unitX, unitY, player)
			   AIForceBuildAirEscortUnits (unitX, unitY, player)
		   end
		   
		 elseif unit:IsHasPromotion(NavalRangedID) then
		 	unit:SetHasPromotion(Sunder1ID, true)
			unit:SetHasPromotion(Sunder2ID, true)
		 	unit:SetHasPromotion(CollDamageLV1ID, true)
			unit:SetHasPromotion(CollDamageLV2ID, true)
			
			------------------------Force AI build escort units!	
		  if AIHasTooManySameUnits(player,ThisUnitClass) then	   	 
			AIForceBuildNavalEscortUnits (unitX, unitY, player)
			AIForceBuildNavalHRUnits (unitX, unitY, player)
	      end
						
			if player:GetCurrentEra() > 4 then
				unit:SetHasPromotion(CollDamageLV3ID, true)
				unit:SetHasPromotion(Sunder3ID, true)
				unit:SetHasPromotion(AIRangeID, true)	
		   	end  
	   	  
	   	
		   		
		   
		elseif unit:IsHasPromotion(LandAOEUnitID) then
		   unit:SetHasPromotion(AOEAttack1ID, true)
		   unit:SetHasPromotion(AOEAttack2ID, true)
		   unit:SetHasPromotion(SetUpID, false)	
			   
			------------------------Force AI build escort units!
			if AIHasTooManySameUnits(player,ThisUnitClass) then	   	 	
				AIForceBuildInfantryUnits (unitX, unitY, player)   
				AIForceBuildMobileUnits (unitX, unitY, player)     
				AIForceBuildLandHRUnits (unitX, unitY, player) 
			end  

		elseif unit:IsHasPromotion(HitandRunID) and player:GetCurrentEra() > 1 then
			unit:SetHasPromotion(Sunder1ID, true)
			unit:SetHasPromotion(Sunder2ID, true)
			unit:SetHasPromotion(AIHitandRunID, true)
			if player:GetCurrentEra() > 5 then
				unit:SetHasPromotion(AIHitandRunID, false)
				unit:SetHasPromotion(AIRangeID, true)	
			end
			
		elseif unit:IsHasPromotion(HelicopterID) then
			unit:SetHasPromotion(Sunder1ID, true)
			unit:SetHasPromotion(Sunder2ID, true)
			unit:SetHasPromotion(Sunder3ID, true)			
			unit:SetHasPromotion(AIRangeID, true)	
					
			------------------------Force AI build escort units!
			if AIHasTooManySameUnits(player,ThisUnitClass) then	   	 
				AIForceBuildInfantryUnits (unitX, unitY, player)  
				AIForceBuildMobileUnits (unitX, unitY, player)     		
			end
			
			
		elseif unit:IsHasPromotion(CitySiegeID) then
			unit:SetHasPromotion(CollDamageLV1ID, true)
			unit:SetHasPromotion(SetUpID, false)
			if player:GetCurrentEra() > 3 then
				unit:SetHasPromotion(CollDamageLV2ID, true)
				unit:SetHasPromotion(CollDamageLV3ID, true)
		   	end
		   	
		  	------------------------Force AI build escort units!
		  	if AIHasTooManySameUnits(player,ThisUnitClass) then	   	 
				AIForceBuildInfantryUnits (unitX, unitY, player) 
			   	AIForceBuildLandHRUnits (unitX, unitY, player) 
		   	end
		   	
		   	
		elseif unit:IsHasPromotion(RangedUnitID) or unit:IsHasPromotion(NavalHitandRunID) or unit:IsHasPromotion(SubmarineID) then
			unit:SetHasPromotion(Barrage1ID, true)
			unit:SetHasPromotion(Barrage2ID, true)
			
			
			
			
			if player:GetCurrentEra() > 4 then
				unit:SetHasPromotion(Barrage3ID, true)		
				unit:SetHasPromotion(FireSupport1ID, true)
				unit:SetHasPromotion(FireSupport2ID, true)					
			end
			
			if AIHasTooManySameUnits(player,ThisUnitClass) then
				if unit:IsHasPromotion(RangedUnitID) then
					AIForceBuildInfantryUnits (unitX, unitY, player) 			
				elseif unit:IsHasPromotion(SubmarineID) or unit:IsHasPromotion(NavalHitandRunID) then
					AIForceBuildNavalEscortUnits (unitX, unitY, player)
				end
			end
			
			
		end
	end	
end
	
GameEvents.CityTrained.Add(AIPromotion)







----------------------Make AI build unit of different types so they can work together----------------------------------------------------

----------Oringinal Codes from William Howard's Policy - Free Warrior' mod

function AIForceBuildAirEscortUnits (unitX, unitY, player)

	if unitX == nil or unitY == nil or player == nil then
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_TRIPLANE")
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end

    local PlayerEra = player:GetCurrentEra()
    local NewUnitEXP = PlayerEra*20

    local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_DEFENSE_AIR)
    
    AINewUnitSetUp (NewUnit, NewUnitEXP)
    
    print ("Stupid AI need more Fighters!")
end



function AIForceBuildNavalEscortUnits (unitX, unitY, player)

	if unitX == nil or unitY == nil or player == nil then
		return
	end


	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_GALLEASS")
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
        
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end


    local PlayerEra = player:GetCurrentEra()
    local NewUnitEXP = PlayerEra*5

    local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ATTACK_SEA)
    
    AINewUnitSetUp (NewUnit, NewUnitEXP)
    
    print ("Stupid AI need more Naval Melee Ships!")
end



function AIForceBuildNavalHRUnits (unitX, unitY, player) 

	if unitX == nil or unitY == nil or player == nil then
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_FIRE_SHIP")
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
        
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end
    
    local PlayerEra = player:GetCurrentEra()
    local NewUnitEXP = PlayerEra*15

    local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ASSAULT_SEA)
   
    AINewUnitSetUp (NewUnit, NewUnitEXP)
     
    print ("Stupid AI need more Naval Hit and Run Ships!")
end



function AIForceBuildInfantryUnits (unitX, unitY, player) 

	if unitX == nil or unitY == nil or player == nil then
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_SWORDSMAN")
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
        
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end
    
    local PlayerEra = player:GetCurrentEra()
    local NewUnitEXP = PlayerEra*5
	

    local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ATTACK)
    
  
  	AINewUnitSetUp (NewUnit, NewUnitEXP)
  
     
    print ("Stupid AI need more Infantry!")
end


function AIForceBuildMobileUnits (unitX, unitY, player) 
	
	if unitX == nil or unitY == nil or player == nil then
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_HORSEMAN")
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
        
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end
    
    local PlayerEra = player:GetCurrentEra()
    local NewUnitEXP = PlayerEra*10

    local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_FAST_ATTACK)
   
    AINewUnitSetUp (NewUnit, NewUnitEXP)
     
    print ("Stupid AI need more Mobile Units!")
end



function AIForceBuildLandHRUnits  (unitX, unitY, player) 
	
	if unitX == nil or unitY == nil or player == nil then
		return
	end
	

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_MEDIEVAL_CHARIOT")
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
        
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end
    
    local PlayerEra = player:GetCurrentEra()
    local NewUnitEXP = PlayerEra*25

    local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_FAST_ATTACK)
   
    AINewUnitSetUp (NewUnit, NewUnitEXP)
     
    print ("Stupid AI need more Land Hit and Run Units!")
end




function AINewUnitSetUp (NewUnit, NewUnitEXP)
	NewUnit:SetExperience (NewUnitEXP)

	if NewUnit == nil then
		return
	end
	
	if NewUnit:GetDomainType() == DomainTypes.DOMAIN_LAND or NewUnit:GetDomainType() == DomainTypes.DOMAIN_SEA then
 		NewUnit:JumpToNearestValidPlot()
	end
	
--	local NewUnitName = NewUnit:GetName()
--	print ("AI New Unit Setup Finsihed:"..NewUnitName)

end



---------------------------------------------------------------------Check if this unit is out of date----------------------------------------------------



function UnitIsOutofDate(player,unit)
	local sUnitType = unit:GetUnitType()
	local sNewUnitClass = GameInfo.Units[sUnitType].GoodyHutUpgradeUnitClass
	 	
	if sNewUnitClass ~= nil and player:GetUnitClassCount(sNewUnitClass)>= 1 then
		print ("AI already has some advanced units!")
		return true
	else
		return false
	end

end


---------------------------------------------------------------------Check if AI has too many units of same type----------------------------------------------------


function AIHasTooManySameUnits(player,ThisUnitClass)
	local UnitRatio = player:GetNumMilitaryUnits ()* 0.2
	print ("Ai UnitRatio:"..UnitRatio)
	if AICanBeBoss (player) or PlayerAtWarWithHuman(player) or player:GetUnitClassCount(ThisUnitClass) >= UnitRatio then
		return true	
	else
		return false		
	end
	
end



---------------------------------------------------------------------Limit Minor Civs build too many untis to make the system slow----------------------------------------------------

function MinorNoCombatUnits(iPlayer, iCity, iUnit, bGold, bFaith)
	local player = Players[iPlayer]
	if player == nil then
		print ("No players")
		return
	end
	
	if iUnit == nil then 
		return
	end	
		
	if player:IsMinorCiv()then
	

		local unit = player:GetUnitByID(iUnit)	
		
		if player:GetNumCities()< 1 then
			return
		end
		
		if unit:GetUnitType() == GameInfoTypes.UNIT_WORKER and player:GetUnitClassCount(GameInfo.UnitClasses.UNITCLASS_WORKER.ID) > 1 then
			unit:Kill()	
			print ("Minor Civ removed too many workers!")
		end
		if unit:IsCombatUnit() and player:GetNumMilitaryUnits()> 3 then			
			unit:Kill()	
			print ("Minor Civ removed too many military units!")
		end	
	end
end


GameEvents.CityTrained.Add(MinorNoCombatUnits)
print("New Handicap Check Pass!")


