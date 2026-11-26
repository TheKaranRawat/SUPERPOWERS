--------------------------------------------------------------------
-- Top Cities Popup
--------------------------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
include( "TopCities_Functions.lua" );
--------------------------------------------------------------------
-- Open/close animation settings
--------------------------------------------------------------------
local ANIM_FADE_DURATION   = 0.25   -- seconds for the fade
local ANIM_SLIDE_DURATION  = 0.30   -- seconds for the slide
local ANIM_SLIDE_DISTANCE  = 60     -- pixels the window travels
-- Where the window slides in from (and back out to):
-- "FromBottom", "FromTop", "FromLeft", "FromRight"
local ANIM_SLIDE_DIRECTION = "FromBottom"
--------------------------------------------------------------------
local g_IsClosing = false
local g_PendingAnims = 0
local g_CloseTimer = 0
-- Safety net: force-hide if the animation callbacks never arrive
local CLOSE_TIMEOUT = math.max(ANIM_FADE_DURATION, ANIM_SLIDE_DURATION, 0.01) + 0.5

-- Call an optional animation setter safely. Some Civ 5 builds don't expose
-- every setter; if one is missing we log it and keep the XML default.
local function TrySet(ctrl, method, ...)
	local fn = ctrl[method]
	if fn then
		local ok = pcall(fn, ctrl, ...)
		if ok then return true end
	end
	print("TopCities: " .. method .. " not available, using XML default");
	return false
end

local function ConfigureAnimations()
	local d = ANIM_SLIDE_DISTANCE
	local offsets = {
		FromBottom = {0,  d},
		FromTop    = {0, -d},
		FromLeft   = {-d, 0},
		FromRight  = { d, 0},
	}
	local o = offsets[ANIM_SLIDE_DIRECTION] or offsets.FromBottom

	-- Speed is 1 / duration in seconds (clamped so 0 means "instant")
	TrySet(Controls.FadeAnim,  "SetSpeed", 1 / math.max(ANIM_FADE_DURATION, 0.01));
	TrySet(Controls.SlideAnim, "SetSpeed", 1 / math.max(ANIM_SLIDE_DURATION, 0.01));
	TrySet(Controls.SlideAnim, "SetStartVal", o[1], o[2]);
	TrySet(Controls.SlideAnim, "SetEndVal", 0, 0);
end
ConfigureAnimations();

-- Finish a close: stop the per-frame watchdog and actually hide the context
local function FinishClose()
	if not g_IsClosing then return end
	g_IsClosing = false;
	g_PendingAnims = 0;
	ContextPtr:ClearUpdate();   -- no per-frame Lua once closed
	ContextPtr:SetHide(true);
end

-- Hide the context only once BOTH reverse animations have finished
local function OnCloseAnimDone()
	if not g_IsClosing then return end
	g_PendingAnims = g_PendingAnims - 1;
	if g_PendingAnims <= 0 then
		FinishClose();
	end
end

-- Watchdog: only registered while closing
local function OnCloseUpdate( fDTime )
	g_CloseTimer = g_CloseTimer + (fDTime or 0);
	if g_CloseTimer >= CLOSE_TIMEOUT then
		FinishClose();
	end
