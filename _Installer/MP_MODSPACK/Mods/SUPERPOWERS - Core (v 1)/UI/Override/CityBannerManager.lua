-------------------------------------------------
-- CityBannerManager  (optimised + hardened)
-------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
include( "InfoTooltipInclude" );
include( "CityStateStatusHelper" );

-------------------------------------------------
-- Options
-------------------------------------------------
-- Coalesce SerialEventCityInfoDirty into one refresh per frame (big perf win).
-- Set to false to fall back to the original "refresh immediately" behaviour.
local USE_DEFERRED_REFRESH = true;
-- Cache the (expensive) warmonger / liberation tooltip text once per turn per city.
local CACHE_WAR_TOOLTIPS = true;
-- Show focus / avoid-growth / specialist icons on OTHER human players' cities (multiplayer).
-- The original showed them for every human; that leaks another player's city management.
local SHOW_MANAGEMENT_ICONS_FOR_OTHER_HUMANS = false;

local g_TeamIM     = InstanceManager:new( "TeamCityBanner",  "Anchor", Controls.CityBanners );
local g_OtherIM    = InstanceManager:new( "OtherCityBanner", "Anchor", Controls.CityBanners );
local g_SVStrikeIM = InstanceManager:new( "SVRangeStrikeButton", "Anchor", Controls.StrategicViewStrikeButtons );

-------------------------------------------------
-- Cached globals / constants
-------------------------------------------------
local floor    = math.floor;
local L        = Locale.ConvertTextKey;
local ToUpper  = Locale.ToUpper;
local DEFAULT_SPECIALIST = GameDefines.DEFAULT_SPECIALIST;

local Instances   = {};   -- [playerID][cityID] = cityBanner
local SVInstances = {};   -- [playerID][cityID] = strategic view strike button
local WorldPositionOffset = { x = 0, y = 0, z = 35 };

local BlackFog = 0; -- invisible
local GreyFog  = 1; -- once seen
local WhiteFog = 2; -- eyes on

local SPY_KEY_STRIDE = 4096;

local COLOR_SHADOW = { x = 0, y = 0, z = 0, w = 0.5 };
local COLOR_SOFT   = { x = 1, y = 1, z = 1, w = 0.5 };
local COLOR_WHITE  = { x = 1, y = 1, z = 1, w = 1 };
local COLOR_HP_GREEN  = { x = 0, y = 1, z = 0, w = 1 };
local COLOR_HP_YELLOW = { x = 1, y = 1, z = 0, w = 1 };
local COLOR_HP_RED    = { x = 1, y = 0, z = 0, w = 1 };

local g_bBannersDisabled = false;
local g_bAllDirty = false;

-------------------------------------------------
-- Small nil-safe control helpers
-------------------------------------------------
local function SetHide( control, bHide )
	if control ~= nil then control:SetHide( bHide ); end
end

local function SetToolTip( control, str )
	if control ~= nil then control:SetToolTipString( str ); end
end

local function HideAll( controls, names )
	for i = 1, #names do
		local c = controls[ names[i] ];
		if c ~= nil then c:SetHide( true ); end
	end
end

-- Show/hide an icon; tooltip text is only built when the icon is actually shown.
local function ShowIconKey( control, bShow, key, ... )
	if control == nil then return; end
	if bShow then
		control:SetHide( false );
		control:SetToolTipString( L( key, ... ) );
	else
		control:SetHide( true );
	end
end

-------------------------------------------------
-- Colour cache (GetPlayerColors allocates new tables on every call)
-------------------------------------------------
local g_ColorCache = {};
local g_OriginalOwnerColorCache = {};

local function GetBannerColors( player, playerID )
	local c = g_ColorCache[ playerID ];
	if c == nil then
		local primary, secondary = player:GetPlayerColors();
		if player:IsMinorCiv() then
			primary, secondary = secondary, primary;
		end
		c = {
			background = { x = secondary.x, y = secondary.y, z = secondary.z, w = 0.7 },
			text       = { x = primary.x,   y = primary.y,   z = primary.z,   w = 1 },
			text200    = { x = primary.x,   y = primary.y,   z = primary.z,   w = 0.7 },
		};
		g_ColorCache[ playerID ] = c;
	end
	return c;
end

local function GetOriginalOwnerColor( pOriginalOwner, originalOwnerID )
	local c = g_OriginalOwnerColorCache[ originalOwnerID ];
	if c == nil then
		local _, secondary = pOriginalOwner:GetPlayerColors();
		c = { x = secondary.x, y = secondary.y, z = secondary.z, w = 1 };
		g_OriginalOwnerColorCache[ originalOwnerID ] = c;
	end
	return c;
end

-------------------------------------------------
-- City focus icons (lookup table instead of an if/elseif chain)
-------------------------------------------------
local g_FocusIcons = {};
do
	local function AddFocus( typeName, icon )
		local v = CityAIFocusTypes[ typeName ];
		if v ~= nil then g_FocusIcons[ v ] = " " .. icon; end
	end
	AddFocus( "CITY_AI_FOCUS_TYPE_FOOD",         "[ICON_FOOD]" );
	AddFocus( "CITY_AI_FOCUS_TYPE_PRODUCTION",   "[ICON_PRODUCTION]" );
	AddFocus( "CITY_AI_FOCUS_TYPE_GOLD",         "[ICON_GOLD]" );
	AddFocus( "CITY_AI_FOCUS_TYPE_SCIENCE",      "[ICON_RESEARCH]" );
	AddFocus( "CITY_AI_FOCUS_TYPE_CULTURE",      "[ICON_CULTURE]" );
	AddFocus( "CITY_AI_FOCUS_TYPE_GREAT_PEOPLE", "[ICON_GREAT_PEOPLE]" );
	AddFocus( "CITY_AI_FOCUS_TYPE_FAITH",        "[ICON_PEACE]" );
end

-------------------------------------------------
-- City size icons (highest tier first) and city hall level icons
-------------------------------------------------
local SIZE_CONTROL_NAMES = { "CityIcon_TOWN", "CityIcon_SMALL", "CityIcon_MEDIUM", "CityIcon_LARGE", "CityIcon_XL", "CityIcon_XXL", "CityIcon_GLOBAL" };
local HALL_CONTROL_NAMES = { "CityIcon_Lv1", "CityIcon_Lv2", "CityIcon_Lv3", "CityIcon_Lv4", "CityIcon_Lv5", "CityIcon_NOAC" };

