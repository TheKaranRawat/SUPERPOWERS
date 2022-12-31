-- NewUnitsRules

--------------------------------------------------------------

include( "UtilityFunctions.lua" )







function NewUnitCreationRules (playerID)   




local player = Players[playerID]

	if player == nil then
		return
	end

	if player:IsBarbarian() then 
	   return
    end  

    if player:IsMinorCiv() then 
	   return
    end 
        
    if player:GetNumCities() < 1 then ---- In case of 0 city error
		return
	end
	
	

if player:IsHuman() then
	
	
	local AirCraftCarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_UNIT"].ID
	
	local CarrierSupply3ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_3"].ID
	local MissileCarrierID = GameInfo.UnitPromotions["PROMOTION_MISSILE_CARRIER"].ID
	local DroneCarrierID = GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID
	
	
	local Penetration1ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_1"].ID
	local Penetration2ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_2"].ID
	local SlowDown1ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID
	local SlowDown2ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_2"].ID
	local MoralWeaken1ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_1"].ID
	local MoralWeaken2ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_2"].ID
	local LoseSupplyID = GameInfo.UnitPromotions["PROMOTION_LOSE_SUPPLY"].ID
		
	local RapidMarchID = GameInfo.UnitPromotions["PROMOTION_RAPID_MARCH"].ID
	local MarkedTargetID = GameInfo.UnitPromotions["PROMOTION_MARKED_TARGET"].ID
--	local ClearShot1ID = GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_1"].ID
--	local ClearShot2ID = GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_2"].ID
	local ClearShot3ID = GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_3"].ID
	
	local Formation1ID = GameInfo.UnitPromotions["PROMOTION_FORMATION_1"].ID
	local Formation2ID = GameInfo.UnitPromotions["PROMOTION_FORMATION_2"].ID
	local Ambush1ID = GameInfo.UnitPromotions["PROMOTION_AMBUSH_1"].ID
	local Ambush2ID = GameInfo.UnitPromotions["PROMOTION_AMBUSH_2"].ID
	
	local LegionGroupID = GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID
	
	local BlackBirdID = GameInfo.UnitPromotions["PROMOTION_BLACKBIRD_RECON"].ID
		
	local SetUpID = GameInfo.UnitPromotions["PROMOTION_MUST_SET_UP"].ID	
	
-----------This is for AI Bonus vs Human!
		for playerID,AIplayer in pairs(Players) do
			if AIplayer == nil then
				print ("No players")
				return
			end	
			

			local AICityCount = AIplayer:GetNumCities()	
	
			if AICityCount > 0 and not AIplayer:IsMinorCiv() and not AIplayer:IsBarbarian() and not AIplayer:IsHuman() then 
			
			
		-----------------AI will gain additional Manpower when at war with Human
				if PlayersAtWar(player,AIplayer) then
				   print ("AI at War with Human!")
				   
--				   local AITeamID = AIplayer:GetTeam()
				   
				   ------------------Give AI Map visibility so their units won't wander around			  
--				   for i = 0, Map.GetNumPlots()-1, 1 do
--						local plot = Map.GetPlotByIndex(i);
--						plot:ChangeVisibilityCount(AITeamID, 10, -1, true, false);
--						plot:SetRevealed(AITeamID, true);
--						plot:UpdateFog();
--						plot:UpdateVisibility();
--						Game.UpdateFOW(true);
--				    end
				   
				   local AICapital = AIplayer:GetCapitalCity()
				   
				   if AICanBeBoss (AIplayer) and AICapital:GetPopulation() > 9 then	
				   	  AIplayer:SetHasPolicy(GameInfo.Policies["POLICY_AI_ATWAR_BONUS"].ID,true)
				   	  print ("You Human want to fuck with AI? We have War Bonus!")
				   end
				   