end
Controls.FadeAnim:RegisterAnimCallback(OnCloseAnimDone);
Controls.SlideAnim:RegisterAnimCallback(OnCloseAnimDone);
--------------------------------------------------------------------
local insert			= table.insert
local concat			= table.concat
local smaller			= math.min
local maxEntries		= g_MaxEntries
local bGnK				= g_IsGnK
local bBNW				= g_IsBNW
local unknownString		= Locale.ConvertTextKey( "TXT_KEY_MISC_UNKNOWN" );
local questionString	= Locale.ConvertTextKey( "TXT_KEY_TC_WORLD_QUESTION" );
local questionOffset, questionTextureSheet = IconLookup( 23, 32, "CIV_COLOR_ATLAS" );
local g_Cities			= {}
--------------------------------------------------------------------
g_Tabs = {
	["WorldCities"] = {
		Panel = Controls.WorldCitiesPanel,
		SelectHighlight = Controls.WorldCitiesSelectHighlight,
	},
	
	["MyCities"] = {
		Panel = Controls.MyCitiesPanel,
		SelectHighlight = Controls.MyCitiesSelectHighlight,
	},
	
	["Historic"] = {
		Panel = Controls.HistoricPanel,
		SelectHighlight = Controls.HistoricSelectHighlight,
	},
}
g_CurrentTab = nil;	
--------------------------------------------------------------------
local g_WorldCitiesManager = InstanceManager:new("WorldCitiesInstance", "Base", Controls.WorldCitiesStack);
local g_MyCitiesManager = InstanceManager:new( "MyCitiesInstance", "Base", Controls.MyCitiesStack);
local g_HistoricManager = InstanceManager:new( "HistoricInstance", "Base", Controls.HistoricStack);
--------------------------------------------------------------------
function TabSelect(tab)
	for i,v in pairs(g_Tabs) do
		local bHide = i ~= tab;
		v.Panel:SetHide(bHide);
		v.SelectHighlight:SetHide(bHide);
	end
	g_CurrentTab = tab;
	g_Tabs[tab].RefreshContent();	
