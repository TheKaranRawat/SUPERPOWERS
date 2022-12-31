-- New Trait and Policies


-------------------------------------------------------------------------New Trait Effects-----------------------------------------------------------------------
function SpecialUnitType(iPlayerID, iUnitID, iX, iY)
   local iPlayer = Players[iPlayerID]
   local pUnit = iPlayer:GetUnitByID(iUnitID)
--   local ChineseGeneralID = GameInfoTypes.UNIT_CHINESE_GREAT_GENERAL
--   local NoOceanID = GameInfo.UnitPromotions["PROMOTION_OCEAN_IMPASSABLE"].ID
   
   local pCity = iPlayer:GetCapitalCity()
   local pPlot = pCity
   
   local GameSpeed = Game.GetGameSpeedType()
   local QuickGameSpeedID = GameInfo.UnitPromotions["PROMOTION_GAME_QUICKSPEED"].ID 
   
     if iPlayer == nil then return
	 end
      
   	 if pUnit == nil then return
	 end
	 
	 if GameSpeed == 3 then
	 	pUnit:SetHasPromotion(QuickGameSpeedID, true)
	 end
	 
end
Events.SerialEventUnitCreated.Add(SpecialUnitType)
--


function JapanCultureUnit(iPlayer, iCity, iUnit, bGold, bFaith)	-- Japan can gain Culture from building units
   local iPlayer = Players[iPlayer]
   local pUnit = iPlayer:GetUnitByID(iUnit)
   
     if iPlayer == nil then return
	 end
	 
	 if pUnit == nil then return
	 end
   

	if(iPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_JAPAN"] and pUnit:IsCombatUnit()) then
		local currentCulture = iPlayer:GetJONSCulture()
		local BaseCulture = pUnit:GetBaseCombatStrength()
		local bonusCulture = math.ceil (BaseCulture * 1)
		
		-- Give the culture
		iPlayer:SetJONSCulture(currentCulture + bonusCulture)

		-- Notification 
		local text;
		if bonusCulture > 0 then		   
		   text = Locale.ConvertTextKey( "TXT_KEY_SP_TRAIT_CULTURE_FROM_UNIT", tostring(bonusCulture), pUnit:GetName())
		end
		if iPlayer:IsHuman() then
			Events.GameplayAlertMessage( text )
		end		
	end
end
GameEvents.CityTrained.Add(JapanCultureUnit)





function HunDestroyCity(newPlayerID)--Hun will gain yield after razing a city

	print ("City Razed!")

	local player = Players[Game.GetActivePlayer()]

	if player ~= nil then
		if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_HUNS"] then
			local CurrentTurn = Game.GetGameTurn()
			local Output = 10 * CurrentTurn
			if Output > 1000 then
				Output = 1000
			end
			
			print ("Output:"..Output)
			
			player:ChangeJONSCulture(Output)			
			player:ChangeGold(Output)
			player:ChangeFaith(Output)
			
			local team = Teams[player:GetTeam()]
			local teamTechs = team:GetTeamTechs()

			
			if teamTechs ~= nil then 
				local currentTech = player:GetCurrentResearch()
				local researchProgress = teamTechs:GetResearchProgress(currentTech)
				
				if currentTech ~= nil and researchProgress > 0 then
					teamTechs:SetResearchProgress(currentTech, researchProgress + Output)
				end
			end
			

			
			if player:IsHuman() and Output > 0 then
			 	local text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_TRAIT_OUTPUT_FROM_RAZING", tostring(Output))
				Events.GameplayAlertMessage( text )
			end
		
			
		
		end
	end

end
Events.SerialEventCityDestroyed.Add (HunDestroyCity)








function AssyriaCityCapture(oldPlayerID, iCapital, iX, iY, newPlayerID, bConquest, iGreatWorksPresent, iGreatWorksXferred)-- Assyria gain population after capturing cities
	local NewPlayer = Players[newPlayerID]
	local pPlot = Map.GetPlot(iX, iY)
	local pCity = pPlot:GetPlotCity()
	if NewPlayer == nil then
		print ("No players")
		return
	end 
	if NewPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ASSYRIA"] then
		if pCity:GetPopulation() > 4 then
		print ("Assyria captured a city!")
		local pCapital = NewPlayer:GetCapitalCity()
			pCapital:ChangePopulation(1,true)
			
			-- Notification
			local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ASSYRIA_POPULATION", pCapital:GetName())
  		    local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ASSYRIA_POPULATION_SHORT")
  			NewPlayer:AddNotification(NotificationTypes.NOTIFICATION_CITY_GROWTH, text, heading, iX, iY)	  
			
		end
	end
end
GameEvents.CityCaptureComplete.Add(AssyriaCityCapture)


--function PortugalBuildFeitoria(iHexX, iHexY, PlayerID, ImprovementType)
--	local iPlayer = Players[PlayerID]
--	
--	if ImprovementType == GameInfo.Improvements.IMPROVEMENT_FEITORIA.ID and iPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_PORTUGAL"] then
--	   	print ("Portugal Build a Feitoria!")
--	   	local GAThreshold = iPlayer:GetGoldenAgeProgressThreshold()
--	   	print ("GoldenAgeProgressThreshold:"..GAThreshold)
--	   	local GAmod = 0.25 * GAThreshold
--	   	iPlayer:ChangeGoldenAgeProgressMeter(GAmod)
--	   	print ("Done!")
--	end
--end
--Events.SerialEventImprovementCreated.Add(PortugalBuildFeitoria)


    
    
    
    
    
    
    
  print ("New Trait Effect Check Pass!")  