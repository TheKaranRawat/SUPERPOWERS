-- Released under GPL v3
--------------------------------------------------------------

--===============================================================================================
-- CITY PLOTS HANDLING
--===============================================================================================
local function GetClosestCity(player, plot)
	local newCity = nil;
	local newCityDist = 100000000;
    for city in player:Cities() do
		local dist = Map.PlotDistance(city:GetX(), city:GetY(), plot:GetX(), plot:GetY());
		if dist < newCityDist then
			newCity = city;
			newCityDist = dist
		end
    end
	return newCity;
end

-------------------------------------------------------------------------------------------------
local function GetForcedPlots(city)
	local forcedPlots = {};

	-- Save which plots were forcefully worked
	for i = 0, city:GetNumCityPlots() - 1, 1 do
		local plot = city:GetCityIndexPlot( i );
		local isForcedWorking = city:IsForcedWorkingPlot(plot);
		if isForcedWorking then
			table.insert(forcedPlots, plot);
		end
	end

	return forcedPlots;	
end

-------------------------------------------------------------------------------------------------
local function SetForcedPlots(city, forcedPlots)
	for _, v in ipairs(forcedPlots) do
		local index = city:GetCityPlotIndex(v);
		if index > 0 then
			if city:IsWorkingPlot(v) then
				city:AlterWorkingPlot(index);
			end
			city:AlterWorkingPlot(index);
		end
	end
end

-------------------------------------------------------------------------------------------------
local function UpdateOwnershipForCityPlot(player, city, plot)
	local forcedPlots = GetForcedPlots(city);

	-- Stop working that plot
	if city:IsWorkingPlot(plot) then
		city:AlterWorkingPlot(city:GetCityPlotIndex(plot));
	end

	-- Update ownership
	plot:SetOwner(-1);
	plot:SetOwner(player:GetID(), city:GetID(), true, true);

	city:DoTask(TaskTypes.TASK_CHANGE_WORKING_PLOT, 0, -1);
	--city:DoReallocateCitizens();
	SetForcedPlots(city, forcedPlots);
end

-------------------------------------------------------------------------------------------------
local function RemoveOwnershipForCityPlot(city, plot)
	local forcedPlots = GetForcedPlots(city);

	-- Stop working that plot
	if city:IsWorkingPlot(plot) then
		city:AlterWorkingPlot(city:GetCityPlotIndex(plot));
	end

	-- Update ownership
	plot:SetOwner(-1);

	city:DoTask(TaskTypes.TASK_CHANGE_WORKING_PLOT, 0, -1);
	--city:DoReallocateCitizens();
	SetForcedPlots(city, forcedPlots);
end

-------------------------------------------------------------------------------------------------
local function UpdateOwnership(plot)
	local owner = Players[plot:GetOwner()];
	if owner ~= nil then
		local city = plot:GetWorkingCity();

		if city and city:Plot() ~= plot then
			UpdateOwnershipForCityPlot(owner, city, plot);
		else
			plot:SetOwner(-1);
			plot:SetOwner(owner:GetID());
		end
	end
end

-------------------------------------------------------------------------------------------------
local function RemoveOwnership(plot)
	local owner = Players[plot:GetOwner()];
	if owner ~= nil then
		local city = plot:GetWorkingCity();
		if city then
			RemoveOwnershipForCityPlot(city, plot);
		else
			plot:SetOwner(-1);
		end
	end
end

-------------------------------------------------------------------------------------------------
local function AddOwnership(player, plot)
	if player ~= nil then
		local city = GetClosestCity(player, plot);
		local cityID = city and city:GetID() or -1;
		plot:SetOwner(player:GetID(), cityID, true, true);

		-- Reveal
		local playerTeamID = player:GetTeam();
		local hexpos = ToHexFromGrid(Vector2(plot:GetX(), plot:GetY()));
		Events.HexFOWStateChanged(hexpos, true, false);
		for neighbor in Neighbors(plot) do
			plot:SetRevealed(playerTeamID, true);
			plot:UpdateFog();
			hexpos = ToHexFromGrid(Vector2(plot:GetX(), plot:GetY()));
			Events.HexFOWStateChanged(hexpos, true, false);
		end
	end
end


--===============================================================================================
-- INVALIDATIONS AND COMMITS
--===============================================================================================
local invalidatedPlotsResources = {};
local invalidatedPlots = {};
local plotsToFog = {};

-------------------------------------------------------------------------------------------------
function InvalidateTerrain(plot, resourceChanged)
	if resourceChanged then
		table.insert(invalidatedPlotsResources, plot);
	end
	table.insert(invalidatedPlots, plot);
end