--				   for unit in AIplayer:Units() do
--					   if unit ~= nil then
--					   
--					   		 -------------------Force AI to set their aircrafts intercepting!-------No Effect?	
--							if unit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_FIGHTER then
--							   unit:SetMoves(400)	
--							   unit:SetMadeInterception (false)
--							   unit:PushMission(GameInfoTypes.MISSION_AIRPATROL)
--						  	   print ("AI Fighter Intercepting!")
--							end
--						end	
--					end
				   
				   
				else
 					print ("AI Not at War with Human!")					
					if AIplayer:HasPolicy(GameInfo.Policies["POLICY_AI_ATWAR_BONUS"].ID) then
						AIplayer:SetHasPolicy(GameInfo.Policies["POLICY_AI_ATWAR_BONUS"].ID,false)
						print ("AI Bonus cancelled!")
					end
				end
				
							
			end
		end
	
	
	
	
	
	
	
		for unit in player:Units() do
		
		
	-------	Fix Possible 0 HP Unit Bug (Temp Method)
			if unit:GetDamage() >=100 or unit:GetCurrHitPoints() <=0 then
				unit:Kill()	
				print ("-----------------------BUG Fix-------0HP Unit---------------")
			end
		
		
	-----------Remove Temp Units	
			if unit:GetUnitType() == GameInfoTypes.UNIT_UAV then
				unit:Kill()	
				print ("UAV Removed!")
			end
		
		
	----------UAV Carriers
			if unit:GetUnitType() == GameInfoTypes.UNIT_NUCLEAR_SUBMARINE or unit:GetUnitType() == GameInfoTypes.UNIT_STEALTH_HELICOPTER then
				unit:SetHasPromotion(DroneCarrierID, true)
			end


		
		
					
	--------Anti-mounted auto upgrade to anti-tank		
				if unit:GetUnitType() == GameInfoTypes.UNIT_ANTI_TANK_GUN then --------anti-mounted auto upgrade to anti-tank
					if unit:IsHasPromotion(Formation1ID) then
					   unit:SetHasPromotion(Formation1ID,false)
					   unit:SetHasPromotion(Ambush1ID,true)
					end
					if unit:IsHasPromotion(Formation2ID) then
					   unit:SetHasPromotion(Formation2ID,false)
					   unit:SetHasPromotion(Ambush2ID,true)
					end	
				end
			
		
	-------No Set-up for French Howitzer		
				if unit:GetUnitType() == GameInfoTypes.UNIT_HOWITZER and player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_FRANCE"] then --------anti-mounted auto upgrade to anti-tank
					if unit:IsHasPromotion(SetUpID) then
					   unit:SetHasPromotion(SetUpID,false)
					end
				end		
		
		
		
----------Remove mis-placed units	
				if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID) then
					local plot = unit:GetPlot()
					if plot~= nil then
						if plot:GetImprovementType() == nil or plot:GetImprovementType() ~= GameInfo.Improvements["IMPROVEMENT_CITADEL"].ID then
							unit:Kill()	
							print ("Miss-placed Citidal units Removed!")
						end	
					end
				end
		
		
		
		
		
		
		
		
