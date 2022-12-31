-- Place Bison -- Author: Neirai -- DateCreated: 5/12/2014 9:35:31 AM

function buildACow(pPlayer, pCity)
	for pCityPlot = 1, pCity:GetNumCityPlots() - 1, 1 do
		local pSpecificPlot = pCity:GetCityIndexPlot(pCityPlot)
		if
			pSpecificPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
			if pSpecificPlot:GetFeatureType() == (-1) and not pSpecificPlot:IsMountain() then
				if pSpecificPlot:GetResourceType(-1) == (-1) then
					pSpecificPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
					pSpecificPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_PASTURE)
					print("Cow Placed on Grasslands")
					return true
				end
			end
				elseif
			pSpecificPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
			if pSpecificPlot:GetFeatureType() == (-1) and not pSpecificPlot:IsMountain() then
				if pSpecificPlot:GetResourceType(-1) == (-1) then
					pSpecificPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
					pSpecificPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_PASTURE)
					print("Cow Placed on Plains")
					return true
				end
			end
		end
	end
	return false
end
	
function PutCowSomewhere(player, city, building)
	print(building)
	print(GameInfoTypes.BUILDING_BULLRING)
	if building == GameInfoTypes.BUILDING_3UC_BULLRING then
		local pPlayer = Players[player]
			local pCity = pPlayer:GetCityByID(city)
			if buildACow(pPlayer, pCity) == false then
				print("No place to place a Cow.")
		end
	end
end
GameEvents.CityConstructed.Add(PutCowSomewhere)
