-- NewPolicyEffects




--------------------------------------------------------------
-------------------------------------------------------------------------New Policy Effects-----------------------------------------------------------------------
-- Militarism reduce city resistance time
function OnCityCaptured(oldPlayerID, iCapital, iX, iY, newPlayerID, bConquest, iGreatWorksPresent, iGreatWorksXferred)

	local PolicyAuto = GameInfo.Policies["POLICY_MILITARISM"].ID
	local NewPlayer = Players[newPlayerID]
	local resModifier = -50
	local pPlot = Map.GetPlot(iX, iY)
	local pCity = pPlot:GetPlotCity()
	
	if NewPlayer == nil then
		print ("No players")
		return
	end 
	
	if NewPlayer:IsBarbarian() or NewPlayer:IsMinorCiv() then
		print ("Minors are Not available!")
    	return
	end
	
	if NewPlayer:HasPolicy(PolicyAuto) then
	local resTime = pCity:GetResistanceTurns()
	local CityPop = pCity:GetPopulation()
		print("resTime="..resTime)
		
		if CityPop < 6 then
			pCity:ChangeResistanceTurns(-CityPop)
		end
		
		if resTime > 1 then
		  	local resTimeRatio =  resTime * resModifier/100 +0.5
		  	local resTimeChange = math.floor(resTimeRatio)
			print ("resTimeChange="..resTimeChange)
			pCity:ChangeResistanceTurns(resTimeChange)
		end
	end	
end
GameEvents.CityCaptureComplete.Add(OnCityCaptured)





-- Citizenship offer free Worker when new city founded
function FreeUnitNewCity(iPlayerID,iX,iY)
    local iPlayer = Players[iPlayerID]
	local pPlot = Map.GetPlot(iX, iY)
	local PolicyLiberty = GameInfo.Policies["POLICY_CITIZENSHIP"].ID
	local WorkerID = GameInfoTypes.UNIT_WORKER
	
    if iPlayer:HasPolicy(PolicyLiberty) then
--    	print ("Free Policy Unit!")
		if iPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_BRAZIL"] then
			WorkerID = GameInfoTypes.UNIT_BRAZILIAN_LABOR
   	 	end
   	 	
   	 	local NewUnit = iPlayer:InitUnit(WorkerID, iX, iY, UNITAI_WORKER)
		NewUnit:JumpToNearestValidPlot()    
	end
end

GameEvents.PlayerCityFounded.Add(FreeUnitNewCity)


--
--
--
---- Honor training unit gain Science
--function UnitGainScience(iPlayer, iCity, iUnit, bGold, bFaith)
--   local player = Players[iPlayer]
--   local pUnit = player:GetUnitByID(iUnit)
--   local policyID = GameInfoTypes["POLICY_MILITARY_CASTE"]
--   
--  	if player == nil then
--		print ("No players")
--		return
--	end 
--	
--
--	
--	if player:IsBarbarian() or player:IsMinorCiv() then
--		print ("Minors are Not available!")
--    	return
--	end
--	
--	if player:GetNumCities() < 1 then 
--		print ("No Cities!")
--		return
--	end
--	
--	 if pUnit == nil then
--		print ("No Units")
--		return
--   	end 
--   
--
--
--	if player:HasPolicy(policyID) and pUnit:IsCombatUnit() then
----		print("New unit built!")
--
--		if not player:IsTurnActive() then
--			print ("Not Current Player")
--			return
--		end 
--	
--
--		local team = Teams[player:GetTeam()]
--		local teamTechs = team:GetTeamTechs()
--		
--		if not teamTechs then --------------Avoid AI crash if a Tech is finished right after a unit built
--			print ("no Tech under researching")
--			return
--		end
--		
--		local currentTech = player:GetCurrentResearch()
--		local researchProgress = teamTechs:GetResearchProgress(currentTech)
--		
--		if not currentTech then
--			return
--		end
--		
--		if not researchProgress then
--			return
--		end
--		
--		
--		local pUnitStrength = pUnit:GetBaseCombatStrength()
--		
--		if pUnitStrength < 1 then 
--			return
--		end
--		
--		
--		if pUnit:IsRanged() then
--			if pUnit:GetBaseCombatStrength() < pUnit:GetBaseRangedCombatStrength()	then
--				pUnitStrength = pUnit:GetBaseRangedCombatStrength()	
--			else
--				pUnitStrength = pUnit:GetBaseCombatStrength()	
--			end
--		end
--		
--		local adjustedBonus = math.ceil(pUnitStrength*0.5)
--		-- Give the Science
--		
--		print ("researchProgress "..researchProgress)
--		if researchProgress > 0 then
--   			teamTechs:SetResearchProgress(currentTech, researchProgress + adjustedBonus)
--   			local text
--			if adjustedBonus > 0 then		   
--			   text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_UNIT_GAIN_SCIENCE", tostring(adjustedBonus), pUnit:GetName())
--			end
--			if player:IsHuman() then
--				Events.GameplayAlertMessage( text )
--			end
--		end
--		
--
--		
--		
--
--		-- Send a notification to the player
----		if player:IsHuman()then
----			local text = Locale.ConvertTextKey("TXT_KEY_SP_POLICY_SCIENCE_FROM_UNIT", tostring(adjustedBonus), pUnit:GetName())
----			player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, text)
----		end
--	end
--end
--GameEvents.CityTrained.Add(UnitGainScience)
--



