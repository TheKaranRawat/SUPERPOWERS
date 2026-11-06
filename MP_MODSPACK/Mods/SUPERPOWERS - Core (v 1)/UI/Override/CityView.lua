------------------------------------------------------
-- City View
-- coded by bc1 from 1.0.3.276 brave new world code
-- code is common using gk_mode and bnw_mode switches
-- compatible with Gazebo's City-State Diplomacy Mod (CSD) for Brave New World v21
-- compatible with JFD's Piety & Prestige for Brave New World
-- compatible with GameInfo.Yields() iterator broken by Communitas
-- todo: sell building button
------------------------------------------------------
include( "EUI_tooltips" )

Events.SequenceGameInitComplete.Add(function()
print("Loading EUI city view",ContextPtr,os.clock(),[[ 
  ____ _ _       __     ___
 / ___(_) |_ _   \ \   / (_) _____      __
| |   | | __| | | \ \ / /| |/ _ \ \ /\ / /
| |___| | |_| |_| |\ V / | |  __/\ V  V /
 \____|_|\__|\__, | \_/  |_|\___| \_/\_/
             |___/
]])

--todo: upper left corner
--todo: add meters
--todo: add meter cues
--todo: selection list with all buildable items
--todo: mod case where several buildings are allowed

-------------------------------
-- minor lua optimizations
-------------------------------
local ipairs = ipairs
local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

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

function EUI.GreatPeopleIcon(k)
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
--local StackInstanceManager = StackInstanceManager
local GameInfo = EUI.GameInfoCache -- warning! use iterator ONLY with table field conditions, NOT string SQL query

--EUI_tooltips
--[[
local GetHelpTextForUnit = GetHelpTextForUnit
local GetHelpTextForBuilding = GetHelpTextForBuilding
local GetHelpTextForProject = GetHelpTextForProject
local GetHelpTextForProcess = GetHelpTextForProcess
local GetFoodTooltip = GetFoodTooltip

local GetScienceTooltip = GetScienceTooltip
local GetProductionTooltip = GetProductionTooltip
local GetCultureTooltip = GetCultureTooltip
local GetFaithTooltip = GetFaithTooltip
local GetTourismTooltip = GetTourismTooltip
]]--
local GetGoldTooltip = civ5_mode and GetGoldTooltip or GetEnergyTooltip
--local Teams = Teams
local g_entryWidth = 56		-- width of one SelectionInstance button + stack padding (measure this in the XML)
local g_entriesPerRow = 5

include( "SupportFunctions" )
--local TruncateString = TruncateString
if not civ5_mode then
	include( "IntrigueHelper" )
end

--[[
local ButtonPopupTypes = ButtonPopupTypes
local CityAIFocusTypes = CityAIFocusTypes
local CityUpdateTypes = CityUpdateTypes
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
]]--
local Events_ClearHexHighlightStyle = Events.ClearHexHighlightStyle
local Events_RequestYieldDisplay = Events.RequestYieldDisplay
local Events_SerialEventHexHighlight = Events.SerialEventHexHighlight

--[[
local Game = Game
local GameDefines = GameDefines
local GameInfoTypes = GameInfoTypes
local GameMessageTypes = GameMessageTypes
local GameOptionTypes = GameOptionTypes
local HexToWorld = HexToWorld
]]--
local InStrategicView = InStrategicView or function() return false end
--[[
local KeyEvents = KeyEvents
local Keys = Keys
]]--
local L = Locale.ConvertTextKey
--[[
local Locale = Locale
local Modding = Modding
local Mouse = Mouse
local Network = Network
local NotificationTypes = NotificationTypes
local OptionsManager = OptionsManager
local OrderTypes = OrderTypes
local Path = Path
local Players = Players
local TaskTypes = TaskTypes
local ToHexFromGrid = ToHexFromGrid
local UI = UI
]]--
local UI_GetHeadSelectedCity = UI.GetHeadSelectedCity
local UI_GetUnitPortraitIcon = UI.GetUnitPortraitIcon
local YieldDisplayTypes_AREA = YieldDisplayTypes.AREA
--[[
local YieldTypes = YieldTypes
]]--

-------------------------------
-- Globals
-------------------------------

local g_options = Modding.OpenUserData( "Enhanced User Interface Options", 1)
local g_isAdvisor = true

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
local g_screenHeight = select(2, UIManager:GetScreenSizeVal() )
local g_leftStackHeigth = g_screenHeight - 40 - Controls.CityInfoBG:GetOffsetY() - Controls.CityInfoBG:GetSizeY()

local g_PlotButtonIM	= StackInstanceManager( "PlotButtonInstance", "PlotButtonAnchor", Controls.PlotButtonContainer )
local g_BuyPlotButtonIM	= StackInstanceManager( "BuyPlotButtonInstance", "BuyPlotButtonAnchor", Controls.PlotButtonContainer )
local g_ProdQueueIM, g_SpecialBuildingsIM, g_GreatWorkIM, g_WondersIM, g_BuildingsIM, g_GreatPeopleIM, g_SlackerIM, g_UnitSelectIM, g_CivilianSelectIM, g_BuildingSelectIM, g_WonderSelectIM, g_ProcessSelectIM, g_FocusSelectIM
local g_slots = table()
local g_works = table()
local g_heap = Controls.Scrap

local g_citySpecialists = {}

local g_queuedItemNumber = false
local g_isViewingMode = true
local g_isDebugMode = false
local g_BuyPlotMode = not ( g_options and g_options.GetValue and g_options.GetValue( "CityPlotPurchase" ) == 0 )
local g_previousCity, g_isCityViewDirty, g_isCityHexesDirty

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
    return (tonumber(item.Combat) or 0) <= 0 and (tonumber(item.RangedCombat) or 0) <= 0
end


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

local g_slackerTexture = civBE_mode and "UnemployedIndicator.dds" or g_slotTexture[ (GameInfo.Specialists[GameDefines.DEFAULT_SPECIALIST or -1] or {}).Type ] or "Blank.dds"

--local g_colorWhite = {x=1, y=1, z=1, w=1}
--local g_colorGreen = {x=0, y=1, z=0, w=1}
--local g_colorYellow = {x=1, y=1, z=0, w=1}
--local g_colorRed = {x=1, y=0, z=0, w=1}
local g_colorCulture = EUI.Color( 1, 0, 1, 1 )

local g_gameInfo = {
[OrderTypes.ORDER_TRAIN] = GameInfo.Units,
[OrderTypes.ORDER_CONSTRUCT] = GameInfo.Buildings,
[OrderTypes.ORDER_CREATE] = GameInfo.Projects,
[OrderTypes.ORDER_MAINTAIN] = GameInfo.Processes,
}
local g_avisorRecommended = {
[OrderTypes.ORDER_TRAIN] = Game.IsUnitRecommended,
[OrderTypes.ORDER_CONSTRUCT] = Game.IsBuildingRecommended,
[OrderTypes.ORDER_CREATE] = Game.IsProjectRecommended,
}
local g_advisors = {
[AdvisorTypes.ADVISOR_ECONOMIC] = "EconomicRecommendation",
[AdvisorTypes.ADVISOR_MILITARY] = "MilitaryRecommendation",
[AdvisorTypes.ADVISOR_SCIENCE] = "ScienceRecommendation",
[AdvisorTypes.ADVISOR_FOREIGN] = "ForeignRecommendation",
}

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

local function DoResizeProdQueue()
	local unitpanelfinal = 0
	local buildingPanelfinal = 0
	local wonderPanelfinal = 0

	local selectionPanelHeight = 0
	local queuePanelHeight = math_min( 190, Controls.QueueStack:IsHidden() and 0 or Controls.QueueStack:GetSizeY() )	-- 190 = 5 x 38=instance height
	
	Controls.QueueSlider:SetSizeY( queuePanelHeight + 38 )				-- 38 = Controls.PQbox:GetSizeY()
	Controls.QueueScrollPanel:SetSizeY( queuePanelHeight )
	Controls.QueueScrollPanel:CalculateInternalSize()
	Controls.QueueBackground:SetSizeY( queuePanelHeight + selectionPanelHeight + 152 )	-- 125 = 38=Controls.PQbox:GetSizeY() + 87 + 27
	
	local unitPanelWidth = 0
	local buildingPanelWidth = 0
	local wonderPanelWidth = 0
	
	local unitPanelHeight = 0

	-- dynamic production grid size 

	if not Controls.CivilianGrid:IsHidden() then
		Controls.CivilianButtonStack:CalculateSize()
		local civilianPanelWidth = Controls.CivilianButtonStack:GetSizeX()
		local civilianPanelFinal = math_max( civilianPanelWidth, 273 )
		Controls.CivilianGrid:SetSizeX( civilianPanelFinal )
		Controls.CivilianGrid:SetSizeY( 44 )
		Controls.CivilianGrid:ReprocessAnchoring()

		Controls.CivilianBG:SetSizeX( civilianPanelFinal - 3 )
		Controls.CivilianBG:SetSizeY( 40 )
		Controls.CivilianBG:ReprocessAnchoring()
	end

	local unitPanelHeight = Controls.UnitButtonStack:GetSizeY()
	if not Controls.UnitGrid:IsHidden() then
		--stack info
		Controls.UnitButtonStack:SetWrapWidth( g_entryWidth * g_entriesPerRow )
		--
		Controls.UnitButtonStack:CalculateSize()
		unitPanelWidth = Controls.UnitButtonStack:GetSizeX()

		unitpanelfinal = math_max( unitPanelWidth, 273 )
		-- Controls.SelectionBackground:SetSizeY( unitPanelWidth + 85 )
		Controls.UnitGrid:SetSizeX( unitpanelfinal )		
		Controls.UnitGrid:SetSizeY( unitPanelHeight + 4 )
		Controls.UnitGrid:ReprocessAnchoring()

		Controls.UnitBG:SetSizeX( unitpanelfinal - 3 )
		Controls.UnitBG:SetSizeY( unitPanelHeight )
		Controls.UnitBG:ReprocessAnchoring()

	end
	

	local buildingPanelHeight = Controls.BuildingButtonStack:GetSizeY()
	if not Controls.BuildingGrid:IsHidden() then
		--stack info
		Controls.BuildingButtonStack:SetWrapWidth( g_entryWidth * g_entriesPerRow )
		--
		Controls.BuildingButtonStack:CalculateSize()
		buildingPanelWidth = Controls.BuildingButtonStack:GetSizeX()

		buildingPanelfinal = math_max( buildingPanelWidth, 273 )
		-- Controls.SelectionBackground:SetSizeY( unitPanelWidth + 85 )
		Controls.BuildingGrid:SetSizeX( buildingPanelfinal )
		Controls.BuildingGrid:SetSizeY( buildingPanelHeight + 4 )
		Controls.BuildingGrid:ReprocessAnchoring()
		
		--set bg for selection stack
		Controls.BuildBG:SetSizeX( buildingPanelfinal - 3 )
		Controls.BuildBG:SetSizeY( buildingPanelHeight )
		Controls.BuildBG:ReprocessAnchoring()
	end

	local wonderPanelHeight = Controls.WonderButtonStack:GetSizeY()
	if not Controls.WonderGrid:IsHidden() then
		--stack info
		Controls.WonderButtonStack:SetWrapWidth( g_entryWidth * g_entriesPerRow )
		--
		Controls.WonderButtonStack:CalculateSize()
		wonderPanelWidth = Controls.WonderButtonStack:GetSizeX()
		
		wonderPanelfinal = math_max( wonderPanelWidth, 273 )
		-- Controls.SelectionBackground:SetSizeY( unitPanelWidth + 85 )
		Controls.WonderGrid:SetSizeX( wonderPanelfinal )
		Controls.WonderGrid:SetSizeY( wonderPanelHeight + 4 )
		Controls.WonderGrid:ReprocessAnchoring()

		--set bg for selection stack
		Controls.WonderBG:SetSizeX( wonderPanelfinal - 3 )
		Controls.WonderBG:SetSizeY( wonderPanelHeight )
		Controls.WonderBG:ReprocessAnchoring()

		--set bg for selection stack
		Controls.OtherBG:SetSizeX( 269 )
		Controls.OtherBG:SetSizeY( 41 )
		Controls.OtherBG:ReprocessAnchoring()		

		--set bg for selection stack
		--Controls.PQBG:SetSizeX( 269 )
		--Controls.PQBG:SetSizeY( 40 )
		--Controls.PQBG:ReprocessAnchoring()	

	end
	
	if not Controls.SelectionScrollPanel:IsHidden() then
		Controls.SelectionStacks:CalculateSize()
		selectionPanelHeight = math_max( math_min( g_leftStackHeigth - queuePanelHeight + wonderPanelHeight + buildingPanelHeight + unitPanelHeight, Controls.SelectionStacks:GetSizeY() ), 260 )
--		Controls.SelectionBackground:SetSizeY( selectionPanelHeight + 85 )
		Controls.SelectionScrollPanel:SetSizeY( selectionPanelHeight )
		--Controls.SelectionScrollPanel:CalculateInternalSize()
		Controls.SelectionScrollPanel:ReprocessAnchoring()
	end
	-- minimize production grid windows

	--local zeroHeight = 0
	--if Controls.UnitButtonStack:IsHidden() then
	--	Controls.UnitGrid:SetSizeY( zeroHeight )
	--end

	--print( "unit panel height" )
	--print( unitPanelWidth )
	
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

-- batching (top level, right after DoResizeRightStack)
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

local function GetSelectedCity()
	return ( not Game.IsNetworkMultiPlayer() or g_activePlayer:IsTurnActive() ) and UI_GetHeadSelectedCity()
end

local function GetSelectedModifiableCity()
	return not g_isViewingMode and GetSelectedCity()
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
							-- bOnlyTestVisible
		else
			return false
		end
	end
end

-------------------------------------------------
-- Clear out the UI so that when a player changes
-- the next update doesn't show the previous player's
-- values for a frame
-------------------------------------------------
local function ClearCityUIInfo()
	g_ProdQueueIM.ResetInstances()
	g_ProdQueueIM.Commit()
	Controls.PQremove:SetHide( true )
	Controls.PQrank:SetText()
	Controls.PQname:SetText()
	Controls.PQturns:SetText()
	return Controls.ProductionPortraitButton:SetHide(true)
end

--------------------
-- Selling Buildings
--------------------
local function SellBuilding( buildingID )

	local city = GetSelectedModifiableCity()

	-- Can this building be sold?
	if city and city:IsBuildingSellable( buildingID ) then
		-- Build info string
		local building = GameInfo.Buildings[ buildingID ]

		Controls.SellBuildingPopupText:SetText( L(building.Description) .. ": "
			.. L( "TXT_KEY_SELL_BUILDING_INFO", city:GetSellBuildingRefund(buildingID), building[g_maintenanceCurrency] or 0 ) )
--todo energy


		Controls.YesButton:SetVoids( city:GetID(), buildingID )

		return Controls.SellBuildingConfirm:SetHide( false )
	end
end

local function CancelBuildingSale()
	Controls.SellBuildingConfirm:SetHide(true)
	return Controls.YesButton:SetVoids( -1, -1 )
end

local function ExitCityButNotScreen()
	-- clear any rogue leftover tooltip
	g_leftTipControls.Box:SetHide( true )
	g_rightTipControls.Box:SetHide( true )
	g_isButtonPopupChooseProduction = false
	g_chainVisited = {}
	Controls.RightScrollPanel:SetScrollValue(0)
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

-- scroll to next city function kraw
local function ScrollToNextIdleCity( fromCityID )
	-- MP: only act while it's your turn
	if Game.IsNetworkMultiPlayer() and not g_activePlayer:IsTurnActive() then
		return false
	end
	for cityX in g_activePlayer:Cities() do
		if cityX:GetID() ~= fromCityID and not cityX:IsPuppet() and cityX:GetOrderQueueLength() < 1 then
			--UI.LookAt( cityX:Plot() )		-- camera only
			g_isButtonPopupChooseProduction = g_isAutoClose		-- keeps the chain going on the next ESC
			UI.DoSelectCityAtPlot( cityX:Plot() )
			return true
		end
	end
	return false
end

--[[
local function ExitCityScreen()
	ExitCityButNotScreen()
	return Events.SerialEventExitCityScreen()
end
]]--
local function ExitCityScreen()
	local wasProductionPopup = g_isButtonPopupChooseProduction	-- ExitCityButNotScreen() resets it
	local city = UI_GetHeadSelectedCity()
	local cityID = city and city:GetID()
	ExitCityButNotScreen()
	Events.SerialEventExitCityScreen()
	if wasProductionPopup and cityID then
		ScrollToNextIdleCity( cityID )	-- after exit, so the exit handler's own camera move can't override it
	end
end

local function FindNextIdleCity( currentCity )
	-- MP: only act on your own turn
	if Game.IsNetworkMultiPlayer() and not g_activePlayer:IsTurnActive() then
		return nil
	end
	local currentID = currentCity and currentCity:GetID()
	for cityX in g_activePlayer:Cities() do
		local id = cityX:GetID()
		if id ~= currentID and not g_chainVisited[ id ] and not cityX:IsPuppet() and cityX:GetOrderQueueLength() < 1 then
			return cityX
		end
	end
end

-- ESC / right click: go to the next idle city, or leave when there are none left
local function CloseOrAdvanceCityScreen()
	if g_isButtonPopupChooseProduction then
		local city = UI_GetHeadSelectedCity()
		if city then
			g_chainVisited[ city:GetID() ] = true	-- skipped cities are not revisited (prevents ping-pong)
		end
		local nextCity = FindNextIdleCity( city )
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

----------------------------------------------------------------
-- Input handling
----------------------------------------------------------------


ContextPtr:SetInputHandler(
function( uiMsg, wParam )
	--record keystrokes in log
	if uiMsg ~= MouseEvents.MouseMove then
		print( "INPUT", uiMsg, wParam )
	end
	if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
		if uiMsg == KeyEvents.KeyDown then
			return true				-- swallow; act on key-up
		elseif uiMsg == KeyEvents.KeyUp then
			local ok, err = pcall( CloseOrAdvanceCityScreen )
			if not ok then print( err ) end
			return true
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
		local ok, err = pcall( CloseOrAdvanceCityScreen )
		if not ok then print( err ) end
		return true
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
	local specialistID = specialistType and GameInfoTypes[specialistType] or GameDefines.DEFAULT_SPECIALIST
	local specialist = specialistID and GameInfo.Specialists[ specialistID ]
	return Events.SearchForPediaEntry( specialist and tostring(specialist.Description) )
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
		-- Culture
		local cultureFromSpecialist, specialistYield = city:GetCultureFromSpecialist( specialistID )
		local specialistCultureModifier, specialistYieldModifier = city:GetCultureRateModifier() + ( cityOwner and ( cityOwner:GetCultureCityModifier() + ( city:GetNumWorldWonders() > 0 and cityOwner:GetCultureWonderMultiplier() or 0 ) or 0 ) )
		-- Yield
		for yieldID = 0, YieldTypes.NUM_YIELD_TYPES-1 do
			specialistYield = city:GetSpecialistYield( specialistID, yieldID )
			specialistYieldModifier = city:GetBaseYieldRateModifier( yieldID )
			if yieldID == YieldTypes.YIELD_CULTURE then
				specialistYield = specialistYield + cultureFromSpecialist
				specialistYieldModifier = specialistYieldModifier + specialistCultureModifier
				cultureFromSpecialist = 0
			end
			yieldTips:insertIf( specialistYield ~= 0 and specialistYield * specialistYieldModifier / 100 .. tostring(YieldIcons[yieldID]) )
		end
		yieldTips:insertIf( cultureFromSpecialist ~= 0 and cultureFromSpecialist .. "[ICON_CULTURE]" )
		yieldTips:insertIf( civ5_mode and (specialist.GreatPeopleRateChange or 0) ~= 0 and specialist.GreatPeopleRateChange .. GreatPeopleIcon( specialist.Type ) )
	end
	return yieldTips:concat(" ")
end

local function SpecialistTooltip( control )
	local buildingID = control:GetVoid1()
	local building = buildingID and GameInfo.Buildings[ buildingID ]
	local specialistType = building and building.SpecialistType
	local specialistID = specialistType and GameInfoTypes[specialistType] or GameDefines.DEFAULT_SPECIALIST
	local specialist = GameInfo.Specialists[ specialistID ]
	local strToolTip = L(specialist.Description) .. " " .. GetSpecialistYields( UI_GetHeadSelectedCity(), specialist )
	local slotTable = building and g_citySpecialists[buildingID]
	if slotTable and not slotTable[control:GetVoid2()] then
		strToolTip = L"TXT_KEY_CITYVIEW_EMPTY_SLOT".."[NEWLINE]("..strToolTip..")"
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

		g_rightTipControls.Text:SetText( GetHelpTextForBuilding( buildingID, false, false, city:GetNumFreeBuilding(buildingID) > 0, city ) )
		IconHookup( building.PortraitIndex, g_rightTipControls.Portrait:GetSizeY(), building.IconAtlas, g_rightTipControls.Portrait )
		g_rightTipControls.Box:SetHide( false )
		return g_rightTipControls.Box:DoAutoSize()
	end
end

local function OrderItemTooltip( city, isDisabled, purchaseYieldID, orderID, itemID, _, isRepeat )
	local itemInfo, strToolTip, strDisabledInfo, portraitOffset, portraitAtlas, isRealRepeat
	if city then
		local cityOwnerID = city:GetOwner()
		if orderID == OrderTypes.ORDER_TRAIN then
			itemInfo = GameInfo.Units
			portraitOffset, portraitAtlas = UI_GetUnitPortraitIcon( itemID, cityOwnerID )
			strToolTip = GetHelpTextForUnit( itemID, true )
			isRealRepeat = isRepeat

			if isDisabled then
				if purchaseYieldID == g_yieldCurrency then
					strDisabledInfo = city:GetPurchaseUnitTooltip(itemID)
				elseif purchaseYieldID == YieldTypes.YIELD_FAITH then
					strDisabledInfo = city:GetFaithPurchaseUnitTooltip(itemID)
				else
					strDisabledInfo = city:CanTrainTooltip(itemID)
				end
			end

		elseif orderID == OrderTypes.ORDER_CONSTRUCT then
			itemInfo = GameInfo.Buildings
			strToolTip = GetHelpTextForBuilding( itemID, false, false, city:GetNumFreeBuilding(itemID) > 0, city )
			if isDisabled then
				if purchaseYieldID == g_yieldCurrency then
--					cash = cityOwner:GetGold() - city:GetBuildingPurchaseCost(itemID)
--					icon = g_currencyIcon
					strDisabledInfo = city:GetPurchaseBuildingTooltip(itemID)
				elseif purchaseYieldID == YieldTypes.YIELD_FAITH then
--					cash = cityOwner:GetFaith() - city:GetBuildingFaithPurchaseCost(itemID)
--					icon = "[ICON_PEACE]"
					strDisabledInfo = city:GetFaithPurchaseBuildingTooltip(itemID)
				else
					strDisabledInfo = city:CanConstructTooltip(itemID)
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
				strDisabledInfo = (strDisabledInfo:gsub("^%[NEWLINE%]","")):gsub("^%[NEWLINE%]","")
--				if cash and cash < 0 then
--					strDisabledInfo = ("%s (%+i%s)"):format( strDisabledInfo, cash, icon )
--				end
				strToolTip = "[COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR][NEWLINE][NEWLINE]"..strToolTip
			elseif purchaseYieldID then
				if not isDisabled then
					strToolTip = "[COLOR_YELLOW]"..L"TXT_KEY_CITYVIEW_PURCHASE_TT".."[ENDCOLOR][NEWLINE][NEWLINE]"..strToolTip
				end
			elseif isDisabled then
				strToolTip = "[COLOR_YIELD_FOOD]"..L"TXT_KEY_CITYVIEW_QUEUE_PROD_TT".."[ENDCOLOR][NEWLINE][NEWLINE]"..strToolTip
			end
		end
		local item = itemInfo and itemInfo[itemID]
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
-- Specialist Managemeent
-------------------------------
local function OnSlackersSelected( buildingID, slotID )
	local city = GetSelectedModifiableCity()
	if city then
		for i=1, slotID<=0 and city:GetSpecialistCount( GameDefines.DEFAULT_SPECIALIST ) or 1 do
			Network.SendDoTask( city:GetID(), TaskTypes.TASK_REMOVE_SLACKER, 0, -1, false )
		end
	end
end

local function ToggleSpecialist( buildingID, slotID )
	local city = buildingID and slotID and GetSelectedModifiableCity()
	if city then

		-- If Specialists are automated then you can't change things with them
		if civ5_mode and not city:IsNoAutoAssignSpecialists() then
			Game.SelectedCitiesGameNetMessage(GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_NO_AUTO_ASSIGN_SPECIALISTS, -1, -1, true)
			Controls.NoAutoSpecialistCheckbox:SetCheck(true)
			if bnw_mode then
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

-------------------------------
-- Great Work Managemeent
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

local function YourCulturePopup( greatWorkID )
	return Events.SerialEventGameMessagePopup{
		Type = ButtonPopupTypes.BUTTONPOPUP_CULTURE_OVERVIEW,
		Data1 = 1,
		Data2 = 1,
		}
end

local function ThemingTooltip( buildingClassID, _, control )
	control:SetToolTipString( UI_GetHeadSelectedCity():GetThemingTooltip( buildingClassID ) )
end

local function GreatWorkTooltip( greatWorkID, greatWorkSlotID, slot )
	if greatWorkID >= 0 then
		return slot:SetToolTipString( Game.GetGreatWorkTooltip( greatWorkID, UI_GetHeadSelectedCity():GetOwner() ) )
	else
		return slot:LocalizeAndSetToolTip( tostring(( GameInfo.GreatWorkSlots[ greatWorkSlotID ] or {}).EmptyToolTipText) )
	end
end

-------------------------------------------------
-- City Buildings List
-------------------------------------------------

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

-- flat lists + per-item flags for the selection list
local g_buildingList, g_isWonderBuilding = {}, {}
for item in GameInfo.Buildings() do
	g_buildingList[ #g_buildingList + 1 ] = item
	local class = GameInfo.BuildingClasses[ item.BuildingClass ]
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

local g_initialCache = {}	-- filled lazily with FirstLetter() results

-- integer key for "already in queue" lookups (replaces float orderID/64 + itemID)
local function QueueKey( orderID, itemID )
	return orderID * 100000 + itemID
end

-- Advisor recommendation cache.
-- Valid for one (city, turn, queue contents) combination. Slightly stale within a
-- turn if gold changes; advisor icons are advisory only. Purely local UI state.
local g_advisorCache = {}
local g_advisorSig = nil
local g_advisorCity = nil
local g_advisorCityReady = false

local function IsAdvisorRecommended( orderID, itemID, advisorID )
	local func = g_avisorRecommended[ orderID ]
	if not func then return false end
	local key = ( orderID * 100000 + itemID ) * 16 + advisorID
	local v = g_advisorCache[ key ]
	if v == nil then
		if not g_advisorCityReady and g_advisorCity then
			Game.SetAdvisorRecommenderCity( g_advisorCity )
			g_advisorCityReady = true
		end
		v = func( itemID, advisorID ) and true or false
		g_advisorCache[ key ] = v
	end
	return v
end

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

	-- per-city values (were recomputed per building)
	local population = city:GetPopulation()
	local foodPerPop = GameDefines.FOOD_CONSUMPTION_PER_POPULATION
	local isFoodShort = city:FoodConsumption() < foodPerPop * population
	local halfSpecialistUnhappiness = 0	-- per specialist
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
		local sellButton = controls.SellButton
		local textButton = controls.TextButton
		textButton:SetHide( true )
		if isNewInstance then
			buildingButton:RegisterCallback( Mouse.eRClick, BuildingPedia )
			buildingButton:RegisterCallback( Mouse.eLClick, SellBuilding )
			buildingButton:SetToolTipCallback( BuildingToolTip )
			sellButton:RegisterCallback( Mouse.eLClick, SellBuilding )
		else
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

		-- sell button is always hidden in this UI; keep the data hookup only when sellable
		if not g_isViewingMode and city:IsBuildingSellable( buildingID ) then
			sellButton:SetText( city:GetSellBuildingRefund( buildingID ) .. g_currencyIcon )
			sellButton:SetVoid1( buildingID )
		end
		sellButton:SetHide( true )

		local slotStack = controls.SlotStack
		local instance	-- created lazily, only when a new slot control must be built

		controls.Portrait:SetHide( not IconHookup( building.PortraitIndex, 128, building.IconAtlas, controls.Portrait ) )

		-------------------
		-- Great Work Slots
		if greatWorkCount > 0 then
			local buildingGreatWorkSlotType = building.GreatWorkSlotType
			if buildingGreatWorkSlotType then
				local buildingGreatWorkSlot = GameInfo.GreatWorkSlots[ buildingGreatWorkSlotType ]
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
		local specialistTable = g_citySpecialists[ buildingID ] or {}
		if specialistTable.n ~= numSpecialistsInBuilding then
			specialistTable = { n = numSpecialistsInBuilding }
			for n = 1, numSpecialistsInBuilding do
				specialistTable[n] = true
			end
			g_citySpecialists[ buildingID ] = specialistTable
		end
		local specialistType = building.SpecialistType
		local specialist = GameInfo.Specialists[ specialistType ]
		if specialist then
			for slotID = 1, city:GetNumSpecialistsAllowedByBuilding( buildingID ) do
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
					slot:SetTexture( specialistTable[ slotID ] and g_slotTexture[ specialistType ] or "CitizenEmpty.dds" )
				elseif instance and instance.Portrait then
					IconHookup( specialist.PortraitIndex, 45, specialist.IconAtlas, instance.Portrait )
					instance.Portrait:SetHide( not specialistTable[ slotID ] )
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
		else -- civBE_mode
			local healthChange = ( tonumber( building.Health ) or 0 ) + ( tonumber( building.UnmoddedHealth ) or 0 ) + cityOwner:GetExtraBuildingHealthFromPolicies( buildingID )
			for _, perkID in ipairs( cityOwnerPerks ) do
				healthChange = healthChange + Game.GetPlayerPerkBuildingClassPercentHealthChange( perkID, buildingClassID )
				defenseChange = defenseChange + Game.GetPlayerPerkBuildingClassCityStrengthChange( perkID, buildingClassID )
				hitPointChange = hitPointChange + Game.GetPlayerPerkBuildingClassCityHPChange( perkID, buildingClassID )
				maintenanceCost = maintenanceCost + Game.GetPlayerPerkBuildingClassEnergyMaintenanceChange( perkID, buildingClassID )
			end
			tips:insertIf( healthChange ~= 0 and healthChange .. "[ICON_HEALTH_1]" )
		end

		-- Yields (only the values that are actually displayed)
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

			-- per-population yield from the precomputed table
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
	if now - g_lastPurchaseClock < 0.3 then
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
			g_advisorSig = nil	-- force advisor cache rebuild
			Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_BANNER )
			Events.SpecificCityInfoDirty( cityOwnerID, cityID, CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION )
			if soundKey then
				Events.AudioPlay2DSound( soundKey )
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

local function SortSelectionList(a,b)
	return a[3]<b[3]
end

-- control queue length
local g_maxQueueLength = 7
local g_SelectionListCallBacks = {
	Button = {
		[Mouse.eLClick] = function( orderID, itemID )
			local city = GetSelectedModifiableCity()
			if city then
				local cityOwnerID = city:GetOwner()
				if cityOwnerID == g_activePlayerID and not city:IsPuppet() then

					-- Queue limit (shift-click replaces the queue, so allow it)
					if city:GetOrderQueueLength() >= g_maxQueueLength and not UI.ShiftKeyDown() then
						return Events.AudioPlay2DSound( "AS2D_INTERFACE_BUTTON_CLICK_DISABLED" ) -- optional feedback; remove if the sound key doesn't exist
					end
					-- cityPushOrder( city, orderID, itemID, bAlt, bShift, bCtrl )
					-- cityPushOrder( city, orderID, itemID, repeatBuild, replaceQueue, bottomOfQueue )
					Game.CityPushOrder( city, orderID, itemID, UI.AltKeyDown(), UI.ShiftKeyDown(), not UI.CtrlKeyDown() )
					Events.SpecificCityInfoDirty( cityOwnerID, city:GetID(), CityUpdateTypes.CITY_UPDATE_TYPE_BANNER )
					Events.SpecificCityInfoDirty( cityOwnerID, city:GetID(), CityUpdateTypes.CITY_UPDATE_TYPE_PRODUCTION )
					
					--[[ disable so production popup doesn't auto close after a single entry 
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
					]]--

				end
			end
		end,
		-- right click buy unit
		-- [Mouse.eRClick] = SelectionPedia,
		[Mouse.eRClick] = function( orderID, itemID )
		-- Ctrl + right click keeps the old Pedia behaviour
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

-- first character of a string, safe for multi-byte UTF-8 (accents, CJK, etc.)
local function FirstLetter( text )
    text = tostring( text or "" )
    -- skip leading colour tags such as [COLOR_YELLOW]
    text = text:gsub( "^%s*%[COLOR_[%w_]+%]", "" )
    -- name starts with a text icon: return the whole icon tag
    local icon = text:match( "^%s*(%[ICON_[%w_]+%])" )
    if icon then
        return icon
    end
    -- otherwise the first (UTF-8 safe) character, uppercased
    return Locale.ToUpper( text:match( "[%z\1-\127\194-\244][\128-\191]*" ) or text )
end

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
	--local useAdvisor = g_isAdvisor and not g_isDebugMode
	local useAdvisor = false
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
		instance.DisabledProduction:SetHide( canProduce or not( canBuyWithGold or canBuyWithFaith ) )
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

		if not turnsLeft then
		elseif turnsLeft > -1 and turnsLeft <= 999 then
			instance.Turns:LocalizeAndSetText( turnsLeft )
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
			instance.GoldButton:SetText( ( cash >= goldCost and goldCost or "[COLOR_WARNING_TEXT]" .. ( goldCost - cash ) .. "[ENDCOLOR]" ) .. g_currencyIcon )
		end
		instance.FaithButton:SetHide( not faithCost )
		if faithCost then
			instance.FaithButton:SetDisabled( not canBuyWithFaith )
			instance.FaithButton:SetAlpha( canBuyWithFaith and 1 or 0.5 )
			instance.FaithButton:SetVoids( orderID, itemID )
			instance.FaithButton:SetText( ( faith >= faithCost and faithCost or "[COLOR_WARNING_TEXT]" .. ( faithCost - faith ) .. "[ENDCOLOR]" ) .. "[ICON_PEACE]" )
		end

		for advisorID, advisorName in pairs( g_advisors ) do
			local advisorControl = instance[ advisorName ]
			if advisorControl then
				advisorControl:SetHide( not ( useAdvisor and IsAdvisorRecommended( orderID, itemID, advisorID ) ) )
			end
		end
	end
	return selectionIM.Commit()
end

-------------------------------
-- Production Queue Managemeent
-------------------------------
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
		local a, b = g_queuedItemNumber, queuedItemNumber
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

-- check project unit prereq
local function IsProjectPrereqMet( item )
	local prereq = item.ProjectPrereq
	if not prereq then
		return true	-- unit has no project requirement
	end
	local projectID = GameInfoTypes[ prereq ]
	if not projectID then
		return false	-- mistyped or missing project type
	end
	return Teams[ g_activePlayer:GetTeam() ]:GetProjectCount( projectID ) > 0
end

-- fix unique unit display
local g_civOnlyUnits = {
	UNIT_SIAMESE_MONK   = "CIVILIZATION_SIAM",
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

	-- Production stored and needed
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
	local sig = cityID .. ":" .. Game.GetGameTurn()

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
			sig = sig .. ":" .. orderID .. "." .. itemID
		end
		local instance, portraitSize
		if queuedItemNumber == 0 then
			instance = Controls	-- callbacks for this one are registered once at load (STEP 7)
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
			itemInfo = IconHookup( portraitOffset or item.PortraitIndex, portraitSize, portraitAtlas or item.IconAtlas, instance.PQportrait )
			instance.PQname:LocalizeAndSetText( item.Description )
			if isMaintain or isQueueEmpty then
			elseif isGeneratingProduction then
				instance.PQturns:LocalizeAndSetText( turnsRemaining )
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

		-- advisor cache: rebuilt only when city / turn / queue changed
		if sig ~= g_advisorSig then
			g_advisorSig = sig
			g_advisorCache = {}
		end
		g_advisorCity = city
		g_advisorCityReady = false	-- SetAdvisorRecommenderCity is called lazily on first cache miss

		-- Buildings & Wonders
		local orderID = OrderTypes.ORDER_CONSTRUCT
		for i = 1, #g_buildingList do
			local item = g_buildingList[i]
			local id = item.ID
			if not queueItems[ QueueKey( orderID, id ) ] then
				AddSelectionItem( city, item,
						g_isWonderBuilding[ id ] and wonderSelectList or buildingSelectList,
						orderID,
						city.CanConstruct,
						-1, id, -1,
						city.GetBuildingProductionTurnsLeft,
						city.GetBuildingPurchaseCost,
						city.GetBuildingFaithPurchaseCost )
			end
		end
		if not g_isDebugMode then
			-- Units
			orderID = OrderTypes.ORDER_TRAIN
			for i = 1, #g_unitList do
				local item = g_unitList[i]
				--if IsProjectPrereqMet( item ) then
				if IsProjectPrereqMet( item ) and IsUnitAllowedForCiv( item ) then
					AddSelectionItem( city, item,
						g_isCivilianUnit[ item.ID ] and civilianSelectList or unitSelectList,
						orderID,
						city.CanTrain,
						item.ID, -1, -1,
						city.GetUnitProductionTurnsLeft,
						city.GetUnitPurchaseCost,
						city.GetUnitFaithPurchaseCost )
				end
			end
			-- Projects
			orderID = OrderTypes.ORDER_CREATE
			for i = 1, #g_projectList do
				local item = g_projectList[i]
				if not queueItems[ QueueKey( orderID, item.ID ) ] then
					AddSelectionItem( city, item,
							processSelectList,
							orderID,
							city.CanCreate,
							-1, -1, item.ID,
							city.GetProjectProductionTurnsLeft,
							city.GetProjectPurchaseCost,
							city.GetProjectFaithPurchaseCost )
				end
			end
			-- Processes
			orderID = OrderTypes.ORDER_MAINTAIN
			for i = 1, #g_processList do
				local item = g_processList[i]
				if not queueItems[ QueueKey( orderID, item.ID ) ] then
					AddSelectionItem( city, item,
							processSelectList,
							orderID,
							city.CanMaintain )
				end
			end
		end

		SetupSelectionList( unitSelectList, g_UnitSelectIM, cityOwnerID, UI_GetUnitPortraitIcon, "initial" )
		SetupSelectionList( civilianSelectList, g_CivilianSelectIM, cityOwnerID, UI_GetUnitPortraitIcon, "initial" )
		SetupSelectionList( buildingSelectList, g_BuildingSelectIM, nil, nil, "initial" )
		SetupSelectionList( wonderSelectList, g_WonderSelectIM, nil, nil, "none" )
		SetupSelectionList( processSelectList, g_ProcessSelectIM, nil, nil, "none" )

		-- keep headers visible even when a list is empty
		Controls.BuildingsButton:SetHide( false )
		Controls.BuildingGrid:SetHide( false )
		Controls.UnitButton:SetHide( false )
		Controls.UnitGrid:SetHide( false )
		Controls.WondersButton:SetHide( false )
		Controls.WonderGrid:SetHide( false )
		Controls.OtherButton:SetHide( false )
		Controls.OtherGrid:SetHide( false )
		Controls.CivilianButton:SetHide( false )
		Controls.CivilianGrid:SetHide( false )
	end
	return ResizeProdQueue()
end

-------------------------------------------------
-- City Hex Clicking & Mousing
-------------------------------------------------
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

-------------------------------------------------
-- City Hexes Update
-------------------------------------------------
local function UpdateWorkingHexesNow()

	g_isCityHexesDirty = false
	local city = UI_GetHeadSelectedCity()
	if city and UI.IsCityScreenUp() then

		Events_ClearHexHighlightStyle( "Culture" )
		Events_ClearHexHighlightStyle( "WorkedFill" )
		Events_ClearHexHighlightStyle( "WorkedOutline" )
		Events_ClearHexHighlightStyle( "OverlapFill" )
		Events_ClearHexHighlightStyle( "OverlapOutline" )
		Events_ClearHexHighlightStyle( "VacantFill" )
		Events_ClearHexHighlightStyle( "VacantOutline" )
		Events_ClearHexHighlightStyle( "EnemyFill" )
		Events_ClearHexHighlightStyle( "EnemyOutline" )
		Events_ClearHexHighlightStyle( "BuyFill" )
		Events_ClearHexHighlightStyle( "BuyOutline" )

		g_PlotButtonIM.ResetInstances()
		g_BuyPlotButtonIM.ResetInstances()

		-- Show plots that will be acquired by culture
		local purchasablePlots = {city:GetBuyablePlotList()}
		for i = 1, #purchasablePlots do
			local plot = purchasablePlots[i]
			Events_SerialEventHexHighlight( ToHexFromGrid{ x=plot:GetX(), y=plot:GetY() }, true, g_colorCulture, "Culture" )
			purchasablePlots[ plot ] = true
		end


		local cityArea = city:GetNumCityPlots() - 1
		Events_RequestYieldDisplay( YieldDisplayTypes_AREA, RadiusHexArea( cityArea ), city:GetX(), city:GetY() )

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
						Events_SerialEventHexHighlight( hexPos , true, nil, "WorkedFill" )
						Events_SerialEventHexHighlight( hexPos , true, nil, "WorkedOutline" )
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
							Events_SerialEventHexHighlight( hexPos , true, nil, "OverlapFill" )
							Events_SerialEventHexHighlight( hexPos , true, nil, "OverlapOutline" )
						elseif cityPlotIndex then
							Events_SerialEventHexHighlight( hexPos , true, nil, "VacantFill" )
							Events_SerialEventHexHighlight( hexPos , true, nil, "VacantOutline" )
						else
							Events_SerialEventHexHighlight( hexPos , true, nil, "EnemyFill" )
							Events_SerialEventHexHighlight( hexPos , true, nil, "EnemyOutline" )
						end
					end
				end
				if iconID and showButtons then
					local instance = g_PlotButtonIM.GetInstance()
					instance.PlotButtonAnchor:SetWorldPositionVal( worldPos.x + g_worldPositionOffset.x, worldPos.y + g_worldPositionOffset.y, worldPos.z + g_worldPositionOffset.z ) --todo: improve code
					instance.PlotButtonImage:LocalizeAndSetToolTip( tipKey )
					IconHookup( iconID, 45, "CITIZEN_ATLAS", instance.PlotButtonImage )
					local button = instance.PlotButtonImage
					if not cityPlotIndex or g_isViewingMode then
						button:ClearCallback( Mouse.eLCLick )
					else
						button:SetVoid1( cityPlotIndex )
						button:RegisterCallback( Mouse.eLCLick, PlotButtonClicked )
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
					local x, y = plot:GetX(), plot:GetY()
					local hexPos = ToHexFromGrid{ x=x, y=y }
					local worldPos = HexToWorld( hexPos )
					if city:CanBuyPlotAt( x, y, true ) then
						local instance = g_BuyPlotButtonIM.GetInstance()
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
							button:RegisterCallback( Mouse.eLCLick, BuyPlotAnchorButtonClicked )
							if notInStrategicView then
								Events_SerialEventHexHighlight( hexPos , true, nil, "BuyFill" )
								if not purchasablePlots[ plot ] then
									Events_SerialEventHexHighlight( hexPos , true, nil, "BuyOutline" )
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
		g_PlotButtonIM.Commit()
		g_BuyPlotButtonIM.Commit()

	end -- city
end

-------------------------------------------------
-- City View Update
-------------------------------------------------
local function UpdateCityViewNow()

	g_isCityViewDirty = false
	local city = UI_GetHeadSelectedCity()

	if city then

		if g_citySpecialists.city ~= city then
			g_citySpecialists = { city = city }
		end
		if g_previousCity ~= city then
			g_previousCity = city
--[[
			Events_ClearHexHighlightStyle("CityLimits")
			if not InStrategicView() then
				for cityPlotIndex = 0, city:GetNumCityPlots() - 1 do
					local plot = city:GetCityIndexPlot( cityPlotIndex )
					if plot then
						local hexPos = ToHexFromGrid{ x=plot:GetX(), y=plot:GetY() }
						Events_SerialEventHexHighlight( hexPos , true, nil, "CityLimits" )
					end
				end
			end
--]]
		end
		local cityID = city:GetID()
		local cityOwnerID = city:GetOwner()
		local cityOwner = Players[cityOwnerID]
		local isActivePlayerCity = cityOwnerID == Game.GetActivePlayer()
		local isCityCaptureViewingMode = UI.IsPopupTypeOpen(ButtonPopupTypes.BUTTONPOPUP_CITY_CAPTURED)
		g_isDebugMode = Game.IsDebugMode()
		g_isViewingMode = city:IsPuppet() or not isActivePlayerCity or isCityCaptureViewingMode

		if civ5_mode then
			-- Auto Specialist checkbox
			local isNoAutoAssignSpecialists = city:IsNoAutoAssignSpecialists()
			Controls.NoAutoSpecialistCheckbox:SetCheck( isNoAutoAssignSpecialists )
			Controls.NoAutoSpecialistCheckbox:SetDisabled( g_isViewingMode )
			if bnw_mode then
				Controls.TourismPerTurnLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_PERTURN_TEXT", city:GetBaseTourism() )
				Controls.NoAutoSpecialistCheckbox2:SetCheck( isNoAutoAssignSpecialists )
				Controls.NoAutoSpecialistCheckbox2:SetDisabled( g_isViewingMode )
			end
		end

		-------------------------------------------
		-- City Banner
		-------------------------------------------

		-- Update capital icon
		local isCapital = city:IsCapital()
		Controls.CityCapitalIcon:SetHide( not isCapital )

		-- Connected to capital?
		Controls.CityIsConnected:SetHide( isCapital or city:IsBlockaded() or not cityOwner:IsCapitalConnectedToCity(city) or city:GetTeam() ~= Game.GetActiveTeam() )

		-- Blockaded
		Controls.CityIsBlockaded:SetHide( not city:IsBlockaded() )

		-- Being Razed
		if city:IsRazing() then
			Controls.CityIsRazing:SetHide(false)
			Controls.CityIsRazing:LocalizeAndSetToolTip("TXT_KEY_CITY_BURNING", city:GetRazingTurns())
		else
			Controls.CityIsRazing:SetHide(true)
		end

		-- Puppet Status
		Controls.CityIsPuppet:SetHide( not city:IsPuppet() )

		-- In Resistance
		if city:IsResistance() then
			Controls.CityIsResistance:SetHide(false)
			Controls.CityIsResistance:LocalizeAndSetToolTip("TXT_KEY_CITY_RESISTANCE", city:GetResistanceTurns())
		else
			Controls.CityIsResistance:SetHide(true)
		end

		-- Occupation Status
--todo BE
		Controls.CityIsOccupied:SetHide( not( civ5_mode and city:IsOccupied() and not city:IsNoOccupiedUnhappiness() ) )

		local cityName = Locale.ToUpper( city:GetName() )

		if city:IsRazing() then
			cityName = cityName .. " (" .. L"TXT_KEY_BURNING" .. ")"
		end

		local size = isCapital and Controls.CityCapitalIcon:GetSizeX() or 0
		Controls.CityNameTitleBarLabel:SetOffsetX( size / 2 )
		TruncateString( Controls.CityNameTitleBarLabel, math_abs(Controls.NextCityButton:GetOffsetX()) * 2 - Controls.NextCityButton:GetSizeX() - size, cityName )

		Controls.Defense:SetText( math_floor( city:GetStrengthValue() / 100 ) )

 		CivIconHookup( cityOwnerID, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true )

		-------------------------------------------
		-- City Damage
		-------------------------------------------
		local cityDamage = city:GetDamage()
		if cityDamage > 0 then
			local cityHealthPercent = 1 - cityDamage / ( gk_mode and city:GetMaxHitPoints() or GameDefines.MAX_CITY_HIT_POINTS )

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
		local cityPopulation = math_floor(city:GetPopulation())
		Controls.CityPopulationLabel:SetText(tostring(cityPopulation))
		Controls.PeopleMeter:SetPercent( city:GetFood() / city:GrowthThreshold() )

		--Update suffix to use correct plurality.
		Controls.CityPopulationLabelSuffix:LocalizeAndSetText( "TXT_KEY_CITYVIEW_CITIZENS_TEXT", cityPopulation )
		
		-- CITY POP FORMAT FUNCTION
		local function FormatNumber( n )
			local absN = math.abs( n )
			if absN >= 1e9 then
				return string.format( "%.1fB", n / 1e9 )
			elseif absN >= 1e6 then
				return string.format( "%.1fM", n / 1e6 )
			elseif absN >= 1e3 then
				return string.format( "%.1fK", n / 1e3 )
			else
				return string.format( "%d", math.floor( n + 0.5 ) )
			end
		end


		-- CITY POP IN MILLIONS
		local cityPopMil = math.floor( 1000 * cityPopulation ^ 2.8 + 0.5 )

		Controls.CityPop:SetText(FormatNumber(cityPopMil))
		Controls.CityPopSuffix:LocalizeAndSetText( "TXT_KEY_POPS_MIL", cityPopulation )

		-------------------------------------------
		-- Citizen Focus & Slackers
		-------------------------------------------

		Controls.AvoidGrowthButton:SetCheck( city:IsForcedAvoidGrowth() )

		local slackerCount = city:GetSpecialistCount( GameDefines.DEFAULT_SPECIALIST )

		local focusType = city:GetFocusType()
		if focusType == CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE then
			Controls.BalancedFocusButton:SetCheck( true )
		elseif focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD then
			Controls.FoodFocusButton:SetCheck( true )
		elseif focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION then
			Controls.ProductionFocusButton:SetCheck( true )
		elseif focusType == g_focusCurrency then
			Controls.GoldFocusButton:SetCheck( true )
		elseif focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE then
			Controls.ResearchFocusButton:SetCheck( true )
		elseif focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE then
			Controls.CultureFocusButton:SetCheck( true )
		elseif focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE then
			Controls.GPFocusButton:SetCheck( true )
		elseif gk_mode and focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH then
			Controls.FaithFocusButton:SetCheck( true )
		else
			Controls.BalancedFocusButton:SetCheck( true )
		end
		if city:GetNumForcedWorkingPlots() > 0 or slackerCount > 0 then
			Controls.ResetButton:SetHide( false )
			Controls.ResetFooter:SetHide( false )
		else
			Controls.ResetButton:SetHide( true )
			Controls.ResetFooter:SetHide( true )
		end

		g_SlackerIM.ResetInstances()
		for i = 1, slackerCount do
			local instance = g_SlackerIM.GetInstance()
			local slot = instance.Button
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

		-------------------------------------------
		-- Great Person Meters
		-------------------------------------------
		if false then
			g_GreatPeopleIM.ResetInstances()
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

					if bnw_mode then
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
						local instance = g_GreatPeopleIM.GetInstance()
						local percent = gpProgress / gpThreshold
						instance.GPMeter:SetPercent( percent )
						local labelText = L(unitClass.Description)
						local icon = GreatPeopleIcon(gpuClass)
						local tips = table( "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( labelText ) .. "[ENDCOLOR]"
									.. " " .. gpProgress .. icon .." / " .. gpThreshold .. icon )
	--					tips:insert( L( "TXT_KEY_PROGRESS_TOWARDS", "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( labelText ) .. "[ENDCOLOR]" )
						if gpChange > 0 then
							local gpTurns = math_ceil( (gpThreshold - gpProgress) / gpChange )
							tips:insert( "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", gpTurns ) ) .. "[ENDCOLOR]  "
										 .. gpChange .. icon .. " " .. L"TXT_KEY_GOLD_PERTURN_HEADING4_TITLE" )
							labelText = labelText .. ": " .. Locale.ToLower( L( "TXT_KEY_STR_TURNS", gpTurns ) )
						end
						instance.GreatPersonLabel:SetText( icon .. labelText )
						if gk_mode then
							if gpChangePlayerMod ~= 0 then
								tips:insert( L( "TXT_KEY_PLAYER_GP_MOD", gpChangePlayerMod ) )
							end
							if gpChangePolicyMod ~= 0 then
								tips:insert( L( "TXT_KEY_POLICY_GP_MOD", gpChangePolicyMod ) )
							end
							if gpChangeCityMod ~= 0 then
								tips:insert( L( "TXT_KEY_CITY_GP_MOD", gpChangeCityMod ) )
							end
							if gpChangeGoldenAgeMod ~= 0 then
								tips:insert( L( "TXT_KEY_GOLDENAGE_GP_MOD", gpChangeGoldenAgeMod ) )
							end
							if gpChangeWorldCongressMod ~= 0 then
								if gpChangeWorldCongressMod < 0 then
									tips:insert( L( "TXT_KEY_WORLD_CONGRESS_NEGATIVE_GP_MOD", gpChangeWorldCongressMod ) )
								else
									tips:insert( L( "TXT_KEY_WORLD_CONGRESS_POSITIVE_GP_MOD", gpChangeWorldCongressMod ) )
								end
							end
						elseif gpChangeMod ~= 0 then
							tips:insert( "[ICON_BULLET] "..gpChangeMod..icon )
						end
						instance.GPBox:SetToolTipString( tips:concat("[NEWLINE]") )
						instance.GPBox:SetVoid1( unitClass.ID )
						instance.GPBox:RegisterCallback( Mouse.eRClick, UnitClassPedia )

						local portraitOffset, portraitAtlas = UI_GetUnitPortraitIcon( GameInfoTypes[ unitClass.DefaultUnit ], cityOwnerID )
						instance.GPImage:SetHide(not IconHookup( portraitOffset, 64, portraitAtlas, instance.GPImage ) )
					end
				end
			end
			g_GreatPeopleIM.Commit()
		end

		-------------------------------------------
		-- Buildings
		-------------------------------------------

		local greatWorkBuildings = table()
		local specialistBuildings = table()
		local wonders = table()
		local otherBuildings = table()
		local noWondersWithSpecialistInThisCity = true

		for building in GameInfo.Buildings() do
			local buildingID = building.ID
			if city:IsHasBuilding(buildingID) then
				local buildingClass = GameInfo.BuildingClasses[ building.BuildingClass ]
				local buildings
				local greatWorkCount = civ5bnw_mode and building.GreatWorkCount or 0
				local areSpecialistsAllowedByBuilding = city:GetNumSpecialistsAllowedByBuilding(buildingID) > 0

				if buildingClass.MaxGlobalInstances > 0
				or buildingClass.MaxTeamInstances > 0
				or ( buildingClass.MaxPlayerInstances == 1 and not areSpecialistsAllowedByBuilding )
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
					buildings:insert{ building, L(building.Description), greatWorkCount, areSpecialistsAllowedByBuilding and GameInfoTypes[building.SpecialistType] or 999 }
				end
			end
		end
		local strMaintenanceTT = L( "TXT_KEY_BUILDING_MAINTENANCE_TT", city:GetTotalBaseBuildingMaintenance() )
		Controls.SpecialBuildingsHeader:SetToolTipString(strMaintenanceTT)
		Controls.BuildingsHeader:SetToolTipString(strMaintenanceTT)
		Controls.GreatWorkHeader:SetToolTipString(strMaintenanceTT)
		Controls.SpecialistControlBox:SetHide( #specialistBuildings < 1 )
		Controls.SpecialistControlBox2:SetHide( noWondersWithSpecialistInThisCity )

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
				Controls.ResourceDemandedString:LocalizeAndSetText( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED", resourceInfo.IconString .. " " .. L(resourceInfo.Description) )
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

			elseif city:IsPuppet() and not(bnw_mode and cityOwner:MayNotAnnex()) then

				-- We can annex this city
				taskID = TaskTypes.TASK_ANNEX_PUPPET
				buttonLabel = L"TXT_KEY_POPUP_ANNEX_CITY"
-- todo
				if civ5_mode then
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
		CityTaskButton:SetVoids( cityID, taskID )
		CityTaskButton:SetToolTipString( buttonToolTip )
		CityTaskButton:SetDisabled( not taskID )
		CityTaskButton:SetHide( not buttonLabel )

		UpdateWorkingHexesNow()
		UpdateCityProductionQueueNow( city, cityID, cityOwnerID, isActivePlayerCity and not isCityCaptureViewingMode and civ5_mode and bnw_mode and cityOwner:MayNotAnnex() and city:IsPuppet() )

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
		local cultureDiff = cultureNext - cultureStored
		if culturePerTurn > 0 then
			local cultureTurns = math_max(math_ceil(cultureDiff / culturePerTurn), 1)
			Controls.CultureTimeTillGrowthLabel:LocalizeAndSetText( "TXT_KEY_CITYVIEW_TURNS_TILL_TILE_TEXT", cultureTurns )
			Controls.CultureTimeTillGrowthLabel:SetHide( false )
		else
			Controls.CultureTimeTillGrowthLabel:SetHide( true )
		end
		local percentComplete = cultureStored / cultureNext
		Controls.CultureMeter:SetPercent( percentComplete )

		if gk_mode then
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

		Controls.BalancedFocusButton:SetDisabled( g_isViewingMode )
		Controls.FoodFocusButton:SetDisabled( g_isViewingMode )
		Controls.ProductionFocusButton:SetDisabled( g_isViewingMode )
		Controls.GoldFocusButton:SetDisabled( g_isViewingMode )
		Controls.ResearchFocusButton:SetDisabled( g_isViewingMode )
		Controls.CultureFocusButton:SetDisabled( g_isViewingMode )
		Controls.GPFocusButton:SetDisabled( g_isViewingMode )

		Controls.AvoidGrowthButton:SetDisabled( g_isViewingMode )
		Controls.ResetButton:SetDisabled( g_isViewingMode )

		Controls.BoxOSlackers:SetDisabled( g_isViewingMode )

		Controls.EditButton:SetHide( g_isViewingMode )
	end
end

local function UpdateStuffBody()
	if g_isCityViewDirty then
		UpdateCityViewNow()
	end
	if g_isCityHexesDirty then
		UpdateWorkingHexesNow()
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
local function UpdateWorkingHexes()
	g_isCityHexesDirty = true
	return ContextPtr:SetUpdate( UpdateStuffNow )
end

local function UpdateOptionsAndCityView()
	g_isAdvisor = not ( g_options and g_options.GetValue and g_options.GetValue( "CityAdvisor" ) == 0 )
	g_isAutoClose = not ( g_options and g_options.GetValue and g_options.GetValue( "AutoClose" ) == 0 )
	--g_FocusSelectIM.Collapse( not OptionsManager.IsNoCitizenWarning() )
	g_FocusSelectIM.Collapse( false )
	Controls.BuyPlotCheckBox:SetCheck( g_BuyPlotMode )
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
g_CivilianSelectIM = StackInstanceManager( "SelectionInstance", "Button", Controls.CivilianButtonStack, Controls.CivilianButton, ResizeProdQueue )
g_BuildingSelectIM	= StackInstanceManager( "SelectionInstance", "Button", Controls.BuildingButtonStack, Controls.BuildingsButton, ResizeProdQueue )
g_WonderSelectIM	= StackInstanceManager( "SelectionInstance", "Button", Controls.WonderButtonStack, Controls.WondersButton, ResizeProdQueue )
g_ProcessSelectIM	= StackInstanceManager( "SelectionInstance", "Button", Controls.OtherButtonStack, Controls.OtherButton, ResizeProdQueue )
g_FocusSelectIM		= StackInstanceManager( "", "", Controls.WorkerManagementBox, Controls.WorkerHeader, function(self, collapsed) g_workerHeadingOpen = not collapsed ResizeRightStack() UpdateWorkingHexes() end, true, false )

local function SetToolTipString( toolTipFunc )
	g_leftTipControls.Text:SetText( toolTipFunc( UI_GetHeadSelectedCity() ) )
	g_leftTipControls.PortraitFrame:SetHide( true )
	return g_leftTipControls.Box:DoAutoSize()
end

local g_toolTips = {
	ProdBox = function()
		return SetToolTipString( GetProductionTooltip )
	end,
	FoodBox = function()
		return SetToolTipString( GetFoodTooltip )
	end,
	GoldBox = function()
		return SetToolTipString( GetGoldTooltip )
	end,
	ScienceBox = function()
		return SetToolTipString( GetScienceTooltip )
	end,
	CultureBox = function()
		return SetToolTipString( GetCultureTooltip )
	end,
	FaithBox = function()
		return SetToolTipString( GetFaithTooltip )
	end,
	TourismBox = function()
		return SetToolTipString( GetTourismTooltip )
	end,
	ProductionPortraitButton = ProductionToolTip
}
g_toolTips.PopulationBox = g_toolTips.FoodBox
Controls.ProductionPortraitButton:SetVoid1(0)

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
				Option2 = false
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
					Text = button:GetToolTipString()
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
	NoButton = {
		[Mouse.eLClick] = CancelBuildingSale,
	},
	NextCityButton = {
		[Mouse.eLClick] = GotoNextCity,
	},
	PrevCityButton = {
		[Mouse.eLClick] = GotoPrevCity,
	},
	ReturnToMapButton = {
		[Mouse.eLClick] = ExitCityScreen,
	},
	ProductionPortraitButton = {
		[Mouse.eRClick] = ProductionPedia,
	},
	BoxOSlackers = {
		[Mouse.eLClick] = OnSlackersSelected,
	},
	ResetButton = {
		[Mouse.eLClick] = PlotButtonClicked,
	},
	NoAutoSpecialistCheckbox = {
		[Mouse.eLClick] = function()
			return Game.SelectedCitiesGameNetMessage(GameMessageTypes.GAMEMESSAGE_DO_TASK, TaskTypes.TASK_NO_AUTO_ASSIGN_SPECIALISTS, -1, -1, not UI_GetHeadSelectedCity():IsNoAutoAssignSpecialists() )
		end,
	},
	EditButton = {
		[Mouse.eLClick] = RenameCity,
	},
	CityNameTitleBarLabel = {
		[Mouse.eRClick] = RenameCity,
	},
}
g_callBacks.NoAutoSpecialistCheckbox2 = g_callBacks.NoAutoSpecialistCheckbox

--Controls.ResetButton:SetVoid1( 0 )	-- calling with 0 = city center causes reset of all forced tiles
--Controls.BoxOSlackers:SetVoids(-1,-1)
--Controls.ProductionPortraitButton:SetVoid1( 0 )
Controls.BalancedFocusButton:SetVoid1( CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE )
Controls.FoodFocusButton:SetVoid1( CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD )
Controls.ProductionFocusButton:SetVoid1( CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION )
Controls.GoldFocusButton:SetVoid1( g_focusCurrency )
Controls.ResearchFocusButton:SetVoid1( CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE )
Controls.CultureFocusButton:SetVoid1( CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE )
Controls.GPFocusButton:SetVoid1( CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE )
if gk_mode then
	Controls.FaithFocusButton:SetVoid1( CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH )
end
Controls.GPFocusButton:SetHide( civBE_mode )
Controls.FaithBox:SetHide( civBE_mode or not gk_mode )
--Controls.GPFocusButton:SetHide( true )
--Controls.FaithFocusButton:SetHide( true )

Controls.FaithFocusButton:SetHide( civBE_mode or not gk_mode )

--Controls.TourismBox:SetHide( not civ5bnw_mode )
Controls.TourismBox:SetHide( true )
Controls.GPHeader:SetHide( true )
Controls.GPStack:SetHide( true )

SetupCallbacks( Controls, g_toolTips, "EUI_CityViewLeftTooltip", g_callBacks )

Controls.BuyPlotCheckBox:RegisterCheckHandler( function( isChecked ) -- Void1, Void2, control )
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
Events.SerialEventCityHexHighlightDirty.Add( UpdateWorkingHexes )
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

--	local city = UI_GetHeadSelectedCity()
--	if city then
--		Network.SendUpdateCityCitizens( city:GetID() )
--	end

	LuaEvents.TryQueueTutorial("CITY_SCREEN", true)

	g_queuedItemNumber = false
	g_previousCity = false
--TODO other scroll panels
	Controls.RightScrollPanel:SetScrollValue(0)
end)

-------------------------
-- Exit City Screen Event
Events.SerialEventExitCityScreen.Add(
function()
	Events.ClearHexHighlights()

	-- We may get here after a player change, clear the UI if this is not the active player's city
	local city = UI_GetHeadSelectedCity()
	if not city or city:GetOwner() ~= g_activePlayerID then
		ClearCityUIInfo()
	end
	UI.ClearSelectedCities()
	LuaEvents.TryDismissTutorial("CITY_SCREEN")

	CancelBuildingSale()

	-- Try and re-select the last unit selected
	if not UI.GetHeadSelectedUnit() then
		local unit = UI.GetLastSelectedUnit()
		if unit and unit:MovesLeft() > 0 then
			UI.SelectUnit( unit )
			UI.LookAtSelectionPlot()
		end
	end
	g_isViewingMode = true
	return UI.SetCityScreenViewingMode(false)
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
		g_previousCity = false
		return UpdateCityView()
	end)
end
--------------------------------------------
-- 'Active' (local human) player has changed
Events.GameplaySetActivePlayer.Add(
function( activePlayerID )--, previousActivePlayerID )
	g_activePlayerID = activePlayerID
	g_activePlayer = Players[ g_activePlayerID ]
	g_finishedItems = {}
	ClearCityUIInfo()
	if UI.IsCityScreenUp() then
		return ExitCityScreen()
	end
end)

Events.ActivePlayerTurnEnd.Add(
function()
	g_finishedItems = {}
end)

Events.SerialEventGameMessagePopup.Add(
function( popupInfo )
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
			g_isButtonPopupChooseProduction = true
			return UI.DoSelectCityAtPlot( city:Plot() )	-- open city screen
		end
	end
end)

Events.NotificationAdded.Add(
function( notificationID, notificationType, toolTip, strSummary, data1, data2, playerID )
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
print("Finished loading EUI city view",os.clock())
end)

---------------------------------
-- Support for Modded Add-in UI's
---------------------------------
local g_uiAddins = {}
for addin in Modding.GetActivatedModEntryPoints("CityViewUIAddin") do
	local addinFile = Modding.GetEvaluatedFilePath(addin.ModID, addin.Version, addin.File)
	local addinPath = addinFile.EvaluatedPath

	-- Get the absolute path and filename without extension.
	local extension = Path.GetExtension(addinPath)
	local ok, result = pcall( ContextPtr.LoadNewContext, ContextPtr, addinPath:sub( 1, #addinPath - #extension ) )
	if ok then
		table.insert( g_uiAddins, result )
	else
		print( addinPath, result )
	end
end

--Controls.CultureFocusButton:SetHide( true )
Controls.WorkerHeader:SetHide( true )
--Controls.GPFocusButton:SetHide( true )
--Controls.FaithFocusButton:SetHide( true )