----------Restore form Temp Effects
			if unit:IsHasPromotion(RapidMarchID) or unit:IsHasPromotion(MarkedTargetID) or unit:IsHasPromotion(ClearShot3ID) or unit:IsHasPromotion(LegionGroupID) or unit:IsHasPromotion(BlackBirdID) then
			 	if unit ==nil then
					return
				end
			 	unit:SetHasPromotion(RapidMarchID,false)		 	
				unit:SetHasPromotion(MarkedTargetID,false)
				unit:SetHasPromotion(ClearShot3ID,false)
				unit:SetHasPromotion(LegionGroupID,false)    
				unit:SetHasPromotion(BlackBirdID,false)   
			end
			
	---- Restore form Debuff Effects		
			if unit:IsHasPromotion(Penetration1ID) or unit:IsHasPromotion(SlowDown1ID) or unit:IsHasPromotion(MoralWeaken1ID) or unit:IsHasPromotion(LoseSupplyID) then	------Remove Debuff		
	--			print ("Find Debuffed Unit!")
			 	if unit ==nil then
					return
				end
				local CurrHP = unit:GetCurrHitPoints()
				local MaxHP = unit:GetMaxHitPoints()
				if (CurrHP == MaxHP) then
					unit:SetHasPromotion(Penetration1ID, false)
					unit:SetHasPromotion(Penetration2ID, false)
					unit:SetHasPromotion(SlowDown1ID, false)
					unit:SetHasPromotion(SlowDown2ID, false)
					unit:SetHasPromotion(MoralWeaken1ID, false)
					unit:SetHasPromotion(MoralWeaken2ID, false)
					unit:SetHasPromotion(LoseSupplyID, false)
	--					print("Health Restored, Removed Debuff!")
				end			
			end
			
			
				
	----------Naval Carriers Auto Restore Cargos			
				if unit:IsHasPromotion(AirCraftCarrierID) or unit:IsHasPromotion(MissileCarrierID) or unit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL then   
					if unit ==nil then
						return
					end
	--				
	--				if not unit:GetDomainType() == DomainTypes.DOMAIN_SEA then
	--			    	print ("Not Naval Unit!")
	--			 	   return
	--			    end
					
				    local plot = unit:GetPlot()
				    if plot == nil then
				    	print ("Unit not available for restoring!")
				    	return
				    end
				    
	--			    if plot:IsCity() then
	--			    	print ("Cannot restore aircrafts in the city!")
	--			    	return
	--			    end
				    
				    
	
				    
				    if unit:IsHasPromotion(AirCraftCarrierID) then
				    
				    	unit:SetHasPromotion(DroneCarrierID, true)
				    	CarrierPromotionTransfer(unit,player,plot) 
				    	
				    	print ("Promotions Transfer Finished!") 
				    end
				    
				    
				    if unit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL then
				    	AASPromotionTransfer(unit,player,plot) 
				    	print ("Promotions Transfer Finished on AAS!") 
				    end
				    
				    
					if not unit:IsFull() and not plot:IsCity() then
						if plot:IsFriendlyTerritory(player) or unit:IsHasPromotion(CarrierSupply3ID) then
						    print ("Unit is avaliable for retoring cargo!")
						    if (player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ENGLAND"]) then
						    	print ("English Navy")
						    	CarrierRestoreEngland(unit,player,plot)
						    else   	
								CarrierRestore(unit,player,plot)				   
							end
						end	 
	    			end    		
				end
			end
	

 					
 											
 												
----------Local Militia 									
-- 	for pCity in player:Cities() do   
-- 	
--
-- 	        
-- 	        
-- 	        
-- 	     ----------Local Militia born on captured cities	   
-- 		if pCity:GetResistanceTurns() > 0 then 
-- 			print ("Find a city in resistance!")			
-- 			local CityOriginalOwnerID = pCity:GetOriginalOwner() 
-- 			local CityOriginalOwner = Players[CityOriginalOwnerID] 
-- 			
-- 			if CityOriginalOwnerID ~= playerID and CityOriginalOwner: GetNumCities() > 1 then
-- 				print ("This city is not built by the player!")
-- 				 			 			
--	 			local pTeam = Teams[CityOriginalOwner:GetTeam()]
--	 			
--	 			print ("Find the original owner!")
--	 			
--	 			local pPlot = pCity
--	 		
--	 		
--	 			
--	 			local plotX = pPlot:GetX()+1
--	 			local plotY = pPlot:GetY()+1
--	 			local RivalLandID = GameInfo.UnitPromotions["PROMOTION_RIVAL_TERRITORY"].ID	
--	 			
--	 			if pTeam:IsHasTech(GameInfoTypes["TECH_MOBILE_TACTICS"]) then
--	 				local NewUnit = CityOriginalOwner:InitUnit(GameInfoTypes.UNIT_MILITIA_MODERN, plotX, plotY, UNITAI_DEFENSE)
--	 				NewUnit:SetHasPromotion(RivalLandID, true)
--	 				NewUnit:JumpToNearestValidPlot() 
--	 				NewUnit:SetHasPromotion(RivalLandID, false)
--	 				print ("New Modern Militia Born!") 
--	 			elseif pTeam:IsHasTech(GameInfoTypes["TECH_MOBILIZATION_T"]) then
--	 				local NewUnit = CityOriginalOwner:InitUnit(GameInfoTypes.UNIT_CONSCRIPTMAN, plotX, plotY, UNITAI_DEFENSE)
--	 				NewUnit:SetHasPromotion(RivalLandID, true)
--	 				NewUnit:JumpToNearestValidPlot() 
--	 				NewUnit:SetHasPromotion(RivalLandID, false)	
--	 				print ("New Conscript Born!") 	
--	 			elseif pTeam:IsHasTech(GameInfoTypes["TECH_METALLURGY"]) then
-- 					local NewUnit = CityOriginalOwner:InitUnit(GameInfoTypes.UNIT_AMERICAN_MINUTEMAN, plotX, plotY, UNITAI_DEFENSE)
-- 					NewUnit:SetHasPromotion(RivalLandID, true)
-- 					NewUnit:JumpToNearestValidPlot() 
-- 					NewUnit:SetHasPromotion(RivalLandID, false)
-- 					print ("New Minuteman Born!") 
--	 			elseif pTeam:IsHasTech(GameInfoTypes["TECH_ENGINEERING"]) then 				
--	 				local NewUnit = CityOriginalOwner:InitUnit(GameInfoTypes.UNIT_MILITIA_ANCIENT, plotX, plotY, UNITAI_DEFENSE)
--	 				NewUnit:SetHasPromotion(RivalLandID, true)
--	 				NewUnit:JumpToNearestValidPlot() 
--	 				NewUnit:SetHasPromotion(RivalLandID, false)
--	 				print ("New Militia Born!") 				
--	 			else 				
--	 				local NewUnit = CityOriginalOwner:InitUnit(GameInfoTypes.UNIT_WARRIOR, plotX, plotY, UNITAI_DEFENSE)
--	 				NewUnit:SetHasPromotion(RivalLandID, true)
--	 				NewUnit:JumpToNearestValidPlot() 
--	 				NewUnit:SetHasPromotion(RivalLandID, false)
--	 				print ("New Warrior Born!")
--	 			end
-- 			end	
-- 			
-- 			
 			
 			
 			 	
 		----------Rebals born inside player's cities if Public Opinion is Revolutional Wave!
--	 	    if player:GetPublicOpinionType() == PublicOpinionTypes.PUBLIC_OPINION_REVOLUTIONARY_WAVE then
--	 	       local BarbarianCivlizationType = GameInfos.Civilizations.CIVILIZATION_BARBARIAN.ID 
--	 	       local BarbarianPlayer = GetPlayerByCivilization (BarbarianCivlizationType)
--	 	       print (BarbarianPlayer:GetName())
--	 	       
--	 	       local pPlot = pCity 		
--	 		   local plotX = pPlot:GetX()+1
--	 		   local plotY = pPlot:GetY()+1
--	 	       
--	 	       if pCity:GetPopulation() >= 30 then
--	 	       	  if player:GetCurrentEra() >= 8 then
--	 	       	  	 local NewUnit = BarbarianPlayer:InitUnit(GameInfoTypes.UNIT_MILITIA_MODERN, plotX, plotY, UNITAI_DEFENSE)
--	 			     NewUnit:JumpToNearestValidPlot() 
--	 	       	  elseif player:GetCurrentEra() >= 6 and player:GetCurrentEra() < 8 then
--	 	       	  	 local NewUnit = BarbarianPlayer:InitUnit(GameInfoTypes.UNIT_CONSCRIPTMAN, plotX, plotY, UNITAI_DEFENSE)
--	 			     NewUnit:JumpToNearestValidPlot() 
--	 			  else 
--	 			   	 local NewUnit = BarbarianPlayer:InitUnit(GameInfoTypes.UNIT_AMERICAN_MINUTEMAN, plotX, plotY, UNITAI_DEFENSE)
--	 			     NewUnit:JumpToNearestValidPlot() 
--	 			  	 print ("Revolution Wave!!!Rebel Spawn!!!")
--	 			  end	 
--	 	       end
--	 	    end    
-- 			
-- 		end
-- 	end									

end

	



end------function end
GameEvents.PlayerDoTurn.Add(NewUnitCreationRules)


-- AI CARRIER RESUPPLY CODE

--[[
function AICarrierResupply (playerID)   

	print ("AI Carrier invoked.")

		local player = Players[playerID]
	
		if player == nil then
			return
		end
	
		if player:IsBarbarian() then 
		   return
		end  
		
		
		if player:IsMinorCiv() then 
		   return
		end 
		

		if player:GetNumCities() < 1 then ---- In case of 0 city error
			return
		end


		if not player:IsHuman() then

			print ("AI Carrier Promotions")

			local AirCraftCarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_UNIT"].ID
			local CarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_UNIT"].ID
	
			local CarrierSupply3ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_3"].ID
			local MissileCarrierID = GameInfo.UnitPromotions["PROMOTION_MISSILE_CARRIER"].ID
			local DroneCarrierID = GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID
			
			
			local Penetration1ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_1"].ID
			local Penetration2ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_2"].ID
			local SlowDown1ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID
			local SlowDown2ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_2"].ID
			local MoralWeaken1ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_1"].ID
			local MoralWeaken2ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_2"].ID
			local LoseSupplyID = GameInfo.UnitPromotions["PROMOTION_LOSE_SUPPLY"].ID
				
			local RapidMarchID = GameInfo.UnitPromotions["PROMOTION_RAPID_MARCH"].ID
			local MarkedTargetID = GameInfo.UnitPromotions["PROMOTION_MARKED_TARGET"].ID
		 --	local ClearShot1ID = GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_1"].ID
		 --	local ClearShot2ID = GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_2"].ID
			local ClearShot3ID = GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_3"].ID
			
			local Formation1ID = GameInfo.UnitPromotions["PROMOTION_FORMATION_1"].ID
			local Formation2ID = GameInfo.UnitPromotions["PROMOTION_FORMATION_2"].ID
			local Ambush1ID = GameInfo.UnitPromotions["PROMOTION_AMBUSH_1"].ID
			local Ambush2ID = GameInfo.UnitPromotions["PROMOTION_AMBUSH_2"].ID
			
			local LegionGroupID = GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID
			
			local BlackBirdID = GameInfo.UnitPromotions["PROMOTION_BLACKBIRD_RECON"].ID
				
			local SetUpID = GameInfo.UnitPromotions["PROMOTION_MUST_SET_UP"].ID	

			for unit in player:Units() do

				print ("AI Carrier Search")

				local plot = unit:GetPlot()
	
				if unit:IsHasPromotion(CarrierID) and not unit:IsFull() then
					print ("AI Carrier Detected")
					 
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
						print ("Found AI Normal Super Carrier1!")
								
					 	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ENGLAND"] then

						     if plot ~= nil and not plot:IsCity() then
						 		 print ("Found AI English Super Carrier!")
								 player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)								 
							 end			
						else

						     if not plot:IsCity() then
								 print ("Found AI Normal Super Carrier2!")
							     player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR)
						     end			
					 	end				   
					end
					print ("AI:Aircrafts carrier code complete")
				end

			end
		end


end
GameEvents.PlayerDoTurn.Add(AICarrierResupply)
]]--


