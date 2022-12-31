---------------------------------------------------------------------------------------
-- Super Power New Attack Effects
-- Author: Lincoln_lyf
-- DateCreated: 02/25/2014 
-- DateRefined: 12/28/2014
--------------------------------------------------------------



include( "UtilityFunctions.lua" )



-----------------------------------------New Attack Effects for Melee Attacks (Event.CombatResult)---------------------------------------------------

function NewAttackEffectMelee(
		attPlayerID,
		attUnitID,
		attUnitDamage,
		attFinalUnitDamage,
		attMaxHitPoints,
		defPlayerID,
		defUnitID,
		defUnitDamage,
		defFinalUnitDamage,
		defMaxHitPoints
		)
		
----------Defines and status checks
   local attPlayer	= Players[attPlayerID]
    if not attPlayer then 
	   return
	end
	
	local attUnit = attPlayer:GetUnitByID(attUnitID)	
	if not attUnit then 
	   return
	end
	
	local defPlayer	= Players[defPlayerID]	
	if not defPlayer then 
	   return
	end
	
	local defUnit = defPlayer:GetUnitByID(defUnitID)	
	if not defUnit then 
	   return
	end
	
	
	
	
 
	--Only for Human VS AI(reduce time and enhance stability!)
	if not defPlayer:IsHuman() and not attPlayer:IsHuman() then 
		return
	end






------Map XY Grids
	local attX = attUnit:GetX()
	local attY = attUnit:GetY()
	local defX = defUnit:GetX()
	local defY = defUnit:GetY()
	
	
------Units Strength	
	local attUnitStrength = attUnit:GetBaseCombatStrength()
	local defUnitStrength = defUnit:GetBaseCombatStrength()



-------	PromotionID 

	local AntiDebuffID = GameInfo.UnitPromotions["PROMOTION_ANTI_DEBUFF"].ID
	
	if defUnit:IsHasPromotion(AntiDebuffID) then  ----------Debuff immune unit
		print ("This unit is debuff immune")
		return
	end


	local KnightID = GameInfo.UnitPromotions["PROMOTION_KNIGHT_COMBAT"].ID
	local TankID = GameInfo.UnitPromotions["PROMOTION_TANK_COMBAT"].ID
	local Charge1ID = GameInfo.UnitPromotions["PROMOTION_CHARGE_1"].ID
	local Charge2ID = GameInfo.UnitPromotions["PROMOTION_CHARGE_2"].ID
	local Charge3ID = GameInfo.UnitPromotions["PROMOTION_CHARGE_3"].ID

	local Barrage1ID = GameInfo.UnitPromotions["PROMOTION_BARRAGE_1"].ID
	local Barrage2ID = GameInfo.UnitPromotions["PROMOTION_BARRAGE_2"].ID
	local Barrage3ID = GameInfo.UnitPromotions["PROMOTION_BARRAGE_3"].ID
	
	local Sunder1ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_1"].ID
	local Sunder2ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_2"].ID
	local Sunder3ID = GameInfo.UnitPromotions["PROMOTION_SUNDER_3"].ID
	
	local Penetration1ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_1"].ID
	local Penetration2ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_2"].ID
	
	local SiegeUnitID = GameInfo.UnitPromotions["PROMOTION_CITY_SIEGE"].ID
	local CollDamageLV1ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_1"].ID
	local CollDamageLV2ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_2"].ID
	local CollDamageLV3ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_3"].ID

	local KillingEffectsID = GameInfo.UnitPromotions["PROMOTION_GAIN_MOVES_AFFER_KILLING"].ID
	local CitadelID = GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID	
		
	local DestroySupply1ID = GameInfo.UnitPromotions["PROMOTION_DESTROY_SUPPLY_1"].ID
	local SPForce1ID = GameInfo.UnitPromotions["PROMOTION_SP_FORCE_1"].ID	
	
	local LoseSupplyID = GameInfo.UnitPromotions["PROMOTION_LOSE_SUPPLY"].ID	
	
	
	local CQBCombat1ID = GameInfo.UnitPromotions["PROMOTION_CQB_COMBAT_1"].ID	
	local CQBCombat2ID = GameInfo.UnitPromotions["PROMOTION_CQB_COMBAT_2"].ID	
	local SuppressionID = GameInfo.UnitPromotions["PROMOTION_LASER_SUPPRESSION"].ID	

	
	local SpecialForcesID = GameInfo.UnitPromotions["PROMOTION_SPECIAL_FORCES_COMBAT"].ID	
	
	
	------LaserSuppression and CQB Combat Freeze the Attacker	
	
	if defUnit:IsHasPromotion(SuppressionID) and attUnit:GetDomainType() == DomainTypes.DOMAIN_LAND then
		if not attUnit:IsHasPromotion(SiegeUnitID) then
			attUnit:SetMoves(0)
			Message = 1
			print ("Attacker Stopped!")	
		end	
	end
	
	
	if defUnit:IsHasPromotion(CQBCombat1ID) and not attUnit:IsRanged() then
		if defUnit:IsHasPromotion(CQBCombat2ID)  then			
			attUnit:SetMoves(0)
			Message = 3
			print ("Attacker Stopped!")				
		elseif attFinalUnitDamage < 20 then		
			attUnit:SetMoves(0)
			Message = 3	
			print ("Attacker Stopped!")		
		end   
	end
	
