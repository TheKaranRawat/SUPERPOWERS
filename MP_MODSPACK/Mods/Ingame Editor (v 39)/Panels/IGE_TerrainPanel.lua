-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
include("IGE_API_Rivers");
include("IGE_API_Terrain");
print("IGE_TerrainPanel");
IGE = nil;

local groupManager = CreateInstanceManager("GroupInstance", "Stack", Controls.MainStack );
local routeItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.RouteList );
local improvementItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.ImprovementList );
local greatImprovementItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.GreatImprovementList );
local strategicResourceItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.StrategicResourceList );
local luxuryResourceItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.LuxuryResourceList );
local bonusResourceItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.BonusResourceList );
local naturalWonderItemManager= CreateInstanceManager("ListItemInstance", "Button", Controls.NaturalWonderList );
local waterItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.WaterList );
local terrainItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.TerrainList );
local featureItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.FeatureList );
local typeItemManager = CreateInstanceManager("TypeInstance", "Button", Controls.TypeList );
local artItemManager= CreateInstanceManager("ListItemInstance", "Button", Controls.ArtList );
local fogItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.FogList );
local ownershipItemManager = CreateInstanceManager("ListItemInstance", "Button", Controls.OwnershipList );

local redoStack = {};
local undoStack = {};
local groups = {};
local editData = {};
local paintData = {};
local currentPlot = nil;
local editSound = "AS2D_BUILD_UNIT";
local selectedStrategicResource = nil;
local clickHandler = nil;
local isEditing = true;
local isVisible = false;


--===============================================================================================
-- INITIALIZATION
--===============================================================================================
local function InitializeData(data)
	SetContinentArtsData(data,	{});
	SetTerrainsData(data,		{});
	SetPlotTypesData(data,		{});
	SetFeaturesData(data,		{ none=true });
	SetResourcesData(data,		{ none=true });
	SetImprovementsData(data,	{ none=true });
	SetRoutesData(data,			{ none=true });

	data.fogs = 
	{
		{ ID = 1, name = L("TXT_KEY_IGE_EXPLORED_SETTING"), visible = true, enabled = true, action = SetFog, value = false, help=L("TXT_KEY_IGE_EXPLORED_SETTING_HELP") },
		{ ID = 2, name = L("TXT_KEY_IGE_UNEXPLORED_SETTING"), visible = true, enabled = true, action = SetFog, value = true, help=L("TXT_KEY_IGE_UNEXPLORED_SETTING_HELP") },
	};
	data.ownerships = 
	{
		{ ID = 1, name = L("TXT_KEY_IGE_FREE_LAND_SETTING"), visible = true, enabled = true, action = SetOwnership, value = false, help=L("TXT_KEY_IGE_FREE_LAND_SETTING_HELP") },
		{ ID = 2, name = L("TXT_KEY_IGE_YOUR_LAND_SETTING"), visible = true, enabled = true, action = SetOwnership, value = true, help=L("TXT_KEY_IGE_YOUR_LAND_SETTING_HELP") },
	};
end

-------------------------------------------------------------------------------------------------
function CreateGroup(theControl, name)
	local theInstance = groupManager:GetInstance();
	if theInstance then
		theInstance.Header:SetText(name);
		theControl:ChangeParent(theInstance.List);
		groups[name] = { instance = theInstance, control = theControl, visible = true };
	end
end

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	print("IGE_TerrainPanel.OnInitialize");
	InitializeData(editData);
	InitializeData(paintData);

	currentPaintSelection = paintData.terrainsByTypes["TERRAIN_GRASS"];
	currentPaintSelection.selected = true;

	Resize(Controls.Container);
	Resize(Controls.PromptContainer);
	Resize(Controls.ScrollPanel);
	Resize(Controls.OuterContainer);
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 36);

	local othersName = L("TXT_KEY_IGE_OTHERS");
	CreateGroup(Controls.CoreContainer, L("TXT_KEY_IGE_TERRAIN"));
	CreateGroup(Controls.FeaturesStack, L("TXT_KEY_IGE_FEATURES_AND_WONDERS"));
	CreateGroup(Controls.ResourcesStack, L("TXT_KEY_IGE_RESOURCES"));
	CreateGroup(Controls.ImprovementsStack, L("TXT_KEY_IGE_IMPROVEMENTS"));
	CreateGroup(Controls.OthersContainer, othersName);
	groups[othersName].instance.Separator:SetHide(true);

	local tt = L("TXT_KEY_IGE_TERRAIN_EDIT_PANEL_HELP");
	LuaEvents.IGE_RegisterTab("TERRAIN_EDITION",  L("TXT_KEY_IGE_TERRAIN_EDIT_PANEL"), 0, "edit",  tt)

	local tt = L("TXT_KEY_IGE_TERRAIN_PAINT_PANEL_HELP");
	LuaEvents.IGE_RegisterTab("TERRAIN_PAINTING", L("TXT_KEY_IGE_TERRAIN_PAINT_PANEL"), 0, "paint", tt, currentPaintSelection)
	print("IGE_TerrainPanel.OnInitialize - Done");
