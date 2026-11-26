-------------------------------------------------
-- City State Diplo Popup (compact layout, stats, MP-safe)
-------------------------------------------------
include( "IconSupport" );
include( "InfoTooltipInclude" );

-------------------------------------------------
-- CONFIG: edit these values to taste
-------------------------------------------------
local kAnimInTime   = 0.7;   -- slide-in duration in seconds (0 = no animation, instant open)
local kAnimOutTime  = 0.7;   -- slide-out duration in seconds (0 = no animation, instant close)
local kSlideInDist  = 370;     -- pixels the popup travels while sliding in
local kSlideOutDist = 370;     -- pixels the popup travels while sliding out
local kPopupBaseY   = 60;     -- resting position; must match Offset="0,60" of the Popup grid in the XML
local kMouseCloseAnimated = true;  -- right click / mouse side button: false = close instantly, true = play slide-out
local kRivalInTooltip = true;   -- true: rival shows in the influence bar tooltip; false: shows as a line (RivalLabel in the XML)
local kMeterTextureGreen = "Assets/UI/Art/Notification/CityStateMeterBaseGreen.dds";  -- influence bar fill while influence >= 0 ("" = use the game's own colours)

-------------------------------------------------
-- Constants / state
-------------------------------------------------
local kPopupVPad       = 86;   -- popup height = MainStack height + this (top offset + bottom frame)
local kGiftLockFrames  = 45;   -- UI frames gift buttons stay locked after a click (anti double-click)

local g_iMinorCivID        = -1;
local g_iMinorCivTeamID    = -1;
local m_PopupInfo          = nil;
local lastBackgroundImage  = "citystatebackgroundculture.dds";

local g_bDirty             = false;  -- a refresh is queued for the next UI frame
local g_bGiftLocked        = false;
local g_iLockFrames        = 0;
local g_bPeaceRequested    = false;  -- we sent a peace request, waiting for the game state to catch up
local g_iPeaceTurn         = -1;
local g_sLayoutSignature   = "";
local g_sResourceCacheKey  = nil;    -- "<active>:<minor>:<turn>"
local g_sResourceCacheText = "";
local g_tTradeResources    = nil;    -- lazily built list of non-bonus resources
local g_sMeterTexture      = nil;    -- last texture set on the influence bar (avoids reloading it every refresh)

local iGoldGiftLarge  = GameDefines["MINOR_GOLD_GIFT_LARGE"];
local iGoldGiftMedium = GameDefines["MINOR_GOLD_GIFT_MEDIUM"];
local iGoldGiftSmall  = GameDefines["MINOR_GOLD_GIFT_SMALL"];

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function Try( fn, ... )
	local ok, v = pcall( fn, ... );
	if ok then return v; end
	return nil;
end

-- Returns v if it is a number, otherwise a default (guards against DLLs that return booleans/nil).
local function N( v, default )
	if type( v ) == "number" then return v; end
	return default or 0;
end

-- Calls obj:name(...) only if the method exists, and never throws. Returns nil on any failure.
local function Call( obj, name, ... )
	if obj == nil then return nil; end
	local f = obj[name];
	if f == nil then return nil; end
	return Try( f, obj, ... );
end

-- Sets text on a button, or on a label inside it (tries several likely label IDs).
-- Logs what it found to Lua.log to make XML mismatches easy to spot.
local function SetButtonText( button, text, labelNames )
	local bSet = false;
	for _, sName in ipairs( labelNames ) do
		local ctrl = Controls[sName];
		if ctrl ~= nil and ctrl.SetText ~= nil then
			Try( ctrl.SetText, ctrl, text );
			bSet = true;
			break;   -- one label is enough; setting more would draw the text twice
		end
	end
	-- Only fall back to the button's own text if there is no label inside it,
	-- otherwise the text is drawn twice, on top of itself.
	if not bSet and button ~= nil and button.SetText ~= nil then
		Try( button.SetText, button, text );
		bSet = true;
	end
	if not bSet then
		print( "CityStateDiploPopup: no text control found for button text '" .. tostring( text ) .. "'" );
	end
end

-- Replaces whatever tooltip the XML defined (including custom tooltip types) with a plain string.
local function SetPlainTooltip( ctrl, text )
	if ctrl == nil then return; end
	if ctrl.SetToolTipType ~= nil then Try( ctrl.SetToolTipType, ctrl, "" ); end
	if ctrl.SetToolTipCallback ~= nil then Try( ctrl.SetToolTipCallback, ctrl, nil ); end
	if ctrl.SetToolTipString ~= nil then Try( ctrl.SetToolTipString, ctrl, text ); end
end

-- Localised text if the key exists, otherwise the English fallback.
local function T( key, fallback )
	if Locale.HasTextKey ~= nil and not Locale.HasTextKey( key ) then
		return fallback;
	end
	local sText = Locale.ConvertTextKey( key );
	if sText == nil or sText == "" or sText == key then
		return fallback;
	end
	return sText;
end

-- Returns the minor civ player if it is still valid, otherwise nil.
local function GetMinor()
	local pPlayer = Players[g_iMinorCivID];
	if pPlayer == nil or not pPlayer:IsMinorCiv() or not pPlayer:IsAlive() then
		return nil;
	end
	return pPlayer;
end

-- In multiplayer you can open the popup while it is not your turn; the engine would reject
-- the commands anyway, so we disable them instead of letting the player spam dead clicks.
local function CanActNow()
	local pActive = Players[Game.GetActivePlayer()];
	return pActive ~= nil and pActive:IsAlive() and pActive:IsTurnActive();
end

local function GetTradeResources()
	if g_tTradeResources == nil then
		g_tTradeResources = {};
		for pResource in GameInfo.Resources() do
			if Game.GetResourceUsageType( pResource.ID ) ~= ResourceUsageTypes.RESOURCEUSAGE_BONUS then
				table.insert( g_tTradeResources, pResource );
			end
		end
	end
	return g_tTradeResources;
end

-- Static captions (set once)
Controls.PopCaption:SetText(  T( "TXT_KEY_CSDP_STAT_POPULATION", "Population" ) );
Controls.ProdCaption:SetText( T( "TXT_KEY_CSDP_STAT_PRODUCTION", "Production" ) );
Controls.SciCaption:SetText(  T( "TXT_KEY_CSDP_STAT_SCIENCE",    "Science" ) );
Controls.GoldCaption:SetText( T( "TXT_KEY_CSDP_STAT_GOLD",       "Gold" ) );

-------------------------------------------------
-- Can the active player pledge to protect this city-state right now?
-- Prefers the engine's own check (BNW / Community Patch / Vox Populi) and falls back to
-- "friends and not already protecting" on DLLs that don't have it.
-------------------------------------------------
local function CanPledge( pPlayer, pActivePlayer, iActivePlayer, bWar, bFriends )
	if bWar then return false; end

	if Call( pActivePlayer, "IsProtectingMinor", g_iMinorCivID ) == true then
		return false;
	end

	local vCan = Call( pPlayer, "CanMajorStartProtection", iActivePlayer );
	if vCan ~= nil then
		return vCan == true or (type( vCan ) == "number" and vCan ~= 0);
	end

	return bFriends;
end

-------------------------------------------------
-- Base tooltip text for the status row.
-- Returns a single string; Refresh() wraps it in a table and appends the bonus lines.
-------------------------------------------------
function GetCityStateStatus( pPlayer, iActivePlayer, bWar )
	local iFriendship = pPlayer:GetMinorCivFriendshipWithMajor( iActivePlayer );
	return Locale.ConvertTextKey( "TXT_KEY_POP_CSTATE_GOLD_STATUS_TT",
		GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"],
		GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"],
		iFriendship );
end

-------------------------------------------------
-- Open
-------------------------------------------------
function OnEventReceived( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO ) then
		return;
	end

	local iPlayer = popupInfo.Data1;
	local pPlayer = Players[iPlayer];
	if pPlayer == nil or not pPlayer:IsMinorCiv() or not pPlayer:IsAlive() then
		return;
	end

	m_PopupInfo = popupInfo;
	g_iMinorCivID = iPlayer;
	g_iMinorCivTeamID = pPlayer:GetTeam();

	-- fresh state for every opening
	g_bGiftLocked = false;
	g_iLockFrames = 0;
	g_bPeaceRequested = false;
	g_sResourceCacheKey = nil;
	g_sLayoutSignature = "";
	g_sMeterTexture = nil;

	SetupStatic( pPlayer );
	Refresh( false );

	UIManager:QueuePopup( ContextPtr, PopupPriority.CityStateDiplo );
end
Events.SerialEventGameMessagePopup.Add( OnEventReceived );

-------------------------------------------------
-- Slide / fade animation
-- Opens by sliding up from below while fading in, closes by sliding back down and fading out.
-------------------------------------------------
local g_sAnim       = nil;    -- nil / "in" / "out"
local g_fAnimT      = 0;
local g_bClosing    = false;

local function EaseOutCubic( t ) local u = 1 - t; return 1 - u * u * u; end
local function EaseInOutQuad( t )
	if t < 0.5 then return 2 * t * t; end
	local u = -2 * t + 2;
	return 1 - u * u / 2;
end

local function SetPopupPose( y, alpha )
	Try( Controls.Popup.SetOffsetVal, Controls.Popup, 0, y );
	if Controls.Popup.SetAlpha ~= nil then
		Try( Controls.Popup.SetAlpha, Controls.Popup, alpha );
	end
end

local function ApplyAnim( sMode, p )
	if sMode == "in" then
		local e = EaseOutCubic( p );
		SetPopupPose( kPopupBaseY + kSlideInDist * (1 - e), e );
	else
		local e = EaseInOutQuad( p );
		SetPopupPose( kPopupBaseY + kSlideOutDist * e, 1 - e );
	end
end

local function ResetPopupPose()
	g_sAnim = nil;
	g_bClosing = false;
	SetPopupPose( kPopupBaseY, 1 );
end

local function StartOpenAnim()
	g_bClosing = false;
	if kAnimInTime <= 0 then
		SetPopupPose( kPopupBaseY, 1 );
		return;
	end
	g_sAnim = "in";
	g_fAnimT = 0;
	ApplyAnim( "in", 0 );
	ContextPtr:SetUpdate( OnUpdate );
end

local function StartCloseAnim()
	if g_bClosing or ContextPtr:IsHidden() then return; end
	if kAnimOutTime <= 0 then
		UIManager:DequeuePopup( ContextPtr );
		return;
	end
	g_bClosing = true;
	g_sAnim = "out";
	g_fAnimT = 0;
	ContextPtr:SetUpdate( OnUpdate );
end

-- Immediate close, no animation (used when another screen takes over)
local function CloseNow()
	UIManager:DequeuePopup( ContextPtr );
end

-------------------------------------------------
-- Dirty events are coalesced: no matter how many arrive in one frame,
-- we refresh at most once, and only while the popup is visible.
-------------------------------------------------
function OnUpdate( fDTime )
	local fDT = fDTime;
	if type( fDT ) ~= "number" or fDT <= 0 or fDT > 0.1 then fDT = 1 / 60; end

	if g_sAnim ~= nil then
		g_fAnimT = g_fAnimT + fDT;
		local fDur = (g_sAnim == "in") and kAnimInTime or kAnimOutTime;
		local p = g_fAnimT / fDur;
		if p > 1 then p = 1; end
		ApplyAnim( g_sAnim, p );
		if p >= 1 then
			local sDone = g_sAnim;
			g_sAnim = nil;
			if sDone == "out" then
				g_bClosing = false;
				CloseNow();
				return;
			end
		end
	end

	if g_iLockFrames > 0 then
		g_iLockFrames = g_iLockFrames - 1;
		if g_iLockFrames == 0 then
			g_bGiftLocked = false;
			g_bDirty = true;
		end
	end

	if g_bDirty then
		g_bDirty = false;
		Refresh( false );
	end

	if not g_bDirty and g_iLockFrames == 0 and g_sAnim == nil then
		ContextPtr:ClearUpdate();
	end
end

function OnGameDataDirty()
	if ContextPtr:IsHidden() then
		return;
	end
	if not g_bDirty then
		g_bDirty = true;
		ContextPtr:SetUpdate( OnUpdate );
	end
end
Events.SerialEventGameDataDirty.Add( OnGameDataDirty );
if Events.ActivePlayerTurnStart ~= nil then Events.ActivePlayerTurnStart.Add( OnGameDataDirty ); end
if Events.ActivePlayerTurnEnd   ~= nil then Events.ActivePlayerTurnEnd.Add( OnGameDataDirty ); end

-------------------------------------------------
-- Things that never change while the popup is open
-------------------------------------------------
function SetupStatic( pPlayer )
	local sMinorCivType = pPlayer:GetMinorCivType();
	local trait = GameInfo.MinorCivilizations[sMinorCivType].MinorCivTrait;

	-- Colors
	local primaryColor, secondaryColor = pPlayer:GetPlayerColors();
	primaryColor, secondaryColor = secondaryColor, primaryColor;
	local textColor = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 1};

	-- Title
	local strTitle = Locale.ConvertTextKey( "{" .. pPlayer:GetCivilizationShortDescriptionKey() .. ":upper}" );
	Controls.TitleLabel:SetText( strTitle );
	Controls.TitleLabel:SetColor( textColor, 0 );

	local civInfo = GameInfo.Civilizations[pPlayer:GetCivilizationType()];
	if GameInfo.MinorCivTraits[trait].TraitTitleIcon ~= nil then
		Controls.TitleIcon:SetTexture( GameInfo.MinorCivTraits[trait].TraitTitleIcon );
	end
	IconHookup( civInfo.PortraitIndex, 32, civInfo.AlphaIconAtlas, Controls.CivIcon );
	Controls.CivIcon:SetColor( textColor );

	-- Background
	if GameInfo.MinorCivTraits[trait].BackgroundImage ~= nil then
		lastBackgroundImage = GameInfo.MinorCivTraits[trait].BackgroundImage;
	end
	Controls.BackgroundImage:SetTexture( lastBackgroundImage );

	-- Status icon (trait icon)
	if GameInfo.MinorCivTraits[trait].TraitIcon ~= nil then
		Controls.StatusIcon:SetTexture( GameInfo.MinorCivTraits[trait].TraitIcon );
	end

	-- Trait: icon only. The name and description show as a tooltip on the trait icon.
	-- Covers every trait type the game knows (incl. Mercantile / Religious) and
	-- falls back to a readable name for modded traits.
	local iTrait = pPlayer:GetMinorCivTrait();
	local sTraitName, sTraitDesc = nil, nil;
	for _, sSuffix in ipairs( { "CULTURED", "MILITARISTIC", "MARITIME", "MERCANTILE", "RELIGIOUS" } ) do
		local eTrait = MinorCivTraitTypes[ "MINOR_CIV_TRAIT_" .. sSuffix ];
		if eTrait ~= nil and eTrait == iTrait then
			sTraitName = T( "TXT_KEY_CITY_STATE_" .. sSuffix .. "_ADJECTIVE", nil );
			sTraitDesc = T( "TXT_KEY_CITY_STATE_" .. sSuffix .. "_TT", nil );
			if sTraitName == nil then
				sTraitName = string.sub( sSuffix, 1, 1 ) .. string.lower( string.sub( sSuffix, 2 ) );
			end
		end
	end
	if sTraitName == nil then
		local sType = tostring( trait );
		sType = string.gsub( sType, "^MINOR_CIV_TRAIT_", "" );
		sType = string.gsub( sType, "^MINOR_TRAIT_", "" );
		sTraitName = string.sub( sType, 1, 1 ) .. string.lower( string.sub( sType, 2 ) );
	end
	local strTraitTT = "[COLOR_POSITIVE_TEXT]" .. sTraitName .. "[ENDCOLOR]";
	if sTraitDesc ~= nil then
		strTraitTT = strTraitTT .. "[NEWLINE][NEWLINE]" .. sTraitDesc;
	end
	SetPlainTooltip( Controls.StatusIcon, strTraitTT );

	local strAllyTT = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_ALLY_TT");
	Controls.AllyInfo:SetToolTipString( strAllyTT );
	Controls.AllyLabel:SetToolTipString( strAllyTT );

	-- Gift Unit / Pledge: set text and tooltips from Lua so they never depend on the XML.
	local sGiftUnit   = T( "TXT_KEY_POP_CSTATE_GIFT_UNIT", "Gift Unit" );
	local sGiftUnitTT = T( "TXT_KEY_POP_CSTATE_GIFT_UNIT_TT", "Gift a military unit to this city-state to gain influence." );
	SetButtonText( Controls.UnitGiftButton, sGiftUnit,
		{ "UnitGiftLabel", "UnitGift", "UnitGiftText", "GiftUnitLabel", "GiftUnit", "UnitGiftButtonLabel", "UnitLabel" } );
	SetPlainTooltip( Controls.UnitGiftButton, sGiftUnitTT );

	SetButtonText( Controls.PledgeButton, T( "TXT_KEY_POP_CSTATE_PLEDGE_TO_PROTECT", "Pledge to Protect" ),
		{ "PledgeLabel" } );

	local sPledgeTT = T( "TXT_KEY_POP_CSTATE_PLEDGE_PROTECTION_TT",
		"Pledge to protect this city-state. Its influence with you will decay more slowly, but you may be drawn into its wars." );
	SetPlainTooltip( Controls.PledgeButton, sPledgeTT );

	local strResourceTT = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_RESOURCES_TT");
	Controls.ResourcesInfo:SetToolTipString( strResourceTT );
	Controls.ResourcesLabel:SetToolTipString( strResourceTT );