function LegionMovement (playerID, unitID, bRemainingMoves)

	print ("Grouped Function loaded!")

	local player = Players[ playerID ]
	local unit = player:GetUnitByID(unitID)

	if player ==nil then
		return
	end
	
	if unit ==nil then
		return
	end	

	if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID) then
		--		local plotX = unit:GetX()
		--		local plotY = unit:GetY()
		local DesPlot = unit:LastMissionPlot()
		UnitGroupMovement(player,DesPlot,unitID)
		
		--[[REMOVES PROMOTION ]]--
		--unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, false)				
		print ("Find a Legion moved!")
	end

end	------function end
Events.UnitSelectionChanged.Add(LegionMovement);






----------------------------------------------------------------------Utilities--------------------------------------


function UnitGroupMovement(player,DesPlot,unitID)---------Move all Units in a Legion
	for unit in player:Units() do
		if unit:IsCombatUnit() and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID) and unit:GetID() ~= unitID then
--		   unit:SetXY(plotX,plotY)
		   local unitPlot = unit:GetPlot()
		   local unitCount = DesPlot:GetNumUnits()
		   
		   if unitCount >= 2 then
		   	for i = 0, 5 do
				local adjPlot = Map.PlotDirection(DesPlot:GetX(), DesPlot:GetY(), i)
				if adjPlot ~= nil and adjPlot:GetNumUnits()< 2 then
			   	    DesPlot = adjPlot
			   	    break
			   	end 
		   	 end  
		   end
		   
		   local plotX = DesPlot:GetX()
		   local plotY = DesPlot:GetY()
		   
		   unit:PushMission(MissionTypes.MISSION_MOVE_TO, plotX, plotY, 0, 0, 1, MissionTypes.MISSION_MOVE_TO, unitPlot, unit)
	
		  