-------------Remove the Citadel Improvement after the fixed artillery is destroyed	
 	if defUnit:IsHasPromotion(CitadelID) and defFinalUnitDamage >= 100 then
   	   local pDefendedPlot = Map.GetPlot(plotX, plotY)	
	   pDefendedPlot:SetImprovementType(-1)
	   print ("Citadel Unit Destroyed!")
	end	



----------- PROMOTION_GAIN_MOVES_AFFER_KILLING Effects
  	if attUnit:IsHasPromotion(KillingEffectsID) then  
  		print ("DefUnit Damage:"..defFinalUnitDamage) 
  		if defFinalUnitDamage >= 100 and defUnit:GetUnitCombatType() ~= GameInfoTypes.UNITCOMBAT_RECON then   		
  		   local MovesLeft = attUnit:GetMoves() 
  		   print ("MoveLeft:" ..MovesLeft)	 
		   attUnit:SetMoves(MovesLeft+100)
		   attUnit:SetMadeAttack(false)
		   print ("Ah, fresh meat!")
	   end
 	end   



	------Charge Damage		   
   	if attUnit:IsHasPromotion(KnightID) or attUnit:IsHasPromotion(LandIcD) or attUnit:IsHasPromotion(TankID) then     
	local pPlot = Map.GetPlot(defX, defY)
		if (pPlot ~= nil) then
--			print("Available for Charge Damage!")
			local unitCount = pPlot:GetNumUnits()
			
			if unitCount <=1 then
				return
			end	 		
				 		
				 		
			if (defUnit ~= nil) then			  
			

											
--				print ("Their damage done ="..attFinalUnitDamage)
				print ("Our damage done="..defFinalUnitDamage)
				if(attFinalUnitDamage < defFinalUnitDamage) then	

				
					
					for i = 0, unitCount-1, 1 do		
						local pFoundUnit = pPlot:GetUnit(i)		
						if pFoundUnit == nil then
							return
						end
						
						local pUnitStrength = pFoundUnit:GetBaseCombatStrength()
						local pPlayer = Players[pFoundUnit:GetOwner()]
								print("pCombat="..pUnitStrength)
								
								
						if (pFoundUnit:GetID() ~= defUnit:GetID()) then
												
							if PlayersAtWar(attPlayer,pPlayer) then
						   	   local ChargeDamageOri = attUnit:GetCombatDamage(attUnitStrength, pUnitStrength, attUnit:GetDamage(),false,false, false)
						   	   
						   	    local ChargeMod = 0.5  -----The percentage of charging damage to the other unit
						   	    
						   	    
						   	    
						   	      if attUnit:IsHasPromotion(Charge1ID) then

				   	     			  ChargeMod = 0.5	
				   	     			  			   	     	
				   	   	 			  if attUnit:IsHasPromotion(Charge2ID) then				   	   	  
				   	     			 	 ChargeMod = 1.0
				   	     			 	 if defFinalUnitDamage < 100 then					 
						 			    	defUnit:ChangeDamage(10)									
									 	 end   	    
				   	     			  end
				   	     			  if attUnit:IsHasPromotion(Charge3ID) then				   	   	  
				   	     			 	 ChargeMod = 1.5  
				   	     			 	 if defFinalUnitDamage < 100 then					 
						 			    	defUnit:ChangeDamage(10)									
									 	 end   	    
				   	     			  end
				   	     			  
		   	     						   	     			 
				   	     			  print ("ChargeMod:"..ChargeMod)			   	      
				   	  			   end
						   	   
						   	   
						       local ChargeDamageFinal = ChargeDamageOri * ChargeMod
						       pFoundUnit:ChangeDamage(ChargeDamageFinal,attPlayer)
						       print("Charge Damage="..ChargeDamageFinal)
						       
						       
						       	if ChargeDamageFinal > 100 and attUnit:GetUnitType() ~= GameInfoTypes.UNIT_SUPER_TANK then -- if the attacker destroy the other unit in the target plot,it advances into the target plot!
							       	attUnit:SetXY(defX, defY)						       							       	
						       		-- Notification											
									if defPlayer:IsHuman() then
										local pFoundUnitName = pFoundUnit:GetName();
										local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_DESTROYED_SHORT")
										local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CHARGE_DAMAGE_DEATH", pFoundUnitName)
										defPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY)						
									end	
								end							       	
							end
						end	
			  		end	
			  		else
			  		print ("our damage done <= their damage done. Fail to charge!")
					return
			  	end			
			end	
		end	
   end	


 	
