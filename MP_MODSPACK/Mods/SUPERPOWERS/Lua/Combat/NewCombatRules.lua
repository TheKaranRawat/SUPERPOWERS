-- New Combat Rules


include( "UtilityFunctions.lua" )

--*******************************************************************************Ranged Unit Combat Rules*******************************************************************************



function RangedUnitRules(iAttackingPlayer, iAttackingUnit, attackerDamage, attackerFinalDamage, attackerMaxHP, iDefendingPlayer, iDefendingUnit, defenderDamage, defenderFinalDamage, defenderMaxHP, iInterceptingPlayer, iInterceptingUnit, interceptorDamage, plotX, plotY)

	local pAttackingPlayer = Players[ iAttackingPlayer ]
	if not pAttackingPlayer then
		return
	end
	
	local pAttackingUnit = pAttackingPlayer:GetUnitByID(iAttackingUnit)
	
	if not pAttackingUnit then 
	   return
	end
	
	if pAttackingUnit:IsDead() then	--If the attacker died, no effect
		print ("Attacker died!")
		return
	end
		
	local pAttackingPlot = pAttackingUnit:GetPlot()	
	local pDefendingPlayer = Players[iDefendingPlayer]
	
	if not pDefendingPlayer then
		return
	end
	
	local pDefendingUnit = pDefendingPlayer:GetUnitByID(iDefendingUnit)	
	local pDefendedPlot = Map.GetPlot(plotX, plotY)
	



-----Larger AI's Bonus against Smaller AIs - AI is easier to become a Boss! Player will feel excited fighting Boss!
	--AI will capture another AI's city by ranged attack
	if not pDefendingPlayer:IsHuman() and not pAttackingPlayer:IsHuman() then 
	
		if not pAttackingUnit then 
		   return
		end
	
		if not pDefendingUnit then 
		   return
		end
	
		if AICanBeBoss(pDefendingPlayer) then
			print("AI Ranged Unit Capturing City Not for AI boss!")
			return
		end
		
		if not pDefendingUnit then			
			if pAttackingUnit:IsRanged() and pDefendedPlot:IsCity()then			
				print ("AI attacking AI's City!")
				local pDefendingCity = pDefendedPlot:GetPlotCity()
				
				if pDefendingCity == nil then
					return
				end
				
				
				if pDefendingCity:GetDamage() >= 80 and defenderFinalDamage < pDefendingCity:GetMaxHitPoints() then
					local cityPop = pDefendingCity:GetPopulation() 		
					if cityPop < 15 then
						local TempUnit = pAttackingPlayer:InitUnit(GameInfoTypes.UNIT_ROMAN_LEGION, plotX, plotY, UNITAI_ATTACK)
						TempUnit:Kill()
--		   				pAttackingUnit:SetXY(plotX, plotY)		
		  	 			print ("AI Ranged Units Takes another AI's city!")
					end
				end
			end
		end
		return
	end	





	
