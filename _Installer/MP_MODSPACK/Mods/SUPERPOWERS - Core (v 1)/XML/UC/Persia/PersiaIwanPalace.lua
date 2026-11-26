
function GenerateResource(pPlayer, pCity)

--Creates a Gold resource on a land plot that doesn't have a resource
--Preference is for hills
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:IsHills() then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_GOLD, 1)
					return true
				end
			end
		end
	end

--And if that fails, stick it pretty much anywhere
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_GOLD, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_GOLD, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
				if fPlot:GetResourceType(-1) == (-1) then
					if not fPlot:GetFeatureType() == GameInfoTypes.FEATURE_OASIS then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_GOLD, 1)
						return true
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_GOLD, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_GOLD, 1)
					return true
				end
			end
		end
	end

	return false
end

GameEvents.CityConstructed.Add(function(iPlayer, iCity, building)
--Watch to see when a Iwan Palace is constructed
	if building == GameInfoTypes.BUILDING_IWAN_PALACE then
		local pPlayer = Players[iPlayer]
		local pCity = pPlayer:GetCityByID(iCity)
--Try to generate a resource. Message if it fails
		if GenerateResource(pPlayer, pCity) == false then
			print("Could not place any resources.")
		end
	end
end)