-- 	if attUnit:IsHasPromotion(SpecialForcesID) and defUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_RECON then
--  		if defFinalUnitDamage > 100  then 
--  		   local MovesLeft = attUnit:GetMoves() 
--  		   print ("MoveLeft:" ..MovesLeft)	 
--		   attUnit:SetMoves(MovesLeft+100)
--		   attUnit:SetMadeAttack(false)
--		   print ("Ah, fresh meat!")
--	   end
-- 	end   
 	

	if attUnit:IsHasPromotion(Charge1ID) and attFinalUnitDamage < defFinalUnitDamage then-----------Gain extra Mp for heavyCharge
   	   local MovesLeft = attUnit:GetMoves() 	
   	   attUnit:SetMoves(MovesLeft+100)	
   	   print ("Carging Unit Gains Movement!")
	end		



 -- Attacking with debuffs
   
    if attUnit:IsHasPromotion(Sunder1ID) or attUnit:IsHasPromotion(Barrage1ID) or attUnit:IsHasPromotion(CollDamageLV1ID) or attUnit:IsHasPromotion(DestroySupply1ID) or attUnit:IsHasPromotion(SPForce1ID) then
    

	    if defFinalUnitDamage >= 100 then
	    	print("Defender is dead, no debuff effects!")
	    	return
	    end
    
    
    	local defUnitName = defUnit:GetName();
  	 	local MovesLeft = defUnit:GetMoves()
  	 	local Message = 0
--  	 	print("Moves Left:"..MovesLeft)

    		if attUnit:IsHasPromotion(DestroySupply1ID) or attUnit:IsHasPromotion(SPForce1ID) then    			
    			defUnit:SetHasPromotion(LoseSupplyID, true)    				
    			Message = 5
    		end	


    	if (defFinalUnitDamage > 40 ) then   
    		if attUnit:IsHasPromotion(Sunder1ID) then
    			SetPenetration(defUnit) 
    			Message = 1    		 			
    		end
    		
    		if attUnit:IsHasPromotion(CollDamageLV1ID) then    			
    			SetMoralWeaken(defUnit) 			
    			Message = 4
    		end
    			    			
    		if attUnit:IsHasPromotion(Barrage1ID) and not defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID, true) then
    			defUnit:SetMoves(1)
    			SetSlowDown(defUnit) 
    			Message = 2
    		elseif attUnit:IsHasPromotion(Barrage1ID) and defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID, true) then 
    			defUnit:SetMoves(0)	
    			SetSlowDown(defUnit) 			
    			Message = 3    	
    		end
    	elseif (defFinalUnitDamage > 25 and defFinalUnitDamage < 40 ) then 
    		if attUnit:IsHasPromotion(Sunder2ID) then
    			SetPenetration(defUnit)
    			Message = 1
    		end
    		
    		if attUnit:IsHasPromotion(CollDamageLV2ID) then    			
    			SetMoralWeaken(defUnit) 			
    			Message = 4
    		end
    		
    		if attUnit:IsHasPromotion(Barrage2ID) and not defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID, true) then
    			defUnit:SetMoves(1)
    			SetSlowDown(defUnit) 
    			Message = 2
    		elseif attUnit:IsHasPromotion(Barrage2ID) and defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID, true) then 
    			defUnit:SetMoves(0)	
    			SetSlowDown(defUnit) 			
    			Message = 3    	
    		end
    	elseif (defFinalUnitDamage > 10 and defFinalUnitDamage < 25 ) then 
    		if attUnit:IsHasPromotion(Sunder3ID) then
    			SetPenetration(defUnit)
    			Message = 1 
    		end
    		
    		if attUnit:IsHasPromotion(CollDamageLV3ID) then    			
    			SetMoralWeaken(defUnit) 			
    			Message = 4
    		end
    		
    		if attUnit:IsHasPromotion(Barrage3ID) and not defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID, true) then
    			defUnit:SetMoves(1)
    			SetSlowDown(defUnit) 
    			Message = 2
    		elseif attUnit:IsHasPromotion(Barrage3ID) and defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID, true) then 
    			defUnit:SetMoves(0)	
    			SetSlowDown(defUnit) 			
    			Message = 3     			
    		end	
    	end   
    	
	-- Notification											
		if attPlayer:IsHuman() then 
			if Message == 1 then					
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_SUNDERED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_SUNDERED", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0	
			elseif Message == 2 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_SLOWED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_SLOWED", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0
			elseif Message == 3 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_STOPPED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_STOPPED", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0
			elseif Message == 4 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_MORAL_WEAKEN_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_MORAL_WEAKEN", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0	
			elseif Message == 5 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_SUPPLY_DESTROYED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ENEMY_SUPPLY_DESTROYED", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0			
			end
		elseif defPlayer:IsHuman() then
			if Message == 1 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_SUNDERED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_SUNDERED", defUnitName);
				defPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0	
			elseif Message == 2 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_SLOWED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_SLOWED", defUnitName);
				defPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0
			elseif Message == 3 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_STOPPED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_STOPPED", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0	
			elseif Message == 4 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_MORAL_WEAKEN_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_MORAL_WEAKEN", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0	
			elseif Message == 5 then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_SUPPLY_DESTROYED_SHORT");
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_US_SUPPLY_DESTROYED", defUnitName);
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY);
				Message = 0		
			end										
		end	 
    end
           