end
LuaEvents.IGE_Initialize.Add(OnInitialize)


--===============================================================================================
-- CORE EVENTS
--===============================================================================================
function OnSelectedPanel(ID)
	if ID == "TERRAIN_EDITION" then
		isEditing = true;
		isVisible = true;
	elseif ID == "TERRAIN_PAINTING" then
		isEditing = false;
		isVisible = true;
	else
		isVisible = false;
	end
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel);

-------------------------------------------------------------------------------------------------
function ClickHandler(item)
	if isEditing then
		if currentPlot then
			Events.AudioPlay2DSound(editSound);	
			BeginUndoGroup();
			DoAction(currentPlot, item.action, item);
			CommitTerrainChanges();
			CommitFogChanges();
			OnUpdate();
		end
	else
		if currentPaintSelection then
			currentPaintSelection.selected = false;
		end
		currentPaintSelection = item;
		if currentPaintSelection then
			currentPaintSelection.selected = true;
		end
		LuaEvents.IGE_SetTabData("TERRAIN_PAINTING", item);
		OnUpdate();
	end
end

-------------------------------------------------------------------------------------------------
function OnPaintPlot(button, plot, shift)
	if isVisible and currentPaintSelection then
		Events.AudioPlay2DSound(editSound);	
		local item = currentPaintSelection;

		DoAction(plot, item.action, item);
		if shift then
			for neighbor in Neighbors(plot) do
				if currentPaintSelection:action(neighbor) then
					DoAction(neighbor, item.action, item);
				end
			end
		end

		CommitFogChanges();
		CommitTerrainChanges();
	end
end
LuaEvents.IGE_PaintPlot.Add(OnPaintPlot);

-------------------------------------------------------------------------------------------------
function OnBeginPaint()
	BeginUndoGroup();
end
LuaEvents.IGE_BeginPaint.Add(OnBeginPaint)

-------------------------------------------------------------------------------------------------
function OnSelectedPlot(plot)
	currentPlot = plot;
end
LuaEvents.IGE_SelectedPlot.Add(OnSelectedPlot)



--===============================================================================================
-- UNDO
--===============================================================================================
function BeginUndoGroup()
	table.insert(undoStack, {});
end

