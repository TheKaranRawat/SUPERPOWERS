--==========================================================
-- City View
-- Re-written by bc1 using Notepad++
-- code is common using switches
-- compatible with Gazebo's City-State Diplomacy Mod (CSD) for Brave New World v21
-- compatible with JFD's Piety & Prestige for Brave New World
-- compatible with GameInfo.Yields() iterator broken by Communitas
--todo: upper left corner
--todo: selection list with all buildable items
--todo: mod case where several buildings are allowed
--==========================================================

include( "IconSupport" );

Events.SequenceGameInitComplete.Add(function()

local IsCiv5 = InStrategicView ~= nil
local IsCivBE = not IsCiv5
local IsCiv5vanilla = IsCiv5 and not Game.GetReligionName
local IsCiv5BNW = IsCiv5 and Game.GetActiveLeague ~= nil

include "UserInterfaceSettings"
local UserInterfaceSettings = UserInterfaceSettings

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfo = GameInfoCache

include "IconHookup"
local IconHookup = IconHookup
local CivIconHookup = CivIconHookup
local ColorCulture = Color( 1, 0, 1, 1 )

include "StackInstanceManager"
local StackInstanceManager = StackInstanceManager

include "ShowProgress"
local ShowProgress = ShowProgress

include "SupportFunctions"
local TruncateString = TruncateString

if IsCiv5BNW then
	include "GreatPeopleIcons"
end
local GreatPeopleIcons = GreatPeopleIcons

if IsCivBE then
	include "IntrigueHelper"
end

--==========================================================
-- Minor lua optimizations
--==========================================================

local ipairs = ipairs
local abs = math.abs
local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local unpack = unpack
local concat = table.concat
local insert = table.insert
local sort = table.sort

local ButtonPopupTypes = ButtonPopupTypes
local CityAIFocusTypes = CityAIFocusTypes
local CityUpdateTypes = CityUpdateTypes
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local EventsClearHexHighlightStyle = Events.ClearHexHighlightStyle.Call
local EventsRequestYieldDisplay = Events.RequestYieldDisplay.Call
local EventsSerialEventHexHighlight = Events.SerialEventHexHighlight.Call
local Game = Game
local GameDefines = GameDefines
local GameInfoTypes = GameInfoTypes
local GameMessageTypes = GameMessageTypes
local GameOptionTypes = GameOptionTypes
local HexToWorld = HexToWorld
local InStrategicView = InStrategicView or function() return false end
local KeyEvents = KeyEvents
local Keys = Keys
local L = Locale.ConvertTextKey
local Locale = Locale
local eLClick = Mouse.eLClick
local eRClick = Mouse.eRClick
local eMouseEnter = Mouse.eMouseEnter
local Network = Network
local NotificationTypes = NotificationTypes
local OptionsManager = OptionsManager
local Players = Players
local PopupPriority = PopupPriority
local TaskTypes = TaskTypes
local ToHexFromGrid = ToHexFromGrid
local UI = UI
local GetHeadSelectedCity = UI.GetHeadSelectedCity
local GetUnitPortraitIcon = UI.GetUnitPortraitIcon
local YieldDisplayTypesAREA = YieldDisplayTypes.AREA
local YieldTypes = YieldTypes

local ORDER_TRAIN = OrderTypes.ORDER_TRAIN
local ORDER_CONSTRUCT = OrderTypes.ORDER_CONSTRUCT
local ORDER_CREATE = OrderTypes.ORDER_CREATE
local ORDER_MAINTAIN = OrderTypes.ORDER_MAINTAIN

--==========================================================
-- Globals
--==========================================================

local g_currencyIcon = IsCiv5 and "[ICON_GOLD]" or "[ICON_ENERGY]"
local g_maintenanceCurrency = IsCiv5 and "GoldMaintenance" or "EnergyMaintenance"
local g_yieldCurrency = IsCiv5 and YieldTypes.YIELD_GOLD or YieldTypes.YIELD_ENERGY

local g_isAdvisor = true

local g_activePlayerID = Game.GetActivePlayer()
local g_activePlayer = Players[ g_activePlayerID ]
local g_finishedItems = {}

local g_workerHeadingOpen = OptionsManager.IsNoCitizenWarning()

local g_worldPositionOffset = { x = 0, y = 0, z = 30 }
local g_worldPositionOffset2 = { x = 0, y = 35, z = 0 }
local g_portraitSize = Controls.PQportrait:GetSizeX()
local g_screenHeight = select(2, UIManager.GetScreenSizeVal() )
local g_leftStackHeigth = g_screenHeight - 40 - Controls.CityInfoBG:GetOffsetY() - Controls.CityInfoBG:GetSizeY()

local g_PlotButtonIM	= StackInstanceManager( "PlotButtonInstance", "PlotButtonAnchor", Controls.PlotButtonContainer )
local g_BuyPlotButtonIM	= StackInstanceManager( "BuyPlotButtonInstance", "BuyPlotButtonAnchor", Controls.PlotButtonContainer )
local g_GreatWorksIM	= StackInstanceManager( "Work", "Button", false )
local g_SpecialistsIM	= StackInstanceManager( "Slot", "Button", false )

local g_ProdQueueIM, g_SpecialBuildingsIM, g_GreatWorkIM, g_WondersIM, g_BuildingsIM, g_GreatPeopleIM, g_SlackerIM, g_UnitSelectIM, g_BuildingSelectIM, g_WonderSelectIM, g_ProcessSelectIM, g_FocusSelectIM
local g_queuedItemNumber, g_isDebugMode, g_BuyPlotMode, g_previousCity, g_isButtonPopupChooseProduction, g_isScreenAutoClose, g_isResetCityPlotPurchase

local g_citySpecialists = {}

local g_isViewingMode = true

local g_slotTexture = {
	SPECIALIST_CITIZEN = "CitizenUnemployed.dds",
	SPECIALIST_SCIENTIST = "CitizenScientist.dds",
	SPECIALIST_MERCHANT = "CitizenMerchant.dds",
	SPECIALIST_ARTIST = "CitizenArtist.dds",
	SPECIALIST_MUSICIAN = "CitizenArtist.dds",
	SPECIALIST_WRITER = "CitizenArtist.dds",
	SPECIALIST_ENGINEER = "CitizenEngineer.dds",
	SPECIALIST_CIVIL_SERVANT = "CitizenCivilServant.dds",	-- Compatibility with Gazebo's City-State Diplomacy Mod (CSD) for Brave New World
	SPECIALIST_JFD_MONK = "CitizenMonk.dds", -- Compatibility with JFD's Piety & Prestige for Brave New World
	SPECIALIST_PMMM_ENTERTAINER = "PMMMEntertainmentSpecialist.dds", --Compatibility with Vicevirtuoso's Madoka Magica: Wish for the World for Brave New World
}
for specialist in GameInfo.Specialists() do
	if specialist.SlotTexture then
		g_slotTexture[ specialist.Type ] = specialist.SlotTexture
	end
end

local g_slackerTexture = IsCivBE and "UnemployedIndicator.dds" or g_slotTexture[ (GameInfo.Specialists[GameDefines.DEFAULT_SPECIALIST] or {}).Type ]

local g_gameInfo = {
[ORDER_TRAIN] = GameInfo.Units,
[ORDER_CONSTRUCT] = GameInfo.Buildings,
[ORDER_CREATE] = GameInfo.Projects,
[ORDER_MAINTAIN] = GameInfo.Processes,
}
local g_avisorRecommended = {
[ORDER_TRAIN] = Game.IsUnitRecommended,
[ORDER_CONSTRUCT] = Game.IsBuildingRecommended,
[ORDER_CREATE] = Game.IsProjectRecommended,
}
local g_advisors = {
[AdvisorTypes.ADVISOR_ECONOMIC] = "EconomicRecommendation",
[AdvisorTypes.ADVISOR_MILITARY] = "MilitaryRecommendation",
[AdvisorTypes.ADVISOR_SCIENCE] = "ScienceRecommendation",
[AdvisorTypes.ADVISOR_FOREIGN] = "ForeignRecommendation",
}

local function GetSelectedCity()
	return ( not Game.IsNetworkMultiPlayer() or g_activePlayer:IsTurnActive() ) and GetHeadSelectedCity()
end

local function GetSelectedModifiableCity()
	return not g_isViewingMode and GetSelectedCity()
end

----------------
-- Citizen Focus
local g_cityFocusButtons = {
		a = Controls.AvoidGrowthButton,
		b = Controls.ResetButton,
		c = Controls.BoxOSlackers,
		d = Controls.EditButton,
}
do
	local g_cityFocusControls = {
		[ Controls.BalancedFocusButton or -1 ] =  CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE or false,
		[ Controls.FoodFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD or false,
		[ Controls.ProductionFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION or false,
		[ Controls.GoldFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD or CityAIFocusTypes.CITY_AI_FOCUS_TYPE_ENERGY or false,
		[ Controls.ResearchFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE or false,
		[ Controls.CultureFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE or false,
		[ Controls.GPFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE or false,
		[ Controls.FaithFocusButton or -1 ] =  CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH or false,
	} g_cityFocusControls[-1] = nil
	local function FocusButtonBehavior( focus )
		local city = GetSelectedModifiableCity()
		if city then
			Network.SendSetCityAIFocus( city:GetID(), focus )
			return Network.SendUpdateCityCitizens( city:GetID() )
		end
	end
	for control, focus in pairs( g_cityFocusControls ) do
		if focus then
			g_cityFocusButtons[ focus ] = control
			control:SetVoid1( focus )
			control:RegisterCallback( eLClick, FocusButtonBehavior )
		else
			control:SetHide( true )
		end
	end
end

local function HexRadius( a )
	return ( sqrt( 1 + 4*a/3 ) - 1 ) / 2
end

local function SetupCallbacks( controls, toolTips, tootTipType, callBacks )
	local control
	-- Setup Tootips
	for name, callback in pairs( toolTips ) do
		control = controls[name]
		if control then
			control:SetToolTipCallback( callback )
			control:SetToolTipType( tootTipType )
		end
	end
	-- Setup Callbacks
	for name, eventCallbacks in pairs( callBacks ) do
		control = controls[name]
		if control then
			for event, callback in pairs( eventCallbacks ) do
				control:RegisterCallback( event, callback )
			end
		end
	end
end

local function ResizeProdQueue()
	local selectionPanelHeight = 0
	local queuePanelHeight = min( 190, Controls.QueueStack:IsHidden() and 0 or Controls.QueueStack:GetSizeY() )	-- 190 = 5 x 38=instance height
	if not Controls.SelectionScrollPanel:IsHidden() then
		Controls.SelectionStacks:CalculateSize()
		selectionPanelHeight = max( min( g_leftStackHeigth - queuePanelHeight, Controls.SelectionStacks:GetSizeY() ), 64 )
--		Controls.SelectionBackground:SetSizeY( selectionPanelHeight + 85 )
		Controls.SelectionScrollPanel:SetSizeY( selectionPanelHeight )
		Controls.SelectionScrollPanel:CalculateInternalSize()
		Controls.SelectionScrollPanel:ReprocessAnchoring()
	end
	Controls.QueueSlider:SetSizeY( queuePanelHeight + 38 )				-- 38 = Controls.PQbox:GetSizeY()
	Controls.QueueScrollPanel:SetSizeY( queuePanelHeight )
	Controls.QueueScrollPanel:CalculateInternalSize()
	Controls.QueueBackground:SetSizeY( queuePanelHeight + selectionPanelHeight + 152 )	-- 125 = 38=Controls.PQbox:GetSizeY() + 87 + 27
	return Controls.QueueBackground:ReprocessAnchoring()
end

local function ResizeRightStack()
	Controls.BoxOSlackers:SetHide( Controls.SlackerStack:IsHidden() )
	Controls.BoxOSlackers:SetSizeY( Controls.SlackerStack:GetSizeY() )
	Controls.WorkerManagementBox:CalculateSize()
	Controls.WorkerManagementBox:ReprocessAnchoring()
	Controls.RightStack:CalculateSize()
	local rightStackHeight = Controls.RightStack:GetSizeY() + 85
	Controls.BuildingListBackground:SetSizeY( max( min( g_screenHeight + 48, rightStackHeight ), 160 ) )
	Controls.RightScrollPanel:SetSizeY( min( g_screenHeight - 38, rightStackHeight ) )
	Controls.RightScrollPanel:CalculateInternalSize()
	return Controls.RightScrollPanel:ReprocessAnchoring()
end

local cityIsCanPurchase
if IsCiv5vanilla then
	function cityIsCanPurchase( city, bTestPurchaseCost, bTestTrainable, unitID, buildingID, projectID, yieldID )
		if yieldID == g_yieldCurrency then
			return city:IsCanPurchase( not bTestPurchaseCost, unitID, buildingID, projectID )
							-- bOnlyTestVisible
		else
			return false
		end
	end
else
	function cityIsCanPurchase( city, ... )
		return city:IsCanPurchase( ... )
	end
end

--==========================================================
-- Clear out the UI so that when a player changes
-- the next update doesn't show the previous player's
-- values for a frame
--==========================================================
local function ClearCityUIInfo()
	g_ProdQueueIM:ResetInstances()
	g_ProdQueueIM.Commit()
	Controls.PQremove:SetHide( true )
	Controls.PQrank:SetText()
	Controls.PQname:SetText()
	Controls.PQturns:SetText()
	return Controls.ProductionPortraitButton:SetHide(true)
end

--==========================================================
-- Selling Buildings
--==========================================================
local function SellBuilding( buildingID )

	local city = GetSelectedModifiableCity()
	local building = GameInfo.Buildings[ buildingID ]
	-- Can this building be sold?
	if building and city and city:IsBuildingSellable( buildingID ) then
		Controls.YesButton:SetVoids( city:GetID(), buildingID )
		Controls.SellBuildingTitle:SetText( building._Name:upper() )
		Controls.SellBuildingText:LocalizeAndSetText( "TXT_KEY_SELL_BUILDING_INFO", city:GetSellBuildingRefund(buildingID), building[g_maintenanceCurrency] or 0 )
		Controls.SellBuildingImage:SetHide( not IconHookup( building.PortraitIndex, 256, building.IconAtlas, Controls.SellBuildingImage ) )
		Controls.SellBuildingStack:CalculateSize()
		Controls.SellBuildingFrame:DoAutoSize()
--todo energy
		return Controls.SellBuildingConfirm:SetHide( false )
	end
end

local function CancelBuildingSale()
	Controls.SellBuildingConfirm:SetHide(true)
	return Controls.YesButton:SetVoids( -1, -1 )
end

local function CleanupCityScreen()
	-- clear any rogue leftover tooltip
	g_isButtonPopupChooseProduction = false
	Controls.RightScrollPanel:SetScrollValue(0)
	return CancelBuildingSale()
end

local function GotoNextCity()
	if not g_isViewingMode then
		CleanupCityScreen()
		return Game.DoControl( GameInfoTypes.CONTROL_NEXTCITY )
	end
end

local function GotoPrevCity()
	if not g_isViewingMode then
		CleanupCityScreen()
		return Game.DoControl( GameInfoTypes.CONTROL_PREVCITY )
	end
end

local function ExitCityScreen()
--print("request exit city screen")
--	CleanupCityScreen()
	return Events.SerialEventExitCityScreen()
end

--==========================================================
-- Key Down Processing
--==========================================================
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local VK_LEFT  = Keys.VK_LEFT
	local VK_RIGHT = Keys.VK_RIGHT
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function ( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				if Controls.SellBuildingConfirm:IsHidden() then
					ExitCityScreen()
				else
					CancelBuildingSale()
				end
				return true
			elseif wParam == VK_LEFT then
				GotoPrevCity()
				return true
			elseif wParam == VK_RIGHT then
				GotoNextCity()
				return true
			end
		end
	end)
end

--==========================================================
-- Pedia
--==========================================================
local SearchForPediaEntry = Events.SearchForPediaEntry.Call
local function Pedia( row )
	return SearchForPediaEntry( row and row._Name )
end
	
local function UnitClassPedia( unitClassID )
	return Pedia( GameInfo.UnitClasses[ unitClassID ] )
end

local function BuildingPedia( buildingID )
	return Pedia( GameInfo.Buildings[ buildingID ] )
end

local function SpecialistPedia( buildingID )
	return Pedia( GameInfo.Specialists[ GameInfoTypes[(GameInfo.Buildings[buildingID]or{}).SpecialistType] or GameDefines.DEFAULT_SPECIALIST ] )
end

local function SelectionPedia( orderID, itemID )
	return Pedia( (g_gameInfo[ orderID ]or{})[ itemID ] )
end

local function ProductionPedia( queuedItemNumber )
	local city = GetHeadSelectedCity()
	if city and queuedItemNumber then
		return SelectionPedia( city:GetOrderFromQueue( queuedItemNumber ) )
	end
end

--==========================================================
-- Tooltips
--==========================================================

local GreatPeopleIcon = GreatPeopleIcons and function (k)
	return GreatPeopleIcons[k] 
end or function()
	return "[ICON_GREAT_PEOPLE]"
end

local function GetSpecialistYields( city, specialist )
	local yieldTips = {}
	if city and specialist then
		local specialistYield, specialistYieldModifier, yieldInfo
		local specialistID = specialist.ID
		local cityOwner = Players[ city:GetOwner() ]
		-- Culture
		local cultureFromSpecialist = city:GetCultureFromSpecialist( specialistID )
		local specialistCultureModifier = city:GetCultureRateModifier() + ( cityOwner and ( cityOwner:GetCultureCityModifier() + ( city:GetNumWorldWonders() > 0 and cityOwner:GetCultureWonderMultiplier() or 0 ) or 0 ) )
		-- Yield
		for yieldID = 0, YieldTypes.NUM_YIELD_TYPES-1 do
			yieldInfo = GameInfo.Yields[yieldID]
			if yieldInfo then
				specialistYield = city:GetSpecialistYield( specialistID, yieldID )
				specialistYieldModifier = city:GetBaseYieldRateModifier( yieldID )
				if yieldID == YieldTypes.YIELD_CULTURE then
					specialistYield = specialistYield + cultureFromSpecialist
					specialistYieldModifier = specialistYieldModifier + specialistCultureModifier
					cultureFromSpecialist = 0
				end
				if specialistYield ~= 0 then
					insert( yieldTips, specialistYield * specialistYieldModifier / 100 .. yieldInfo.IconString )
				end
			end
		end
		if cultureFromSpecialist ~= 0 then
			insert( yieldTips, cultureFromSpecialist .. "[ICON_CULTURE]" )
		end
		if IsCiv5 and (specialist.GreatPeopleRateChange or 0) ~= 0 then
			insert( yieldTips, specialist.GreatPeopleRateChange .. GreatPeopleIcon( specialist.Type ) )
		end
	end
	return concat( yieldTips, " " )
end

local ShowTextToolTipAndPicture = LuaEvents.ShowTextToolTipAndPicture.Call
local BuildingToolTip = LuaEvents.CityViewBuildingToolTip.Call
local CityOrderItemTooltip = LuaEvents.CityOrderItemTooltip.Call

local function SpecialistTooltip( control )
	local buildingID = control:GetVoid1()
	local building = GameInfo.Buildings[ buildingID ]
	local specialistType = building and building.SpecialistType
	local specialistID = specialistType and GameInfoTypes[specialistType] or GameDefines.DEFAULT_SPECIALIST
	local specialist = GameInfo.Specialists[ specialistID ]
	local tip = specialist._Name .. " " .. GetSpecialistYields( GetHeadSelectedCity(), specialist )
	local slotTable = building and g_citySpecialists[buildingID]
	if slotTable and not slotTable[control:GetVoid2()] then
		tip = L"TXT_KEY_CITYVIEW_EMPTY_SLOT".."[NEWLINE]("..tip..")"
	end
	return ShowTextToolTipAndPicture( tip, specialist.PortraitIndex, specialist.IconAtlas )
end

local function ProductionToolTip( control )
	local city = GetHeadSelectedCity()
	local queuedItemNumber = control:GetVoid1()
	if city and not Controls.QueueSlider:IsTrackingLeftMouseButton() then
		return CityOrderItemTooltip( city, false, false, city:GetOrderFromQueue( queuedItemNumber ) )
	end
end

--==========================================================
-- Specialist Managemeent
--==========================================================

local function OnSlackersSelected( buildingID, slotID )
	local city = GetSelectedModifiableCity()
	if city then
		for _=1, slotID<=0 and city:GetSpecialistCount( GameDefines.DEFAULT_SPECIALIST ) or 1 do
			Network.SendDoTask( city:GetID(), TaskTypes.TASK_REMOVE_SLACKER, 0, -1, false )
		end
	end
end

local function ToggleSpecialist( buildingID, slotID )
	local city = buildingID and slotID and GetSelectedModifiableCity()
	if city then

		-- If Specialists are automated then you can't change things with them
		if IsCiv5 and not city:IsNoAutoAssignSpecialists() then
			Game.SelectedCitiesGameNetMessage(GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_NO_AUTO_ASSIGN_SPECIALISTS, -1, -1, true)
			Controls.NoAutoSpecialistCheckbox:SetCheck(true)
			if IsCiv5BNW then
				Controls.NoAutoSpecialistCheckbox2:SetCheck(true)
			end
		end

		local specialistID = GameInfoTypes[(GameInfo.Buildings[ buildingID ] or {}).SpecialistType] or -1
		local specialistTable = g_citySpecialists[buildingID]
		if specialistTable[slotID] then
			if city:GetNumSpecialistsInBuilding(buildingID) > 0 then
				specialistTable[slotID] = false
				specialistTable.n = specialistTable.n - 1
				return Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_REMOVE_SPECIALIST, specialistID, buildingID )
			end
		elseif city:IsCanAddSpecialistToBuilding(buildingID) then
			specialistTable[slotID] = true
			specialistTable.n = specialistTable.n + 1
			return Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_ADD_SPECIALIST, specialistID, buildingID )
		end
	end
end

--==========================================================
-- Great Work Managemeent
--==========================================================

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

local function YourCulturePopup( greatWorkID )
	return Events.SerialEventGameMessagePopup{
		Type = ButtonPopupTypes.BUTTONPOPUP_CULTURE_OVERVIEW,
		Data1 = 1,
		Data2 = 1,
		}
end

local function ThemingTooltip( buildingClassID, _, control )
	control:SetToolTipString( GetHeadSelectedCity():GetThemingTooltip( buildingClassID ) )
end

local function GreatWorkTooltip( greatWorkID, greatWorkSlotID, slot )
	if greatWorkID >= 0 then
		return slot:SetToolTipString( Game.GetGreatWorkTooltip( greatWorkID, GetHeadSelectedCity():GetOwner() ) )
	else
		return slot:LocalizeAndSetToolTip( tostring(( GameInfo.GreatWorkSlots[ greatWorkSlotID ] or {}).EmptyToolTipText) )
	end
end

--==========================================================
-- City Buildings List
--==========================================================

local function sortBuildings(a,b)
	if a and b then
		if a[4] ~= b[4] then
			return a[4] < b[4]
		elseif a[3] ~= b[3] then
			return a[3] > b[3]
		end
		return a[2] < b[2]
	end
end

local function SetupBuildingList( city, buildings, buildingIM )
	buildingIM:ResetInstances()
	sort( buildings, sortBuildings )
	local cityOwnerID = city:GetOwner()
	local cityOwner = Players[ cityOwnerID ]
	local isNotResistance = not city:IsResistance()
	-- Get the active perk types for civ BE
	local cityOwnerPerks = IsCivBE and cityOwner:GetAllActivePlayerPerkTypes()
	local building, buildingID, buildingClassID, buildingName, greatWorkCount, greatWorkID, slotStack, slot, new, instance, buildingButton, sellButton, textButton

	for i = 1, #buildings do

		building, buildingName, greatWorkCount = unpack(buildings[i])
		buildingID = building.ID
		buildingClassID = GameInfoTypes[ building.BuildingClass ] or -1
		instance, new = buildingIM:GetInstance()
		slotStack = instance.SlotStack
		buildingButton = instance.Button
		sellButton = instance.SellButton
		textButton = instance.TextButton
		textButton:SetHide( true )

		if new then
			buildingButton:RegisterCallback( eRClick, BuildingPedia )
			buildingButton:SetToolTipCallback( BuildingToolTip )
			sellButton:RegisterCallback( eLClick, SellBuilding )
			textButton:RegisterCallback( eLClick, YourCulturePopup )
			textButton:RegisterCallback( eMouseEnter, ThemingTooltip )
		end
		buildingButton:SetVoid1( buildingID )

		-- Can we sell this building?
		if not g_isViewingMode and city:IsBuildingSellable( buildingID ) then
			sellButton:SetText( city:GetSellBuildingRefund( buildingID ) .. g_currencyIcon )
			sellButton:SetHide( false )
			sellButton:SetVoid1( buildingID )
		else
			sellButton:SetHide( true )
		end


--!!!BE portrait size is bigger

		instance.Portrait:SetHide( not IconHookup( building.PortraitIndex, 64, building.IconAtlas, instance.Portrait ) )

		-------------------
		-- Great Work Slots
		if greatWorkCount > 0 then
			local buildingGreatWorkSlotType = building.GreatWorkSlotType
			if buildingGreatWorkSlotType then
				local buildingGreatWorkSlot = GameInfo.GreatWorkSlots[ buildingGreatWorkSlotType ]
				if city:IsThemingBonusPossible( buildingClassID ) then
					textButton:SetText( " +" .. city:GetThemingBonus( buildingClassID ) )
					textButton:SetVoid1( buildingClassID )
					textButton:SetHide( false )
				end

				for i = 0, greatWorkCount - 1 do
					slot, new = g_GreatWorksIM:GetInstance( slotStack )
					slot = slot.Button
					if new then
						slot:RegisterCallback( eLClick, YourCulturePopup )
						slot:RegisterCallback( eMouseEnter, GreatWorkTooltip )
					end
					greatWorkID = city:GetBuildingGreatWork( buildingClassID, i )
					slot:SetVoids( greatWorkID, buildingGreatWorkSlot.ID )
					if greatWorkID >= 0 then
						slot:SetTexture( buildingGreatWorkSlot.FilledIcon )
						slot:RegisterCallback( eRClick, GreatWorkPopup )
					else
						slot:SetTexture( buildingGreatWorkSlot.EmptyIcon )
						slot:ClearCallback( eRClick )
					end
				end
			end
		end

		-------------------
		-- Specialist Slots
		local numSpecialistsInBuilding = city:GetNumSpecialistsInBuilding( buildingID )
		local specialistTable = g_citySpecialists[buildingID] or {}
		if specialistTable.n ~= numSpecialistsInBuilding then
			specialistTable = { n = numSpecialistsInBuilding }
			for i = 1, numSpecialistsInBuilding do
				specialistTable[i] = true
			end
			g_citySpecialists[buildingID] = specialistTable
		end
		local specialistType = building.SpecialistType
		local specialist = GameInfo.Specialists[specialistType]
		if specialist then
			for slotID = 1, city:GetNumSpecialistsAllowedByBuilding( buildingID ) do
				slot, new = g_SpecialistsIM:GetInstance( slotStack )
				slot = slot.Button
				if new then
					slot:RegisterCallback( eRClick, SpecialistPedia )
					slot:SetToolTipCallback( SpecialistTooltip )
				end
				if IsCiv5 then
					slot:SetTexture( specialistTable[ slotID ] and g_slotTexture[ specialistType ] or "CitizenEmpty.dds" )
				else
					-- todo (does not look right)
					IconHookup( specialist.PortraitIndex, 45, specialist.IconAtlas, slot )
					slot:SetHide( not specialistTable[ slotID ] )
				end
				slot:SetVoids( buildingID, slotID )
				if g_isViewingMode then
					slot:ClearCallback( eLClick )
				else
					slot:RegisterCallback( eLClick, ToggleSpecialist )
				end
			end -- Specialist Slots
		end

		-- Building stats/bonuses
		local maintenanceCost = tonumber(building[g_maintenanceCurrency]) or 0
		local defenseChange = tonumber(building.Defense) or 0
		local hitPointChange = tonumber(building.ExtraCityHitPoints) or 0
		local buildingCultureRate = (IsCiv5vanilla and tonumber(building.Culture) or 0) + (specialist and city:GetCultureFromSpecialist( specialist.ID ) or 0) * numSpecialistsInBuilding
		local buildingCultureModifier = tonumber(building.CultureRateModifier) or 0
		local cityCultureRateModifier = cityOwner:GetCultureCityModifier() + city:GetCultureRateModifier() + (city:GetNumWorldWonders() > 0 and cityOwner and cityOwner:GetCultureWonderMultiplier() or 0)
		local cityCultureRate
		local population = city:GetPopulation()
		local tips = {}
		local thisBuildingAndYieldTypes = { BuildingType = building.Type }
		if IsCiv5 then
			cityCultureRate = city:GetBaseJONSCulturePerTurn()
			-- Happiness
			local happinessChange = (tonumber(building.Happiness) or 0) + (tonumber(building.UnmoddedHappiness) or 0)
						+ cityOwner:GetExtraBuildingHappinessFromPolicies( buildingID )
						+ (cityOwner:IsHalfSpecialistUnhappiness() and GameDefines.UNHAPPINESS_PER_POPULATION * numSpecialistsInBuilding * ((city:IsCapital() and cityOwner:GetCapitalUnhappinessMod() or 0)+100) * (cityOwner:GetUnhappinessMod() + 100) * (cityOwner:GetTraitPopUnhappinessMod() + 100) / 2e6 or 0) -- missing getHandicapInfo().getPopulationUnhappinessMod()
			if happinessChange ~=0 then
				insert( tips, happinessChange .. "[ICON_HAPPINESS_1]" )
			end
		else -- IsCivBE
			cityCultureRate = city:GetBaseCulturePerTurn()
			-- Health
			local healthChange = (tonumber(building.Health) or 0) + (tonumber(building.UnmoddedHealth) or 0) + cityOwner:GetExtraBuildingHealthFromPolicies( buildingID )
			local healthModifier = tonumber(building.HealthModifier) or 0
			-- Effect of player perks
			for _, perkID in ipairs(cityOwnerPerks) do
				healthChange = healthChange + Game.GetPlayerPerkBuildingClassPercentHealthChange( perkID, buildingClassID )
				healthModifier = healthModifier + Game.GetPlayerPerkBuildingClassPercentHealthChange( perkID, buildingClassID )
				defenseChange = defenseChange + Game.GetPlayerPerkBuildingClassCityStrengthChange( perkID, buildingClassID )
				hitPointChange = hitPointChange + Game.GetPlayerPerkBuildingClassCityHPChange( perkID, buildingClassID )
				maintenanceCost = maintenanceCost + Game.GetPlayerPerkBuildingClassEnergyMaintenanceChange( perkID, buildingClassID )
			end
			if healthChange ~=0 then
				insert( tips, healthChange .. "[ICON_HEALTH_1]" )
			end
--			if healthModifier~=0 then insert( tips, L( "TXT_KEY_STAT_POSITIVE_YIELD_MOD", "[ICON_HEALTH_1]", healthModifier ) ) end
		end
		local buildingYieldRate, buildingYieldPerPop, buildingYieldModifier, cityYieldRate, cityYieldRateModifier, isProducing, yieldInfo
		for yieldID = 0, YieldTypes.NUM_YIELD_TYPES-1 do
			yieldInfo = GameInfo.Yields[yieldID]
			if yieldInfo then
				isProducing = isNotResistance
				thisBuildingAndYieldTypes.YieldType = yieldInfo.Type or -1
				-- Yield changes from the building
				buildingYieldRate = Game.GetBuildingYieldChange( buildingID, yieldID )
							+ (not IsCiv5vanilla and cityOwner:GetPlayerBuildingClassYieldChange( buildingClassID, yieldID )
								+ city:GetReligionBuildingClassYieldChange( buildingClassID, yieldID ) or 0)
							+ (IsCiv5BNW and city:GetLeagueBuildingClassYieldChange( buildingClassID, yieldID ) or 0)
				-- Yield modifiers from the building
				buildingYieldModifier = Game.GetBuildingYieldModifier( buildingID, yieldID )
							+ cityOwner:GetPolicyBuildingClassYieldModifier( buildingClassID, yieldID )
				-- Effect of player perks
				if IsCivBE then
					for _, perkID in ipairs(cityOwnerPerks) do
						buildingYieldRate = buildingYieldRate + Game.GetPlayerPerkBuildingClassFlatYieldChange( perkID, buildingClassID, yieldID )
						buildingYieldModifier = buildingYieldModifier + Game.GetPlayerPerkBuildingClassPercentYieldChange( perkID, buildingClassID, yieldID )
					end
				end
				-- Specialists yield
				if specialist then
					buildingYieldRate = buildingYieldRate + numSpecialistsInBuilding * city:GetSpecialistYield( specialist.ID, yieldID )
				end
				cityYieldRateModifier = city:GetBaseYieldRateModifier( yieldID )
				cityYieldRate = city:GetYieldPerPopTimes100( yieldID ) * population / 100 + city:GetBaseYieldRate( yieldID )
				-- Special culture case
				if yieldID == YieldTypes.YIELD_CULTURE then
					buildingYieldRate = buildingYieldRate + buildingCultureRate
					buildingYieldModifier = buildingYieldModifier + buildingCultureModifier
					cityYieldRateModifier = cityYieldRateModifier + cityCultureRateModifier
					cityYieldRate = cityYieldRate + cityCultureRate
					buildingCultureRate = 0
					buildingCultureModifier = 0
				elseif yieldID == YieldTypes.YIELD_FOOD then
					local foodPerPop = GameDefines.FOOD_CONSUMPTION_PER_POPULATION
					local foodConsumed = city:FoodConsumption()
					buildingYieldRate = buildingYieldRate + (foodConsumed < foodPerPop * population and foodPerPop * numSpecialistsInBuilding / 2 or 0)
					buildingYieldModifier = buildingYieldModifier + (tonumber(building.FoodKept) or 0)
					cityYieldRate = city:FoodDifferenceTimes100() / 100 -- cityYieldRate - foodConsumed
					cityYieldRateModifier = cityYieldRateModifier + city:GetMaxFoodKeptPercent()
					isProducing = true
				end
				-- Population yield
				buildingYieldPerPop = 0
				for row in GameInfo.Building_YieldChangesPerPop( thisBuildingAndYieldTypes ) do
					buildingYieldPerPop = buildingYieldPerPop + (row.Yield or 0)
				end
				buildingYieldRate = buildingYieldRate + buildingYieldPerPop * population / 100

				buildingYieldRate = buildingYieldRate * cityYieldRateModifier + ( cityYieldRate - buildingYieldRate ) * buildingYieldModifier
				if isProducing and buildingYieldRate ~= 0 then
					insert( tips, buildingYieldRate / 100 .. yieldInfo.IconString )
				end
			end
		end

		-- Culture leftovers
		buildingCultureRate = buildingCultureRate * (100+cityCultureRateModifier) + ( cityCultureRate - buildingCultureRate ) * buildingCultureModifier
		if isNotResistance and buildingCultureRate ~=0 then
			insert( tips, buildingCultureRate / 100 .. "[ICON_CULTURE]" )
		end

-- TODO TOURISM
		if IsCiv5BNW then
			local tourism = ( ( (building.FaithCost or 0) > 0
					and building.UnlockedByBelief
					and building.Cost == -1
					and city and city:GetFaithBuildingTourism()
					) or 0 )
--			local enhancedYieldTechID = GameInfoTypes[ building.EnhancedYieldTech ]
			tourism = tourism + (tonumber(building.TechEnhancedTourism) or 0)
			if tourism ~= 0 then
				insert( tips, tourism.."[ICON_TOURISM]" )
			end
		end

		if IsCiv5 and building.IsReligious then
			buildingName = L( "TXT_KEY_RELIGIOUS_BUILDING", buildingName, Players[city:GetOwner()]:GetStateReligionKey() )
		end
		if city:GetNumFreeBuilding( buildingID ) > 0 then
			buildingName = buildingName .. " (" .. L"TXT_KEY_FREE" .. ")"
		elseif maintenanceCost ~=0 then
			insert( tips, -maintenanceCost .. g_currencyIcon )
		end
		instance.Name:SetText( buildingName )

		if defenseChange ~=0 then
			insert( tips, defenseChange / 100 .. "[ICON_STRENGTH]" )
		end
		if hitPointChange ~= 0 then
			insert( tips, L( "TXT_KEY_PEDIA_DEFENSE_HITPOINTS", hitPointChange ) )
		end

		instance.Label:ChangeParent( instance.Stack )
		instance.Label:SetText( concat( tips, " ") )
		slotStack:CalculateSize()
		if slotStack:GetSizeX() + instance.Label:GetSizeX() < 254 then
			instance.Label:ChangeParent( slotStack )
		end
		instance.Stack:CalculateSize()
--		slotStack:ReprocessAnchoring()
--		instance.Stack:ReprocessAnchoring()
		buildingButton:SetSizeY( max(64, instance.Stack:GetSizeY() + 16) )
	end
	return buildingIM.Commit()
end

--==========================================================
-- Production Selection List Management
--==========================================================

local function SelectionPurchase( orderID, itemID, yieldID, soundKey )
	local city = GetHeadSelectedCity()
	if city then
		local cityOwnerID = city:GetOwner()
		if cityOwnerID == g_activePlayerID
			and ( not city:IsPuppet() or ( IsCiv5BNW and g_activePlayer:MayNotAnnex() ) )
							----------- Venice exception -----------
		then
			local cityID = city:GetID()
			local isPurchase
			if orderID == ORDER_TRAIN then
				if cityIsCanPurchase( city, true, true, itemID, -1, -1, yieldID ) then
					Game.CityPurchaseUnit( city, itemID, yieldID )
					isPurchase = true
				end
			elseif orderID == ORDER_CONSTRUCT then
				if cityIsCanPurchase( city, true, true, -1, itemID, -1, yieldID ) then
					Game.CityPurchaseBuilding( city, itemID, yieldID )
					Network.SendUpdateCityCitizens( cityID )
					isPurchase = true
				end
			elseif orderID == ORDER_CREATE then
				if cityIsCanPurchase( city, true, true, -1, -1, itemID, yieldID ) then
					Game.CityPurchaseProject( city, itemID, yieldID )
					isPurchase = true
				end
			end
			if isPurchase then
				Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_BANNER )
				Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION )
				if soundKey then
					Events.AudioPlay2DSound( soundKey )
				end
			end
		end
	end
end

local function AddSelectionItem( city, item,
				selectionList,
				orderID,
				cityCanProduce,
				unitID, buildingID, projectID,
				cityGetProductionTurnsLeft,
				cityGetGoldCost,
				cityGetFaithCost )

	local itemID = item.ID
	local name = item._Name
	local turnsLeft = not g_isViewingMode and cityCanProduce( city, itemID, 0, 1 )	-- 0 = /continue, 1 = testvisible, nil = /ignore cost
	local canProduce = not g_isViewingMode and cityCanProduce( city, itemID )	-- nil = /continue, nil = /testvisible, nil = /ignore cost
	local canBuyWithGold, goldCost, canBuyWithFaith, faithCost
	if unitID then
		if IsCivBE then
			local bestUpgradeInfo = GameInfo.UnitUpgrades[ g_activePlayer:GetBestUnitUpgrade(unitID) ]
			name = bestUpgradeInfo and bestUpgradeInfo._Name or name
		end
		if cityGetGoldCost then
			canBuyWithGold = cityIsCanPurchase( city, true, true, unitID, buildingID, projectID, g_yieldCurrency )
			goldCost = cityIsCanPurchase( city, false, false, unitID, buildingID, projectID, g_yieldCurrency )
					and cityGetGoldCost( city, itemID )
		end
		if cityGetFaithCost then
			canBuyWithFaith = cityIsCanPurchase( city, true, true, unitID, buildingID, projectID, YieldTypes.YIELD_FAITH )
			faithCost = cityIsCanPurchase( city, false, false, unitID, buildingID, projectID, YieldTypes.YIELD_FAITH )
					and cityGetFaithCost( city, itemID, true )
		end
	end
	if turnsLeft or goldCost or faithCost then --or (g_isDebugMode and not city:IsHasBuilding(buildingID)) then
		turnsLeft = turnsLeft and ( cityGetProductionTurnsLeft and cityGetProductionTurnsLeft( city, itemID ) or -1 )
		return insert( selectionList, { item, orderID, name, turnsLeft, canProduce, goldCost, canBuyWithGold, faithCost, canBuyWithFaith } )
	end
end

local function SortSelectionList(a,b)
	return a[3]<b[3]
end

local g_SelectionListCallBacks = {
	Button = {
		[eLClick] = function( orderID, itemID )
			local city = GetSelectedModifiableCity()
			if city then
				local cityOwnerID = city:GetOwner()
				if cityOwnerID == g_activePlayerID and not city:IsPuppet() then
					-- cityPushOrder( city, orderID, itemID, bAlt, bShift, bCtrl )
					-- cityPushOrder( city, orderID, itemID, repeatBuild, replaceQueue, bottomOfQueue )
					Game.CityPushOrder( city, orderID, itemID, UI.AltKeyDown(), UI.ShiftKeyDown(), not UI.CtrlKeyDown() )
					Events.SpecificCityInfoDirty( cityOwnerID, city:GetID(), CityUpdateTypes.CITY_UPDATE_TYPE_BANNER )
					Events.SpecificCityInfoDirty( cityOwnerID, city:GetID(), CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION )
					if g_isButtonPopupChooseProduction then
						-- is there another city without production order ?
						for cityX in g_activePlayer:Cities() do
							if cityX ~= city and not cityX:IsPuppet() and cityX:GetOrderQueueLength() < 1 then
								UI.SelectCity( cityX )
								return UI.LookAtSelectionPlot()
							end
						end
						-- all cities are producing...
						return ExitCityScreen()
					end
				end
			end
		end,
		[eRClick] = SelectionPedia,
	},
	GoldButton = {
		[eLClick] = function( orderID, itemID )
			return SelectionPurchase( orderID, itemID, g_yieldCurrency, "AS2D_INTERFACE_CITY_SCREEN_PURCHASE" )
		end,
	},
	FaithButton = {
		[eLClick] = function( orderID, itemID )
			return SelectionPurchase( orderID, itemID, YieldTypes.YIELD_FAITH, "AS2D_INTERFACE_FAITH_PURCHASE" )
		end,
	},
}
local g_SelectionListTooltips = {
	Button = function( control )
		return CityOrderItemTooltip( GetHeadSelectedCity(), true, false, control:GetVoid1(), control:GetVoid2() )
	end,
	GoldButton = function( control )
		return CityOrderItemTooltip( GetHeadSelectedCity(), control:IsDisabled(), g_yieldCurrency, control:GetVoid1(), control:GetVoid2() )
	end,
	FaithButton = function( control )
		return CityOrderItemTooltip( GetHeadSelectedCity(), control:IsDisabled(), YieldTypes.YIELD_FAITH, control:GetVoid1(), control:GetVoid2() )
	end,
}

local function SetupSelectionList( itemList, selectionIM, cityOwnerID, getUnitPortraitIcon )
	sort( itemList, SortSelectionList )
	selectionIM:ResetInstances()
	local cash = g_activePlayer:GetGold()
	local faith = not IsCiv5vanilla and g_activePlayer:GetFaith() or 0
	for i = 1, #itemList do
		local item, orderID, itemDescription, turnsLeft, canProduce, goldCost, canBuyWithGold, faithCost, canBuyWithFaith = unpack( itemList[i] )
		local itemID = item.ID
		local avisorRecommended = g_isAdvisor and g_avisorRecommended[ orderID ]

		local instance, new = selectionIM:GetInstance()
		if new then
			SetupCallbacks( instance, g_SelectionListTooltips, "EUI_ItemTooltip", g_SelectionListCallBacks )
		end
		instance.DisabledProduction:SetHide( canProduce or not(canBuyWithGold or canBuyWithFaith) )
		instance.Disabled:SetHide( canProduce or canBuyWithGold or canBuyWithFaith )
		if getUnitPortraitIcon then
			local iconIndex, iconAtlas = getUnitPortraitIcon( itemID, cityOwnerID )
			IconHookup( iconIndex, 45, iconAtlas, instance.Portrait )
		else
			IconHookup( item.PortraitIndex, 45, item.IconAtlas, instance.Portrait )
		end
		instance.Name:SetText( itemDescription )
		if not turnsLeft then
		elseif turnsLeft > -1 and turnsLeft <= 999 then
			instance.Turns:LocalizeAndSetText( "TXT_KEY_STR_TURNS", turnsLeft )
		else
			instance.Turns:LocalizeAndSetText( "TXT_KEY_PRODUCTION_HELP_INFINITE_TURNS" )
		end
		instance.Turns:SetHide( not turnsLeft )
		instance.Button:SetVoids( orderID, itemID )

		instance.GoldButton:SetHide( not goldCost )
		if goldCost then
			instance.GoldButton:SetDisabled( not canBuyWithGold )
			instance.GoldButton:SetAlpha( canBuyWithGold and 1 or 0.5 )
			instance.GoldButton:SetVoids( orderID, itemID )
			instance.GoldButton:SetText( (cash>=goldCost and goldCost or "[COLOR_WARNING_TEXT]"..(goldCost-cash).."[ENDCOLOR]") .. g_currencyIcon )
		end
		instance.FaithButton:SetHide( not faithCost )
		if faithCost then
			instance.FaithButton:SetDisabled( not canBuyWithFaith )
			instance.FaithButton:SetAlpha( canBuyWithFaith and 1 or 0.5 )
			instance.FaithButton:SetVoids( orderID, itemID )
			instance.FaithButton:SetText( (faith>=faithCost and faithCost or "[COLOR_WARNING_TEXT]"..(faithCost-faith).."[ENDCOLOR]") .. "[ICON_PEACE]" )
		end

		for advisorID, advisorName in pairs(g_advisors) do
			local advisorControl = instance[ advisorName ]
			if advisorControl then
				advisorControl:SetHide( not (avisorRecommended and avisorRecommended( itemID, advisorID )) )
			end
		end
	end
	return selectionIM.Commit()
end

--==========================================================
-- Production Queue Managemeent
--==========================================================
local function RemoveQueueItem( queuedItemNumber )
	local city = GetSelectedModifiableCity()
	if city then
		local queueLength = city:GetOrderQueueLength()
		if city:GetOwner() == g_activePlayerID and queueLength > queuedItemNumber then
			Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_POP_ORDER, queuedItemNumber )
			if queueLength < 2 then
				local strTooltip = L( "TXT_KEY_NOTIFICATION_NEW_CONSTRUCTION", city:GetNameKey() )
				g_activePlayer:AddNotification( NotificationTypes.NOTIFICATION_PRODUCTION, strTooltip, strTooltip, city:GetX(), city:GetY(), -1, -1 )
			end
		end
	end
end

local function SwapQueueItem( queuedItemNumber )
	if g_queuedItemNumber and Controls.QueueSlider:IsTrackingLeftMouseButton() then
		local a = g_queuedItemNumber
		local b = queuedItemNumber
		if a>b then a, b = b, a end
		for i=a, b-1 do
			Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_SWAP_ORDER, i )
		end
		for i=b-2, a, -1 do
			Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_SWAP_ORDER, i )
		end
	end
	g_queuedItemNumber = queuedItemNumber or g_queuedItemNumber
