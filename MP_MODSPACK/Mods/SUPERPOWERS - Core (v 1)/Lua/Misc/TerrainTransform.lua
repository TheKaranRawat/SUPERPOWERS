



--Road/Railroad turn mountain into hill

--function RoadChangeMountain(iHexX, iHexY, iPlayerID, iRouteType)
--	local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY))
--	
--	if pPlot == nil then
--		return
--	end
--	
--	if pPlot:IsMountain() then	
--		pPlot:SetPlotType(PlotTypes.PLOT_HILLS, false, true)
--		print("Road on Mountain! Now it is Hill!")
--	end
--
--end
--
--Events.SerialEventRoadCreated.Add(RoadChangeMountain)
--
--


--Build Improvements Effects



function ImprovementBuilt(iPlayer, x, y, eImprovement)


	if iPlayer == nil then
		return
	end
	
	local player = Players[iPlayer]
--	if not player:IsHuman() then ------(only for human players for now)
--		print ("Improvement is built by AI, Not available for now because it may cause CTD!!!!")
--    	return
--	end
	

--	print ("Improvement Built:" ..eImprovement)
	local pPlot = Map.GetPlot(x, y)
	
	
	if pPlot == nil then
		return
	end
	
	
	
	--if (eImprovement == GameInfo.Improvements["IMPROVEMENT_FISHERY_MOD"].ID) then		
	--	pPlot:SetImprovementType(-1)
	--	pPlot:SetResourceType(-1)
	--	pPlot:SetResourceType(GameInfoTypes.RESOURCE_FISH, 1)
	--	pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_FISHFARM_MOD"].ID)	
	--	print ("fish farm created!")

		
--	elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_SAND_DREDGE_MOD"].ID) then
--		print ("Sand dredge ceated!")
--		pPlot:SetImprovementType(-1)
--		pPlot:SetResourceType(GameInfoTypes.RESOURCE_SAND_DREDGE, 1)
--		pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_SAND_DREDGE_MOD"].ID)	
		
	--elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_GAS_RIG_MOD"].ID) then		
	--	pPlot:SetImprovementType(-1)
	--	pPlot:SetResourceType(-1)
	--	pPlot:SetResourceType(GameInfoTypes.RESOURCE_NATRUALGAS, 1)
	--	pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_OFFSHORE_PLATFORM"].ID)	
	--	print ("Gas Rig created!")
		
		
	if (eImprovement == GameInfo.Improvements["IMPROVEMENT_IROQUOIAN_FOREST_FARM"].ID) then		
		pPlot:SetImprovementType(-1)
		pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_FARM"].ID)	
		print ("Farm in Forest created!")
				
		
	elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_ETHIOPIA_COFFEE"].ID) then	
	
			if pPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				pPlot:SetImprovementType(-1)	
				pPlot:SetFeatureType(-1)
				pPlot:SetResourceType(GameInfoTypes.RESOURCE_COFFEE, 1)
				pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_PLANTATION"].ID)	
				print ("Ethiopian Coffee created!")	
			elseif pPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then 
				pPlot:SetImprovementType(-1)	
				pPlot:SetFeatureType(-1)
				pPlot:SetResourceType(GameInfoTypes.RESOURCE_COCOA, 1)
				pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_PLANTATION"].ID)	
				print ("Ethiopian Cocoa created!")	
			end
		
	elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_CITADEL"].ID) then		
		SetCitadelUnits(iPlayer, x, y)   
		print ("Citadel created!")
		
		
	elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_CREATE_FOREST_MOD"].ID) then		
		pPlot:SetImprovementType(-1)	
		pPlot:SetFeatureType(-1)
		pPlot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1)
		print ("Forest created!")
		
		
	elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_CREATE_JUNGLE_MOD"].ID) then		
		pPlot:SetImprovementType(-1)	
		pPlot:SetFeatureType(-1)
		pPlot:SetFeatureType(FeatureTypes.FEATURE_JUNGLE, -1)
		print ("Jungle created!")
				
	
	elseif (eImprovement == GameInfo.Improvements["IMPROVEMENT_MOUNTAIN_ROCKS"].ID) then
		pPlot:SetPlotType(PlotTypes.PLOT_HILLS, false, true)
		pPlot:SetResourceType(GameInfoTypes.RESOURCE_STONE, 1)
		pPlot:SetImprovementType(GameInfo.Improvements["IMPROVEMENT_QUARRY"].ID)	
		print("Mountain digged!")

				

	end
	
	
	


end
GameEvents.BuildFinished.Add(ImprovementBuilt) 