-------------------------------------------------------------------------------------------------
function CommitFogChanges()
	if #plotsToFog == 0 then return end
	print("commit fog changes")

	local pPlayer = Players[IGE.currentPlayerID];
	local playerTeamID = pPlayer:GetTeam();
	local width = Map.GetGridSize();
	local data = {};

	-- Init data with the current state
	for i = 0, Map.GetNumPlots()-1, 1 do
		local otherPlot = Map.GetPlotByIndex(i);
		data[i] = otherPlot:IsRevealed(playerTeamID, false);
	end

	-- Modify data
	for _, v in ipairs(plotsToFog) do
		local index = v:GetY() * width + v:GetX();
		data[index] = false;
	end

	-- Apply data
	FOW_SetAll(1);
	for i = 0, Map.GetNumPlots()-1, 1 do
		local plot = Map.GetPlotByIndex(i);
		plot:SetRevealed(playerTeamID, data[i]);
		plot:UpdateFog();
	end

	Game.UpdateFOW(true);
	UI:RequestMinimapBroadcast();
	plotsToFog = {};
end

-------------------------------------------------------------------------------------------------
function CommitTerrainChanges()
	if #invalidatedPlots == 0 then return end

	for i, pPlot in ipairs(invalidatedPlotsResources) do
		local playerID = pPlot:GetOwner();
		if playerID >= 0 then
			UpdateOwnership(pPlot);
		end
	end	

	for i, pPlot in ipairs(invalidatedPlots) do
		if pPlot:IsRevealed(IGE.currentTeamID, false) then
			pPlot:UpdateFog();
		end
		LuaEvents.IGE_ModifiedPlot(pPlot);
		for neighbor in Neighbors(pPlot) do
			LuaEvents.IGE_ModifiedPlot(neighbor);
		end
	end	

	Map.RecalculateAreas();
	invalidatedPlots = {};
	invalidatedPlotsResources = {};

	if IGE.revealMap then
		FOW_SetAll(0);
		Game.UpdateFOW(true);
		UI:RequestMinimapBroadcast();
	end
end

--===============================================================================================
-- COMPATIBILITY CHECKS
--===============================================================================================
local function MatchValidTerrainsAndFeatures(item, terrainID, featureID)
	-- Scroll through valid features compatible with the current terrain
	for _, feature in pairs(item.validFeatures) do
		if feature.validTerrains[terrainID] then
			if feature.ID == featureID then
				return true;
			end
		end
	end

	-- Scroll through terrains
	return item.validTerrains[terrainID];
end

-------------------------------------------------------------------------------------------------
function CanBeOcean(plot)
	-- Lands cannot become oceans
	if plot:GetPlotType() ~= PlotTypes.PLOT_OCEAN then 
		return false;
	end

	-- False if any neighbor is coastal land
	for neighbor in Neighbors(plot) do
		if neighbor:IsCoastalLand() then return false end
	end

	return true 
end

-------------------------------------------------------------------------------------------------
function CanBeOwner(player)
	if player.ID == -1 then return true end

	local row = Players[player.ID];
	if not row then return false end

	return row:IsAlive();
end

-------------------------------------------------------------------------------------------------
function CanHaveTerrain(plot, terrain)
	-- Oceans only for coastal lands.
	if terrain.ID == TerrainTypes.TERRAIN_OCEAN then
		return CanBeOcean(plot);

	else
		return true;
	end
end

-------------------------------------------------------------------------------------------------
function CanHaveNaturalWonder(plot, wonder)
	-- Gibraltar
	if wonder.type == "FEATURE_GIBRALTAR" then 
		return plot:IsCoastalLand() 
	end

	-- Krakatoa and Reef are on waters
	if wonder.type == "FEATURE_VOLCANO" or wonder.type == "FEATURE_REEF" then
		return plot:IsWater() and not plot:IsLake();
	end

	-- Others on firm lands
	return not plot:IsWater();
end

-------------------------------------------------------------------------------------------------
function CanHaveFeature(plot, feature)
	if feature.ID < 0 then return true end
	if feature.ID == FeatureTypes.FEATURE_FALLOUT then return true end

	local terrainID = plot:GetTerrainType();
	return feature.validTerrains[terrainID];
end

-------------------------------------------------------------------------------------------------
function CanHaveResource(plot, resource)
	if resource.ID < 0 then return true end

	local type = plot:GetPlotType();
	if type == PlotTypes.PLOT_HILLS and not resource.hills then 
		return false;
	end
	if type == PlotTypes.PLOT_LAND and not resource.flatLands then 
		return false;
	end

	local terrainID = plot:GetTerrainType();
	local featureID = plot:GetFeatureType();
	if not MatchValidTerrainsAndFeatures(resource, terrainID, featureID) then return false end

	return true;
end

