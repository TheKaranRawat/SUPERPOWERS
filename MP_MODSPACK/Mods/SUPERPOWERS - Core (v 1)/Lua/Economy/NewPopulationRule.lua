-- New Population Rule

--------------------------------------------------------------

--------------------------------------------------------------Still WIP! Some functions are still stupid and cumbersome! Sorry but I'm a newbee for programming!!!----------------------------------

include( "UtilityFunctions.lua" )



-----------------------------------------------------------------------Settlers & Population---------------------------------------
function SettlerTrainedCity(iPlayer, iCity, iUnit, bGold, bFaith)
   local pPlayer = Players[iPlayer]
   local pUnit = pPlayer:GetUnitByID(iUnit)
   local pCity = pPlayer:GetCityByID(iCity)
   local CityPop = pCity:GetPopulation()   
   local NewCityPop = CityPop
   
	if pPlayer:IsHuman() and pUnit ~= nil then
		if pUnit:GetUnitType()== GameInfoTypes.UNIT_SETTLER then			
--			pUnit:JumpToNearestValidPlot() ----Move Settler out of the city to avoid settler become population after built BUG
			if 	pPlayer:HasPolicy(GameInfo.Policies["POLICY_RESETTLEMENT"].ID) and CityPop >= 4 then
				NewCityPop = CityPop - 3
				pUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_SETTLER_POP_3"].ID, true)			
			else	
				NewCityPop = CityPop - 1
			end		
			
				pCity:SetPopulation(NewCityPop, true)----Set Real Population
			----Notifications
		    local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_SETTLER_TRAINED_CITY", pUnit:GetName(), pCity:GetName())
	        local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_SETTLER_TRAINED_CITY_SHORT", pUnit:GetName(), pCity:GetName())
	        pPlayer:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, pUnit:GetX(), pUnit:GetY())
	        
		end	
	end
end
GameEvents.CityTrained.Add(SettlerTrainedCity)









---------------------------------------------------------------------Unit death cause population loss---------------------------------------

--
g_UnitDeathSum = 0 ------------Counter for the total unit death 
--g_UnitDeathSumAI = 0

function UnitDeathCounterAI(attPlayerID,defPlayerID,defUnitTypeID)

	if attPlayerID == nil or defPlayerID == nil then
		return
	end



	local defPlayer	= Players[defPlayerID]
--	local defUnit	= defPlayer:GetUnitByID(defUnitID) 
	local PlayerCitiesCount = defPlayer:GetNumCities()
	local apCities = {}
	local iCounter = 0
	

	
	
	if defPlayer == nil then
		return
	end
	
 	
	if defPlayer:IsBarbarian() then --------- No Population Loss for Barbarian
	   return
    end  
    
    if defPlayer:IsHuman() then --------- For AI only
	   return
    end 
    
    if defPlayer:IsMinorCiv() then --------- No Population Loss for Minor Civs
	   return
    end 
	
	if PlayerCitiesCount < 1 then ---- In case of 0 city error
		return
	end
	
	for pCity in defPlayer:Cities() do
	local cityPop = pCity:GetPopulation()
		if ( cityPop > 5 ) then
			apCities[iCounter] = pCity
			iCounter = iCounter + 1
		end		
	end	
		
	if (iCounter > 0) then
		local iRandChoice = Game.Rand(iCounter, "Choosing random city")
		local targetCity = apCities[iRandChoice]
		local Cityname = targetCity:GetName()	
		if targetCity:GetPopulation() > 3 then
			targetCity:ChangePopulation(-1, true)
			print ("population lost!"..Cityname)
		else 
			return
		end	
	end	

end
GameEvents.UnitKilledInCombat.Add(UnitDeathCounterAI)	