end

-------------------------------------------------
-- Nearby resources (11x11 plot scan). Cached per active player / minor / turn.
-------------------------------------------------
function GetNearbyResourceText( pPlayer, iActivePlayer )
	local sKey = iActivePlayer .. ":" .. g_iMinorCivID .. ":" .. Game.GetGameTurn();
	if sKey == g_sResourceCacheKey then
		return g_sResourceCacheText;
	end

	local tParts = {};
	local pCapital = pPlayer:GetCapitalCity();

	if pCapital ~= nil then
		local thisX = pCapital:GetX();
		local thisY = pCapital:GetY();
		local iRange = 5;
		local iCloseRange = 2;
		local iActiveTeam = Game.GetActiveTeam();

		for iDX = -iRange, iRange do
			for iDY = -iRange, iRange do
				local pPlot = Map.GetPlotXY( thisX, thisY, iDX, iDY );
				if pPlot ~= nil then
					local iOwner = pPlot:GetOwner();
					if (iOwner == g_iMinorCivID or iOwner == -1) then
						local iDist = Map.PlotDistance( thisX, thisY, pPlot:GetX(), pPlot:GetY() );
						if (iDist <= iRange and (iDist <= iCloseRange or iOwner == g_iMinorCivID)) then
							local iResourceType = pPlot:GetResourceType( iActiveTeam );
							if (iResourceType ~= -1
								and Game.GetResourceUsageType( iResourceType ) ~= ResourceUsageTypes.RESOURCEUSAGE_BONUS) then
								local pResource = GameInfo.Resources[iResourceType];
								table.insert( tParts, pResource.IconString .. " [COLOR_POSITIVE_TEXT]"
									.. Locale.ConvertTextKey( pResource.Description )
									.. " (" .. pPlot:GetNumResource() .. ") [ENDCOLOR]" );
							end
						end
					end
				end
			end
		end
	end

	g_sResourceCacheKey = sKey;
	g_sResourceCacheText = table.concat( tParts, ", " );
	return g_sResourceCacheText;