-------------------------------------------------------------------------------------------------
function CanHaveImprovement(plot, improvement)
	if improvement.ID < 0 then return true end

	if improvement.hillsMakesValid then
		if plot:GetPlotType() == PlotTypes.PLOT_HILLS then return true end	-- Sheeps
	end

	if improvement.freshWaterMakesValid then
		if plot:IsFreshWater() then return true end	-- Farms
	end

	if improvement.requiresFlatlandsOrFreshWater then
		if not plot:IsFreshWater() then return false end
		if not plot:GetPlotType() == PlotTypes.PLOT_LAND then return false end
	end

	local terrainID = plot:GetTerrainType();
	local featureID = plot:GetFeatureType();
	if not MatchValidTerrainsAndFeatures(improvement, terrainID, featureID) then return false end

	if next(improvement.improvedResources) ~= nil then
		local resourceID = plot:GetResourceType();
		return improvement.improvedResources[resourceID] ~= nil;
	end

	return true;
end

--===============================================================================================
-- SETTERS
--===============================================================================================
local function CheckConsistency(plot)
	if plot:GetTerrainType() == TerrainTypes.TERRAIN_OCEAN then
		for neighbor in Neighbors(plot) do
			-- Any neighbor is land? Turn plot into coast, not ocean
			if neighbor:GetPlotType() ~= PlotTypes.PLOT_OCEAN then 
				plot:SetTerrainType(TerrainTypes.TERRAIN_COAST);
				InvalidateTerrain(plot, true);
				break
			end
		end
	elseif plot:GetPlotType() ~= PlotTypes.PLOT_OCEAN then
		for neighbor in Neighbors(plot) do
			if neighbor:GetTerrainType() == TerrainTypes.TERRAIN_OCEAN then 
				neighbor:SetTerrainType(TerrainTypes.TERRAIN_COAST);
				InvalidateTerrain(neighbor, true);
			end
		end
	end
end

-------------------------------------------------------------------------------------------------
function SetTerrain(terrain, plot)
	if plot then
		-- Want to set coast ? 
		if terrain.ID ~= plot:GetTerrainType() then
			if terrain.water then
				plot:SetPlotType(PlotTypes.PLOT_OCEAN);
			elseif plot:GetPlotType() == PlotTypes.PLOT_OCEAN then
				plot:SetPlotType(PlotTypes.PLOT_LAND);
			end

			plot:SetTerrainType(terrain.ID);
			CheckConsistency(plot)
			plot:SetArea(-1)

			local art = plot:GetContinentArtType()
			if (not art) or (art < 1) then
				plot:SetContinentArtType(1)
			end
			return true, true;
		end
	end
end

-------------------------------------------------------------------------------------------------
function SetPlotType(type, plot)
	if plot and plot:GetPlotType() ~= type then
		plot:SetPlotType(type.type);
		plot:SetArea(-1)
		CheckConsistency(plot)
		return true;
	end
end

-------------------------------------------------------------------------------------------------
function SetFoggy(plot)
	table.insert(plotsToFog, plot);
end

-------------------------------------------------------------------------------------------------
function SetFeature(feature, plot)
	if plot and plot:GetFeatureType() ~= feature.ID then
		local terrainType = plot:GetTerrainType();
		local isOcean = plot:IsWater() and not plot:IsLake();

		if feature.naturalWonder then
			if feature.type == "FEATURE_GEYSER" then
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS);

			elseif feature.type == "FEATURE_CRATER" then
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				if terrainType ~= TerrainTypes.TERRAIN_DESERT and terrainType ~= TerrainTypes.TERRAIN_TUNDRA then
					plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT);
				end

			elseif feature.type == "FEATURE_GIBRALTAR" then
				if not plot:IsCoastalLand() and not isOcean then return end
				plot:SetPlotType(PlotTypes.PLOT_LAND);
				plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS);

			elseif feature.type == "FEATURE_FUJI" then
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS);

			elseif feature.type == "FEATURE_MESA" then
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT);

			elseif feature.type == "FEATURE_REEF" then
				if not isOcean then return end
				plot:SetTerrainType(TerrainTypes.TERRAIN_COAST);

			elseif feature.type == "FEATURE_VOLCANO" then
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS);

			elseif feature.type == "FEATURE_FOUNTAIN_YOUTH" then
				plot:SetPlotType(PlotTypes.PLOT_LAND);
				plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS);

			elseif feature.type == "FEATURE_POTOSI" then
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS);

			elseif feature.type == "FEATURE_EL_DORADO" then
				plot:SetPlotType(PlotTypes.PLOT_LAND);
				plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS);

			else
				print("unknown wonder");
				plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN);
				plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS);
			end
			CheckConsistency(plot)
		end
		plot:SetFeatureType(feature.ID);
		plot:SetArea(-1)
		return true, true;
	end
end

-------------------------------------------------------------------------------------------------
function SetResource(resource, plot)
	if plot and (plot:GetResourceType() ~= resource.ID or plot:GetNumResource() ~= resource.qty) then
		plot:SetResourceType(resource.ID, resource.qty);
		plot:SetNumResource(resource.qty);
		return true, true
	end
