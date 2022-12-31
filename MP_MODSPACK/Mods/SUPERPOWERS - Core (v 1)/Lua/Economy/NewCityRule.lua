-- NewCityRule
-- Author: Lincoln_lyf
-- Edited by Tokata
--------------------------------------------------------------
include( "UtilityFunctions.lua" )




--==========================================================================================
-- Global Defines
--==========================================================================================

--local resManpower		= GameInfoTypes["RESOURCE_MANPOWER"]
--local resConsumer		= GameInfoTypes["RESOURCE_CONSUMER"]
--local resElectricity	= GameInfoTypes["RESOURCE_ELECTRICITY"]
--local bCitySizeLV1	= GameInfoTypes["BUILDING_CITY_SIZE_TOWN"]
--local bCitySizeLV2	= GameInfoTypes["BUILDING_CITY_SIZE_SMALL"]
--local bCitySizeLV3	= GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"]
--local bCitySizeLV4	= GameInfoTypes["BUILDING_CITY_SIZE_LARGE"]
--local bCitySizeLV5	= GameInfoTypes["BUILDING_CITY_SIZE_XL"]
--local bCitySizeLV6	= GameInfoTypes["BUILDING_CITY_SIZE_XXL"]
--local bCitySizeLV7	= GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"]
--
--local bPuppetGov	= GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"]
--local bPuppetGovFull= GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"]
--local bConstable	= GameInfoTypes["BUILDING_CONSTABLE"]
--local bRomanSenate	= GameInfoTypes["BUILDING_ROMAN_SENATE"]
--local bSheriffOffice= GameInfoTypes["BUILDING_SHERIFF_OFFICE"]
--local bPoliceStation= GameInfoTypes["BUILDING_POLICE_STATION"]
--local bProcuratorate= GameInfoTypes["BUILDING_PROCURATORATE"]
--
--local polRationalismID	= GameInfo.Policies["POLICY_RATIONALISM"].ID
--local bRationalism	= GameInfoTypes["BUILDING_RATIONALISM_HAPPINESS"]
--local polAristocracyID	= GameInfo.Policies["POLICY_ARISTOCRACY"].ID
--local bTourismBoost	= GameInfoTypes["BUILDING_HAPPINESS_TOURISMBOOST"]
--
--local bManpowerBonus	= GameInfoTypes["BUILDING_MANPOWER_BONUS"]
--local bConsumerBonus	= GameInfoTypes["BUILDING_CONSUMER_BONUS"]
--local bConsumerPenalty	= GameInfoTypes["BUILDING_CONSUMER_PENALTY"]
--local bElectricityBonus	= GameInfoTypes["BUILDING_ELECTRICITY_BONUS"]
--local bElectriPenalty	= GameInfoTypes["BUILDING_ELECTRICITY_PENALTY"]
--
--local eModernID	= GameInfo.Eras["ERA_MODERN"].ID
--
--local polMonarchyID	= GameInfoTypes["POLICY_MONARCHY"]
--local bTManpower	= GameInfoTypes["BUILDING_TRADITION_MANPOWER"]
--local bTFood		= GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"]
--






function PlayerEditCity()------------------------This will trigger when player edit the specialists slots inside their cities.


------------------------CANNOT use Events.SpecificCityInfoDirty because it will cause infinte LOOP!!!!!!!!!!!!!!!!!!!!!!WTF!!!!!!!!!!!!!!!!!!!!!!!________

	local player = Players[Game.GetActivePlayer()]
	
	if player:IsBarbarian() or player:IsMinorCiv() then
		print ("Minors are Not available!")
    	return
	end

	if not player:IsHuman() then
		return
	end
	

	if UI.GetHeadSelectedCity() == nil then	
		return
	end

	local city = UI.GetHeadSelectedCity()

	local ManpowerRes = player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true)
	local ConsumerRes = player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_CONSUMER"], true)
--
--	SetCityPerTurnEffects(player)
	
	SetCitySpecialistResources(player,city)
	SetCityAntiNegGoldBonus(player,city)
	
	print ("city's Specialist slot Updated in city screen!")
	
	

end
Events.SerialEventCityInfoDirty.Add(PlayerEditCity)