end

Controls.AutomateProduction:RegisterCheckHandler( function( isChecked )
	Game.SelectedCitiesGameNetMessage( GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_SET_AUTOMATED_PRODUCTION, -1, -1, isChecked, false )
--	Network.SendDoTask( city:GetID(), TaskTypes.TASK_SET_AUTOMATED_PRODUCTION, -1, -1, isChecked, false )
end)

--==========================================================
-- Update Production Queue
--==========================================================
local function UpdateCityProductionQueue( city, cityID, cityOwnerID, isVeniceException )
	local queueLength = city:GetOrderQueueLength()
	local currentProductionPerTurnTimes100 = city:GetCurrentProductionDifferenceTimes100( false, false )	-- bIgnoreFood, bOverflow
	local isGeneratingProduction = ( currentProductionPerTurnTimes100 > 0 ) and not ( city.IsProductionProcess and city:IsProductionProcess() )
	local isMaintain = false
	local isQueueEmpty = queueLength < 1
	Controls.ProductionFinished:SetHide( true )

	-- Progress info for meter
	ShowProgress( g_portraitSize, Controls.PQlossMeter, Controls.PQprogressMeter, Controls.PQline1, Controls.PQlabel1, Controls.PQline2, Controls.PQlabel2,
		isGeneratingProduction and not isQueueEmpty and city:GetProductionTurnsLeft(),
		city:GetProductionNeeded() * 100,
		city:GetProductionTimes100() + city:GetCurrentProductionDifferenceTimes100( false, true ) - currentProductionPerTurnTimes100,	-- bIgnoreFood, bOverflow
		currentProductionPerTurnTimes100 )

	Controls.ProdPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", currentProductionPerTurnTimes100 / 100 )

	Controls.ProductionPortraitButton:SetHide( false )

	g_ProdQueueIM:ResetInstances()
	local queueItems = {}

	for queuedItemNumber = 0, max( queueLength-1, 0 ) do

		local orderID, itemID, _, isRepeat, isReallyRepeat
		if isQueueEmpty then
			local item = g_finishedItems[ cityID ]
			if item then
				orderID, itemID = unpack( item )
				Controls.ProductionFinished:SetHide( false )
			end
		else
			orderID, itemID, _, isRepeat = city:GetOrderFromQueue( queuedItemNumber )
			queueItems[ orderID / 64 + itemID ] = true
		end
		local instance, portraitSize
		if queuedItemNumber == 0 then
			instance = Controls
			portraitSize = g_portraitSize
		else
			portraitSize = 45
			instance = g_ProdQueueIM:GetInstance()
			instance.PQdisabled:SetHide( not isMaintain )
		end
		instance.PQbox:SetVoid1( queuedItemNumber )
		instance.PQbox:RegisterCallback( eMouseEnter, SwapQueueItem )
		instance.PQbox:RegisterCallback( eRClick, ProductionPedia )
		instance.PQbox:SetToolTipCallback( ProductionToolTip )

		instance.PQremove:SetHide( isQueueEmpty or g_isViewingMode )
		instance.PQremove:SetVoid1( queuedItemNumber )
		instance.PQremove:RegisterCallback( eLClick, RemoveQueueItem )

		local itemInfo, turnsRemaining, portraitOffset, portraitAtlas

		if orderID == ORDER_TRAIN then
			itemInfo = GameInfo.Units
			turnsRemaining = city:GetUnitProductionTurnsLeft( itemID, queuedItemNumber )
			portraitOffset, portraitAtlas = GetUnitPortraitIcon( itemID, cityOwnerID )
			isReallyRepeat = isRepeat
		elseif orderID == ORDER_CONSTRUCT then
			itemInfo = GameInfo.Buildings
			turnsRemaining = city:GetBuildingProductionTurnsLeft( itemID, queuedItemNumber )
		elseif orderID == ORDER_CREATE then
			itemInfo = GameInfo.Projects
			turnsRemaining = city:GetProjectProductionTurnsLeft( itemID, queuedItemNumber )
		elseif orderID == ORDER_MAINTAIN then
			itemInfo = GameInfo.Processes
			isMaintain = true
			isReallyRepeat = true
		end
		if itemInfo then
			local item = itemInfo[itemID]
			itemInfo = IconHookup( portraitOffset or item.PortraitIndex, portraitSize, portraitAtlas or item.IconAtlas, instance.PQportrait )
			instance.PQname:SetText( item._Name )
			if isMaintain or isQueueEmpty then
			elseif isGeneratingProduction then
				instance.PQturns:LocalizeAndSetText( "TXT_KEY_PRODUCTION_HELP_NUM_TURNS", turnsRemaining )
			else
				instance.PQturns:LocalizeAndSetText( "TXT_KEY_PRODUCTION_HELP_INFINITE_TURNS" )
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
			instance.PQrank:SetText( not isMaintain and queueLength > 1 and (queuedItemNumber+1).."." )
		end
	end

	g_ProdQueueIM.Commit()

	-------------------------------------------
	-- Update Selection List
	-------------------------------------------

	local isSelectionList = not g_isViewingMode or isVeniceException or g_isDebugMode
	Controls.SelectionScrollPanel:SetHide( not isSelectionList )
	if isSelectionList then
		local unitSelectList = {}
		local buildingSelectList = {}
		local wonderSelectList = {}
		local processSelectList = {}

		if g_isAdvisor then
			Game.SetAdvisorRecommenderCity( city )
		end
		-- Buildings & Wonders
		local orderID = ORDER_CONSTRUCT
		local code = orderID / 64
		for item in GameInfo.Buildings() do
			local buildingClass = GameInfo.BuildingClasses[item.BuildingClass]
			local isWonder = buildingClass and (buildingClass.MaxGlobalInstances > 0 or buildingClass.MaxPlayerInstances == 1 or buildingClass.MaxTeamInstances > 0)
			if not queueItems[ code + item.ID ] then
				AddSelectionItem( city, item,
						isWonder and wonderSelectList or buildingSelectList,
						orderID,
						city.CanConstruct,
						-1, item.ID, -1,
						city.GetBuildingProductionTurnsLeft,
						city.GetBuildingPurchaseCost,
						city.GetBuildingFaithPurchaseCost )
			end
		end

		-- Units
		orderID = ORDER_TRAIN
		for item in GameInfo.Units() do
			AddSelectionItem( city, item,
						unitSelectList,
						orderID,
						city.CanTrain,
						item.ID, -1, -1,
						city.GetUnitProductionTurnsLeft,
						city.GetUnitPurchaseCost,
						city.GetUnitFaithPurchaseCost )
		end
		-- Projects
		orderID = ORDER_CREATE
		code = orderID / 64
		for item in GameInfo.Projects() do
			if not queueItems[ code + item.ID ] then
				AddSelectionItem( city, item,
						wonderSelectList,
						orderID,
						city.CanCreate,
						-1, -1, item.ID,
						city.GetProjectProductionTurnsLeft,
						city.GetProjectPurchaseCost,
						city.GetProjectFaithPurchaseCost )	-- nil
			end
		end
		-- Processes
		orderID = ORDER_MAINTAIN
		code = orderID / 64
		for item in GameInfo.Processes() do
			if not queueItems[ code + item.ID ] then
				AddSelectionItem( city, item,
						processSelectList,
						orderID,
						city.CanMaintain )
			end
		end

		SetupSelectionList( unitSelectList, g_UnitSelectIM, cityOwnerID, GetUnitPortraitIcon )
		SetupSelectionList( buildingSelectList, g_BuildingSelectIM )
		SetupSelectionList( wonderSelectList, g_WonderSelectIM )
		SetupSelectionList( processSelectList, g_ProcessSelectIM )

	end
	return ResizeProdQueue()