--		   if unitCount >= 3 then
--		  	  unit:JumpToNearestValidPlot()
--		   end
		   unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, false)
--		   unit:SetMoves(0)
		   print ("Group Movement finished!")	
		end
	end
end






function CarrierRestoreEngland(unit,player,plot) ---------English Carrier with Harrier Fighters


   	if unit:GetUnitType() == GameInfoTypes.UNIT_CARRIER then
   		player:InitUnit(GameInfoTypes.UNIT_JAPANESE_ZERO, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)
		print ("Aircrafts restored on carrier!")
					  
					  
					  
	elseif unit:GetUnitType() == GameInfoTypes.UNIT_NUCLEAR_CARRIER then
				
		local unitCount = plot:GetNumUnits()
		for i = 0, unitCount-1, 1 do
			local pFoundUnit = plot:GetUnit(i)			
			
			if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_JAPANESE_ZERO then		-----------Remove the old aircrafts			
				print ("Found old English aircrafts!")
				pFoundUnit:Kill()
				player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
			end
		end
		
		player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)															
		print ("Aircrafts restored on English nuclear powered carrier!")
	
	
	
	
	elseif unit:GetUnitType() == GameInfoTypes.UNIT_SUPER_CARRIER or unit:GetUnitType() == GameInfoTypes.UNIT_AMERICAN_NIMITZ then
	
		local unitCount = plot:GetNumUnits()
		for i = 0, unitCount-1, 1 do
			local pFoundUnit = plot:GetUnit(i)			
			
			if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_CARRIER_FIGHTER_JET or unit:GetUnitType() == GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER then		-----------Remove the old aircrafts			
				print ("Found old aircrafts!")
				pFoundUnit:Kill()
				player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
			end
		end
		
		player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)											
		print ("Aircrafts restored on English super-carrier!")
	end
	
	if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MISSILE_CARRIER"].ID) then	
		while not unit:IsFull() do
			player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR):SetMoves(0)			
			print ("Missile restored!")
		end
	end
		