function NewCitySystem(playerID)
	local player = Players[playerID]
	
	
	if player == nil then
		print ("No players")
		return
	end
	
	if player:IsBarbarian() or player:IsMinorCiv() then
		print ("Minors are Not available!")
    	return
	end
	
	if player:GetNumCities() <= 0 then 
		print ("No Cities!")
		return
	end
	
	

	
	-------------Some Nation's UAs are here!!!!!!!
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_GERMANY"] then
		SetProductionToCulture(player)
		print ("Germany's UA!")
	elseif player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_CHINA"] then
		SetGoldenAgeBonus(player)
		print ("China's UA!")
--	elseif player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_HUNS"] then
--		SetOutputFromRazing(player)
--		print ("Hun's UA!")	
	end
	
	
--	if not player:IsAlive() then
--		print ("No players")
--		return
--	end

	if not player:IsHuman() then ------(only for human players for now)
		print ("Not available!")
    	return
	end
	
	
	
	
-------------Special Policy Effects
	
	if player:HasPolicy(GameInfoTypes["POLICY_RELIGIOUS_POLITICS"]) or player:HasPolicy(GameInfoTypes["POLICY_CAPITALISM"]) then
		SetPolicyPerTurnEffects(player)		
		print ("Set Policy Per Turn Effects!") 
	end
	
	
-------------Set City Per Turn Effects

	if player:GetNumCities() > 0 then 
		local ManpowerRes = player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true)
		local ConsumerRes = player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_CONSUMER"], true)
		local ElectricityRes = player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_ELECTRICITY"], true)
		local ExcessHappiness = player:GetExcessHappiness()
		print ("ExcessHappiness:"..ExcessHappiness)
		
		InternationalImmigration(player)
		print ("International Immigration Start!")	
		
		if ConsumerRes < 0 then
			AutoAddingMerchants (player,ConsumerRes)
		end
		
		SetCityPerTurnEffects(player)
		SetCityResEffects (player,ManpowerRes,ConsumerRes,ElectricityRes)		
		if ExcessHappiness > 0 then
			SetHappinessEffects (player,ExcessHappiness)
		end		
		
		
		
		print("City per Turn Effects set!!")	
	end
	
	

end---------Function End
GameEvents.PlayerDoTurn.Add(NewCitySystem)



--------------Trigger the city system when player build new city
function HumanFoundingNewCities (iPlayerID,iX,iY)

	local player = Players[iPlayerID]
	if player:IsHuman() and player:GetNumCities() >= 1 then
		local pPlot = Map.GetPlot(iX, iY)
		local pCity = pPlot:GetPlotCity()
		
	----------In case of unwanted moving capital bug
		if pCity:IsOriginalCapital() then
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CAPITAL_LOCATOR"],1)
			print ("Marked with Capital label!")
		end
			
		SetCityPerTurnEffects(player)
		SetCityResEffects (player,ManpowerRes,ConsumerRes,ElectricityRes)	
		print ("Human's New city founded!")
	end
end
GameEvents.PlayerCityFounded.Add(HumanFoundingNewCities)







----------------City sized changing by population growth

function CitySizeChanged(hexX, hexY, population, citySize)
	if hexX == nil or hexY ==nil then
		print ("No Plot")
	return
	end	

	local plot = Map.GetPlot(ToGridFromHex(hexX, hexY))
	local city = plot:GetPlotCity()
	
	if city ==nil then
		print ("No cities")
	return
	end
	
	local player = Players[city:GetOwner()]

	
	if player == nil then
		print ("No players")
		return
	end
	
	if player:IsBarbarian() or player:IsMinorCiv() then
    	return
	end

	local cityPop = city:GetPopulation()
	if  cityPop >= 1  then
	   CitySetSize(city,player,cityPop)
	   print ("Set CitySize!")
	end
	
	
end-------------Function End
Events.SerialEventCityPopulationChanged.Add(CitySizeChanged)





print("New City Rule Check Pass!")



----------------------------------------------Utilities----------------------------------------
--
---- On city sell a building
--function CitySellGovernment(playerID, cityID, buildingID)
--	local pPlayer = Players[playerID]
--	local pBuilding = GameInfo.Buildings[buildingID]
--	if pBuilding.CityHallLevel > 0 then -- we sell the government!
--		local pCity = pPlayer:GetCityByID(cityID)
--		pCity:SetPuppet(true)
--		pCity:SetNumRealBuilding(bPuppetGov, 1) -- we do not need to consider Venice because they cannot sell governments!
--	end
--end
--GameEvents.CitySoldBuilding.Add(CitySellGovernment)
--







