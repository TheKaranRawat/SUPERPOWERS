
--===============================================================================================
-- ORIGINAL PRODUCTION POPUP CODE
-- Copied from the base one, I just moved global hooks to the IGE section at the bottom
--===============================================================================================
include("IGE_Utils");
include("IconSupport");
include("InstanceManager");
include("InfoTooltipInclude");
include("IGE_InfoToolTipInclude")

local g_UnitInstanceManager = InstanceManager:new( "ProdButton", "Button", Controls.UnitButtonStack );
local g_BuildingInstanceManager = InstanceManager:new( "ProdButton", "Button", Controls.BuildingButtonStack );
local g_WonderInstanceManager = InstanceManager:new( "ProdButton", "Button", Controls.WonderButtonStack );

local m_PopupInfo = nil;

local bHidden = true;

------------------------------------------------
-- global constants
------------------------------------------------
g_strInfiniteTurns = L("TXT_KEY_PRODUCTION_HELP_INFINITE_TURNS");

-- Storing current city in a global because the button cannot have more than 2 extra args.
local g_currentCity = nil;

local g_append = false;

local g_IsProductionMode = true;

local m_gOrderType = -1;
local m_gFinishedItemType = -1;

local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal()
local scrollPanelSize = Controls.ScrollPanel:GetSize();
local scrollPanelSize = Controls.ScrollPanel:GetSize();
local scrollBarSize = { x = scrollBarWidth; y = screenSizeY - 400; };
Controls.ScrollBar:SetSize( scrollBarSize );
Controls.ScrollBar:SetOffsetVal( 15, 18 );
Controls.UpButton:SetOffsetVal( 15, 0);
Controls.DownButton:SetOffsetVal( 15, screenSizeY - 414 );
scrollPanelSize.y = screenSizeY - 396;
Controls.ScrollPanel:SetSize( scrollPanelSize );
Controls.ScrollPanel:CalculateInternalSize();
local backdropSize = { x = 377; y = screenSizeY - 300; };
Controls.Backdrop:SetSize( backdropSize );
--local mouseCatcherSize = { x = 465; y = screenSizeY - 30; };
--Controls.MouseCatcher:SetSize( mouseCatcherSize );

local listOfStrings = {};

-------------------------------------------------
-- On Production Selected
-------------------------------------------------
function ProductionSelected( eOrder, iData)
		
	-- Viewing mode only!
	if (UI.IsCityScreenViewingMode()) then
		return;
	end
	
    local city = g_currentCity;
    
    if g_IsProductionMode then
		Game.CityPushOrder(city, eOrder, iData, false, not g_append, true);
    else
		local bSomethingPurchased = false;
		if (eOrder == OrderTypes.ORDER_TRAIN) then
			Game.CityPurchaseUnit(city, iData);
			print("purchase: "..iData.." ; "..city:GetID());
			bSomethingPurchased = true;
		elseif (eOrder == OrderTypes.ORDER_CONSTRUCT) then
			Game.CityPurchaseBuilding(city, iData);
			bSomethingPurchased = true;
		elseif (eOrder == OrderTypes.ORDER_CREATE) then
			Game.CityPurchaseProject(city, iData);
			bSomethingPurchased = true;
		end
		
		if (bSomethingPurchased) then
			Events.AudioPlay2DSound("AS2D_INTERFACE_CITY_SCREEN_PURCHASE");
		end
    end
  
    
	local cityID = city:GetID();
	local player = city:GetOwner();
    Events.SpecificCityInfoDirty( player, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_BANNER);
    Events.SpecificCityInfoDirty( player, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION);
 
	if not g_append or not g_IsProductionMode then 
		OnClose();
	end
end

-------------------------------------------------
-------------------------------------------------
function OnCityButton( x, y )
    OnClose();
    UI.DoSelectCityAtPlot( Map.GetPlot( x, y ) );
end
Controls.CityButton:RegisterCallback( Mouse.eLClick, OnCityButton );

-------------------------------------------------
-------------------------------------------------
local buildingHeadingOpen = true;
local unitHeadingOpen = true;
local wonderHeadingOpen = true;
local otherHeadingOpen = true;

function OnBuildingHeaderSelected()
	buildingHeadingOpen = not buildingHeadingOpen;
	UpdateWindow( g_currentCity );
end

function OnUnitHeaderSelected()
	unitHeadingOpen = not unitHeadingOpen;
	UpdateWindow( g_currentCity );
end

function OnWonderHeaderSelected()
	wonderHeadingOpen = not wonderHeadingOpen;
	UpdateWindow( g_currentCity );
end

function OnOtherHeaderSelected()
	otherHeadingOpen = not otherHeadingOpen;
	UpdateWindow( g_currentCity );
end