end--Function END
GameEvents.CombatResult.Add(NewAttackEffectMelee);--Event Trigger
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

-------------------------New Attack Effects for Ranged Attacks (Event.CombatEnded)---Not working for Melee attacks!!!!--------------------------------


function NewAttackEffectRanged(iAttackingPlayer, iAttackingUnit, attackerDamage, attackerFinalDamage, attackerMaxHP, iDefendingPlayer, iDefendingUnit, defenderDamage, defenderFinalDamage, defenderMaxHP, iInterceptingPlayer, iInterceptingUnit, interceptorDamage, plotX, plotY)



----------Defines and status checks


	local pAttackingPlayer = Players[ iAttackingPlayer]	
	if not pAttackingPlayer then
		return
	end
	
	local pDefendingPlayer = Players[iDefendingPlayer]	
	if not pDefendingPlayer then
		return
	end
	
		--Only for Human VS AI(reduce time and enhance stability, however when these functions get mature, they may be available for AI)
	if not pDefendingPlayer:IsHuman() and not pAttackingPlayer:IsHuman() then 
		return
	end	
	
	
	---Attacking Unit
	local pAttackingUnit = pAttackingPlayer:GetUnitByID(iAttackingUnit)	
	
	local pAttackingPlot = pAttackingUnit:GetPlot()	
			
	if not pAttackingUnit or not pAttackingPlot then 
	   return
	end
	
	if attackerMaxHP - attackerFinalDamage <= 0 then	--If the attacker died, no effect
		print ("Attacker died!")
		return
	end
	
	
	---Defending Unit
	local pDefendingUnit = pDefendingPlayer:GetUnitByID(iDefendingUnit)	
	
	local pDefendedPlot = Map.GetPlot(plotX, plotY)
	
	
	if not pDefendingUnit then
	   print ("Attacking a City! NewAttackEffects is not designed for this!") 
	   return
	end
	


------Map XY Grids
	local attX = pAttackingUnit:GetX()
	local attY = pAttackingUnit:GetY()
	local defX = pDefendingUnit:GetX()
	local defY = pDefendingUnit:GetY()



------Units Strength

	local attUnitStrength = pAttackingUnit:GetBaseCombatStrength()
	local defUnitStrength = pDefendingUnit:GetBaseCombatStrength()



-------	PromotionID 
	local LogisticsID = GameInfo.UnitPromotions["PROMOTION_LOGISTICS"].ID

	local SplashDamageID = GameInfo.UnitPromotions["PROMOTION_SPLASH_DAMAGE"].ID
	local NavalCapitalShipID = GameInfo.UnitPromotions["PROMOTION_NAVAL_CAPITAL_SHIP"].ID
		
	local ClusterRocket1ID = GameInfo.UnitPromotions["PROMOTION_CLUSTER_ROCKET_1"].ID
	local ClusterRocket2ID = GameInfo.UnitPromotions["PROMOTION_CLUSTER_ROCKET_2"].ID
	
	local CitySiegeID = GameInfo.UnitPromotions["PROMOTION_CITY_SIEGE"].ID
	local NavalCollDmgID = GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_SHIP"].ID
	local CollDamageLV1ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_1"].ID
	local CollDamageLV2ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_2"].ID
	local CollDamageLV3ID = GameInfo.UnitPromotions["PROMOTION_COLLATERAL_DAMAGE_3"].ID
	
	local DestroySupply2ID = GameInfo.UnitPromotions["PROMOTION_DESTROY_SUPPLY_2"].ID
	local LoseSupplyID = GameInfo.UnitPromotions["PROMOTION_LOSE_SUPPLY"].ID	
		
	local EMPBomberID = GameInfo.UnitPromotions["PROMOTION_EMP_ATTACK"].ID	
		
	
	local FireSupport1ID = GameInfo.UnitPromotions["PROMOTION_FIRESUPPORT_UNIT_1"].ID	
	local FireSupport2ID = GameInfo.UnitPromotions["PROMOTION_FIRESUPPORT_UNIT_2"].ID	
	
	local CitadelUnitID = GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID	
	
	local MoveAfterID = GameInfo.UnitPromotions["PROMOTION_CAN_MOVE_AFTER_ATTACKING"].ID
	
		
	local NuclearArtilleryID = GameInfo.UnitPromotions["PROMOTION_NUCLEAR_ARTILLERY"].ID		
	local ChainReactionID = GameInfo.UnitPromotions["PROMOTION_CHAIN_REACTION"].ID	
		