---------------------International Immigration
function InternationalImmigration(iPlayer)
	local HumanPlayerID = iPlayer:GetID()	

	for playerID,player in pairs(Players) do 
		if player == nil then
			print ("No players")
			return
		end
		if player:GetNumCities() > 0 and not player:IsMinorCiv() and not player:IsBarbarian() and not player:IsHuman() then  
		   local AIPlayerID = player:GetID()
		   if CheckMoveOutCounter(AIPlayerID,HumanPlayerID) >= 4 then		   	  
		   	  DoInternationalImmigration(AIPlayerID,HumanPlayerID)
		   	  print ("International Immigration: AI to Human!")
		   elseif CheckMoveOutCounter(HumanPlayerID,AIPlayerID) >= 4 then
		   	  DoInternationalImmigration(HumanPlayerID,AIPlayerID)
		   	  print ("International Immigration: Human to AI!")
		   end	  
		end
	end

end---------function end
















function DoInternationalImmigration(MoveOutPlayerID,MoveInPlayerID)
		
	local MoveOutPlayer = Players[MoveOutPlayerID]-----------This nation's population tries to move out
	local MoveInPlayer = Players[MoveInPlayerID]-----------Move to this nation	
	
	if MoveOutPlayer:GetNumCities() < 1 or MoveInPlayer:GetNumCities() < 1 then	
		return
	end
		
		
		
---------------------------------Immigrant Moving out--------------------
	local MoveOutCities = {}
	local MoveOutCounter = 0

	for pCity in MoveOutPlayer:Cities() do
		local cityPop = pCity:GetPopulation()
		if cityPop > 3 then
			MoveOutCities[MoveOutCounter] = pCity
			MoveOutCounter = MoveOutCounter + 1
		end		
	end	
		
	if (MoveOutCounter > 0) then
		local iRandChoice = Game.Rand(MoveOutCounter, "Choosing random city")
		local targetCity = MoveOutCities[iRandChoice]
		local Cityname = targetCity:GetName()	
		if targetCity:GetPopulation() > 3 then
			targetCity:ChangePopulation(-1, true)
			print ("Immigrant left this city:"..Cityname)
			
			------------Notification-----------
			if MoveOutPlayer:IsHuman() and targetCity ~= nil then
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_IMMIGRANT_LEFT_CITY", targetCity:GetName())
		        local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_IMMIGRANT_LEFT_CITY_SHORT")
		        MoveOutPlayer:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, targetCity:GetX(), targetCity:GetY())
			end
			
		else 
			return
		end	
	end	




---------------------------------Immigrant Moving In--------------------
	local apCities = {}
	local iCounter = 0
	for pCity in MoveInPlayer:Cities() do
		local cityPop = pCity:GetPopulation()
		if cityPop > 1 and cityPop < 80 and not pCity:IsPuppet() and not pCity:IsRazing() and not pCity:IsResistance() and not pCity:IsForcedAvoidGrowth() and not pCity:IsHasBuilding(GameInfoTypes["BUILDING_IMMIGRANT_RECEIVED"]) and pCity:GetSpecialistCount(GameInfo.Specialists.SPECIALIST_CITIZEN.ID) <= 0 then
			apCities[iCounter] = pCity
			iCounter = iCounter + 1
		end		
	end	
		
		
		
	if (iCounter > 0) then
		local iRandChoice = Game.Rand(iCounter, "Choosing random city")
		local targetCity = apCities[iRandChoice]
		local Cityname = targetCity:GetName()	
		if targetCity:GetPopulation() > 1 then
			targetCity:ChangePopulation(1, true)
			targetCity:SetNumRealBuilding(GameInfoTypes["BUILDING_IMMIGRANT_RECEIVED"],1)
			print ("Immigrant Move into this city:"..Cityname)
			
			------------Notification-----------
			if MoveInPlayer:IsHuman() and targetCity ~= nil then
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_IMMIGRANT_REACHED_CITY", targetCity:GetName())
		        local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_IMMIGRANT_REACHED_CITY_SHORT")
		        MoveInPlayer:AddNotification(NotificationTypes.NOTIFICATION_CITY_GROWTH, text, heading, targetCity:GetX(), targetCity:GetY())
			end
		end	
	end	