--Complex Effects Only for Human VS AI(reduce time and enhance stability)
--	if not pDefendingPlayer:IsHuman() and not pAttackingPlayer:IsHuman() then 
--		print ("Only Effective bewteen AI and Humans!")
--		return
--	end	
	
	if pAttackingPlayer:IsBarbarian() then ---Not for Barbarins
		return
	end
			



			
	local StgBomberID = GameInfo.UnitPromotions["PROMOTION_STRATEGIC_BOMBER"].ID
		
	local EMPBomberID = GameInfo.UnitPromotions["PROMOTION_EMP_ATTACK"].ID	
		
	local NapalmBomb1ID = GameInfo.UnitPromotions["PROMOTION_NAPALMBOMB_1"].ID
	local NapalmBomb2ID = GameInfo.UnitPromotions["PROMOTION_NAPALMBOMB_2"].ID
	local NapalmBomb3ID = GameInfo.UnitPromotions["PROMOTION_NAPALMBOMB_3"].ID
	local AirSiege1ID = GameInfo.UnitPromotions["PROMOTION_AIR_SIEGE_1"].ID
	local AirSiege2ID = GameInfo.UnitPromotions["PROMOTION_AIR_SIEGE_2"].ID
	local AirSiege3ID = GameInfo.UnitPromotions["PROMOTION_AIR_SIEGE_3"].ID		
	local BombShelterID = GameInfo.Buildings["BUILDING_BOMB_SHELTER"].ID
	
	local AttackAirCraftID = GameInfo.UnitPromotions["PROMOTION_AIR_ATTACK"].ID
	local AirTarget1ID = GameInfo.UnitPromotions["PROMOTION_AIR_TARGETING_1"].ID
	local AirTarget2ID = GameInfo.UnitPromotions["PROMOTION_AIR_TARGETING_2"].ID
	local AirTarget3ID = GameInfo.UnitPromotions["PROMOTION_AIR_TARGETING_3"].ID	
	
	
	local CarrierFighterID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER"].ID
	local AirTarget_CarrierID = GameInfo.UnitPromotions["PROMOTION_CARRIER_FIGHTER_SIEGE_2"].ID

	local SPForce2ID = GameInfo.UnitPromotions["PROMOTION_SP_FORCE_2"].ID
	
	local KnightID = GameInfo.UnitPromotions["PROMOTION_KNIGHT_COMBAT"].ID
	local TankID = GameInfo.UnitPromotions["PROMOTION_TANK_COMBAT"].ID
	
		
	local AntiAirID = GameInfo.UnitPromotions["PROMOTION_ANTI_AIR"].ID	
	local DestroyerID = GameInfo.UnitPromotions["PROMOTION_DESTROYER_COMBAT"].ID	
	local CruiserID = GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_CRUISER"].ID	
	
	local NuclearArtilleryID = GameInfo.UnitPromotions["PROMOTION_NUCLEAR_ARTILLERY"].ID	
	
	
if not pDefendingUnit then --------------If attacking Cities
	print ("attacking city!")
	if pAttackingUnit:IsHasPromotion(StgBomberID) then 	----------------Strategic Bomber damage City 
				
		local pDefendingCity	
		
		if pDefendedPlot then 
			pDefendingCity = pDefendedPlot:GetPlotCity()
--			print ("City in Defending Plot!")
			local cityPop = pDefendingCity:GetPopulation() 			
			-- *************************Popluation Loss************************************
			if ( cityPop > 1 ) then 
				if pAttackingUnit:IsHasPromotion(NapalmBomb1ID) then     --Strategic Bomber attacking City killing popluation Lv1	
					if pDefendingCity:IsHasBuilding(BombShelterID) then
					pDefendingCity:ChangePopulation( -math.floor(cityPop * 0.05 ), true )
--					print("Has shelter!Lose less popluation!");
					else 
					pDefendingCity:ChangePopulation( -math.floor(cityPop * 0.2 ), true )
--					print("No shelter!Lose more popluation!");
					end					
				end
				if pAttackingUnit:IsHasPromotion(NapalmBomb2ID) then     --Strategic Bomber attacking City killing popluation Lv2	
					if pDefendingCity:IsHasBuilding(BombShelterID) then
					pDefendingCity:ChangePopulation( -math.floor(cityPop * 0.05 ), true )

					else 
					pDefendingCity:ChangePopulation( -math.floor(cityPop * 0.2 ), true )

					end					
				end
				if pAttackingUnit:IsHasPromotion(NapalmBomb3ID) or pAttackingUnit:IsHasPromotion(NuclearArtilleryID) then     --Strategic Bomber attacking City killing popluation Lv3	
					if pDefendingCity:IsHasBuilding(BombShelterID) then
					pDefendingCity:ChangePopulation( -math.floor(cityPop * 0.05 ), true )

					else 
					pDefendingCity:ChangePopulation( -math.floor(cityPop * 0.2 ), true )

					end					
				end
			end
				-- *************************Destroy Building************************************
			if pAttackingUnit:IsHasPromotion(AirSiege1ID) then
				local iCounterLv1 = 0
				if iCounterLv1 < 1 then 				
					if pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_MILITARY_BASE"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_MILITARY_BASE"],0);
					iCounterLv1=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_SHIPYARD"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SHIPYARD"],0); 
					iCounterLv1=2
									
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_ARSENAL"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ARSENAL"],0); 
					iCounterLv1=2			
					
