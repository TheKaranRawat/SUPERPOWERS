------------------------------------------------------
-- City View (simplified)
-- based on bc1's EUI city view for Brave New World
-- changes: no hex highlighting, no advisor icons, no dead code,
--          fewer per-update lookups, server-authoritative specialist
--          slots and multiplayer-safe UI actions
-- compatible with CSD, JFD's Piety & Prestige, Communitas
------------------------------------------------------
include( "EUI_tooltips" )

Events.SequenceGameInitComplete.Add(function()
print( "Loading EUI city view", ContextPtr, os.clock() )

-------------------------------
-- minor lua optimizations
-------------------------------
local ipairs, pairs, tonumber, tostring, unpack = ipairs, pairs, tonumber, tostring, unpack
local math_abs, math_ceil, math_floor, math_max, math_min = math.abs, math.ceil, math.floor, math.max, math.min

local civ5_mode = InStrategicView ~= nil
local civBE_mode = not civ5_mode
local gk_mode = civBE_mode or Game.GetReligionName ~= nil
local bnw_mode = civBE_mode or Game.GetActiveLeague ~= nil
local civ5bnw_mode = civ5_mode and bnw_mode
local g_currencyIcon = civ5_mode and "[ICON_GOLD]" or "[ICON_ENERGY]"
local g_maintenanceCurrency = civ5_mode and "GoldMaintenance" or "EnergyMaintenance"
local g_yieldCurrency = civ5_mode and YieldTypes.YIELD_GOLD or YieldTypes.YIELD_ENERGY
local g_focusCurrency = CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD or CityAIFocusTypes.CITY_AI_FOCUS_TYPE_ENERGY

local GreatPeopleIcons = {
	SPECIALIST_CITIZEN = "[ICON_CITIZEN]",
	SPECIALIST_WRITER = "[ICON_GREAT_WRITER]",
	SPECIALIST_ARTIST = "[ICON_GREAT_ARTIST]",
	SPECIALIST_MUSICIAN = "[ICON_GREAT_MUSICIAN]",
	SPECIALIST_SCIENTIST = "[ICON_GREAT_SCIENTIST]",
	SPECIALIST_MERCHANT = "[ICON_GREAT_MERCHANT]",
	SPECIALIST_ENGINEER = "[ICON_GREAT_ENGINEER]",
	SPECIALIST_GREAT_GENERAL = "[ICON_GREAT_GENERAL]",
	SPECIALIST_GREAT_ADMIRAL = "[ICON_GREAT_ADMIRAL]",
	SPECIALIST_PROPHET = "[ICON_PROPHET]",
	UNITCLASS_WRITER = "[ICON_GREAT_WRITER]",
	UNITCLASS_ARTIST = "[ICON_GREAT_ARTIST]",
	UNITCLASS_MUSICIAN = "[ICON_GREAT_MUSICIAN]",
	UNITCLASS_SCIENTIST = "[ICON_GREAT_SCIENTIST]",
	UNITCLASS_MERCHANT = "[ICON_GREAT_MERCHANT]",
	UNITCLASS_ENGINEER = "[ICON_GREAT_ENGINEER]",
	UNITCLASS_GREAT_GENERAL = "[ICON_GREAT_GENERAL]",
	UNITCLASS_GREAT_ADMIRAL = "[ICON_GREAT_ADMIRAL]",
	UNITCLASS_PROPHET = "[ICON_PROPHET]",
}

-- other EUI files use these
function EUI.GreatPeopleIcon( k )
	return bnw_mode and GreatPeopleIcons[k] or "[ICON_GREAT_PEOPLE]"
end
EUI.GreatPeopleIcons = GreatPeopleIcons

--EUI_utilities
local IconHookup = EUI.IconHookup
local CivIconHookup = EUI.CivIconHookup
local RadiusHexArea = EUI.RadiusHexArea
local table = EUI.table
local YieldIcons = EUI.YieldIcons
local GreatPeopleIcon = EUI.GreatPeopleIcon
local GameInfo = EUI.GameInfoCache -- warning! use iterator ONLY with table field conditions, NOT string SQL query

--EUI_tooltips
local GetGoldTooltip = civ5_mode and GetGoldTooltip or GetEnergyTooltip

local g_entryWidth = 56		-- width of one SelectionInstance button + stack padding
local g_entriesPerRow = 5

include( "SupportFunctions" )
if not civ5_mode then
	include( "IntrigueHelper" )
end

local Events_RequestYieldDisplay = Events.RequestYieldDisplay
local L = Locale.ConvertTextKey
local UI_GetHeadSelectedCity = UI.GetHeadSelectedCity
local UI_GetUnitPortraitIcon = UI.GetUnitPortraitIcon
local YieldDisplayTypes_AREA = YieldDisplayTypes.AREA
local InStrategicView = InStrategicView or function() return false end

-------------------------------
-- Globals
-------------------------------
local g_options = Modding.OpenUserData( "Enhanced User Interface Options", 1 )

local g_activePlayerID = Game.GetActivePlayer()
local g_activePlayer = Players[ g_activePlayerID ]
local g_finishedItems = {}

local g_workerHeadingOpen = true

local g_rightTipControls = {}
local g_leftTipControls = {}
TTManager:GetTypeControlTable( "EUI_CityViewRightTooltip", g_rightTipControls )
TTManager:GetTypeControlTable( "EUI_CityViewLeftTooltip", g_leftTipControls )

local g_worldPositionOffset = { x = 0, y = 0, z = 30 }
local g_worldPositionOffset2 = { x = 0, y = 35, z = 0 }
local g_portraitSize = Controls.PQportrait:GetSizeX()
local g_screenHeight = select( 2, UIManager:GetScreenSizeVal() )
local g_leftStackHeight = g_screenHeight - 40 - Controls.CityInfoBG:GetOffsetY() - Controls.CityInfoBG:GetSizeY()

local g_PlotButtonIM = StackInstanceManager( "PlotButtonInstance", "PlotButtonAnchor", Controls.PlotButtonContainer )
local g_BuyPlotButtonIM = StackInstanceManager( "BuyPlotButtonInstance", "BuyPlotButtonAnchor", Controls.PlotButtonContainer )
local g_ProdQueueIM, g_SpecialBuildingsIM, g_GreatWorkIM, g_WondersIM, g_BuildingsIM, g_SlackerIM
local g_UnitSelectIM, g_CivilianSelectIM, g_BuildingSelectIM, g_WonderSelectIM, g_ProcessSelectIM, g_FocusSelectIM
local g_slots = table()
local g_works = table()
local g_heap = Controls.Scrap

local g_queuedItemNumber = false
local g_isViewingMode = true
local g_isDebugMode = false
local g_BuyPlotMode = not ( g_options and g_options.GetValue and g_options.GetValue( "CityPlotPurchase" ) == 0 )
local g_isCityViewDirty, g_isPlotButtonsDirty

local g_isButtonPopupChooseProduction = false
local g_chainVisited = {}
local g_isAutoClose

-- units that have no Combat/RangedCombat but should stay in the military list
local g_forceMilitary = {
	UNIT_ATOMIC_BOMB = true,
	UNIT_NUCLEAR_MISSILE = true,
	UNIT_TSAR_BOMBA = true,
	UNIT_ICBM_MISSILE = true,
}

local function IsCivilianUnit( item )
	if g_forceMilitary[ item.Type ] then
		return false
	end
	return ( tonumber( item.Combat ) or 0 ) <= 0 and ( tonumber( item.RangedCombat ) or 0 ) <= 0
end

local g_slotTexture = {
	SPECIALIST_CITIZEN = "CitizenUnemployed.dds",
	SPECIALIST_SCIENTIST = "CitizenScientist.dds",
	SPECIALIST_MERCHANT = "CitizenMerchant.dds",
	SPECIALIST_ARTIST = "CitizenArtist.dds",
	SPECIALIST_MUSICIAN = "CitizenArtist.dds",
	SPECIALIST_WRITER = "CitizenArtist.dds",
	SPECIALIST_ENGINEER = "CitizenEngineer.dds",
	SPECIALIST_CIVIL_SERVANT = "CitizenCivilServant.dds",	-- CSD
	SPECIALIST_JFD_MONK = "CitizenMonk.dds",				-- JFD's Piety & Prestige
	SPECIALIST_PMMM_ENTERTAINER = "PMMMEntertainmentSpecialist.dds",
}
for specialist in GameInfo.Specialists() do
	if specialist.SlotTexture then
		g_slotTexture[ specialist.Type ] = specialist.SlotTexture
	end
end

local g_slackerTexture = civBE_mode and "UnemployedIndicator.dds"
	or g_slotTexture[ ( GameInfo.Specialists[ GameDefines.DEFAULT_SPECIALIST or -1 ] or {} ).Type ] or "Blank.dds"

local g_gameInfo = {
	[OrderTypes.ORDER_TRAIN] = GameInfo.Units,
	[OrderTypes.ORDER_CONSTRUCT] = GameInfo.Buildings,
	[OrderTypes.ORDER_CREATE] = GameInfo.Projects,
	[OrderTypes.ORDER_MAINTAIN] = GameInfo.Processes,
}

local function SetupCallbacks( controls, toolTips, toolTipType, callBacks )
	for name, callback in pairs( toolTips ) do
		local control = controls[name]
		if control then
			control:SetToolTipCallback( callback )
			control:SetToolTipType( toolTipType )
		end
	end
	for name, eventCallbacks in pairs( callBacks ) do
		local control = controls[name]
		if control then
			for event, callback in pairs( eventCallbacks ) do
				control:RegisterCallback( event, callback )
			end
		end
	end
end

-------------------------------
-- Layout
-------------------------------
-- resize one wrapped selection grid and its background, returns stack height
local function FitSelectionGrid( stack, grid, bg )
	stack:SetWrapWidth( g_entryWidth * g_entriesPerRow )
	stack:CalculateSize()
	local width = math_max( stack:GetSizeX(), 273 )
	local height = stack:GetSizeY()
	grid:SetSizeX( width )
	grid:SetSizeY( height + 4 )
	grid:ReprocessAnchoring()
	bg:SetSizeX( width - 3 )
	bg:SetSizeY( height )
	bg:ReprocessAnchoring()
	return height
end

local function DoResizeProdQueue()
	local queuePanelHeight = math_min( 190, Controls.QueueStack:IsHidden() and 0 or Controls.QueueStack:GetSizeY() )	-- 190 = 5 x 38

	Controls.QueueSlider:SetSizeY( queuePanelHeight + 38 )
	Controls.QueueScrollPanel:SetSizeY( queuePanelHeight )
	Controls.QueueScrollPanel:CalculateInternalSize()
	Controls.QueueBackground:SetSizeY( queuePanelHeight + 152 )

	-- civilian grid: fixed height
	Controls.CivilianButtonStack:CalculateSize()
	local civilianWidth = math_max( Controls.CivilianButtonStack:GetSizeX(), 273 )
	Controls.CivilianGrid:SetSizeX( civilianWidth )
	Controls.CivilianGrid:SetSizeY( 44 )
	Controls.CivilianGrid:ReprocessAnchoring()
	Controls.CivilianBG:SetSizeX( civilianWidth - 3 )
	Controls.CivilianBG:SetSizeY( 40 )
	Controls.CivilianBG:ReprocessAnchoring()

	local unitHeight = FitSelectionGrid( Controls.UnitButtonStack, Controls.UnitGrid, Controls.UnitBG )
	local buildingHeight = FitSelectionGrid( Controls.BuildingButtonStack, Controls.BuildingGrid, Controls.BuildBG )
	local wonderHeight = FitSelectionGrid( Controls.WonderButtonStack, Controls.WonderGrid, Controls.WonderBG )

	Controls.OtherBG:SetSizeX( 269 )
	Controls.OtherBG:SetSizeY( 41 )
	Controls.OtherBG:ReprocessAnchoring()

	if not Controls.SelectionScrollPanel:IsHidden() then
		Controls.SelectionStacks:CalculateSize()
		local selectionPanelHeight = math_max( math_min( g_leftStackHeight - queuePanelHeight + wonderHeight + buildingHeight + unitHeight, Controls.SelectionStacks:GetSizeY() ), 260 )
		Controls.SelectionScrollPanel:SetSizeY( selectionPanelHeight )
		Controls.SelectionScrollPanel:ReprocessAnchoring()
	end

	return Controls.QueueBackground:ReprocessAnchoring()
end

local function DoResizeRightStack()
	Controls.BoxOSlackers:SetHide( Controls.SlackerStack:IsHidden() )
	Controls.BoxOSlackers:SetSizeY( Controls.SlackerStack:GetSizeY() )
	Controls.WorkerManagementBox:CalculateSize()
	Controls.WorkerManagementBox:ReprocessAnchoring()
	Controls.RightStack:CalculateSize()
	local rightStackHeight = Controls.RightStack:GetSizeY() + 85
	Controls.BuildingListBackground:SetSizeY( math_max( math_min( g_screenHeight + 48, rightStackHeight ), 160 ) )
	Controls.RightScrollPanel:SetSizeY( math_min( g_screenHeight - 38, rightStackHeight ) )
	Controls.RightScrollPanel:CalculateInternalSize()
	return Controls.RightScrollPanel:ReprocessAnchoring()
end

-- batching: many stack changes in one update only trigger one layout pass
local g_batching = false
local g_queuePending = false
local g_rightPending = false

local function ResizeProdQueue()
	if g_batching then g_queuePending = true return end
	return DoResizeProdQueue()
end

local function ResizeRightStack()
	if g_batching then g_rightPending = true return end
	return DoResizeRightStack()
end

local function RunBatched( func )
	g_batching = true
	local ok, err = pcall( func )
	g_batching = false
	if g_rightPending then g_rightPending = false DoResizeRightStack() end
	if g_queuePending then g_queuePending = false DoResizeProdQueue() end
	if not ok then error( err, 0 ) end
end

-------------------------------
-- City access (multiplayer safe)
-------------------------------
-- In multiplayer nothing may be sent while it is not our turn.
local function GetSelectedCity()
	return ( not Game.IsNetworkMultiPlayer() or g_activePlayer:IsTurnActive() ) and UI_GetHeadSelectedCity()
end

-- Only our own, non-viewing-mode city can be modified.
local function GetSelectedModifiableCity()
	if g_isViewingMode then
		return false
	end
	local city = GetSelectedCity()
	return city and city:GetOwner() == g_activePlayerID and city
end

local cityIsCanPurchase
if gk_mode then
	function cityIsCanPurchase( city, ... )
		return city:IsCanPurchase( ... )
	end
else
	function cityIsCanPurchase( city, bTestPurchaseCost, bTestTrainable, unitID, buildingID, projectID, yieldID )
		if yieldID == g_yieldCurrency then
			return city:IsCanPurchase( not bTestPurchaseCost, unitID, buildingID, projectID )
		else
			return false
		end
	end
end

-- Clear the UI so the next update doesn't show the previous player's values
local function ClearCityUIInfo()
	g_ProdQueueIM.ResetInstances()
	g_ProdQueueIM.Commit()
	Controls.PQremove:SetHide( true )
	Controls.PQrank:SetText()
	Controls.PQname:SetText()
	Controls.PQturns:SetText()
	return Controls.ProductionPortraitButton:SetHide( true )
end

--------------------
-- Selling Buildings
--------------------
local function SellBuilding( buildingID )
	local city = GetSelectedModifiableCity()
	if city and city:IsBuildingSellable( buildingID ) then
		local building = GameInfo.Buildings[ buildingID ]
		Controls.SellBuildingPopupText:SetText( L( building.Description ) .. ": "
			.. L( "TXT_KEY_SELL_BUILDING_INFO", city:GetSellBuildingRefund( buildingID ), building[ g_maintenanceCurrency ] or 0 ) )
		Controls.YesButton:SetVoids( city:GetID(), buildingID )
		return Controls.SellBuildingConfirm:SetHide( false )
	end
end

local function CancelBuildingSale()
	Controls.SellBuildingConfirm:SetHide( true )
	return Controls.YesButton:SetVoids( -1, -1 )
end

-------------------------------
-- Navigation
-------------------------------
local function ExitCityButNotScreen()
	g_leftTipControls.Box:SetHide( true )
	g_rightTipControls.Box:SetHide( true )
	g_isButtonPopupChooseProduction = false
	g_chainVisited = {}
	Controls.RightScrollPanel:SetScrollValue( 0 )
	return CancelBuildingSale()
end

local function GotoNextCity()
	ExitCityButNotScreen()
	return Game.DoControl( GameInfoTypes.CONTROL_NEXTCITY )
end

local function GotoPrevCity()
	ExitCityButNotScreen()
	return Game.DoControl( GameInfoTypes.CONTROL_PREVCITY )
end

-- next city without production that was not yet skipped in this chain
local function FindNextIdleCity( currentCityID )
	if Game.IsNetworkMultiPlayer() and not g_activePlayer:IsTurnActive() then
		return nil
	end
	for city in g_activePlayer:Cities() do
		local id = city:GetID()
		if id ~= currentCityID and not g_chainVisited[ id ] and not city:IsPuppet() and city:GetOrderQueueLength() < 1 then
			return city
		end
	end
end

local function ExitCityScreen()
	local wasProductionPopup = g_isButtonPopupChooseProduction	-- ExitCityButNotScreen() resets it
	local city = UI_GetHeadSelectedCity()
	local cityID = city and city:GetID()
	ExitCityButNotScreen()
	Events.SerialEventExitCityScreen()
	if wasProductionPopup and cityID then
		-- after exit, so the exit handler's own camera move can't override it
		local nextCity = FindNextIdleCity( cityID )
		if nextCity then
			g_isButtonPopupChooseProduction = g_isAutoClose	-- keeps the chain going on the next ESC
			UI.DoSelectCityAtPlot( nextCity:Plot() )
		end
	end
end

-- ESC / right click: go to the next idle city, or leave when there are none left
local function CloseOrAdvanceCityScreen()
	if g_isButtonPopupChooseProduction then
		local city = UI_GetHeadSelectedCity()
		if city then
			g_chainVisited[ city:GetID() ] = true	-- skipped cities are not revisited
		end
		local nextCity = FindNextIdleCity( city and city:GetID() )
		if nextCity then
			g_leftTipControls.Box:SetHide( true )
			g_rightTipControls.Box:SetHide( true )
			Controls.RightScrollPanel:SetScrollValue( 0 )
			CancelBuildingSale()
			UI.SelectCity( nextCity )
			return UI.LookAtSelectionPlot()
		end
	end
	return ExitCityScreen()
end

local function SafeCloseOrAdvance()
	local ok, err = pcall( CloseOrAdvanceCityScreen )
	if not ok then print( err ) end
	return true
end

ContextPtr:SetInputHandler(
function( uiMsg, wParam )
	-- key strokes in log
	if uiMsg == KeyEvents.KeyDown then
		print("Key down: " .. tostring(wParam))
	end

	-- mouse keys
	print("uiMsg: " .. tostring(uiMsg) .. "  wParam: " .. tostring(wParam))

	if wParam == Keys.VK_ESCAPE then
		if uiMsg == KeyEvents.KeyDown then
			return true				-- swallow; act on key-up
		elseif uiMsg == KeyEvents.KeyUp then
			return SafeCloseOrAdvance()
		end
	elseif uiMsg == KeyEvents.KeyDown then
		if wParam == Keys.VK_LEFT then
			GotoPrevCity()
			return true
		elseif wParam == Keys.VK_RIGHT then
			GotoNextCity()
			return true
		end
	elseif uiMsg == MouseEvents.RButtonUp then
		return SafeCloseOrAdvance()
	-- mouse left button 523
	elseif uiMsg == 523 then
		GotoNextCity()
		return true
	end
	return false
end)

-------------------------------
-- Pedia
-------------------------------
local function UnitClassPedia( unitClassID )
	return Events.SearchForPediaEntry( GameInfo.UnitClasses[ unitClassID ].Description )
end

local function BuildingPedia( buildingID )
	return Events.SearchForPediaEntry( GameInfo.Buildings[ buildingID ].Description )
end

local function SpecialistPedia( buildingID )
	local building = buildingID and GameInfo.Buildings[ buildingID ]
	local specialistType = building and building.SpecialistType
	local specialistID = specialistType and GameInfoTypes[ specialistType ] or GameDefines.DEFAULT_SPECIALIST
	local specialist = specialistID and GameInfo.Specialists[ specialistID ]
	return Events.SearchForPediaEntry( specialist and tostring( specialist.Description ) )
end

local function SelectionPedia( orderID, itemID )
	local item = g_gameInfo[ orderID ]
	item = item and item[ itemID ]
	if item then
		return Events.SearchForPediaEntry( item.Description )
	end
end

local function ProductionPedia( queuedItemNumber )
	local city = UI_GetHeadSelectedCity()
	if city and queuedItemNumber then
		return SelectionPedia( city:GetOrderFromQueue( queuedItemNumber ) )
	end
end

-------------------------------
-- Tooltips
-------------------------------
local function GetSpecialistYields( city, specialist )
	local yieldTips = table()
	if city and specialist then
		local specialistID = specialist.ID
		local cityOwner = Players[ city:GetOwner() ]
		local cultureFromSpecialist = city:GetCultureFromSpecialist( specialistID )
		local specialistCultureModifier = city:GetCultureRateModifier()
			+ ( cityOwner and ( cityOwner:GetCultureCityModifier() + ( city:GetNumWorldWonders() > 0 and cityOwner:GetCultureWonderMultiplier() or 0 ) ) or 0 )
		for yieldID = 0, YieldTypes.NUM_YIELD_TYPES - 1 do
			local specialistYield = city:GetSpecialistYield( specialistID, yieldID )
			local specialistYieldModifier = city:GetBaseYieldRateModifier( yieldID )
			if yieldID == YieldTypes.YIELD_CULTURE then
				specialistYield = specialistYield + cultureFromSpecialist
				specialistYieldModifier = specialistYieldModifier + specialistCultureModifier
				cultureFromSpecialist = 0
			end
			yieldTips:insertIf( specialistYield ~= 0 and specialistYield * specialistYieldModifier / 100 .. tostring( YieldIcons[ yieldID ] ) )
		end
		yieldTips:insertIf( cultureFromSpecialist ~= 0 and cultureFromSpecialist .. "[ICON_CULTURE]" )
		yieldTips:insertIf( civ5_mode and ( specialist.GreatPeopleRateChange or 0 ) ~= 0 and specialist.GreatPeopleRateChange .. GreatPeopleIcon( specialist.Type ) )
	end
	return yieldTips:concat( " " )
end

local function SpecialistTooltip( control )
	local buildingID = control:GetVoid1()
	local building = buildingID and GameInfo.Buildings[ buildingID ]
	local specialistType = building and building.SpecialistType
	local specialistID = specialistType and GameInfoTypes[ specialistType ] or GameDefines.DEFAULT_SPECIALIST
	local specialist = GameInfo.Specialists[ specialistID ]
	local city = UI_GetHeadSelectedCity()
	local strToolTip = L( specialist.Description ) .. " " .. GetSpecialistYields( city, specialist )
	-- slot state comes straight from the city, never from local UI state
	if building and city and control:GetVoid2() > city:GetNumSpecialistsInBuilding( buildingID ) then
		strToolTip = L"TXT_KEY_CITYVIEW_EMPTY_SLOT" .. "[NEWLINE](" .. strToolTip .. ")"
	end
	g_rightTipControls.Text:SetText( strToolTip )
	IconHookup( specialist.PortraitIndex, g_rightTipControls.Portrait:GetSizeY(), specialist.IconAtlas, g_rightTipControls.Portrait )
	g_rightTipControls.Box:SetHide( false )
	return g_rightTipControls.Box:DoAutoSize()
end

local function BuildingToolTip( control )
	local buildingID = control:GetVoid1()
	local building = GameInfo.Buildings[ buildingID ]
	local city = UI_GetHeadSelectedCity()
	if city and building then
		g_rightTipControls.Text:SetText( GetHelpTextForBuilding( buildingID, false, false, city:GetNumFreeBuilding( buildingID ) > 0, city ) )
		IconHookup( building.PortraitIndex, g_rightTipControls.Portrait:GetSizeY(), building.IconAtlas, g_rightTipControls.Portrait )
		g_rightTipControls.Box:SetHide( false )
		return g_rightTipControls.Box:DoAutoSize()
	end
end

local function OrderItemTooltip( city, isDisabled, purchaseYieldID, orderID, itemID, _, isRepeat )
	local itemInfo, strToolTip, strDisabledInfo, portraitOffset, portraitAtlas, isRealRepeat
	if city then
		if orderID == OrderTypes.ORDER_TRAIN then
			itemInfo = GameInfo.Units
			portraitOffset, portraitAtlas = UI_GetUnitPortraitIcon( itemID, city:GetOwner() )
			strToolTip = GetHelpTextForUnit( itemID, true )
			isRealRepeat = isRepeat
			if isDisabled then
				if purchaseYieldID == g_yieldCurrency then
					strDisabledInfo = city:GetPurchaseUnitTooltip( itemID )
				elseif purchaseYieldID == YieldTypes.YIELD_FAITH then
					strDisabledInfo = city:GetFaithPurchaseUnitTooltip( itemID )
				else
					strDisabledInfo = city:CanTrainTooltip( itemID )
				end
			end
		elseif orderID == OrderTypes.ORDER_CONSTRUCT then
			itemInfo = GameInfo.Buildings
			strToolTip = GetHelpTextForBuilding( itemID, false, false, city:GetNumFreeBuilding( itemID ) > 0, city )
			if isDisabled then
				if purchaseYieldID == g_yieldCurrency then
					strDisabledInfo = city:GetPurchaseBuildingTooltip( itemID )
				elseif purchaseYieldID == YieldTypes.YIELD_FAITH then
					strDisabledInfo = city:GetFaithPurchaseBuildingTooltip( itemID )
				else
					strDisabledInfo = city:CanConstructTooltip( itemID )
				end
			end
		elseif orderID == OrderTypes.ORDER_CREATE then
			itemInfo = GameInfo.Projects
			strToolTip = GetHelpTextForProject( itemID, true )
		elseif orderID == OrderTypes.ORDER_MAINTAIN then
			itemInfo = GameInfo.Processes
			strToolTip = GetHelpTextForProcess( itemID, true )
			isRealRepeat = true
		else
			strToolTip = L"TXT_KEY_PRODUCTION_NO_PRODUCTION"
		end
		if strToolTip then
			if isRealRepeat then
				strToolTip = "[ICON_TURNS_REMAINING]" .. strToolTip
			end
			if strDisabledInfo and #strDisabledInfo > 0 then
				strDisabledInfo = ( strDisabledInfo:gsub( "^%[NEWLINE%]", "" ) ):gsub( "^%[NEWLINE%]", "" )
				strToolTip = "[COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR][NEWLINE][NEWLINE]" .. strToolTip
			elseif purchaseYieldID then
				if not isDisabled then
					strToolTip = "[COLOR_YELLOW]" .. L"TXT_KEY_CITYVIEW_PURCHASE_TT" .. "[ENDCOLOR][NEWLINE][NEWLINE]" .. strToolTip
				end
			elseif isDisabled then
				strToolTip = "[COLOR_YIELD_FOOD]" .. L"TXT_KEY_CITYVIEW_QUEUE_PROD_TT" .. "[ENDCOLOR][NEWLINE][NEWLINE]" .. strToolTip
			end
		end
		local item = itemInfo and itemInfo[ itemID ]
		item = item and IconHookup( portraitOffset or item.PortraitIndex, g_leftTipControls.Portrait:GetSizeY(), portraitAtlas or item.IconAtlas, g_leftTipControls.Portrait )
		g_leftTipControls.Text:SetText( strToolTip )
		g_leftTipControls.PortraitFrame:SetHide( not item )
		g_leftTipControls.Box:DoAutoSize()
	end
	return g_leftTipControls.Box:SetHide( not strToolTip )
end

local function ProductionToolTip( control )
	local city = UI_GetHeadSelectedCity()
	local queuedItemNumber = control:GetVoid1()
	if city and queuedItemNumber and not Controls.QueueSlider:IsTrackingLeftMouseButton() then
		return OrderItemTooltip( city, false, false, city:GetOrderFromQueue( queuedItemNumber ) )
	end
end

local function SelectionToolTip( control )
	return OrderItemTooltip( UI_GetHeadSelectedCity(), true, false, control:GetVoid1(), control:GetVoid2() )
end

-------------------------------
-- Specialist Management
-------------------------------
local function OnSlackersSelected( buildingID, slotID )
	local city = GetSelectedModifiableCity()
	if city then
		for i = 1, slotID <= 0 and city:GetSpecialistCount( GameDefines.DEFAULT_SPECIALIST ) or 1 do
			Network.SendDoTask( city:GetID(), TaskTypes.TASK_REMOVE_SLACKER, 0, -1, false )
		end
	end
end

-- Slot state is read from the city every time, nothing is predicted locally.
-- The network layer validates every request, so a fast double click is harmless.
local function ToggleSpecialist( buildingID, slotID )
	local city = buildingID and slotID and GetSelectedModifiableCity()
	if not city then
		return
	end

	-- manual assignment is impossible while specialists are automated
	if civ5_mode and not city:IsNoAutoAssignSpecialists() then
		Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_NO_AUTO_ASSIGN_SPECIALISTS, -1, -1, true )
		Controls.NoAutoSpecialistCheckbox:SetCheck( true )
		if bnw_mode then
			Controls.NoAutoSpecialistCheckbox2:SetCheck( true )
		end
	end

	local specialistID = GameInfoTypes[ ( GameInfo.Buildings[ buildingID ] or {} ).SpecialistType ] or -1
	if slotID <= city:GetNumSpecialistsInBuilding( buildingID ) then
		return Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_REMOVE_SPECIALIST, specialistID, buildingID )
	elseif city:IsCanAddSpecialistToBuilding( buildingID ) then
		return Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_ADD_SPECIALIST, specialistID, buildingID )
	end