--	if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID) then
--		print ("UAV Carrier found!")
--		local pTeam = Teams[player:GetTeam()]
--		if pTeam:IsHasTech(GameInfoTypes["TECH_ARTIFICIAL_INTELLIGENCE"]) then
--			player:InitUnit(GameInfoTypes.UNIT_UAV, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR):SetMoves(0)
--			print ("UAV restored!")
--		end		
--   	end 
   	
end








function CarrierRestore(unit,player,plot) ----------------Other Nations' normal carrier-based fighters


	local pTeam = Teams[player:GetTeam()]
	
   	if unit:GetUnitType() == GameInfoTypes.UNIT_CARRIER then
   		player:InitUnit(GameInfoTypes.UNIT_JAPANESE_ZERO, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)
		print ("Aircrafts restored on carrier!")
					  
					  
					  
	elseif unit:GetUnitType() == GameInfoTypes.UNIT_NUCLEAR_CARRIER then
				
		local unitCount = plot:GetNumUnits()
		for i = 0, unitCount-1, 1 do
			local pFoundUnit = plot:GetUnit(i)			
			
			if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_JAPANESE_ZERO then		-----------Remove the old aircrafts			
				print ("Found old aircrafts!")
				pFoundUnit:Kill()
				player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_JET, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
			end
		end
		
		player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_JET, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)															
		print ("Aircrafts restored on nuclear powered carrier!")
	
	
	
	
	elseif unit:GetUnitType() == GameInfoTypes.UNIT_SUPER_CARRIER then
		
		local unitCount = plot:GetNumUnits()
		for i = 0, unitCount-1, 1 do
			local pFoundUnit = plot:GetUnit(i)
			if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_CARRIER_FIGHTER_JET then		-----------Remove the old aircrafts	
				print ("Found old aircrafts!")
				pFoundUnit:Kill()
				player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
			end
		end
		
		player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)											
		print ("Aircrafts restored on super-carrier!")
	
	
	
	----------------Nimitz Special
	
	elseif unit:GetUnitType() == GameInfoTypes.UNIT_AMERICAN_NIMITZ then
		if pTeam:IsHasTech(GameInfoTypes["TECH_NUCLEAR_FUSION"]) then
			print ("Nimitz can have Carrier-Fighter-Adv!")
			local unitCount = plot:GetNumUnits()
			for i = 0, unitCount-1, 1 do
				local pFoundUnit = plot:GetUnit(i)
				if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_CARRIER_FIGHTER_JET then		-----------Remove the old aircrafts	
					print ("Found old aircrafts!")
					pFoundUnit:Kill()
					player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
				end
			end
			player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)											
			print ("Carrier-Fighter-Adv restored on super-carrier!")
		else
			local unitCount = plot:GetNumUnits()
			for i = 0, unitCount-1, 1 do
				local pFoundUnit = plot:GetUnit(i)			
				
				if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_JAPANESE_ZERO then		-----------Remove the old aircrafts			
					print ("Found old aircrafts!")
					pFoundUnit:Kill()
					player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_JET, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
				end
			end		
			player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_JET, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)															
			print ("Carrier-Fighter-Jet restored on Nimitz!")			
		end		
	end
	
	
	if unit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL then
		while not unit:IsFull() do
			player:InitUnit(GameInfoTypes.UNIT_FRANCE_EUROCOPTER_TIGER, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR):SetMoves(0)		
			print ("French Eurotiger restored!")
		end
	end
	
	
	if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MISSILE_CARRIER"].ID) then	
		while not unit:IsFull() do
			player:InitUnit(GameInfoTypes.UNIT_GUIDED_MISSILE, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR):SetMoves(0)			
			print ("Missile restored!")
		end
	end
	
		