-----------Ranged Unit Logistics Use up all MPs

	if pAttackingUnit:IsHasPromotion(LogisticsID) then 
		local MovesLeft = pAttackingUnit:GetMoves() 
		print ("Logistics Ranged Unit MPs left:"..MovesLeft)
		if pAttackingUnit:IsHasPromotion(MoveAfterID)then
			print ("Special Ranged Unit free from MP Penalty!")
			return
		end
		
		if MovesLeft > 1 then
		   pAttackingUnit:SetMoves(1)
		end
	end
	
	
	
	
	
	
	
-----------Effects for attacking units
	if pDefendingUnit then
	print ("attacking a Unit!")
	
	

	
	
	
	
	 --------Splash Damage (AOE) 
	
	if pAttackingUnit:IsHasPromotion(SplashDamageID) or pAttackingUnit:IsHasPromotion(NavalCapitalShipID) then  
	
		for i = 0, 5 do
			local adjPlot = Map.PlotDirection(defX, defY, i)
			if (adjPlot ~= nil) then
				print("Available for AOE Damage!")

				local pUnit = adjPlot:GetUnit(0) ------------Find Units affected
					if (pUnit ~= nil) then				
						local pCombat = pUnit:GetBaseCombatStrength()
					    local pPlayer = Players[pUnit:GetOwner()]
				    
				    if PlayersAtWar(pAttackingPlayer,pPlayer) then
				   	   local SplashDamageOri = pAttackingUnit:GetRangeCombatDamage(pUnit,nil,false)
				   	   
				   	   
				   	   local AOEmod = 0.5   -- the percent of damage reducing to nearby units
				   	   
				   	   
				   	   if pAttackingUnit:IsHasPromotion(ClusterRocket1ID) then
				   	      AOEmod = 0.75				   	   
				   
				   	   	  if pAttackingUnit:IsHasPromotion(ClusterRocket2ID) then				   	   	  
				   	     	 AOEmod = 1  				   	    
				   	      end
				   	      print ("AOEmod:"..AOEmod)				   	      
				   	   end
				   	   
				   	   
				       local SplashDamageFinal = SplashDamageOri * AOEmod ------------Set the Final Damage
				       
				       if SplashDamageFinal > 100 then   ---------------Data overflow may cause Crashing?
				      	  SplashDamageFinal = 100
				       end
				       
				       if pUnit:GetDomainType() == DomainTypes.DOMAIN_LAND or pUnit:GetDomainType() == DomainTypes.DOMAIN_SEA then
				      	  pUnit:ChangeDamage(SplashDamageFinal,pAttackingPlayer)
				     	  print("Splash Damage="..SplashDamageFinal)
					   end

						-- Notification											
						if pDefendingPlayer:IsHuman() and SplashDamageFinal >= 100 then
							local pUnitName = pUnit:GetName()
							local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_DESTROYED_SHORT")
							local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_SPLASH_DAMAGE_DEATH", pUnitName)
							pDefendingPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY)					
						end
				   end
				end
			end
		end	
	end
	
	

 	-------- Collateral Damage

 	if pAttackingUnit:IsHasPromotion(CitySiegeID) or pAttackingUnit:IsHasPromotion(NavalCollDmgID) then     
			local pPlot = Map.GetPlot(defX, defY)
			if (pPlot ~= nil) then