end

-------------------------------
-- Great Work Management
-------------------------------
local function GreatWorkPopup( greatWorkID )
	local greatWork = GameInfo.GreatWorks[ Game.GetGreatWorkType( greatWorkID or -1 ) or -1 ]
	if greatWork and greatWork.GreatWorkClassType ~= "GREAT_WORK_ARTIFACT" then
		return Events.SerialEventGameMessagePopup{
			Type = ButtonPopupTypes.BUTTONPOPUP_GREAT_WORK_COMPLETED_ACTIVE_PLAYER,
			Data1 = greatWorkID,
			Priority = PopupPriority.Current
		}
	end
end

local function YourCulturePopup()
	return Events.SerialEventGameMessagePopup{
		Type = ButtonPopupTypes.BUTTONPOPUP_CULTURE_OVERVIEW,
		Data1 = 1,
		Data2 = 1,
	}
end

local function GreatWorkTooltip( greatWorkID, greatWorkSlotID, slot )
	if greatWorkID >= 0 then
		return slot:SetToolTipString( Game.GetGreatWorkTooltip( greatWorkID, UI_GetHeadSelectedCity():GetOwner() ) )
	else
		return slot:LocalizeAndSetToolTip( tostring( ( GameInfo.GreatWorkSlots[ greatWorkSlotID ] or {} ).EmptyToolTipText ) )
	end
