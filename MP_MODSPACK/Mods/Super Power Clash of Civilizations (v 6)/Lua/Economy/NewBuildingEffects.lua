-- NewBuildingEffects

--------------------------------------------------------------


-----------New building effects when it is built
function NewBuildingEffects(iPlayer, iCity, iBuilding, bGold, bFaith)
 local player = Players[iPlayer]
 local pCity = player:GetCityByID(iCity)
 	if player == nil then
 		return
 	end
 	
 		
	if player:IsBarbarian() or player:IsMinorCiv() then
    	return
	end
 	
 	
	if player:GetNumCities() > 0 then
	
		-- AI Bonus
		if iBuilding == GameInfo.Buildings.BUILDING_MARKET.ID or iBuilding == GameInfo.Buildings.BUILDING_BAZAAR.ID then
			if not player:IsHuman() then
				local MAID = GameInfo.Buildings.BUILDING_MILITARY_ACADEMY.ID
--				local ConsumerResID = GameInfoTypes["RESOURCE_CONSUMER"]-----------Give AI additional Consumer Goods to make them able to build settlers
				pCity:SetNumRealBuilding(MAID, 1)
--				player:ChangeNumResourceTotal (ConsumerResID,1)
				print ("AI Free Military Academy!")	
			end
		end
	
	
		-- One-time Money Offer Effect
	
		if iBuilding == GameInfo.Buildings.BUILDING_BURJ_TOWER.ID then		
			local GameSpeed = Game.GetGameSpeedType()
			print ("Game Speed:"..GameSpeed)
			if GameSpeed == 0 then
				player:ChangeGold(99999)
			elseif GameSpeed == 1 then
				player:ChangeGold(66666)
			elseif GameSpeed == 2 then
				player:ChangeGold(44444)
			elseif GameSpeed == 3 then
				player:ChangeGold(22222)				
			end	
		end   
		
		if iBuilding == GameInfo.Buildings.BUILDING_AUSTRIA_MUSIC_SCHOOL.ID then		
			local GameSpeed = Game.GetGameSpeedType()
			print ("Game Speed:"..GameSpeed)
			if GameSpeed == 0 then
				player:ChangeGold(1000)
			elseif GameSpeed == 1 then
				player:ChangeGold(750)
			elseif GameSpeed == 2 then
				player:ChangeGold(500)
			elseif GameSpeed == 3 then
				player:ChangeGold(300)				
			end	
		end   
		
		
		
		
		
		
		-- One-time Population Effect
		
		if iBuilding == GameInfo.Buildings.BUILDING_MEGACITY_PYRAMID.ID then	
			pCity:ChangePopulation(30, true)
		end
			
		---Move Captial
		
		if iBuilding == GameInfo.Buildings.BUILDING_NEW_PALACE.ID then
			print("New Captial Building!")
			local palaceID = GameInfo.Buildings.BUILDING_PALACE.ID
			if player:IsHuman()then --Only for human players
				for city in player:Cities() do
					if city:IsHasBuilding(palaceID) then
						print("Old Captial Found!")
						city:SetNumRealBuilding(palaceID, 0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_BONUS"],0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_ELECTRICITY_PENALTY"],0)
						
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_MANPOWER_BONUS"],0)

						city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_BONUS"],0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY_WARNING"],0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSUMER_PENALTY"],0)
						
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_TB_ART_OF_WAR"],0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_HAPPINESS_TOURISMBOOST"],0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_TRADE_TO_SCIENCE"],0)
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_RATIONALISM_HAPPINESS"],0)
						
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_CAPITAL_LOCATOR"],0)
					end	
					

									
				end	
				
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CAPITAL_LOCATOR"],1)
				pCity:SetNumRealBuilding(palaceID, 1)
				
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)	
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_NEW_PALACE"], 0)
				print("Captial Moved!")
			end	
		end 
	end
	
	
end------Function End

GameEvents.CityConstructed.Add(NewBuildingEffects)





function NotificationEvents (notification,notificationType,toolTip,summary)

	
	
	-------------Remove Useless Notifications （Temporary method）
	
	

	local Keywords = string.find(summary,"OVER_RESOURCE") 

	if Keywords ~= nil then 
		UI.RemoveNotification( notification )
		print ("Useless Notification Removed!"..notificationType)		
	else
		return
	end
	
	
	
	-----------------------Spy Events
--	if notificationType == NotificationTypes.NOTIFICATION_SPY_KILLED_A_SPY then
--		local player = Players[Game.GetActivePlayer()]
--		if player:IsHuman() then
--			local pCity = player:GetCapitalCity()
--			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_INTELLIGENCE_AGENCY"],1) 
--			print ("Espionage Success!")
--		end	
--	end

end
Events.NotificationAdded.Add(NotificationEvents);








-------Auto replacement for obsolete buildings, currently only for human player for stability issues