--				print("Available for Collateral Damage!")
				local unitCount = pPlot:GetNumUnits()	
						
				if (pDefendingUnit ~= nil) then				 
					for i = 0, unitCount-1, 1 do		  --------------Get the number of units in the same plot
						local pFoundUnit = pPlot:GetUnit(i)	
						if (pFoundUnit ~= nil) and (pFoundUnit:GetID() ~= pDefendingUnit:GetID()) then
							local pCombat = pFoundUnit:GetBaseCombatStrength()
							local pPlayer = Players[pFoundUnit:GetOwner()]
							if PlayersAtWar(pAttackingPlayer,pPlayer) then
						   	   local CollDamageOri = pAttackingUnit:GetRangeCombatDamage(pFoundUnit,nil,false)
						   	   
						   	   local CollDmgMod = 0.5
						   	   
						   	   if pAttackingUnit:IsHasPromotion(CollDamageLV1ID) then
				   	 			  CollDmgMod = 0.83				   	   
				   	            
				   	   	          if pAttackingUnit:IsHasPromotion(CollDamageLV2ID) then				   	   	  
				   	     	      	  CollDmgMod = 0.99 
				   	     	      	  				   	    	 
					   	    	      if pAttackingUnit:IsHasPromotion(CollDamageLV3ID) then				   	   	  
					   	     	     	 CollDmgMod = 1.34  					   	    	 
					   	              end
					   	              		
				   	              end
				   	              print ("CollDmgMod:"..CollDmgMod)					   	      
				   	          end
						   	   
						      local CollDamageFinal = CollDamageOri * CollDmgMod 
						       
						       
						       if CollDamageFinal > 100 then   ---------------Data overflow may cause Crashing?
				      	          CollDamageFinal = 100
				               end
						       
						       if pFoundUnit:GetDomainType() == DomainTypes.DOMAIN_AIR then
				      			  return
				      	       else			
						     	  pFoundUnit:ChangeDamage(CollDamageFinal,pAttackingPlayer)
						     	  print("Collateral Damage="..CollDamageFinal)
						       end
						       
							-- Notification											
								if pDefendingPlayer:IsHuman() and CollDamageFinal >= 100 then
									local pUnitName = pFoundUnit:GetName()
									local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_DESTROYED_SHORT")
									local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_COLL_DAMAGE_DEATH", pUnitName)
									pDefendingPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, defX, defY)					
								end
							end
						end	
				  	 end				
				  end	
		       end	
	        end	
	        
	        
	        
	-------------------------Both Collateral Damage and AOE
	
	if pAttackingUnit:IsHasPromotion(NuclearArtilleryID) then
					
		local defX = pDefendingUnit:GetX()
		local defY = pDefendingUnit:GetY()
		local pPlot = Map.GetPlot(defX, defY)
		local unitCount = pPlot:GetNumUnits()
				
		for i = 0, unitCount-1, 1 do
			local pFoundUnit = pPlot:GetUnit(i)	
			if (pFoundUnit ~= nil) and (pFoundUnit:GetID() ~= pDefendingUnit:GetID()) then	
				pFoundUnit:ChangeDamage(pAttackingUnit:GetRangeCombatDamage(pFoundUnit,nil,false),pAttackingPlayer)
				print ("Nuclear Artillery!")
			end
		end			
					
		for i = 0, 5 do
			local adjPlot = Map.PlotDirection(defX, defY, i)
			if (adjPlot ~= nil) then
				
				local pUnit = adjPlot:GetUnit(0)
				local unitCountAdj = adjPlot:GetNumUnits()	
				if (pUnit ~= nil) then
					pUnit:ChangeDamage(pAttackingUnit:GetRangeCombatDamage(pUnit,nil,false),pAttackingPlayer)
					print ("Nuclear Artillery!")
					for i = 0, unitCount-1, 1 do
						local pFoundUnit = adjPlot:GetUnit(i)					
						if (pFoundUnit ~= nil) and (pFoundUnit:GetID() ~= pDefendingUnit:GetID()) then	
							pFoundUnit:ChangeDamage(pAttackingUnit:GetRangeCombatDamage(pFoundUnit,nil,false),pAttackingPlayer)
							print ("Nuclear Artillery!")	
						end
					end
				end    
			end		    
		end
	end		
	        
	        
	 -------------------------Chain Reaction 
	 if pAttackingUnit:IsHasPromotion(ChainReactionID) then	

	 	for unit in pDefendingPlayer:Units() do
			if unit ~= nil then
				local plot = unit:GetPlot()
				if unit:IsCombatUnit() and unit:GetID()~= pDefendingUnit:GetID() and PlotIsVisibleToHuman(plot) then
					local DamageOri = pAttackingUnit:GetRangeCombatDamage(unit,nil,false)
	 				local ChainDamage = 0.33 * DamageOri
					unit:ChangeDamage(ChainDamage,pAttackingPlayer)
					print ("Chain Reaction!")
				end
	    	end
	    end
	 end      
	        
	 --------------------------- Supply Damage AOE Effects  
	if pAttackingUnit:IsHasPromotion(DestroySupply2ID) then	
	
		pDefendingUnit:SetHasPromotion(LoseSupplyID, true)  
		
		local defX = pDefendingUnit:GetX()
		local defY = pDefendingUnit:GetY()			
		for i = 0, 5 do
			local adjPlot = Map.PlotDirection(defX, defY, i)
			if (adjPlot ~= nil) then
				local pUnit = adjPlot:GetUnit(0)
				if (pUnit ~= nil) then				
					pUnit:SetHasPromotion(LoseSupplyID, true)  
				end    
			end		    
		end
	end		      
	      
	        
	 --------------------------- EMP Bomb Effects
	 if pAttackingUnit:IsHasPromotion(EMPBomberID) then
		local pTeam = Teams[pDefendingPlayer:GetTeam()]
		if not pTeam:IsHasTech(GameInfoTypes["TECH_COMPUTERS"]) then	
			print("No Tech!")
			return
		end
		
		pDefendingUnit:SetMoves(0)
		
		-- Notification											
		if pDefendingPlayer:IsHuman() then
			local pUnitName = pDefendingUnit:GetName()
			local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_US_EMP_SHORT")
			local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_US_EMP", pUnitName)
			pDefendingPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, pDefendingUnit:GetX(), pDefendingUnit:GetY())	
		elseif pAttackingPlayer:IsHuman() then
			local pUnitName = pDefendingUnit:GetName()
			local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_ENEMY_EMP_SHORT")
			local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_ENEMY_EMP", pUnitName)
			pAttackingPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, pDefendingUnit:GetX(), pDefendingUnit:GetY())						
		end
							
		local defX = pDefendingUnit:GetX()
		local defY = pDefendingUnit:GetY()
		local pPlot = Map.GetPlot(defX, defY)
		local unitCount = pPlot:GetNumUnits()
		for i = 0, unitCount-1, 1 do
			local pFoundUnit = pPlot:GetUnit(i)	
			if (pFoundUnit ~= nil) and (pFoundUnit:GetID() ~= pDefendingUnit:GetID()) then	
				pFoundUnit:SetMoves(0)	
				print ("EMP same tile!")			
			end
		end			
					
		for i = 0, 5 do
			local adjPlot = Map.PlotDirection(defX, defY, i)
			if (adjPlot ~= nil) then
				
				local pUnit = adjPlot:GetUnit(0)
				local unitCountAdj = adjPlot:GetNumUnits()	
				if (pUnit ~= nil) then
					pUnit:SetMoves(0)
					print ("EMP!")
				
					for i = 0, unitCount-1, 1 do
						local pFoundUnit = adjPlot:GetUnit(i)					
						if (pFoundUnit ~= nil) and (pFoundUnit:GetID() ~= pDefendingUnit:GetID()) then	
							pFoundUnit:SetMoves(0)	
							print ("EMP around!")					
						end
					end
				end    
			end		    
		end
	end		
	        
	        
	----------------------Ranged Unit Counter Attack     
	        