function UpdateWindow( city )
    g_UnitInstanceManager:ResetInstances();
    g_BuildingInstanceManager:ResetInstances();
    g_WonderInstanceManager:ResetInstances();
    
    if city == nil then
		city = UI.GetHeadSelectedCity();
    end

    if city == nil then
		return;
    end
   
	local qMode = g_append and g_IsProductionMode;
 
	if qMode then
		local qLength = city:GetOrderQueueLength();
		if qLength >= 6 then
			OnClose();
		end
		
		local queuedOrderType;
		local queuedData1;
		local queuedData2;
		local queuedSave;
		local queuedRush;

		local isMaint = false;
		for i = 1, qLength do
			queuedOrderType, queuedData1, queuedData2, queuedSave, queuedRush = city:GetOrderFromQueue( i-1 );
			if (queuedOrderType == OrderTypes.ORDER_MAINTAIN) then
				isMaint = true;
				break;
			end
		end
		
		if isMaint then
			OnClose();
		end
	end
    
    if( g_IsProductionMode ) then
        Controls.PurchaseIcon:SetText( "[ICON_GOLD]" );
        Controls.PurchaseString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PURCHASE_BUTTON" );
        Controls.PurchaseButton:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_PURCHASE_TT" );
    else
        Controls.PurchaseIcon:SetText( "[ICON_PRODUCTION]" );
        Controls.PurchaseString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PRODUCE_BUTTON" );
        --Controls.PurchaseString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_QUEUE_PROD" );
        
        if( g_append ) then
            Controls.PurchaseButton:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_QUEUE_PROD_TT" );
        else
            Controls.PurchaseButton:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_CHOOSE_PROD_TT" );
        end
        
        
    end
    
    local player = Players[Game.GetActivePlayer()];
    local cityID = city:GetID();
    
    local selectedCity = UI.GetHeadSelectedCity();
    local selectedCityID = selectedCity and selectedCity:GetID() or -1;
	
	Game.SetAdvisorRecommenderCity(city);

	-- Should we pan to this city?
	if(cityID ~= selectedCityID) then
		local plot = city:Plot();
		UI.LookAt(plot, 0);
	end
   
    g_currentCity = city;
 		
    -- City Detail info
    Controls.CityName:SetText( city:GetName() );
    
    local cityPopulation = city:GetPopulation();
    Controls.Population:SetText( cityPopulation );
    Controls.PopulationSuffix:LocalizeAndSetText("TXT_KEY_CITYVIEW_CITIZENS_TEXT", cityPopulation);
    
    local productionYield = city:GetYieldRate(YieldTypes.YIELD_PRODUCTION);
    local productionPerTurn = math.floor(productionYield + (productionYield * (city:GetProductionModifier() / 100)));
    
    local scienceYield = city:GetYieldRate(YieldTypes.YIELD_SCIENCE);
    if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)) then
		scienceYield = 0;
	end
    
	Controls.GrowthBar:SetPercent( city:GetFood() / city:GrowthThreshold() );
    Controls.Food:SetText( "[ICON_FOOD]" .. city:FoodDifference() );
    Controls.Production:SetText( "[ICON_PRODUCTION]" .. productionPerTurn );
    Controls.Science:SetText( "[ICON_RESEARCH]" ..  scienceYield);
    Controls.Gold:SetText( "[ICON_GOLD]" .. city:GetYieldRate( YieldTypes.YIELD_GOLD ) );
    Controls.Culture:SetText( "[ICON_CULTURE]" .. city:GetJONSCulturePerTurn() );
    Controls.CityButton:SetVoids( city:GetX(), city:GetY() );

	local cityGrowth = city:GetFoodTurnsLeft();			
	if (city:IsFoodProduction() or city:FoodDifferenceTimes100() == 0) then
		Controls.CityGrowthLabel:SetText(L("TXT_KEY_CITYVIEW_STAGNATION_TEXT"));
	elseif city:FoodDifference() < 0 then
		Controls.CityGrowthLabel:SetText(L("TXT_KEY_CITYVIEW_STARVATION_TEXT"));
	else
		Controls.CityGrowthLabel:SetText(L("TXT_KEY_CITYVIEW_TURNS_TILL_CITIZEN_TEXT", cityGrowth));
	end

	-- Yield (and Culture) Tooltips
	local strFoodToolTip = GetFoodTooltip(city);
	Controls.PopBox:SetToolTipString(strFoodToolTip);
	Controls.Food:SetToolTipString(strFoodToolTip);
	
	local strProductionToolTip = GetProductionTooltip(city);
	Controls.Production:SetToolTipString(strProductionToolTip);
	
	local strGoldToolTip = GetGoldTooltip(city);
	Controls.Gold:SetToolTipString(strGoldToolTip);
	
	local strScienceToolTip = GetScienceTooltip(city);
	Controls.Science:SetToolTipString(strScienceToolTip);
	
	local strCultureToolTip = GetCultureTooltip(city);
	Controls.Culture:SetToolTipString(strCultureToolTip);
   
	local ourCiv = player:GetCivilizationType();
    local ourCivCiv = GameInfo.Civilizations[ourCiv];
 	IconHookup( ourCivCiv.PortraitIndex, 32, ourCivCiv.IconAtlas, Controls.CivIcon );                    
            
	local strTurnsLeft = g_strInfiniteTurns;
	
	local bGeneratingProduction = false;
	if (city:GetCurrentProductionDifferenceTimes100(false, false) > 0) then
		bGeneratingProduction = true;
	end
	
	listOfStrings = {};
	
    -- Units
    local numUnitButtons = 0;	
 	for unit in GameInfo.Units() do
 		local unitID = unit.ID;
 		if g_IsProductionMode then
 			-- test w/ visible (ie COULD train if ... )
			if city:CanTrain( unitID, 0, 1 ) then
				local isDisabled = false;
     			-- test w/o visible (ie can train right now)
    			if not city:CanTrain( unitID ) then
    				isDisabled = true;
				end
				
				if (bGeneratingProduction) then
					strTurnsLeft = L( "TXT_KEY_STR_TURNS", city:GetUnitProductionTurnsLeft( unitID ));
				else
					strTurnsLeft = g_strInfiniteTurns;
				end
				
				AddProductionButton( unitID, unit.Description, OrderTypes.ORDER_TRAIN, strTurnsLeft, 1, isDisabled );
				numUnitButtons = numUnitButtons + 1;
			end
 		else
			if city:IsCanPurchase(true, unitID, -1, -1) then
 				local isDisabled = false;
     			-- test w/o visible (ie can train right now)
	     	
    			if (not city:IsCanPurchase(false, unitID, -1, -1)) then
    				isDisabled = true;
				end
	 			
 				local cost = city:GetUnitPurchaseCost( unitID );
				AddProductionButton( unitID, unit.Description, OrderTypes.ORDER_TRAIN, cost, 1, isDisabled);
				numUnitButtons = numUnitButtons + 1;
			end
 		end
	end
	if unitHeadingOpen then
		local localizedLabel = "[ICON_MINUS] "..L( "TXT_KEY_POP_UNITS" );
		Controls.UnitButtonLabel:SetText(localizedLabel);
		Controls.UnitButtonStack:SetHide( false );
	else
		local localizedLabel = "[ICON_PLUS] "..L( "TXT_KEY_POP_UNITS" );
		Controls.UnitButtonLabel:SetText(localizedLabel);
		Controls.UnitButtonStack:SetHide( true );
	end
	if numUnitButtons > 0 then
		Controls.UnitButton:SetHide( false );
	else
		Controls.UnitButton:SetHide( true );
		Controls.UnitButton:SetHide( true );
	end
	Controls.UnitButton:RegisterCallback( Mouse.eLClick, OnUnitHeaderSelected );

	local numBuildingButtons = 0;
	local numWonderButtons = 0;
    -- Projects	
 	for project in GameInfo.Projects() do
 		local projectID = project.ID;
 	 	if g_IsProductionMode then
 	 	 	-- test w/ visible (ie COULD train if ... )
			if city:CanCreate( projectID, 0, 1 ) then
				local isDisabled = false;
			    
     			-- test w/o visible (ie can train right now)
    			if( not city:CanCreate( projectID ) )
    			then
    				isDisabled = true;
				end
				
				if (bGeneratingProduction) then
					strTurnsLeft = L( "TXT_KEY_STR_TURNS", city:GetProjectProductionTurnsLeft( projectID ));
				else
					strTurnsLeft = g_strInfiniteTurns;
				end
				
				AddProductionButton( projectID, project.Description, OrderTypes.ORDER_CREATE, strTurnsLeft, 3, isDisabled );
				numWonderButtons = numWonderButtons + 1;
			end
		else
			if city:IsCanPurchase(true, -1, -1, projectID) then
				local isDisabled = true;		    
 				local cost = city:GetProjectPurchaseCost( projectID );
				AddProductionButton( projectID, project.Description, OrderTypes.ORDER_CREATE, cost, 3, isDisabled );
				numWonderButtons = numWonderButtons + 1;
			end
		end
	end

    -- Buildings	
 	for building in GameInfo.Buildings() do
 		local buildingID = building.ID;
 		if g_IsProductionMode then
 			-- test w/ visible (ie COULD train if ... )
			if city:CanConstruct( buildingID, 0, 1 ) then
				local isDisabled = false;
			    
     			-- test w/o visible (ie can train right now)
    			if not city:CanConstruct( buildingID ) then
    				isDisabled = true;
				end

				local col = 2;
				local thisBuildingClass = GameInfo.BuildingClasses[building.BuildingClass];
				if thisBuildingClass.MaxGlobalInstances > 0 or thisBuildingClass.MaxPlayerInstances > 0 or thisBuildingClass.MaxTeamInstances > 0 then
					col = 3;
				end
				
				if (bGeneratingProduction) then
					strTurnsLeft = L( "TXT_KEY_STR_TURNS", city:GetBuildingProductionTurnsLeft( buildingID ));
				else
					strTurnsLeft = g_strInfiniteTurns;
				end
				
				AddProductionButton( buildingID, building.Description, OrderTypes.ORDER_CONSTRUCT, strTurnsLeft, col, isDisabled );
				if col == 2 then
					numBuildingButtons = numBuildingButtons + 1;
				else
					numWonderButtons = numWonderButtons + 1;
				end
			end
		else
			if city:IsCanPurchase(true, -1, buildingID, -1) then
				local col = 2;
				local thisBuildingClass = GameInfo.BuildingClasses[building.BuildingClass];
				if thisBuildingClass.MaxGlobalInstances > 0 or thisBuildingClass.MaxPlayerInstances > 0 or thisBuildingClass.MaxTeamInstances > 0 then
					col = 3;
				end

 				local isDisabled = false;
    			if (not city:IsCanPurchase(false, -1, buildingID, -1)) then
 					isDisabled = true;
 				end
	 			
 				local cost = city:GetBuildingPurchaseCost( buildingID );
				AddProductionButton( buildingID, building.Description, OrderTypes.ORDER_CONSTRUCT, cost, col, isDisabled );
				if col == 2 then
					numBuildingButtons = numBuildingButtons + 1;
				else
					numWonderButtons = numWonderButtons + 1;
				end
			end
		end
	end
	if buildingHeadingOpen then
		local localizedLabel = "[ICON_MINUS] "..L( "TXT_KEY_POP_BUILDINGS" );
		Controls.BuildingsButtonLabel:SetText(localizedLabel);
		Controls.BuildingButtonStack:SetHide( false );
	else
		local localizedLabel = "[ICON_PLUS] "..L( "TXT_KEY_POP_BUILDINGS" );
		Controls.BuildingsButtonLabel:SetText(localizedLabel);
		Controls.BuildingButtonStack:SetHide( true );
	end
	if numBuildingButtons > 0 then
		Controls.BuildingsButton:SetHide( false );
	else
		Controls.BuildingsButton:SetHide( true );
		Controls.BuildingsButton:SetHide( true );
	end
	Controls.BuildingsButton:RegisterCallback( Mouse.eLClick, OnBuildingHeaderSelected );
	
	if wonderHeadingOpen then
		local localizedLabel = "[ICON_MINUS] "..L( "TXT_KEY_POP_WONDERS" );
		Controls.WondersButtonLabel:SetText(localizedLabel);
		Controls.WonderButtonStack:SetHide( false );
	else
		local localizedLabel = "[ICON_PLUS] "..L( "TXT_KEY_POP_WONDERS" );
		Controls.WondersButtonLabel:SetText(localizedLabel);
		Controls.WonderButtonStack:SetHide( true );
	end
	if numWonderButtons > 0 then
		Controls.WondersButton:SetHide( false );
	else
		Controls.WondersButton:SetHide( true );
		Controls.WondersButton:SetHide( true );
	end
	Controls.WondersButton:RegisterCallback( Mouse.eLClick, OnWonderHeaderSelected );
    	
	-- Processes
	local numOtherButtons = 0;
    Controls.ProduceGoldButton:SetHide( true );
    Controls.ProduceResearchButton:SetHide( true );
    if g_IsProductionMode then
 		for process in GameInfo.Processes() do
 			local processID = process.ID;				
			if city:CanMaintain( processID, 1 ) then
 				if process.Type == "PROCESS_WEALTH" then
					Controls.ProduceGoldButton:SetHide( false );
					Controls.ProduceGoldButton:SetVoid1( OrderTypes.ORDER_MAINTAIN );
					Controls.ProduceGoldButton:SetVoid2( processID );
					Controls.ProduceGoldButton:RegisterCallback( Mouse.eLClick, ProductionSelected );
					numOtherButtons = numOtherButtons + 1;
				elseif process.Type == "PROCESS_RESEARCH" then
					Controls.ProduceResearchButton:SetHide( false );
					Controls.ProduceResearchButton:SetVoid1( OrderTypes.ORDER_MAINTAIN ); 
					Controls.ProduceResearchButton:SetVoid2( processID );
					Controls.ProduceResearchButton:RegisterCallback( Mouse.eLClick, ProductionSelected );
					numOtherButtons = numOtherButtons + 1;
				end
			end
		end
	end   	
	if otherHeadingOpen then
		local localizedLabel = "[ICON_MINUS] "..L( "TXT_KEY_CITYVIEW_OTHER" );
		Controls.OtherButtonLabel:SetText(localizedLabel);
	else
		local localizedLabel = "[ICON_PLUS] "..L( "TXT_KEY_CITYVIEW_OTHER" );
		Controls.OtherButtonLabel:SetText(localizedLabel);
		Controls.ProduceGoldButton:SetHide( true );
		Controls.ProduceResearchButton:SetHide( true );
	end
	if numOtherButtons > 0 then
		Controls.OtherButton:SetHide( false );
	else
		Controls.OtherButton:SetHide( true );
		Controls.OtherButton:SetHide( true );
	end
	Controls.OtherButton:RegisterCallback( Mouse.eLClick, OnOtherHeaderSelected );
    	   	
	-- Header Text
	
	-------------------------------------------
	-- Item under Production
	-------------------------------------------
	
	local strItemName	;
	local szHelpText = "";
	local unitProduction = -1;
	local buildingProduction = -1;
	local projectProduction = -1;
	local processProduction = -1;
	local noProduction = false;
	
	local bJustFinishedSomething;
	
	-- Didn't just finish something
	if (m_gOrderType == -1 or m_gOrderType > 4) then
		
		bJustFinishedSomething = false;
		
		strItemName = L(city:GetProductionNameKey());
		
		-- Description and picture of Item under Production
		unitProduction = city:GetProductionUnit();
		buildingProduction = city:GetProductionBuilding();
		projectProduction = city:GetProductionProject();
		processProduction = city:GetProductionProcess();
		
	-- We just finished something, so show THAT in the bottom left
	else
		
		bJustFinishedSomething = true;
		
		-- Just finished a Unit
		if (m_gOrderType == OrderTypes.ORDER_TRAIN) then
			unitProduction = m_gFinishedItemType;
			strItemName = L(GameInfo.Units[unitProduction].Description);
			
		-- Just finished a Building/Wonder
		elseif (m_gOrderType == OrderTypes.ORDER_CONSTRUCT) then
			buildingProduction = m_gFinishedItemType;
			strItemName = L(GameInfo.Buildings[buildingProduction].Description);
			
		-- Just finished a Project
		elseif (m_gOrderType == OrderTypes.ORDER_CREATE) then
			projectProduction = m_gFinishedItemType;
			strItemName = L(GameInfo.Projects[projectProduction].Description);
			
		-- Don't worry about specialists or processes
		end
		
		strItemName = L("TXT_KEY_RESEARCH_FINISHED") .. " " .. strItemName;
		
	end
	
	Controls.ProductionItemName:SetText(strItemName);
	
	local strToolTip = L("TXT_KEY_CITYVIEW_PROD_METER_TT");

	if unitProduction ~= -1 then
		local thisUnitInfo = GameInfo.Units[unitProduction];
		szHelpText = L(thisUnitInfo.Help);
		if IconHookup( thisUnitInfo.PortraitIndex, 128, thisUnitInfo.IconAtlas, Controls.ProductionPortrait ) then
			Controls.ProductionPortrait:SetHide( false );
			
			-- Info for this thing
			strToolTip = L(GetHelpTextForUnit(unitProduction, true)) .. "[NEWLINE][NEWLINE]" .. strToolTip;
			
		else
			Controls.ProductionPortrait:SetHide( true );
		end
	elseif buildingProduction ~= -1 then
		local thisBuildingInfo = GameInfo.Buildings[buildingProduction];
		szHelpText = thisBuildingInfo.Help;
		if IconHookup( thisBuildingInfo.PortraitIndex, 128, thisBuildingInfo.IconAtlas, Controls.ProductionPortrait ) then
			Controls.ProductionPortrait:SetHide( false );
			
			-- Info for this thing
			strToolTip = L(GetHelpTextForBuilding(buildingProduction, false, false, false)) .. "[NEWLINE][NEWLINE]" .. strToolTip;
			
		else
			Controls.ProductionPortrait:SetHide( true );
		end
	elseif projectProduction ~= -1 then
		local thisProjectInfo = GameInfo.Projects[projectProduction];
		szHelpText = thisProjectInfo.Help;
		if IconHookup( thisProjectInfo.PortraitIndex, 128, thisProjectInfo.IconAtlas, Controls.ProductionPortrait ) then
			Controls.ProductionPortrait:SetHide( false );
			
			-- Info for this thing
			strToolTip = L(GetHelpTextForProject(projectProduction, true)) .. "[NEWLINE][NEWLINE]" .. strToolTip;
			
		else
			Controls.ProductionPortrait:SetHide( true );
		end
	elseif processProduction ~= -1 then
		local thisProcessInfo = GameInfo.Processes[processProduction];
		szHelpText = thisProcessInfo.Help;
		if IconHookup( thisProcessInfo.PortraitIndex, 128, thisProcessInfo.IconAtlas, Controls.ProductionPortrait ) then
			Controls.ProductionPortrait:SetHide( false );
		else
			Controls.ProductionPortrait:SetHide( true );
		end
	else
		Controls.ProductionPortrait:SetHide(true);
		noProduction = true;
	end
	
	Controls.ProductionPortrait:SetToolTipString( strToolTip );
	
	if (not bJustFinishedSomething) then
		
		-- Production stored and needed
		local iStoredProduction = city:GetProductionTimes100() / 100;
		local iProductionNeeded = city:GetProductionNeeded();
		if (city:IsProductionProcess()) then
			iProductionNeeded = 0;
		end
		
		-- Base Production per turn
		local iProductionPerTurn = city:GetCurrentProductionDifferenceTimes100(false, false) / 100;
		local iProductionModifier = city:GetProductionModifier() + 100;
			
		local strProductionPerTurn = L("TXT_KEY_CITY_SCREEN_PROD_PER_TURN", iProductionPerTurn);
		Controls.ProductionOutput:SetText(strProductionPerTurn);
		
		-- Progress info for meter
		local iStoredProductionPlusThisTurn = iStoredProduction + iProductionPerTurn;
		
		local fProductionProgressPercent = iStoredProduction / iProductionNeeded;
		local fProductionProgressPlusThisTurnPercent = iStoredProductionPlusThisTurn / iProductionNeeded;
		if (fProductionProgressPlusThisTurnPercent > 1) then
			fProductionProgressPlusThisTurnPercent = 1
		end
		
		Controls.ProductionMeter:SetPercents( fProductionProgressPercent, fProductionProgressPlusThisTurnPercent );
		
		-- Turns left
		local productionTurnsLeft = city:GetProductionTurnsLeft();
		local strNumTurns;
		
		if productionTurnsLeft > 99 then
			strNumTurns = L("TXT_KEY_PRODUCTION_HELP_99PLUS_TURNS");
		else
			strNumTurns = L("TXT_KEY_PRODUCTION_HELP_NUM_TURNS", productionTurnsLeft);
		end
			
		local bGeneratingProduction = city:IsProductionProcess() or city:GetCurrentProductionDifferenceTimes100(false, false) == 0;
		
		if (bGeneratingProduction) then
			strNumTurns = "";
		end
		
		-- Indicator for the fact that the empire is very unhappy
		if (player:IsEmpireVeryUnhappy()) then
			strNumTurns = strNumTurns .. " [ICON_HAPPINESS_4]";
		end
		
		if (not bGeneratingProduction) then
			Controls.ProductionTurnsLabel:SetText("(" .. strNumTurns .. ")");
		else
			Controls.ProductionTurnsLabel:SetText(strNumTurns);
		end
		
		--end
		
	-- Just Finished something
	else
		Controls.ProductionOutput:SetText("");
		Controls.ProductionTurnsLabel:SetText("");
		
	end
		
	if noProduction then
		Controls.ProductionBox:SetHide(true);
	else
		Controls.ProductionBox:SetHide(false);
	end
      
	if qMode then
		Controls.ProductionBox:SetHide(true);
		
		Controls.b1box:SetHide( true );
		Controls.b2box:SetHide( true );
		Controls.b3box:SetHide( true );
		Controls.b4box:SetHide( true );
		Controls.b5box:SetHide( true );
		Controls.b6box:SetHide( true );
				
		local qLength = city:GetOrderQueueLength();
		for i = 1, qLength do
			local queuedOrderType;
			local queuedData1;
			local queuedData2;
			local queuedSave;
			local queuedRush;
			local buttonPrefix = "b"..tostring(i);
			local controlBox = buttonPrefix.."box";
			local controlName = buttonPrefix.."name";
			local controlTurns = buttonPrefix.."turns";		
			local strToolTip = "";
			
			Controls[controlTurns]:SetHide( false );

			queuedOrderType, queuedData1, queuedData2, queuedSave, queuedRush = city:GetOrderFromQueue( i-1 );
			if (queuedOrderType == OrderTypes.ORDER_TRAIN) then
				local thisUnitInfo = GameInfo.Units[queuedData1];
				Controls[controlName]:SetText( L( thisUnitInfo.Description ) );
				Controls[controlTurns]:SetText( L("TXT_KEY_PRODUCTION_HELP_NUM_TURNS", city:GetUnitProductionTurnsLeft(queuedData1, i-1) ) );
				if (thisUnitInfo.Help ~= nil) then
					strToolTip = thisUnitInfo.Help;
				end
			elseif (queuedOrderType == OrderTypes.ORDER_CONSTRUCT) then
				local thisBuildingInfo = GameInfo.Buildings[queuedData1];
				Controls[controlName]:SetText( L( thisBuildingInfo.Description ) );
				Controls[controlTurns]:SetText( L("TXT_KEY_PRODUCTION_HELP_NUM_TURNS", city:GetBuildingProductionTurnsLeft(queuedData1, i-1)) );
				if (thisBuildingInfo.Help ~= nil) then
					strToolTip = thisBuildingInfo.Help;
				end
			elseif (queuedOrderType == OrderTypes.ORDER_CREATE) then
				local thisProjectInfo = GameInfo.Projects[queuedData1];
				Controls[controlName]:SetText( L( thisProjectInfo.Description ) );
				Controls[controlTurns]:SetText( L("TXT_KEY_PRODUCTION_HELP_NUM_TURNS", city:GetProjectProductionTurnsLeft(queuedData1, i-1)) );
				if (thisProjectInfo.Help ~= nil) then
					strToolTip = thisProjectInfo.Help;
				end
			elseif (queuedOrderType == OrderTypes.ORDER_MAINTAIN) then
				local thisProcessInfo = GameInfo.Processes[queuedData1];
				Controls[controlName]:SetText( L( thisProcessInfo.Description ) );
				Controls[controlTurns]:SetHide( true );
				if (thisProcessInfo.Help ~= nil) then
					strToolTip = thisProcessInfo.Help;
				end
			end
			Controls[controlBox]:SetToolTipString(L(strToolTip));
			Controls[controlBox]:SetHide( false );
		end
		Controls.ProductionQueueBox:SetHide(false);
	else
		Controls.ProductionQueueBox:SetHide(true);
	end
      
	Controls.UnitButtonStack:CalculateSize();
	Controls.UnitButtonStack:ReprocessAnchoring();
	
	Controls.BuildingButtonStack:CalculateSize();
	Controls.BuildingButtonStack:ReprocessAnchoring();
	
	Controls.WonderButtonStack:CalculateSize();
	Controls.WonderButtonStack:ReprocessAnchoring();
	
	Controls.StackOStacks:CalculateSize();
	Controls.StackOStacks:ReprocessAnchoring();

	Controls.ScrollPanel:CalculateInternalSize();