--					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_ARMORY"].ID) then
--					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ARMORY"],0); 
--					iCounterLv1=2
	
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_BARRACKS"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_BARRACKS"],0);	
					iCounterLv1=2						
	
					end
				end			
			end	
			
			if pAttackingUnit:IsHasPromotion(AirSiege2ID) then
				local iCounterLv2 = 0
				if iCounterLv2 < 1 then 
					if pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_FUSION_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_FUSION_PLANT"],0);
					iCounterLv2=2
								
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_NUCLEAR_PLANT_EXTEND"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_NUCLEAR_PLANT_EXTEND"],0);
					iCounterLv2=2	
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_NUCLEAR_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_NUCLEAR_PLANT"],0); 
					iCounterLv2=2
	
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_COAL_PLANT_EXTEND"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_COAL_PLANT_EXTEND"],0);
					iCounterLv2=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_COAL_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_COAL_PLANT"],0);
					iCounterLv2=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_WIND_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_TIDAL_PLANT"],0);	
					iCounterLv2=2	
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_HYDRO_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_HYDRO_PLANT"],0);
					iCounterLv2=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_OIL_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_OIL_PLANT"],0);
					iCounterLv2=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_GAS_PLANT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_GAS_PLANT"],0);
					iCounterLv2=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_TIDAL_PLANTT"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_TIDAL_PLANT"],0);	
					iCounterLv2=2
					
	
					
					end
				end			
			end	
			if pAttackingUnit:IsHasPromotion(AirSiege3ID) then
				local iCounterLv3 = 0
				if iCounterLv3 < 1 then 					
					if pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_SPACESHIP_FACTORY"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SPACESHIP_FACTORY"],0);
					iCounterLv3=2	
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_FUTURE_FACTORY"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_FACTORY"],0);
					iCounterLv2=2						
														
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_FACTORY"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_FACTORY"],0);
					iCounterLv2=2
									
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_STEEL_MILL"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_STEEL_MILL"],0);
					iCounterLv2=2				
									
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_OIL_REFINERY"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_OIL_REFINERY"],0);					
					iCounterLv2=2
										
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_FORGE"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_FORGE"],0);
					iCounterLv2=2
					
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_MINGING_FACTORY"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_MINGING_FACTORY"],0);
					iCounterLv2=2
				
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_INLAND_CANAL"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_INLAND_CANAL"],0);
					iCounterLv2=2
				
					elseif pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_METAL_FACTORY"].ID) then
					pDefendingCity:SetNumRealBuilding(GameInfoTypes["BUILDING_METAL_FACTORY"],0);
					iCounterLv2=2
					
					
				
					end
				end			
			end					
		end				
	end		