end

--==========================================================
-- City Hex Clicking & Mousing
--==========================================================

local function PlotButtonClicked( plotIndex )
	local city = GetSelectedModifiableCity()
	local plot = city and city:GetCityIndexPlot( plotIndex )
	if plot then
		local outside = city ~= plot:GetWorkingCity()
		-- calling this with the city center (0 in the third param) causes it to reset all forced tiles
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
		local plotX = plot:GetX()
		local plotY = plot:GetY()
		Network.SendCityBuyPlot(city:GetID(), plotX, plotY)
		Network.SendUpdateCityCitizens( city:GetID() )
		UI.UpdateCityScreen()
		Events.AudioPlay2DSound("AS2D_INTERFACE_BUY_TILE")
	end
	return true
end

--==========================================================
-- Update City Hexes
--==========================================================

local function UpdateCityWorkingHexes( city )

	EventsClearHexHighlightStyle( "HexContour" )
	EventsClearHexHighlightStyle( "WorkedFill" )
	EventsClearHexHighlightStyle( "WorkedOutline" )
	EventsClearHexHighlightStyle( "OverlapFill" )
	EventsClearHexHighlightStyle( "OverlapOutline" )
	EventsClearHexHighlightStyle( "VacantFill" )
	EventsClearHexHighlightStyle( "VacantOutline" )
	EventsClearHexHighlightStyle( "EnemyFill" )
	EventsClearHexHighlightStyle( "EnemyOutline" )
	EventsClearHexHighlightStyle( "BuyFill" )
	EventsClearHexHighlightStyle( "BuyOutline" )

	g_PlotButtonIM:ResetInstances()
	g_BuyPlotButtonIM:ResetInstances()

	-- Show plots that will be acquired by culture
	local purchasablePlots = {city:GetBuyablePlotList()}
	for i = 1, #purchasablePlots do
		local plot = purchasablePlots[i]
		EventsSerialEventHexHighlight( ToHexFromGrid{ x=plot:GetX(), y=plot:GetY() }, true, ColorCulture, "HexContour" )
		purchasablePlots[ plot ] = true
	end


	local cityArea = city:GetNumCityPlots() - 1
	EventsRequestYieldDisplay( YieldDisplayTypesAREA, HexRadius( cityArea ), city:GetX(), city:GetY() )

	-- display worked plots buttons
	local cityOwnerID = city:GetOwner()
	local notInStrategicView = not InStrategicView()
	local showButtons = g_workerHeadingOpen and not g_isViewingMode

	for cityPlotIndex = 0, cityArea do
		local plot = city:GetCityIndexPlot( cityPlotIndex )

		if plot and plot:GetOwner() == cityOwnerID then

			local hexPos = ToHexFromGrid{ x=plot:GetX(), y=plot:GetY() }
			local worldPos = HexToWorld( hexPos )
			local iconID, tipKey
			if city:IsWorkingPlot( plot ) then

				-- The city itself
				if cityPlotIndex == 0 then
					iconID = 11
					tipKey = "TXT_KEY_CITYVIEW_CITY_CENTER"

				-- FORCED worked plot
				elseif city:IsForcedWorkingPlot( plot ) then
					iconID = 10
					tipKey = "TXT_KEY_CITYVIEW_FORCED_WORK_TILE"

				-- AI-picked worked plot
				else
					iconID = 0
					tipKey = "TXT_KEY_CITYVIEW_GUVNA_WORK_TILE"
				end
				if notInStrategicView then
					EventsSerialEventHexHighlight( hexPos , true, nil, "WorkedFill" )
					EventsSerialEventHexHighlight( hexPos , true, nil, "WorkedOutline" )
				end
			else
				local workingCity = plot:GetWorkingCity()
				-- worked by another one of our Cities
				if workingCity:IsWorkingPlot( plot ) then
					iconID = 12
					tipKey = "TXT_KEY_CITYVIEW_NUTHA_CITY_TILE"

				-- Workable plot
				elseif workingCity:CanWork( plot ) then
					iconID = 9
					tipKey = "TXT_KEY_CITYVIEW_UNWORKED_CITY_TILE"

				-- Blockaded water plot
				elseif plot:IsWater() and city:IsPlotBlockaded( plot ) then
					iconID = 13
					tipKey = "TXT_KEY_CITYVIEW_BLOCKADED_CITY_TILE"
					cityPlotIndex = nil

				-- Enemy Unit standing here
				elseif plot:IsVisibleEnemyUnit( cityOwnerID ) then
					iconID = 13
					tipKey = "TXT_KEY_CITYVIEW_ENEMY_UNIT_CITY_TILE"
					cityPlotIndex = nil
				end
				if notInStrategicView then
					if workingCity ~= city then
						EventsSerialEventHexHighlight( hexPos , true, nil, "OverlapFill" )
						EventsSerialEventHexHighlight( hexPos , true, nil, "OverlapOutline" )
					elseif cityPlotIndex then
						EventsSerialEventHexHighlight( hexPos , true, nil, "VacantFill" )
						EventsSerialEventHexHighlight( hexPos , true, nil, "VacantOutline" )
					else
						EventsSerialEventHexHighlight( hexPos , true, nil, "EnemyFill" )
						EventsSerialEventHexHighlight( hexPos , true, nil, "EnemyOutline" )
					end
				end
			end
			if iconID and showButtons then
				local instance = g_PlotButtonIM:GetInstance()
				instance.PlotButtonAnchor:SetWorldPositionVal( worldPos.x + g_worldPositionOffset.x, worldPos.y + g_worldPositionOffset.y, worldPos.z + g_worldPositionOffset.z ) --todo: improve code
				instance.PlotButtonImage:LocalizeAndSetToolTip( tipKey )
				IconHookup( iconID, 45, "CITIZEN_ATLAS", instance.PlotButtonImage )
				local button = instance.PlotButtonImage
				if not cityPlotIndex or g_isViewingMode then
					button:ClearCallback( eLClick )
				else
					button:SetVoid1( cityPlotIndex )
					button:RegisterCallback( eLClick, PlotButtonClicked )
				end
			end
		end
	end --loop

	-- display buy plot buttons
	if g_BuyPlotMode and not g_isViewingMode then
		local cash = g_activePlayer:GetGold()
		for cityPlotIndex = 0, cityArea do
			local plot = city:GetCityIndexPlot( cityPlotIndex )
			if plot then
				local x = plot:GetX()
				local y = plot:GetY()
				local hexPos = ToHexFromGrid{ x=x, y=y }
				local worldPos = HexToWorld( hexPos )
				if city:CanBuyPlotAt( x, y, true ) then
					local instance = g_BuyPlotButtonIM:GetInstance()
					local button = instance.BuyPlotAnchoredButton
					instance.BuyPlotButtonAnchor:SetWorldPositionVal( worldPos.x + g_worldPositionOffset2.x, worldPos.y + g_worldPositionOffset2.y, worldPos.z + g_worldPositionOffset2.z ) --todo: improve code
					local plotCost = city:GetBuyPlotCost( x, y )
					local tip, txt, alpha
					local canBuy = city:CanBuyPlotAt( x, y, false )
					if canBuy then
						tip = L( "TXT_KEY_CITYVIEW_CLAIM_NEW_LAND", plotCost )
						txt = plotCost
						alpha = 1
						button:SetVoid1( cityPlotIndex )
						button:RegisterCallback( eLClick, BuyPlotAnchorButtonClicked )
						if notInStrategicView then
							EventsSerialEventHexHighlight( hexPos , true, nil, "BuyFill" )
							if not purchasablePlots[ plot ] then
								EventsSerialEventHexHighlight( hexPos , true, nil, "BuyOutline" )
							end
						end
					else
						tip = L( "TXT_KEY_CITYVIEW_NEED_MONEY_BUY_TILE", plotCost )
						txt = "[COLOR_WARNING_TEXT]"..(plotCost-cash).."[ENDCOLOR]"
						alpha = 0.5
					end
					button:SetDisabled( not canBuy )
					instance.BuyPlotButtonAnchor:SetAlpha( alpha )
