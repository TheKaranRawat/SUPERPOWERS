-- Released under GPL v3
--------------------------------------------------------------
include("IconSupport");
include("InstanceManager");
include("RSD_Utils");
local riverManager = InstanceManager:new("IgeRiverInstance", "Anchor", Controls.RiverContainer);
local cityManager = InstanceManager:new("IgeCityInstance", "Anchor", Controls.CityContainer);
local hexManager = InstanceManager:new("IgeHexInstance", "Anchor", Controls.HexContainer);
local fogManager = InstanceManager:new("IgeFogInstance", "Anchor", Controls.FogContainer);
local riverInstances = {}
local cityInstances = {}
local hexInstances = {}
local fogInstances = {}
local highlights = {}
local debugVisible = {}

local width, height = Map.GetGridSize()
local initialized = false
local opened = false
local IGE = {};

local terrains = {}
terrains[TerrainTypes.TERRAIN_COAST] = "IgeCoast.dds";
terrains[TerrainTypes.TERRAIN_OCEAN] = "IgeOcean.dds";
terrains[TerrainTypes.TERRAIN_GRASS] = "IgeGrass.dds";
terrains[TerrainTypes.TERRAIN_PLAINS] = "IgePlains.dds";
terrains[TerrainTypes.TERRAIN_DESERT] = "IgeDesert.dds";
terrains[TerrainTypes.TERRAIN_TUNDRA] = "IgeTundra.dds";
terrains[TerrainTypes.TERRAIN_SNOW] = "IgeSnow.dds";

local types = {}
types[PlotTypes.PLOT_LAND] = {}
types[PlotTypes.PLOT_HILLS] = {}
types[PlotTypes.PLOT_MOUNTAIN] = {}
types[PlotTypes.PLOT_OCEAN] = {}

types[PlotTypes.PLOT_HILLS][-1] = "sv_hills.dds"
types[PlotTypes.PLOT_HILLS][TerrainTypes.TERRAIN_SNOW] = "sv_hills_on_snow.dds"
types[PlotTypes.PLOT_HILLS][TerrainTypes.TERRAIN_TUNDRA] = "sv_hills_on_tundra.dds"

types[PlotTypes.PLOT_MOUNTAIN][-1] = "sv_mountains.dds"
types[PlotTypes.PLOT_MOUNTAIN][TerrainTypes.TERRAIN_SNOW] = "sv_mountains_on_snow.dds"

local features = {};
local isWonder = {}
for row in GameInfo.Features() do
	features[row.ID] = {}
	isWonder[row.ID] = row.NaturalWonder;
	if row.ArtDefineTag and row.ArtDefineTag ~= "" then
		for subRow in GameInfo.ArtDefine_StrategicView{StrategicViewType=row.ArtDefineTag} do
			features[row.ID][-1] = subRow.Asset;
		end
	end
end
--features[FeatureTypes.FEATURE_FOREST][TerrainTypes.TERRAIN_PLAINS] = "sv_forest_on_plains.dds";
features[-1] = {};

local resources = {};
for row in GameInfo.Resources() do
	if row.ArtDefineTag and row.ArtDefineTag ~= "" then
		for subRow in GameInfo.ArtDefine_StrategicView{StrategicViewType=row.ArtDefineTag} do
			resources[row.ID] = subRow.Asset;
		end
	end
end

local improvements = {};
for row in GameInfo.Improvements() do
	if row.ArtDefineTag and row.ArtDefineTag ~= "" then
		for subRow in GameInfo.ArtDefine_StrategicView{StrategicViewType=row.ArtDefineTag} do
			improvements[row.ID] = subRow.Asset;
		end
	end
end

local civilianUnits = {};
local militaryUnits = {}
for row in GameInfo.Units() do
	if row.CombatClass then
		militaryUnits[row.ID] = { tex=row.UnitFlagAtlas, offset=row.UnitFlagIconOffset };
	else
		civilianUnits[row.ID] = { tex=row.UnitFlagAtlas, offset=row.UnitFlagIconOffset };
	end
end


local function GetPlotIndex(plot)
	return plot:GetY() * width + plot:GetX()
end