function UnitDeathCounter(
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
		
	local defPlayer	= Players[defPlayerID]
--	local defUnit	= defPlayer:GetUnitByID(defUnitID)


	if not defPlayer then 
	   return
	end

	local defUnit = defPlayer:GetUnitByID(defUnitID)	
		if not defUnit then 
	   return
	end
	
	local NoCasualtiesID = GameInfo.UnitPromotions["PROMOTION_NO_CASUALTIES"].ID
	local HalfCasualtiesID = GameInfo.UnitPromotions["PROMOTION_HALF_CASUALTIES"].ID
	
	if defUnit: IsHasPromotion( NoCasualtiesID) then
	print ("This unit won't cause Casualties!")
		return
	end
	

		
	if defPlayer:IsHuman() then 	---------Population Loss for Human Players
		if defFinalUnitDamage >= defMaxHitPoints then    ----------Uncombat units do not count.			
			if defPlayer:HasPolicy(GameInfo.Policies["POLICY_CENTRALISATION"].ID)then
				if defUnit: IsHasPromotion(HalfCasualtiesID) then
					print("This unit only cause half casualties!")
					g_UnitDeathSum = g_UnitDeathSum + 0.33
				else
					print("Player has the Policy to reduce the population loss rate!")
					g_UnitDeathSum = g_UnitDeathSum + 0.50
				end		
					
			else 
				if defUnit: IsHasPromotion(HalfCasualtiesID) then
					print("This unit only cause half casualties!")
					g_UnitDeathSum = g_UnitDeathSum + 0.5
				else
					print("Normal population loss rate!")
					g_UnitDeathSum = g_UnitDeathSum + 1
				end	
			end	
				PlayerUnitPopulationLoss(defPlayer)
			end		
		end	
	end			
GameEvents.CombatResult.Add(UnitDeathCounter)			


		
function PlayerUnitPopulationLoss(defPlayer)
	print("Human unit died total:"..g_UnitDeathSum)
	local PlayerCitiesCount = defPlayer:GetNumCities()
	local apCities = {}
	local iCounter = 0
	
	if g_UnitDeathSum < 2 then---- every two deaths cause a popluaton loss
		return
	end
	
	if PlayerCitiesCount <= 0 then ---- In case of 0 city error
		return
	end
		
	for pCity in defPlayer:Cities() do
		local cityPop = pCity:GetPopulation()
		if ( cityPop > 1 ) then
			apCities[iCounter] = pCity
			iCounter = iCounter + 1
		end		
	end	
		
	if (iCounter > 0) then
		local iRandChoice = Game.Rand(iCounter, "Choosing random city")
		local targetCity = apCities[iRandChoice]
		local Cityname = targetCity:GetName()
		local iX = targetCity:GetX();
		local iY = targetCity:GetY();
			
		if targetCity:GetPopulation() > 1 then
			targetCity:ChangePopulation(-1, true)
			print ("population lost!"..Cityname)
		else 
			return
		end	
		g_UnitDeathSum = 0    ------------prepare for another run
		local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTE_POPULATION_LOSS",targetCity:GetName()) --------Sending Message
		local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTE_POPULATION_LOSS_SHORT")
		defPlayer:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, iX, iY)			
	end	
end		




-----------------------------------------------------------------------Reset Unit Death Counter---------------------------------------
--function ResetDeathCounter(iPlayer, iAgainstTeam) 
----	local player = Players[iPlayer]
--	local iTeam = iAgainstTeam
--	if iPlayer:IsHuman() or iTeam:IsHuman() then
--		g_UnitDeathSum = 0
--		print ("Unit died total reset:"..g_UnitDeathSum)
--		return g_UnitDeathSum	
--	end
--end
--GameEvents.MakePeace.Add(ResetDeathCounter)
------------------------------------------------------------Unit death Counter-------------------------------------------------------------------------
--function UnitDeathCounter()	 
--	g_UnitDeathSum = g_UnitDeathSum + 1
--	print("Unit died total for this turn:"..g_UnitDeathSum)
--	if g_UnitDeathSum > 2 then		
--		return true		
--	else
--		return false
--	end
--end









------------------------------------------------------------------Misc Functions-------------------------------------------------------------------------











print("New Population Rule Pass!")
	