--todo
					button:SetToolTipString( tip )
					instance.BuyPlotAnchoredButtonLabel:SetText( txt )
				end
			end
		end --loop
	end
end

local function UpdateWorkingHexes()
	local city = GetHeadSelectedCity()
	if city and UI.IsCityScreenUp() then
		return UpdateCityWorkingHexes( city )
	end
end

--==========================================================
-- Update City View
--==========================================================

local function UpdateCityView()

	local city = GetHeadSelectedCity()

	if city and UI.IsCityScreenUp() then

		if g_citySpecialists.city ~= city then
			g_citySpecialists = { city = city }
		end
--[[
		if g_previousCity ~= city then
			g_previousCity = city
			EventsClearHexHighlightStyle("CityLimits")
			if not InStrategicView() then
				for cityPlotIndex = 0, city:GetNumCityPlots() - 1 do
					local plot = city:GetCityIndexPlot( cityPlotIndex )
					if plot then
						local hexPos = ToHexFromGrid{ x=plot:GetX(), y=plot:GetY() }
						EventsSerialEventHexHighlight( hexPos , true, nil, "CityLimits" )
					end
				end
			end
		end
--]]
		local cityID = city:GetID()
		local cityOwnerID = city:GetOwner()
		local cityOwner = Players[cityOwnerID]
		local isActivePlayerCity = cityOwnerID == Game.GetActivePlayer()
		local isCityCaptureViewingMode = UI.IsPopupTypeOpen(ButtonPopupTypes.BUTTONPOPUP_CITY_CAPTURED)
		g_isDebugMode = Game.IsDebugMode()
		g_isViewingMode = city:IsPuppet() or not isActivePlayerCity or isCityCaptureViewingMode

		if IsCiv5 then
			-- Auto Specialist checkbox
			local isNoAutoAssignSpecialists = city:IsNoAutoAssignSpecialists()
			Controls.NoAutoSpecialistCheckbox:SetCheck( isNoAutoAssignSpecialists )
			Controls.NoAutoSpecialistCheckbox:SetDisabled( g_isViewingMode )
			if IsCiv5BNW then
				Controls.TourismPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", city:GetBaseTourism() )
				Controls.NoAutoSpecialistCheckbox2:SetCheck( isNoAutoAssignSpecialists )
				Controls.NoAutoSpecialistCheckbox2:SetDisabled( g_isViewingMode )
			end
		end
		Controls.AutomateProduction:SetCheck( city:IsProductionAutomated() )
		Controls.AutomateProduction:SetDisabled( g_isViewingMode )
		
		-- MOD - TOKATA
		local bCityLevel = nil;
		local bCityHall  = nil;
		local iCityLevel = -2
		-- MOD - TOKATA END

		-------------------------------------------
		-- City Banner
		-------------------------------------------

		local isCapital = city:IsCapital()
		Controls.CityCapitalIcon:SetHide( not isCapital )

		Controls.CityIsConnected:SetHide( isCapital or city:IsBlockaded() or not cityOwner:IsCapitalConnectedToCity(city) or city:GetTeam() ~= Game.GetActiveTeam() )

		Controls.CityIsBlockaded:SetHide( not city:IsBlockaded() )

		if city:IsRazing() then
			Controls.CityIsRazing:SetHide(false)
			Controls.CityIsRazing:LocalizeAndSetToolTip("TXT_KEY_CITY_BURNING", city:GetRazingTurns())
		else
			Controls.CityIsRazing:SetHide(true)
		end

		Controls.CityIsPuppet:SetHide( not city:IsPuppet() )

		if city:IsResistance() then
			Controls.CityIsResistance:SetHide(false)
			Controls.CityIsResistance:LocalizeAndSetToolTip("TXT_KEY_CITY_RESISTANCE", city:GetResistanceTurns())
		else
			Controls.CityIsResistance:SetHide(true)
		end