end

-------------------------------------------------
-- Static data, built once at load
-------------------------------------------------
local function sortBuildings( a, b )
	if a and b then
		if a[4] ~= b[4] then
			return a[4] < b[4]
		elseif a[3] ~= b[3] then
			return a[3] > b[3]
		end
		return a[2] < b[2]
	end
end

-- yieldID -> yield type string
local g_yieldTypes = {}
for yieldID = 0, YieldTypes.NUM_YIELD_TYPES - 1 do
	g_yieldTypes[ yieldID ] = ( GameInfo.Yields[ yieldID ] or {} ).Type or -1
end

-- g_popYield[ BuildingType ][ YieldType ] = summed per-pop yield
local g_popYield = {}
for row in GameInfo.Building_YieldChangesPerPop() do
	local b, y = row.BuildingType, row.YieldType
	if b and y then
		local t = g_popYield[ b ]
		if not t then
			t = {}
			g_popYield[ b ] = t
		end
		t[ y ] = ( t[ y ] or 0 ) + ( row.Yield or 0 )
	end
end

-- flat lists and per-building class info
local g_buildingList, g_buildingClass, g_isWonderBuilding = {}, {}, {}
for item in GameInfo.Buildings() do
	g_buildingList[ #g_buildingList + 1 ] = item
	local class = GameInfo.BuildingClasses[ item.BuildingClass ]
	g_buildingClass[ item.ID ] = class
	g_isWonderBuilding[ item.ID ] = ( class and ( class.MaxGlobalInstances > 0 or class.MaxPlayerInstances == 1 or class.MaxTeamInstances > 0 ) ) and true or false
end

local g_unitList, g_isCivilianUnit = {}, {}
for item in GameInfo.Units() do
	g_unitList[ #g_unitList + 1 ] = item
	g_isCivilianUnit[ item.ID ] = IsCivilianUnit( item )
end

local g_projectList = {}
for item in GameInfo.Projects() do
	g_projectList[ #g_projectList + 1 ] = item
end

local g_processList = {}
for item in GameInfo.Processes() do
	g_processList[ #g_processList + 1 ] = item
end

-- localized-name cache (language can't change mid-game)
local g_nameCache = {}
local function LocalName( key )
	if not key then return "" end
	local s = g_nameCache[ key ]
	if not s then
		s = L( key )
		g_nameCache[ key ] = s
	end
	return s
end

-- integer key for "already in queue" lookups
local function QueueKey( orderID, itemID )
	return orderID * 100000 + itemID
end

-------------------------------------------------
-- City Buildings List
-------------------------------------------------
local function SetupBuildingList( city, buildings, buildingIM )
	buildingIM.ResetInstances()
	if #buildings < 1 then
		return buildingIM.Commit()
	end
	buildings:sort( sortBuildings )

	local cityOwnerID = city:GetOwner()
	local cityOwner = Players[ cityOwnerID ]
	local isNotResistance = not city:IsResistance()
	local cityOwnerPerks = civBE_mode and cityOwner:GetAllActivePlayerPerkTypes()

	-- per-city values
	local population = city:GetPopulation()
	local foodPerPop = GameDefines.FOOD_CONSUMPTION_PER_POPULATION
	local isFoodShort = city:FoodConsumption() < foodPerPop * population
	local halfSpecialistUnhappiness = 0
	if civ5_mode and cityOwner:IsHalfSpecialistUnhappiness() then
		halfSpecialistUnhappiness = GameDefines.UNHAPPINESS_PER_POPULATION
			* ( ( city:IsCapital() and cityOwner:GetCapitalUnhappinessMod() or 0 ) + 100 )
			* ( cityOwner:GetUnhappinessMod() + 100 )
			* ( cityOwner:GetTraitPopUnhappinessMod() + 100 ) / 2e6
	end
	local numYields = YieldTypes.NUM_YIELD_TYPES - 1

	for i = 1, #buildings do
		local building, buildingName, greatWorkCount = unpack( buildings[i] )
		local buildingID = building.ID
		local buildingType = building.Type
		local controls, isNewInstance = buildingIM.GetInstance()
		local buildingButton = controls.Button
		local textButton = controls.TextButton
		textButton:SetHide( true )

		if isNewInstance then
			buildingButton:RegisterCallback( Mouse.eRClick, BuildingPedia )
			buildingButton:RegisterCallback( Mouse.eLClick, SellBuilding )
			buildingButton:SetToolTipCallback( BuildingToolTip )
			controls.SellButton:SetHide( true )		-- the sell button is not used in this UI
		else
			-- recycle slot controls
			for _, slot in pairs( controls[1] ) do
				g_slots:insert( slot )
				slot:ChangeParent( g_heap )
			end
			for _, slot in pairs( controls[2] ) do
				g_works:insert( slot )
				slot:ChangeParent( g_heap )
			end
		end
		controls[1] = table()
		controls[2] = table()
		buildingButton:SetVoid1( buildingID )

		local slotStack = controls.SlotStack
		local instance	-- created lazily, only when a new slot control must be built

		controls.Portrait:SetHide( not IconHookup( building.PortraitIndex, 128, building.IconAtlas, controls.Portrait ) )

		-------------------
		-- Great Work Slots
		if greatWorkCount > 0 then
			local buildingGreatWorkSlot = building.GreatWorkSlotType and GameInfo.GreatWorkSlots[ building.GreatWorkSlotType ]
			if buildingGreatWorkSlot then
				local buildingClassID = GameInfoTypes[ building.BuildingClass ]

				if city:IsThemingBonusPossible( buildingClassID ) then
					textButton:SetText( " +" .. city:GetThemingBonus( buildingClassID ) )
					textButton:SetVoid1( buildingClassID )
					textButton:SetHide( false )
				end

				for n = 0, greatWorkCount - 1 do
					local slot = g_works:remove()
					if slot then
						slot:ChangeParent( slotStack )
					else
						instance = instance or {}
						ContextPtr:BuildInstanceForControl( "Work", instance, slotStack )
						slot = instance.Button
						slot:RegisterCallback( Mouse.eLClick, YourCulturePopup )
						slot:RegisterCallback( Mouse.eMouseEnter, GreatWorkTooltip )
					end
					controls[2]:insert( slot )
					local greatWorkID = city:GetBuildingGreatWork( buildingClassID, n )
					slot:SetVoids( greatWorkID, buildingGreatWorkSlot.ID )
					if greatWorkID >= 0 then
						slot:SetTexture( buildingGreatWorkSlot.FilledIcon )
						slot:RegisterCallback( Mouse.eRClick, GreatWorkPopup )
					else
						slot:SetTexture( buildingGreatWorkSlot.EmptyIcon )
						slot:ClearCallback( Mouse.eRClick )
					end
				end
			end
		end

		-------------------
		-- Specialist Slots
		local numSpecialistsInBuilding = city:GetNumSpecialistsInBuilding( buildingID )
		local specialistType = building.SpecialistType
		local specialist = GameInfo.Specialists[ specialistType ]
		if specialist then
			for slotID = 1, city:GetNumSpecialistsAllowedByBuilding( buildingID ) do
				local isFilled = slotID <= numSpecialistsInBuilding
				local slot = g_slots:remove()
				if slot then
					slot:ChangeParent( slotStack )
				else
					instance = instance or {}
					ContextPtr:BuildInstanceForControl( "Slot", instance, slotStack )
					slot = instance.Button
					slot:RegisterCallback( Mouse.eRClick, SpecialistPedia )
					slot:SetToolTipCallback( SpecialistTooltip )
				end
				controls[1]:insert( slot )
				if civ5_mode then
					slot:SetTexture( isFilled and g_slotTexture[ specialistType ] or "CitizenEmpty.dds" )
				elseif instance and instance.Portrait then
					IconHookup( specialist.PortraitIndex, 45, specialist.IconAtlas, instance.Portrait )
					instance.Portrait:SetHide( not isFilled )
				end
				slot:SetVoids( buildingID, slotID )
				if g_isViewingMode then
					slot:ClearCallback( Mouse.eLClick )
				else
					slot:RegisterCallback( Mouse.eLClick, ToggleSpecialist )
				end
			end
		end

		-------------------
		-- Building stats / bonuses
		local buildingClassID = GameInfoTypes[ building.BuildingClass ] or -1
		local maintenanceCost = tonumber( building[ g_maintenanceCurrency ] ) or 0
		local defenseChange = tonumber( building.Defense ) or 0
		local hitPointChange = tonumber( building.ExtraCityHitPoints ) or 0
		local buildingCultureRate = ( not gk_mode and tonumber( building.Culture ) or 0 )
			+ ( specialist and city:GetCultureFromSpecialist( specialist.ID ) or 0 ) * numSpecialistsInBuilding
		local tips = table()

		if civ5_mode then
			local happinessChange = ( tonumber( building.Happiness ) or 0 ) + ( tonumber( building.UnmoddedHappiness ) or 0 )
				+ cityOwner:GetExtraBuildingHappinessFromPolicies( buildingID )
				+ halfSpecialistUnhappiness * numSpecialistsInBuilding
			tips:insertIf( happinessChange ~= 0 and happinessChange .. "[ICON_HAPPINESS_1]" )
		else
			local healthChange = ( tonumber( building.Health ) or 0 ) + ( tonumber( building.UnmoddedHealth ) or 0 ) + cityOwner:GetExtraBuildingHealthFromPolicies( buildingID )
			for _, perkID in ipairs( cityOwnerPerks ) do
				healthChange = healthChange + Game.GetPlayerPerkBuildingClassPercentHealthChange( perkID, buildingClassID )
				defenseChange = defenseChange + Game.GetPlayerPerkBuildingClassCityStrengthChange( perkID, buildingClassID )
				hitPointChange = hitPointChange + Game.GetPlayerPerkBuildingClassCityHPChange( perkID, buildingClassID )
				maintenanceCost = maintenanceCost + Game.GetPlayerPerkBuildingClassEnergyMaintenanceChange( perkID, buildingClassID )
			end
			tips:insertIf( healthChange ~= 0 and healthChange .. "[ICON_HEALTH_1]" )
		end

		-- yields
		local popYieldRow = g_popYield[ buildingType ]
		for yieldID = 0, numYields do
			local isProducing = isNotResistance
			local rate = Game.GetBuildingYieldChange( buildingID, yieldID )
			if gk_mode then
				rate = rate + cityOwner:GetPlayerBuildingClassYieldChange( buildingClassID, yieldID )
					+ city:GetReligionBuildingClassYieldChange( buildingClassID, yieldID )
				if bnw_mode then
					rate = rate + city:GetLeagueBuildingClassYieldChange( buildingClassID, yieldID )
				end
			end
			if civBE_mode then
				for _, perkID in ipairs( cityOwnerPerks ) do
					rate = rate + Game.GetPlayerPerkBuildingClassFlatYieldChange( perkID, buildingClassID, yieldID )
				end
			end
			if specialist then
				rate = rate + numSpecialistsInBuilding * city:GetSpecialistYield( specialist.ID, yieldID )
			end

			if yieldID == YieldTypes.YIELD_CULTURE then
				rate = rate + buildingCultureRate
			elseif yieldID == YieldTypes.YIELD_FOOD then
				if isFoodShort then
					rate = rate + foodPerPop * numSpecialistsInBuilding / 2
				end
				isProducing = true
			end

			local perPop = popYieldRow and popYieldRow[ g_yieldTypes[ yieldID ] ]
			if perPop then
				rate = rate + perPop * population / 100
			end

			if isProducing and rate ~= 0 then
				tips:insert( rate .. tostring( YieldIcons[ yieldID ] ) )
			end
		end

		if civ5_mode and building.IsReligious then
			buildingName = L( "TXT_KEY_RELIGIOUS_BUILDING", buildingName, cityOwner:GetStateReligionKey() )
		end
		if city:GetNumFreeBuilding( buildingID ) > 0 then
			buildingName = buildingName .. " (" .. LocalName( "TXT_KEY_FREE" ) .. ")"
		else
			tips:insertIf( maintenanceCost ~= 0 and -maintenanceCost .. g_currencyIcon )
		end
		controls.Name:SetText( buildingName )

		tips:insertIf( defenseChange ~= 0 and defenseChange / 100 .. "[ICON_STRENGTH]" )
		tips:insertLocalizedIfNonZero( "TXT_KEY_PEDIA_DEFENSE_HITPOINTS", hitPointChange )

		controls.Label:ChangeParent( controls.Stack )
		controls.Label:SetText( tips:concat( " " ) )
		slotStack:CalculateSize()
		if slotStack:GetSizeX() + controls.Label:GetSizeX() < 254 then
			controls.Label:ChangeParent( slotStack )
		end
		controls.Stack:CalculateSize()
		buildingButton:SetSizeY( math_max( 64, controls.Stack:GetSizeY() + 16 ) )
	end
	return buildingIM.Commit()
end

-------------------------------------------
-- Production Selection List Management
-------------------------------------------
local g_lastPurchaseClock = 0

local function SelectionPurchase( orderID, itemID, yieldID, soundKey )
	local city = GetSelectedCity()
	if not city then
		return
	end
	local now = os.clock()
	if now - g_lastPurchaseClock < 0.3 then	-- ignore double clicks
		return
	end
	local cityOwnerID = city:GetOwner()
	if cityOwnerID == g_activePlayerID
		and ( not city:IsPuppet() or ( bnw_mode and g_activePlayer:MayNotAnnex() ) )	-- Venice exception
	then
		local cityID = city:GetID()
		local isPurchase
		if orderID == OrderTypes.ORDER_TRAIN then
			if cityIsCanPurchase( city, true, true, itemID, -1, -1, yieldID ) then
				Game.CityPurchaseUnit( city, itemID, yieldID )
				isPurchase = true
			end
		elseif orderID == OrderTypes.ORDER_CONSTRUCT then
			if cityIsCanPurchase( city, true, true, -1, itemID, -1, yieldID ) then
				Game.CityPurchaseBuilding( city, itemID, yieldID )
				Network.SendUpdateCityCitizens( cityID )
				isPurchase = true
			end
		elseif orderID == OrderTypes.ORDER_CREATE then
			if cityIsCanPurchase( city, true, true, -1, -1, itemID, yieldID ) then
				Game.CityPurchaseProject( city, itemID, yieldID )
				isPurchase = true
			end
		end
		if isPurchase then
			g_lastPurchaseClock = now
			Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_BANNER )
			Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION )
			if soundKey then
				Events.AudioPlay2DSound( soundKey )
			end
		end
	end
end

local function AddSelectionItem( city, item, selectionList, orderID, cityCanProduce,
			unitID, buildingID, projectID,
			cityGetProductionTurnsLeft, cityGetGoldCost, cityGetFaithCost )

	local itemID = item.ID
	local name = item.Description

	local turnsLeft, canProduce = false, false
	if not g_isViewingMode then
		turnsLeft = cityCanProduce( city, itemID, 0, 1 )	-- 0 = /continue, 1 = testvisible
		if turnsLeft or g_isDebugMode then
			canProduce = cityCanProduce( city, itemID )
		end
	end

	local canBuyWithGold, goldCost, canBuyWithFaith, faithCost
	if unitID then
		if civBE_mode then
			local bestUpgradeInfo = GameInfo.UnitUpgrades[ g_activePlayer:GetBestUnitUpgrade( unitID ) ]
			name = bestUpgradeInfo and bestUpgradeInfo.Description or name
		end
		if cityGetGoldCost and cityIsCanPurchase( city, false, false, unitID, buildingID, projectID, g_yieldCurrency ) then
			goldCost = cityGetGoldCost( city, itemID )
			canBuyWithGold = cityIsCanPurchase( city, true, true, unitID, buildingID, projectID, g_yieldCurrency )
		end
		if cityGetFaithCost and cityIsCanPurchase( city, false, false, unitID, buildingID, projectID, YieldTypes.YIELD_FAITH ) then
			faithCost = cityGetFaithCost( city, itemID, true )
			canBuyWithFaith = cityIsCanPurchase( city, true, true, unitID, buildingID, projectID, YieldTypes.YIELD_FAITH )
		end
	end

	if turnsLeft or goldCost or faithCost or ( g_isDebugMode and not ( buildingID and city:IsHasBuilding( buildingID ) ) ) then
		turnsLeft = turnsLeft and ( cityGetProductionTurnsLeft and cityGetProductionTurnsLeft( city, itemID ) or -1 )
		return selectionList:insert{ item, orderID, LocalName( name ), turnsLeft, canProduce, goldCost, canBuyWithGold, faithCost, canBuyWithFaith }
	end
end

local function SortSelectionList( a, b )
	return a[3] < b[3]
end

local g_maxQueueLength = 7
local g_SelectionListCallBacks = {
	Button = {
		[Mouse.eLClick] = function( orderID, itemID )
			local city = GetSelectedModifiableCity()
			if city and not city:IsPuppet() then
				-- queue limit (shift-click replaces the queue, so allow it)
				if city:GetOrderQueueLength() >= g_maxQueueLength and not UI.ShiftKeyDown() then
					return Events.AudioPlay2DSound( "AS2D_INTERFACE_BUTTON_CLICK_DISABLED" )
				end
				-- Game.CityPushOrder( city, orderID, itemID, repeatBuild, replaceQueue, bottomOfQueue )
				Game.CityPushOrder( city, orderID, itemID, UI.AltKeyDown(), UI.ShiftKeyDown(), not UI.CtrlKeyDown() )
				local cityOwnerID, cityID = city:GetOwner(), city:GetID()
				Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_BANNER )
				Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION )
			end
		end,
		-- right click buys units, Ctrl + right click opens the Pedia
		[Mouse.eRClick] = function( orderID, itemID )
			if orderID == OrderTypes.ORDER_TRAIN and GetSelectedModifiableCity() and not UI.CtrlKeyDown() then
				return SelectionPurchase( orderID, itemID, g_yieldCurrency, "AS2D_INTERFACE_CITY_SCREEN_PURCHASE" )
			end
			return SelectionPedia( orderID, itemID )
		end,
	},
	GoldButton = {
		[Mouse.eLClick] = function( orderID, itemID )
			return SelectionPurchase( orderID, itemID, g_yieldCurrency, "AS2D_INTERFACE_CITY_SCREEN_PURCHASE" )
		end,
	},
	FaithButton = {
		[Mouse.eLClick] = function( orderID, itemID )
			return SelectionPurchase( orderID, itemID, YieldTypes.YIELD_FAITH, "AS2D_INTERFACE_FAITH_PURCHASE" )
		end,
	},
}
local g_SelectionListTooltips = {
	Button = SelectionToolTip,
	GoldButton = function( control )
		return OrderItemTooltip( UI_GetHeadSelectedCity(), control:IsDisabled(), g_yieldCurrency, control:GetVoid1(), control:GetVoid2() )
	end,
	FaithButton = function( control )
		return OrderItemTooltip( UI_GetHeadSelectedCity(), control:IsDisabled(), YieldTypes.YIELD_FAITH, control:GetVoid1(), control:GetVoid2() )
	end,
}

-- first character of a string, safe for multi-byte UTF-8
local function FirstLetter( text )
	text = tostring( text or "" )
	text = text:gsub( "^%s*%[COLOR_[%w_]+%]", "" )
	local icon = text:match( "^%s*(%[ICON_[%w_]+%])" )
	if icon then
		return icon
	end
	return Locale.ToUpper( text:match( "[%z\1-\127\194-\244][\128-\191]*" ) or text )
end

local g_initialCache = {}
local function CachedInitial( text )
	local s = g_initialCache[ text ]
	if not s then
		s = FirstLetter( text )
		g_initialCache[ text ] = s
	end
	return s
end

local function SetupSelectionList( itemList, selectionIM, cityOwnerID, getUnitPortraitIcon, nameMode )
	itemList:sort( SortSelectionList )
	selectionIM.ResetInstances()
	local cash = g_activePlayer:GetGold()
	local faith = gk_mode and g_activePlayer:GetFaith() or 0
	for i = 1, #itemList do
		local item, orderID, itemDescription, turnsLeft, canProduce, goldCost, canBuyWithGold, faithCost, canBuyWithFaith = unpack( itemList[i] )
		local itemID = item.ID
		if g_isDebugMode then
			goldCost, canBuyWithGold, faithCost, canBuyWithFaith = nil
		end
		local instance, isNewInstance = selectionIM.GetInstance()
		if isNewInstance then
			SetupCallbacks( instance, g_SelectionListTooltips, "EUI_CityViewLeftTooltip", g_SelectionListCallBacks )
		end
		instance.DisabledProduction:SetHide( canProduce or not ( canBuyWithGold or canBuyWithFaith ) )
		instance.Disabled:SetHide( canProduce or canBuyWithGold or canBuyWithFaith )
		if getUnitPortraitIcon then
			local iconIndex, iconAtlas = getUnitPortraitIcon( itemID, cityOwnerID )
			IconHookup( iconIndex, 45, iconAtlas, instance.Portrait )
		else
			IconHookup( item.PortraitIndex, 45, item.IconAtlas, instance.Portrait )
		end

		if nameMode == "none" then
			instance.Name:SetText( "" )
			instance.Name:SetHide( true )
		else
			instance.Name:SetHide( false )	-- instances are reused, so always reset this
			instance.Name:SetText( nameMode == "initial" and CachedInitial( itemDescription ) or itemDescription )
		end

		if turnsLeft then
			if turnsLeft > -1 and turnsLeft <= 999 then
				instance.Turns:LocalizeAndSetText( turnsLeft )
			else
				instance.Turns:LocalizeAndSetText( "TXT_KEY_PRODUCTION_HELP_INFINITE_TURNS" )
			end
		end
		instance.Turns:SetHide( not turnsLeft )
		instance.Button:SetVoids( orderID, itemID )

		instance.GoldButton:SetHide( not goldCost )
		if goldCost then
			instance.GoldButton:SetDisabled( not canBuyWithGold )
			instance.GoldButton:SetAlpha( canBuyWithGold and 1 or 0.5 )
			instance.GoldButton:SetVoids( orderID, itemID )
			instance.GoldButton:SetText( ( cash >= goldCost and goldCost or "[COLOR_WARNING_TEXT]" .. ( goldCost - cash ) .. "[ENDCOLOR]" ) .. g_currencyIcon )
		end
		instance.FaithButton:SetHide( not faithCost )
		if faithCost then
			instance.FaithButton:SetDisabled( not canBuyWithFaith )
			instance.FaithButton:SetAlpha( canBuyWithFaith and 1 or 0.5 )
			instance.FaithButton:SetVoids( orderID, itemID )
			instance.FaithButton:SetText( ( faith >= faithCost and faithCost or "[COLOR_WARNING_TEXT]" .. ( faithCost - faith ) .. "[ENDCOLOR]" ) .. "[ICON_PEACE]" )
		end
	end
	return selectionIM.Commit()
end

-------------------------------
-- Production Queue Management
-------------------------------
local function RemoveQueueItem( queuedItemNumber )
	local city = GetSelectedModifiableCity()
	if city then
		local queueLength = city:GetOrderQueueLength()
		if queueLength > queuedItemNumber then
			Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_POP_ORDER, queuedItemNumber )
			-- AddNotification changes game state locally, so never do it in multiplayer
			if queueLength < 2 and not Game.IsNetworkMultiPlayer() then
				local strTooltip = L( "TXT_KEY_NOTIFICATION_NEW_CONSTRUCTION", city:GetNameKey() )
				g_activePlayer:AddNotification( NotificationTypes.NOTIFICATION_PRODUCTION, strTooltip, strTooltip, city:GetX(), city:GetY(), -1, -1 )
			end
		end
	end