end


-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION ) then
		return;
	end

	CivIconHookup( Game.GetActivePlayer(), 32, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
	
	m_PopupInfo = popupInfo;

    local player = Players[Game.GetActivePlayer()];
    local city = player:GetCityByID( popupInfo.Data1 );
    
    if city and city:IsPuppet() then
		return;
    end
	
	m_gOrderType = popupInfo.Data2;
	m_gFinishedItemType = popupInfo.Data3;
	
    g_append = popupInfo.Option1;
    
    -- Purchase mode?
    if (popupInfo.Option2 == true) then
		g_IsProductionMode = false;
	else
		g_IsProductionMode = true;
	end
 
	UpdateWindow( city );
 			
    --UIManager:QueuePopup( ContextPtr, PopupPriority.ProductionPopup );
    ContextPtr:SetHide( false );
end


function OnDirty()
	if not bHidden then
		local pCity = UI.GetHeadSelectedCity();
		if pCity ~= nil then
			UpdateWindow( pCity );
		elseif g_currentCity ~= nil then
			UpdateWindow( g_currentCity );
		end
	end
end

function OnCityDestroyed(hexPos, playerID, cityID, newPlayerID)
	if not bHidden then
		local city = g_currentCity;
		local currentCityID = city:GetID();
		if playerID == Game.GetActivePlayer() and cityID == currentCityID then
			OnClose();
		end
	end	
end

function GetProdHelp( void1, void2, button )
	local searchString = listOfStrings[tostring(button)];
	Events.SearchForPediaEntry( searchString );		
end

function OnPortraitRClicked()
	local city = g_currentCity;
	local cityID = city:GetID();

	local searchString = "";
	
	local unitProduction = -1;
	local buildingProduction = -1;
	local projectProduction = -1;
	local processProduction = -1;
	local noProduction = false;
	
	-- Didn't just finish something
	if (m_gOrderType == -1) then
		
		-- Description and picture of Item under Production
		unitProduction = city:GetProductionUnit();
		buildingProduction = city:GetProductionBuilding();
		projectProduction = city:GetProductionProject();
		processProduction = city:GetProductionProcess();
		
	-- We just finished something, so show THAT in the bottom left
	else
		
		-- Just finished a Unit
		if (m_gOrderType == OrderTypes.ORDER_TRAIN) then
			unitProduction = m_gFinishedItemType;
			
		-- Just finished a Building/Wonder
		elseif (m_gOrderType == OrderTypes.ORDER_CONSTRUCT) then
			buildingProduction = m_gFinishedItemType;
			
		-- Just finished a Project
		elseif (m_gOrderType == OrderTypes.ORDER_CREATE) then
			projectProduction = m_gFinishedItemType;
			
		-- Don't worry about specialists or processes
		end
		
	end

	if unitProduction ~= -1 then
		local thisUnitInfo = GameInfo.Units[unitProduction];
		searchString = L( thisUnitInfo.Description );
	elseif buildingProduction ~= -1 then
		local thisBuildingInfo = GameInfo.Buildings[buildingProduction];
		searchString = L( thisBuildingInfo.Description );
	elseif projectProduction ~= -1 then
		local thisProjectInfo = GameInfo.Projects[projectProduction];
		searchString = L( thisProjectInfo.Description );
	elseif processProduction ~= -1 then
		local pProcessInfo = GameInfo.Processes[processProduction];
		searchString = L( pProcessInfo.Description );
	else
		noProduction = true;
	end
		
	if noProduction == false then
		-- search by name
		Events.SearchForPediaEntry( searchString );		
	end
		
end
Controls.ProductionPortraitButton:RegisterCallback( Mouse.eRClick, OnPortraitRClicked );



local defaultErrorTextureSheet = "TechAtlasSmall.dds";
local nullOffset = Vector2( 0, 0 );

----------------------------------------------------------------        
-- Add a button based on the item info
----------------------------------------------------------------        
function AddProductionButton( id, description, orderType, turnsLeft, column, isDisabled )	
	local controlTable;
	
	local pCity = g_currentCity;
	local abAdvisorRecommends = {false, false, false, false};
	local iUnit = -1;
	local iBuilding = -1;
	local iProject = -1;
	
	if column == 1 then -- we are a unit
		iUnit = id;
		controlTable = g_UnitInstanceManager:GetInstance();
		local thisUnitInfo = GameInfo.Units[id];
		
		-- Portrait
		local textureOffset, textureSheet = IconLookup( thisUnitInfo.PortraitIndex, 45, thisUnitInfo.IconAtlas );				
		if textureOffset == nil then
			textureSheet = defaultErrorTextureSheet;
			textureOffset = nullOffset;
		end				
		controlTable.ProductionButtonImage:SetTexture(textureSheet);
		controlTable.ProductionButtonImage:SetTextureOffset(textureOffset);
		
		-- Tooltip
		local bIncludeRequirementsInfo = false;
		local strToolTip = L(GetHelpTextForUnit(id, bIncludeRequirementsInfo));
		
		-- Disabled help text
		if (isDisabled) then
			if (g_IsProductionMode) then
				local strDisabledInfo = pCity:CanTrainTooltip(id);
				if (strDisabledInfo ~= nil and strDisabledInfo ~= "") then
					strToolTip = strToolTip .. "[NEWLINE][COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR]";
				end
			else
				local strDisabledInfo = pCity:GetPurchaseUnitTooltip(id);
				if (strDisabledInfo ~= nil and strDisabledInfo ~= "") then
					strToolTip = strToolTip .. "[NEWLINE][COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR]";
				end
			end
		end
		
		controlTable.Button:SetToolTipString(strToolTip);
		
	elseif column == 2 or column == 3 then -- we are a building, wonder, project, or process
		if column == 2 then
			controlTable = g_BuildingInstanceManager:GetInstance();
		elseif column == 3 then
			controlTable = g_WonderInstanceManager:GetInstance();
		end
		
		local thisInfo;
		
		local strToolTip = "";
		
		-- Process
		if orderType == OrderTypes.ORDER_MAINTAIN then
		else
			local bBuilding;
			if orderType == OrderTypes.ORDER_CREATE then
				bBuilding = false;
				thisInfo = GameInfo.Projects[id];
				iProject = id;
			elseif orderType == OrderTypes.ORDER_CONSTRUCT then
				bBuilding = true;
				thisInfo = GameInfo.Buildings[id];
				iBuilding = id;
			end
			
			local textureOffset, textureSheet = IconLookup( thisInfo.PortraitIndex, 45, thisInfo.IconAtlas );				
			if textureOffset == nil then
				textureSheet = defaultErrorTextureSheet;
				textureOffset = nullOffset;
			end				
			controlTable.ProductionButtonImage:SetTexture(textureSheet);
			controlTable.ProductionButtonImage:SetTextureOffset(textureOffset);
			
			-- Tooltip
			if (bBuilding) then
				local bExcludeName = false;
				local bExcludeHeader = false;
				strToolTip = GetHelpTextForBuilding(id, bExcludeName, bExcludeHeader, false);
			else
				local bIncludeRequirementsInfo = false;
				strToolTip = GetHelpTextForProject(id, bIncludeRequirementsInfo);
			end
			
			-- Disabled help text
			if (isDisabled) then
				if (g_IsProductionMode) then
					local strDisabledInfo = pCity:CanConstructTooltip(id);
					if (strDisabledInfo ~= nil and strDisabledInfo ~= "") then
						strToolTip = strToolTip .. "[NEWLINE][COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR]";
					end
				else
					local strDisabledInfo = pCity:GetPurchaseBuildingTooltip(id);
					if (strDisabledInfo ~= nil and strDisabledInfo ~= "") then
						strToolTip = strToolTip .. "[NEWLINE][COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR]";
					end
				end
			end
			
		end
		
		controlTable.Button:SetToolTipString(strToolTip);
		
	else
		return
	end
    
    local nameString = L( description );
    
    listOfStrings[tostring(controlTable.Button)] = nameString;
    
    controlTable.UnitName:SetText( nameString );
    if g_IsProductionMode then
		controlTable.NumTurns:SetText(turnsLeft);
	else
		controlTable.NumTurns:SetText( turnsLeft.." [ICON_GOLD]" );
	end
    controlTable.Button:SetVoid1( orderType ); -- indicates type
    controlTable.Button:SetVoid2( id );
    controlTable.Button:RegisterCallback( Mouse.eLClick, ProductionSelected );
    controlTable.Button:RegisterCallback( Mouse.eRClick, GetProdHelp );
    controlTable.Button:SetDisabled( isDisabled );
    if( isDisabled )
    then
        controlTable.Button:SetAlpha( 0.4 );
    else
        controlTable.Button:SetAlpha( 1.0 );
    end
    
    if (iUnit >= 0) then
		for iAdvisorLoop = 0, AdvisorTypes.NUM_ADVISOR_TYPES - 1, 1 do
			abAdvisorRecommends[iAdvisorLoop] = Game.IsUnitRecommended(iUnit, iAdvisorLoop);
		end
    elseif (iBuilding >= 0) then
		for iAdvisorLoop = 0, AdvisorTypes.NUM_ADVISOR_TYPES - 1, 1 do
			abAdvisorRecommends[iAdvisorLoop] = Game.IsBuildingRecommended(iBuilding, iAdvisorLoop);
		end
    elseif (iProject >= 0) then
		for iAdvisorLoop = 0, AdvisorTypes.NUM_ADVISOR_TYPES - 1, 1 do
			abAdvisorRecommends[iAdvisorLoop] = Game.IsProjectRecommended(iProject, iAdvisorLoop);
		end    
    end
    
    for iAdvisorLoop = 0, AdvisorTypes.NUM_ADVISOR_TYPES - 1, 1 do
		local pControl = nil;
		if (iAdvisorLoop == AdvisorTypes.ADVISOR_ECONOMIC) then			
			pControl = controlTable.EconomicRecommendation;
		elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_MILITARY) then
			pControl = controlTable.MilitaryRecommendation;			
		elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_SCIENCE) then
			pControl = controlTable.ScienceRecommendation;
		elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_FOREIGN) then
			pControl = controlTable.ForeignRecommendation;
		end
	
		if (pControl) then
			pControl:SetHide(not abAdvisorRecommends[iAdvisorLoop]);
		end
    end