--todo BE
		Controls.CityIsOccupied:SetHide( not( IsCiv5 and city:IsOccupied() and not city:IsNoOccupiedUnhappiness() ) )

		local cityName = Locale.ToUpper( city:GetName() )

		if city:IsRazing() then
			cityName = cityName .. " (" .. L"TXT_KEY_BURNING" .. ")"
		end

		local size = isCapital and Controls.CityCapitalIcon:GetSizeX() or 0
		Controls.CityNameTitleBarLabel:SetOffsetX( size / 2 )
		TruncateString( Controls.CityNameTitleBarLabel, abs(Controls.NextCityButton:GetOffsetX()) * 2 - Controls.NextCityButton:GetSizeX() - size, cityName )

		Controls.Defense:SetText( floor( city:GetStrengthValue() / 100 ) )

 		CivIconHookup( cityOwnerID, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true )

		-------------------------------------------
		-- City Damage
		-------------------------------------------

		local cityDamage = city:GetDamage()
		if cityDamage > 0 then
			local cityHealthPercent = 1 - cityDamage / ( not IsCiv5vanilla and city:GetMaxHitPoints() or GameDefines.MAX_CITY_HIT_POINTS )

			Controls.HealthMeter:SetPercent( cityHealthPercent )
			if cityHealthPercent > 0.66 then
				Controls.HealthMeter:SetTexture("CityNamePanelHealthBarGreen.dds")
			elseif cityHealthPercent > 0.33 then
				Controls.HealthMeter:SetTexture("CityNamePanelHealthBarYellow.dds")
			else
				Controls.HealthMeter:SetTexture("CityNamePanelHealthBarRed.dds")
			end
			Controls.HealthFrame:SetHide( false )
		else
			Controls.HealthFrame:SetHide( true )
		end

		-------------------------------------------
		-- Growth Meter
		-------------------------------------------

		local cityPopulation = floor( city:GetPopulation() )
		Controls.CityPopulationLabel:SetText( cityPopulation )
		Controls.PeopleMeter:SetPercent( city:GetFood() / city:GrowthThreshold() )

		--Update suffix to use correct plurality.
		Controls.CityPopulationLabelSuffix:LocalizeAndSetText( "TXT_KEY_CITYVIEW_CITIZENS_TEXT", cityPopulation )


		-------------------------------------------
		-- Citizen Focus & Slackers
		-------------------------------------------

		Controls.AvoidGrowthButton:SetCheck( city:IsForcedAvoidGrowth() )

		local slackerCount = city:GetSpecialistCount( GameDefines.DEFAULT_SPECIALIST )

		local focusButton = g_cityFocusButtons[ city:GetFocusType() ]
		if focusButton then
			focusButton:SetCheck( true )
		end

		local doHide = city:GetNumForcedWorkingPlots() < 1 and slackerCount < 1
		Controls.ResetButton:SetHide( doHide )
		Controls.ResetFooter:SetHide( doHide )

		g_SlackerIM:ResetInstances()
		for i = 1, slackerCount do
			local instance = g_SlackerIM:GetInstance()
			local slot = instance.Button
			slot:SetVoids( -1, i )
			slot:SetToolTipCallback( SpecialistTooltip )
			slot:SetTexture( g_slackerTexture )
			if g_isViewingMode then
				slot:ClearCallback( eLClick )
			else
				slot:RegisterCallback( eLClick, OnSlackersSelected )
			end
			slot:RegisterCallback( eRClick, SpecialistPedia )
		end
		g_SlackerIM.Commit()

		-------------------------------------------
		-- Great Person Meters
		-------------------------------------------
		if IsCiv5 then
			g_GreatPeopleIM:ResetInstances()
			for specialist in GameInfo.Specialists() do

				local gpuClass = specialist.GreatPeopleUnitClass	-- nil / UNITCLASS_ARTIST / UNITCLASS_SCIENTIST / UNITCLASS_MERCHANT / UNITCLASS_ENGINEER ...
				local unitClass = GameInfo.UnitClasses[ gpuClass or -1 ]
				if unitClass then
					local gpThreshold = city:GetSpecialistUpgradeThreshold(unitClass.ID)
					local gpProgress = city:GetSpecialistGreatPersonProgressTimes100(specialist.ID) / 100
					local gpChange = specialist.GreatPeopleRateChange * city:GetSpecialistCount( specialist.ID )
					for building in GameInfo.Buildings{SpecialistType = specialist.Type} do
						if city:IsHasBuilding(building.ID) then
							gpChange = gpChange + building.GreatPeopleRateChange
						end
					end

					local gpChangePlayerMod = cityOwner:GetGreatPeopleRateModifier()
					local gpChangeCityMod = city:GetGreatPeopleRateModifier()
					local gpChangePolicyMod = 0
					local gpChangeWorldCongressMod = 0
					local gpChangeGoldenAgeMod = 0
					local isGoldenAge = cityOwner:GetGoldenAgeTurns() > 0

					if IsCiv5BNW then
						-- Generic GP mods

						gpChangePolicyMod = cityOwner:GetPolicyGreatPeopleRateModifier()

						local worldCongress = (Game.GetNumActiveLeagues() > 0) and Game.GetActiveLeague()

						-- GP mods by type
						if specialist.GreatPeopleUnitClass == "UNITCLASS_WRITER" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatWriterRateModifier()
							gpChangePolicyMod = gpChangePolicyMod + cityOwner:GetPolicyGreatWriterRateModifier()
							if worldCongress then
								gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetArtsyGreatPersonRateModifier()
							end
							if isGoldenAge and cityOwner:GetGoldenAgeGreatWriterRateModifier() > 0 then
								gpChangeGoldenAgeMod = gpChangeGoldenAgeMod + cityOwner:GetGoldenAgeGreatWriterRateModifier()
							end
						elseif specialist.GreatPeopleUnitClass == "UNITCLASS_ARTIST" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatArtistRateModifier()
							gpChangePolicyMod = gpChangePolicyMod + cityOwner:GetPolicyGreatArtistRateModifier()
							if worldCongress then
								gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetArtsyGreatPersonRateModifier()
							end
							if isGoldenAge and cityOwner:GetGoldenAgeGreatArtistRateModifier() > 0 then
								gpChangeGoldenAgeMod = gpChangeGoldenAgeMod + cityOwner:GetGoldenAgeGreatArtistRateModifier()
							end
						elseif specialist.GreatPeopleUnitClass == "UNITCLASS_MUSICIAN" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatMusicianRateModifier()
							gpChangePolicyMod = gpChangePolicyMod + cityOwner:GetPolicyGreatMusicianRateModifier()
							if worldCongress then
								gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetArtsyGreatPersonRateModifier()
							end
							if isGoldenAge and cityOwner:GetGoldenAgeGreatMusicianRateModifier() > 0 then
								gpChangeGoldenAgeMod = gpChangeGoldenAgeMod + cityOwner:GetGoldenAgeGreatMusicianRateModifier()
							end
						elseif specialist.GreatPeopleUnitClass == "UNITCLASS_SCIENTIST" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatScientistRateModifier()
							gpChangePolicyMod = gpChangePolicyMod + cityOwner:GetPolicyGreatScientistRateModifier()
							if worldCongress then
								gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetScienceyGreatPersonRateModifier()
							end
						elseif specialist.GreatPeopleUnitClass == "UNITCLASS_MERCHANT" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatMerchantRateModifier()
							gpChangePolicyMod = gpChangePolicyMod + cityOwner:GetPolicyGreatMerchantRateModifier()
							if worldCongress then
								gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetScienceyGreatPersonRateModifier()
							end
						elseif specialist.GreatPeopleUnitClass == "UNITCLASS_ENGINEER" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatEngineerRateModifier()
							gpChangePolicyMod = gpChangePolicyMod + cityOwner:GetPolicyGreatEngineerRateModifier()
							if worldCongress then
								gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetScienceyGreatPersonRateModifier()
							end
						-- Compatibility with Gazebo's City-State Diplomacy Mod (CSD) for Brave New World
						elseif cityOwner.GetGreatDiplomatRateModifier and specialist.GreatPeopleUnitClass == "UNITCLASS_GREAT_DIPLOMAT" then
							gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetGreatDiplomatRateModifier()
						end

						-- Player mod actually includes policy mod and World Congress mod, so separate them for tooltip

						gpChangePlayerMod = gpChangePlayerMod - gpChangePolicyMod - gpChangeWorldCongressMod

					elseif gpuClass == "UNITCLASS_SCIENTIST" then

						gpChangePlayerMod = gpChangePlayerMod + cityOwner:GetTraitGreatScientistRateModifier()

					end

					local gpChangeMod = gpChangePlayerMod + gpChangePolicyMod + gpChangeWorldCongressMod + gpChangeCityMod + gpChangeGoldenAgeMod
					gpChange = (gpChangeMod / 100 + 1) * gpChange

					if gpProgress > 0 or gpChange > 0 then
						local instance = g_GreatPeopleIM:GetInstance()
						local percent = gpProgress / gpThreshold
						instance.GPMeter:SetPercent( percent )
						local labelText = unitClass._Name
						local icon = GreatPeopleIcon(gpuClass)
						local tips = { "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( labelText ) .. "[ENDCOLOR]" .. " " .. gpProgress .. icon .." / " .. gpThreshold .. icon }
	--					insert( tips, L( "TXT_KEY_PROGRESS_TOWARDS", "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( labelText ) .. "[ENDCOLOR]" ) )
						if gpChange > 0 then
							local gpTurns = ceil( (gpThreshold - gpProgress) / gpChange )
							insert( tips, "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", gpTurns ) ) .. "[ENDCOLOR]  "
										 .. gpChange .. icon .. " " .. L"TXT_KEY_GOLD_PERTURN_HEADING4_TITLE" )
							labelText = labelText .. ": " .. Locale.ToLower( L( "TXT_KEY_STR_TURNS", gpTurns ) )
						end
						instance.GreatPersonLabel:SetText( icon .. labelText )
						if IsCiv5vanilla then
							if gpChangeMod ~= 0 then
								insert( tips, "[ICON_BULLET] "..gpChangeMod..icon )
							end
						else
							if gpChangePlayerMod ~= 0 then
								insert( tips, L( "TXT_KEY_PLAYER_GP_MOD", gpChangePlayerMod ) )
							end
							if gpChangePolicyMod ~= 0 then
								insert( tips, L( "TXT_KEY_POLICY_GP_MOD", gpChangePolicyMod ) )
							end
							if gpChangeCityMod ~= 0 then
								insert( tips, L( "TXT_KEY_CITY_GP_MOD", gpChangeCityMod ) )
							end
							if gpChangeGoldenAgeMod ~= 0 then
								insert( tips, L( "TXT_KEY_GOLDENAGE_GP_MOD", gpChangeGoldenAgeMod ) )
							end
							if gpChangeWorldCongressMod < 0 then
								insert( tips, L( "TXT_KEY_WORLD_CONGRESS_NEGATIVE_GP_MOD", gpChangeWorldCongressMod ) )
							elseif gpChangeWorldCongressMod > 0 then
								insert( tips, L( "TXT_KEY_WORLD_CONGRESS_POSITIVE_GP_MOD", gpChangeWorldCongressMod ) )
							end
						end
						instance.GPBox:SetToolTipString( concat( tips, "[NEWLINE]") )
						instance.GPBox:SetVoid1( unitClass.ID )
						instance.GPBox:RegisterCallback( eRClick, UnitClassPedia )

						local portraitOffset, portraitAtlas = GetUnitPortraitIcon( GameInfoTypes[ unitClass.DefaultUnit ], cityOwnerID )
						instance.GPImage:SetHide(not IconHookup( portraitOffset, 64, portraitAtlas, instance.GPImage ) )
					end
				end
			end
			g_GreatPeopleIM.Commit()
		end
		
		--------------------------------
		
		--- SUPERPOWERS
		
		--------------------------------
		
		-------------------------------------------
		--  MOD - City Level By TOKATA
		-------------------------------------------
		if bCityLevel ~= nil then
			IconHookup( bCityLevel.PortraitIndex, 128, bCityLevel.IconAtlas, Controls.CityLevelImage );
			local strToolTip = GetHelpTextForBuilding(bCityLevel.ID, false, false, false, pCity);
			Controls.CityLevelImage:SetToolTipString(strToolTip);
			Controls.CityLevelFrame:SetHide(false);
		else
			Controls.CityLevelFrame:SetHide(true);
		end
		-------------------------------------------
		--  MOD - City Hall
		-------------------------------------------
		if bCityHall ~= nil then
			IconHookup( bCityHall.PortraitIndex, 64, bCityHall.IconAtlas, Controls.CityHallImage );
			local strToolTip = GetHelpTextForBuilding(bCityHall.ID, false, false, false, pCity);
			-- Can we sell this thing?
			if (pCity:IsBuildingSellable(bCityHall.ID) and not pCity:IsPuppet()) then
				strToolTip = strToolTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey( "TXT_KEY_CLICK_TO_SELL" );
				Controls.CityHallButton:RegisterCallback( Mouse.eLClick, OnBuildingClicked );
				Controls.CityHallButton:SetVoid1( bCityHall.ID );
			-- We have to clear the data out here or else the instance manager will recycle it in other cities!
			else
				Controls.CityHallButton:ClearCallback(Mouse.eLClick);
				Controls.CityHallButton:SetVoid1( -1 );
			end
			Controls.CityHallButton:SetToolTipString(strToolTip);
			Controls.CityHallFrame:SetHide(false);
		else
			Controls.CityHallFrame:SetHide(true);
		end
		
		
	-------------------------------------------	MOD By TOKATA ENDCOLOR

		-------------------------------------------
		-- Buildings
		-------------------------------------------

		local greatWorkBuildings = {}
		local specialistBuildings = {}
		local wonders = {}
		local otherBuildings = {}
		local noWondersWithSpecialistInThisCity = true

		for building in GameInfo.Buildings() do
			local buildingID = building.ID
			if city:IsHasBuilding(buildingID) then
				local buildingClass = GameInfo.BuildingClasses[ building.BuildingClass ]
				local buildings
				local greatWorkCount = IsCiv5BNW and building.GreatWorkCount or 0
				local areSpecialistsAllowedByBuilding = city:GetNumSpecialistsAllowedByBuilding(buildingID) > 0

				if buildingClass 
					and ( buildingClass.MaxGlobalInstances > 0
						or buildingClass.MaxTeamInstances > 0
						or ( buildingClass.MaxPlayerInstances == 1 and not areSpecialistsAllowedByBuilding ) )
				then
					buildings = wonders
					if areSpecialistsAllowedByBuilding then
						noWondersWithSpecialistInThisCity = false
					end
				elseif areSpecialistsAllowedByBuilding then
					buildings = specialistBuildings
				elseif greatWorkCount > 0 then
					buildings = greatWorkBuildings
				elseif greatWorkCount == 0 then		-- compatibility with Firaxis code exploit for invisibility
					buildings = otherBuildings
				end
				if buildings then
					insert( buildings, { building, building._Name, greatWorkCount, areSpecialistsAllowedByBuilding and GameInfoTypes[building.SpecialistType] or 999 } )
				end
			end
		end
		local strMaintenanceTT = L( "TXT_KEY_BUILDING_MAINTENANCE_TT", city:GetTotalBaseBuildingMaintenance() )
		Controls.SpecialBuildingsHeader:SetToolTipString(strMaintenanceTT)
		Controls.BuildingsHeader:SetToolTipString(strMaintenanceTT)
		Controls.GreatWorkHeader:SetToolTipString(strMaintenanceTT)
		Controls.SpecialistControlBox:SetHide( #specialistBuildings < 1 )
		Controls.SpecialistControlBox2:SetHide( noWondersWithSpecialistInThisCity )
		g_GreatWorksIM:ResetInstances()
		g_SpecialistsIM:ResetInstances()
		SetupBuildingList( city, specialistBuildings, g_SpecialBuildingsIM )
		SetupBuildingList( city, wonders, g_WondersIM )
		SetupBuildingList( city, greatWorkBuildings, g_GreatWorkIM )
		SetupBuildingList( city, otherBuildings, g_BuildingsIM )
		ResizeRightStack()

		-------------------------------------------
		-- Buying Plots
		-------------------------------------------
--		szText = L"TXT_KEY_CITYVIEW_BUY_TILE"
--		Controls.BuyPlotButton:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_BUY_TILE_TT" )
--		Controls.BuyPlotText:SetText(szText)
--		Controls.BuyPlotButton:SetDisabled( g_isViewingMode or (GameDefines.BUY_PLOTS_DISABLED ~= 0 and city:CanBuyAnyPlot()) )

		-------------------------------------------
		-- Resource Demanded
		-------------------------------------------

		if city:GetResourceDemanded(true) ~= -1 then
			local resourceInfo = GameInfo.Resources[ city:GetResourceDemanded() ]
			local weLoveTheKingDayCounter = city:GetWeLoveTheKingDayCounter()
			if weLoveTheKingDayCounter > 0 then
				Controls.ResourceDemandedString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_WLTKD_COUNTER", weLoveTheKingDayCounter )
				Controls.ResourceDemandedBox:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_RESOURCE_FULFILLED_TT" )
			else
				Controls.ResourceDemandedString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED", (resourceInfo.IconString or"") .. " " .. resourceInfo._Name )
				Controls.ResourceDemandedBox:LocalizeAndSetToolTip( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED_TT" )
			end

			Controls.ResourceDemandedBox:SetSizeX(Controls.ResourceDemandedString:GetSizeX() + 10)
			Controls.ResourceDemandedBox:SetHide(false)
		else
			Controls.ResourceDemandedBox:SetHide(true)
		end

		Controls.IconsStack:CalculateSize()
		Controls.IconsStack:ReprocessAnchoring()

		Controls.NotificationStack:CalculateSize()
		Controls.NotificationStack:ReprocessAnchoring()

		-------------------------------------------
		-- Raze / Unraze / Annex City Buttons
		-------------------------------------------

		local buttonToolTip, buttonLabel, taskID
		if isActivePlayerCity then

			if city:IsRazing() then

				-- We can unraze this city
				taskID = TaskTypes.TASK_UNRAZE
				buttonLabel = L"TXT_KEY_CITYVIEW_UNRAZE_BUTTON_TEXT"
				buttonToolTip = L"TXT_KEY_CITYVIEW_UNRAZE_BUTTON_TT"

			elseif city:IsPuppet() and not(IsCiv5BNW and cityOwner:MayNotAnnex()) then

				-- We can annex this city
				taskID = TaskTypes.TASK_ANNEX_PUPPET
				buttonLabel = L"TXT_KEY_POPUP_ANNEX_CITY"
-- todo
				if IsCiv5 then
					buttonToolTip = L( "TXT_KEY_POPUP_CITY_CAPTURE_INFO_ANNEX", cityOwner:GetUnhappinessForecast(city) - cityOwner:GetUnhappiness() )
				end
			elseif not g_isViewingMode and cityOwner:CanRaze( city, true ) then
				buttonLabel = L"TXT_KEY_CITYVIEW_RAZE_BUTTON_TEXT"

				if cityOwner:CanRaze( city, false ) then

					-- We can actually raze this city
					taskID = TaskTypes.TASK_RAZE
					buttonToolTip = L"TXT_KEY_CITYVIEW_RAZE_BUTTON_TT"
				else
					-- We COULD raze this city if it weren't a capital
					buttonToolTip = L"TXT_KEY_CITYVIEW_RAZE_BUTTON_DISABLED_BECAUSE_CAPITAL_TT"
				end
			end
		end
		local CityTaskButton = Controls.CityTaskButton
		CityTaskButton:SetText( buttonLabel )
		CityTaskButton:SetVoids( cityID, taskID or -1 )
		CityTaskButton:SetToolTipString( buttonToolTip )
		CityTaskButton:SetDisabled( not taskID )
		CityTaskButton:SetHide( not buttonLabel )
--Controls.ReturnToMapButton:SetToolTipString( concat( {"g_isViewingMode:", tostring(g_isViewingMode), "Can raze:", tostring(cityOwner:CanRaze( city, true )), "Can actually raze:", tostring(cityOwner:CanRaze( city, false )), "taskID:", tostring(taskID) }, " " ) )

		UpdateCityWorkingHexes( city )

		UpdateCityProductionQueue( city, cityID, cityOwnerID, isActivePlayerCity and not isCityCaptureViewingMode and IsCiv5BNW and cityOwner:MayNotAnnex() and city:IsPuppet() )

		-- display gold income
		local iGoldPerTurn = city:GetYieldRateTimes100( g_yieldCurrency ) / 100
		Controls.GoldPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", iGoldPerTurn )

		-- display science income
		if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE) then
			Controls.SciencePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_OFF" )
		else
			local iSciencePerTurn = city:GetYieldRateTimes100(YieldTypes.YIELD_SCIENCE) / 100
			Controls.SciencePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", iSciencePerTurn )
		end

		local culturePerTurn, cultureStored, cultureNext
		-- thanks for Firaxis Cleverness !
		if IsCiv5 then
			culturePerTurn = city:GetJONSCulturePerTurn()
			cultureStored = city:GetJONSCultureStored()
			cultureNext = city:GetJONSCultureThreshold()
		else
			culturePerTurn = city:GetCulturePerTurn()
			cultureStored = city:GetCultureStored()
			cultureNext = city:GetCultureThreshold()
		end
		Controls.CulturePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", culturePerTurn )
		local cultureDiff = cultureNext - cultureStored
		if culturePerTurn > 0 then
			local cultureTurns = max( ceil(cultureDiff / culturePerTurn), 1 )
			Controls.CultureTimeTillGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_TURNS_TILL_TILE_TEXT", cultureTurns )
			Controls.CultureTimeTillGrowthLabel:SetHide( false )
		else
			Controls.CultureTimeTillGrowthLabel:SetHide( true )
		end
		local percentComplete = cultureStored / cultureNext
		Controls.CultureMeter:SetPercent( percentComplete )

		if not IsCiv5vanilla then
			if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION) then
				Controls.FaithPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_OFF" )
			else
				Controls.FaithPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", city:GetFaithPerTurn() )
			end
			Controls.FaithFocusButton:SetDisabled( g_isViewingMode )
		end

		local cityGrowth = city:GetFoodTurnsLeft()
		local foodPerTurnTimes100 = city:FoodDifferenceTimes100()
		if city:IsFoodProduction() or foodPerTurnTimes100 == 0 then
			Controls.CityGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_STAGNATION_TEXT" )
		elseif foodPerTurnTimes100 < 0 then
			Controls.CityGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_STARVATION_TEXT" )
		else
			Controls.CityGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_TURNS_TILL_CITIZEN_TEXT", cityGrowth )
		end

		Controls.FoodPerTurnLabel:LocalizeAndSetText( foodPerTurnTimes100 >= 0 and "TXT_KEY_CITYVIEW_PERTURN_TEXT" or "TXT_KEY_CITYVIEW_PERTURN_TEXT_NEGATIVE", foodPerTurnTimes100 / 100 )

		-------------------------------------------
		-- Disable Buttons as Appropriate
		-------------------------------------------
		local bIsLock = g_isViewingMode or (cityOwner:GetNumCities() <= 1)
		Controls.PrevCityButton:SetDisabled( bIsLock )
		Controls.NextCityButton:SetDisabled( bIsLock )

		for _, control in pairs( g_cityFocusButtons ) do
			control:SetDisabled( g_isViewingMode )
		end

	end
end

local function UpdateOptionsAndCityView()
	g_isAdvisor = UserInterfaceSettings.CityAdvisor ~= 0
	g_isScreenAutoClose = UserInterfaceSettings.ScreenAutoClose ~= 0
	g_isResetCityPlotPurchase = UserInterfaceSettings.ResetCityPlotPurchase ~= 0
	g_FocusSelectIM.Collapse( not OptionsManager.IsNoCitizenWarning() )
	return UpdateCityView()
end

g_SpecialBuildingsIM	= StackInstanceManager( "BuildingInstance", "Button", Controls.SpecialBuildingsStack, Controls.SpecialBuildingsHeader, ResizeRightStack )
g_GreatWorkIM		= StackInstanceManager( "BuildingInstance", "Button", Controls.GreatWorkStack, Controls.GreatWorkHeader, ResizeRightStack )
g_WondersIM		= StackInstanceManager( "BuildingInstance", "Button", Controls.WondersStack, Controls.WondersHeader, ResizeRightStack )
g_BuildingsIM		= StackInstanceManager( "BuildingInstance", "Button", Controls.BuildingsStack, Controls.BuildingsHeader, ResizeRightStack )
g_GreatPeopleIM		= StackInstanceManager( "GPInstance", "GPBox", Controls.GPStack, Controls.GPHeader, ResizeRightStack )
g_SlackerIM		= StackInstanceManager( "Slot", "Button", Controls.SlackerStack, Controls.SlackerHeader, ResizeRightStack )
g_ProdQueueIM		= StackInstanceManager( "ProductionInstance", "PQbox", Controls.QueueStack, Controls.ProdBox, ResizeProdQueue, true )
g_UnitSelectIM		= StackInstanceManager( "SelectionInstance", "Button", Controls.UnitButtonStack, Controls.UnitButton, ResizeProdQueue )
g_BuildingSelectIM	= StackInstanceManager( "SelectionInstance", "Button", Controls.BuildingButtonStack, Controls.BuildingsButton, ResizeProdQueue )
g_WonderSelectIM	= StackInstanceManager( "SelectionInstance", "Button", Controls.WonderButtonStack, Controls.WondersButton, ResizeProdQueue )
g_ProcessSelectIM	= StackInstanceManager( "SelectionInstance", "Button", Controls.OtherButtonStack, Controls.OtherButton, ResizeProdQueue )
g_FocusSelectIM		= StackInstanceManager( "", "", Controls.WorkerManagementBox, Controls.WorkerHeader, function(collapsed) g_workerHeadingOpen = not collapsed ResizeRightStack() UpdateWorkingHexes() end, true, not g_workerHeadingOpen )

--------------
-- Rename City
local function RenameCity()
	local city = GetHeadSelectedCity()
	if city then
		return Events.SerialEventGameMessagePopup{
				Type = ButtonPopupTypes.BUTTONPOPUP_RENAME_CITY,
				Data1 = city:GetID(),
				Data2 = -1,
				Data3 = -1,
				Option1 = false,
				Option2 = false
				}
	end
end

local NoAutoSpecialistCheckbox = { [eLClick] = function()
			return Game.SelectedCitiesGameNetMessage(GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_NO_AUTO_ASSIGN_SPECIALISTS, -1, -1, not GetHeadSelectedCity():IsNoAutoAssignSpecialists() )
		end }

--==========================================================
-- Register Events
--==========================================================

SetupCallbacks( Controls, 
{
	ProdBox = LuaEvents.CityViewToolTips.Call,
	FoodBox = LuaEvents.CityViewToolTips.Call,
	GoldBox = LuaEvents.CityViewToolTips.Call,
	ScienceBox = LuaEvents.CityViewToolTips.Call,
	CultureBox = LuaEvents.CityViewToolTips.Call,
	FaithBox = LuaEvents.CityViewToolTips.Call,
	TourismBox = LuaEvents.CityViewToolTips.Call,
	ProductionPortraitButton = LuaEvents.CityViewToolTips.Call,
	PopulationBox = LuaEvents.CityViewToolTips.Call,
},
"EUI_ItemTooltip",
{
	AvoidGrowthButton = {
		[eLClick] = function()
			local city = GetSelectedModifiableCity()
			if city then
				Network.SendSetCityAvoidGrowth( city:GetID(), not city:IsForcedAvoidGrowth() )
				return Network.SendUpdateCityCitizens( city:GetID() )
			end
		end,
	},
	CityTaskButton = {
		[eLClick] = function( cityID, taskID, button )
			local city = GetSelectedCity()
			if city and city:GetID() == cityID then
				return Events.SerialEventGameMessagePopup{
					Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_CITY_TASK,
					Data1 = cityID,
					Data2 = taskID,
					Text = button:GetToolTipString()
					}
			end
		end,
	},
	YesButton = {
		[eLClick] = function( cityID, buildingID )
			Controls.SellBuildingConfirm:SetHide( true )
			if cityID and buildingID and buildingID > 0 and GetSelectedModifiableCity() then
				Network.SendSellBuilding( cityID, buildingID )
				Network.SendUpdateCityCitizens( cityID )
			end
			return Controls.YesButton:SetVoids( -1, -1 )
		end,
	},
	NoButton = { [eLClick] = CancelBuildingSale },
	NextCityButton = { [eLClick] = GotoNextCity },
	PrevCityButton = { [eLClick] = GotoPrevCity },
	ReturnToMapButton = { [eLClick] = ExitCityScreen },
	ProductionPortraitButton = { [eRClick] = ProductionPedia },
	BoxOSlackers = { [eLClick] = OnSlackersSelected },
	ResetButton = { [eLClick] = PlotButtonClicked },
	NoAutoSpecialistCheckbox = NoAutoSpecialistCheckbox,
	NoAutoSpecialistCheckbox2 = NoAutoSpecialistCheckbox,
	EditButton = { [eLClick] = RenameCity },
	TitlePanel = { [eRClick] = RenameCity },
})

--Controls.ResetButton:SetVoid1( 0 )	-- calling with 0 = city center causes reset of all forced tiles
--Controls.BoxOSlackers:SetVoids(-1,-1)
--Controls.ProductionPortraitButton:SetVoid1( 0 )

Controls.FaithBox:SetHide( IsCivBE or IsCiv5vanilla )
Controls.TourismBox:SetHide( not IsCiv5BNW )


Controls.BuyPlotCheckBox:RegisterCheckHandler( function( isChecked ) -- Void1, Void2, control )
	g_BuyPlotMode = isChecked
	return UpdateCityView()
end)