local function ResolveIDs( names )
	local ids = {};
	for i = 1, #names do
		local id = GameInfoTypes[ names[i] ];
		if id ~= nil then ids[ #ids + 1 ] = id; end
	end
	return ids;
end

local g_SizeDefs = {};
do
	local defs = {
		{ "BUILDING_CITY_SIZE_GLOBAL", "CityIcon_GLOBAL", "TXT_KEY_BUILDING_CITY_SIZE_GLOBAL_HELP" },
		{ "BUILDING_CITY_SIZE_XXL",    "CityIcon_XXL",    "TXT_KEY_BUILDING_CITY_SIZE_XXL_HELP" },
		{ "BUILDING_CITY_SIZE_XL",     "CityIcon_XL",     "TXT_KEY_BUILDING_CITY_SIZE_XL_HELP" },
		{ "BUILDING_CITY_SIZE_LARGE",  "CityIcon_LARGE",  "TXT_KEY_BUILDING_CITY_SIZE_LARGE_HELP" },
		{ "BUILDING_CITY_SIZE_MEDIUM", "CityIcon_MEDIUM", "TXT_KEY_BUILDING_CITY_SIZE_MEDIUM_HELP" },
		{ "BUILDING_CITY_SIZE_SMALL",  "CityIcon_SMALL",  "TXT_KEY_BUILDING_CITY_SIZE_SMALL_HELP" },
		{ "BUILDING_CITY_SIZE_TOWN",   "CityIcon_TOWN",   "TXT_KEY_BUILDING_CITY_SIZE_TOWN_HELP" },
	};
	for i = 1, #defs do
		local id = GameInfoTypes[ defs[i][1] ];
		if id ~= nil then
			g_SizeDefs[ #g_SizeDefs + 1 ] = { id = id, control = defs[i][2], tip = defs[i][3] };
		end
	end
end

-- halls: any of these buildings selects this level
-- ok:    (optional) any of these must also be present, otherwise the "NOAC" icon is shown
local g_HallDefs = {};
do
	local defs = {
		{ halls = { "BUILDING_CITY_HALL_LV1", "BUILDING_SATRAPS_COURT" }, ok = nil,
		  icon = "CityIcon_Lv1", tip = "TXT_KEY_BUILDING_CITY_HALL_LV1_HELP", noacTip = nil },
		{ halls = { "BUILDING_CITY_HALL_LV2" }, ok = { "BUILDING_CONSTABLE", "BUILDING_ROMAN_SENATE" },
		  icon = "CityIcon_Lv2", tip = "TXT_KEY_BUILDING_CITY_HALL_LV2_HELP", noacTip = "TXT_KEY_BUILDING_CITY_HALL_NOAC_LV2" },
		{ halls = { "BUILDING_CITY_HALL_LV3" }, ok = { "BUILDING_SHERIFF_OFFICE" },
		  icon = "CityIcon_Lv3", tip = "TXT_KEY_BUILDING_CITY_HALL_LV3_HELP", noacTip = "TXT_KEY_BUILDING_CITY_HALL_NOAC_LV3" },
		{ halls = { "BUILDING_CITY_HALL_LV4" }, ok = { "BUILDING_POLICE_STATION" },
		  icon = "CityIcon_Lv4", tip = "TXT_KEY_BUILDING_CITY_HALL_LV4_HELP", noacTip = "TXT_KEY_BUILDING_CITY_HALL_NOAC_LV4" },
		{ halls = { "BUILDING_CITY_HALL_LV5" }, ok = { "BUILDING_PROCURATORATE" },
		  icon = "CityIcon_Lv5", tip = "TXT_KEY_BUILDING_CITY_HALL_LV5_HELP", noacTip = "TXT_KEY_BUILDING_CITY_HALL_NOAC_LV5" },
	};
	for i = 1, #defs do
		local d = defs[i];
		g_HallDefs[ #g_HallDefs + 1 ] = {
			halls = ResolveIDs( d.halls ),
			ok = d.ok and ResolveIDs( d.ok ) or nil,
			icon = d.icon, tip = d.tip, noacTip = d.noacTip,
		};
	end
end

local function HasAny( city, ids )
	for i = 1, #ids do
		if city:IsHasBuilding( ids[i] ) then return true; end
	end
	return false;
end

-------------------------------------------------
-- Determines whether or not to show the Range Strike Button
-------------------------------------------------
function ShouldShowRangeStrikeButton( city )
	if city == nil then
		return false;
	end
	if city:GetOwner() ~= Game.GetActivePlayer() then
		return false;
	end
	return city:CanRangeStrikeNow();
end

-------------------------------------------------
-- Show/hide the range strike icon
-------------------------------------------------
function UpdateRangeStrikeIcon( cityBanner )
	local player = Players[ cityBanner.playerID ];
	if player == nil then return; end

	local city = player:GetCityByID( cityBanner.cityID );
	local bShow = ShouldShowRangeStrikeButton( city );
	local bHide = not bShow;

	local controls = cityBanner.SubControls;
	if controls ~= nil then
		SetHide( controls.CityRangeStrikeButton, bHide );
		SetHide( controls.CityRangeStrikeAnim, bHide );
	end

	local svTable = SVInstances[ cityBanner.playerID ];
	local sv = svTable and svTable[ cityBanner.cityID ];
	if sv ~= nil then
		SetHide( sv.CityRangeStrikeButton, bHide );
		SetHide( sv.CityRangeStrikeAnim, bHide );
	end
end

-------------------------------------------------
-- Espionage: one lookup table per refresh pass instead of one
-- GetEspionageSpies() call per city.
-------------------------------------------------
local function BuildSpyMap( iActivePlayer )
	local map = {};
	local activePlayer = Players[ iActivePlayer ];
	if activePlayer == nil then return map; end

	local spies = activePlayer:GetEspionageSpies();
	if spies ~= nil then
		for _, v in ipairs( spies ) do
			if v.CityX ~= nil and v.CityY ~= nil and v.CityX >= 0 and v.CityY >= 0 then
				local key = v.CityX + v.CityY * SPY_KEY_STRIDE;
				local entry = map[ key ];
				if entry == nil then
					entry = {};
					map[ key ] = entry;
				end
				local info = { name = L( v.Name ), rank = L( v.Rank ) };
				if v.IsDiplomat then
					entry.diplomat = info;
				else
					entry.spy = info;
				end
			end
		end
	end
	return map;
end

-------------------------------------------------
-- Banner refresh: split into small pieces (keeps upvalue/local counts sane
-- and makes it easy to see what each part touches)
-------------------------------------------------
local function ApplyColors( controls, colors, isActiveTeamCity )
	local bg = colors.background;

	if controls.CityBannerBackground ~= nil then controls.CityBannerBackground:SetColor( bg ); end

	if isActiveTeamCity then
		if controls.CityBannerBGLeftHL ~= nil then controls.CityBannerBGLeftHL:SetColor( bg ); end
		if controls.CityBannerBGRightHL ~= nil then controls.CityBannerBGRightHL:SetColor( bg ); end
		if controls.CityBannerRightBackground ~= nil then controls.CityBannerRightBackground:SetColor( bg ); end
		if controls.CityBannerLeftBackground ~= nil then controls.CityBannerLeftBackground:SetColor( bg ); end
	else
		-- These only exist on the "other player" banner type.
		if controls.RightBackground ~= nil then controls.RightBackground:SetColor( bg ); end
		if controls.LeftBackground ~= nil then controls.LeftBackground:SetColor( bg ); end
	end

	if controls.CityProductionName ~= nil then
		controls.CityProductionName:SetColor( colors.text200, 0 );
	end
	if controls.CityName ~= nil then
		controls.CityName:SetColor( colors.text, 0 );
		controls.CityName:SetColor( COLOR_SHADOW, 1 );
		controls.CityName:SetColor( COLOR_SOFT, 2 );
	end
end

-- Name text, tooltip, religion icon.  Returns the localized city name.
local function RefreshNameAndTooltip( cityBanner, controls, player, city, iActiveTeam, iActivePlayer, isActivePlayerCity, isActiveTeamCity, isMinor )
	local playerID = cityBanner.playerID;

	local localizedCityName = L( city:GetNameKey() );
	local displayName = ToUpper( localizedCityName );

	if city:IsCapital() and not isMinor then
		displayName = "[ICON_CAPITAL]" .. displayName;
	end

	-- City management icons (focus, avoid growth, no-auto-specialists, unemployed citizens)
	if player:IsHuman() and ( isActiveTeamCity or SHOW_MANAGEMENT_ICONS_FOR_OTHER_HUMANS ) then
		if city:IsForcedAvoidGrowth() then
			displayName = displayName .. " [ICON_LOCKED]";
		end

		local focusIcon = g_FocusIcons[ city:GetFocusType() ];
		if focusIcon ~= nil then
			displayName = displayName .. focusIcon;
		end

		if city:IsNoAutoAssignSpecialists() then
			displayName = displayName .. " [ICON_CHECKBOX]";
		end

		if city:GetSpecialistCount( DEFAULT_SPECIALIST ) > 0 then
			displayName = displayName .. " [ICON_HAPPINESS_3]";
		end
	end

	local layoutDirty = false;
	if cityBanner.LastName ~= displayName then
		controls.CityName:SetText( displayName );
		cityBanner.LastName = displayName;
		layoutDirty = true;
	end

	-- Tooltip
	local strToolTip = "";
	if isActivePlayerCity then
		if city:IsPuppet() and not player:MayNotAnnex() then
			strToolTip = L( "TXT_KEY_CITY_ANNEX_TT" );
		else
			strToolTip = L( "TXT_KEY_CITY_ENTER_CITY_SCREEN" );
		end
	elseif isActiveTeamCity then
		strToolTip = L( "TXT_KEY_CITY_TEAMMATE" );
	elseif Game.IsOption( GameOptionTypes.GAMEOPTION_ALWAYS_WAR ) then
		strToolTip = L( "TXT_KEY_ALWAYS_AT_WAR_WITH_CITY" );
	elseif isMinor then
		local strStatusTT = GetCityStateStatusToolTip( iActivePlayer, playerID, false );
		strToolTip = strToolTip .. strStatusTT;
		SetToolTip( controls.StatusIconBG, strStatusTT );
		SetToolTip( controls.StatusIcon, strStatusTT );
	elseif not Teams[ iActiveTeam ]:IsHasMet( player:GetTeam() ) then
		strToolTip = L( "TXT_KEY_HAVENT_MET" );
	else
		strToolTip = L( "TXT_KEY_TALK_TO_PLAYER" );
	end

	if Teams[ iActiveTeam ]:IsAtWar( player:GetTeam() ) then
		local warTip = cityBanner.WarTipText;
		local turn = Game.GetGameTurn();
		if not CACHE_WAR_TOOLTIPS or warTip == nil or cityBanner.WarTipTurn ~= turn then
			warTip = "[NEWLINE]----------------[NEWLINE]" .. player:GetWarmongerPreviewString( city:GetOwner() );
			if city:GetOriginalOwner() ~= city:GetOwner() then
				warTip = warTip .. "[NEWLINE]----------------[NEWLINE]" .. player:GetLiberationPreviewString( city:GetOriginalOwner() );
			end
			cityBanner.WarTipText = warTip;
			cityBanner.WarTipTurn = turn;
		end
		strToolTip = strToolTip .. warTip;
	end

	-- Religion
	local eReligion = city:GetReligiousMajority();
	local bHasReligion = ( eReligion >= 0 );

	if cityBanner.LastReligion ~= eReligion then
		if bHasReligion and controls.ReligiousIcon ~= nil then
			local religion = GameInfo.Religions[ eReligion ];
			if religion ~= nil then
				IconHookup( religion.PortraitIndex, 32, religion.IconAtlas, controls.ReligiousIcon );
				if controls.ReligiousIconShadow ~= nil then
					IconHookup( religion.PortraitIndex, 32, religion.IconAtlas, controls.ReligiousIconShadow );
				end
			end
		end
		cityBanner.LastReligion = eReligion;
		layoutDirty = true;
	end

	local religionToolTip = "";
	if GetReligionTooltip ~= nil then
		religionToolTip = GetReligionTooltip( city );
	end
	if religionToolTip ~= "" then
		strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]" .. religionToolTip;
	end

	controls.BannerButton:SetToolTipString( strToolTip );

	if controls.ReligiousIcon ~= nil then
		controls.ReligiousIcon:SetToolTipString( religionToolTip );
		SetHide( controls.ReligiousIconContainer, not bHasReligion );
	end

	if layoutDirty then
		DoResizeBanner( controls );
	end

	return localizedCityName;
end

-- Connected / blockaded / razing / resistance / puppet / occupied
local function RefreshStatusIcons( controls, city, isActivePlayerCity, isActiveTeamCity )
	if isActiveTeamCity and controls.ConnectedIcon ~= nil then
		local player = Players[ city:GetOwner() ];
		local bConnected = ( not city:IsCapital() ) and player ~= nil and player:IsCapitalConnectedToCity( city ) and ( not city:IsBlockaded() );
		ShowIconKey( controls.ConnectedIcon, bConnected, "TXT_KEY_CITY_CONNECTED" );
	end

	ShowIconKey( controls.BlockadedIcon, city:IsBlockaded(), "TXT_KEY_CITY_BLOCKADED" );

	if controls.RazingIcon ~= nil then
		if city:IsRazing() then
			controls.RazingIcon:SetHide( false );
			controls.RazingIcon:SetToolTipString( L( "TXT_KEY_CITY_BURNING", tostring( city:GetRazingTurns() ) ) );
		else
			controls.RazingIcon:SetHide( true );
		end
	end

	if controls.ResistanceIcon ~= nil then
		if city:IsResistance() then
			controls.ResistanceIcon:SetHide( false );
			controls.ResistanceIcon:SetToolTipString( L( "TXT_KEY_CITY_RESISTANCE", tostring( city:GetResistanceTurns() ) ) );
		else
			controls.ResistanceIcon:SetHide( true );
		end
	end

	if controls.PuppetIcon ~= nil then
		if city:IsPuppet() then
			controls.PuppetIcon:SetHide( false );
			if isActivePlayerCity then
				controls.PuppetIcon:SetToolTipString( L( "TXT_KEY_BUILDING_PUPPET_GOVERNEMENT" ) );
			else
				controls.PuppetIcon:SetToolTipString( L( "TXT_KEY_CITY_PUPPET_OTHER" ) );
			end
		else
			controls.PuppetIcon:SetHide( true );
		end
	end

	ShowIconKey( controls.OccupiedIcon, city:IsOccupied() and not city:IsNoOccupiedUnhappiness(), "TXT_KEY_CITY_OCCUPIED" );
end

-- Custom mod icons: city size, city hall level, resource demand
local function RefreshCustomIcons( controls, city )
	-- Size
	HideAll( controls, SIZE_CONTROL_NAMES );
	if city:GetPopulation() > 0 then
		for i = 1, #g_SizeDefs do
			local d = g_SizeDefs[i];
			if city:IsHasBuilding( d.id ) then
				local c = controls[ d.control ];
				if c ~= nil then
					c:SetHide( false );
					c:SetToolTipString( L( d.tip ) );
				end
				break;
			end
		end
	end

	-- City hall level (capital and puppets never show one)
	HideAll( controls, HALL_CONTROL_NAMES );
	if not city:IsCapital() and not city:IsPuppet() then
		for i = 1, #g_HallDefs do
			local d = g_HallDefs[i];
			if HasAny( city, d.halls ) then
				local iconName, tipKey;
				if d.ok == nil or HasAny( city, d.ok ) then
					iconName, tipKey = d.icon, d.tip;
				else
					iconName, tipKey = "CityIcon_NOAC", d.noacTip;
				end
				local c = controls[ iconName ];
				if c ~= nil then
					c:SetHide( false );
					if tipKey ~= nil then c:SetToolTipString( L( tipKey ) ); end
				end
				break;
			end
		end
	end

	-- Resource demand
	local demandCtrl = controls.CityIcon_ResurceDemand;
	if demandCtrl ~= nil then
		local bShown = false;
		if city:GetResourceDemanded( true ) ~= -1 and city:GetWeLoveTheKingDayCounter() <= 0 then
			local resourceInfo = GameInfo.Resources[ city:GetResourceDemanded() ];
			if resourceInfo ~= nil then
				demandCtrl:SetText( resourceInfo.IconString );
				demandCtrl:SetToolTipString( L( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED_TT" ) );
				bShown = true;
			end
		end
		demandCtrl:SetHide( not bShown );
	end
end

-- Spy / diplomat icons.  Only ever shown for the ACTIVE player's own agents and
-- always explicitly hidden otherwise (stops stale icons from pooled instances).
local function RefreshSpyIcons( controls, city, spyMap, isActivePlayerCity, isMinor )
	local entry = spyMap[ city:GetX() + city:GetY() * SPY_KEY_STRIDE ];
	local spy = entry and entry.spy;
	local dip = entry and entry.diplomat;

	local spyCtrl = controls.SpyIcon;
	if spyCtrl ~= nil then
		if spy ~= nil then
			spyCtrl:SetHide( false );
			if isActivePlayerCity then
				spyCtrl:LocalizeAndSetToolTip( "TXT_KEY_CITY_SPY_YOUR_CITY_TT", spy.rank, spy.name, city:GetName(), spy.rank, spy.name );
			elseif isMinor then
				spyCtrl:LocalizeAndSetToolTip( "TXT_KEY_CITY_SPY_CITY_STATE_TT", spy.rank, spy.name, city:GetName(), spy.rank, spy.name );
			else
				spyCtrl:LocalizeAndSetToolTip( "TXT_KEY_CITY_SPY_OTHER_CIV_TT", spy.rank, spy.name, city:GetName(), spy.rank, spy.name, spy.rank, spy.name );
			end
		else
			spyCtrl:SetHide( true );
		end
	end

	local dipCtrl = controls.DiplomatIcon;
	if dipCtrl ~= nil then
		if dip ~= nil then
			dipCtrl:SetHide( false );
			dipCtrl:LocalizeAndSetToolTip( "TXT_KEY_CITY_DIPLOMAT_OTHER_CIV_TT", dip.rank, dip.name, city:GetName(), dip.rank, dip.name, dip.rank, dip.name );
		else
			dipCtrl:SetHide( true );
		end
	end
end

-- Population / defence / garrison / range strike.
local function RefreshCoreStats( cityBanner, controls, city, isActiveTeamCity )
	-- Defence
	local strengthCtrl = controls.CityStrength;
	if strengthCtrl ~= nil then
		strengthCtrl:SetText( floor( city:GetStrengthValue() / 100 ) );
		if not isActiveTeamCity then strengthCtrl:SetHide( false ); end
	end

	-- Population
	local cityPopulation = floor( city:GetPopulation() );
	local popCtrl = controls.CityPopulation;
	if popCtrl ~= nil then
		popCtrl:SetText( cityPopulation );
		if not isActiveTeamCity then popCtrl:SetHide( false ); end
	end

	if isActiveTeamCity then
		if city:GetGarrisonedUnit() == nil then
			SetHide( controls.GarrisonFrame, true );
		end
		SetHide( controls.EjectGarrison, true );
		UpdateRangeStrikeIcon( cityBanner );
	end

	return cityPopulation;
end

-- Growth, production, bars, production icon (these controls only exist on the team banner)
local function RefreshGrowthAndProduction( cityBanner, controls, city, localizedCityName, cityPopulation, isActivePlayerCity )
	-- Growth turns
	if controls.CityGrowth ~= nil then
		local foodDiff100 = city:FoodDifferenceTimes100();
		local cityGrowth = city:GetFoodTurnsLeft();
		local tip;

		if city:IsFoodProduction() or foodDiff100 == 0 then
			cityGrowth = "-";
			tip = L( "TXT_KEY_CITY_STOPPED_GROWING_TT", localizedCityName, cityPopulation );
		elseif foodDiff100 < 0 then
			cityGrowth = "[COLOR_WARNING_TEXT]-[ENDCOLOR]";
			tip = L( "TXT_KEY_CITY_STARVING_TT", localizedCityName );
		else
			tip = L( "TXT_KEY_CITY_WILL_GROW_TT", localizedCityName, cityPopulation, cityPopulation + 1, cityGrowth );
		end

		SetToolTip( controls.CityBannerRightBackground, tip );
		controls.CityGrowth:SetText( cityGrowth );
	end

	-- Production turns
	if controls.BuildGrowth ~= nil then
		local buildGrowth = "-";
		if city:IsProduction() and not city:IsProductionProcess() then
			if city:GetCurrentProductionDifferenceTimes100( false, false ) > 0 then
				buildGrowth = city:GetProductionTurnsLeft();
			end
		end
		controls.BuildGrowth:SetText( buildGrowth );
	end

	-- Growth bar
	if controls.GrowthBar ~= nil then
		local iFoodNeeded = city:GrowthThreshold();
		if iFoodNeeded > 0 then
			local iCurrentFood = city:GetFood();
			local pct = iCurrentFood / iFoodNeeded;
			local pctPlus = ( iCurrentFood + city:FoodDifference() ) / iFoodNeeded;
			if pctPlus > 1 then pctPlus = 1; end
			controls.GrowthBar:SetPercent( pct );
			controls.GrowthBarShadow:SetPercent( pctPlus );
		else
			controls.GrowthBar:SetPercent( 0 );
			controls.GrowthBarShadow:SetPercent( 0 );
		end
	end

	-- Production bar
	if controls.ProductionBar ~= nil then
		local iProductionNeeded = city:GetProductionNeeded();
		if iProductionNeeded > 0 then
			local iCurrentProduction = city:GetProduction();
			local iProductionPerTurn = city:GetYieldRate( YieldTypes.YIELD_PRODUCTION );
			if city:IsFoodProduction() then
				iProductionPerTurn = iProductionPerTurn + city:GetYieldRate( YieldTypes.YIELD_FOOD ) - city:FoodConsumption( true );
			end
			local pct = iCurrentProduction / iProductionNeeded;
			local pctPlus = ( iCurrentProduction + iProductionPerTurn ) / iProductionNeeded;
			if pctPlus > 1 then pctPlus = 1; end
			controls.ProductionBar:SetPercent( pct );
			controls.ProductionBarShadow:SetPercent( pctPlus );
		else
			controls.ProductionBar:SetPercent( 0 );
			controls.ProductionBarShadow:SetPercent( 0 );
		end
	end

	-- Production name + tooltip
	local cityProductionName = city:GetProductionNameKey();
	if cityProductionName == nil or string.len( cityProductionName ) == 0 then
		cityProductionName = "TXT_KEY_PRODUCTION_NO_PRODUCTION";
	end

	if controls.CityProductionName ~= nil then
		controls.CityProductionName:SetText( L( cityProductionName ) );

		if controls.CityBannerLeftBackground ~= nil then
			local tooltipString;
			if city:IsProductionProcess() then
				tooltipString = GetHelpTextForProcess( city:GetProductionProcess(), false );
			elseif cityProductionName == "TXT_KEY_PRODUCTION_NO_PRODUCTION" then
				tooltipString = L( "TXT_KEY_CITY_NOT_PRODUCING", localizedCityName );
			else
				local productionTurnsLeft = city:GetProductionTurnsLeft();
				if productionTurnsLeft > 99 then
					tooltipString = L( "TXT_KEY_CITY_CURRENTLY_PRODUCING_99PLUS_TT", localizedCityName, cityProductionName );
				else
					tooltipString = L( "TXT_KEY_CITY_CURRENTLY_PRODUCING_TT", localizedCityName, cityProductionName, productionTurnsLeft );
				end
			end
			controls.CityBannerLeftBackground:SetToolTipString( tooltipString );
		end
	end

	-- Production icon (only re-hooked when what is being built changes)
	local prodImage = controls.CityBannerProductionImage;
	if prodImage ~= nil then
		local kind, id = 0, -1;
		local v = city:GetProductionUnit();
		if v ~= -1 then
			kind, id = 1, v;
		else
			v = city:GetProductionBuilding();
			if v ~= -1 then
				kind, id = 2, v;
			else
				v = city:GetProductionProject();
				if v ~= -1 then
					kind, id = 3, v;
				else
					v = city:GetProductionProcess();
					if v ~= -1 then kind, id = 4, v; end
				end
			end
		end

		if kind ~= cityBanner.LastProdKind or id ~= cityBanner.LastProdID then
			local ok = false;
			if kind == 1 then
				local portraitOffset, portraitAtlas = UI.GetUnitPortraitIcon( id, city:GetOwner() );
				ok = IconHookup( portraitOffset, 45, portraitAtlas, prodImage );
			elseif kind == 2 then
				local info = GameInfo.Buildings[ id ];
				ok = info ~= nil and IconHookup( info.PortraitIndex, 45, info.IconAtlas, prodImage );
			elseif kind == 3 then
				local info = GameInfo.Projects[ id ];
				ok = info ~= nil and IconHookup( info.PortraitIndex, 45, info.IconAtlas, prodImage );
			elseif kind == 4 then
				local info = GameInfo.Processes[ id ];
				ok = info ~= nil and IconHookup( info.PortraitIndex, 45, info.IconAtlas, prodImage );
			end
			prodImage:SetHide( not ok );
			cityBanner.LastProdKind = kind;
			cityBanner.LastProdID = id;
		end

		-- Hook the production button once, and only on the active player's own cities
		if isActivePlayerCity and not cityBanner.ProdButtonHooked and controls.CityBannerProductionButton ~= nil then
			controls.CityBannerProductionButton:RegisterCallback( Mouse.eLClick, OnProdClick );
			controls.CityBannerProductionButton:SetVoids( city:GetID(), cityBanner.playerID );
			cityBanner.ProdButtonHooked = true;
		end
	end
end

-- Civ icon / city-state meter / original owner indicator ("other player" banner only)
local function SetCivIcon( control, civInfo, tintColor )
	local ok = false;
	if civInfo ~= nil then
		control:SetColor( tintColor or COLOR_WHITE );
		ok = IconHookup( civInfo.PortraitIndex, 32, civInfo.AlphaIconAtlas, control );
		if not ok and civInfo.IconAtlas ~= nil then
			-- Alpha atlas missing for this civ/size: fall back to the coloured atlas instead
			-- of silently keeping whatever icon the pooled instance had before.
			control:SetColor( COLOR_WHITE );
			ok = IconHookup( civInfo.PortraitIndex, 32, civInfo.IconAtlas, control );
		end
	end
	control:SetHide( not ok );
	return ok;
end

-------------------------------------------------
-- City-state ally icon
-------------------------------------------------
local COLOR_BLACK = { x = 0, y = 0, z = 0, w = 1 };
local g_AllyColorCache = {};
local g_AllyLabel = nil;

local function GetAllyColor( pAlly, allyID )
	local c = g_AllyColorCache[ allyID ];
	if c == nil then
		local primary = pAlly:GetPlayerColors();
		c = { x = primary.x, y = primary.y, z = primary.z, w = 1 };
		g_AllyColorCache[ allyID ] = c;
	end
	return c;
end

-- Optional text key TXT_KEY_CITY_BANNER_ALLY; falls back to English if it isn't defined.
local function GetAllyLabel()
	if g_AllyLabel == nil then
		local s = L( "TXT_KEY_CITY_BANNER_ALLY" );
		if s == nil or s == "TXT_KEY_CITY_BANNER_ALLY" then
			s = "Ally:";
		end
		g_AllyLabel = s;
	end
	return g_AllyLabel;
end

-- Returns the ID of the ally to display for a city-state, or -1.
-- Only allies the active team has met (or is on) are shown, so a banner can never
-- reveal who an unmet civilization is.
local function GetVisibleAllyID( player, iActiveTeam )
	local allyID = player:GetAlly();
	if allyID == nil or allyID < 0 then
		return -1;
	end

	local pAlly = Players[ allyID ];
	if pAlly == nil then
		return -1;
	end

	local allyTeam = pAlly:GetTeam();
	if allyTeam ~= iActiveTeam and not Teams[ iActiveTeam ]:IsHasMet( allyTeam ) then
		return -1;
	end
	return allyID;
end

-- Returns true if the banner layout changed (icon shown/hidden).
local function RefreshAllyIcon( cityBanner, controls, player, iActiveTeam, isMinor )
	local container = controls.AllyIconContainer;
	local icon = controls.AllyIcon;
	if container == nil or icon == nil then
		return false;
	end

	local allyID = -1;
	if isMinor then
		allyID = GetVisibleAllyID( player, iActiveTeam );
	end

	if allyID == cityBanner.LastAlly then
		return false; -- nothing changed, keep the icon as it is
	end
	cityBanner.LastAlly = allyID;

	if allyID < 0 then
		container:SetHide( true );
		return true;
	end

	local pAlly = Players[ allyID ];
	local civInfo = GameInfo.Civilizations[ pAlly:GetCivilizationType() ];
	local ok = SetCivIcon( icon, civInfo, GetAllyColor( pAlly, allyID ) );
	if ok then
		if controls.AllyIconShadow ~= nil then
			SetCivIcon( controls.AllyIconShadow, civInfo, COLOR_BLACK );
		end
		icon:SetToolTipString( GetAllyLabel() .. " " .. L( pAlly:GetCivilizationShortDescription() ) );
	end
	container:SetHide( not ok );
	return true;
end

-- Returns true if something in the name stack appeared/disappeared (caller re-sizes the banner).
local function RefreshOtherPlayerIcons( cityBanner, controls, player, city, iActivePlayer, iActiveTeam, colors, isMinor )
	if controls.MinorIndicator == nil or controls.StatusIcon == nil then
		return false;
	end

	local statusIcon = controls.StatusIcon;
	statusIcon:SetHide( false );
	statusIcon:SetColor( colors.text );

	if isMinor then
		SetUpMinorMeter( iActivePlayer, cityBanner.playerID, controls, colors.text );

		-- Minor civ trait icon
		local minorInfo = GameInfo.MinorCivilizations[ player:GetMinorCivType() ];
		local traitInfo = minorInfo ~= nil and GameInfo.MinorCivTraits[ minorInfo.MinorCivTrait ] or nil;
		if traitInfo ~= nil then
			statusIcon:SetTexture( traitInfo.TraitIcon );
			statusIcon:SetTextureOffsetVal( 0, 0 );
		end
	else
		local civInfo = GameInfo.Civilizations[ player:GetCivilizationType() ];
		SetCivIcon( statusIcon, civInfo, colors.text );
		statusIcon:SetOffsetX( 0 );
		SetHide( controls.StatusIconBG, true );
		SetHide( controls.StatusMeterFrame, true );
	end

	-- Original owner (only drawn for ex city-state cities)
	local originalOwnerID = city:GetOriginalOwner();
	local pOriginalOwner = Players[ originalOwnerID ];
	local bIndicator = false;
	if pOriginalOwner ~= nil and pOriginalOwner:IsMinorCiv() then
		local origInfo = GameInfo.Civilizations[ pOriginalOwner:GetCivilizationType() ];
		bIndicator = SetCivIcon( controls.MinorIndicator, origInfo, GetOriginalOwnerColor( pOriginalOwner, originalOwnerID ) );
	else
		controls.MinorIndicator:SetHide( true );
	end

	-- Both of these live in the name stack, so the banner width must follow them
	local bLayoutChanged = ( cityBanner.LastIndicator ~= bIndicator );
	cityBanner.LastIndicator = bIndicator;

	if RefreshAllyIcon( cityBanner, controls, player, iActiveTeam, isMinor ) then
		bLayoutChanged = true;
	end

	return bLayoutChanged;
end

-------------------------------------------------
-- Updates banner to reflect latest city info.
-------------------------------------------------
function RefreshCityBanner( cityBanner, iActiveTeam, iActivePlayer, spyMap )
	local playerID = cityBanner.playerID;
	local playerInstances = Instances[ playerID ];
	if playerInstances == nil or playerInstances[ cityBanner.cityID ] == nil then
		return;
	end

	local controls = cityBanner.SubControls;
	local player = Players[ playerID ];
	if controls == nil or player == nil then
		return;
	end

	local isActivePlayerCity = ( playerID == iActivePlayer );
	local isActiveTeamCity = ( player:GetTeam() == iActiveTeam );
	local isMinor = player:IsMinorCiv();
	local colors = GetBannerColors( player, playerID );

	ApplyColors( controls, colors, isActiveTeamCity );

	-- grab city using playerID and cityID
	local city = player:GetCityByID( cityBanner.cityID );
	if city ~= nil then
		spyMap = spyMap or BuildSpyMap( iActivePlayer );

		local localizedCityName = RefreshNameAndTooltip( cityBanner, controls, player, city, iActiveTeam, iActivePlayer, isActivePlayerCity, isActiveTeamCity, isMinor );

		RefreshStatusIcons( controls, city, isActivePlayerCity, isActiveTeamCity );

		if player:IsHuman() then
			RefreshCustomIcons( controls, city );
		end

		RefreshSpyIcons( controls, city, spyMap, isActivePlayerCity, isMinor );

		local cityPopulation = RefreshCoreStats( cityBanner, controls, city, isActiveTeamCity );

		RefreshGrowthAndProduction( cityBanner, controls, city, localizedCityName, cityPopulation, isActivePlayerCity );

		if RefreshOtherPlayerIcons( cityBanner, controls, player, city, iActivePlayer, iActiveTeam, colors, isMinor ) then
			DoResizeBanner( controls );
		end

		RefreshCityDamage( cityBanner, city:GetDamage(), city:GetMaxHitPoints() );
	end

	if controls.NameStack ~= nil then
		controls.NameStack:CalculateSize();
		controls.NameStack:ReprocessAnchoring();
	end
	controls.IconsStack:CalculateSize();
	controls.IconsStack:ReprocessAnchoring();
end

local function RefreshSingleBanner( instance )
	local iActivePlayer = Game.GetActivePlayer();
	local pActive = Players[ iActivePlayer ];
	if pActive == nil then return; end
	RefreshCityBanner( instance, pActive:GetTeam(), iActivePlayer );
end

----------------------------------------------------------------
----------------------------------------------------------------
function SetUpMinorMeter( iMajor, iMinor, controls, minorColor )

	controls.StatusMeterFrame:SetHide( false );
	controls.StatusIconBG:SetHide( false );
	controls.StatusIcon:SetOffsetX( 0 );
	controls.StatusIcon:SetColor( COLOR_WHITE );

	-- If we're neutral, show the minor's own colors
	if GetCityStateStatusType( iMajor, iMinor ) == "MINOR_FRIENDSHIP_STATUS_NEUTRAL" then
		controls.StatusIcon:SetColor( minorColor );
		controls.StatusIconBG:SetHide( true );
		controls.StatusIcon:SetOffsetX( -5 );
	end

	-- If INF is 0, don't bother showing the meter
	if Players[ iMinor ]:GetMinorCivFriendshipWithMajor( iMajor ) == 0 then
		controls.StatusMeterFrame:SetHide( true );
	end

	UpdateCityStateStatusUI( iMajor, iMinor, controls.PositiveStatusMeter, controls.NegativeStatusMeter, controls.StatusMeterMarker, controls.StatusIconBG );
end

-------------------------------------------------
-- Banner / strike button creation helpers
-------------------------------------------------
local function ApplyBannerInteractivity( controls )
	if controls ~= nil and controls.BannerButton ~= nil then
		controls.BannerButton:SetDisabled( g_bBannersDisabled );
		controls.BannerButton:EnableToolTip( not g_bBannersDisabled );
	end
end

local function CreateBannerControls( hexPos, playerID, cityID, bActiveType )
	local gridPosX, gridPosY = ToGridFromHex( hexPos.x, hexPos.y );
	local controlTable;

	if bActiveType then
		controlTable = g_TeamIM:GetInstance();
	else
		controlTable = g_OtherIM:GetInstance();
	end

	controlTable.BannerButton:RegisterCallback( Mouse.eLClick, OnBannerClick );
	controlTable.BannerButton:SetVoid1( gridPosX );
	controlTable.BannerButton:SetVoid2( gridPosY );

	if bActiveType then
		if controlTable.EjectGarrison ~= nil then
			controlTable.EjectGarrison:RegisterCallback( Mouse.eLClick, OnEjectGarrisonClick );
			controlTable.EjectGarrison:SetVoid1( playerID );
			controlTable.EjectGarrison:SetVoid2( cityID );
		end
		if controlTable.CityRangeStrikeButton ~= nil then
			controlTable.CityRangeStrikeButton:RegisterCallback( Mouse.eLClick, OnCityRangeStrikeButtonClick );
			controlTable.CityRangeStrikeButton:SetVoid1( playerID );
			controlTable.CityRangeStrikeButton:SetVoid2( cityID );
		end
	end

	ApplyBannerInteractivity( controlTable );
	return controlTable;
end

local function ReleaseSVStrikeButton( playerID, cityID )
	local t = SVInstances[ playerID ];
	if t ~= nil then
		local sv = t[ cityID ];
		if sv ~= nil then
			g_SVStrikeIM:ReleaseInstance( sv );
			t[ cityID ] = nil;
		end
	end
end

local function CreateSVStrikeButton( playerID, cityID, worldPos )
	ReleaseSVStrikeButton( playerID, cityID );

	local t = SVInstances[ playerID ];
	if t == nil then
		t = {};
		SVInstances[ playerID ] = t;
	end

	local sv = g_SVStrikeIM:GetInstance();
	sv.Anchor:SetWorldPosition( worldPos );
	sv.CityRangeStrikeButton:RegisterCallback( Mouse.eLClick, OnCityRangeStrikeButtonClick );
	sv.CityRangeStrikeButton:SetVoid1( playerID );
	sv.CityRangeStrikeButton:SetVoid2( cityID );
	t[ cityID ] = sv;
end

-------------------------------------------------
-- On City Created
-------------------------------------------------
function OnCityCreated( hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState )
	local pPlayer = Players[ playerID ];
	local iActivePlayer = Game.GetActivePlayer();
	local pActive = Players[ iActivePlayer ];
	if pPlayer == nil or pActive == nil then
		return;
	end

	if Instances[ playerID ] ~= nil and Instances[ playerID ][ cityID ] ~= nil then
		return;
	end

	local iActiveTeam = pActive:GetTeam();
	local isActiveType = ( pPlayer:GetTeam() == iActiveTeam );

	local controlTable = CreateBannerControls( hexPos, playerID, cityID, isActiveType );
	local worldPos = HexToWorld( hexPos );

	if isActiveType then
		CreateSVStrikeButton( playerID, cityID, worldPos );
	end

	local cityBanner = {
		playerID = playerID,
		cityID = cityID,
		IsActiveType = isActiveType,
		SubControls = controlTable,
		Hex = hexPos,
	};

	if Instances[ playerID ] == nil then
		Instances[ playerID ] = {};
	end
	Instances[ playerID ][ cityID ] = cityBanner;

	controlTable.Anchor:SetWorldPosition( VecAdd( worldPos, WorldPositionOffset ) );

	RefreshCityBanner( cityBanner, iActiveTeam, iActivePlayer );

	controlTable.Anchor:SetHide( fowState == BlackFog );
end
Events.SerialEventCityCreated.Add( OnCityCreated );

-------------------------------------------------------------------------------
-- Check the banner to see if it needs to be rebuilt (active player change)
-------------------------------------------------------------------------------
function CheckCityBannerRebuild( instance, iActiveTeam, iActivePlayer )

	local pPlayer = Players[ instance.playerID ];
	if pPlayer == nil then return; end

	-- If the city banner was instanced for the active team and now its not or vice versa, rebuild the banner
	local bWantActive = ( pPlayer:GetTeam() == iActiveTeam );
	if instance.IsActiveType == bWantActive then
		return;
	end

	local worldPos = HexToWorld( instance.Hex );
	local bWasHidden = instance.SubControls.Anchor:IsHidden();

	-- Release the old controls
	if instance.SubControls ~= nil then
		if instance.IsActiveType then
			g_TeamIM:ReleaseInstance( instance.SubControls );
		else
			g_OtherIM:ReleaseInstance( instance.SubControls );
		end
	end

	local controlTable = CreateBannerControls( instance.Hex, instance.playerID, instance.cityID, bWantActive );
	if bWantActive then
		CreateSVStrikeButton( instance.playerID, instance.cityID, worldPos );
	else
		ReleaseSVStrikeButton( instance.playerID, instance.cityID );
	end

	controlTable.Anchor:SetWorldPosition( VecAdd( worldPos, WorldPositionOffset ) );

	-- Attach
	instance.SubControls = controlTable;
	instance.IsActiveType = bWantActive;

	-- New controls: forget everything we cached about the old ones
	instance.LastName = nil;
	instance.LastReligion = nil;
	instance.LastProdKind = nil;
	instance.LastProdID = nil;
	instance.HealthBand = nil;
	instance.WarTipText = nil;
	instance.WarTipTurn = nil;
	instance.ProdButtonHooked = nil;
	instance.LastAlly = nil;
	instance.LastIndicator = nil;

	RefreshCityBanner( instance, iActiveTeam, iActivePlayer );

	-- Keep the hidden state
	controlTable.Anchor:SetHide( bWasHidden );
end

-------------------------------------------------
-- Change the width of the banner so it looks good with the length of the city name
-------------------------------------------------
function DoResizeBanner( BannerInstance )

	-- Just in case
	BannerInstance.NameStack:CalculateSize();
	BannerInstance.NameStack:ReprocessAnchoring();

	local iWidth = BannerInstance.NameStack:GetSizeX();

	-- If this control doesn't exist, then we're using the active player banner as opposed to the other player.
	-- NOTE:	There are rare instances when the active player will change (hotseat, autoplay) so just checking
	--			the active player is not good enough.
	if BannerInstance.CityBannerBaseFrame == nil then
		iWidth = iWidth + 60;	-- Offset for human player's banners

		if BannerInstance.CityBannerBackgroundIcon ~= nil then BannerInstance.CityBannerBackgroundIcon:SetSizeX( iWidth ); end
		if BannerInstance.CityBannerButtonGlow ~= nil then BannerInstance.CityBannerButtonGlow:SetSizeX( iWidth ); end
		if BannerInstance.CityBannerButtonBase ~= nil then BannerInstance.CityBannerButtonBase:SetSizeX( iWidth ); end
	else
		iWidth = iWidth + 10;	-- Offset for other player's banners
		BannerInstance.CityBannerBaseFrame:SetSizeX( iWidth );
	end

	BannerInstance.BannerButton:SetSizeX( iWidth );
	BannerInstance.CityBannerBackground:SetSizeX( iWidth );
	if BannerInstance.CityBannerBackgroundHL ~= nil then BannerInstance.CityBannerBackgroundHL:SetSizeX( iWidth ); end

	BannerInstance.BannerButton:ReprocessAnchoring();
	BannerInstance.NameStack:ReprocessAnchoring();
end

-------------------------------------------------
-- Refresh every visible banner (one spy lookup for the whole pass)
-------------------------------------------------
local function RefreshAllBanners()
	local iActivePlayer = Game.GetActivePlayer();
	local pActive = Players[ iActivePlayer ];
	if pActive == nil then return; end

	local iActiveTeam = pActive:GetTeam();
	local spyMap = BuildSpyMap( iActivePlayer );

	for _, playerBanners in pairs( Instances ) do
		for _, banner in pairs( playerBanners ) do
			local controls = banner.SubControls;
			-- Banners hidden by fog are refreshed when they are revealed (see OnHexFogEvent)
			if controls ~= nil and not controls.Anchor:IsHidden() then
				RefreshCityBanner( banner, iActiveTeam, iActivePlayer, spyMap );
			end
		end
	end
end

-------------------------------------------------
-- On City Update
-------------------------------------------------
function OnCityUpdate()
	if USE_DEFERRED_REFRESH then
		g_bAllDirty = true;
	else
		RefreshAllBanners();
	end
end
Events.SerialEventCityInfoDirty.Add( OnCityUpdate );
-- A city-state changed ally: banners need to swap their ally icon
if Events.MinorAlliesChanged ~= nil then
	Events.MinorAlliesChanged.Add( OnCityUpdate );
end

if USE_DEFERRED_REFRESH then
	-- Cheap per-frame check; the real work only happens when something was marked dirty.
	ContextPtr:SetUpdate( function()
		if g_bAllDirty then
			g_bAllDirty = false;
			RefreshAllBanners();
		end
	end );
end

-------------------------------------------------
-- On City Destroyed
-------------------------------------------------
function OnCityDestroyed( hexPos, playerID, cityID, newPlayerID )

	local playerTable = Instances[ playerID ];
	if playerTable == nil then return; end

	local banner = playerTable[ cityID ];
	if banner == nil then return; end

	if banner.SubControls ~= nil then
		if banner.IsActiveType then
			g_TeamIM:ReleaseInstance( banner.SubControls );
		else
			g_OtherIM:ReleaseInstance( banner.SubControls );
		end
	end

	ReleaseSVStrikeButton( playerID, cityID );
	playerTable[ cityID ] = nil;
end
Events.SerialEventCityDestroyed.Add( OnCityDestroyed );
Events.SerialEventCityCaptured.Add( OnCityDestroyed );

-------------------------------------------------
-- Refresh the City Damage bar
-------------------------------------------------
function RefreshCityDamage( instance, iDamage, iMaxDamage )

	if instance == nil or instance.SubControls == nil then
		return;
	end

	local controls = instance.SubControls;
	local healthBar = controls.CityBannerHealthBar;
	if healthBar == nil then
		return;
	end

	local iHealthPercent = 1;
	if iMaxDamage ~= nil and iMaxDamage > 0 then
		iHealthPercent = 1 - ( iDamage / iMaxDamage );
	end

	healthBar:SetPercent( iHealthPercent );

	-- Health bar colour based on amount of damage (only touched when the band changes)
	local band;
	if iHealthPercent > 0.66 then
		band = 3;
	elseif iHealthPercent > 0.33 then
		band = 2;
	else
		band = 1;
	end

	if instance.HealthBand ~= band then
		instance.HealthBand = band;
		if band == 3 then
			healthBar:SetFGColor( COLOR_HP_GREEN );
		elseif band == 2 then
			healthBar:SetFGColor( COLOR_HP_YELLOW );
		else
			healthBar:SetFGColor( COLOR_HP_RED );
		end
	end

	-- Show or hide the Health Bar as necessary
	local bHide = ( iDamage == 0 );
	SetHide( controls.CityBannerHealthBarBase, bHide );
	healthBar:SetHide( bHide );
end

-------------------------------------------------
-- On City Set Damage
-------------------------------------------------
function OnCitySetDamage( iPlayerID, iCityID, iDamage, iPreviousDamage )

	local playerTable = Instances[ iPlayerID ];
	if playerTable == nil then return; end

	local instance = playerTable[ iCityID ];
	if instance == nil then return; end

	local iMaxHitPoints;
	-- It is possible that the city is gone by now, but the banner still exists as messages are played back
	-- Get the max hit points from the city, but if it is not there get the global max.
	local pPlayer = Players[ iPlayerID ];
	local city = pPlayer and pPlayer:GetCityByID( iCityID );
	if city ~= nil then
		iMaxHitPoints = city:GetMaxHitPoints();
	else
		iMaxHitPoints = GameDefines[ "MAX_CITY_HIT_POINTS" ];
	end

	RefreshCityDamage( instance, iDamage, iMaxHitPoints );
end
Events.SerialEventCitySetDamage.Add( OnCitySetDamage );

-------------------------------------------------
-- On Specific City changed
-------------------------------------------------
function OnSpecificCityInfoDirty( iPlayerID, iCityID, eUpdateType )

	if eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_BANNER or
	   eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_ENEMY_IN_RANGE or
	   eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_GARRISON then

		local playerTable = Instances[ iPlayerID ];
		if playerTable == nil then
			return;
		end

		local instance = playerTable[ iCityID ];
		if instance == nil then
			return;
		end

		if eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_ENEMY_IN_RANGE then
			UpdateRangeStrikeIcon( instance );
		else
			instance.WarTipTurn = nil; -- something about this city changed: rebuild the cached war tooltip
			RefreshSingleBanner( instance );
		end
	end

end
Events.SpecificCityInfoDirty.Add( OnSpecificCityInfoDirty );

------------------------------------------------------------
------------------------------------------------------------
function OnHexFogEvent( hexPos, fowType, bWholeMap )
	if bWholeMap then
		local bHide = ( fowType == BlackFog );
		for _, playerTable in pairs( Instances ) do
			for _, instance in pairs( playerTable ) do
				instance.SubControls.Anchor:SetHide( bHide );
			end
		end
		if not bHide then
			OnCityUpdate(); -- banners that were skipped while hidden need a refresh
		end
	else
		local gridPosX, gridPosY = ToGridFromHex( hexPos.x, hexPos.y );
		local plot = Map.GetPlot( gridPosX, gridPosY );
		if plot == nil then return; end

		local city = plot:GetPlotCity();
		if city == nil then return; end

		local playerTable = Instances[ city:GetOwner() ];
		if playerTable == nil then return; end

		local instance = playerTable[ city:GetID() ];
		if instance == nil then return; end

		local anchor = instance.SubControls.Anchor;
		if fowType == BlackFog then
			anchor:SetHide( true );
		else
			local wasHidden = anchor:IsHidden();

			local garrisonedUnit = city:GetGarrisonedUnit();
			if garrisonedUnit and not UnitMoving( garrisonedUnit:GetOwner(), garrisonedUnit:GetID() ) then
				GarrisonComplete( instance, city );
			end

			anchor:SetHide( false );

			if wasHidden then
				RefreshSingleBanner( instance );
			end
		end
	end
end
Events.HexFOWStateChanged.Add( OnHexFogEvent );

-------------------------------------------------
-- Click handler helpers
-------------------------------------------------
-- Returns the city only if it belongs to the active player
local function GetActivePlayerCity( PlayerID, CityID )
	local player = Players[ PlayerID ];
	if player == nil or player:GetID() ~= Game.GetActivePlayer() then
		return nil;
	end
	return player:GetCityByID( CityID );
end

-------------------------------------------------
-- On City Range Strike Button Selected
-------------------------------------------------
function OnCityRangeStrikeButtonClick( PlayerID, CityID )
	local city = GetActivePlayerCity( PlayerID, CityID );
	if city == nil then return; end

	UI.SetInterfaceMode( InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK );
	UI.ClearSelectionList();
	UI.SelectCity( city );

	Events.InitCityRangeStrike( PlayerID, CityID );
end

function OnInitCityRangeStrike( PlayerID, CityID )
	local city = GetActivePlayerCity( PlayerID, CityID );
	if city == nil then return; end

	UI.SelectCity( city );
	UI.SetInterfaceMode( InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK );
end
Events.InitCityRangeStrike.Add( OnInitCityRangeStrike );

------------------------------------------------------------
-- OnEjectGarrisonClick - kick out the city's garrison!
------------------------------------------------------------
function OnEjectGarrisonClick( PlayerID, CityID )
	local city = GetActivePlayerCity( PlayerID, CityID );
	if city == nil then return; end

	local unit = city:GetGarrisonedUnit();
	if unit == nil then return; end

	UI.SetPlaceUnit( unit );
	UI.SetInterfaceMode( InterfaceModeTypes.INTERFACEMODE_PLACE_UNIT );
	OnCityUpdate();
	UI.HighlightCanPlacePlots( unit, city:Plot() );
end

------------------------------------------------------------
------------------------------------------------------------
function LeaderSelected( ePlayer )

	if not Players[ Game.GetActivePlayer() ]:IsTurnActive() or Game.IsProcessingMessages() then
		return;
	end

	local player = Players[ ePlayer ];
	if player == nil then return; end

	if player:IsHuman() then
		Events.OpenPlayerDealScreenEvent( ePlayer );
	else
		UI.SetRepeatActionPlayer( ePlayer );
		UI.ChangeStartDiploRepeatCount( 1 );
		player:DoBeginDiploWithHuman();
	end
end

------------------------------------------------------------
------------------------------------------------------------
function OnBannerClick( x, y )
	local plot = Map.GetPlot( x, y );
	if plot == nil then return; end

	local playerID = plot:GetOwner();
	local player = Players[ playerID ];
	local plotCity = plot:GetPlotCity();
	if player == nil or plotCity == nil then return; end

	-- Active player city
	if playerID == Game.GetActivePlayer() then
		-- Puppets are special
		if plotCity:IsPuppet() and not player:MayNotAnnex() then
			local popupInfo = {
				Type = ButtonPopupTypes.BUTTONPOPUP_ANNEX_CITY,
				Data1 = plotCity:GetID(),
				Data2 = -1,
				Data3 = -1,
				Option1 = false,
				Option2 = false;
			}
			Events.SerialEventGameMessagePopup( popupInfo );
		else
			UI.DoSelectCityAtPlot( plot );
		end

	-- Other player, which has been met
	elseif Teams[ Game.GetActiveTeam() ]:IsHasMet( player:GetTeam() ) then
		if player:IsMinorCiv() then
			UI.DoSelectCityAtPlot( plot );
		else
			LeaderSelected( playerID );
		end
	end
end

------------------------------------------------------------
------------------------------------------------------------
function GarrisonComplete( cityBanner, pCity )
	local pPlayer = Players[ cityBanner.playerID ];
	if pPlayer == nil then return; end

	if pPlayer:GetTeam() == Players[ Game.GetActivePlayer() ]:GetTeam() then
		SetHide( cityBanner.SubControls.GarrisonFrame, false );
	end
end

-------------------------------------------------
-- On Unit Garrison
-------------------------------------------------
function OnUnitGarrison( playerID, unitID, bGarrisoned )
	if bGarrisoned and not UnitMoving( playerID, unitID ) then
		local player = Players[ playerID ];
		local cityBanners = Instances[ playerID ];
		if player ~= nil and cityBanners ~= nil then
			local unit = player:GetUnitByID( unitID );
			if unit ~= nil then
				local city = unit:GetGarrisonedCity();
				if city ~= nil then
					local banner = cityBanners[ city:GetID() ];
					if banner ~= nil then
						GarrisonComplete( banner, city );
					end
				end
			end
		end
	end
end
Events.UnitGarrison.Add( OnUnitGarrison );

-------------------------------------------------
-- On Unit Move Queue Changed
-------------------------------------------------
function OnUnitMoveQueueChanged( playerID, unitID, bRemainingMoves )
	if not bRemainingMoves then
		local player = Players[ playerID ];
		local cityBanners = Instances[ playerID ];
		if player ~= nil and cityBanners ~= nil then
			local unit = player:GetUnitByID( unitID );
			if unit ~= nil and unit:IsGarrisoned() then
				local city = unit:GetGarrisonedCity();
				if city ~= nil then
					local banner = cityBanners[ city:GetID() ];
					if banner ~= nil then
						GarrisonComplete( banner, city );
					end
				end
			end
		end
	end
end
Events.UnitMoveQueueChanged.Add( OnUnitMoveQueueChanged );

-------------------------------------------------
-- Production button (only valid for the active player's own cities)
-------------------------------------------------
function OnProdClick( cityID, playerID )
	local activePlayerID = Game.GetActivePlayer();
	if playerID ~= nil and playerID ~= activePlayerID then
		return;
	end

	local activePlayer = Players[ activePlayerID ];
	if activePlayer == nil then return; end

	local city = activePlayer:GetCityByID( cityID );
	if city ~= nil and not city:IsPuppet() then
		local popupInfo = {
			Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
			Data1 = cityID,
			Data2 = -1,
			Data3 = -1,
			Option1 = false,
			Option2 = false;
		}
		Events.SerialEventGameMessagePopup( popupInfo );
		-- send production popup message
	end
end

------------------------------------------------------------
------------------------------------------------------------
function OnInterfaceModeChanged( oldInterfaceMode, newInterfaceMode )
	local disableBanners = ( newInterfaceMode ~= InterfaceModeTypes.INTERFACEMODE_SELECTION );
	if disableBanners == g_bBannersDisabled then
		return;
	end
	g_bBannersDisabled = disableBanners;

	for _, playerCityBanners in pairs( Instances ) do
		for _, cityBanner in pairs( playerCityBanners ) do
			ApplyBannerInteractivity( cityBanner.SubControls );
		end
	end
end
Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
g_bBannersDisabled = ( UI.GetInterfaceMode() ~= InterfaceModeTypes.INTERFACEMODE_SELECTION );

------------------------------------------------------------
------------------------------------------------------------
function OnStrategicViewStateChanged( bStrategicView, bCityBanners )
	local bShowBanners = bCityBanners or not bStrategicView;
	Controls.CityBanners:SetHide( not bShowBanners );
	Controls.StrategicViewStrikeButtons:SetHide( bShowBanners );
end
Events.StrategicViewStateChanged.Add( OnStrategicViewStateChanged );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnCityBannerActivePlayerChanged( iActivePlayer, iPrevActivePlayer )

	local pActive = Players[ iActivePlayer ];
	if pActive == nil then return; end

	local iActiveTeam = pActive:GetTeam();
	for _, v in pairs( Instances ) do
		for _, vCities in pairs( v ) do
			CheckCityBannerRebuild( vCities, iActiveTeam, iActivePlayer );
		end
	end

	-- Tooltips, spy icons, etc. are all relative to the active player: refresh everything
	OnCityUpdate();
end
Events.GameplaySetActivePlayer.Add( OnCityBannerActivePlayerChanged );

------------------------------------------------------------
------------------------------------------------------------
function HideGarrisonRing( iX, iY, bHide )

	local pPlot = Map.GetPlot( iX, iY );
	if pPlot == nil then return; end

	local pCity = pPlot:GetPlotCity();
	if pCity == nil then return; end

	local playerID = pCity:GetOwner();
	if playerID == -1 then return; end

	-- Only the active team has a Garrison ring
	local pActive = Players[ Game.GetActivePlayer() ];
	local pOwner = Players[ playerID ];
	if pActive == nil or pOwner == nil or pActive:GetTeam() ~= pOwner:GetTeam() then
		return;
	end

	local playerTable = Instances[ playerID ];
	local pBannerInstance = playerTable and playerTable[ pCity:GetID() ];
	if pBannerInstance == nil then return; end

	local frame = pBannerInstance.SubControls.GarrisonFrame;
	if frame == nil then return; end

	if bHide then
		frame:SetHide( true );
	elseif pCity:GetGarrisonedUnit() ~= nil then
		-- Only show it if we really need to
		frame:SetHide( false );
	end
end

------------------------------------------------------------
------------------------------------------------------------
function OnCombatBegin( attackerPlayerID,
                        attackerUnitID,
                        attackerUnitDamage,
                        attackerFinalUnitDamage,
                        attackerMaxHitPoints,
                        defenderPlayerID,
                        defenderUnitID,
                        defenderUnitDamage,
                        defenderFinalUnitDamage,
                        defenderMaxHitPoints,
                        bContinuation,
                        attackerX,
                        attackerY,
                        defenderX,
                        defenderY )
	HideGarrisonRing( attackerX, attackerY, true );
	HideGarrisonRing( defenderX, defenderY, true );
end
Events.RunCombatSim.Add( OnCombatBegin );

------------------------------------------------------------
------------------------------------------------------------
function OnCombatEnd( attackerPlayerID,
                      attackerUnitID,
                      attackerUnitDamage,
                      attackerFinalUnitDamage,
                      attackerMaxHitPoints,
                      defenderPlayerID,
                      defenderUnitID,
                      defenderUnitDamage,
                      defenderFinalUnitDamage,
                      defenderMaxHitPoints,
                      attackerX,
                      attackerY,
                      defenderX,
                      defenderY )
	HideGarrisonRing( attackerX, attackerY, false );
	HideGarrisonRing( defenderX, defenderY, false );
end
Events.EndCombatSim.Add( OnCombatEnd );

--------------------------------------------------------------
-- The active player's turn has begin, make sure their range strike icons are correct
--------------------------------------------------------------
function OnActivePlayerTurnStart()

	-- Picks up civs met since the last refresh (ally icons only show for met civs)
	OnCityUpdate();

	local playerTable = Instances[ Game.GetActivePlayer() ];
	if playerTable == nil then
		return;
	end

	-- City IDs are NOT contiguous (cities get lost / founded), so iterate the banners we
	-- actually have rather than GetCityByID( 0 .. NumCities-1 ).
	for _, pBannerInstance in pairs( playerTable ) do
		UpdateRangeStrikeIcon( pBannerInstance );
	end
end
Events.ActivePlayerTurnStart.Add( OnActivePlayerTurnStart );

------------------------------------------------------------
-- scan for all cities when we are loaded
-- this keeps the banners from disappearing on hotload
------------------------------------------------------------
if ContextPtr:IsHotLoad() then
	local i = 0;
	local player = Players[ i ];
	while player ~= nil do
		if player:IsAlive() then
			-- Cities() is the safe way to walk a player's cities (IDs are not contiguous)
			for city in player:Cities() do
				OnCityCreated( ToHexFromGrid( Vector2( city:GetX(), city:GetY() ) ), player:GetID(), city:GetID() );
			end
		end

		i = i + 1;
		player = Players[ i ];
	end
end