end


	if pAttackingUnit:IsHasPromotion(AirTarget1ID) or pAttackingUnit:IsHasPromotion(AirTarget_CarrierID) then ------------------------Attack Aircraft attack units inside the city
		if pDefendedPlot then
			 if pDefendedPlot:IsCity() then			 				
				pDefendingCity = pDefendedPlot:GetPlotCity()
				print("Attak AirCraft attacking City!")
				local unitCount = pDefendedPlot:GetNumUnits()	
				if unitCount > 0 then 
					print ("Units in the city!")
					for i = 0, unitCount-1, 1 do
						local pFoundUnit = pDefendedPlot:GetUnit(i)	
						if (pFoundUnit ~= nil) then
							pFoundUnit:ChangeDamage(20)
							print ("Units in the city are attacked!")
							if pAttackingUnit:IsHasPromotion(AirTarget2ID) then 
								pFoundUnit:ChangeDamage(10)
							end	
							if pAttackingUnit:IsHasPromotion(AirTarget3ID) then 
								pFoundUnit:ChangeDamage(10)						
							end
						end
					end
				end
			end
		end		
	end





	if pAttackingUnit:IsHasPromotion(EMPBomberID) then 	----------------EMP Bomber effects
		local pTeam = Teams[pDefendingPlayer:GetTeam()]
		if not pTeam:IsHasTech(GameInfoTypes["TECH_COMPUTERS"]) then	
			print("No Tech!")
			return
		end
		
		if pDefendedPlot then	
		 	if pDefendedPlot:IsCity() then			
				pDefendingCity = pDefendedPlot:GetPlotCity()
				pDefendingCity:ChangeResistanceTurns(1)
				print("EMP City!")
			end
		end
	end
	
	
	if pAttackingUnit:IsHasPromotion(SPForce2ID) then  ----------------Special Forces sabotage city 
		if pDefendedPlot:IsCity() then
			local pDefendingCity = pDefendedPlot:GetPlotCity()
			pDefendingCity:ChangeResistanceTurns(1)
		
			if pDefendingCity:GetGarrisonedUnit() == nil  then
				local CityMaxHP = pDefendingCity:GetMaxHitPoints()
				if CityMaxHP >= 250 then						
					pDefendingCity:SetDamage (250)
				else
					pDefendingCity:SetDamage (CityMaxHP)			
				end
			end	
			print ("City Sabotaged")	
		end	
	end
	
	
	if pAttackingUnit:IsHasPromotion(KnightID) or pAttackingUnit:IsHasPromotion(TankID) then  ----------------Heavy Knight&Tank attacking cities lose all MPs
		if pDefendedPlot:IsCity() then
		   if not pAttackingUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITY_PILLAGE_FREE"].ID) then
		   	  pAttackingUnit:SetMoves(0)		
		   end
		   print ("Attacking City and lost all MPs!")	
		end	
	end
	
	
	
	if pAttackingUnit:IsHasPromotion(CarrierFighterID) then ----------------Carrier-based aircrafts give EXP to carrier
		print ("Found a carrier-based aircraft!")
		local AircraftEXP = pAttackingUnit:GetExperience()
		print ("Gained EXP:"..AircraftEXP)
		if AircraftEXP > 0 and pAttackingUnit:GetTransportUnit()~= nil then
			local CarrierUnit = pAttackingUnit:GetTransportUnit() 
			print("Found its carrier!")
			CarrierUnit:ChangeExperience(AircraftEXP)
			pAttackingUnit:SetExperience(0)
		end
	end

	if pAttackingUnit:GetUnitType() == GameInfoTypes.UNIT_BAZOOKA then  ----------------Nuclear Rocket Launcher Kills itself (<suicide>is not working!)
	   pAttackingUnit:ChangeDamage(100)	   
	end
	
	
	if pAttackingUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_FIGHTER or pAttackingUnit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MIRRAGE2000 then  ----------------Fighters will damage land and naval AA units in an air-sweep
	   print ("Airsweep!")
	   
	   if pDefendingUnit == nil then
	   		return
	   end
	   
	   if pDefendingUnit:IsHasPromotion(AntiAirID) or pDefendingUnit:IsHasPromotion(DestroyerID) or pDefendingUnit:IsHasPromotion(CruiserID) then
--	   		local attUnitStrength = pAttackingUnit:GetBaseCombatStrength()
--	   		local defUnitStrength = pDefendingUnit:GetBaseCombatStrength()
	   
	 		print ("Airsweep and the defender is an AA unit!")

	   		local MyDamageInflicted = pAttackingUnit:GetRangeCombatDamage(pDefendingUnit,nil,false)
	   		local TheirDamageInflicted = pDefendingUnit:GetRangeCombatDamage(pDefendingUnit,nil,false)
	   		local TheirDamageFinal = TheirDamageInflicted * 0.5
	   		
	   		
	   		------------In case of the AA unit is a melee unit
	   		if not pDefendingUnit:IsRanged() then
	   			TheirDamageFinal = MyDamageInflicted * 0.25
	   		end