--	if not pAttackingUnit:IsDead() and not pDefendingUnit:IsDead() then    	----------------------Ranged Unit Counter Attack		
--		if (pAttackingUnit:IsRanged() and pDefendingUnit:IsRanged() and not pAttackingPlot:IsCity()) then	
--			if pAttackingUnit:GetBaseRangedCombatStrength() > pAttackingUnit:GetBaseCombatStrength() and pDefendingUnit:GetBaseRangedCombatStrength() > pDefendingUnit:GetBaseCombatStrength()	then --Hit and Run units won't have this effect				
--				-- Initialize the attack-tracking if this is the first attack of the turn.
--				   HasAttackedThisTurn = {}
--				if HasAttackedThisTurn[pDefendingUnit] ~= true and HasAttackedThisTurn[pAttackingUnit] ~= true then
--				   HasAttackedThisTurn[pAttackingUnit] = true
--				end
--				
--				if HasAttackedThisTurn[pDefendingUnit] ~= true then
--					local movesLeft = pDefendingUnit:MovesLeft()
--					print("Qualifies for a counterattack.")
--					pDefendingUnit:RangeStrike( pAttackingUnit:GetX(), pAttackingUnit:GetY() )
--					--The defender can defend itself for more than its attacks allowed every turn.
--					pDefendingUnit:SetMadeAttack(false)
--					pDefendingUnit:SetMoves(movesLeft)
--					-- By this point, the attacker will already have been checked to make a counter-counter attack, so let's delete our table. 
--					HasAttackedThisTurn = nil				
--				else				
--					return
--				end	
--			end				
--		end
--	end	
	        
	        
	        
	        
	 	
	
	-----------Archery Unit Counter-attack the attacker attacking the Stacking units
	
	if pDefendingUnit:IsHasPromotion(CitadelUnitID) or pDefendingUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_MELEE then
		local pPlot = Map.GetPlot(defX, defY)
		if defenderFinalDamage >= 100 then
			print ("Defender died!")
			return
		end
		
		if (pPlot ~= nil) then
			local unitCount = pPlot:GetNumUnits()	
			
			if (pDefendingUnit ~= nil) then				 
				for i = 0, unitCount-1, 1 do		  --------------Get the number of units in the same plot
					local pFoundUnit = pPlot:GetUnit(i)
					
					if pFoundUnit:GetDamage() >= 100 then
						print ("The Fire Support Unit died!")
						return
					end
		
