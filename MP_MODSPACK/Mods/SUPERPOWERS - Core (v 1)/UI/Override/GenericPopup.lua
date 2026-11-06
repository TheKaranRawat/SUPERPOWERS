--==========================================================
-- Generic Popups
-- Re-written by bc1 using Notepad++
--==========================================================

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query

include "IconHookup"
local IconHookup = IconHookup

--==========================================================
-- Minor lua optimizations
--==========================================================

local pairs = pairs
local table = table
local print = print
local type = type

local UIManager = UIManager
local ContextPtr = ContextPtr
local Events = Events
local UI = UI
local Controls = Controls
local Mouse = Mouse
local PopupPriority = PopupPriority
local KeyEvents = KeyEvents
local Keys = Keys
local INTERFACEMODE_SELECTION = InterfaceModeTypes.INTERFACEMODE_SELECTION
local SetInterfaceMode = UI.SetInterfaceMode

PopupLayouts = {}
PopupInputHandlers = {}
local PopupLayouts = PopupLayouts
local PopupInputHandlers = PopupInputHandlers
local mostRecentPopup
local specializedInputHandler
local buttonList = {}
local buttonIndex = 0
local canEscape
local MajorPopups = {}
local PopupContexts = ButtonPopupTypes and {
	AdvisorCounselPopup = ButtonPopupTypes.BUTTONPOPUP_ADVISOR_COUNSEL,
	AdvisorInfoPopup = ButtonPopupTypes.BUTTONPOPUP_ADVISOR_INFO,
	AdvisorModal = ButtonPopupTypes.BUTTONPOPUP_ADVISOR_MODAL,
	ChooseAdmiralNewPort = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_ADMIRAL_PORT,
	ChooseArchaeology = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_ARCHAEOLOGY,
	ChooseFaithGreatPerson = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_FAITH_GREAT_PERSON,
	ChooseFreeItem = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_FREE_GREAT_PERSON,
	ChooseGoodyHutRewardPopup = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_GOODY_HUT_REWARD,
	ChooseIdeology = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_IDEOLOGY,
	ChooseInternationalTradeRoute = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_INTERNATIONAL_TRADE_ROUTE,
	ChooseMayaBonus	= ButtonPopupTypes.BUTTONPOPUP_CHOOSE_MAYA_BONUS,
	ChoosePantheon = ButtonPopupTypes.BUTTONPOPUP_FOUND_PANTHEON,
	ChooseReligion = ButtonPopupTypes.BUTTONPOPUP_FOUND_RELIGION,
	ChooseTradeRouteNewHome = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TRADE_UNIT_NEW_HOME,
	CityStateDiploPopup = ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO,
	CityStateGreetingPopup = { ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_GREETING, ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_MESSAGE },
	CultureOverview = ButtonPopupTypes.BUTTONPOPUP_CULTURE_OVERVIEW,
	DeclareWarPopup = { ButtonPopupTypes.BUTTONPOPUP_DECLAREWARMOVE, ButtonPopupTypes.BUTTONPOPUP_DECLAREWARRANGESTRIKE, ButtonPopupTypes.BUTTONPOPUP_DECLAREWAR_PLUNDER_TRADE_ROUTE },
	Demographics = ButtonPopupTypes.BUTTONPOPUP_DEMOGRAPHICS,
	EndGameDemographics = {}, --ButtonPopupTypes.BUTTONPOPUP_DEMOGRAPHICS,-- duplicate but it doesn't need to be hooked up anyway
	DiploList = ButtonPopupTypes.BUTTONPOPUP_DIPLOMACY,
	DiploOverview = ButtonPopupTypes.BUTTONPOPUP_DIPLOMATIC_OVERVIEW,
	DiploVotePopup = ButtonPopupTypes.BUTTONPOPUP_DIPLO_VOTE,
	EconomicOverview = ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW,
	EspionageOverview = ButtonPopupTypes.BUTTONPOPUP_ESPIONAGE_OVERVIEW,
	GreatPersonRewardPopup = ButtonPopupTypes.BUTTONPOPUP_GREAT_PERSON_REWARD,
	GreatWorkSplash = ButtonPopupTypes.BUTTONPOPUP_GREAT_WORK_COMPLETED_ACTIVE_PLAYER,
	LeagueOverviewPopup = ButtonPopupTypes.BUTTONPOPUP_LEAGUE_OVERVIEW,
	LeagueProjectPopup = ButtonPopupTypes.BUTTONPOPUP_LEAGUE_PROJECT_COMPLETED,
	MilitaryOverview = ButtonPopupTypes.BUTTONPOPUP_MILITARY_OVERVIEW,
	NotificationLogPopup = ButtonPopupTypes.BUTTONPOPUP_NOTIFICATION_LOG,
	ProductionPopup = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
	ReligionOverview = ButtonPopupTypes.BUTTONPOPUP_RELIGION_OVERVIEW,
	SocialPolicyPopup = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY,
	TechAwardPopup = ButtonPopupTypes.BUTTONPOPUP_TECH_AWARD,
	TechPanel = {}, --ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH, -- prevents tech info panel from hooking up to popup events and open automatically
--	TechPopup = ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH,-- this panel is deleted in EUI
--	TechTree = ButtonPopupTypes.BUTTONPOPUP_TECH_TREE,
	TradeRouteOverview = ButtonPopupTypes.BUTTONPOPUP_TRADE_ROUTE_OVERVIEW,
	VictoryProgress = ButtonPopupTypes.BUTTONPOPUP_VICTORY_INFO,
	VoteResultsPopup = ButtonPopupTypes.BUTTONPOPUP_VOTE_RESULTS,
	WhosWinningPopup = ButtonPopupTypes.BUTTONPOPUP_WHOS_WINNING,
	WonderPopup = ButtonPopupTypes.BUTTONPOPUP_WONDER_COMPLETED_ACTIVE_PLAYER,
} or {}