end

-------------------------------------------------
-- Stats (Population / Production / Science / Gold)
-------------------------------------------------
local function SetStat( ctrl, icon, value )
	if value == nil then
		ctrl:SetText( icon .. " -" );
	else
		ctrl:SetText( icon .. " " .. tostring( math.floor( value + 0.5 ) ) );
	end
end

function UpdateStats( pPlayer )
	local iPop, iProd, iSciCities = 0, 0, 0;
	local iCities = 0;

	for pCity in pPlayer:Cities() do
		iCities = iCities + 1;
		iPop  = iPop  + (Try( pCity.GetPopulation, pCity ) or 0);
		iProd = iProd + (Try( pCity.GetYieldRate, pCity, YieldTypes.YIELD_PRODUCTION ) or 0);
		local iSciT100 = Try( pCity.GetYieldRateTimes100, pCity, YieldTypes.YIELD_SCIENCE );
		if iSciT100 ~= nil then
			iSciCities = iSciCities + iSciT100 / 100;
		else
			iSciCities = iSciCities + (Try( pCity.GetYieldRate, pCity, YieldTypes.YIELD_SCIENCE ) or 0);
		end
	end

	local iScience = Try( pPlayer.GetScience, pPlayer );
	if iScience == nil then iScience = iSciCities; end

	local iGold   = Try( pPlayer.GetGold, pPlayer );
	local iIncome = Try( pPlayer.CalculateGoldRate, pPlayer );

	SetStat( Controls.PopValue,  "[ICON_CITIZEN]",    iPop );
	SetStat( Controls.ProdValue, "[ICON_PRODUCTION]", iProd );
	SetStat( Controls.SciValue,  "[ICON_RESEARCH]",   iScience );
	SetStat( Controls.GoldValue, "[ICON_GOLD]",       iGold );

	Controls.PopButton:SetToolTipString(  T( "TXT_KEY_CSDP_STAT_POPULATION_TT", "Total population across all city-state cities" ) .. " (" .. iCities .. ")" );
	Controls.ProdButton:SetToolTipString( T( "TXT_KEY_CSDP_STAT_PRODUCTION_TT", "Production per turn" ) );
	Controls.SciButton:SetToolTipString(  T( "TXT_KEY_CSDP_STAT_SCIENCE_TT",    "Science per turn" ) );

	local strGoldTT = T( "TXT_KEY_CSDP_STAT_GOLD_TT", "Gold in the city-state's treasury" );
	if iIncome ~= nil then
		strGoldTT = strGoldTT .. "[NEWLINE]" .. (iIncome >= 0 and "+" or "") .. tostring( math.floor( iIncome + 0.5 ) ) .. " [ICON_GOLD] / turn";
	end
	Controls.GoldButton:SetToolTipString( strGoldTT );