--					if pFoundUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_SIEGE then
					if pFoundUnit:IsRanged() and pFoundUnit:IsHasPromotion(FireSupport1ID) then
						print ("Fire support Unit Counter-attack!")
						if pAttackingUnit:IsRanged() and not pFoundUnit:IsHasPromotion(FireSupport2ID) then							
							print ("Fire support Unit Counter-attack Not available!")
							return							
						else
							pFoundUnit:RangeStrike( pAttackingUnit:GetX(), pAttackingUnit:GetY() )
						end
						local movesLeft = pFoundUnit:MaxMoves()
						pFoundUnit:SetMadeAttack(false)
						pFoundUnit:SetMoves(movesLeft)
					end
				end
			end
		end	
	end
	       
	        
	        
	        
	end ------END for Attacking Units Effects
	
	
	
	
	
	









end  --Function END	
GameEvents.CombatEnded.Add(NewAttackEffectRanged)



--function UnitMPChangeCapturing(oldPlayerID, iCapital, iX, iY, newPlayerID, bConquest, iGreatWorksPresent, iGreatWorksXferred)--------Unit Movements Change after Capturing a City 
--
--
--
--	local InfantryID = GameInfo.UnitPromotions["PROMOTION_INFANTRY_COMBAT"].ID
--	local GunInfantryID = GameInfo.UnitPromotions["PROMOTION_GUNPOWDER_INFANTRY_COMBAT"].ID
--	local pPlot = Map.GetPlot(iX, iY)
--	local unitCount = pPlot:GetNumUnits()
--	
--	for i = 0, unitCount-1, 1 do
--		local pFoundUnit = pPlot:GetUnit(i)	
--		if (pFoundUnit ~= nil) then
--			if pFoundUnit:IsHasPromotion(InfantryID, true) or pFoundUnit:IsHasPromotion(GunInfantryID, true) then		
--	   		pFoundUnit:SetMoves(100)	
--			print ("Infantry Unit Add MP!")	
--			end		
--		end
--	end	
--end
--
--GameEvents.CityCaptureComplete.Add(UnitMPChangeCapturing)
--
--




--****************************************************************************Utilities*************************************************************************************************


---- Set Debuff Effects: Armor Damaged
function SetPenetration(defUnit) 
	local Penetration1ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_1"].ID
	local Penetration2ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_2"].ID

   	if (defUnit:IsHasPromotion(Penetration1ID, true) ) then
   		defUnit:SetHasPromotion(Penetration2ID, true)   					  
    else
   		defUnit:SetHasPromotion(Penetration1ID, true)   		
   		return	
   	end 
end


---- Set Debuff Effects: Slow Down
function SetSlowDown(defUnit) 
	local SlowDown1ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID
	local SlowDown2ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_2"].ID

   	if (defUnit:IsHasPromotion(SlowDown1ID, true) ) then
   		defUnit:SetHasPromotion(SlowDown2ID, true)	   				  
    else
   		defUnit:SetHasPromotion(SlowDown1ID, true)   	
   		return	
   	end 
end


---- Set Debuff Effects: Moral Weaken
function SetMoralWeaken(defUnit) 
	local MoralWeaken1ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_1"].ID
	local MoralWeaken2ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_2"].ID

   	if (defUnit:IsHasPromotion(MoralWeaken1ID, true) ) then
   		defUnit:SetHasPromotion(MoralWeaken2ID, true)			  
    else
   		defUnit:SetHasPromotion(MoralWeaken1ID, true)
   		return	
   	end 
end


---- Set Debuff Effects: Destroy Supply
function SetLoseSupply(defUnit) 
	local LoseSupply1ID = GameInfo.UnitPromotions["PROMOTION_LOSE_SUPPLY"].ID	

   	if (defUnit:IsHasPromotion(LoseSupply1ID, false)) then
   		defUnit:SetHasPromotion(LoseSupply1ID, true)  
   	else
   		return	 		
   	end 
end




--





print("New Attack Effect Check Pass!")

