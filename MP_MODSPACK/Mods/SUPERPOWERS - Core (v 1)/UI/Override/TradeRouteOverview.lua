--==========================================================
-- Religion Overview Popup
-- Modified by bc1 from 1.0.3.276 code using Notepad++
--==========================================================

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfo = GameInfoCache

include "IconHookup"
local CivIconHookup = CivIconHookup

include "TradeRouteHelpers"
local BuildTradeRouteToolTipString = BuildTradeRouteToolTipString

--==========================================================
-- Minor lua optimizations
--==========================================================

local ipairs = ipairs
local pairs = pairs
local sort = table.sort
local tonumber = tonumber
local insert = table.insert
local remove = table.remove

local ContextPtr = ContextPtr
local Controls = Controls
local DomainTypes = DomainTypes
local Events = Events
local Game = Game
local KeyDown = KeyEvents.KeyDown
local Keys = Keys
local Locale = Locale
local Mouse = Mouse
local Players = Players
local PopupPriority = PopupPriority
local UI = UI
local UIManager = UIManager
local BUTTONPOPUP_TRADE_ROUTE_OVERVIEW = ButtonPopupTypes.BUTTONPOPUP_TRADE_ROUTE_OVERVIEW

-------------------------------------------------
-- Global Variables
-------------------------------------------------
local g_PopupInfo
local g_CurrentTab = 1	-- The currently selected Tab : your TR
local g_instances = {}
local g_routes = {}

local g_Tabs = {
	{
		Button = Controls.TabButtonYourTR,
		SelectHighlight = Controls.YourTRSelectHighlight,
		Content = Players[0].GetTradeRoutes,
	},
	{
		Button = Controls.TabButtonAvailableTR,
		SelectHighlight = Controls.AvailableTRSelectHighlight,
		Content = Players[0].GetTradeRoutesAvailable,
	},
	{
		Button = Controls.TabButtonTRWithYou,
		SelectHighlight = Controls.TRWithYouSelectHighlight,
		Content = Players[0].GetTradeRoutesToYou,
	},
}

local g_filterControls = { Domain = Controls.Domain, FromCiv = Controls.FromOwnerHeader, FromCityName = Controls.FromCityHeader, ToCiv = Controls.ToOwnerHeader, ToCityName = Controls.ToCityHeader }
local g_filtersActive = {}

local g_SortOptions = {
	{
		Button = Controls.FromGPT,
		Column = "FromGPT",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.FromScience,
		Column = "FromScience",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.ToFood,
		Column = "ToFood",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.ToProduction,
		Column = "ToProduction",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.ToOwnerHeader,
		Column = "ToCiv",
		Ascending = true,
	},
	{
		Button = Controls.ToCityHeader,
		Column = "ToCityName",
		Ascending = true,
	},
	{
		Button = Controls.FromOwnerHeader,
		Column = "FromCiv",
		Ascending = true,
	},
	{
		Button = Controls.FromCityHeader,
		Column = "FromCityName",
		Ascending = true,
	},
	{
		Button = Controls.ToGPT,
		Column = "ToGPT",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.ToScience,
		Column = "ToScience",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.ToReligion,
		Column = "ToReligion",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.FromReligion,
		Column = "FromReligion",
		Ascending = false,
		Numeric = true,
	},
	{
		Button = Controls.Domain,
		Column = "Domain",
		Ascending = true,
	},
	{
		Button = Controls.TurnsLeft,
		Column = "TurnsLeft",
		Ascending = false,
		Numeric = true,
	},
};

-------------------------------------------------------------------------------
-- Sorting Support
-------------------------------------------------------------------------------

local function OnClose()
	UIManager:DequeuePopup( ContextPtr )
end

local function SetTooltip( i, _, control )
	local v = g_routes[i]
	control:SetToolTipString( BuildTradeRouteToolTipString(Players[v.FromID], v.FromCity, v.ToCity, v.Domain ) )
end

local function SortAndDisplayData()
	sort( g_routes,
		function(a,b)
			local t = g_SortOptions
			local ti, x, y
			for i = 1, #t do
				ti = t[i]
				x = a[ti.Column]
				y = b[ti.Column]
				if x~=y then
					return x<y == ti.Ascending
				end
			end
		end)
--	Controls.MainStack:DestroyAllChildren()
	local v, instance, religion
	for i = 1, #g_routes do
		instance = g_instances[i]
		v = g_routes[i]
		if instance then
			instance.Root:SetHide( false )
		else
			instance = {}
			ContextPtr:BuildInstanceForControl( "TRInstance", instance, Controls.MainStack )
			instance.Root:SetVoid1(i)
			instance.Root:RegisterCallback( Mouse.eMouseEnter, SetTooltip )
			g_instances[i] = instance
		end