-------------------------------------------------------------------------------------------------
-- VERTICES	  		 SIDES
--     0			   .
--	 /	 \			 0   5
--  1     5	       .       .
--	|	  |		   1       4
--  2     4		   .       .
--	 \	 /			 2   3
--     3               .
-------------------------------------------------------------------------------------------------
local function HasRiverOnSide(plot, index)
	index = (index + 6 ) % 6
	if index == 0 then -- NW
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_NORTHWEST)
		return other and other:IsNWOfRiver()
	elseif index == 1 then -- W
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_WEST)
		return other and other:IsWOfRiver()
	elseif index == 2 then -- SW
		return plot:IsNEOfRiver()
	elseif index == 3 then -- SE
		return plot:IsNWOfRiver()
	elseif index == 4 then -- E
		return plot:IsWOfRiver()
	else -- NE
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_NORTHEAST)
		return other and other:IsNEOfRiver()
	end
end

-------------------------------------------------------------------------------------------------
local function HasVertexOutgoingRiver(plot, index)
	index = (index + 6 ) % 6
	if index == 0 then -- N
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_NORTHWEST)
		return other and other:IsWOfRiver();
	elseif index == 1 then -- NW
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_NORTHWEST)
		return other and other:IsNEOfRiver();
	elseif index == 2 then -- SW
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_WEST)
		return other and other:IsNWOfRiver();
	elseif index == 3 then -- S
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST)
		return other and other:IsWOfRiver();
	elseif index == 4 then -- SE
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_EAST)
		return other and other:IsNEOfRiver();
	else -- NE
		local other = Map.PlotDirection(plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_NORTHEAST)
		return other and other:IsNWOfRiver()
	end
end

-------------------------------------------------------------------------------------------------
local function IsNeighborWater(plot, direction)
	local other = Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
	return other and other:IsWater();
end

-------------------------------------------------------------------------------------------------
-- Returns 0 if no river should be displayed (may have a river displayed by another plot)
-- Returns "x3" if a three-edges connection should be displayed 
-- Returns "x2" if a two-edges connection should be displayed \__/
-- Returns "cws"  if a river source is present in CW direction
-- Returns "ccws" if a river source is present in CCW direction
-- Returns "cwe"  if a river ending is present in CW direction
-- Returns "ccwe" if a river ending is present in CCW direction
-------------------------------------------------------------------------------------------------
local vertexCWDirection = {};
vertexCWDirection[0] = DirectionTypes.DIRECTION_NORTHWEST;
vertexCWDirection[1] = DirectionTypes.DIRECTION_WEST;
vertexCWDirection[2] = DirectionTypes.DIRECTION_SOUTHWEST;
vertexCWDirection[3] = DirectionTypes.DIRECTION_SOUTHEAST;
vertexCWDirection[4] = DirectionTypes.DIRECTION_EAST;
vertexCWDirection[5] = DirectionTypes.DIRECTION_NORTHEAST;

local function GetRiverStatusForVertex(plot, index)
	index = (index + 6 ) % 6
	local after = HasRiverOnSide(plot, index)
	local before = HasRiverOnSide(plot, index - 1)
	local outgoing = HasVertexOutgoingRiver(plot, index)

	-- No river on the edges
	if (not after) and (not before) then return 0 end

	-- Three-way connection
	if after and before and outgoing then 
		if index > 1 then return 0 end
		return "x3" 
	end

	-- Two-way connection
	if after and before then return "x2" end

	-- River on one side only, continued in another plot: this other plot will display it, do nothing now
	if outgoing then return 0 end

	-- River stops here, is it a source or an ending?
	if before then
		if index > 2 then return 0 end
		return IsNeighborWater(plot, vertexCWDirection[index]) and "cwe" or "cws";
	else
		if index > 1 and index ~= 5 then return 0 end
		return IsNeighborWater(plot, vertexCWDirection[(index + 5) % 6]) and "ccwe" or "ccws";
	end
end

-- Set coordinates for IgeRivers.dds. Look at this file first to understand.
-------------------------------------------------------------------------------------------------

-- First store the position to align sources on vertices. Convention: during a CW rotation, the ending is the head and the source the tail
local riverSources = {}		
riverSources[0] = { x = 149,	y = 751 }
riverSources[1] = { x = 450,	y = 452 }
riverSources[2] = { x = 755,	y = 450 }
riverSources[3] = { x = 150,	y = 449 }
riverSources[4] = { x = 451,	y = 752 }
riverSources[5] = { x = 754,	y = 150 }