end
--------------------------------------------------------------------
Controls.TabButtonWorldCities:RegisterCallback( Mouse.eLClick, function() TabSelect("WorldCities"); end);
Controls.TabButtonMyCities:RegisterCallback( Mouse.eLClick, function() TabSelect("MyCities"); end );
Controls.TabButtonHistoric:RegisterCallback( Mouse.eLClick, function() TabSelect("Historic"); end );
--------------------------------------------------------------------
function RefreshWorldCities()
	g_WorldCitiesManager:ResetInstances();

	if (#g_Cities > 0) then
		local cities = TableReduce(g_Cities, smaller(maxEntries, #g_Cities));
		
		Controls.WorldCitiesScrollPanel:SetHide(false);
		Controls.NoWorldCities:SetHide(true);
		
		local activeTeam = Teams[Game.GetActiveTeam()]
		local playerID = Game.GetActivePlayer();

		for i,v in ipairs(cities) do
			local cityEntry = g_WorldCitiesManager:GetInstance();
			
			cityEntry.WorldRank:SetText(tostring(i));
			
			local city = v.city
			local ownerID = city:GetOwner()
			local bCurrBest = IsCurrentGreatestCity(city);

			local bReveal = false
			if (playerID == ownerID) or activeTeam:IsHasMet(Players[ownerID]:GetTeam()) or bCurrBest then
				bReveal = true
			end
			
			if bReveal then
				local civType = GameInfo.Civilizations[city:GetCivilizationType()]
				IconHookup(civType.PortraitIndex, 32, civType.IconAtlas, cityEntry.WorldCivIcon);
				cityEntry.WorldCivIcon:SetToolTipString(Locale.ConvertTextKey(civType.ShortDescription));
				
				local cityName = city:GetName()
				if bCurrBest then
					cityName = Locale.ConvertTextKey("TXT_KEY_TC_WORLD_CURRENT_TOPCITY", cityName)
					cityEntry.WorldCityName:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_TC_STATUS_TOPCITY"));
				end

				cityEntry.WorldCityName:SetText(cityName);
				cityEntry.WorldPopulation:SetText(CommaFormat(v.city:GetRealPopulation()));
			else
				cityEntry.WorldCivIcon:SetTexture( questionTextureSheet );
				cityEntry.WorldCivIcon:SetTextureOffset( questionOffset );
				cityEntry.WorldCivIcon:SetToolTipString( unknownString );
				cityEntry.WorldCityName:SetText( questionString );
				cityEntry.WorldPopulation:SetText( questionString );
			end
			
			cityEntry.WorldScore:SetText(v.score);
			cityEntry.WorldScore:SetToolTipString( GetScoreToolTip(v.details) );
		end
		
		Controls.WorldCitiesStack:CalculateSize();
		Controls.WorldCitiesStack:ReprocessAnchoring();
		Controls.WorldCitiesScrollPanel:CalculateInternalSize();
	
	else
		Controls.WorldCitiesScrollPanel:SetHide(true);
		Controls.NoWorldCities:SetHide(false);
	end
end
g_Tabs["WorldCities"].RefreshContent = RefreshWorldCities;
--------------------------------------------------------------------
function RefreshMyCities()
	g_MyCitiesManager:ResetInstances();

	local myCities = {}

	if (#g_Cities > 0) then
		local playerID = Game.GetActivePlayer();
		for i,v in ipairs(g_Cities) do
			if v.city:GetOwner() == playerID then
				v.rank = i
				insert(myCities, v)
			end
		end
	end

	if (#myCities > 0) then
		myCities = TableReduce(myCities, smaller(maxEntries, #myCities));
		
		Controls.MyCitiesScrollPanel:SetHide(false);
		Controls.NoMyCities:SetHide(true);
		
		for _,v in ipairs(myCities) do
			local cityEntry = g_MyCitiesManager:GetInstance();
			
			cityEntry.MyRank:SetText(v.rank);
			
			local icon, iconTT = GetStatusIcons(v.city);
			cityEntry.CityStatusIcon:SetText(icon);
			cityEntry.CityStatusIcon:SetToolTipString(iconTT);

			cityEntry.MyCityName:SetText(v.city:GetName());
			cityEntry.MyCityPopulation:SetText(CommaFormat(v.city:GetRealPopulation()));
			cityEntry.MyCityScore:SetText(v.score);
			cityEntry.MyCityScore:SetToolTipString( GetScoreToolTip(v.details) );
		end
		
		Controls.MyCitiesStack:CalculateSize();
		Controls.MyCitiesStack:ReprocessAnchoring();
		Controls.MyCitiesScrollPanel:CalculateInternalSize();
	
	else
		Controls.MyCitiesScrollPanel:SetHide(true);
		Controls.NoMyCities:SetHide(false);
	end
end
g_Tabs["MyCities"].RefreshContent = RefreshMyCities;
--------------------------------------------------------------------
function RefreshHistoricCities()
	g_HistoricManager:ResetInstances();

	local cities = GetHallOfFameCities()
	
	if (#cities > 0) then
		
		Controls.HistoricScrollPanel:SetHide(false);
		Controls.NoHistoric:SetHide(true);
		
		for i,v in ipairs(cities) do
			local cityEntry = g_HistoricManager:GetInstance();
			
			local era = GameInfo.Eras[v.era]
			if era then
				cityEntry.EraWon:SetText(Locale.ConvertTextKey(era.Description));
			end

			local civType = GameInfo.Civilizations[v.civ]
			if civType then
				IconHookup(civType.PortraitIndex, 32, civType.IconAtlas, cityEntry.HistoricCivIcon);
				cityEntry.HistoricCivIcon:SetToolTipString(Locale.ConvertTextKey(civType.ShortDescription));
			end

			cityEntry.HistoricCityName:SetText(Locale.ConvertTextKey(v.name));
			cityEntry.HistoricPopulation:SetText(CommaFormat(v.pop));
			cityEntry.HistoricScore:SetText(v.score);
		end
		
		Controls.HistoricStack:CalculateSize();
		Controls.HistoricStack:ReprocessAnchoring();
		Controls.HistoricScrollPanel:CalculateInternalSize();
	
	else
		Controls.HistoricScrollPanel:SetHide(true);
		Controls.NoHistoric:SetHide(false);
	end
end
g_Tabs["Historic"].RefreshContent = RefreshHistoricCities;
--------------------------------------------------------------------
function GetScoreToolTip(t)
	local strTT;
	local tips = {};

	for key,value in pairs(t) do
		insert(tips, "[ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TC_SCORE_"..key.."_TT", value));
	end
	
	if #tips > 0 then
		strTT = concat(tips, "[NEWLINE]")
	end

	return strTT;
end
--------------------------------------------------------------------
function GetStatusIcons(city)
	local icon = "";
	local iconTT;

	if IsCurrentGreatestCity(city) then
		icon = "[ICON_TOPCITY]"
		iconTT = "TXT_KEY_TC_STATUS_TOPCITY"
	elseif city:IsRazing() then
		icon = "[ICON_RAZING]"
		iconTT = "TXT_KEY_TC_STATUS_RAZING"
	elseif city:IsResistance() then
		icon = "[ICON_RESISTANCE]"
		iconTT = "TXT_KEY_TC_STATUS_RESISTANCE"
	elseif (bBNW or bGnK) and city:IsHolyCityAnyReligion() then
		icon = "[ICON_RELIGION]"
		iconTT = "TXT_KEY_TC_STATUS_HOLYCITY"
	elseif city:IsPuppet() then
		icon = "[ICON_PUPPET]"
		iconTT = "TXT_KEY_TC_STATUS_PUPPET"
	elseif city:IsCapital() then
		icon = "[ICON_CAPITAL]"
		iconTT = "TXT_KEY_TC_STATUS_CAPITAL"
	end

	if iconTT then
		iconTT = Locale.ConvertTextKey(iconTT)
	end

	return icon, iconTT
end
--------------------------------------------------------------------
function IgnoreLeftClick( Id )
end
--------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )      
    if(uiMsg == KeyEvents.KeyDown) then
        if (wParam == Keys.VK_ESCAPE) then
            OnClose();
            return true;
        end
 
        if(wParam == Keys.VK_RETURN) then
            return true;
        end

    -- right click closes the screen
    elseif(uiMsg == MouseEvents.RButtonUp) then
        OnClose();
        return true;

    -- mouse side button closes the screen
    elseif(uiMsg == 523) then   -- WM_XBUTTONDOWN
        local xButton = math.floor( wParam / 65536 ) % 256   -- high word
        if xButton == 0 then xButton = wParam end            -- fallback if already unpacked
        if xButton == 1 then   -- same button as the other screens; use 1 for the other one
            OnClose();
            return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );
--------------------------------------------------------------------
function OnClose()
	if g_IsClosing or ContextPtr:IsHidden() then return end
	g_IsClosing = true;
	g_PendingAnims = 2;
	g_CloseTimer = 0;
	ContextPtr:SetUpdate(OnCloseUpdate);
	Controls.FadeAnim:Reverse();
	Controls.SlideAnim:Reverse();
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose);
--------------------------------------------------------------------
function ShowHideHandler(bIsHide, bInitState)
	if bIsHide then
		g_IsClosing = false;
		ContextPtr:ClearUpdate();
	elseif not bInitState then
		g_IsClosing = false;
		ContextPtr:ClearUpdate();
		g_Cities = GetCitiesByScore()
		TabSelect(g_CurrentTab)

		Controls.FadeAnim:SetToBeginning();
		Controls.SlideAnim:SetToBeginning();
		Controls.FadeAnim:Play();
		Controls.SlideAnim:Play();
	end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)
--------------------------------------------------------------------
function OnDiploCornerPopup()
	ContextPtr:SetHide(false)
end
--------------------------------------------------------------------
function OnAdditionalInformationDropdownGatherEntries(entries)
    insert(entries, {text = Locale.ConvertTextKey("TXT_KEY_DIPLO_CORNER_HOOK_TOP_CITY_ADDINS"), call = OnDiploCornerPopup})
end
--------------------------------------------------------------------
LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries)
LuaEvents.RequestRefreshAdditionalInformationDropdownEntries()
--------------------------------------------------------------------
ContextPtr:SetHide(true)
--------------------------------------------------------------------
TabSelect("WorldCities");