end

local function SwapQueueItem( queuedItemNumber )
	if g_queuedItemNumber and Controls.QueueSlider:IsTrackingLeftMouseButton() then
		local a, b = g_queuedItemNumber, queuedItemNumber
		if a > b then a, b = b, a end
		for i = a, b - 1 do
			Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_SWAP_ORDER, i )
		end
		for i = b - 2, a, -1 do
			Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_SWAP_ORDER, i )
		end
	end
	g_queuedItemNumber = queuedItemNumber or g_queuedItemNumber
end

-- check project unit prereq
local function IsProjectPrereqMet( item )
	local prereq = item.ProjectPrereq
	if not prereq then
		return true
	end
	local projectID = GameInfoTypes[ prereq ]
	if not projectID then
		return false
	end
	return Teams[ g_activePlayer:GetTeam() ]:GetProjectCount( projectID ) > 0
end

-- unique units that must only show for their civilization
local g_civOnlyUnits = {
	UNIT_SIAMESE_MONK = "CIVILIZATION_SIAM",
	UNIT_HUN_SHAMAN = "CIVILIZATION_HUNS",
}

local function IsUnitAllowedForCiv( item )
	local civ = g_civOnlyUnits[ item.Type ]
	return not civ or GameInfo.Civilizations[ g_activePlayer:GetCivilizationType() ].Type == civ