Events.GameOptionsChanged.Add( UpdateOptionsAndCityView )
UpdateOptionsAndCityView()

--------------------------
-- Enter City Screen Event
Events.SerialEventEnterCityScreen.Add( function()

--print("enter city screen", GetHeadSelectedCity())
	LuaEvents.TryQueueTutorial("CITY_SCREEN", true)

	Events.SerialEventCityScreenDirty.Add( UpdateCityView )
	Events.SerialEventCityInfoDirty.Add( UpdateCityView )
	Events.SerialEventCityHexHighlightDirty.Add( UpdateWorkingHexes )
	g_queuedItemNumber = nil
	g_previousCity = nil
	if g_isResetCityPlotPurchase then
		g_BuyPlotMode = false
		Controls.BuyPlotCheckBox:SetCheck( false )
	end
	Controls.RightScrollPanel:SetScrollValue(0)
--TODO other scroll panels
	return UpdateCityView()
end)

-------------------------
-- Exit City Screen Event
Events.SerialEventExitCityScreen.Add( function()
--print("exit city screen")
	if UI.IsCityScreenUp() then
		Events.SerialEventCityScreenDirty.RemoveAll()
		Events.SerialEventCityInfoDirty.RemoveAll()
		Events.SerialEventCityHexHighlightDirty.RemoveAll()
		local city = UI.GetHeadSelectedCity()
		local plot = city and city:Plot()

		CleanupCityScreen()
		Events.ClearHexHighlights()

		-- We may get here after a player change, clear the UI if this is not the active player's city
		if not city or city:GetOwner() ~= g_activePlayerID then
			ClearCityUIInfo()
		end
		-- required for game engine to display proper hex shading
		UI.ClearSelectedCities()
		LuaEvents.TryDismissTutorial("CITY_SCREEN")
		-- Try and re-select the last unit selected
		if not UI.GetHeadSelectedUnit() and UI.GetLastSelectedUnit() then
			UI.SelectUnit( UI.GetLastSelectedUnit() )
		end
		if plot then
			UI.LookAt( plot, 2 ) -- 1 = CAMERALOOKAT_CITY_ZOOM_IN, 2 = CAMERALOOKAT_NORMAL (player zoom)
		else
			UI.LookAtSelectionPlot()
		end
		g_isViewingMode = true
	end
end)