-- Compute endings from sources
local riverEndings = {}
for i = 0, 5, 1 do
	local angle = (2 * i - 1) * math.pi / 6;
	local c = math.cos(angle);
	local s = math.sin(angle);
	local r = 115;

	riverEndings[i] = { 
		x = riverSources[i].x + r * c, 
		y = riverSources[i].y - r * s 
	};
end

-- Assign all coordinates
local riverTextures = {};
local riverImagesLocations = {};
for i = 0, 5, 1 do 
	local angle = (2 * i + 3) * math.pi / 6;
	local c = math.cos(angle);
	local s = math.sin(angle);

	riverTextures[i] = {};
	riverImagesLocations[i] = { x = 208 * c,	y = -208 * s }

	-- Three-edges intersection
	if (i % 2) == 0 then
		riverTextures[i].x3 = { x = 151,		y = 147 }
	else
		riverTextures[i].x3 = { x = 453,		y = 152 }
	end

	-- Two edges intersection
	riverTextures[i].x2 = { x = 750 + 125 * c,	y = 750 - 125 * s };

	-- Sources and endings
	riverTextures[i].cws =  riverSources[i]
	riverTextures[i].ccwe = riverEndings[(i + 1) % 6]
	riverTextures[i].cwe =  riverEndings[(i + 3) % 6]
	riverTextures[i].ccws = riverSources[(i + 4) % 6]
end

-- Fix coordinates: so far we provided centers but we need their top left corners.
local processed = {}
for i = 0, 5, 1 do
	for _, v in pairs(riverTextures[i]) do
		if not processed[v] then
			processed[v] = true;
			v.x = v.x - 70		
			v.y = v.y - 70		
		end
	end
end


-------------------------------------------------------------------------------------------------
local resourcesVisibility = {}
local function UpdateResourceVisibility()
	local player = Players[Game.GetActivePlayer()];
	local team = Teams[player:GetTeam()];

	for row in GameInfo.Resources() do
		if IGE.showUnknownResources or (not row.TechReveal) then
			resourcesVisibility[row.ID] = true
		else
			local tech = GameInfoTypes[row.TechReveal];
			resourcesVisibility[row.ID] = team:GetTeamTechs():HasTech(tech);
		end
	end
end

-------------------------------------------------------------------------------------------------
local function UpdateUnit(instance, unit, isCivilian, hasManyUnits)
	local prefix = isCivilian and "Civilian" or "Military"
	local manyStatus1 = instance[prefix.."ManyStatus1"]
	local manyStatus2 = instance[prefix.."ManyStatus2"]
	local status1 = instance[prefix.."Status1"]
	local status2 = instance[prefix.."Status2"]
	local icon = instance[prefix.."Icon"]

	manyStatus1:SetHide(not hasManyUnits)
	manyStatus2:SetHide(not hasManyUnits)
	status1:SetHide(not unit)
	status2:SetHide(not unit)
	icon:SetHide(not unit)
	if not unit then return end

	local texInfo = isCivilian and civilianUnits[unit:GetUnitType()] or militaryUnits[unit:GetUnitType()]
	IconHookup(texInfo.offset, 32, texInfo.tex, icon)

	local statusTexture = unit:IsEmbarked() and "unitflagembark.dds" or (unit:IsGarrisoned() and "unitflagfortify.dds" or (isCivilian and "unitflagciv.dds" or "unitflagbase.dds"))
	status1:SetTexture(statusTexture)
	status2:SetTexture(statusTexture)

	local owner = Players[unit:GetOwner()]
	local color1, color2 = owner:GetPlayerColors();
	if owner:IsMinorCiv() then
		color1, color2 = color2, color1
	end
	status1:SetColor(color2)
	status2:SetColor(color1)
	icon:SetColor(color1)

	if hasManyUnits then
		manyStatus1:SetTexture(statusTexture)
		manyStatus2:SetTexture(statusTexture)
		manyStatus1:SetColor(color2)
		manyStatus2:SetColor(color1)
	end
end