--	if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID) then
--		print ("UAV Carrier found!")
--		if pTeam:IsHasTech(GameInfoTypes["TECH_ARTIFICIAL_INTELLIGENCE"]) then
--			player:InitUnit(GameInfoTypes.UNIT_UAV, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR):SetMoves(0)
--			print ("UAV restored!")
--		end		
--   	end 
end








function CarrierPromotionTransfer(unit,player,plot) 
	local AirCraftCarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_UNIT"].ID
	local AirCraftID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER"].ID
	
	local AntiAir1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_ANTI_AIR_1"].ID
	local AntiAir2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_ANTI_AIR_2"].ID
	
	local AirFight1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_AIRFIGHT_1"].ID
	local AirFight2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_AIRFIGHT_2"].ID
	local Attack1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_ATTACK_1"].ID
	local Attack2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_ATTACK_2"].ID
	local Siege1ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_SIEGE_1"].ID
	local Siege2ID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_SIEGE_2"].ID
	local SupplyID = GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_2"].ID
	local SortieID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_SORTIE"].ID

	
	if unit:IsHasPromotion(AirCraftCarrierID) and unit:HasCargo() then
		print("Found the carrier!")
		local unitCount = plot:GetNumUnits()

		for i = 0, unitCount-1, 1 do
			local pFoundUnit = plot:GetUnit(i)				
			print ("Found the aircraft on the carrier!")
			
			
			if pFoundUnit:IsCargo() and pFoundUnit:IsHasPromotion(AirCraftID) then 
				
				if unit:IsHasPromotion(AntiAir1ID) then
					pFoundUnit:SetHasPromotion(AirFight1ID, true) 
				end
				if unit:IsHasPromotion(AntiAir2ID) then
					pFoundUnit:SetHasPromotion(AirFight2ID, true) 
				end			
				if unit:IsHasPromotion(Attack1ID) then
					pFoundUnit:SetHasPromotion(Attack1ID, true) 													
				end					
				if unit:IsHasPromotion(Attack2ID) then
					pFoundUnit:SetHasPromotion(Attack2ID, true) 													
				end					
				if unit:IsHasPromotion(Siege1ID) then
					pFoundUnit:SetHasPromotion(Siege1ID, true) 													
				end				
				if unit:IsHasPromotion(Siege2ID) then
					pFoundUnit:SetHasPromotion(Siege2ID, true) 													
				end					
				if unit:IsHasPromotion(SupplyID) then
					pFoundUnit:SetHasPromotion(SupplyID, true) 													
				end
				if unit:IsHasPromotion(SortieID) then
					pFoundUnit:SetHasPromotion(SortieID, true) 													
				end
					
			end
		end
	end