--			local TheirDamageInflicted = pAttackingUnit:GetCombatDamage(defUnitStrength, attUnitStrength, pDefendingUnit:GetDamage(),false,false, false)
			
			
			
			pDefendingUnit:ChangeDamage(MyDamageInflicted,pAttackingPlayer)
			pAttackingUnit:ChangeDamage(TheirDamageFinal,pDefendingPlayer)
			
			
			------------Notifications
			local text
			
	
			if pAttackingUnit:GetDamage() >= 100 then
				print ("Airsweep Unit died!")
				if pAttackingPlayer:IsHuman() then
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_BY_ENEMY", pAttackingUnit:GetName())
				elseif pDefendingPlayer:IsHuman() then
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_ENEMY_FIGHTER", pAttackingUnit:GetName())
				end
				return
			else
				pAttackingUnit:ChangeExperience(4)
				if pAttackingPlayer:IsHuman() then	
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_TO_ENEMY", tostring(MyDamageInflicted), pDefendingUnit:GetName())
				end
			end
			
			if pDefendingUnit:GetDamage() >= 100 then
				print ("AA Unit died!")
				
				if pAttackingPlayer:IsHuman() then
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_ENEMY_AA", pDefendingUnit:GetName())
				elseif pDefendingPlayer:IsHuman() then
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_AA_KILLED_BY_ENEMY", pDefendingUnit:GetName())
				end
				
				
				return
			else
				pDefendingUnit:ChangeExperience(2)	
				
				
				if pDefendingPlayer:IsHuman() then
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AIRSWEEP_BY_ENEMY", pDefendingUnit:GetName(), tostring(MyDamageInflicted))
				end
			end
			
			if pAttackingPlayer:IsHuman() or pDefendingPlayer:IsHuman() then
				Events.GameplayAlertMessage( text )
			end
			
			
			print ("Air Sweep Damage Dealt:"..MyDamageInflicted)
			print ("Air Sweep Damage Received:"..TheirDamageInflicted)
	   end	   
	end
	
	
	
	
	
	
	
	if pAttackingUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_RECON or pAttackingUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_GUN then -------Fix Stealth Unit cannot capture city Bug
		if pDefendedPlot:IsCity() then
			local pDefendingCity = pDefendedPlot:GetPlotCity()
			
			if pAttackingUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_GUN and pDefendingCity:GetDamage() >= pDefendingCity:GetMaxHitPoints() then
				local TempUnit = pAttackingPlayer:InitUnit(GameInfoTypes.UNIT_ROMAN_LEGION, plotX, plotY, UNITAI_ATTACK)
				TempUnit:Kill()
		   		pAttackingUnit:SetXY(plotX, plotY)		
--				pAttackingPlayer:AcquireCity(pDefendingCity) 
		  	 	print ("Special Forces Takes the city!")
			end
			
--			local resTime = pDefendingCity:GetResistanceTurns()
--			if pAttackingUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_RECON and resTime >= 1 then ----------------Militia can capture the resisting city in one hit
--
--				local TempUnit = pAttackingPlayer:InitUnit(GameInfoTypes.UNIT_ROMAN_LEGION, plotX, plotY, UNITAI_ATTACK)				
--				TempUnit:Kill()
--	   			pAttackingUnit:SetXY(plotX, plotY)		
--		  	 	print ("Militia Takes the city!")	
--		  	 
--		   end
		end	
	end



	if pAttackingUnit:IsRanged() and pAttackingUnit:GetUnitCombatType() ~= GameInfoTypes.UNITCOMBAT_FIGHTER then --------------Ranged Attack Kill Popluation of Heavily Damaged City 
		if pDefendedPlot:IsCity() then