-------------------------------------------------------------------------------------------------
local startingPlots = {};
local function UpdatePlotCore(plot, instance, riverInstance, cityInstance, fogInstance)
	-- Terrain or fog
	local index = GetPlotIndex(plot)
	local revealed = plot:IsRevealed(Game.GetActiveTeam(), false) or debugVisible[index]
	riverInstance.Anchor:SetHide(not revealed)
	cityInstance.Anchor:SetHide(not revealed)
	instance.Anchor:SetHide(not revealed)
	fogInstance.Anchor:SetHide(revealed)

	if revealed then
		-- Terrain
		instance.Terrain:SetTexture(terrains[plot:GetTerrainType()])

		-- Hills / moutains
		if not isWonder[plot:GetFeatureType()] then
			local typeTexture = types[plot:GetPlotType()][plot:GetTerrainType()] or types[plot:GetPlotType()][-1];
			instance.Type:SetHide(not typeTexture);
			instance.Type:SetTexture(typeTexture);
		else
			instance.Type:SetHide(true);
		end

		-- Features and natural wonders
		local featureTexture = features[plot:GetFeatureType()][plot:GetTerrainType()] or features[plot:GetFeatureType()][-1];
		instance.Feature:SetHide(not featureTexture);
		instance.Feature:SetTexture(featureTexture);

		-- Resources
		if resourcesVisibility[plot:GetResourceType()] then
			local resourceTexture = resources[plot:GetResourceType()];
			instance.Resource:SetHide(not resourceTexture);
			instance.Resource:SetTexture(resourceTexture);
		else
			instance.Resource:SetHide(true);
		end

		-- Improvement
		local improvementTexture = improvements[plot:GetImprovementType()];
		instance.Improvement:SetHide(not improvementTexture);
		instance.Improvement:SetTexture(improvementTexture);

		-- Highlight
		local color = highlights[index]
		instance.Highlight:SetHide(not color)
		if color then instance.Highlight:SetColor(color) end

		-- City
		cityInstance.City:SetHide(not plot:GetPlotCity())

		-- Units
		local topCivilian = nil
		local topMilitary = nil
		local civilianCount = 0
		local militaryCount = 0
		for i = 0, plot:GetNumUnits() - 1 do
			local unit = plot:GetUnit(i)
			if unit and not unit:IsDead() then
				local unitType = unit:GetUnitType()
				if civilianUnits[unitType]then
					civilianCount = civilianCount + 1
					topCivilian = unit
				elseif militaryUnits[unitType] then
					militaryCount = militaryCount + 1
					topMilitary = unit
				end
			end
		end
		UpdateUnit(cityInstance, topCivilian, true, civilianCount > 1)
		UpdateUnit(cityInstance, topMilitary, false, militaryCount > 1)
	end

	-- Rivers
	for i = 0, 5, 1 do
		local ctl = riverInstance["Vertex"..i];
		local status = GetRiverStatusForVertex(plot, i);
		local texCoords = riverTextures[i][status];
		if texCoords then
			--print(plot:GetX(), plot:GetY(), i, status);
			ctl:SetTextureOffsetVal(riverTextures[i][status].x, riverTextures[i][status].y)
		end
		ctl:SetHide(status == 0);
	end
end

-------------------------------------------------------------------------------------------------
function UpdateCore()
	if ContextPtr:IsHidden() or (not IGE) then return end
	UpdateResourceVisibility();

	if not initialized then 
		Initialize() 
		initialized = true
	end

	-- Collect players' colors and starting plots
	startingPlots = {};
	for i = 0, GameDefines.MAX_CIV_PLAYERS, 1 do
		local player = Players[i];
		if player:IsEverAlive() then
			if player:GetStartingPlot() then
				startingPlots[player:GetStartingPlot()] = player;
			end
		end
	end

	-- Update plots
	for i = 0, Map.GetNumPlots()-1, 1 do
		UpdatePlotCore(Map.GetPlotByIndex(i), hexInstances[i], riverInstances[i], cityInstances[i], fogInstances[i])
	end
end
Events.GameplaySetActivePlayer.Add(UpdateCore);

