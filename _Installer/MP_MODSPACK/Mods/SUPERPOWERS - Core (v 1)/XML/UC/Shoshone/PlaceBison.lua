-- Place Bison -- Author: Neirai -- DateCreated: 5/12/2014 9:35:31 AM

function buildABison(pPlayer, pCity)
	for pCityPlot = 1, pCity:GetNumCityPlots() - 1, 1 do
		local pSpecificPlot = pCity:GetCityIndexPlot(pCityPlot)
		if pSpecificPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
			if pSpecificPlot:GetFeatureType() == (-1) and not pSpecificPlot:IsMountain() then
				if pSpecificPlot:GetResourceType(-1) == (-1) then
					pSpecificPlot:SetResourceType(GameInfoTypes.RESOURCE_BISON, 1)
					pSpecificPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_CAMP)
					print("Bison Placed on Plains")
					return true
				end
			end
		elseif
			pSpecificPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
			if pSpecificPlot:GetFeatureType() == (-1) and not pSpecificPlot:IsMountain() then
				if pSpecificPlot:GetResourceType(-1) == (-1) then
					pSpecificPlot:SetResourceType(GameInfoTypes.RESOURCE_BISON, 1)
					pSpecificPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_CAMP)
					print("Bison Placed on Grasslands")
					return true
				end
			end
		elseif
			pSpecificPlot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
			if pSpecificPlot:GetFeatureType() == (-1) and not pSpecificPlot:IsMountain() then
				if pSpecificPlot:GetResourceType(-1) == (-1) then
					pSpecificPlot:SetResourceType(GameInfoTypes.RESOURCE_BISON, 1)
					pSpecificPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_CAMP)
					print("Bison Placed on Tundra")
					return true
				end
			end
		end
	end
	return false
end
	
function PutBisonSomewhere(player, city, building)
	print(building)
	print(GameInfoTypes.BUILDING_3BUFFALOPOUND)
	if building == GameInfoTypes.BUILDING_3BUFFALOPOUND then
		local pPlayer = Players[player]
			local pCity = pPlayer:GetCityByID(city)
			if buildABison(pPlayer, pCity) == false then
				print("No place to place a Bison place.")
		end
	end
end
GameEvents.CityConstructed.Add(PutBisonSomewhere)