end

-------------------------------------------------
-- Gift buttons (gold amounts + unit)
-------------------------------------------------
function UpdateGiftButtons( pPlayer, bCanAct )
	local iActivePlayer = Game.GetActivePlayer();
	local pActivePlayer = Players[iActivePlayer];
	local iGoldHave = pActivePlayer:GetGold();

	local tGifts = {
		{ iGoldGiftSmall,  Controls.SmallGift,  Controls.SmallGiftButton },
		{ iGoldGiftMedium, Controls.MediumGift, Controls.MediumGiftButton },
		{ iGoldGiftLarge,  Controls.LargeGift,  Controls.LargeGiftButton },
	};

	for _, g in ipairs( tGifts ) do
		local iGold, label, button = g[1], g[2], g[3];
		local iInfluence = pPlayer:GetFriendshipFromGoldGift( iActivePlayer, iGold );
		local sText = Locale.ConvertTextKey( "TXT_KEY_POPUP_MINOR_GOLD_GIFT_AMOUNT", iGold, iInfluence );
		local bAfford = iGoldHave >= iGold;
		if not bAfford then
			sText = "[COLOR_WARNING_TEXT]" .. sText .. "[ENDCOLOR]";
		end
		label:SetText( sText );
		button:SetDisabled( g_bGiftLocked or not bCanAct or not bAfford );
	end

	Controls.UnitGiftButton:SetDisabled( g_bGiftLocked or not bCanAct );

	-- Tooltip
	local iFriendsAmount = GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"];
	local iAlliesAmount  = GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"];
	local iFriendship    = pPlayer:GetMinorCivFriendshipWithMajor( iActivePlayer );
	local strInfoTT = Locale.ConvertTextKey( "TXT_KEY_POP_CSTATE_GOLD_STATUS_TT", iFriendsAmount, iAlliesAmount, iFriendship );
	strInfoTT = strInfoTT .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey( "TXT_KEY_POP_CSTATE_GOLD_TT" );
	Controls.SmallGiftButton:SetToolTipString( strInfoTT );
	Controls.MediumGiftButton:SetToolTipString( strInfoTT );
	Controls.LargeGiftButton:SetToolTipString( strInfoTT );
end

-------------------------------------------------
-- Status bar helper (defined before Refresh, which uses it)
-------------------------------------------------
-- Looks up a MinorCivTraits_Status row, trying several possible Type names.
local function FindStatusRow( ... )
	for _, sType in ipairs( { ... } ) do
		local row = GameInfo.MinorCivTraits_Status[sType];
		if row ~= nil then return row; end
	end
	return nil;
end

local function SafeRatio( num, den )
	if den == nil or den == 0 then return 0; end
	local v = num / den;
	if v < 0 then v = 0; end
	if v > 1 then v = 1; end
	return v;
end

