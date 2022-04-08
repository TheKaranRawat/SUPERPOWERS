-- Released under GPL v3
--------------------------------------------------------------
include("IGE_Utils");
include("IconSupport");
include("InstanceManager");
include("PlotMouseoverInclude");
include("ResourceTooltipGenerator");
print("loaded");
IGE = nil;

local yieldManager = InstanceManager:new("OverlayYieldInstance", "Anchor", Controls.OverlayYieldContainer);
local yieldImageManager = InstanceManager:new("OverlayYieldImageInstance", "Image", Controls.OverlayYieldImageScrap);
local resourceManager = InstanceManager:new("OverlayResourceInstance", "Anchor", Controls.OverlayResourceContainer);

local cultureTexture = "YieldAtlas_128_Culture.dds";
local defaultTexture = "YieldAtlas.dds";
local initialized = false;
local opened = false;

local debugVisible = {}
local plotInstances = {};
local resourceInstances = {};
local width, height = Map.GetGridSize();

local function GetPlotIndex(plot)
	return plot:GetY() * width + plot:GetX()
end

--===============================================================================================
-- PLOT TOOLTIP
--===============================================================================================
local tipControls = {};
TTManager:GetTypeControlTable( "HexDetails", tipControls );

local function GetUnitsString(plot)
	local strUnitText = "";

	local iActiveTeam = Game.GetActiveTeam();
	local pTeam = Teams[iActiveTeam];
	local bIsDebug = Game.IsDebugMode();
	
	-- Loop through all units
	local numUnits = plot:GetNumUnits();
	for i = 0, numUnits do
		local unit = plot:GetUnit(i);
		if unit then
			if strUnitText ~= "" then 
				strUnitText = strUnitText .. "[NEWLINE]";
			end

			local strength = 0;
			strength = unit:GetBaseCombatStrength();
			local pPlayer = Players[unit:GetOwner()];
			
			-- Player using nickname
			if (pPlayer:GetNickName() ~= nil and pPlayer:GetNickName() ~= "") then
				strUnitText = strUnitText .. Locale.ConvertTextKey("TXT_KEY_MULTIPLAYER_UNIT_TT", pPlayer:GetNickName(), pPlayer:GetCivilizationAdjectiveKey(), unit:GetNameKey());

			-- Use civ short description
			else
				if(unit:HasName()) then
					local desc = Locale.ConvertTextKey("TXT_KEY_PLOTROLL_UNIT_DESCRIPTION_CIV", pPlayer:GetCivilizationAdjectiveKey(), unit:GetNameKey());
					strUnitText = strUnitText .. string.format("%s (%s)", unit:GetNameNoDesc(), desc); 
				else
					strUnitText = strUnitText .. Locale.ConvertTextKey("TXT_KEY_PLOTROLL_UNIT_DESCRIPTION_CIV", pPlayer:GetCivilizationAdjectiveKey(), unit:GetNameKey());
				end
			end
			
			local unitTeam = unit:GetTeam();
			if iActiveTeam == unitTeam then
				strUnitText = "[COLOR_WHITE]" .. strUnitText .. "[ENDCOLOR]";
			elseif pTeam:IsAtWar(unitTeam) then
				strUnitText = "[COLOR_NEGATIVE_TEXT]" .. strUnitText .. "[ENDCOLOR]";
			else
				strUnitText = "[COLOR_POSITIVE_TEXT]" .. strUnitText .. "[ENDCOLOR]";
			end
			
			-- Debug stuff
			if (OptionsManager:IsDebugMode()) then
				strUnitText = strUnitText .. " ("..tostring(unit:GetOwner()).." - " .. tostring(unit:GetID()) .. ")";
			end
			
			-- Combat strength
			if (strength > 0) then
				strUnitText = strUnitText .. ", [ICON_STRENGTH]" .. unit:GetBaseCombatStrength();
			end
			
			-- Hit Points
			if (unit:GetDamage() > 0) then
				strUnitText = strUnitText .. ", " .. Locale.ConvertTextKey("TXT_KEY_PLOTROLL_UNIT_HP", GameDefines["MAX_HIT_POINTS"] - unit:GetDamage());
			end
			
			-- Embarked?
			if (unit:IsEmbarked()) then
				strUnitText = strUnitText .. ", " .. Locale.ConvertTextKey( "TXT_KEY_PLOTROLL_EMBARKED" );
			end
		end			
	end	
	return strUnitText;