--[[
"Domain", "FromCivilizationType", "FromID", "FromCityName", "FromCity", "ToCivilizationType", "ToID", "ToCityName", "ToCity", "FromGPT", "ToGPT", "ToFood", "ToProduction", "FromScience", "ToScience", "ToReligion", "ToPressure", "FromReligion", "FromPressure", "FromTourism", "ToTourism", "TurnsLeft"
--]]

		instance.Domain_Land:SetHide( v.Domain ~= DomainTypes.DOMAIN_LAND )
		instance.Domain_Sea:SetHide( v.Domain ~= DomainTypes.DOMAIN_SEA )

		CivIconHookup(v.FromID, 32, instance.FromCivIcon, instance.FromCivIconBG, instance.FromCivIconShadow, false, true, instance.FromCivIconHighlight);
		instance.FromCivIcon:SetToolTipString( Players[ v.FromID ]:GetCivilizationShortDescription() )
		instance.FromCity:SetText(v.FromCityName);

		CivIconHookup(v.ToID, 32, instance.ToCivIcon, instance.ToCivIconBG, instance.ToCivIconShadow, false, true, instance.ToCivIconHighlight);
		instance.ToCivIcon:SetToolTipString( Players[ v.ToID ]:GetCivilizationShortDescription() )
		instance.ToCity:SetText(v.ToCityName);

		instance.ToGPT:SetText( v.ToGPT ~= 0 and Locale.ConvertTextKey("TXT_KEY_TRO_GPT_ENTRY",  v.ToGPT / 100) )

		instance.FromGPT:SetText( v.FromGPT ~= 0 and v.FromGPT / 100 )
		instance.ToFood:SetText( v.ToFood ~= 0 and v.ToFood / 100 )
		instance.ToProduction:SetText( v.ToProduction ~= 0 and v.ToProduction / 100 )

		religion = GameInfo.Religions[v.ToReligion] or {}
		instance.ToReligion:SetText( v.ToReligion > 0 and v.ToPressure ~= 0 and Locale.ConvertTextKey("TXT_KEY_TRO_RELIGIOUS_PRESSURE_ENTRY", religion.IconString or "??", v.ToPressure) )

		religion = GameInfo.Religions[v.FromReligion] or {}
		instance.FromReligion:SetText( v.FromReligion > 0 and v.FromPressure ~= 0 and Locale.ConvertTextKey("TXT_KEY_TRO_RELIGIOUS_PRESSURE_ENTRY", religion.IconString or "??", v.FromPressure) )

		local fromScience, toScience
		if v.FromID ~= v.ToID then
			if v.FromScience ~= 0 then
				fromScience = v.FromScience / 100
			end
			if v.ToScience ~= 0 then
				toScience = v.ToScience / 100
			end
		end
		instance.FromScience:SetText(fromScience);
		instance.ToScience:SetText(toScience);

		instance.TurnsLeft:SetText( v.TurnsLeft and v.TurnsLeft >= 0 and v.TurnsLeft )
	end
	for i = #g_routes+1, #g_instances do
		g_instances[i].Root:SetHide( true )
	end
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();
	Controls.MainScroll:CalculateInternalSize();
end

local function TabSelect( tabID )
	local tab = g_Tabs[ tabID ]
	if tab then
		g_CurrentTab = tabID
		for i,v in pairs( g_Tabs ) do
			v.SelectHighlight:SetHide( i ~= tabID )
		end
		g_routes = tab.Content( Players[ Game.GetActivePlayer() ] )
--[[
		for k, control in pairs( g_filterControls ) do
			local t = {}
			for _,v in pairs( g_routes ) do
				t[ v[k] ] = true
			end
		end
			PopulatePulldown( Controls.OverlayDropDown, g_Overlays, function( index )
	for i, text in pairs( modes ) do
		local controlTable = {}
		control:BuildEntry( "InstanceOne", controlTable )
		controlTable.Button:SetVoid1( i )
		controlTable.Button:LocalizeAndSetText( text )
	end
	control:GetButton():LocalizeAndSetText( modes[1] )
	control:CalculateInternals()
	control:RegisterSelectionCallback( action )
--]]
		SortAndDisplayData()
	end
end

local function SelectSortOption( v )
	local i = v.Rank
	if i==1 then
		g_SortOptions[1].Ascending = not g_SortOptions[1].Ascending
	elseif i then
		insert( g_SortOptions, 1, remove(g_SortOptions, i) )
		for i,v in ipairs( g_SortOptions ) do
			v.Rank = i
		end
	end
	SortAndDisplayData()
end

-------------------------------------------------------------------------------
-- ========================================================================= --
-- Initialization
-- ========================================================================= --
-------------------------------------------------------------------------------

-- Register Callbacks
for i,v in ipairs( g_SortOptions ) do
	v.Rank = i
	if v.Button then
		v.Button:RegisterCallback( Mouse.eLClick, function() SelectSortOption(v) end )
	end
end
for i, v in pairs( g_Tabs ) do
	v.Button:SetVoid1( i )
	v.Button:RegisterCallback( Mouse.eLClick, TabSelect )
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose )

ContextPtr:SetShowHideHandler( function( bIsHide, bInitState )
	if not bInitState then
		if bIsHide then
			if g_PopupInfo then
				Events.SerialEventGameMessagePopupProcessed.CallImmediate(g_PopupInfo.Type, 0)
			end
			UI.decTurnTimerSemaphore()
		else
			UI.incTurnTimerSemaphore()
			Events.SerialEventGameMessagePopupShown(g_PopupInfo)
			CivIconHookup( Game.GetActivePlayer(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
			TabSelect( g_CurrentTab )
		end
	end
end)

-- Key Down Processing
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				OnClose()
			end
			return true
		end
	end)
end

AddSerialEventGameMessagePopup( function( popupInfo )
	if popupInfo.Type == BUTTONPOPUP_TRADE_ROUTE_OVERVIEW then
		g_PopupInfo = popupInfo
		if popupInfo.Data1 == 1 then
			if ContextPtr:IsHidden() then
				if g_Tabs[popupInfo.Data2] then
					g_CurrentTab = popupInfo.Data2 -- Data 2 parameter holds desired tab to open on
				end
				UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost )
			else
				OnClose()
			end
		else
			UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy )
		end
	end
end, ButtonPopupTypes.BUTTONPOPUP_TRADE_ROUTE_OVERVIEW )