end





function AASPromotionTransfer(unit,player,plot) 

	local Sunder1ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_1"].ID
	local Sunder2ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_2"].ID
	local Sunder3ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_3"].ID
	local CollDamageLV1ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_1"].ID
	local CollDamageLV2ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_2"].ID
	local CollDamageLV3ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_3"].ID
	
	local LogisticsID = GameInfo.UnitPromotions["PROMOTION_LOGISTICS"].ID
	

	if unit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL and unit:HasCargo() then
		print("Found the AAS!")
		local unitCount = plot:GetNumUnits()

		for i = 0, unitCount-1, 1 do
			local pFoundUnit = plot:GetUnit(i)				
			print ("Found the aircraft on the AAS!")
						
			if pFoundUnit:IsCargo() and unit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL then 
				
				if unit:IsHasPromotion(Sunder1ID) then
					pFoundUnit:SetHasPromotion(Sunder1ID, true) 
					print("Promotion for aircrafts on the carrier!-AntiAir1")								
				end
				if unit:IsHasPromotion(Sunder2ID) then
					pFoundUnit:SetHasPromotion(Sunder2ID, true) 
					print("Promotion for aircrafts on the carrier!-AntiAir2")												
				end			
				if unit:IsHasPromotion(Sunder3ID) then
					pFoundUnit:SetHasPromotion(Sunder3ID, true) 													
				end					
				if unit:IsHasPromotion(CollDamageLV1ID) then
					pFoundUnit:SetHasPromotion(CollDamageLV1ID, true) 													
				end					
				if unit:IsHasPromotion(CollDamageLV2ID) then
					pFoundUnit:SetHasPromotion(CollDamageLV2ID, true) 													
				end				
				if unit:IsHasPromotion(CollDamageLV3ID) then
					pFoundUnit:SetHasPromotion(CollDamageLV3ID, true) 													
				end					
				if unit:IsHasPromotion(LogisticsID) then
					pFoundUnit:SetHasPromotion(LogisticsID, true) 													
				end		
			end
		end
	end
	
	
end





function NimitizBugFix(iTeam, iTech, bAdopted)-------------Fix full Nimitz won't restore fighter bug

local pTeam = Teams[iTeam]
	
	if not pTeam:IsHuman() then
--	print ("Only for human!")
	 	return
	end
	
	local player = Players[Game.GetActivePlayer()]
	if player:IsMinorCiv() and player:IsBarbarian()  then
	 	return
	end
		
	if iTech == GameInfoTypes["TECH_NUCLEAR_FUSION"] then	
		print ("Nuclear Fusion Researched!")
		for unit in player:Units() do
			if unit:GetUnitType() == GameInfoTypes.UNIT_AMERICAN_NIMITZ then
				local plot = unit:GetPlot()
				print ("Nimitz can have Carrier-Fighter-Adv!")
				local unitCount = plot:GetNumUnits()
				for i = 0, unitCount-1, 1 do
					local pFoundUnit = plot:GetUnit(i)
					if pFoundUnit:GetUnitType() == GameInfoTypes.UNIT_CARRIER_FIGHTER_JET then		-----------Remove the old aircrafts	
						print ("Found old aircrafts!")
						pFoundUnit:Kill()
						player:InitUnit(GameInfoTypes.UNIT_CARRIER_FIGHTER_ADV, plot:GetX(), plot:GetY(),UNITAI_ATTACK_AIR):SetMoves(0)	
					end
				end
				print ("Carrier-Fighter-Adv restored on Nimitz!")
			end
		end
	end

end
GameEvents.TeamSetHasTech.Add(NimitizBugFix)


-------------If players are AT WAR?
--
--function PlayersAtWar(iPlayer,ePlayer)
--	local iTeam = Teams[iPlayer:GetTeam()];
--	local eTeamIndex = ePlayer:GetTeam();
--	if iTeam:IsAtWar(eTeamIndex) then
--	   return true;
--	else
--	   return false;
--	end
--end
--
--
--






print("NewUnitRules Check success!")