end

local function UpdateCityProductionQueueNow( city, cityID, cityOwnerID, isVeniceException )
	local civilianSelectList = table()
	local queueLength = city:GetOrderQueueLength()
	local currentProductionPerTurnTimes100 = city:GetCurrentProductionDifferenceTimes100( false, false )
	local isGeneratingProduction = not bnw_mode or ( currentProductionPerTurnTimes100 > 0 )
	local isMaintain = false
	local isQueueEmpty = queueLength < 1
	Controls.ProductionFinished:SetHide( true )

	-- production stored and needed
	local storedProduction = city:GetProduction() + city:GetOverflowProduction() + city:GetFeatureProduction()
	local productionNeeded = 1E-99
	if isGeneratingProduction and not isQueueEmpty and not city:IsProductionProcess() then
		productionNeeded = city:GetProductionNeeded()
	end
	local storedProductionPlusThisTurn = storedProduction + currentProductionPerTurnTimes100 / 100

	Controls.PQmeter:SetPercents( storedProduction / productionNeeded, storedProductionPlusThisTurn / productionNeeded )
	Controls.ProdPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", currentProductionPerTurnTimes100 / 100 )
	Controls.ProductionPortraitButton:SetHide( false )

	g_ProdQueueIM.ResetInstances()
	local queueItems = {}

	for queuedItemNumber = 0, math_max( queueLength - 1, 0 ) do
		local orderID, itemID, _, isRepeat, isReallyRepeat
		if isQueueEmpty then
			local item = g_finishedItems[ cityID ]
			if item then
				orderID, itemID = unpack( item )
				Controls.ProductionFinished:SetHide( false )
			end
		else
			orderID, itemID, _, isRepeat = city:GetOrderFromQueue( queuedItemNumber )
			queueItems[ QueueKey( orderID, itemID ) ] = true
		end

		local instance, portraitSize
		if queuedItemNumber == 0 then
			instance = Controls	-- callbacks for the first entry are registered once at load
			portraitSize = g_portraitSize
		else
			portraitSize = 45
			instance = g_ProdQueueIM.GetInstance()
			if not instance.callbacksReady then
				instance.callbacksReady = true
				instance.PQbox:RegisterCallback( Mouse.eMouseEnter, SwapQueueItem )
				instance.PQbox:RegisterCallback( Mouse.eRClick, RemoveQueueItem )
				instance.PQbox:RegisterCallback( Mouse.eLClick, RemoveQueueItem )
				instance.PQbox:SetToolTipCallback( ProductionToolTip )
				instance.PQremove:RegisterCallback( Mouse.eLClick, RemoveQueueItem )
			end
			instance.PQdisabled:SetHide( not isMaintain )
		end
		instance.PQbox:SetVoid1( queuedItemNumber )
		instance.PQremove:SetHide( true )
		instance.PQremove:SetVoid1( queuedItemNumber )

		local itemInfo, turnsRemaining, portraitOffset, portraitAtlas

		if orderID == OrderTypes.ORDER_TRAIN then
			itemInfo = GameInfo.Units
			turnsRemaining = city:GetUnitProductionTurnsLeft( itemID, queuedItemNumber )
			portraitOffset, portraitAtlas = UI_GetUnitPortraitIcon( itemID, cityOwnerID )
			isReallyRepeat = isRepeat
		elseif orderID == OrderTypes.ORDER_CONSTRUCT then
			itemInfo = GameInfo.Buildings
			turnsRemaining = city:GetBuildingProductionTurnsLeft( itemID, queuedItemNumber )
		elseif orderID == OrderTypes.ORDER_CREATE then
			itemInfo = GameInfo.Projects
			turnsRemaining = city:GetProjectProductionTurnsLeft( itemID, queuedItemNumber )
		elseif orderID == OrderTypes.ORDER_MAINTAIN then
			itemInfo = GameInfo.Processes
			isMaintain = true
			isReallyRepeat = true
		end
		if itemInfo then
			local item = itemInfo[ itemID ]
			IconHookup( portraitOffset or item.PortraitIndex, portraitSize, portraitAtlas or item.IconAtlas, instance.PQportrait )
			instance.PQname:LocalizeAndSetText( item.Description )
			if not ( isMaintain or isQueueEmpty ) then
				if isGeneratingProduction then
					instance.PQturns:LocalizeAndSetText( turnsRemaining )
				else
					instance.PQturns:LocalizeAndSetText( "TXT_KEY_PRODUCTION_HELP_INFINITE_TURNS" )
				end
			end
		else
			instance.PQname:LocalizeAndSetText( "TXT_KEY_PRODUCTION_NO_PRODUCTION" )
		end
		instance.PQturns:SetHide( isMaintain or isQueueEmpty or not itemInfo )
		instance.PQportrait:SetHide( not itemInfo )
		if isReallyRepeat then
			isMaintain = true
			instance.PQrank:SetText( "[ICON_TURNS_REMAINING]" )
		else
			instance.PQrank:SetText( not isMaintain and queueLength > 1 and ( queuedItemNumber + 1 ) .. "." )
		end
	end

	g_ProdQueueIM.Commit()

	-------------------------------------------
	-- Update Selection List
	-------------------------------------------
	local isSelectionList = not g_isViewingMode or isVeniceException or g_isDebugMode
	Controls.SelectionScrollPanel:SetHide( not isSelectionList )
	if isSelectionList then
		local unitSelectList = table()
		local buildingSelectList = table()
		local wonderSelectList = table()
		local processSelectList = table()

		-- buildings & wonders
		local orderID = OrderTypes.ORDER_CONSTRUCT
		for i = 1, #g_buildingList do
			local item = g_buildingList[i]
			local id = item.ID
			-- an existing building is never offered (outside debug mode), skip the expensive checks
			if not queueItems[ QueueKey( orderID, id ) ] and ( g_isDebugMode or not city:IsHasBuilding( id ) ) then
				AddSelectionItem( city, item,
					g_isWonderBuilding[ id ] and wonderSelectList or buildingSelectList,
					orderID, city.CanConstruct,
					-1, id, -1,
					city.GetBuildingProductionTurnsLeft,
					city.GetBuildingPurchaseCost,
					city.GetBuildingFaithPurchaseCost )
			elseif g_isDebugMode and not queueItems[ QueueKey( orderID, id ) ] then
				-- (unreachable, kept simple) debug mode is handled by the first branch
			end
		end

		if not g_isDebugMode then
			-- units
			orderID = OrderTypes.ORDER_TRAIN
			for i = 1, #g_unitList do
				local item = g_unitList[i]
				if IsProjectPrereqMet( item ) and IsUnitAllowedForCiv( item ) then
					AddSelectionItem( city, item,
						g_isCivilianUnit[ item.ID ] and civilianSelectList or unitSelectList,
						orderID, city.CanTrain,
						item.ID, -1, -1,
						city.GetUnitProductionTurnsLeft,
						city.GetUnitPurchaseCost,
						city.GetUnitFaithPurchaseCost )
				end
			end
			-- projects
			orderID = OrderTypes.ORDER_CREATE
			for i = 1, #g_projectList do
				local item = g_projectList[i]
				if not queueItems[ QueueKey( orderID, item.ID ) ] then
					AddSelectionItem( city, item, processSelectList, orderID, city.CanCreate,
						-1, -1, item.ID,
						city.GetProjectProductionTurnsLeft,
						city.GetProjectPurchaseCost,
						city.GetProjectFaithPurchaseCost )
				end
			end
			-- processes
			orderID = OrderTypes.ORDER_MAINTAIN
			for i = 1, #g_processList do
				local item = g_processList[i]
				if not queueItems[ QueueKey( orderID, item.ID ) ] then
					AddSelectionItem( city, item, processSelectList, orderID, city.CanMaintain )
				end
			end
		end

		SetupSelectionList( unitSelectList, g_UnitSelectIM, cityOwnerID, UI_GetUnitPortraitIcon, "initial" )
		SetupSelectionList( civilianSelectList, g_CivilianSelectIM, cityOwnerID, UI_GetUnitPortraitIcon, "initial" )
		SetupSelectionList( buildingSelectList, g_BuildingSelectIM, nil, nil, "initial" )
		SetupSelectionList( wonderSelectList, g_WonderSelectIM, nil, nil, "none" )
		SetupSelectionList( processSelectList, g_ProcessSelectIM, nil, nil, "none" )
	end
	return ResizeProdQueue()