end

-------------------------------------------------------------------------------------------------
local function GetResourceString(plot)
	if plot:GetResourceType() < 0 then return "" end

	-- Is the resource known?
	local improvementStr = "";
	local resourceType = plot:GetResourceType();
	local pResource = GameInfo.Resources[resourceType];
	if pResource.TechReveal and (not IGE.showUnknownResources) then
		local team = Teams[IGE.currentPlayer:GetTeam()];
		local revealer = GameInfoTypes[pResource.TechReveal];
		local isKnown = team:GetTeamTechs():HasTech(revealer);
		if not isKnown then return "" end
	end
		
	if plot:GetNumResource() > 1 then
		improvementStr = improvementStr .. plot:GetNumResource() .. " ";
	end
		
	local convertedKey = L(pResource.Description);		
	improvementStr = improvementStr .. pResource.IconString .. " " .. convertedKey;
		
	-- Resource Hookup info
	local iTechCityTrade = GameInfoTypes[pResource.TechCityTrade];
	if iTechCityTrade ~= nil and iTechCityTrade ~= -1 then
		local iActiveTeam = Game.GetActiveTeam();
		local pTeam = Teams[iActiveTeam];

		if not pTeam:GetTeamTechs():HasTech(iTechCityTrade) then
			local techName = GameInfo.Technologies[iTechCityTrade].Description;
			improvementStr = improvementStr .. " " .. L( "TXT_KEY_PLOTROLL_REQUIRES_TECH_TO_USE", techName );
		end
	end
	
	return improvementStr;
end

-------------------------------------------------------------------------------------------------
local function GetToolTipText(plot)
	if not plot then return "" end
	local visible = debugVisible[GetPlotIndex(plot)] or plot:IsRevealed(Game.GetActiveTeam(), false)
	if not visible then return "" end

	-- Units
	local str = GetUnitsString(plot);

	-- Under construction
	for pBuildInfo in GameInfo.Builds() do
		local iTurnsLeft = plot:GetBuildTurnsLeft(pBuildInfo.ID, 0, 0);
		if iTurnsLeft < 4000 and iTurnsLeft > 0 then
			if str ~= "" then str = str.."[NEWLINE]" end
			local convertedKey = L(pBuildInfo.Description);
			str = str..L("TXT_KEY_WORKER_BUILD_PROGRESS", iTurnsLeft, convertedKey);
		end
	end

	-- City/plot owner
	local strOwner = GetOwnerString(plot);
	if strOwner ~= "" then
		if str ~= "" then str = str.."[NEWLINE]" end
		str = str..strOwner;
	end
		
	-- Resource
	local strResource = GetResourceString(plot, true);
	if strResource ~= "" then
		if str ~= "" then str = str.."[NEWLINE]" end
		str = str.."[COLOR_POSITIVE_TEXT]" .. L("TXT_KEY_RESOURCE") .. "[ENDCOLOR]" .. " : " .. strResource;
	end	
		
	-- Improvement & route
	local strImprovement = GetImprovementString(plot);
	if strImprovement ~= "" or plot:IsTradeRoute() then
		if str ~= "" then str = str.."[NEWLINE]" end

		local strTradeRouteBlock = "";
		if strImprovement ~= "" then
			str = str.."[COLOR_POSITIVE_TEXT]" .. L("TXT_KEY_IMPROVEMENT") .. "[ENDCOLOR]" .. " : " .. strImprovement;
			strTradeRouteBlock = ", ";
		end
		
		-- Trade Route
		if plot:IsTradeRoute() then
			str = str..strTradeRouteBlock..L( "TXT_KEY_PLOTROLL_TRADE_ROUTE" );			
		end
	end	
		
	-- Terrain type, feature
	local natureStr = GetNatureString(plot);
	if natureStr ~= "" then
		if str ~= "" then str = str.."[NEWLINE]" end
		str = str.."[COLOR_POSITIVE_TEXT]" .. L("TXT_KEY_PEDIA_TERRAIN_LABEL") .. "[ENDCOLOR]" .. " : " .. natureStr;
	end
		
	-- Yield
	local strYield = GetYieldString(plot);
	if strYield ~= "" then
		if str ~= "" then str = str.."[NEWLINE]" end
		str = str.."[COLOR_POSITIVE_TEXT]" .. L("TXT_KEY_OUTPUT") .. "[ENDCOLOR]" .. " : " .. strYield;
	end
		
	-- Presence of fresh water
	if plot:IsFreshWater() then
		if str ~= "" then str = str.."[NEWLINE]" end
		str = str..L("TXT_KEY_PLOTROLL_FRESH_WATER");
	end
		
	-- City state quest
	local cityStateStr = GetCivStateQuestString(plot, false);
	if cityStateStr ~= "" then
		if str ~= "" then str = str.."[NEWLINE]" end
		str = str..cityStateStr;
	end

	-- Coords
	if str ~= "" then str = str.."[NEWLINE]" end
	str = str..plot:GetX()..", "..plot:GetY()
	
	return str;