function AutoBuildingReplace(iTeam, iTech, bAdopted)
--	print ("tech researched!")
	local pTeam = Teams[iTeam]
	
	if not pTeam:IsHuman() then
--	print ("Only for human!")
	 	return
	end
	
	local player = Players[Game.GetActivePlayer()]
	if player:IsMinorCiv() and player:IsBarbarian()  then
	 	return
	end
	
	if player:GetNumCities() > 0 then
		print ("Auto Buildings Replacement!")	
		
		local text
		 
		
		if iTech == GameInfoTypes["TECH_DYNAMITE"] then
			print ("tech: DYNAMITE")
			for city in player:Cities() do
				if city:IsHasBuilding(GameInfoTypes["BUILDING_STONE_WORKS"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_SAWMILL"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_LONGHOUSE"]) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_MINGING_FACTORY"],1)
					
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
					text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_MINGING_FACTORY")
					
					Events.GameplayAlertMessage( text )

				end	
			end
		elseif iTech == GameInfoTypes["TECH_INDUSTRIALIZATION"] then
			print ("tech: INDUSTRIALIZATION")
			for city in player:Cities() do
				if city:IsHasBuilding(GameInfoTypes["BUILDING_WORKSHOP"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_PAPER_MAKER"])then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_FACTORY"],1)
					
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
					text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_FACTORY")
					
					Events.GameplayAlertMessage( text )
							
				end
				if city:IsHasBuilding(GameInfoTypes["BUILDING_GRAIN_MILL"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_WATERMILL"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_FLOATING_GARDENS"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_WINDMILL"])  then
					if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_SHOSHONE"] then
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHOSHONE_HUNTING"],1)
						
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_SHOSHONE_HUNTING")
						
						
						
					else
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_MECHANIZED_FARM"],1)
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_MECHANIZED_FARM")
											
					end
					
						Events.GameplayAlertMessage( text )
					
				end	
			end
		elseif iTech == GameInfoTypes["TECH_FERTILIZER"] then
			print ("tech: FERTILIZER")
			for city in player:Cities() do
				if city:IsHasBuilding(GameInfoTypes["BUILDING_FISH_FARM"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_GRANARY"])then
				
					if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_MOROCCO"] then
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_MOROCCO_IRRIGATION"],1)					
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_MOROCCO_IRRIGATION")
					else
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_GRAIN_DEPOT"],1)					
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_GRAIN_DEPOT")
					end
					Events.GameplayAlertMessage( text )
									
				end
			end		
		elseif iTech == GameInfoTypes["TECH_URBANLIZATION"] then
			print ("tech: URBANLIZATION")
			for city in player:Cities() do
				if city:IsHasBuilding(GameInfoTypes["BUILDING_AQUEDUCT"]) or city:IsHasBuilding(GameInfoTypes["BUILDING_BASILICA_CISTERN"])then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_TAP_WATER_SUPPLY"],1)
						
					text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
					text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_TAP_WATER_SUPPLY")
									
					Events.GameplayAlertMessage( text )				
									
				end
			end	
		elseif iTech == GameInfoTypes["TECH_COMBUSTION"] then
			print ("tech: COMBUSTION")
			for city in player:Cities() do
				if city:IsHasBuilding(GameInfoTypes["BUILDING_STAGECOACH"])then
					
					if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_GERMANY"] then
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_GERMAN_AUTOBAHN"],1)
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_GERMAN_AUTOBAHN")

					elseif player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_VENICE"] then
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_VENICE_GRAND_CANAL"],1)	
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_VENICE_GRAND_CANAL")
					else
						city:SetNumRealBuilding(GameInfoTypes["BUILDING_BUS_STATION"],1)	
						text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_BUILDING_REPLACEMENT",city:GetName())
						text = text .. Locale.ConvertTextKey ("TXT_KEY_BUILDING_BUS_STATION")
					end	
					
					Events.GameplayAlertMessage( text )			
								
				end
			end				
		elseif iTech == GameInfoTypes["TECH_RAILROAD"] then
			print ("tech: RAILROAD")
			
			text = Locale.ConvertTextKey( "TXT_KEY_SP_NOTIFICATION_AUTO_RAILROAD_REPLACEMENT")
			Events.GameplayAlertMessage( text )

			for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
				local plot = Map.GetPlotByIndex(plotLoop)
--				local plotOwner = Players[plot:GetOwner()]

			   if plot:GetRouteType() == GameInfo.Routes.ROUTE_ROAD.ID then
				  plot:SetRouteType(GameInfo.Routes.ROUTE_RAILROAD.ID)
			   end
--				if plotOwner ~= nil then
--					if plotOwner == player then	
--		
--					end
--				end	
			end
			
		else
			
		end
		
	end
	
	
end------Function End
GameEvents.TeamSetHasTech.Add(AutoBuildingReplace)









print("New Building Effects Check Pass!")


---------------------------------------------------------Utilities---------------------------------------------------------