function GetStatusRow( status )
	local tResult = {};
	local iNeutral = N( GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"], 0 );
	local iFriends = N( GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"], 30 );
	local iAllies  = N( GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"], 60 );
	local iMax     = N( GameDefines["FRIENDSHIP_THRESHOLD_MAX"], 120 );
	status = N( status, 0 );

	if status < iNeutral then
		tResult.row   = FindStatusRow( "MINOR_FRIENDSHIP_AT_WAR", "FRIENDSHIP_AT_WAR" );
		tResult.value = SafeRatio( status, GameDefines["MINOR_FRIENDSHIP_AT_WAR"] );
	elseif status < iFriends then
		tResult.row   = FindStatusRow( "MINOR_FRIENDSHIP_NEUTRAL", "FRIENDSHIP_THRESHOLD_NEUTRAL" );
		tResult.value = SafeRatio( status - iNeutral, iFriends - iNeutral );
	elseif status < iAllies then
		tResult.row   = FindStatusRow( "MINOR_FRIENDSHIP_FRIENDS", "FRIENDSHIP_THRESHOLD_FRIENDS" );
		tResult.value = SafeRatio( status - iFriends, iAllies - iFriends );
	else
		tResult.row   = FindStatusRow( "MINOR_FRIENDSHIP_ALLIES", "FRIENDSHIP_THRESHOLD_ALLIES" );
		tResult.value = SafeRatio( status - iAllies, iMax - iAllies );
	end
	return tResult;
end

-------------------------------------------------
-- Top rival for this city-state's influence
-------------------------------------------------
function GetRival( pPlayer, iActivePlayer, iActiveTeam )
	local iBest, iBestVal = -1, 0;

	for iLoop = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		if iLoop ~= iActivePlayer then
			local pOther = Players[iLoop];
			if pOther ~= nil and pOther:IsAlive() and Teams[pOther:GetTeam()]:IsHasMet( iActiveTeam ) then
				local iVal = N( Try( pPlayer.GetMinorCivFriendshipWithMajor, pPlayer, iLoop ) );
				if iVal > iBestVal then
					iBest, iBestVal = iLoop, iVal;
				end
			end
		end
	end

	local sCaption = T( "TXT_KEY_CSDP_RIVAL", "Rival" );
	local sYou = T( "TXT_KEY_CSDP_RIVAL_YOU", "You" );
	local iMine = N( Try( pPlayer.GetMinorCivFriendshipWithMajor, pPlayer, iActivePlayer ) );
	local sText, sTT;

	if iBest ~= -1 then
		local sName = Locale.ConvertTextKey( Players[iBest]:GetCivilizationShortDescriptionKey() );
		local sColor = (iBestVal > iMine) and "[COLOR_NEGATIVE_TEXT]" or "[COLOR_POSITIVE_TEXT]";
		sText = sCaption .. ": " .. sColor .. sName .. " (" .. iBestVal .. ")[ENDCOLOR]";
		sTT = sText .. "  -  " .. sYou .. ": " .. iMine;
	else
		sText = sCaption .. ": " .. T( "TXT_KEY_CITY_STATE_NOBODY", "Nobody" );
		sTT = sText;
	end
	return sText, sTT;
end

-------------------------------------------------
-- Main refresh
-------------------------------------------------
function RefreshImpl( bForcePeace )

	local pPlayer = GetMinor();
	if pPlayer == nil then
		-- the city state was destroyed / became invalid while we were open
		if not ContextPtr:IsHidden() then
			UIManager:DequeuePopup( ContextPtr );
		end
		return;
	end

	local iActivePlayer = Game.GetActivePlayer();
	local pActivePlayer = Players[iActivePlayer];
	local iActiveTeam   = Game.GetActiveTeam();
	local pActiveTeam   = Teams[iActiveTeam];
	local iPlayer       = g_iMinorCivID;
	local iTeam         = g_iMinorCivTeamID;
	local pTeam         = Teams[iTeam];

	local bAllies  = pPlayer:IsAllies( iActivePlayer );
	local bFriends = pPlayer:IsFriends( iActivePlayer );
	local bCanAct  = CanActNow();

	-- At war? (a pending peace request keeps showing peace until the game state catches up or the turn changes)
	local bRealWar = pActiveTeam:IsAtWar( iTeam );
	if g_bPeaceRequested then
		if (not bRealWar) or Game.GetGameTurn() ~= g_iPeaceTurn then
			if not bRealWar then bForcePeace = true; end
			g_bPeaceRequested = false;
		else
			bForcePeace = true;
		end
	end
	local bWar = bRealWar;
	if bForcePeace then bWar = false; end

	local iTrait = pPlayer:GetMinorCivTrait();

	---------------------------------------------------------------
	-- Status text + tooltip
	---------------------------------------------------------------
	local strStatusText;
	if bAllies then
		strStatusText = "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_ALLIES") .. "[ENDCOLOR]";
	elseif bFriends then
		strStatusText = "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_FRIENDS") .. "[ENDCOLOR]";
	elseif pPlayer:IsMinorPermanentWar( iActiveTeam ) then
		strStatusText = "[COLOR_NEGATIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_PERMANENT_WAR") .. "[ENDCOLOR]";
	elseif pPlayer:IsPeaceBlocked( iActiveTeam ) then
		strStatusText = "[COLOR_NEGATIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_PEACE_BLOCKED") .. "[ENDCOLOR]";
	elseif bWar then
		strStatusText = "[COLOR_NEGATIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_WAR") .. "[ENDCOLOR]";
	elseif pPlayer:GetMinorCivFriendshipWithMajor( iActivePlayer ) < 0 then
		strStatusText = "[COLOR_NEGATIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_ANGRY") .. "[ENDCOLOR]";
	else
		strStatusText = "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_NEUTRAL") .. "[ENDCOLOR]";
	end

	local tTT = { GetCityStateStatus( pPlayer, iActivePlayer, bWar ) };

	if Call( pPlayer, "IsPlayerHasOpenBorders", iActivePlayer ) then
		if Call( pPlayer, "IsPlayerHasOpenBordersAutomatically", iActivePlayer ) then
			table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_OPEN_BORDERS_TRAIT") );
		else
			table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_OPEN_BORDERS_FRIENDS") );
		end
	end

	local iCultureBonus = N( Call( pPlayer, "GetCurrentCultureBonus", iActivePlayer ) );
	if iCultureBonus ~= 0 then
		table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_CULTURE_BONUS", iCultureBonus) );
	end

	local iCapitalFoodBonus   = N( Call( pPlayer, "GetCurrentCapitalFoodBonus", iActivePlayer ) ) / 100;
	local iOtherCityFoodBonus = N( Call( pPlayer, "GetCurrentOtherCityFoodBonus", iActivePlayer ) ) / 100;
	if iCapitalFoodBonus ~= 0 or iOtherCityFoodBonus ~= 0 then
		table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_FOOD_BONUS", iCapitalFoodBonus, iOtherCityFoodBonus) );
	end

	local iSpawn = N( Call( pPlayer, "GetCurrentSpawnEstimate", iActivePlayer ) );
	if iSpawn ~= 0 then
		table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_MILITARY_BONUS", iSpawn) );
	end

	local iScienceBonus = N( Call( pPlayer, "GetCurrentScienceFriendshipBonusTimes100", iActivePlayer ) );
	if iScienceBonus ~= 0 then
		table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_SCIENCE_BONUS", iScienceBonus / 100) );
	end

	-- Exported resources (only shown in the tooltip for allies)
	if bAllies then
		local tExp = {};
		for _, pResource in ipairs( GetTradeResources() ) do
			local iAmount = N( Call( pPlayer, "GetResourceExport", pResource.ID ) );
			if iAmount > 0 then
				table.insert( tExp, pResource.IconString .. " [COLOR_POSITIVE_TEXT]"
					.. Locale.ConvertTextKey( pResource.Description ) .. " (" .. iAmount .. ") [ENDCOLOR]" );
			end
		end
		if #tExp > 0 then
			table.insert( tTT, Locale.ConvertTextKey("TXT_KEY_CSTATE_RESOURCES_RECEIVED", table.concat( tExp )) );
		end
	end

	-- Top rival: the civ (other than you) with the most influence here (met civs only).
	local sRivalText, sRivalTT = GetRival( pPlayer, iActivePlayer, iActiveTeam );
	if kRivalInTooltip then
		table.insert( tTT, sRivalTT );
	elseif Controls.RivalLabel ~= nil then
		Controls.RivalLabel:SetText( sRivalText );
		Controls.RivalLabel:SetToolTipString( sRivalTT );
	end

	local strStatusTT = table.concat( tTT, "[NEWLINE][NEWLINE]" );

	local info = GetStatusRow( pPlayer:GetMinorCivFriendshipWithMajor( iActivePlayer ) );
	-- Green fill while influence is positive; negative influence keeps the game's own (red) bar.
	local sMeterTexture = nil;
	if N( pPlayer:GetMinorCivFriendshipWithMajor( iActivePlayer ) ) >= 0
		and kMeterTextureGreen ~= nil and kMeterTextureGreen ~= "" then
		sMeterTexture = kMeterTextureGreen;
	elseif info.row ~= nil then
		sMeterTexture = info.row.StatusMeter;
	end
	if sMeterTexture ~= nil and sMeterTexture ~= g_sMeterTexture then
		g_sMeterTexture = sMeterTexture;
		Controls.StatusMeter:SetTexture( sMeterTexture );
	end
	Controls.StatusMeter:SetPercent( info.value );
	Controls.StatusInfo:SetText( strStatusText );
	Controls.StatusInfo:SetToolTipString( strStatusTT );
	Controls.StatusLabel:SetToolTipString( strStatusTT );
	--Controls.StatusIconBG:SetToolTipString( strStatusTT );
	Controls.StatusMeter:SetToolTipString( strStatusTT );

	---------------------------------------------------------------
	-- Personality
	---------------------------------------------------------------
	local iPersonality = pPlayer:GetPersonality();
	local strPersonalityText, strPersonalityTT = "", "";
	if iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_FRIENDLY then
		strPersonalityText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_FRIENDLY");
		strPersonalityTT   = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_FRIENDLY_TT");
	elseif iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_NEUTRAL then
		strPersonalityText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_NEUTRAL");
		strPersonalityTT   = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_NEUTRAL_TT");
	elseif iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_HOSTILE then
		strPersonalityText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_HOSTILE");
		strPersonalityTT   = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_HOSTILE_TT");
	elseif iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_IRRATIONAL then
		strPersonalityText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_IRRATIONAL");
		strPersonalityTT   = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_IRRATIONAL_TT");
	end
	Controls.PersonalityInfo:SetText( "[COLOR_POSITIVE_TEXT]" .. strPersonalityText .. "[ENDCOLOR]" );
	Controls.PersonalityInfo:SetToolTipString( strPersonalityTT );
	Controls.PersonalityLabel:SetToolTipString( strPersonalityTT );

	---------------------------------------------------------------
	-- Ally
	---------------------------------------------------------------
	local iAlly = pPlayer:GetAlly();
	if iAlly ~= nil and iAlly ~= -1 then
		if iAlly ~= iActivePlayer then
			if Teams[Players[iAlly]:GetTeam()]:IsHasMet( iActiveTeam ) then
				Controls.AllyInfo:SetText( "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey( Players[iAlly]:GetCivilizationShortDescriptionKey() ) .. "[ENDCOLOR]" );
			else
				Controls.AllyInfo:SetText( "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_UNMET_PLAYER") .. "[ENDCOLOR]" );
			end
		else
			Controls.AllyInfo:SetText( "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_YOU") .. "[ENDCOLOR]" );
		end
	else
		Controls.AllyInfo:SetText( Locale.ConvertTextKey("TXT_KEY_CITY_STATE_NOBODY") );
	end

	---------------------------------------------------------------
	-- Stats + resources
	---------------------------------------------------------------
	UpdateStats( pPlayer );

	local strResources = GetNearbyResourceText( pPlayer, iActivePlayer );
	Controls.ResourcesInfo:SetText( strResources );
	Controls.ResourcesGroup:SetHide( strResources == "" );

	---------------------------------------------------------------
	-- Body text
	---------------------------------------------------------------
	local strText = "";

	if not bWar then

		if bForcePeace then
			strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_PEACE_JUST_MADE");
		else
			if iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_FRIENDLY then
				strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_HELLO_PEACE_FRIENDLY");
			elseif iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_NEUTRAL then
				strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_HELLO_PEACE_NEUTRAL");
			elseif iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_HOSTILE then
				strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_HELLO_PEACE_HOSTILE");
			elseif iPersonality == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_IRRATIONAL then
				strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_HELLO_PEACE_IRRATIONAL");
			end
		end

		local strQuestString = "";
		local tWar = {};

		for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1 do
			if iPlayerLoop ~= iActivePlayer then
				local pOther = Players[iPlayerLoop];
				if pOther ~= nil and pOther:IsAlive() and pTeam:IsAtWar( pOther:GetTeam() ) then
					if Call( pPlayer, "IsMinorWarQuestWithMajorActive", iPlayerLoop ) then
						table.insert( tWar, Locale.ConvertTextKey( pOther:GetNameKey() ) );
					end
				end
			end
		end

		if #tWar > 0 then
			strQuestString = strQuestString .. " " .. Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_WAR_WITH_PLAYERS", table.concat( tWar, ", " ));
		end

		local vBarb = Try( pPlayer.GetTurnsSinceThreatenedByBarbarians, pPlayer );
		if (type( vBarb ) == "number" and vBarb >= 0) or vBarb == true then
			strQuestString = strQuestString .. " " .. Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_BARBARIANS");
		end

		-- Quest API differs between DLL versions (some return a boolean or have a different name),
		-- so every call is guarded and the quest text is built defensively.
		local iQuest = Try( pPlayer.GetActiveQuestForPlayer, pPlayer, iActivePlayer );
		if type( iQuest ) ~= "number" then
			iQuest = Try( pPlayer.GetFirstActiveQuestForPlayer, pPlayer, iActivePlayer );
		end
		if type( iQuest ) ~= "number" then iQuest = -1; end

		local iQuestData1 = Try( pPlayer.GetQuestData1, pPlayer, iActivePlayer, iQuest );
		if type( iQuestData1 ) ~= "number" then iQuestData1 = -1; end

		if iQuest >= 0 then
			if strQuestString ~= "" then
				strQuestString = strQuestString .. " " .. Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_ONE_MORE_THING");
			end

			local ok, sQuest = pcall( function()
				if iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_ROUTE then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_ROUTE");
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_KILL_CAMP then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_KILL_CAMP");
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_CONNECT_RESOURCE then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_CONNECT_RESOURCE", GameInfo.Resources[iQuestData1].Description);
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_CONSTRUCT_WONDER then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_CONSTRUCT_WONDER", GameInfo.Buildings[iQuestData1].Description);
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_GREAT_PERSON then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_GREAT_PERSON", GameInfo.Units[iQuestData1].Description);
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_KILL_CITY_STATE then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_KILL_CITY_STATE", Players[iQuestData1]:GetNameKey());
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_FIND_PLAYER then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_FIND_PLAYER", Players[iQuestData1]:GetCivilizationShortDescriptionKey());
				elseif iQuest == MinorCivQuestTypes.MINOR_CIV_QUEST_FIND_NATURAL_WONDER then
					return Locale.ConvertTextKey("TXT_KEY_CITY_STATE_QUEST_FIND_NATURAL_WONDER");
				end
				return nil;
			end );
			if ok and sQuest ~= nil then
				strQuestString = strQuestString .. " " .. sQuest;
			end
		end

		strText = strText .. strQuestString;

		-- Unit spawning toggle (militaristic friends only)
		local bShowSpawn = (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC and bFriends);
		Controls.NoUnitSpawningButton:SetHide( not bShowSpawn );
		if bShowSpawn then
			if pPlayer:IsMinorCivUnitSpawningDisabled( iActivePlayer ) then
				Controls.NoUnitSpawningLabel:SetText( Locale.ConvertTextKey("TXT_KEY_CITY_STATE_TURN_SPAWNING_ON") );
			else
				Controls.NoUnitSpawningLabel:SetText( Locale.ConvertTextKey("TXT_KEY_CITY_STATE_TURN_SPAWNING_OFF") );
			end
		end

		Controls.GiftStack:SetHide( false );
		Controls.PeaceButton:SetHide( true );
		Controls.WarButton:SetHide( false );

	else -- at war

		if pPlayer:IsPeaceBlocked( iActiveTeam ) then
			strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_HELLO_WARMONGER");
			Controls.PeaceButton:SetHide( true );
		else
			strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_DIPLO_HELLO_WAR");
			Controls.PeaceButton:SetHide( false );
		end

		Controls.GiftStack:SetHide( true );
		Controls.WarButton:SetHide( true );
		Controls.NoUnitSpawningButton:SetHide( true );
	end

	-- Pledge: must be friends, not at war, not already protecting
	Controls.PledgeButton:SetHide( not CanPledge( pPlayer, pActivePlayer, iActivePlayer, bWar, bFriends ) );

	-- Game options
	if Game.IsOption( GameOptionTypes.GAMEOPTION_ALWAYS_WAR ) then
		Controls.PeaceButton:SetHide( true );
	end
	if Game.IsOption( GameOptionTypes.GAMEOPTION_ALWAYS_PEACE ) then
		Controls.WarButton:SetHide( true );
	end
	if Game.IsOption( GameOptionTypes.GAMEOPTION_NO_CHANGING_WAR_PEACE ) then
		Controls.PeaceButton:SetHide( true );
		Controls.WarButton:SetHide( true );
	end

	Controls.DescriptionLabel:SetText( strText );

	---------------------------------------------------------------
	-- Enable / disable (multiplayer: only on our own active turn)
	---------------------------------------------------------------
	Controls.PeaceButton:SetDisabled( not bCanAct );
	Controls.WarButton:SetDisabled( not bCanAct );
	Controls.PledgeButton:SetDisabled( not bCanAct );
	Controls.NoUnitSpawningButton:SetDisabled( not bCanAct );

	if not bWar then
		UpdateGiftButtons( pPlayer, bCanAct );
	end

	Controls.ActionStack:SetHide( Controls.PeaceButton:IsHidden() and Controls.WarButton:IsHidden()
		and Controls.PledgeButton:IsHidden() and Controls.NoUnitSpawningButton:IsHidden() );

	UpdateLayout( strText, strResources );
