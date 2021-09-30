
function GenerateResource(pPlayer, pCity)
--Prioritizes generating deer and bison, if possible.
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if pCity:CanWork(fPlot) and not fPlot:IsMountain() then
			if fPlot:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
					return true
				end
			elseif fPlot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
				if fPlot:GetFeatureType() == (-1) then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_BISON, 1)
							return true
						end
					end
				end
			end
		end
	end

--Falls back to generate cattle or sheep if deer/bison were not possible.
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if pCity:CanWork(fPlot) and not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				if fPlot:GetFeatureType() == (-1) then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
							return true
						end
					end
				end
			elseif fPlot:GetFeatureType() == (-1) then
				if fPlot:IsHills() and not fPlot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_SHEEP, 1)
						return true
					end
				end
			end
		end
	end

--If none of that was possible, check everything again. Can also place cattle on flood plains and deer on jungle or snow
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				if fPlot:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
						return true
					end
				elseif fPlot:GetFeatureType() == (-1) then
					if fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_SHEEP, 1)
							return true
						end
					else
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
							return true
						end
					end
				elseif fPlot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
						return true
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
				if fPlot:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
						return true
					end
				elseif fPlot:GetFeatureType() == (-1) then
					if fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_SHEEP, 1)
							return true
						end
					else
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_BISON, 1)
							return true
						end
					end
				elseif fPlot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
						return true
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
				if fPlot:IsHills() then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_SHEEP, 1)
						return true
					end
				elseif fPlot:GetFeatureType() == FeatureTypes.FEATURE_FLOOD_PLAINS then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_COW, 1)
						return true
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_DEER, 1)
					return true
				end
			end
		end
	end

--If all else fails, can place fish on coast.
--This building doesn't improve fish, but at least you get something.
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_COAST then
			if fPlot:GetFeatureType() == (-1) then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_FISH, 1)
					return true
				end
			end
		end
	end
	return false
end


GameEvents.CityConstructed.Add(function(iPlayer, iCity, building)
--Watch to see when a Ranch is construscted
	if building == GameInfoTypes.BUILDING_3UC_RANCH then
		local pPlayer = Players[iPlayer]
		local pCity = pPlayer:GetCityByID(iCity)
--Try to generate a resource. Message if it fails
		if GenerateResource(pPlayer, pCity) == false then
			print("Could not place any resources.")
		end
	end
end)