--			print ("Ranged Unit attacked City!")
			local pDefendingCity = pDefendedPlot:GetPlotCity()								
			if  ( pDefendingCity:GetDamage() >= pDefendingCity:GetMaxHitPoints() - 1 and defenderFinalDamage < pDefendingCity:GetMaxHitPoints() ) then
				local cityPop = pDefendingCity:GetPopulation() 
				if ( cityPop > 1 ) then
					local NewCityPop = cityPop - 1
					pDefendingCity:SetPopulation(NewCityPop, true)----Set Real Population
					local CityOwner = pDefendingCity:GetOwner()
				
					
					 if Players[CityOwner]:IsHuman() then
					     local pPlayer = Players[CityOwner]
						 local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CITY_POPULATION_LOST_BY_RANGEDFIRE", pAttackingUnit:GetName(), pDefendingCity:GetName())
	     	 			 local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CITY_POPULATION_LOST_BY_RANGEDFIRE_SHORT")
	      				 pPlayer:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, plotX, plotY)
					 end
				
				
--				else	
----					if pDefendingCity:IsHasBuilding(GameInfo.Buildings["BUILDING_WALLS"].ID) then----------Destroy a city with only 1 pop and without wall (heavily damaged)
----						return
----					elseif pDefendingCity:IsOriginalCapital()then
----						return
----					else
----						pDefendingCity:Kill()
----						Events.SerialEventCityDestroyed(hexpos, playerID, cityID, -1)
----						Events.SerialEventGameDataDirty()
----						OnUpdate()
----					end	
--					local attX = pAttackingUnit:GetX()
--					local attY = pAttackingUnit:GetY()				
--					local Distance =  Map.PlotDistance (attX,attY,plotX,plotY )
--					if (Distance <= 1 )then
--						pAttackingUnit:SetXY(plotX, plotY)
--					end				
				end			
			end
		end
	end	
 		
		





end--function END
--
GameEvents.CombatEnded.Add(RangedUnitRules)





--
--



--*******************************************************************************Combat restrictions*******************************************************************************


--function UnitAbortAttack (
--		attPlayerID,
--		attUnitID,
--		attUnitDamage,
--		attFinalUnitDamage,
--		attMaxHitPoints,
--		defPlayerID,
--		defUnitID,
--		defUnitDamage,
--		defFinalUnitDamage,
--		defMaxHitPoints
--		)
--	local defPlayer	= Players[defPlayerID];
--	local defUnit	= defPlayer:GetUnitByID(defUnitID);
--    local attPlayer	= Players[attPlayerID];
--	local attUnit	= attPlayer:GetUnitByID(attUnitID);	
--	local attX = attUnit:GetX()
--	local attY = attUnit:GetY()
--	local defX = defUnit:GetX()
--	local defY = defUnit:GetY()
--	local attUnitStrength = attUnit:GetBaseCombatStrength();
--	local defUnitStrength = defUnit:GetBaseCombatStrength();
--	
--	local AirAttackID = GameInfo.UnitPromotions["PROMOTION_AIR_ATTACK"].ID
--		
--	if attUnit:IsHasPromotion(AirAttackID) then    
--		 
--	end
--		
--	return false
--end
--GameEvents.MustAbortAttack.Add( UnitAbortAttack )