end

-------------------------------------------------------------------------------------------------
local function UpdateToolTipCore(plot)
	local str = GetToolTipText(plot);

	if str ~= "" then
		tipControls.HexDetailsText:SetText(str);
		tipControls.HexDetailsGrid:DoAutoSize();
		Controls.OverlayToolTipContainer:SetToolTipType("HexDetails");
	else
		Controls.OverlayToolTipContainer:SetToolTipType();
	end
end

-------------------------------------------------------------------------------------------------
local function OnBroadcastingMouseState(mouseOver, gridX, gridY, plot)
	if mouseOver then
		UpdateToolTipCore(plot);
	end
end
LuaEvents.IGE_BroadcastingMouseState.Add(OnBroadcastingMouseState);



--===============================================================================================
-- YIELD AND RESOURCES OVERLAY
--===============================================================================================
local function GetNumberOffset( number )
	number =  (number > 12) and 12 or number;
    local y = (number > 9) and 768 or 640;
    local x = 128 * ((number - 6) % 4);
    return x, y;
end

-------------------------------------------------------------------------------------------------
local function AppendYieldIcon(yieldType, amount, container, records)
    if amount <= 0 then return end

    local imageInstance = yieldImageManager:GetInstance();
	imageInstance.Image:ChangeParent(container);
	table.insert(records, imageInstance);
        
	-- Food, prod, gold, science, faith
    if( yieldType ~= YieldTypes.YIELD_CULTURE ) then
        imageInstance.Image:SetTexture(defaultTexture);
        if( amount >= 6 ) then
            imageInstance.Image:SetTextureOffsetVal( yieldType * 128, 512 );
        else
            imageInstance.Image:SetTextureOffsetVal( yieldType * 128, 128 * ( amount - 1 ) );
        end

		-- Additional image for number ?
		if( amount > 5 ) then
			local textImageInstance = yieldImageManager:GetInstance();
			textImageInstance.Image:SetTextureOffsetVal( GetNumberOffset( amount ) );
			textImageInstance.Image:ChangeParent( imageInstance.Image );
			table.insert(records, textImageInstance);
		end

	-- Culture
	else
        imageInstance.Image:SetTexture(cultureTexture);
        if( amount >= 5 ) then
            imageInstance.Image:SetTextureOffsetVal( 0 * 128, 512 );
        else
            imageInstance.Image:SetTextureOffsetVal( 0 * 128, 128 * ( amount - 1 ) );
        end
    end
end