-------------------------------------------------------------------------------------------------
function Undo(stack, altStack)
	while true do
		if #stack == 0 then break end

		local set = stack[#stack];
		table.remove(stack, #stack);

		if #set > 0 then
			local altSet = {};
			table.insert(altStack, altSet);

			for i = #set, 1, -1 do
				local backup = set[i];
				local plot = Map.GetPlot(backup.x, backup.y);
				local altBackup = BackupPlot(plot);
				table.insert(altSet, altBackup);
				RestorePlot(backup);
			end
			break;
		end
	end

	CommitTerrainChanges();
	CommitFogChanges();
	LuaEvents.IGE_Update();
end

-------------------------------------------------------------------------------------------------
function DoAction(plot, func, arg, invalidate)
	if invalidate == nil then 
		invalidate = true;
	end

	local backup = BackupPlot(plot);
	local changed, resourceChanged = func(arg, plot)
	if changed then
		if invalidate then
			InvalidateTerrain(plot, resourceChanged);
		end
		table.insert(undoStack[#undoStack], backup);
	end
end

-------------------------------------------------------------------------------------------------
function OnUndo()
	if not isVisible then return end
	Undo(undoStack, redoStack);	
end
LuaEvents.IGE_Undo.Add(OnUndo);

-------------------------------------------------------------------------------------------------
function OnRedo()
	if not isVisible then return end
	Undo(redoStack, undoStack);	
end
LuaEvents.IGE_Redo.Add(OnRedo);

-------------------------------------------------------------------------------------------------
function OnPushUndoStack(set)
	if not isVisible then return end
	table.insert(undoStack, set);
end
LuaEvents.IGE_PushUndoStack.Add(OnPushUndoStack);


--===============================================================================================
-- UPDATE
--===============================================================================================
function UpdateStatusForPlot(plot)
	local selected = nil;

	-- Terrains
	local terrainID = plot:GetTerrainType();
	for i, v in pairs(editData.terrains) do
		v.enabled = CanHaveTerrain(plot, v);
		v.selected = (terrainID == v.ID);
		if v.selected then selected = v end
	end

	-- Water terrains
	for i, v in pairs(editData.waterTerrains) do
		v.enabled = CanHaveTerrain(plot, v);
		v.note = v.enabled and BUG_NoGraphicalUpdate or BUG_SavegameCorruption;
		v.selected = (terrainID == v.ID);
		if v.selected then selected = v end
	end

	-- Types
	local plotType = plot:GetPlotType();
	for i, v in pairs(editData.types) do
		v.selected = (plotType == v.type);
	end

	-- Features
	local featureID = plot:GetFeatureType();
	for i, v in pairs(editData.features) do 
		v.enabled = CanHaveFeature(plot, v);
		v.selected = (featureID == v.ID);
	end

	-- Natural wonders
	for k, v in pairs(editData.naturalWonders) do 
		v.enabled = CanHaveNaturalWonder(plot, v);
		v.selected = (featureID == v.ID);
	end

	-- Resources
	local resourceID = plot:GetResourceType();
	local numResource = plot:GetNumResource();
	for k, v in pairs(editData.allResources) do 
		v.enabled = CanHaveResource(plot, v);
		v.selected = (resourceID == v.ID);

		if v.selected and v.usage == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC then
			v.qty = numResource;
		end
	end

	-- Improvements
	local improvementID = plot:GetImprovementType();
	for k, v in pairs(editData.improvements) do 
		v.enabled = CanHaveImprovement(plot, v);
		v.selected = (improvementID == v.ID);
	end

	-- Great improvements
	for k, v in pairs(editData.greatImprovements) do 
		v.enabled = CanHaveImprovement(plot, v);
		v.selected = (improvementID == v.ID);
	end

	-- Routes
	local routeID = plot:GetRouteType();
	for k, v in pairs(editData.routes) do 
		v.enabled = (plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS);
		v.selected = (routeID == v.ID);
	end

	-- Continent Arts
	local artID = plot:GetContinentArtType();
	for k, v in pairs(editData.continentArts) do 
		v.selected = (artID == v.ID);
	end

	local isOwner = (plot:GetOwner() == IGE.currentPlayerID);
	editData.ownerships[1].selected = not isOwner;
	editData.ownerships[2].selected = isOwner;

	local team = Players[IGE.currentPlayerID]:GetTeam();
	local visible = plot:IsRevealed(team, false);
	editData.fogs[2].selected = not visible;
	editData.fogs[1].selected = visible;


	local variety = plot:GetFeatureVariety();
	IGE.pillaged = plot:IsImprovementPillaged();
end

-------------------------------------------------------------------------------------------------
local function UpdateCore(data)
	-- Strategic resources
	selectedStrategicResource = GetSelection(data.strategicResources);
	Controls.ResourceAmountGrid:SetHide(selectedStrategicResource == nil);
	Controls.ResourceAmountLabel:SetText(selectedStrategicResource and selectedStrategicResource.iconString or "");
	UpdateResourceAmount(GetResourceAmount());

	-- Pillaged improvement
	local selectedImprovement = GetSelection(data.improvements) or GetSelection(data.greatImprovements);
	if selectedImprovement and selectedImprovement.ID == -1 then selectedImprovement = nil end

	Controls.PillageCB:SetCheck(IGE.pillaged);
	Controls.PillageCB:SetHide(selectedImprovement == nil);

	-- Update lists
	UpdateGeneric(data.types,				typeItemManager,				ClickHandler);
	UpdateList(data.features,				featureItemManager,				ClickHandler);
	UpdateList(data.terrains,				terrainItemManager,				ClickHandler);
	UpdateList(data.waterTerrains,			waterItemManager,				ClickHandler);
	UpdateList(data.naturalWonders,			naturalWonderItemManager,		ClickHandler);
	UpdateList(data.bonusResources,			bonusResourceItemManager,		ClickHandler);
	UpdateList(data.luxuryResources,		luxuryResourceItemManager,		ClickHandler);
	UpdateList(data.strategicResources,		strategicResourceItemManager,	ClickHandler);
	UpdateList(data.greatImprovements,		greatImprovementItemManager,	ClickHandler);
	UpdateList(data.improvements,			improvementItemManager,			ClickHandler);
	UpdateList(data.routes,					routeItemManager,				ClickHandler);
	UpdateList(data.fogs,					fogItemManager,					ClickHandler);
	UpdateList(data.ownerships,				ownershipItemManager,			ClickHandler);
	UpdateList(data.continentArts,			artItemManager,					ClickHandler);

	-- Resize
	Controls.ImprovementsInnerStack:CalculateSize();
	Controls.ImprovementsInnerStack:ReprocessAnchoring();

	Controls.StrategicResourceStack:CalculateSize();
	Controls.StrategicResourceStack:ReprocessAnchoring();

	-- Update elements visibility
	local selectedLand = GetSelection(data.terrains);
	local isWaterPlot = isEditing and (selectedLand == nil);
	Controls.RiversElement:SetHide(isWaterPlot or not isEditing);
	Controls.TypeList:SetHide(isWaterPlot);
	Controls.ArtList:SetHide(isWaterPlot);

	local selectionPrompt = isEditing and (currentPlot == nil);
	Controls.PromptContainer:SetHide(not selectionPrompt);
	Controls.ScrollPanel:SetHide(selectionPrompt);

	-- Update groups size
	local groupCount = 0;
	for k, v in pairs(groups) do
		v.instance.Stack:SetHide(not v.visible);
		if v.visible then
			if v.control.CalculateSize then
				v.control:CalculateSize();
			end
			local width = v.control:GetSizeX();
			v.instance.Stack:SetSizeX(width + 20);
			v.instance.HeaderBackground:SetSizeX(width + 20);
			v.instance.List:SetOffsetX(10);
			groupCount = groupCount + 1;
		end
	end

	-- Adjust padding to cover the whole length
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();

	local diff = Controls.MainStack:GetSizeX() - Controls.Container:GetSizeX();
	local offset = (diff < 0) and 10 - diff / (2 * groupCount) or 10;
	for k, v in pairs(groups) do
		local width = v.control:GetSizeX();
		v.instance.Stack:SetSizeX(width + 2 * offset);
		v.instance.HeaderBackground:SetSizeX(width + 2 * offset);
		v.instance.List:SetOffsetX(offset);
	end

	-- Update scroll bar
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();
    Controls.ScrollPanel:CalculateInternalSize();
end

-------------------------------------------------------------------------------------------------
function OnUpdate()
	Controls.OuterContainer:SetHide(not isVisible);
	Controls.RiversElement:SetHide(true);
	OnResizedReseedElement(0, 0)

	if isEditing then
		if not isVisible then return end
		LuaEvents.IGE_SetMouseMode(IGE_MODE_EDIT);

		Controls.PromptContainer:SetHide(currentPlot ~= nil);
		Controls.Container:SetHide(currentPlot == nil);
		if not currentPlot then return end

		UpdateStatusForPlot(currentPlot);
		UpdateCore(editData);
	else
		if not isVisible then return end
		LuaEvents.IGE_SetMouseMode(currentPaintSelection and IGE_MODE_PAINT or IGE_MODE_NONE);

		Controls.PromptContainer:SetHide(true);
		Controls.Container:SetHide(false);
		UpdateCore(paintData);
	end
end
LuaEvents.IGE_Update.Add(OnUpdate);

-------------------------------------------------------------------------------------------------
function OnResizedReseedElement(w, h)
	Controls.PromptLabelContainer:SetSizeX(Controls.PromptContainer:GetSizeX() - (w + 40));
	Controls.PromptLabelContainer:SetSizeY(Controls.PromptContainer:GetSizeY());
	Controls.PromptLabelContainer:ReprocessAnchoring();
	Controls.PromptContainer:ReprocessAnchoring();
end
LuaEvents.IGE_ResizedReseedElement.Add(OnResizedReseedElement)

--===============================================================================================
-- CONTROLS EVENTS
--===============================================================================================
function GetResourceAmount()
	return selectedStrategicResource and selectedStrategicResource.qty or 1;
end

-------------------------------------------------------------------------------------------------
function SetResourceAmount(amount, userInteraction)
	if selectedStrategicResource then
		selectedStrategicResource.qty = amount;

		if isEditing then
			if currentPlot and userInteraction then
				BeginUndoGroup();
				DoAction(currentPlot, SetResourceQty, amount, false);
			end
		end
	end
end
UpdateResourceAmount = HookNumericBox("ResourceAmount", GetResourceAmount, SetResourceAmount, 1, nil, 1);

-------------------------------------------------------------------------------------------------
function OnPillageCBChanged()
	if isEditing and currentPlot then
		IGE.pillaged = Controls.PillageCB:IsChecked();

		BeginUndoGroup();
		DoAction(currentPlot, SetImprovementPillaged, IGE.pillaged, false);
	end
end
Controls.PillageCB:RegisterCallback(Mouse.eLClick, OnPillageCBChanged);