function PolicyAdoptedEffects(playerID,policyID)

 local player = Players[playerID]	
 
 	if player== nil then
 		return
 	end
	
	if not player:IsHuman() then ------(only for human players for now)
		print ("Ai Poicy, not available!")
    	return
	end
	
	if player:GetNumCities() < 1 then 
		return
		print("Not enough city!")	
	end
	
	 if policyID == nil then
		return
   	end 

	if policyID == GameInfo.Policies["POLICY_DICTATORSHIP_PROLETARIAT"].ID then
		ChangeACBuildings (player)		
	elseif policyID == GameInfo.Policies["POLICY_REPRESENTATION"].ID then
		ReducePolicyCost (player)		
	elseif policyID == GameInfo.Policies["POLICY_MONARCHY"].ID then
		AddAdditionalManpower (player)	
	elseif policyID == GameInfo.Policies["POLICY_ARISTOCRACY"].ID then
		FasterFoodGrowth (player)		
			
	end
	
	

end

GameEvents.PlayerAdoptPolicy.Add(PolicyAdoptedEffects);




print("New Policy Effects Check Pass!")





----------------------------------------------Utilities----------------------------------------

function FasterFoodGrowth (player)	
	for city in player:Cities() do
		if city:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_SIZE_TOWN"].ID) then
			local pPopulation = city:GetPopulation()
			local pThreshold = city:GrowthThreshold ()
			city:ChangeFood(pThreshold)			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],1)
			print ("Aristocracy Growth Bonus!")
		end
	end
end


function AddAdditionalManpower (player)
	for city in player:Cities() do
		if city:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_SIZE_GLOBAL"].ID) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],5)
			
		elseif city:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_SIZE_XXL"].ID) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],4)
			
		elseif city:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_SIZE_XL"].ID) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],3)	
			
		elseif city:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_SIZE_LARGE"].ID) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],2)	
			
		elseif city:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_SIZE_MEDIUM"].ID) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],1)		
		end
	end
end



function ReducePolicyCost (player)
	for pCity in player:Cities() do
		if not pCity:IsPuppet() and not pCity:IsCapital() then
	  	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"],1)	
	  	  print ("Player has the Representation policy!")
	   end
	end
end




function ChangeACBuildings (player)

	for pCity in player:Cities() do
		if pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_HALL_LV2"].ID) then
		
		   if pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_CONSTABLE"].ID) then
			   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0);
			   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
		   end
		   
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],1)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
		   
		   
		   
		 elseif pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_HALL_LV3"].ID) then

		  if pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_SHERIFF_OFFICE"].ID) then
			   if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ROME"] then
			      pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0); 
			   	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0); 
			      pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],1)
			   else   
			   	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0); 
			      pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],1);
			   end
		   end
		   
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],1)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
		   
		   
		   
		 elseif pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_HALL_LV4"].ID) then
		  
		   if pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_POLICE_STATION"].ID) then
		   	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0); 
		  	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],1); 
		   end
		   
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],1)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
		   
		 elseif pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_CITY_HALL_LV5"].ID) then
		 
			 if pCity:IsHasBuilding(GameInfo.Buildings["BUILDING_PROCURATORATE"].ID) then
			   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0); 
			   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],1); 
			 end	
			 
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],1)
		   pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
			 
		end
		print ("AC building changed!")	
	end
end