end

-------------------------------------------------
-- Plot buttons (citizen management and tile buying)
-------------------------------------------------
local function PlotButtonClicked( plotIndex )
	local city = GetSelectedModifiableCity()
	local plot = city and city:GetCityIndexPlot( plotIndex )
	if plot then
		local outside = city ~= plot:GetWorkingCity()
		-- plotIndex 0 (the city center) resets all forced tiles
		Network.SendDoTask( city:GetID(), TaskTypes.TASK_CHANGE_WORKING_PLOT, plotIndex, -1, false )
		if outside then
			return Network.SendUpdateCityCitizens( city:GetID() )
		end
	end
end

local function BuyPlotAnchorButtonClicked( plotIndex )
	local city = GetSelectedModifiableCity()
	if city then
		local plot = city:GetCityIndexPlot( plotIndex )
		if plot then
			Network.SendCityBuyPlot( city:GetID(), plot:GetX(), plot:GetY() )
			Network.SendUpdateCityCitizens( city:GetID() )
			UI.UpdateCityScreen()
			Events.AudioPlay2DSound( "AS2D_INTERFACE_BUY_TILE" )
		end
	end
	return true
end

local function UpdatePlotButtonsNow()
	g_isPlotButtonsDirty = false
	local city = UI_GetHeadSelectedCity()
	if not ( city and UI.IsCityScreenUp() ) then
		return
	end

	g_PlotButtonIM.ResetInstances()
	g_BuyPlotButtonIM.ResetInstances()

	local cityArea = city:GetNumCityPlots() - 1
	Events_RequestYieldDisplay( YieldDisplayTypes_AREA, RadiusHexArea( cityArea ), city:GetX(), city:GetY() )

	local cityOwnerID = city:GetOwner()

	-- worked / workable tile buttons
	if g_workerHeadingOpen and not g_isViewingMode then
		for plotIndex = 0, cityArea do
			local plot = city:GetCityIndexPlot( plotIndex )
			if plot and plot:GetOwner() == cityOwnerID then
				local iconID, tipKey, clickable
				if city:IsWorkingPlot( plot ) then
					clickable = true
					if plotIndex == 0 then
						iconID, tipKey = 11, "TXT_KEY_CITYVIEW_CITY_CENTER"
					elseif city:IsForcedWorkingPlot( plot ) then
						iconID, tipKey = 10, "TXT_KEY_CITYVIEW_FORCED_WORK_TILE"
					else
						iconID, tipKey = 0, "TXT_KEY_CITYVIEW_GUVNA_WORK_TILE"
					end
				else
					local workingCity = plot:GetWorkingCity()
					if workingCity and workingCity:IsWorkingPlot( plot ) then
						iconID, tipKey, clickable = 12, "TXT_KEY_CITYVIEW_NUTHA_CITY_TILE", true
					elseif workingCity and workingCity:CanWork( plot ) then
						iconID, tipKey, clickable = 9, "TXT_KEY_CITYVIEW_UNWORKED_CITY_TILE", true
					elseif not ( plot:IsWater() and city:IsPlotBlockaded( plot ) ) and plot:IsVisibleEnemyUnit( cityOwnerID ) then
						iconID, tipKey = 13, "TXT_KEY_CITYVIEW_ENEMY_UNIT_CITY_TILE"
					end
				end
				if iconID then
					local worldPos = HexToWorld( ToHexFromGrid{ x = plot:GetX(), y = plot:GetY() } )
					local instance = g_PlotButtonIM.GetInstance()
					instance.PlotButtonAnchor:SetWorldPositionVal( worldPos.x + g_worldPositionOffset.x, worldPos.y + g_worldPositionOffset.y, worldPos.z + g_worldPositionOffset.z )
					instance.PlotButtonImage:LocalizeAndSetToolTip( tipKey )
					IconHookup( iconID, 45, "CITIZEN_ATLAS", instance.PlotButtonImage )
					local button = instance.PlotButtonImage
					if clickable then
						button:SetVoid1( plotIndex )
						button:RegisterCallback( Mouse.eLClick, PlotButtonClicked )
					else
						button:ClearCallback( Mouse.eLClick )
					end
				end
			end
		end
	end

	-- buy plot buttons
	if g_BuyPlotMode and not g_isViewingMode then
		local cash = g_activePlayer:GetGold()
		for plotIndex = 0, cityArea do
			local plot = city:GetCityIndexPlot( plotIndex )
			if plot then
				local x, y = plot:GetX(), plot:GetY()
				if city:CanBuyPlotAt( x, y, true ) then
					local worldPos = HexToWorld( ToHexFromGrid{ x = x, y = y } )
					local instance = g_BuyPlotButtonIM.GetInstance()
					local button = instance.BuyPlotAnchoredButton
					instance.BuyPlotButtonAnchor:SetWorldPositionVal( worldPos.x + g_worldPositionOffset2.x, worldPos.y + g_worldPositionOffset2.y, worldPos.z + g_worldPositionOffset2.z )
					local plotCost = city:GetBuyPlotCost( x, y )
					local canBuy = city:CanBuyPlotAt( x, y, false )
					local tip, txt, alpha
					if canBuy then
						tip = L( "TXT_KEY_CITYVIEW_CLAIM_NEW_LAND", plotCost )
						txt = plotCost
						alpha = 1
						button:SetVoid1( plotIndex )
						button:RegisterCallback( Mouse.eLClick, BuyPlotAnchorButtonClicked )
					else
						tip = L( "TXT_KEY_CITYVIEW_NEED_MONEY_BUY_TILE", plotCost )
						txt = "[COLOR_WARNING_TEXT]" .. ( plotCost - cash ) .. "[ENDCOLOR]"
						alpha = 0.5
					end
					button:SetDisabled( not canBuy )
					instance.BuyPlotButtonAnchor:SetAlpha( alpha )
					button:SetToolTipString( tip )
					instance.BuyPlotAnchoredButtonLabel:SetText( txt )
				end
			end
		end
	end

	g_PlotButtonIM.Commit()
	g_BuyPlotButtonIM.Commit()
end

-------------------------------------------------
-- City View Update (split into small parts)
-------------------------------------------------
local function FormatNumber( n )
	local absN = math_abs( n )
	if absN >= 1e9 then
		return string.format( "%.1fB", n / 1e9 )
	elseif absN >= 1e6 then
		return string.format( "%.1fM", n / 1e6 )
	elseif absN >= 1e3 then
		return string.format( "%.1fK", n / 1e3 )
	end
	return string.format( "%d", math_floor( n + 0.5 ) )
end

-- focus type -> radio button
local g_focusButtons = {
	[CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE] = Controls.BalancedFocusButton,
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD] = Controls.FoodFocusButton,
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION] = Controls.ProductionFocusButton,
	[g_focusCurrency] = Controls.GoldFocusButton,
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE] = Controls.ResearchFocusButton,
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE] = Controls.CultureFocusButton,
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE] = Controls.GPFocusButton,
}
if gk_mode then
	g_focusButtons[ CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH ] = Controls.FaithFocusButton
end
for focus, button in pairs( g_focusButtons ) do
	button:SetVoid1( focus )
end

local function UpdateBanner( city, cityOwnerID, cityOwner, isCapital )
	Controls.CityCapitalIcon:SetHide( not isCapital )
	local isBlockaded = city:IsBlockaded()
	Controls.CityIsConnected:SetHide( isCapital or isBlockaded or not cityOwner:IsCapitalConnectedToCity( city ) or city:GetTeam() ~= Game.GetActiveTeam() )
	Controls.CityIsBlockaded:SetHide( not isBlockaded )

	local isRazing = city:IsRazing()
	Controls.CityIsRazing:SetHide( not isRazing )
	if isRazing then
		Controls.CityIsRazing:LocalizeAndSetToolTip( "TXT_KEY_CITY_BURNING", city:GetRazingTurns() )
	end

	Controls.CityIsPuppet:SetHide( not city:IsPuppet() )

	local isResistance = city:IsResistance()
	Controls.CityIsResistance:SetHide( not isResistance )
	if isResistance then
		Controls.CityIsResistance:LocalizeAndSetToolTip( "TXT_KEY_CITY_RESISTANCE", city:GetResistanceTurns() )
	end

	Controls.CityIsOccupied:SetHide( not ( civ5_mode and city:IsOccupied() and not city:IsNoOccupiedUnhappiness() ) )

	local cityName = Locale.ToUpper( city:GetName() )
	if isRazing then
		cityName = cityName .. " (" .. L"TXT_KEY_BURNING" .. ")"
	end
	local size = isCapital and Controls.CityCapitalIcon:GetSizeX() or 0
	Controls.CityNameTitleBarLabel:SetOffsetX( size / 2 )
	TruncateString( Controls.CityNameTitleBarLabel, math_abs( Controls.NextCityButton:GetOffsetX() ) * 2 - Controls.NextCityButton:GetSizeX() - size, cityName )

	Controls.Defense:SetText( math_floor( city:GetStrengthValue() / 100 ) )
	CivIconHookup( cityOwnerID, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true )

	-- city damage
	local cityDamage = city:GetDamage()
	if cityDamage > 0 then
		local percent = 1 - cityDamage / ( gk_mode and city:GetMaxHitPoints() or GameDefines.MAX_CITY_HIT_POINTS )
		Controls.HealthMeter:SetPercent( percent )
		if percent > 0.66 then
			Controls.HealthMeter:SetTexture( "CityNamePanelHealthBarGreen.dds" )
		elseif percent > 0.33 then
			Controls.HealthMeter:SetTexture( "CityNamePanelHealthBarYellow.dds" )
		else
			Controls.HealthMeter:SetTexture( "CityNamePanelHealthBarRed.dds" )
		end
	end
	Controls.HealthFrame:SetHide( cityDamage <= 0 )

	-- growth meter and population
	local population = math_floor( city:GetPopulation() )
	Controls.CityPopulationLabel:SetText( tostring( population ) )
	Controls.PeopleMeter:SetPercent( city:GetFood() / city:GrowthThreshold() )
	Controls.CityPopulationLabelSuffix:LocalizeAndSetText( "TXT_KEY_CITYVIEW_CITIZENS_TEXT", population )
	Controls.CityPop:SetText( FormatNumber( math_floor( 1000 * population ^ 2.8 + 0.5 ) ) )
	Controls.CityPopSuffix:LocalizeAndSetText( "TXT_KEY_POPS_MIL", population )
end

local function UpdateFocusAndSlackers( city )
	Controls.AvoidGrowthButton:SetCheck( city:IsForcedAvoidGrowth() )

	local focusButton = g_focusButtons[ city:GetFocusType() ] or Controls.BalancedFocusButton
	focusButton:SetCheck( true )

	local slackerCount = city:GetSpecialistCount( GameDefines.DEFAULT_SPECIALIST )
	-- rest unchanged
	local showReset = city:GetNumForcedWorkingPlots() > 0 or slackerCount > 0
	Controls.ResetButton:SetHide( not showReset )
	Controls.ResetFooter:SetHide( not showReset )

	g_SlackerIM.ResetInstances()
	for i = 1, slackerCount do
		local slot = g_SlackerIM.GetInstance().Button
		slot:SetVoids( -1, i )
		slot:SetToolTipCallback( SpecialistTooltip )
		slot:SetTexture( g_slackerTexture )
		if g_isViewingMode then
			slot:ClearCallback( Mouse.eLClick )
		else
			slot:RegisterCallback( Mouse.eLClick, OnSlackersSelected )
		end
		slot:RegisterCallback( Mouse.eRClick, SpecialistPedia )
	end
	g_SlackerIM.Commit()