LuaEvents.AddSerialEventGameMessagePopup.Add( function( ... )
	for _, popupType in pairs{...} do
		MajorPopups[ popupType ] = LuaEvents[ popupType ].Call
	end
end)
LuaEvents.QuerySerialEventGameMessagePopup.Add( function( ContextPtr )
	local popups = PopupContexts[ ContextPtr:GetID() ]
	if popups then
		LuaEvents["PopupTypesFor"..ContextPtr:GetID()]( tonumber(popups) and {popups} or popups )
	end
end)

-- Hide popup window
function HideWindow()
	specializedInputHandler = nil
    UIManager:DequeuePopup( ContextPtr )
	if mostRecentPopup then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate( mostRecentPopup, 0 )
		UI.decTurnTimerSemaphore()
		mostRecentPopup = nil	
	end
end

local function SetControlText( control, text, width )
	control:SetText( text )
	control:SetWrapWidth( width or 440 )
end

local function SetControlImage( control, a, b, atlas, d )
	if atlas then
		control:SetSizeVal( a, a )
		control:SetTextureSizeVal( a, a )
		control:SetOffsetY( d or 0 )
		control:SetHide( not IconHookup( b, a, atlas, control ) )
	elseif a then
		control:SetTextureOffsetVal( 0, 0 )
		control:SetTextureAndResize( a )
		control:SetOffsetY( b or 0 )
		control:SetHide( false )
	else
		control:SetHide( true )
	end
end

function SetTopIcon( ... )
	Controls.GenericAnim:SetHide( true )
	return SetControlImage( Controls.Icon, ... )
end
function SetTopImage( ... )
	Controls.Icon:SetHide( true )
	Controls.GoldenAgeAnim:SetHide( true )
	return SetControlImage( Controls.TopImage, ... )
end
function SetImage( ... )
	return SetControlImage( Controls.Image, ... )
end
function SetBottomImage( ... )
	return SetControlImage( Controls.BottomImage, ... )
end
-- Set popup title
function SetPopupTitle( ... )
	return SetControlText( Controls.Title, ... )
end
-- Set popup text
function SetPopupText( ... )
	return SetControlText( Controls.PopupText, ... )
end

-- Add a button to popup
function AddButton( buttonText, buttonClickFunc, strToolTip, bPreventClose )
	buttonIndex = buttonIndex + 1
	local button = buttonList[ buttonIndex ]
	if button then
		button:SetHide( false )
	else
		button = {}
		ContextPtr:BuildInstanceForControl( "Button", button, Controls.Stack )
		button = button.Button
		buttonList[ buttonIndex ] = button
	end
	button:SetText( buttonText )
	button:SetToolTipString( strToolTip )
--	button:SetDisabled( false )
	-- By default, button clicks will hide the popup window after executing the click function
	-- This ugly kludge is only used in one case: when viewing a captured city (PuppetCityPopup)
	if not buttonClickFunc then
		button:RegisterCallback( Mouse.eLClick, HideWindow )
		canEscape = true
	elseif bPreventClose then
		button:RegisterCallback( Mouse.eLClick, buttonClickFunc )
	else
		button:RegisterCallback( Mouse.eLClick, function() buttonClickFunc() return HideWindow() end )
	end
	return button
end

-------------------------------------------------
-- Popup Initializers
L = Locale.ConvertTextKey
local files = include( "InGame\\PopupsGeneric\\%w+%.lua$", true )
PopupLayouts[-1] = nil
PopupInputHandlers[-1] = nil
--table.sort( files )
--print( "Loaded", #files, "files for", n, "popups\n", ("="):rep(80), "\n", table.concat( files, "\n\t" ), "\n", ("="):rep(80) )

-------------------------------------------------
-- Event Handlers
Events.SerialEventGameMessagePopup.Add( function( popupInfo )
	local func = MajorPopups[ popupInfo.Type ]
	if func then
		return func( popupInfo )
	else
		func = PopupLayouts[ popupInfo.Type ]
		if func and ContextPtr:IsHidden() then
			-- Clear popup
			for _, button in pairs( buttonList ) do
				button:SetHide( true )
			end
			buttonIndex = 0
			Controls.Title:SetText()
			Controls.PopupText:SetText()
			Controls.CloseButton:SetHide( true )
			Controls.Image:SetHide( true )
			Controls.BottomImage:SetHide( true )
			Controls.Editing:SetHide( true )
			SetTopImage( "Top512IconTrim.dds", -14 )
			SetTopIcon( "NotificationFrameBase.dds", -6 )
			Controls.GenericAnim:SetHide( false )
			canEscape = false
			-- Initialize popup
			if func( popupInfo ) ~= false then
				-- Resize popup
				Controls.Stack:CalculateSize()
				Controls.Grid:DoAutoSize()
				-- Show popup
				UIManager:QueuePopup( ContextPtr, PopupPriority.GenericPopup )
				Events.SerialEventGameMessagePopupShown( popupInfo )
				UI.incTurnTimerSemaphore()
				mostRecentPopup = popupInfo.Type
				specializedInputHandler = PopupInputHandlers[ mostRecentPopup ]
			end
		end
	end
end)

do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam, lParam )
		if specializedInputHandler then
			specializedInputHandler( uiMsg, wParam, lParam )
		elseif canEscape and uiMsg == KeyDown and (wParam == VK_ESCAPE or wParam == VK_RETURN) then
			HideWindow()
		end
		return true
	end)
end

Controls.CloseButton:RegisterCallback( Mouse.eLClick, HideWindow )
Events.GameplaySetActivePlayer.Add( HideWindow )