end

-- Safe wrapper: a script error in one refresh is logged instead of breaking the popup.
function Refresh( bForcePeace )
	local ok, err = pcall( RefreshImpl, bForcePeace );
	if not ok then
		print( "CityStateDiploPopup Refresh error: " .. tostring( err ) );
	end
end

-------------------------------------------------
-- Popup height follows the content; only recalculated when the layout can have changed.
-------------------------------------------------
function UpdateLayout( strText, strResources )
	local tSig = {
		strText, strResources,
		Controls.ResourcesGroup:IsHidden() and 1 or 0,
		Controls.GiftStack:IsHidden() and 1 or 0,
		Controls.ActionStack:IsHidden() and 1 or 0,
		Controls.PeaceButton:IsHidden() and 1 or 0,
		Controls.WarButton:IsHidden() and 1 or 0,
		Controls.PledgeButton:IsHidden() and 1 or 0,
		Controls.NoUnitSpawningButton:IsHidden() and 1 or 0,
	};
	local sSig = table.concat( tSig, "|" );
	if sSig == g_sLayoutSignature then
		return;
	end
	g_sLayoutSignature = sSig;

	Controls.ResourcesGroup:CalculateSize();
	Controls.GiftStack:CalculateSize();
	Controls.ActionStack:CalculateSize();
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();
	Controls.Popup:SetSizeY( Controls.MainStack:GetSizeY() + kPopupVPad );
	Controls.Popup:ReprocessAnchoring();