--function CombatRules(
--		attPlayerID,
--		attUnitID,
--		attUnitDamage,
--		attFinalUnitDamage,
--		attMaxHitPoints,
--		defPlayerID,
--		defUnitID,
--		defUnitDamage,
--		defFinalUnitDamage,
--		defMaxHitPoints	
--		)
--	local attUnitType = attUnit:GetUnitType(); 	
--	local defUnitType = defUnit:GetUnitType(); 	
--	local attUnitCombatType = attUnit:GetUnitCombatType(); 	
--	local defUnitCombatType = defUnit:GetUnitCombatType(); 	
--	local defPlayer	= Players[defPlayerID];
--	local defUnit	= defPlayer:GetUnitByID(defUnitID);
--    local attPlayer	= Players[attPlayerID];
--	local attUnit	= attPlayer:GetUnitByID(attUnitID);	
--	local defX = defUnit:GetX();
--	local defY = defUnit:GetY();
--
----For Unit who can't range strike at cites
--if (attUnitType==GameInfoTypes.UNIT_MOBILE_SAM) then  
--	local pPlot = Map.GetPlot(defX, defY);	
--		if (defUnitCombatType ~= GameInfoTypes.UNITCOMBAT_HELICOPTER) then
--				
--		
--		end
--		
--
--	  
--	local unitCount = plot:GetNumUnits()
--	local bestDefender = nil
--	for i = 0, unitCount - 1, 1 do	
--    	local testUnit = plot:GetUnit(i)
--		if testUnit and testUnit:IsBetterDefenderThan(bestDefender, unit) then
--			bestDefender = testUnit
--		end
--	end
--	if bestDefender then
--		local defenderClassType = bestDefender:GetUnitClassType()
--		local defenderNumType = g_Unit_Classes[defenderClassType].NumType or -1
--		--Dprint("defendernumtype = " .. tostring(defenderNumType))
--		local classType = unit:GetUnitClassType()
--		local numType = g_Unit_Classes[classType].NumType or -1
--		--Dprint("attackernumtype = " .. tostring(numType))
--		-- to attack submarines we can't be land based or large bomber
--		-- to do : change that check to depth charge or torpedoes promotions
--		if IsSubmarineClass(defenderNumType) and (unitDomain == DomainTypes.DOMAIN_LAND or (unitDomain == DomainTypes.DOMAIN_AIR and not IsSmallBomberClass(numType))) then
--			return false
--		end
--	end
--
--	return true
--end
--end
--


--function CanRangeStrike(iPlayer, iUnit, x, y)
--	--Dprint("Can range strike at (" .. x .. "," .. y ..") ?")
--	local player = Players[iPlayer]
--	if not player then
--		return false
--	end
--	local unit = player:GetUnitByID(iUnit)
--	local plot = GetPlot(x,y)
--
--	if (not unit) or (not plot) then -- we may want to change that to allow range strike on improvement...
--		return false 
--	end
--
--	local unitDomain = unit:GetDomainType()
--	local unitPlot = unit:GetPlot()
--
--	if unitDomain == DomainTypes.DOMAIN_SEA and unitPlot:IsCity() then -- naval units can't fire from harbors
--		return false
--	end
--
--	if unitDomain == DomainTypes.DOMAIN_LAND and unit:Range() < 3 and (unitPlot:GetArea() ~= plot:GetArea() and not plot:IsWater()) then -- don't fire across sea channel unless we are really long range...
--		return false
--	end
--
--	local unitCount = plot:GetNumUnits()
--	local bestDefender = nil
--	for i = 0, unitCount - 1, 1 do	
--    	local testUnit = plot:GetUnit(i)
--		if testUnit and testUnit:IsBetterDefenderThan(bestDefender, unit) then
--			bestDefender = testUnit
--		end
--	end
--	if bestDefender then
--		local defenderClassType = bestDefender:GetUnitClassType()
--		local defenderNumType = g_Unit_Classes[defenderClassType].NumType or -1
--		--Dprint("defendernumtype = " .. tostring(defenderNumType))
--		local classType = unit:GetUnitClassType()
--		local numType = g_Unit_Classes[classType].NumType or -1
--		--Dprint("attackernumtype = " .. tostring(numType))
--		-- to attack submarines we can't be land based or large bomber
--		-- to do : change that check to depth charge or torpedoes promotions
--		if IsSubmarineClass(defenderNumType) and (unitDomain == DomainTypes.DOMAIN_LAND or (unitDomain == DomainTypes.DOMAIN_AIR and not IsSmallBomberClass(numType))) then
--			return false
--		end
--	end
--
--	return true
--end


print("New Combat Rules Check Pass!")