end

local function UpdateBuildings( city )
	local greatWorkBuildings = table()
	local specialistBuildings = table()
	local wonders = table()
	local otherBuildings = table()
	local noWondersWithSpecialistInThisCity = true

	for i = 1, #g_buildingList do
		local building = g_buildingList[i]
		local buildingID = building.ID
		if city:IsHasBuilding( buildingID ) then
			local buildingClass = g_buildingClass[ buildingID ]
			local buildings
			local greatWorkCount = civ5bnw_mode and building.GreatWorkCount or 0
			local areSpecialistsAllowed = city:GetNumSpecialistsAllowedByBuilding( buildingID ) > 0

			if buildingClass.MaxGlobalInstances > 0
				or buildingClass.MaxTeamInstances > 0
				or ( buildingClass.MaxPlayerInstances == 1 and not areSpecialistsAllowed )
			then
				buildings = wonders
				if areSpecialistsAllowed then
					noWondersWithSpecialistInThisCity = false
				end
			elseif areSpecialistsAllowed then
				buildings = specialistBuildings
			elseif greatWorkCount > 0 then
				buildings = greatWorkBuildings
			elseif greatWorkCount == 0 then	-- compatibility with Firaxis code exploit for invisibility
				buildings = otherBuildings
			end
			if buildings then
				buildings:insert{ building, L( building.Description ), greatWorkCount, areSpecialistsAllowed and GameInfoTypes[ building.SpecialistType ] or 999 }
			end
		end
	end

	local strMaintenanceTT = L( "TXT_KEY_BUILDING_MAINTENANCE_TT", city:GetTotalBaseBuildingMaintenance() )
	Controls.SpecialBuildingsHeader:SetToolTipString( strMaintenanceTT )
	Controls.BuildingsHeader:SetToolTipString( strMaintenanceTT )
	Controls.GreatWorkHeader:SetToolTipString( strMaintenanceTT )
	Controls.SpecialistControlBox:SetHide( #specialistBuildings < 1 )
	Controls.SpecialistControlBox2:SetHide( noWondersWithSpecialistInThisCity )

	SetupBuildingList( city, specialistBuildings, g_SpecialBuildingsIM )
	SetupBuildingList( city, wonders, g_WondersIM )
	SetupBuildingList( city, greatWorkBuildings, g_GreatWorkIM )
	SetupBuildingList( city, otherBuildings, g_BuildingsIM )
	ResizeRightStack()
end

local function UpdateResourceDemanded( city )
	if city:GetResourceDemanded( true ) ~= -1 then
		local resourceInfo = GameInfo.Resources[ city:GetResourceDemanded() ]
		local weLoveTheKingDayCounter = city:GetWeLoveTheKingDayCounter()
		if weLoveTheKingDayCounter > 0 then
			Controls.ResourceDemandedString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_WLTKD_COUNTER", weLoveTheKingDayCounter )
			Controls.ResourceDemandedBox:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_RESOURCE_FULFILLED_TT" )
		else
			Controls.ResourceDemandedString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED", resourceInfo.IconString .. " " .. L( resourceInfo.Description ) )
			Controls.ResourceDemandedBox:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED_TT" )
		end
		Controls.ResourceDemandedBox:SetSizeX( Controls.ResourceDemandedString:GetSizeX() + 10 )
		Controls.ResourceDemandedBox:SetHide( false )
	else
		Controls.ResourceDemandedBox:SetHide( true )
	end
	Controls.IconsStack:CalculateSize()
	Controls.IconsStack:ReprocessAnchoring()
	Controls.NotificationStack:CalculateSize()
	Controls.NotificationStack:ReprocessAnchoring()
end

local function UpdateTaskButton( city, cityID, cityOwner, isActivePlayerCity )
	local buttonToolTip, buttonLabel, taskID
	if isActivePlayerCity then
		if city:IsRazing() then
			taskID = TaskTypes.TASK_UNRAZE
			buttonLabel = L"TXT_KEY_CITYVIEW_UNRAZE_BUTTON_TEXT"
			buttonToolTip = L"TXT_KEY_CITYVIEW_UNRAZE_BUTTON_TT"
		elseif city:IsPuppet() and not ( bnw_mode and cityOwner:MayNotAnnex() ) then
			taskID = TaskTypes.TASK_ANNEX_PUPPET
			buttonLabel = L"TXT_KEY_POPUP_ANNEX_CITY"
			if civ5_mode then
				buttonToolTip = L( "TXT_KEY_POPUP_CITY_CAPTURE_INFO_ANNEX", cityOwner:GetUnhappinessForecast( city ) - cityOwner:GetUnhappiness() )
			end
		elseif not g_isViewingMode and cityOwner:CanRaze( city, true ) then
			buttonLabel = L"TXT_KEY_CITYVIEW_RAZE_BUTTON_TEXT"
			if cityOwner:CanRaze( city, false ) then
				taskID = TaskTypes.TASK_RAZE
				buttonToolTip = L"TXT_KEY_CITYVIEW_RAZE_BUTTON_TT"
			else
				-- we could raze this city if it weren't a capital
				buttonToolTip = L"TXT_KEY_CITYVIEW_RAZE_BUTTON_DISABLED_BECAUSE_CAPITAL_TT"
			end
		end
	end
	local button = Controls.CityTaskButton
	button:SetText( buttonLabel )
	button:SetVoids( cityID, taskID )
	button:SetToolTipString( buttonToolTip )
	button:SetDisabled( not taskID )
	button:SetHide( not buttonLabel )
end

local function UpdateYields( city )
	Controls.GoldPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", city:GetYieldRateTimes100( g_yieldCurrency ) / 100 )

	if Game.IsOption( GameOptionTypes.GAMEOPTION_NO_SCIENCE ) then
		Controls.SciencePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_OFF" )
	else
		Controls.SciencePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", city:GetYieldRateTimes100( YieldTypes.YIELD_SCIENCE ) / 100 )
	end

	local culturePerTurn, cultureStored, cultureNext
	if civ5_mode then
		culturePerTurn = city:GetJONSCulturePerTurn()
		cultureStored = city:GetJONSCultureStored()
		cultureNext = city:GetJONSCultureThreshold()
	else
		culturePerTurn = city:GetCulturePerTurn()
		cultureStored = city:GetCultureStored()
		cultureNext = city:GetCultureThreshold()
	end
	Controls.CulturePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", culturePerTurn )
	if culturePerTurn > 0 then
		Controls.CultureTimeTillGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_TURNS_TILL_TILE_TEXT", math_max( math_ceil( ( cultureNext - cultureStored ) / culturePerTurn ), 1 ) )
	end
	Controls.CultureTimeTillGrowthLabel:SetHide( culturePerTurn <= 0 )
	Controls.CultureMeter:SetPercent( cultureStored / cultureNext )

	if gk_mode then
		if Game.IsOption( GameOptionTypes.GAMEOPTION_NO_RELIGION ) then
			Controls.FaithPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_OFF" )
		else
			Controls.FaithPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", city:GetFaithPerTurn() )
		end
	end

	local foodPerTurnTimes100 = city:FoodDifferenceTimes100()
	if city:IsFoodProduction() or foodPerTurnTimes100 == 0 then
		Controls.CityGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_STAGNATION_TEXT" )
	elseif foodPerTurnTimes100 < 0 then
		Controls.CityGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_STARVATION_TEXT" )
	else
		Controls.CityGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_TURNS_TILL_CITIZEN_TEXT", city:GetFoodTurnsLeft() )
	end
	Controls.FoodPerTurnLabel:LocalizeAndSetText( foodPerTurnTimes100 >= 0 and "TXT_KEY_CITYVIEW_PERTURN_TEXT" or "TXT_KEY_CITYVIEW_PERTURN_TEXT_NEGATIVE", foodPerTurnTimes100 / 100 )
end

local function UpdateButtonStates( cityOwner )
	local isLocked = g_isViewingMode or ( cityOwner:GetNumCities() <= 1 )
	Controls.PrevCityButton:SetDisabled( isLocked )
	Controls.NextCityButton:SetDisabled( isLocked )

	for _, button in pairs( g_focusButtons ) do
		button:SetDisabled( g_isViewingMode )
	end
	Controls.AvoidGrowthButton:SetDisabled( g_isViewingMode )
	Controls.ResetButton:SetDisabled( g_isViewingMode )
	Controls.BoxOSlackers:SetDisabled( g_isViewingMode )
	Controls.EditButton:SetHide( g_isViewingMode )
end

local function UpdateCityViewNow()
	g_isCityViewDirty = false
	local city = UI_GetHeadSelectedCity()
	if not city then
		return
	end

	local cityID = city:GetID()
	local cityOwnerID = city:GetOwner()
	local cityOwner = Players[ cityOwnerID ]
	local isActivePlayerCity = cityOwnerID == g_activePlayerID
	local isCityCaptureViewingMode = UI.IsPopupTypeOpen( ButtonPopupTypes.BUTTONPOPUP_CITY_CAPTURED )
	g_isDebugMode = Game.IsDebugMode()
	g_isViewingMode = city:IsPuppet() or not isActivePlayerCity or isCityCaptureViewingMode

	if civ5_mode then
		local isNoAuto = city:IsNoAutoAssignSpecialists()
		Controls.NoAutoSpecialistCheckbox:SetCheck( isNoAuto )
		Controls.NoAutoSpecialistCheckbox:SetDisabled( g_isViewingMode )
		if bnw_mode then
			Controls.NoAutoSpecialistCheckbox2:SetCheck( isNoAuto )
			Controls.NoAutoSpecialistCheckbox2:SetDisabled( g_isViewingMode )
		end
	end

	UpdateBanner( city, cityOwnerID, cityOwner, city:IsCapital() )
	UpdateFocusAndSlackers( city )
	UpdateBuildings( city )
	UpdateResourceDemanded( city )
	UpdateTaskButton( city, cityID, cityOwner, isActivePlayerCity )
	UpdatePlotButtonsNow()
	UpdateCityProductionQueueNow( city, cityID, cityOwnerID,
		isActivePlayerCity and not isCityCaptureViewingMode and civ5bnw_mode and cityOwner:MayNotAnnex() and city:IsPuppet() )
	UpdateYields( city )
	UpdateButtonStates( cityOwner )
end

-- Updates are coalesced: any number of dirty events within a frame result in one refresh.
local function UpdateStuffBody()
	if g_isCityViewDirty then
		UpdateCityViewNow()
	end
	if g_isPlotButtonsDirty then
		UpdatePlotButtonsNow()
	end
end

local function UpdateStuffNow()
	ContextPtr:ClearUpdate()
	return RunBatched( UpdateStuffBody )
end

local function UpdateCityView()
	g_isCityViewDirty = true
	return ContextPtr:SetUpdate( UpdateStuffNow )
end

local function UpdatePlotButtons()
	g_isPlotButtonsDirty = true
	return ContextPtr:SetUpdate( UpdateStuffNow )
end

local function UpdateOptionsAndCityView()
	g_isAutoClose = not ( g_options and g_options.GetValue and g_options.GetValue( "AutoClose" ) == 0 )
	g_FocusSelectIM.Collapse( false )
	Controls.BuyPlotCheckBox:SetCheck( g_BuyPlotMode )
	return UpdateCityView()
end

g_SpecialBuildingsIM = StackInstanceManager( "BuildingInstance", "Button", Controls.SpecialBuildingsStack, Controls.SpecialBuildingsHeader, ResizeRightStack )
g_GreatWorkIM = StackInstanceManager( "BuildingInstance", "Button", Controls.GreatWorkStack, Controls.GreatWorkHeader, ResizeRightStack )
g_WondersIM = StackInstanceManager( "BuildingInstance", "Button", Controls.WondersStack, Controls.WondersHeader, ResizeRightStack )
g_BuildingsIM = StackInstanceManager( "BuildingInstance", "Button", Controls.BuildingsStack, Controls.BuildingsHeader, ResizeRightStack )
g_SlackerIM = StackInstanceManager( "Slot", "Button", Controls.SlackerStack, Controls.SlackerHeader, ResizeRightStack )
g_ProdQueueIM = StackInstanceManager( "ProductionInstance", "PQbox", Controls.QueueStack, Controls.ProdBox, ResizeProdQueue, true )
g_UnitSelectIM = StackInstanceManager( "SelectionInstance", "Button", Controls.UnitButtonStack, Controls.UnitButton, ResizeProdQueue )
g_CivilianSelectIM = StackInstanceManager( "SelectionInstance", "Button", Controls.CivilianButtonStack, Controls.CivilianButton, ResizeProdQueue )
g_BuildingSelectIM = StackInstanceManager( "SelectionInstance", "Button", Controls.BuildingButtonStack, Controls.BuildingsButton, ResizeProdQueue )
g_WonderSelectIM = StackInstanceManager( "SelectionInstance", "Button", Controls.WonderButtonStack, Controls.WondersButton, ResizeProdQueue )
g_ProcessSelectIM = StackInstanceManager( "SelectionInstance", "Button", Controls.OtherButtonStack, Controls.OtherButton, ResizeProdQueue )
g_FocusSelectIM = StackInstanceManager( "", "", Controls.WorkerManagementBox, Controls.WorkerHeader,
	function( self, collapsed )
		g_workerHeadingOpen = not collapsed
		ResizeRightStack()
		UpdatePlotButtons()
	end, true, false )

local function SetToolTipString( toolTipFunc )
	g_leftTipControls.Text:SetText( toolTipFunc( UI_GetHeadSelectedCity() ) )
	g_leftTipControls.PortraitFrame:SetHide( true )
	return g_leftTipControls.Box:DoAutoSize()
end

local g_toolTips = {
	ProdBox = function() return SetToolTipString( GetProductionTooltip ) end,
	FoodBox = function() return SetToolTipString( GetFoodTooltip ) end,
	GoldBox = function() return SetToolTipString( GetGoldTooltip ) end,
	ScienceBox = function() return SetToolTipString( GetScienceTooltip ) end,
	CultureBox = function() return SetToolTipString( GetCultureTooltip ) end,
	FaithBox = function() return SetToolTipString( GetFaithTooltip ) end,
	ProductionPortraitButton = ProductionToolTip,
}
g_toolTips.PopulationBox = g_toolTips.FoodBox
Controls.ProductionPortraitButton:SetVoid1( 0 )

--------------
-- Rename City
local function RenameCity()
	local city = UI_GetHeadSelectedCity()
	if city then
		return Events.SerialEventGameMessagePopup{
			Type = ButtonPopupTypes.BUTTONPOPUP_RENAME_CITY,
			Data1 = city:GetID(),
			Data2 = -1,
			Data3 = -1,
			Option1 = false,
			Option2 = false,
		}
	end
end

----------------
-- Citizen Focus
local FocusButtonBehavior = {
	[Mouse.eLClick] = function( focus )
		local city = GetSelectedModifiableCity()
		if city then
			Network.SendSetCityAIFocus( city:GetID(), focus )
			return Network.SendUpdateCityCitizens( city:GetID() )
		end
	end,
}

local g_callBacks = {
	BalancedFocusButton = FocusButtonBehavior,
	FoodFocusButton = FocusButtonBehavior,
	ProductionFocusButton = FocusButtonBehavior,
	GoldFocusButton = FocusButtonBehavior,
	ResearchFocusButton = FocusButtonBehavior,
	CultureFocusButton = FocusButtonBehavior,
	GPFocusButton = FocusButtonBehavior,
	FaithFocusButton = FocusButtonBehavior,

	AvoidGrowthButton = {
		[Mouse.eLClick] = function()
			local city = GetSelectedModifiableCity()
			if city then
				Network.SendSetCityAvoidGrowth( city:GetID(), not city:IsForcedAvoidGrowth() )
				return Network.SendUpdateCityCitizens( city:GetID() )
			end
		end,
	},
	CityTaskButton = {
		[Mouse.eLClick] = function( cityID, taskID, button )
			local city = GetSelectedCity()
			if city and city:GetID() == cityID then
				return Events.SerialEventGameMessagePopup{
					Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_CITY_TASK,
					Data1 = cityID,
					Data2 = taskID,
					Text = button:GetToolTipString(),
				}
			end
		end,
	},
	YesButton = {
		[Mouse.eLClick] = function( cityID, buildingID )
			Controls.SellBuildingConfirm:SetHide( true )
			if cityID and buildingID and buildingID > 0 and GetSelectedModifiableCity() then
				Network.SendSellBuilding( cityID, buildingID )
				Network.SendUpdateCityCitizens( cityID )
			end
			return Controls.YesButton:SetVoids( -1, -1 )
		end,
	},
	NoButton = { [Mouse.eLClick] = CancelBuildingSale },
	NextCityButton = { [Mouse.eLClick] = GotoNextCity },
	PrevCityButton = { [Mouse.eLClick] = GotoPrevCity },
	ReturnToMapButton = { [Mouse.eLClick] = ExitCityScreen },
	ProductionPortraitButton = { [Mouse.eRClick] = ProductionPedia },
	-- void 0 / -1: remove all slackers
	BoxOSlackers = { [Mouse.eLClick] = OnSlackersSelected },
	-- void 0 = city center: resets all forced tiles
	ResetButton = { [Mouse.eLClick] = PlotButtonClicked },
	NoAutoSpecialistCheckbox = {
		[Mouse.eLClick] = function()
			local city = GetSelectedModifiableCity()
			if city then
				return Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_NO_AUTO_ASSIGN_SPECIALISTS, -1, -1, not city:IsNoAutoAssignSpecialists() )
			end
		end,
	},
	EditButton = { [Mouse.eLClick] = RenameCity },
	CityNameTitleBarLabel = { [Mouse.eRClick] = RenameCity },
}
g_callBacks.NoAutoSpecialistCheckbox2 = g_callBacks.NoAutoSpecialistCheckbox