end

----------------------------------------------------------------
-- Input processing
----------------------------------------------------------------

-------------------------------------------------------------------------------
-- GOLD GIFTS (all three amounts are always on screen)
-------------------------------------------------------------------------------
local function DoGoldGift( iAmount )
	if g_bGiftLocked then return; end                       -- double-click guard
	if GetMinor() == nil then return; end
	if not CanActNow() then return; end                     -- not our turn (MP)
	if Teams[Game.GetActiveTeam()]:IsAtWar( g_iMinorCivTeamID ) then return; end
	if Players[Game.GetActivePlayer()]:GetGold() < iAmount then return; end   -- re-check live gold

	g_bGiftLocked = true;
	g_iLockFrames = kGiftLockFrames;
	ContextPtr:SetUpdate( OnUpdate );

	Controls.SmallGiftButton:SetDisabled( true );
	Controls.MediumGiftButton:SetDisabled( true );
	Controls.LargeGiftButton:SetDisabled( true );
	Controls.UnitGiftButton:SetDisabled( true );

	Game.DoMinorGoldGift( g_iMinorCivID, iAmount );
end

function OnSmallGold ()  DoGoldGift( iGoldGiftSmall );  end
function OnMediumGold () DoGoldGift( iGoldGiftMedium ); end
function OnBigGold ()    DoGoldGift( iGoldGiftLarge );  end
Controls.SmallGiftButton:RegisterCallback(  Mouse.eLClick, OnSmallGold );
Controls.MediumGiftButton:RegisterCallback( Mouse.eLClick, OnMediumGold );
Controls.LargeGiftButton:RegisterCallback(  Mouse.eLClick, OnBigGold );

-------------------------------------------------------------------------------
-- GIFT UNIT
-------------------------------------------------------------------------------
function OnGiftUnit()
	if g_bGiftLocked or GetMinor() == nil or not CanActNow() then return; end

	UIManager:DequeuePopup( ContextPtr );

	UI.SetInterfaceMode( InterfaceModeTypes.INTERFACEMODE_GIFT_UNIT );
	UI.SetInterfaceModeValue( g_iMinorCivID );
end
Controls.UnitGiftButton:RegisterCallback( Mouse.eLClick, OnGiftUnit );

-------------------------------------------------------------------------------
-- STOP/START SPAWNING
-------------------------------------------------------------------------------
function OnStopStartSpawning()
	local pPlayer = GetMinor();
	if pPlayer == nil or not CanActNow() then return; end

	local iActivePlayer = Game.GetActivePlayer();
	local bSpawningDisabled = pPlayer:IsMinorCivUnitSpawningDisabled( iActivePlayer );

	-- Update the text based on the state we are changing to
	if bSpawningDisabled then
		Controls.NoUnitSpawningLabel:SetText( Locale.ConvertTextKey("TXT_KEY_CITY_STATE_TURN_SPAWNING_OFF") );
	else
		Controls.NoUnitSpawningLabel:SetText( Locale.ConvertTextKey("TXT_KEY_CITY_STATE_TURN_SPAWNING_ON") );
	end

	Network.SendMinorNoUnitSpawning( g_iMinorCivID, not bSpawningDisabled );
end
Controls.NoUnitSpawningButton:RegisterCallback( Mouse.eLClick, OnStopStartSpawning );

-------------------------------------------------------------------------------
-- PLEDGE
-------------------------------------------------------------------------------
function OnPledgeButtonClicked ()
	local pPlayer = GetMinor();
	if pPlayer == nil or not CanActNow() then return; end
	if Call( Players[Game.GetActivePlayer()], "IsProtectingMinor", g_iMinorCivID ) == true then return; end

	local strText;
	if pPlayer:GetPersonality() == MinorCivPersonalityTypes.MINOR_CIV_PERSONALITY_HOSTILE then
		strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PLEDGE_RESPONSE_HOSTILE");
	else
		strText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PLEDGE_RESPONSE");
	end
	Controls.DescriptionLabel:SetText( strText );

	Network.SendPledgeMinorProtection( g_iMinorCivID, true );

	Controls.PledgeButton:SetHide( true );
	g_sLayoutSignature = "";
	UpdateLayout( strText, g_sResourceCacheText );
end
Controls.PledgeButton:RegisterCallback( Mouse.eLClick, OnPledgeButtonClicked );