end


----------------------------------------------------------------        
----------------------------------------------------------------        
function OnClose()
    --UIManager:DequeuePopup( ContextPtr );
    ContextPtr:SetHide( true );
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );



----------------------------------------------------------------        
-- Input processing
----------------------------------------------------------------        
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose();
            return true;
 		--elseif wParam == Keys.VK_LEFT then
			--Game.DoControl(GameInfoTypes.CONTROL_PREVCITY);
			--return true;
		--elseif wParam == Keys.VK_RIGHT then
			--Game.DoControl(GameInfoTypes.CONTROL_NEXTCITY);
			--return true;
		end
    end
end
ContextPtr:SetInputHandler(InputHandler);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

    if( not bInitState ) then
        if( not bIsHide ) then
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION, 0);
        end
        bHidden = bIsHide;
        LuaEvents.ProductionPopup( bIsHide );
    end
end
ContextPtr:SetShowHideHandler(ShowHideHandler);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnPurchaseButton()
	g_IsProductionMode = not g_IsProductionMode;
	UpdateWindow( g_currentCity );
end
Controls.PurchaseButton:RegisterCallback( Mouse.eLClick, OnPurchaseButton );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnActivePlayerChanged()
	if (not ContextPtr:IsHidden()) then
		OnClose();
	end