end---------function end






---------------------Policy Per Turn Effects
function SetPolicyPerTurnEffects(player)	
	if player:GetNumCities() > 0 then
		local pCity = player:GetCapitalCity()
		
		if player:HasPolicy(GameInfoTypes["POLICY_RELIGIOUS_POLITICS"]) then
			local FaithGained = player:GetTotalFaithPerTurn()
			local FaithToHappiness = math.floor(0.1 * FaithGained)
			print ("Player Faith to Happiness per Turn:"..FaithToHappiness)
			if FaithToHappiness > 0 then
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_FAITH_RELIGIOUS_POLITICS"],FaithToHappiness)
			else
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_FAITH_RELIGIOUS_POLITICS"],0)
			end			
		end
		
		
		if player:HasPolicy(GameInfoTypes["POLICY_CAPITALISM"]) then
		   local iUsedTradeRoutes = player:GetNumInternationalTradeRoutesUsed()
		   if iUsedTradeRoutes > 0 then
		   	  print ("Science from International Trade Route:"..iUsedTradeRoutes)	
		   	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADE_TO_SCIENCE"],iUsedTradeRoutes)		   	  
		   else
		   	  pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADE_TO_SCIENCE"],0)
		   end
		end
		
	end
end


---------------------China's UA
function SetGoldenAgeBonus(player)
	if player:GetNumCities() > 0 then
	local pCity = player:GetCapitalCity()  
		pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_TB_ART_OF_WAR"],0)
		if player:IsGoldenAge()then				
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_TB_ART_OF_WAR"],1)
			print ("China in Pax Sinica!")			
		end
	end
end


---------------------Germany's UA
function SetProductionToCulture (player)
	if player:GetNumCities() > 0 then
	
		for city in player:Cities() do
			local Cityname = city:GetName()	
			local CityProduction = city:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
			local ProductionRate = 0
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TB_CONVERTS_LAND_BARBARIANS"],0)
			print ("German city:"..Cityname.."Production:"..CityProduction)
			if CityProduction < 50 then				
				print ("Production Too Low!")				
			else 
				ProductionRate = math.floor(CityProduction/50)
--				if ProductionRate > 20 then
--					ProductionRate = 20
--				end
				print ("Production to Culture and Science for Germany! Rate:"..ProductionRate)						
			end
			
			if ProductionRate >= 1 then
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_TB_CONVERTS_LAND_BARBARIANS"],ProductionRate)
			end
		end	
	end
end---------function end



---------------------Hun's UA
--function SetOutputFromRazing(player)
--	if player:GetNumCities() > 0 then
--		for city in player:Cities() do
--			if city:IsRazing() then
--				local Cityname = city:GetName()		
--				print ("Burning city:"..Cityname)
--				
--				local CityPop = city:GetPopulation()
--
--				if CityPop < 1 then
--					print ("Citizens are all dead!")
--					return
--				end
--				
--				local GoldOutput = city:GetYieldRate(YieldTypes.YIELD_GOLD)
--				local ScienceOutput = city:GetYieldRate(YieldTypes.YIELD_SCIENCE)
--				local CultureOutput = city:GetYieldRate(YieldTypes.YIELD_CULTURE)
--				local FaithOutput = city:GetYieldRate(YieldTypes.YIELD_FAITH)
--					
--				print ("Gold:"..GoldOutput)
--				print ("Science:"..ScienceOutput)
--				print ("Culture:"..CultureOutput)
--				print ("Faith:"..FaithOutput)	
--				
--				player:ChangeJONSCulture(CultureOutput)
--				player:ChangeGold(GoldOutput)
--				player:ChangeFaith(FaithOutput)
--				
--				
--				local team = Teams[player:GetTeam()]
--				local teamTechs = team:GetTeamTechs()
--	
--				
--				if teamTechs ~= nil then 
--					local currentTech = player:GetCurrentResearch()
--					local researchProgress = teamTechs:GetResearchProgress(currentTech)
--					
--					if currentTech ~= nil and researchProgress > 0 then
--						teamTechs:SetResearchProgress(currentTech, researchProgress + ScienceOutput)
--					end
--				end
--				
--	
--				
--				if player:IsHuman() and ScienceOutput > 0 then
--				 	local text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_TRAIT_OUTPUT_FROM_RAZING", tostring(ScienceOutput), Cityname)
--					Events.GameplayAlertMessage( text )
--				end
--				
--			end
--		end
--	end
--end
--