-------------------------------------------------------------------------------------------------
function Initialize()
	for i = 0, Map.GetNumPlots()-1, 1 do
		local plot = Map.GetPlotByIndex(i);
		hexInstances[i] = hexManager:GetInstance()
		cityInstances[i] = cityManager:GetInstance()
		riverInstances[i] = riverManager:GetInstance()
		fogInstances[i] = fogManager:GetInstance()

		local wx, wy, wz = GridToWorld(plot:GetX(), plot:GetY());
		hexInstances[i].Anchor:SetWorldPositionVal(wx, wy, 0);
		cityInstances[i].Anchor:SetWorldPositionVal(wx, wy, 0);
		riverInstances[i].Anchor:SetWorldPositionVal(wx, wy, 0);
		fogInstances[i].Anchor:SetWorldPositionVal(wx, wy, 0);

		for j = 0, 5, 1 do
			local ctl = riverInstances[i]["Vertex"..j];
			ctl:SetOffsetVal(riverImagesLocations[j].x, riverImagesLocations[j].y);
			ctl:SetSizeVal(238, 238);
		end

		hexInstances[i].Type:SetSizeVal(425, 425);
		hexInstances[i].Feature:SetSizeVal(425, 425);
		hexInstances[i].Resource:SetSizeVal(148, 148);
		hexInstances[i].Resource:SetTextureOffsetVal(40, 40);
		hexInstances[i].Improvement:SetSizeVal(148, 148);
		hexInstances[i].Improvement:SetTextureOffsetVal(40, 40);
		hexInstances[i].Highlight:SetSizeVal(402, 402);

		cityInstances[i].City:SetSizeVal(425, 425);

		cityInstances[i].MilitaryManyStatus1:SetSizeVal(200, 200)
		cityInstances[i].MilitaryManyStatus2:SetSizeVal(200, 200)
		cityInstances[i].MilitaryStatus1:SetSizeVal(200, 200)
		cityInstances[i].MilitaryStatus2:SetSizeVal(200, 200)
		cityInstances[i].MilitaryIcon:SetSizeVal(150, 150)

		cityInstances[i].CivilianManyStatus1:SetSizeVal(200, 200)
		cityInstances[i].CivilianManyStatus2:SetSizeVal(200, 200)
		cityInstances[i].CivilianStatus1:SetSizeVal(200, 200)
		cityInstances[i].CivilianStatus2:SetSizeVal(200, 200)
		cityInstances[i].CivilianIcon:SetSizeVal(128, 128)
	end
end

-------------------------------------------------------------------------------------------------
function UpdatePlot(plot)
	if ContextPtr:IsHidden() or (not initialized) then return end
	local index = GetPlotIndex(plot)
	UpdatePlotCore(plot, hexInstances[index], riverInstances[index], cityInstances[index], fogInstances[index])
end
LuaEvents.IGE_ModifiedPlot.Add(UpdatePlot);

-------------------------------------------------------------------------------------------------
local function OnHexFogEvent(hexPos, fogState, bWholeMap)
	if bWholeMap then 
		for i = 0, Map.GetNumPlots()-1, 1 do
			local plot = Map.GetPlotByIndex(i);
			local index = GetPlotIndex(plot)
			debugVisible[index] = (fogState == 2)
		end
		UpdateCore()
	else
		local x, y = ToGridFromHex(hexPos.x, hexPos.y);
		local plot = Map.GetPlot(x, y);
		local index = GetPlotIndex(plot)
		debugVisible[index] = (fogState == 2)
		UpdatePlot(plot)
	end
end
Events.HexFOWStateChanged.Add(OnHexFogEvent);

-------------------------------------------------------------------------------------------------
local function OnHexHighlight(hexPos, bFlag, color)
	local x, y = ToGridFromHex(hexPos.x, hexPos.y);
	local plot = Map.GetPlot(x, y);
	local index = GetPlotIndex(plot)
	highlights[index] = color
	UpdatePlot(plot)
end
Events.SerialEventHexHighlight.Add(OnHexHighlight)

-------------------------------------------------------------------------------------------------
local function OnClearHighlights(abc)
	for index in pairs(highlights) do
		highlights[index] = false
		UpdatePlot(Map.GetPlotByIndex(index))
	end
	highlights = {}
end
Events.ClearHexHighlights.Add(OnClearHighlights)

-------------------------------------------------------------------------------------------------
local function CheckVisibility()
	local visible = opened and InStrategicView() and IGE and not IGE.disableStrategicView
	if visible == not ContextPtr:IsHidden() then return end
	ContextPtr:SetHide(not visible)
	UpdateCore()
	return true
end
Events.StrategicViewStateChanged.Add(CheckVisibility);

-------------------------------------------------------------------------------------------------
local function OnOptionsChanged()
	if not CheckVisibility() then UpdateCore() end
end
LuaEvents.IGE_UpdatedOptions.Add(OnOptionsChanged);

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
	CheckVisibility()
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnShowing()
	opened = true
	CheckVisibility()
end
LuaEvents.IGE_Showing.Add(OnShowing)

-------------------------------------------------------------------------------------------------
local function OnClosing()
	opened = false
	CheckVisibility()
end
LuaEvents.IGE_Closing.Add(OnClosing)