--==========================================================
-- Strategic View State Change Event
--==========================================================

if IsCiv5 then
	local NormalWorldPositionOffset = g_worldPositionOffset
	local NormalWorldPositionOffset2 = g_worldPositionOffset2
	local StrategicViewWorldPositionOffset = { x = 0, y = 20, z = 0 }
	Events.StrategicViewStateChanged.Add( function( bStrategicView )
		if bStrategicView then
			g_worldPositionOffset = StrategicViewWorldPositionOffset
			g_worldPositionOffset2 = StrategicViewWorldPositionOffset
		else
			g_worldPositionOffset = NormalWorldPositionOffset
			g_worldPositionOffset2 = NormalWorldPositionOffset2
		end
		g_previousCity = false
		return UpdateCityView()
	end)
end
--==========================================================
-- 'Active' (local human) player has changed
--==========================================================

Events.GameplaySetActivePlayer.Add( function( activePlayerID )--, previousActivePlayerID )
	g_activePlayerID = activePlayerID
	g_activePlayer = Players[ g_activePlayerID ]
	g_finishedItems = {}
	ClearCityUIInfo()
	if UI.IsCityScreenUp() then
		return ExitCityScreen()
	end
end)

Events.ActivePlayerTurnEnd.Add( function()
	g_finishedItems = {}
end)