-------------------------------------------------------------------------------------------------
local function UpdateYieldOverlay(plot, index, x, y)
	local visible = debugVisible[GetPlotIndex(plot)] or plot:IsRevealed(Game.GetActiveTeam(), false)

	-- No resource? Delete old instance and sub instances
	if not visible then
		local instance = plotInstances[index];
		if instance then 
			for _, v in pairs(instance.images) do
				yieldImageManager:ReleaseInstance(v)
			end
			yieldManager:ReleaseInstance(instance) 
			plotInstances[index] = nil
		end
		return;
	end

	-- Create instance
	local plotInstance = plotInstances[index];
	if plotInstance then
		-- Clean sub-instances
		for _, v in pairs(plotInstance.images) do
			yieldImageManager:ReleaseInstance(v)
		end
	else
		-- Create instance
		plotInstance = yieldManager:GetInstance();
		plotInstances[index] = plotInstance;
	end

	-- Set it up
	plotInstance.images = {};
	AppendYieldIcon(0, plot:CalculateYield(0, true), plotInstance.Stack, plotInstance.images);
	AppendYieldIcon(1, plot:CalculateYield(1, true), plotInstance.Stack, plotInstance.images);
	AppendYieldIcon(2, plot:CalculateYield(2, true), plotInstance.Stack, plotInstance.images);
	AppendYieldIcon(3, plot:CalculateYield(3, true), plotInstance.Stack, plotInstance.images);
	if IGE_HasGodsAndKings then
		AppendYieldIcon(4, plot:CalculateYield(4, true), plotInstance.CultureContainer, plotInstance.images);
		AppendYieldIcon(5, plot:CalculateYield(5, true), plotInstance.CultureContainer, plotInstance.images);
	else
		AppendYieldIcon(4, plot:GetCulture(), plotInstance.CultureContainer, plotInstance.images);
	end
	plotInstance.Stack:CalculateSize();
	plotInstance.Stack:ReprocessAnchoring();
	plotInstance.Anchor:SetHexPosition(x, y);
end

-------------------------------------------------------------------------------------------------
local function UpdateResourceOverlay(plot, index, x, y)
	local visible = debugVisible[GetPlotIndex(plot)] or plot:IsRevealed(Game.GetActiveTeam(), false)

	-- No resource? Delete old instance
	local resourceType = plot:GetResourceType();
	if (not resourceType) or (resourceType == -1) or (not visible) then
		local instance = resourceInstances[index];
		if instance then 
			resourceManager:ReleaseInstance(instance) 
			resourceInstances[index] = nil
		end
		return;
	end
	
	-- Unknown resource? Delete old instance
	local resourceInfo = GameInfo.Resources[resourceType];
	if resourceInfo.TechReveal and (not IGE.showUnknownResources) then
		local team = Teams[Game.GetActiveTeam()];
		local revealer = GameInfoTypes[resourceInfo.TechReveal];
		local isKnown = team:GetTeamTechs():HasTech(revealer);
		--print(resourceInfo.Type.." ; "..resourceInfo.TechReveal.." ; "..getstr(isKnown));
		if not isKnown then
			local instance = resourceInstances[index];
			if instance then resourceManager:ReleaseInstance(instance) end
			return;
		end
	end

	-- Create/retrieve instance
	local instance = resourceInstances[index] or resourceManager:GetInstance();
	resourceInstances[index] = instance;

	-- Update instance
	IconHookup(resourceInfo.PortraitIndex, 64, resourceInfo.IconAtlas, instance.ResourceIcon);

	local strToolTip = GenerateResourceToolTip(plot);
	instance.ResourceIcon:SetToolTipString(strToolTip or "");

	-- Position instance
	local wx, wy, wz = GridToWorld(x, y);
	instance.Anchor:SetWorldPositionVal(wx - 30, wy + 15, wz);
end

-------------------------------------------------------------------------------------------------
local function UpdatePlot(x, y)
	--print(x.." ; "..y);
	local plot = Map.GetPlot(x, y);
	local index = x + y * width;

	UpdateResourceOverlay(plot, index, x, y);
	UpdateYieldOverlay(plot, index, x, y);