function SetCityPerTurnEffects (player)

	if player:GetNumCities() > 0 then
		for city in player:Cities() do
		
			if city ~= nil then
			
				local Cityname = city:GetName()	
				print ("Get the city:"..Cityname)
						
	----------In case of unwanted capital movement
				if player:IsHuman() then	
					if city:IsHasBuilding(GameInfoTypes["BUILDING_CAPITAL_LOCATOR"]) then
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_PALACE"],1)
						print ("this city is Capital because it has the label:"..Cityname)
					else
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_PALACE"],0)
					end	
				end				
								
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_IMMIGRANT_RECEIVED"],0)
	--			print ("Reset immigrant status!")
				
				SetCityLevelbyDistance(player,city)
			
				SetCitySpecialistResources(player,city)
			
				SetCityAntiNegGoldBonus(player,city)
			end
		end	
	end	
			
end-------------Function End




function SetCityAntiNegGoldBonus(player,city)

	if not city then
		print ("City does not exist!")
		return
	end
	
	if city:GetYieldRate(YieldTypes.YIELD_GOLD) < 0 then
		print ("City Goldyield < 0!")
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_BUGFIX_NEGATIVE_GOLD"],1)
	else
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_BUGFIX_NEGATIVE_GOLD"],0)		
	end

end




function SetCitySpecialistResources(player,city)

			if not city then
				print ("City does not exist!")
				return
			end
			
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_SPECIALISTS_MANPOWER"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_SPECIALISTS_CONSUMER"],0)
			
	-------------------Set Manpower offered by Engineers	
			local CityEngineerCount = city:GetSpecialistCount(GameInfo.Specialists.SPECIALIST_ENGINEER.ID)	
			if CityEngineerCount > 0 then
				print ("Engineers in the city:"..CityEngineerCount)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SPECIALISTS_MANPOWER"],CityEngineerCount)
			end
			
		-------------------Set Comsumer Goods offered by Merchants	
		local CityMerchantCount = city:GetSpecialistCount(GameInfo.Specialists.SPECIALIST_MERCHANT.ID)
		
			if CityMerchantCount > 0 then
				local ComsumerGoodsMultiplier = 2
				print ("Merchant in the city Base:"..CityMerchantCount)
				if player:HasPolicy(GameInfo.Policies["POLICY_MERCANTILISM"].ID) then
					ComsumerGoodsMultiplier = ComsumerGoodsMultiplier + 1
				end
				if player:HasPolicy(GameInfo.Policies["POLICY_ISKA_UNITED_FRONT"].ID) then
					ComsumerGoodsMultiplier = ComsumerGoodsMultiplier + 1
				end
				if player:HasPolicy(GameInfo.Policies["POLICY_SPACE_PROCUREMENTS"].ID) then
					ComsumerGoodsMultiplier = ComsumerGoodsMultiplier + 1
				end
				print ("Merchant Multiplier:"..ComsumerGoodsMultiplier)
				
				local CityMerchantProducingFinal = CityMerchantCount * ComsumerGoodsMultiplier				
				print ("Merchant in the city producing Final:"..CityMerchantProducingFinal)
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SPECIALISTS_CONSUMER"],CityMerchantProducingFinal)
			end		

end---------function end











function SetHappinessEffects(player,ExcessHappiness)	
--	print ("ExcessHappiness:"..ExcessHappiness)


	if player:HasPolicy(GameInfo.Policies["POLICY_RATIONALISM"].ID) then
	   local HappinesstoScienceRatio = math.floor(ExcessHappiness/25)	
	   local CaptialCity = player:GetCapitalCity()
	   
   		if HappinesstoScienceRatio > 10 then
			HappinesstoScienceRatio = 10
		end 
	  
	   if HappinesstoScienceRatio >= 1 then
	   	   CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_RATIONALISM_HAPPINESS"],HappinesstoScienceRatio)
	   	    print ("Happiness to Science!"..HappinesstoScienceRatio)
	   else
	   	  CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_RATIONALISM_HAPPINESS"],0)
	   end
	end
	
	local HappinessRatio = 0
	if ExcessHappiness > 0 then
		local CityTotal = player:GetNumCities()	
		local DubCityTotal = CityTotal * 5	
		HappinessRatio = math.floor(ExcessHappiness/DubCityTotal)	
		print ("Happiness Ratio 5 times:"..HappinessRatio)
	end 
	
	print ("Happiness to Tourism Ratio:"..HappinessRatio)
	if HappinessRatio >= 1 then
		for city in player:Cities() do
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_HAPPINESS_TOURISMBOOST"],HappinessRatio)
			print ("Excess Happiness add to Tourism!")
		end	
	end



	