end



--===============================================================================================
-- IGE HOOKS
--===============================================================================================
local function OnShowing()
	Events.SerialEventGameMessagePopup.Add(OnPopup);

	Events.SerialEventCityDestroyed.Add(OnCityDestroyed);
	Events.SerialEventCityCaptured.Add(OnCityDestroyed);

	Events.SerialEventExitCityScreen.Add(OnClose);
	Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged);

	Events.SerialEventCityScreenDirty.Add(OnDirty);
	Events.SerialEventCityInfoDirty.Add(OnDirty);
	Events.SerialEventGameDataDirty.Add(OnDirty);
	Events.SerialEventUnitInfoDirty.Add(OnDirty);
	Events.UnitSelectionChanged.Add(OnDirty);
	Events.UnitGarrison.Add(OnDirty);
	Events.UnitEmbark.Add(OnDirty);
end
LuaEvents.IGE_Showing.Add(OnShowing);

-------------------------------------------------------------------------------------------------
local function OnClosing()
    ContextPtr:SetHide(true);

	Events.SerialEventGameMessagePopup.Remove(OnPopup);

	Events.SerialEventCityDestroyed.Remove(OnCityDestroyed);
	Events.SerialEventCityCaptured.Remove(OnCityDestroyed);

	Events.SerialEventExitCityScreen.Remove(OnClose);
	Events.GameplaySetActivePlayer.Remove(OnActivePlayerChanged);

	Events.SerialEventCityScreenDirty.Remove(OnDirty);
	Events.SerialEventCityInfoDirty.Remove(OnDirty);
	Events.SerialEventGameDataDirty.Remove(OnDirty);
	Events.SerialEventUnitInfoDirty.Remove(OnDirty);
	Events.UnitSelectionChanged.Remove(OnDirty);
	Events.UnitGarrison.Remove(OnDirty);
	Events.UnitEmbark.Remove(OnDirty);
end
LuaEvents.IGE_Closing.Add(OnClosing);
