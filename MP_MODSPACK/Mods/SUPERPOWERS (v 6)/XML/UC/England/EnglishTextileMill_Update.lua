
function GenerateResource(pPlayer, pCity)

--Creates a Cotton resource on a land plot that doesn't have a resource
--Preference is for flat grass, plains, or flood plains
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				if fPlot:GetFeatureType() == (-1) then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
							return true
						end
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
				if fPlot:GetFeatureType() == (-1) then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
							return true
						end
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
				if fPlot:GetFeatureType() == FeatureTypes.FEATURE_FLOOD_PLAINS then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
						return true
					end
				end
			end
		end
	end

--May also stick on flat forest grass or plains
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				if fPlot:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
							return true
						end
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
				if fPlot:GetFeatureType() == FeatureTypes.FEATURE_FOREST then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
							return true
						end
					end
				end
			end
		end
	end

--But if that fails, settle for flat tundra (with or without forest) or desert (but not oasis)
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if not fPlot:IsHills() then
					if fPlot:GetResourceType(-1) == (-1) then
						fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
						return true
					end
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
				if fPlot:GetFeatureType() == (-1) then
					if not fPlot:IsHills() then
						if fPlot:GetResourceType(-1) == (-1) then
							fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
							return true
						end
					end
				end
			end
		end
	end


--And if that fails, stick the thing on any available land tile
--This could get really weird, so I'm hoping it doesn't happen. Often.
	for i = 1, pCity:GetNumCityPlots() - 1, 1 do
		local fPlot = pCity:GetCityIndexPlot(i)
		if not fPlot:IsMountain() then
			if fPlot:GetTerrainType() == TerrainTypes.TERRAIN_GRASS then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_PLAINS then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
					return true
				end
			elseif fPlot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW then
				if fPlot:GetResourceType(-1) == (-1) then
					fPlot:SetResourceType(GameInfoTypes.RESOURCE_COTTON, 1)
					return true
				end
			end
		end
	end

	return false
end

GameEvents.CityConstructed.Add(function(iPlayer, iCity, building)
--Watch to see when a Textile Mill is constructed
	if building == GameInfoTypes.BUILDING_3UC_TEXTILE then
		local pPlayer = Players[iPlayer]
		local pCity = pPlayer:GetCityByID(iCity)
--Try to generate a resource. Message if it fails
		if GenerateResource(pPlayer, pCity) == false then
			print("Could not place any resources.")
		end
	end
end)