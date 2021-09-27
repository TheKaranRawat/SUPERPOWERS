
function GenerateResource(pPlayer, pCity)

--Creates a Cow or Sheep resource on a land plot that doesn't have a resource
--Prefers to place cows in grassland or plains and sheep on non-snow hills
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if pCity:CanWork(fPlot) and not fPlot:IsMountain() then
			if fPlot:GetResourceType(-1) == (-1) then
				if fPlot:GetFeatureType() == (-1) then
					if not fPlot:IsHills() then
						if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
							return true
						elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
							return true
						end
					elseif not fPlot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_SHEEP, 1)
						return true
					end
				end
			end
		end
	end

--If normal spots weren't available, go ahead and get weird.
--Cows will go anywhere flat and sheep on any hills
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if pCity:CanWork(fPlot) and not fPlot:IsMountain() then
			if fPlot:GetResourceType(-1) == (-1) then
				if fPlot:GetFeatureType() == (-1) then
					if fPlot:IsHills() then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_SHEEP, 1)
						return true
					else
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
						return true
					end
				end
			end
		end
	end
end

GameEvents.CityConstructed.Add(function(iPlayer, iCity, building)
--Watch to see when a Kraal is constructed
	if building == GameInfoTypes.BUILDING_KRAAL then
		local pPlayer = Players[iPlayer]
		local pCity = pPlayer:GetCityByID(iCity)
--Try to generate a resource. Message if it fails
		if GenerateResource(pPlayer, pCity) == false then
			print("Could not place any resources.")
		end
	end
end)