Controls.GPFocusButton:SetHide( civBE_mode )
Controls.FaithBox:SetHide( civBE_mode or not gk_mode )
Controls.FaithFocusButton:SetHide( civBE_mode or not gk_mode )
Controls.TourismBox:SetHide( true )
Controls.GPHeader:SetHide( true )
Controls.GPStack:SetHide( true )

-- selection headers and grids are always visible, even when a list is empty
for _, name in ipairs{ "BuildingsButton", "BuildingGrid", "UnitButton", "UnitGrid", "WondersButton", "WonderGrid",
		"OtherButton", "OtherGrid", "CivilianButton", "CivilianGrid" } do
	Controls[ name ]:SetHide( false )
end

SetupCallbacks( Controls, g_toolTips, "EUI_CityViewLeftTooltip", g_callBacks )

Controls.BuyPlotCheckBox:RegisterCheckHandler( function( isChecked )
	g_BuyPlotMode = isChecked
	g_options.SetValue( "CityPlotPurchase", isChecked and 1 or 0 )
	return UpdateCityView()
end )

Controls.PQbox:SetVoid1( 0 )
Controls.PQbox:RegisterCallback( Mouse.eMouseEnter, SwapQueueItem )
Controls.PQbox:RegisterCallback( Mouse.eRClick, RemoveQueueItem )
Controls.PQbox:RegisterCallback( Mouse.eLClick, RemoveQueueItem )
Controls.PQbox:SetToolTipCallback( ProductionToolTip )
Controls.PQremove:SetVoid1( 0 )
Controls.PQremove:RegisterCallback( Mouse.eLClick, RemoveQueueItem )

----------------------------------------------
-- Register Events
----------------------------------------------
Events.SerialEventCityScreenDirty.Add( UpdateCityView )
Events.SerialEventCityInfoDirty.Add( UpdateCityView )
Events.GameOptionsChanged.Add( UpdateOptionsAndCityView )
Events.SerialEventCityHexHighlightDirty.Add( UpdatePlotButtons )
UpdateOptionsAndCityView()

--------------------------
-- Enter City Screen Event
Events.SerialEventEnterCityScreen.Add(
function()
	local city = UI_GetHeadSelectedCity()
	if not g_isButtonPopupChooseProduction
		and city
		and city:GetOwner() == g_activePlayerID
		and not city:IsPuppet()
		and city:GetOrderQueueLength() < 1
	then
		g_isButtonPopupChooseProduction = true
		g_chainVisited = {}
	end

	LuaEvents.TryQueueTutorial( "CITY_SCREEN", true )

	g_queuedItemNumber = false
	Controls.RightScrollPanel:SetScrollValue( 0 )
end)

-------------------------
-- Exit City Screen Event
Events.SerialEventExitCityScreen.Add(
function()
	Events.ClearHexHighlights()	-- clears anything left over by other contexts

	-- we may get here after a player change, clear the UI if this is not the active player's city
	local city = UI_GetHeadSelectedCity()
	if not city or city:GetOwner() ~= g_activePlayerID then
		ClearCityUIInfo()
	end
	UI.ClearSelectedCities()
	LuaEvents.TryDismissTutorial( "CITY_SCREEN" )

	CancelBuildingSale()

	-- try and re-select the last unit selected
	if not UI.GetHeadSelectedUnit() then
		local unit = UI.GetLastSelectedUnit()
		if unit and unit:MovesLeft() > 0 then
			UI.SelectUnit( unit )
			UI.LookAtSelectionPlot()
		end
	end
	g_isViewingMode = true
	return UI.SetCityScreenViewingMode( false )
end)

if civ5_mode then
	------------------------------------
	-- Strategic View State Change Event
	local NormalWorldPositionOffset = g_worldPositionOffset
	local NormalWorldPositionOffset2 = g_worldPositionOffset2
	local StrategicViewWorldPositionOffset = { x = 0, y = 20, z = 0 }
	Events.StrategicViewStateChanged.Add(
	function( bStrategicView )
		if bStrategicView then
			g_worldPositionOffset = StrategicViewWorldPositionOffset
			g_worldPositionOffset2 = StrategicViewWorldPositionOffset
		else
			g_worldPositionOffset = NormalWorldPositionOffset
			g_worldPositionOffset2 = NormalWorldPositionOffset2
		end
		return UpdateCityView()
	end)
end

--------------------------------------------
-- 'Active' (local human) player has changed (hotseat)
Events.GameplaySetActivePlayer.Add(
function( activePlayerID )
	g_activePlayerID = activePlayerID
	g_activePlayer = Players[ g_activePlayerID ]
	g_finishedItems = {}
	g_chainVisited = {}
	ClearCityUIInfo()
	if UI.IsCityScreenUp() then
		return ExitCityScreen()
	end
end)

Events.ActivePlayerTurnEnd.Add(
function()
	g_finishedItems = {}
	g_chainVisited = {}
end)

Events.SerialEventGameMessagePopup.Add(
function( popupInfo )
	if popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate( ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION, 0 )
		Events.SerialEventGameMessagePopupShown( popupInfo )

		local cityID = popupInfo.Data1		-- city id
		local orderID = popupInfo.Data2		-- finished order id
		local itemID = popupInfo.Data3		-- finished item id
		local city = cityID and g_activePlayer:GetCityByID( cityID )

		if city and not UI.IsCityScreenUp() then
			if orderID >= 0 and itemID >= 0 then
				g_finishedItems[ cityID ] = { orderID, itemID }
			end
			g_isButtonPopupChooseProduction = true
			return UI.DoSelectCityAtPlot( city:Plot() )	-- open city screen
		end
	end
end)

Events.NotificationAdded.Add(
function( notificationID, notificationType, toolTip, strSummary, data1, data2, playerID )
	if notificationType == NotificationTypes.NOTIFICATION_PRODUCTION and playerID == g_activePlayerID then
		-- find the city this notification belongs to
		for city in g_activePlayer:Cities() do
			if strSummary == L( "TXT_KEY_NOTIFICATION_NEW_CONSTRUCTION", city:GetNameKey() ) then
				if data1 >= 0 and data2 >= 0 then
					g_finishedItems[ city:GetID() ] = { data1, data2 }
				end
				if city:GetGameTurnFounded() == Game.GetGameTurn() and not UI.IsCityScreenUp() then
					return UI.DoSelectCityAtPlot( city:Plot() )	-- open city screen
				end
				return
			end
		end
	end
end)

print( "Finished loading EUI city view", os.clock() )
end)

---------------------------------
-- Support for Modded Add-in UI's
---------------------------------
local g_uiAddins = {}
for addin in Modding.GetActivatedModEntryPoints( "CityViewUIAddin" ) do
	local addinFile = Modding.GetEvaluatedFilePath( addin.ModID, addin.Version, addin.File )
	local addinPath = addinFile.EvaluatedPath

	-- absolute path and filename without extension
	local extension = Path.GetExtension( addinPath )
	local ok, result = pcall( ContextPtr.LoadNewContext, ContextPtr, addinPath:sub( 1, #addinPath - #extension ) )
	if ok then
		table.insert( g_uiAddins, result )
	else
		print( addinPath, result )
	end
end

Controls.WorkerHeader:SetHide( true )