--------------------------------------------------------------------
-- Top Cities Popup
--------------------------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
include( "TopCities_Functions.lua" );
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
    end
end
ContextPtr:SetInputHandler( InputHandler );
--------------------------------------------------------------------
function OnClose()
	ContextPtr:SetHide(true)
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose);
--------------------------------------------------------------------
function ShowHideHandler(bIsHide, bInitState)
	if (not bInitState and not bIsHide) then
		g_Cities = GetCitiesByScore()
		TabSelect(g_CurrentTab)
	end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)
--------------------------------------------------------------------
function OnDiploCornerPopup()
	ContextPtr:SetHide(false)
end
--------------------------------------------------------------------
function OnAdditionalInformationDropdownGatherEntries(entries)
    table.insert(entries, {
		text = Locale.ConvertTextKey("TXT_KEY_DIPLO_CORNER_HOOK_TOP_CITY_ADDINS"), 
		call = OnDiploCornerPopup
	})
end




--------------------------------------------------------------------
LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries)
LuaEvents.RequestRefreshAdditionalInformationDropdownEntries()
--------------------------------------------------------------------
ContextPtr:SetHide(true)
--------------------------------------------------------------------
TabSelect("WorldCities");