end-------------Function End






function AutoAddingMerchants (player,ConsumerRes)

	if player == nil then
		print ("No players")
		return
	end
	
	if ConsumerRes < 0 then
		for city in player:Cities() do
			if not city:IsNoAutoAssignSpecialists() and not city:IsResistance() and not city:IsPuppet() and not city:IsRazing() and city:GetYieldRate(YieldTypes.YIELD_FOOD) > 2 then
				local Cityname = city:GetName()	
				print ("This city can add merchant: "..Cityname)
				for building in GameInfo.Buildings() do
					if building.SpecialistType == "SPECIALIST_MERCHANT" then
						local buildingID= building.ID
						if city:IsHasBuilding(buildingID) then
							if city:GetNumSpecialistsAllowedByBuilding(buildingID) > 0 and city:GetNumSpecialistsInBuilding(buildingID) < 1 then
								city:DoTask(TaskTypes.TASK_ADD_SPECIALIST,GameInfo.Specialists.SPECIALIST_MERCHANT.ID,buildingID)
								print ("Auto add a merchant to fill the consumer goods' gap!")
							end
						end
					end
				end
				
			end
		end
	end
end-------------Function End







function SetCityResEffects(player,ManpowerRes,ConsumerRes,ElectricityRes)
	local CaptialCity = player:GetCapitalCity()
	CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_MANPOWER_BONUS"],0)
	CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_BONUS"],0)
	CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY"],0)
	CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_BONUS"],0)
	CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_PENALTY"],0)
		
	local CityTotal = player:GetNumCities()	
	local DubCityTotal = CityTotal * 2
	local CityDivd = math.ceil(CityTotal/10)
	print ("Player Total Cities:"..CityTotal)
	
	
	if ManpowerRes == nil or ConsumerRes == nil or ElectricityRes == nil then
		print ("NO Resources!")
		return
	end
	
	----------------------Manpower Effects
	if ManpowerRes >= 25 then	
		local ManpowerRate = math.floor(ManpowerRes/DubCityTotal)
		if ManpowerRate > 7 then		
		   ManpowerRate = 7
		end
		