------Remove Citadel Improvement when the unit is destroyed 
--function RemoveCitadel(playerID,unitID)
--
--	print ("Unit removed!")
--
-- 
--	if playerID == nil then
--		return
--	end
--	
--	local player = Players[playerID]	
--	if not player:IsHuman() then ------(only for human players for now)
--		print ("Unit Removed by AI! Not available for now because it may cause CTD!!!!")
--    	return
--	end
--	
--	
----	local pFoundUnit = Players[playerID]:GetUnitByID(unitID)
--
--	local CitadelUnitID = GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID
--	
--	
--	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
--		local pPlot = Map.GetPlotByIndex(plotLoop)
--		local plotImprovement = pPlot:GetImprovementType()
--
--		if pPlot:GetImprovementType() == GameInfo.Improvements["IMPROVEMENT_CITADEL"].ID then
--			print ("Find Citadel!")
--			local unitCount = pPlot:GetNumUnits()
--			
--			for i = 0, unitCount-1, 1 do					
--				local pFoundUnit = pPlot:GetUnit(i)					
--				if pFoundUnit ~= nil and pFoundUnit:IsHasPromotion(CitadelUnitID) then
--					pPlot:SetImprovementType(-1)
--					print ("Citadel Removed!")
--				end
--			end	
--		end
--		
--
--	end
--	
--	
--end	
--
--Events.SerialEventUnitDestroyed.Add(RemoveCitadel)	



--------------------------------------------------Utilities-------------------------------------


function SetCitadelUnits(iPlayer, x, y)

	local pPlayer = Players[iPlayer]
	local pTeam = Teams[pPlayer:GetTeam()]
	local pPlot = Map.GetPlot(x, y)
	
	local CitadelUnitID = GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID
	
	local CitadelUnitEarly = GameInfoTypes.UNIT_CITADEL_EARLY
	local CitadelUnitMid = GameInfoTypes.UNIT_CITADEL_MID
	local CitadelUnitLate = GameInfoTypes.UNIT_CITADEL_LATE


	
	if pPlayer == nil then
		return
	end
	
	
--	if not pPlayer:IsHuman() then ------(only for human players for now)
--		print ("Citadel Units Not available for now because it may cause CTD!!!!")
--    	return
--	end
	
	
	local unitCount = pPlot:GetNumUnits()
	local iCounter = 1
	
	---------------This Event will be triggered TWICE , so must delete one of them to stop it from creating two units
	for i = 0, unitCount-1, 1 do
		local pFoundUnit = pPlot:GetUnit(i)			
		if pFoundUnit ~= nil and pFoundUnit:IsHasPromotion(CitadelUnitID) then
			iCounter = 3
			print ("Already there!")		
		end	
	end	
	
	if iCounter < 2 then
		if pTeam:IsHasTech(GameInfoTypes["TECH_ADV_FLIGHT"]) then
		   pPlayer:InitUnit(CitadelUnitLate, x, y, UNITAI_RANGED)
		elseif pTeam:IsHasTech(GameInfoTypes["TECH_MILITARY_LOGISTICS"]) then
		   pPlayer:InitUnit(CitadelUnitMid, x, y, UNITAI_RANGED)
		elseif pTeam:IsHasTech(GameInfoTypes["TECH_GUNPOWDER"]) then	   		   
		   pPlayer:InitUnit(CitadelUnitEarly, x, y, UNITAI_RANGED)
		end
	end

end















--------------------------Clear the naval improvement resource after being destroyed--------------------------

--function ImprovementDestroyed(iHexX, iHexY, iContinent1, iContinent2)
--	print ("Improvement Destroyed!")
--
--	local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY))
--	
--	if pPlot == nil then
--		return
--	end
--
--
--	---------------Remove Man-made Naval Resources
--	
-- 	if pPlot:GetResourceType() == GameInfoTypes.RESOURCE_OIL and pPlot:GetNumResource()== 1 then
-- 	   print ("find naval resource leftover: natrual gas!")	
--	   pPlot:SetResourceType(-1)	   
--	   LuaEvents.SerialEventRawResourceIconDestroyed(iHexX, iHexY)
-- 	end
--
--	if pPlot:GetResourceType() == GameInfoTypes.RESOURCE_FISHFARM or pPlot:GetResourceType() == GameInfoTypes.RESOURCE_SAND_DREDGE then
--	   print ("find naval resource leftover: fish or sand!")	
--	   pPlot:SetResourceType(-1)
--	   LuaEvents.SerialEventRawResourceIconDestroyed(iHexX, iHexY)
--	end
--
--
--	
--	---------------Remove Citadel Units
--	
--	local unitCount = pPlot:GetNumUnits()
--		
--	for i = 0, unitCount-1, 1 do
--		local pFoundUnit = pPlot:GetUnit(i)	
--		local CitadelUnitID = GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID		
--		if pFoundUnit ~= nil and pFoundUnit:IsHasPromotion(CitadelUnitID) then
--			if pPlot:GetImprovementType() ~= GameInfo.Improvements["IMPROVEMENT_CITADEL"].ID then			
--			   print ("Find Citadel Unit on normal tile!")	
--			   pFoundUnit:Kill()
--			end
--		end	
--	end	
--	
--
--end
--Events.SerialEventImprovementDestroyed.Add(ImprovementDestroyed)
--

print("TerrainTransform Check Pass!")