-------------------------------------------------------------------------------
-- WAR
-------------------------------------------------------------------------------
function OnWarButtonClicked ()
	if GetMinor() == nil or not CanActNow() then return; end

	local iActivePlayer = Game.GetActivePlayer();
	local tProtectors = {};

	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		if iPlayerLoop ~= iActivePlayer then
			local pOther = Players[iPlayerLoop];
			if pOther ~= nil and pOther:IsAlive() and pOther:IsProtectingMinor( g_iMinorCivID ) then
				table.insert( tProtectors, Locale.ConvertTextKey( pOther:GetCivilizationShortDescriptionKey() ) );
			end
		end
	end

	local warConfirmString;
	if #tProtectors > 0 then
		warConfirmString = Locale.ConvertTextKey("TXT_KEY_CONFIRM_WAR_PROTECTED_CITY_STATE", Players[g_iMinorCivID]:GetCivilizationShortDescriptionKey())
			.. " " .. table.concat( tProtectors, ", " );
	else
		warConfirmString = Locale.ConvertTextKey("TXT_KEY_CONFIRM_WAR");
	end

	Controls.WarConfirmLabel:SetText( warConfirmString );
	Controls.WarConfirm:SetHide( false );
	Controls.BGBlock:SetHide( true );
end
Controls.WarButton:RegisterCallback( Mouse.eLClick, OnWarButtonClicked );

-------------------------------------------------------------------------------
-- PEACE
-------------------------------------------------------------------------------
function OnPeaceButtonClicked ()
	if GetMinor() == nil or not CanActNow() then return; end
	if not Teams[Game.GetActiveTeam()]:IsAtWar( g_iMinorCivTeamID ) then return; end

	Network.SendChangeWar( g_iMinorCivTeamID, false );

	g_bPeaceRequested = true;
	g_iPeaceTurn = Game.GetGameTurn();
	Refresh( true );
end
Controls.PeaceButton:RegisterCallback( Mouse.eLClick, OnPeaceButtonClicked );

-------------------------------------------------------------------------------
-- CLOSE BUTTON
-------------------------------------------------------------------------------
function OnCloseButtonClicked ()
	StartCloseAnim();
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButtonClicked );

-------------------------------------------------------------------------------
-- Right click on the dimmed area outside the panel (and on the panel itself)
-------------------------------------------------------------------------------
local function OnRightClickClose()
	if not Controls.WarConfirm:IsHidden() then
		Controls.WarConfirm:SetHide( true );     -- cancel the confirmation only
		Controls.BGBlock:SetHide( false );
	elseif kMouseCloseAnimated then
		OnCloseButtonClicked();
	else
		CloseNow();
	end
end

-- Wrapped in pcall so a control type that can't take callbacks never breaks loading.
pcall( function() Controls.BGBlock:RegisterCallback( Mouse.eRClick, OnRightClickClose ); end );
pcall( function() Controls.Popup:RegisterCallback( Mouse.eRClick, OnRightClickClose ); end );
pcall( function() Controls.WarConfirm:RegisterCallback( Mouse.eRClick, OnRightClickClose ); end );

-------------------------------------------------------------------------------
-- WAR CONFIRMATION POPUP
-------------------------------------------------------------------------------
function OnYes( )
	Controls.WarConfirm:SetHide( true );
	Controls.BGBlock:SetHide( false );

	UIManager:DequeuePopup( ContextPtr );

	-- Re-validate: state may have changed while the confirm dialog was open
	if GetMinor() == nil or not CanActNow() then return; end
	if Teams[Game.GetActiveTeam()]:IsAtWar( g_iMinorCivTeamID ) then return; end

	Network.SendChangeWar( g_iMinorCivTeamID, true );
	Network.SendPledgeMinorProtection( g_iMinorCivID, false );
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );

function OnNo( )
	Controls.WarConfirm:SetHide( true );
	Controls.BGBlock:SetHide( false );
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Mouse side ("back") button. The message names differ between builds, so only names that
-- actually exist are used; the ones found are written to Lua.log.
local g_tBackMouseMsgs = {};
for _, sName in ipairs( { "XButton1Down", "XButton2Down", "Button4Down", "Button5Down", "BackButtonDown" } ) do
	if MouseEvents ~= nil and MouseEvents[sName] ~= nil then
		table.insert( g_tBackMouseMsgs, MouseEvents[sName] );
		print( "CityStateDiploPopup: mouse side button message found: " .. sName );
	end
end
-- 523 (0x020B) is WM_XBUTTONDOWN, the mouse side buttons, confirmed in-game.
local kXButtonDown = 523;
local bHave523 = false;
for _, v in ipairs( g_tBackMouseMsgs ) do
	if v == kXButtonDown then bHave523 = true; end
end
if not bHave523 then table.insert( g_tBackMouseMsgs, kXButtonDown ); end
local g_eBrowserBack = (Keys ~= nil) and Keys.VK_BROWSER_BACK or nil;

local function IsBackMouseMessage( uiMsg )
	for _, v in ipairs( g_tBackMouseMsgs ) do
		if uiMsg == v then return true; end
	end
	return false;
end

-- bAnimated: true plays the slide-out, false closes at once.
-- If the war confirmation is open, it is cancelled instead of closing the popup.
local function CloseOrCancelConfirm( bAnimated )
	if not Controls.WarConfirm:IsHidden() then
		Controls.WarConfirm:SetHide( true );
		Controls.BGBlock:SetHide( false );
	elseif bAnimated then
		OnCloseButtonClicked();
	else
		CloseNow();
	end
end

local kXButtonUp = 524;   -- WM_XBUTTONUP, swallowed so it does not leak to the game map

function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyDown then
		if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN
			or (g_eBrowserBack ~= nil and wParam == g_eBrowserBack) then
			CloseOrCancelConfirm( true );
			return true;
		end

	-- Mouse side button: close on press
	elseif IsBackMouseMessage( uiMsg ) then
		CloseOrCancelConfirm( kMouseCloseAnimated );
		return true;
	elseif uiMsg == kXButtonUp then
		return true;

	-- Right click: swallow the press, close on release (so the release never reaches the map)
	elseif MouseEvents ~= nil and uiMsg == MouseEvents.RButtonDown then
		return true;
	elseif MouseEvents ~= nil and uiMsg == MouseEvents.RButtonUp then
		CloseOrCancelConfirm( kMouseCloseAnimated );
		return true;
	end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

	if( not bInitState ) then
		Controls.BackgroundImage:UnloadTexture();
		if( not bIsHide ) then
			Controls.BackgroundImage:SetTexture( lastBackgroundImage );
			UI.incTurnTimerSemaphore();
			if m_PopupInfo ~= nil then
				Events.SerialEventGameMessagePopupShown( m_PopupInfo );
			end
			StartOpenAnim();
		else
			-- stop all per-frame work and reset transient state
			ContextPtr:ClearUpdate();
			ResetPopupPose();
			g_bDirty = false;
			g_bGiftLocked = false;
			g_iLockFrames = 0;
			g_bPeaceRequested = false;
			g_sResourceCacheKey = nil;

			UI.decTurnTimerSemaphore();
			Events.SerialEventGameMessagePopupProcessed.CallImmediate( ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO, 0 );
		end
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add( CloseNow );