--		local PlayerHurryMod = player:GetHurryModifier(GameInfo.HurryInfos.HURRY_GOLD.ID) 
--		print ("-------------------------------------------------Player HurryModifier:"..PlayerHurryMod)
		
		print ("Manpower Rate:"..ManpowerRate)
		CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_MANPOWER_BONUS"],ManpowerRate)
		print ("Manpower Bonus!")
	else
		CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_MANPOWER_BONUS"],0)	
		print ("No Manpower Bonus!")
	end
	
	
		----------------------Consumer Effects/Penalties
	if ConsumerRes >= 25 then	
		local ConsumerRate = math.floor(ConsumerRes/CityTotal)
		if ConsumerRate >= 50 then		
		   ConsumerRate = 50
		end
		print ("Consumer Rate:"..ConsumerRate)
		
		if ConsumerRate >= 1 then
		   CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_BONUS"],ConsumerRate)
		   CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY"],0)
		   CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY_WARNING"],0)
		   print ("Consumer Bonus!")
		end
	elseif ConsumerRes >= 0 and ConsumerRes < 25 then	
		CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_BONUS"],0)
		CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY"],0)
		CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY_WARNING"],0)
		print ("No Consumer Bonus!")
		
	elseif ConsumerRes < 0 then		
		local ConsumerLackRaw = math.floor(ConsumerRes*CityDivd)
		local ConsumerLack = math.abs(ConsumerLackRaw)
		print ("Consumer Lacking:"..ConsumerLack)
		
		
		if ConsumerLack >= 50 then
		   ConsumerLack = 50
		elseif ConsumerLack <= 5 then
			ConsumerLack = 5    
		end
		
		if CaptialCity:IsHasBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY_WARNING"]) then
		   CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY"],ConsumerLack)	
		   print ("Consumer Penalty Effective!")
		else
			CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY_WARNING"],1)
			local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_LACKING_CONSUMER_GOODS_WARNING_SHORT")
			local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_LACKING_CONSUMER_GOODS_WARNING")
			player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, heading)	
			print ("Consumer Penalty Warning! Penalty will come if still lacking next turn!")
		end		
		
	end
	
	
	
		----------------------Electricity Effects/Penalties
	if player:GetCurrentEra() >= GameInfo.Eras["ERA_MODERN"].ID then
		
		if ElectricityRes >= 25 then
		   local ElectricityRate = math.floor(ElectricityRes/CityTotal)
		   if ElectricityRate >= 50 then		
			  ElectricityRate = 50
		   end
		  
		  	print ("Electricity Rate:"..ElectricityRate)
		  
		  if ElectricityRate >= 1 then
			 CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_BONUS"],ElectricityRate)			 
			 print ("Electricity Bonus!")
		  end
		  
		elseif ElectricityRes >= 0  and ElectricityRes < 25 then
		  
		  CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_BONUS"],0)
		  CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_PENALTY"],0)
		  print ("No Electricity Bonus!")
		  
		elseif ElectricityRes < 0 then
		   local ElectricityLackRaw = math.floor(ElectricityRes*CityDivd)
		   local ElectricityLack = math.abs(ElectricityLackRaw) 
		   
		   	if ElectricityLack >= 50 then
			   ElectricityLack = 50
			elseif ElectricityLack <= 5 then
			   ElectricityLack = 5    
			end
		   
		   	print ("Electricity lacking:"..ElectricityLack)
		   
		   	CaptialCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_PENALTY"],ElectricityLack)
			print ("Electricity Penalty!")
		   
	    end	
	end		
		
			
	
	
end-------------Function End









function CitySetSize(city,player,cityPop)

	if player == nil then
		print ("No players")
		return
	end
	
	if city == nil then
		print ("No city")
		return
	end
	
	if cityPop < 1 then
		print ("No Population!")
		return
	end	

	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_VENICE"] then--------------Fix Venice purchased citystate doesn't considered as Puppet BUG
		if not city:IsCapital() then
			city:SetNumRealBuilding(bPuppetGovFull,1)
			city:SetNumRealBuilding(bPuppetGov,0)
--			city:SetFocusType(3)
			print("Venice City Hall!")
		end
	end


	--[[ CITY BUILDINGS NEED TO BE 1 TO BE PRESENT IN CITY, ADD MODDED CITY SIZES TO CONDITION]]--

	if cityPop >= 80 then
		local pCity = player:GetCapitalCity()

		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	
		
		
		if player:HasPolicy(GameInfoTypes["POLICY_MONARCHY"])then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],5)
			print ("Monarchy Manpower Bonus!")
		else
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		end
		
	elseif cityPop >= 60 then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	
		
		if player:HasPolicy(GameInfoTypes["POLICY_MONARCHY"])then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],4)
			print ("Monarchy Manpower Bonus!")
		else
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		end

		
	elseif cityPop >= 40 then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	

		if player:HasPolicy(GameInfoTypes["POLICY_MONARCHY"])then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],3)
			print ("Monarchy Manpower Bonus!")
		else
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		end
	
	
	elseif cityPop >= 26 then
		local pCity = player:GetCapitalCity()

		
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	
		
		
		if player:HasPolicy(GameInfoTypes["POLICY_MONARCHY"])then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],2)
			print ("Monarchy Manpower Bonus!")
		else
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		end

	
	elseif cityPop >= 15 then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	

		
		if player:HasPolicy(GameInfoTypes["POLICY_MONARCHY"])then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],1)
			print ("Monarchy Manpower Bonus!")
		else
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		end


	
	elseif cityPop >= 6 then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	
		
	else 
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_TOWN"],1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_SMALL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_MEDIUM"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_LARGE"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_XXL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_SIZE_GLOBAL"],0)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_MANPOWER"],0)	
		
		if player:HasPolicy(GameInfoTypes["POLICY_ARISTOCRACY"])then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],1)
			print ("Aristocracy Growth Bonus!")
		else
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADITION_FOOD_GROWTH"],0)	
		end
				
	end
	





end-------------Function End