end

-------------------------------------------------------------------------------------------------
local function OnModifiedPlot(plot)
	if initialized then
		UpdatePlot(plot:GetX(), plot:GetY());
	end
end
LuaEvents.IGE_ModifiedPlot.Add(OnModifiedPlot);

-------------------------------------------------------------------------------------------------
local function UpdateOverlay()
    Controls.OverlayResourceContainer:SetHide(InStrategicView() or (not IGE.showResources));
	local showOverlay = (not Controls.OverlayResourceContainer:IsHidden()) or (not Controls.OverlayYieldContainer:IsHidden());
	if showOverlay then
		yieldImageManager:ResetInstances();
		resourceManager:ResetInstances();
		yieldManager:ResetInstances();
		resourceInstances = {};
		plotInstances = {};

		for y = height - 1, 0, -1 do
			for x = width - 1, 0, -1 do
				UpdatePlot(x, y);
			end
		end

		return true;
	end
end
Events.GameplaySetActivePlayer.Add(UpdateOverlay);

-------------------------------------------------------------------------------------------------
local function InitializeOverlay()
	if opened and not initialized then
		if UpdateOverlay() then
			initialized = true;
			return true;
		end
	end
	return false;
end

-------------------------------------------------------------------------------------------------
local function OnHexFogEvent(hexPos, fogState, bWholeMap)
	if bWholeMap then 
		for i = 0, Map.GetNumPlots()-1, 1 do
			local plot = Map.GetPlotByIndex(i);
			debugVisible[GetPlotIndex(plot)] = (fogState == 2)
		end
		UpdateOverlay()
	else
		local x, y = ToGridFromHex(hexPos.x, hexPos.y);
		local plot = Map.GetPlot(x, y);
		debugVisible[GetPlotIndex(plot)] = (fogState == 2)
		OnModifiedPlot(plot)
	end
end
Events.HexFOWStateChanged.Add(OnHexFogEvent);

-------------------------------------------------------------------------------------------------
local function OnResourceAdded(hexPosX, hexPosY)
	local x, y = ToGridFromHex(hexPosX, hexPosY);
	local plot = Map.GetPlot(x, y);
	debugVisible[GetPlotIndex(plot)] = (fogState == 2)
	OnModifiedPlot(plot)
end
Events.SerialEventRawResourceIconCreated.Add( OnResourceAdded )	-- Includes techs discoveries, I guess.

-------------------------------------------------------------------------------------------------
local function OnStrategicViewStateChanged()
    Controls.OverlayResourceContainer:SetHide(InStrategicView() or (not IGE.showResources));
	InitializeOverlay();
end
Events.StrategicViewStateChanged.Add(OnStrategicViewStateChanged);

-------------------------------------------------------------------------------------------------
function OnUpdatedOptions(IGE)
    Controls.OverlayYieldContainer:SetHide(not IGE.showYields);
    Controls.OverlayResourceContainer:SetHide(InStrategicView() or (not IGE.showResources));

	if not initialized then
		InitializeOverlay();
	else
		print("update overlay: showResources="..getstr(IGE.showResources).." ; showYields="..getstr(IGE.showYields));
		UpdateOverlay();
	end
end
LuaEvents.IGE_UpdatedOptions.Add(OnUpdatedOptions);


--===============================================================================================
-- HOOKS
--===============================================================================================
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
	OnUpdatedOptions(_IGE);
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

local function OnShowing()
	opened = true;
	if InitializeOverlay() then
		Events.HexYieldMightHaveChanged.Add(UpdatePlot);
	end
end
LuaEvents.IGE_Showing.Add(OnShowing);

-------------------------------------------------------------------------------------------------
local function OnClosing()
	opened = false;
	if initialized then
		initialized = false;
		Events.HexYieldMightHaveChanged.Remove(UpdatePlot);
	end
end
LuaEvents.IGE_Closing.Add(OnClosing);