AddSerialEventGameMessagePopup( function( popupInfo )
	if popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION, 0)
		Events.SerialEventGameMessagePopupShown( popupInfo )

		local cityID = popupInfo.Data1		-- city id
		local orderID = popupInfo.Data2		-- finished order id
		local itemID = popupInfo.Data3		-- finished item id
		local city = cityID and g_activePlayer:GetCityByID( cityID )

		if city and not UI.IsCityScreenUp() then
			if orderID >= 0 and itemID >= 0 then
				g_finishedItems[ cityID ] = { orderID, itemID }
			end
			g_isButtonPopupChooseProduction = g_isScreenAutoClose
			return UI.DoSelectCityAtPlot( city:Plot() )	-- open city screen
		end
	end
end, ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION )

Events.NotificationAdded.Add( function( notificationID, notificationType, toolTip, strSummary, data1, data2, playerID )
	if notificationType == NotificationTypes.NOTIFICATION_PRODUCTION and playerID == g_activePlayerID then
		-- Hack to find city
		for city in g_activePlayer:Cities() do
			if strSummary == L( "TXT_KEY_NOTIFICATION_NEW_CONSTRUCTION", city:GetNameKey() ) then
				if data1 >= 0 and data2 >=0 then
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
end)

--==========================================================
-- Support for Modded Add-in UI's
--==========================================================
do
	g_uiAddins = {}
	local Modding = Modding
	local uiAddins = g_uiAddins
	for addin in Modding.GetActivatedModEntryPoints("CityViewUIAddin") do
		local addinFile = Modding.GetEvaluatedFilePath(addin.ModID, addin.Version, addin.File)
		if addinFile then
			print( "Loading MOD CityViewUIAddin\n", Modding.GetModProperty(addin.ModID, addin.Version, "Name"), addin.File )
			table.insert( uiAddins, ContextPtr:LoadNewContext( addinFile.EvaluatedPath:match("(.*)%..*") ) )
		end
	end
end