end

-------------------------------------------------------------------------------------------------
function SetResourceQty(qty, plot)
	if plot and plot:GetNumResource() ~= qty then
		plot:SetNumResource(qty);
		return true, true
	end
end

-------------------------------------------------------------------------------------------------
function SetImprovement(improvement, plot)
	if plot and (plot:GetImprovementType() ~= improvement.ID or plot:IsImprovementPillaged() ~= IGE.pillaged) then
		plot:SetImprovementType(improvement.ID);
		plot:SetImprovementPillaged(IGE.pillaged);
		return true, true;
	end
end

-------------------------------------------------------------------------------------------------
function SetImprovementPillaged(value, plot)
	if plot and plot:IsImprovementPillaged() ~= value then
		plot:SetImprovementPillaged(value);
		return true, true;
	end
end

-------------------------------------------------------------------------------------------------
function SetRoute(route, plot)
	if plot and plot:GetRouteType() ~= route.ID then
		plot:SetRouteType(route.ID);
		return true;
	end
end

-------------------------------------------------------------------------------------------------
function SetContinentArt(art, plot)
	if plot and plot:GetContinentArtType() ~= art.ID then
		plot:SetContinentArtType(art.ID);
		return true;
	end
end

-------------------------------------------------------------------------------------------------
function SetFog(data, plot)
	if plot then
		local pPlayer = Players[IGE.currentPlayerID];
		local team = pPlayer:GetTeam();
		if data.value then
			SetFoggy(plot);
		else
			--plot:ChangeVisibilityCount(team, 1, -1, false, false);
			plot:SetRevealed(team, true);
		end
		Game.UpdateFOW(true);
		InvalidateTerrain(plot);
		return true;
	end
end

-------------------------------------------------------------------------------------------------
function SetOwnership(data, plot)
	if data.value then
		if Players[plot:GetOwner()] == IGE.currentPlayer then 
			return false 
		end
		AddOwnership(IGE.currentPlayer, plot);
	else
		if Players[plot:GetOwner()] ~= IGE.currentPlayer then 
			return false 
		end
		RemoveOwnership(plot);
	end
	return true;
end

--===============================================================================================
-- BACKUP / RESTORE / UNDO
--===============================================================================================
function BackupPlot(plot)
	local team = IGE.currentPlayer:GetTeam();

	local backup = {};
	backup.x = plot:GetX();
	backup.y = plot:GetY();
	backup.type = plot:GetPlotType();
	backup.terrain = plot:GetTerrainType();
	backup.feature = plot:GetFeatureType();
	backup.resource = plot:GetResourceType();
	backup.resourceQty = plot:GetNumResource();
	backup.improvement = plot:GetImprovementType();
	backup.pillaged = plot:IsImprovementPillaged();
	backup.route = plot:GetRouteType();
	backup.owner = plot:GetOwner();
	backup.art = plot:GetContinentArtType();
	backup.revealed = plot:IsRevealed(team);

	backup.rivers = {};
	for _, side in ipairs(RiverSides) do
		backup.rivers[side] = GetFlowRotation(plot, side);
	end

	return backup;
end

-------------------------------------------------------------------------------------------------
function RestorePlot(backup)
	--print("restore plot");
	local team = IGE.currentPlayer:GetTeam();
	local plot = Map.GetPlot(backup.x, backup.y);
	local resourceChanged = (plot:GetResourceType() ~= backup.resource) or (plot:GetNumResource() ~= backup.resourceQty) or (plot:GetPlotType() ~= backup.type);

	plot:SetPlotType(backup.type);
	plot:SetTerrainType(backup.terrain);
	plot:SetFeatureType(backup.feature);
	plot:SetResourceType(backup.resource);
	plot:SetNumResource(backup.resourceQty);
	plot:SetImprovementType(backup.improvement);
	plot:SetImprovementPillaged(backup.pillaged);
	plot:SetContinentArtType(backup.art);
	plot:SetRouteType(backup.route);
	CheckConsistency(plot)

	if (plot:GetOwner() ~= backup.owner) then
		RemoveOwnership(plot);
		local newOwner = Players[backup.owner];
		if (newOwner ~= nil) then
			AddOwnership(newOwner, plot);
		end
	else
		UpdateOwnership(plot);
	end

	if backup.revealed ~= plot:IsRevealed(team) then
		if backup.revealed then
			plot:SetRevealed(team, true);
		else 
			SetFoggy(plot);
		end
		Game.UpdateFOW(true);
	end

	for _, side in ipairs(RiverSides) do
		SetFlowRotation(plot, side, backup.rivers[side]);
	end

	LuaEvents.IGE_FlashPlot(plot);
	InvalidateTerrain(plot, resourceChanged);
end
