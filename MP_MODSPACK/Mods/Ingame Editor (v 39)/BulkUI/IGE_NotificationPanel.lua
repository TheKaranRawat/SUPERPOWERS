-------------------------------------------------
-- Action Info Panel
-- Copied from the original lua file, I just moved the hooks to the IGE section.
-------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
include( "IGE_Utils" );

local g_ActiveNotifications = {};
local g_Instances = {};

-------------------------------------------------------------------------------
-- details for dynamically sizing the small notification stack
-------------------------------------------------------------------------------
local DIPLO_SIZE_GUESS = 120;
local _, screenY = UIManager:GetScreenSizeVal();
local _, offsetY = Controls.OuterStack:GetOffsetVal();
local g_SmallScrollMax = screenY - offsetY - DIPLO_SIZE_GUESS;

-------------------------------------------------
-------------------------------------------------
function GenericLeftClick( Id )
	UI.ActivateNotification( Id )
end


-------------------------------------------------
-------------------------------------------------
function GenericRightClick ( Id )
	UI.RemoveNotification( Id )
end


------------------------------------------------------------------------------------
-- set up the exceptions
------------------------------------------------------------------------------------
Controls[ "TechButton" ]:RegisterCallback( Mouse.eLClick, GenericLeftClick );
Controls[ "TechButton" ]:RegisterCallback( Mouse.eRClick, GenericRightClick );
Controls[ "ProductionButton" ]:RegisterCallback( Mouse.eLClick, GenericLeftClick );
Controls[ "ProductionButton" ]:RegisterCallback( Mouse.eRClick, GenericRightClick );
Controls[ "FreeTechButton" ]:RegisterCallback( Mouse.eLClick, GenericLeftClick );
Controls[ "FreeTechButton" ]:RegisterCallback( Mouse.eRClick, GenericRightClick );
Controls[ "FreePolicyButton" ]:RegisterCallback( Mouse.eLClick, GenericLeftClick );
Controls[ "FreePolicyButton" ]:RegisterCallback( Mouse.eRClick, GenericRightClick );
Controls[ "FreeGreatPersonButton" ]:RegisterCallback( Mouse.eLClick, GenericLeftClick );
Controls[ "FreeGreatPersonButton" ]:RegisterCallback( Mouse.eRClick, GenericRightClick );

------------------------------------------------------------------------------------
-- build the list of types we can handle
------------------------------------------------------------------------------------
local g_NameTable = {};
g_NameTable[ -1 ]																= "Generic";
g_NameTable[ NotificationTypes.NOTIFICATION_POLICY ]							= "SocialPolicy";
g_NameTable[ NotificationTypes.NOTIFICATION_MET_MINOR ]							= "MetCityState";
g_NameTable[ NotificationTypes.NOTIFICATION_MINOR ]								= "CityState";
g_NameTable[ NotificationTypes.NOTIFICATION_MINOR_QUEST ]						= "CityState";
g_NameTable[ NotificationTypes.NOTIFICATION_ENEMY_IN_TERRITORY ]				= "EnemyInTerritory";
g_NameTable[ NotificationTypes.NOTIFICATION_REBELS ]				= "EnemyInTerritory";
g_NameTable[ NotificationTypes.NOTIFICATION_CITY_RANGE_ATTACK ]					= "Generic";
g_NameTable[ NotificationTypes.NOTIFICATION_BARBARIAN ]							= "Barbarian";
g_NameTable[ NotificationTypes.NOTIFICATION_GOODY ]								= "AncientRuins";
g_NameTable[ NotificationTypes.NOTIFICATION_BUY_TILE ]							= "BuyTile";
g_NameTable[ NotificationTypes.NOTIFICATION_CITY_GROWTH ]						= "CityGrowth";
g_NameTable[ NotificationTypes.NOTIFICATION_CITY_TILE ]							= "CityTile";
g_NameTable[ NotificationTypes.NOTIFICATION_DEMAND_RESOURCE ]					= "BonusResource";
g_NameTable[ NotificationTypes.NOTIFICATION_UNIT_PROMOTION ]					= "UnitPromoted";
--g_NameTable[ NotificationTypes.NOTIFICATION_WONDER_STARTED ]					= "WonderConstructed";
g_NameTable[ NotificationTypes.NOTIFICATION_WONDER_COMPLETED_ACTIVE_PLAYER]     = "WonderConstructed";
g_NameTable[ NotificationTypes.NOTIFICATION_WONDER_COMPLETED ]					= "WonderConstructed";
g_NameTable[ NotificationTypes.NOTIFICATION_WONDER_BEATEN ]						= "WonderConstructed";
g_NameTable[ NotificationTypes.NOTIFICATION_GOLDEN_AGE_BEGUN_ACTIVE_PLAYER ]	= "GoldenAge";
--g_NameTable[ NotificationTypes.NOTIFICATION_GOLDEN_AGE_BEGUN ]				= "GoldenAge";
g_NameTable[ NotificationTypes.NOTIFICATION_GOLDEN_AGE_ENDED_ACTIVE_PLAYER ]	= "GoldenAge";
--g_NameTable[ NotificationTypes.NOTIFICATION_GOLDEN_AGE_ENDED ]				= "GoldenAge";
g_NameTable[ NotificationTypes.NOTIFICATION_GREAT_PERSON_ACTIVE_PLAYER ]		= "GreatPerson";
--g_NameTable[ NotificationTypes.NOTIFICATION_GREAT_PERSON ]					= "GreatPerson";
g_NameTable[ NotificationTypes.NOTIFICATION_STARVING ]							= "Starving";
g_NameTable[ NotificationTypes.NOTIFICATION_WAR_ACTIVE_PLAYER ]                 = "War";
g_NameTable[ NotificationTypes.NOTIFICATION_WAR ]								= "WarOther";
g_NameTable[ NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER ]				= "Peace";
g_NameTable[ NotificationTypes.NOTIFICATION_PEACE ]								= "PeaceOther";
g_NameTable[ NotificationTypes.NOTIFICATION_VICTORY ]							= "Victory";
g_NameTable[ NotificationTypes.NOTIFICATION_UNIT_DIED ]							= "UnitDied";
g_NameTable[ NotificationTypes.NOTIFICATION_CITY_LOST ]							= "CapitalLost";
g_NameTable[ NotificationTypes.NOTIFICATION_CAPITAL_LOST_ACTIVE_PLAYER ]        = "CapitalLost";
g_NameTable[ NotificationTypes.NOTIFICATION_CAPITAL_LOST ]						= "CapitalLost";
g_NameTable[ NotificationTypes.NOTIFICATION_CAPITAL_RECOVERED ]					= "CapitalRecovered";
g_NameTable[ NotificationTypes.NOTIFICATION_PLAYER_KILLED ]						= "CapitalLost";
g_NameTable[ NotificationTypes.NOTIFICATION_DISCOVERED_LUXURY_RESOURCE ]		= "LuxuryResource";
g_NameTable[ NotificationTypes.NOTIFICATION_DISCOVERED_STRATEGIC_RESOURCE ]		= "StrategicResource";
g_NameTable[ NotificationTypes.NOTIFICATION_DISCOVERED_BONUS_RESOURCE ]			= "BonusResource";
--g_NameTable[ NotificationTypes.NOTIFICATION_POLICY_ADOPTION ]					= "Generic";
g_NameTable[ NotificationTypes.NOTIFICATION_DIPLO_VOTE ]						= "Generic";
g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_RACE ]						= "Generic";
g_NameTable[ NotificationTypes.NOTIFICATION_EXPLORATION_RACE ]					= "NaturalWonder";
g_NameTable[ NotificationTypes.NOTIFICATION_DIPLOMACY_DECLARATION ]				= "Diplomacy";
g_NameTable[ NotificationTypes.NOTIFICATION_DEAL_EXPIRED_GPT ]					= "DiplomacyX";
g_NameTable[ NotificationTypes.NOTIFICATION_DEAL_EXPIRED_RESOURCE ]				= "DiplomacyX";
g_NameTable[ NotificationTypes.NOTIFICATION_DEAL_EXPIRED_OPEN_BORDERS ]			= "DiplomacyX";
g_NameTable[ NotificationTypes.NOTIFICATION_DEAL_EXPIRED_DEFENSIVE_PACT ]		= "DiplomacyX";
g_NameTable[ NotificationTypes.NOTIFICATION_DEAL_EXPIRED_RESEARCH_AGREEMENT ]	= "DiplomacyX";
g_NameTable[ NotificationTypes.NOTIFICATION_DEAL_EXPIRED_TRADE_AGREEMENT ]		= "DiplomacyX";
g_NameTable[ NotificationTypes.NOTIFICATION_TECH_AWARD ]						= "TechAward";
g_NameTable[ NotificationTypes.NOTIFICATION_PLAYER_DEAL ]						= "Diplomacy";
g_NameTable[ NotificationTypes.NOTIFICATION_PLAYER_DEAL_RECEIVED ]				= "Diplomacy";
g_NameTable[ NotificationTypes.NOTIFICATION_PLAYER_DEAL_RESOLVED ]				= "Diplomacy";
g_NameTable[ NotificationTypes.NOTIFICATION_PROJECT_COMPLETED ]					= "ProjectConstructed";


g_NameTable[ NotificationTypes.NOTIFICATION_TECH ]       = "Tech";
g_NameTable[ NotificationTypes.NOTIFICATION_PRODUCTION ] = "Production";
g_NameTable[ NotificationTypes.NOTIFICATION_FREE_TECH ]	 = "FreeTech";
g_NameTable[ NotificationTypes.NOTIFICATION_FREE_POLICY ]	 = "FreePolicy";
g_NameTable[ NotificationTypes.NOTIFICATION_FREE_GREAT_PERSON ]	 = "FreeGreatPerson";

g_NameTable[ NotificationTypes.NOTIFICATION_DENUNCIATION_EXPIRED ]	= "Diplomacy";
g_NameTable[ NotificationTypes.NOTIFICATION_FRIENDSHIP_EXPIRED ] = "Diplomacy";

if IGE_HasGodsAndKings then
	g_NameTable[ NotificationTypes.NOTIFICATION_FOUND_PANTHEON] = "FoundPantheon";
	g_NameTable[ NotificationTypes.NOTIFICATION_FOUND_RELIGION] = "FoundReligion";
	g_NameTable[ NotificationTypes.NOTIFICATION_PANTHEON_FOUNDED_ACTIVE_PLAYER ] = "PantheonFounded";
	g_NameTable[ NotificationTypes.NOTIFICATION_PANTHEON_FOUNDED ] = "PantheonFounded";
	g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_FOUNDED_ACTIVE_PLAYER ] = "ReligionFounded";
	g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_FOUNDED ] = "ReligionFounded";
	g_NameTable[ NotificationTypes.NOTIFICATION_ENHANCE_RELIGION] = "EnhanceReligion";
	g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_ENHANCED_ACTIVE_PLAYER ] = "ReligionEnhanced";
	g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_ENHANCED ] = "ReligionEnhanced";
	g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_SPREAD ] = "ReligionSpread";

	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_CREATED_ACTIVE_PLAYER ]					= "NewSpy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_CANT_STEAL_TECH ]						= "SpyCannotSteal";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_EVICTED ]								= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_TECH_STOLEN_SPY_DETECTED ]					= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_TECH_STOLEN_SPY_IDENTIFIED ]				= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_KILLED_A_SPY ]							= "SpyKilledASpy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_WAS_KILLED ]							= "SpyWasKilled";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_REPLACEMENT ]							= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_PROMOTION ]								= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_DECEPTION ]						= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_BUILDING_SNEAK_ATTACK_ARMY ]       = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_BUILDING_SNEAK_ATTACK_AMPHIBIOUS ] = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_ARMY_AGAINST_KNOWN_CITY_UNKNOWN ]   = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_ARMY_AGAINST_KNOWN_CITY_KNOWN ]     = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_ARMY_AGAINST_YOU_CITY_UNKNOWN ]	  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_ARMY_AGAINST_YOU_CITY_KNOWN ]		  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_ARMY_AGAINST_UNKNOWN ]			  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_AMPHIB_AGAINST_KNOWN_CITY_UNKNOWN ] = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_AMPHIB_AGAINST_KNOWN_CITY_KNOWN ]	  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_AMPHIB_AGAINST_YOU_CITY_UNKNOWN ]	  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_AMPHIB_AGAINST_YOU_CITY_KNOWN ]	  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_SNEAK_ATTACK_AMPHIB_AGAINST_UNKNOWN ]			  = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_INTRIGUE_CONSTRUCTING_WONDER ]							  = "Spy";

	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_RIG_ELECTION_SUCCESS ]				    = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_RIG_ELECTION_FAILURE ]				    = "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_RIG_ELECTION_ALERT ]					= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_YOU_STAGE_COUP_SUCCESS ]				= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_YOU_STAGE_COUP_FAILURE ]				= "SpyWasKilled";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_STAGE_COUP_SUCCESS ]					= "Spy";
	g_NameTable[ NotificationTypes.NOTIFICATION_SPY_STAGE_COUP_FAILURE ]					= "Spy";

	g_NameTable[ NotificationTypes.NOTIFICATION_CAN_BUILD_MISSIONARY ] = "EnoughFaith";
	g_NameTable[ NotificationTypes.NOTIFICATION_AUTOMATIC_FAITH_PURCHASE_STOPPED] = "AutomaticFaithStop";
	g_NameTable[ NotificationTypes.NOTIFICATION_OTHER_PLAYER_NEW_ERA ] = "OtherPlayerNewEra";

	g_NameTable[ NotificationTypes.NOTIFICATION_MAYA_LONG_COUNT ]	= "FreeGreatPerson";
	g_NameTable[ NotificationTypes.NOTIFICATION_FAITH_GREAT_PERSON ]	= "FreeGreatPerson";

	g_NameTable[ NotificationTypes.NOTIFICATION_EXPANSION_PROMISE_EXPIRED ] = "Diplomacy";
	g_NameTable[ NotificationTypes.NOTIFICATION_BORDER_PROMISE_EXPIRED ] = "Diplomacy";

	g_NameTable[ NotificationTypes.NOTIFICATION_TRADE_ROUTE ] = "TradeRoute";
	g_NameTable[ NotificationTypes.NOTIFICATION_TRADE_ROUTE_BROKEN ] = "TradeRouteBroken";

	g_NameTable[ NotificationTypes.NOTIFICATION_RELIGION_SPREAD_NATURAL ] = "ReligionNaturalSpread";

	g_NameTable[ NotificationTypes.NOTIFICATION_MINOR_BUYOUT ] = "CityStateBuyout";
end

--===============================================================================================
-- Actual new notification entry point
--===============================================================================================
function OnNotificationAdded( Id, type, toolTip, strSummary, iGameValue, iExtraGameData )
    print( "NotificationAdded " .. getstr( Id ) .. " " 
                                .. getstr( type ) .. " " 
                                .. getstr( iGameValue ) .. " " 
                                .. getstr( iExtraGameData ) .. " " 
                                .. getstr( strSummary ) .. " " 
                                .. getstr( toolTip ) );

    if( g_ActiveNotifications[ Id ] ~= nil )
    then
        print( "Redundant Notification Id: "..tostring(Id) );
        return;
    end
       
    local name = g_NameTable[ type ];
	--print(getstr(name));
    
    
    local button;
    local text;
    local bg;
    local fingerTitle;
    local root;
        
    if( name == "Production" or
        name == "Tech" or
        name == "FreeTech" or
        name == "StealTech" or
        name == "FreePolicy" or
		name == "FreeGreatPerson" or
		name == "FoundPantheon" or
		name == "FoundReligion" or
		name == "EnhanceReligion") then

        button = Controls[ name .. "Button"  ];
        text   = Controls[ name .. "Text"   ];
        bg     = Controls[ name .. "BG"   ];
    else
        if( name == nil ) then
            print( "Unknown Notification, Adding generic " .. Id );
            name = "Generic";
        end

        local instance = {};
        ContextPtr:BuildInstanceForControl( name .. "Item", instance, Controls.SmallStack );
        g_Instances[ Id ] = instance;

		if name == "PantheonFounded" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationPantheon80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationPantheonGlow80.dds");
		elseif name == "ReligionFounded" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationReligion80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationReligionGlow80.dds");
		elseif name == "ReligionEnhanced" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationEnhanceReligion80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationEnhanceReligionGlow80.dds");
		elseif name == "EnoughFaith" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationIconsFaith80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationIconsFaithGlow80.dds");
		elseif name == "AutomaticFaithStop" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationFaithStopped80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationFaithStoppedGlow80.dds");
		elseif name == "ReligionSpread" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationSpreadReligionForced80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationSpreadReligionForcedGlow80.dds");
		elseif name == "ReligionNaturalSpread" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationSpreadReligion80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationSpreadReligionGlow80.dds");
		elseif name == "Spy" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/EspionageSpyIcons80_Expansion.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationSpyGlow80.dds");
		elseif name == "NewSpy" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationIconsSpyNew80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationIconsSpyNewGlow80.dds");
		elseif name == "SpyCannotSteal" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/EspionageSpyIcons80_Expansion.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationSpyGlow80.dds");
		elseif name == "SpyKilledASpy" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationIconsSpyKilled80.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationIconsSpyKilledGlow80.dds");
		elseif name == "SpyWasKilled" then
			instance.IGEImage:SetTexture("assets/UI/Art/Notification/NotificationIconsRedSpyKilled.dds");
			instance.IGEImageAlpha:SetTexture("assets/UI/Art/Notification/NotificationIconsRedSpyKilledGlow2.dds");
		end
        
        button = instance[ name .. "Button" ];
        text   = instance[ name .. "Text" ];
        root   = instance[ name .. "Container" ];
        
        instance.FingerTitle:SetText( strSummary );
        root:BranchResetAnimation();
        
		--if type == NotificationTypes.NOTIFICATION_WONDER_STARTED
		if type == NotificationTypes.NOTIFICATION_WONDER_COMPLETED_ACTIVE_PLAYER
		or type == NotificationTypes.NOTIFICATION_WONDER_COMPLETED
		or type == NotificationTypes.NOTIFICATION_WONDER_BEATEN then
			if iGameValue ~= -1 then
				local portraitIndex = GameInfo.Buildings[iGameValue].PortraitIndex;
				if portraitIndex ~= -1 then
					IconHookup( portraitIndex, 80, GameInfo.Buildings[iGameValue].IconAtlas, instance.WonderConstructedAlphaAnim );				
				end
			end
			if iExtraGameData ~= -1 then
				CivIconHookup( iExtraGameData, 45, instance.CivIcon, instance.CivIconBG, instance.CivIconShadow, false, true );
				instance.WonderSmallCivFrame:SetHide(false);				
			else
				CivIconHookup( 22, 45, instance.CivIcon, instance.CivIconBG, instance.CivIconShadow, false, true );
				instance.WonderSmallCivFrame:SetHide(true);				
			end
		elseif type == NotificationTypes.NOTIFICATION_PROJECT_COMPLETED then
			if iGameValue ~= -1 then
				local portraitIndex = GameInfo.Projects[iGameValue].PortraitIndex;
				if portraitIndex ~= -1 then
					IconHookup( portraitIndex, 80, GameInfo.Projects[iGameValue].IconAtlas, instance.ProjectConstructedAlphaAnim );				
				end
			end
			if iExtraGameData ~= -1 then
				CivIconHookup( iExtraGameData, 45, instance.CivIcon, instance.CivIconBG, instance.CivIconShadow, false, true );
				instance.ProjectSmallCivFrame:SetHide(false);				
			else
				CivIconHookup( 22, 45, instance.CivIcon, instance.CivIconBG, instance.CivIconShadow, false, true );
				instance.ProjectSmallCivFrame:SetHide(true);				
			end
		elseif type == NotificationTypes.NOTIFICATION_DISCOVERED_LUXURY_RESOURCE 
		or type == NotificationTypes.NOTIFICATION_DISCOVERED_STRATEGIC_RESOURCE 
		or type == NotificationTypes.NOTIFICATION_DISCOVERED_BONUS_RESOURCE 
		or type == NotificationTypes.NOTIFICATION_DEMAND_RESOURCE then
			local thisResourceInfo = GameInfo.Resources[iGameValue];
			local portraitIndex = thisResourceInfo.PortraitIndex;
			if portraitIndex ~= -1 then
				IconHookup( portraitIndex, 80, thisResourceInfo.IconAtlas, instance.ResourceImage );				
			end
		elseif type == NotificationTypes.NOTIFICATION_EXPLORATION_RACE then
			local thisFeatureInfo = GameInfo.Features[iGameValue];
			local portraitIndex = thisFeatureInfo.PortraitIndex;
			if portraitIndex ~= -1 then
				IconHookup( portraitIndex, 80, thisFeatureInfo.IconAtlas, instance.NaturalWonderImage );				
			end
		elseif type == NotificationTypes.NOTIFICATION_TECH_AWARD then
			local thisTechInfo = GameInfo.Technologies[iExtraGameData];
			local portraitIndex = thisTechInfo.PortraitIndex;
			if portraitIndex ~= -1 then
				IconHookup( portraitIndex, 80, thisTechInfo.IconAtlas, instance.TechAwardImage );				
			else
				instance.TechAwardImage:SetHide( true );
			end
		elseif type == NotificationTypes.NOTIFICATION_UNIT_PROMOTION
		or type == NotificationTypes.NOTIFICATION_UNIT_DIED 
		or type == NotificationTypes.NOTIFICATION_GREAT_PERSON_ACTIVE_PLAYER 			
		or type == NotificationTypes.NOTIFICATION_ENEMY_IN_TERRITORY
		or type == NotificationTypes.NOTIFICATION_REBELS then
			local thisUnitType = iGameValue;
			local thisUnitInfo = GameInfo.Units[thisUnitType];
			local portraitIndex = thisUnitInfo.PortraitIndex;
			if portraitIndex ~= -1 then
				IconHookup( portraitIndex, 80, thisUnitInfo.IconAtlas, instance.UnitImage );				
			end
		elseif type == NotificationTypes.NOTIFICATION_WAR_ACTIVE_PLAYER then
			local index = iGameValue;
			CivIconHookup( index, 80, instance.WarImage, instance.CivIconBG, instance.CivIconShadow, false, true ); 
		elseif type == NotificationTypes.NOTIFICATION_WAR then
			local index = iGameValue;
			CivIconHookup( index, 45, instance.War1Image, instance.Civ1IconBG, instance.Civ1IconShadow, false, true );
			index = iExtraGameData;
			CivIconHookup( index, 45, instance.War2Image, instance.Civ2IconBG, instance.Civ2IconShadow, false, true );
		elseif type == NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER then
			local index = iGameValue;
			CivIconHookup( index, 80, instance.PeaceImage, instance.CivIconBG, instance.CivIconShadow, false, true );
		elseif type == NotificationTypes.NOTIFICATION_PEACE then
			local index = iGameValue;
			CivIconHookup( index, 45, instance.Peace1Image, instance.Civ1IconBG, instance.Civ1IconShadow, false, true );
			index = iExtraGameData;
			CivIconHookup( index, 45, instance.Peace2Image, instance.Civ2IconBG, instance.Civ2IconShadow, false, true );
		end
       
    end
    
    button:SetHide( false );
    button:SetVoid1( Id );
    button:RegisterCallback( Mouse.eLClick, GenericLeftClick );
    button:RegisterCallback( Mouse.eRClick, GenericRightClick );
--    title:SetText( name );
--    text:SetText( toolTip );
    
    local strToolTip = toolTip;
    button:SetToolTipString(strToolTip);
    
       
    g_ActiveNotifications[ Id ] = type;
    
    ProcessStackSizes();

end

-------------------------------------------------------------------------------------------------
function RemoveNotificationID( Id )
	print("removing notification: "..getstr(Id));

    if( g_ActiveNotifications[ Id ] == nil )
    then
        print( "Attempt to remove unknown Notification " .. tostring( Id ) );
        return;
    end

    local name = g_NameTable[ g_ActiveNotifications[ Id ] ];
    
    if( name == "Production" or
        name == "Tech" or
        name == "FreeTech" or
        name == "FreePolicy" or
	name == "FreeGreatPerson" )
    then
        Controls[ name .. "Button" ]:SetHide( true );
    else
     
        if( name == nil ) then
            name = "Generic";
        end
        
        local instance = g_Instances[ Id ];
        if( instance ~= nil ) then
			Controls.SmallStack:ReleaseChild( instance[ name .. "Container" ] );
		    g_Instances[ Id ] = nil;
		end
        
    end
    
	g_ActiveNotifications[ Id ] = nil;    
end

-------------------------------------------------------------------------------------------------
function NotificationRemoved( Id )
	--print("removed notification: "..getstr(Id));
	RemoveNotificationID( Id );	
    ProcessStackSizes();
end

-------------------------------------------------------------------------------------------------
function OnNotificationPanelActivePlayerChanged( iActivePlayer, iPrevActivePlayer )
	-- Remove all the UI notifications.  The new player will rebroadcast any persistent ones from their last turn	
	for thisID, thisType in pairs(g_ActiveNotifications) do
		RemoveNotificationID(thisID);
	end

end

-------------------------------------------------------------------------------------------------
function ProcessStackSizes()
    Controls.BigStack:CalculateSize();
    local bigY = Controls.BigStack:GetSizeY();
    Controls.SmallScrollPanel:SetSizeY( g_SmallScrollMax - bigY );

    Controls.SmallStack:CalculateSize();
    Controls.SmallStack:ReprocessAnchoring();

	Controls.SmallScrollPanel:CalculateInternalSize();
    if( Controls.SmallScrollPanel:GetRatio() ~= 1 ) then
        Controls.SmallScrollPanel:SetOffsetVal( 20, 0 );
    else
        Controls.SmallScrollPanel:SetOffsetVal( 0, 0 );
    end
    
    Controls.OuterStack:CalculateSize();
    Controls.OuterStack:ReprocessAnchoring();
end

--===============================================================================================
-- IGE HOOKS
--===============================================================================================
local function OnShowing()
	if IGE_HasGodsAndKings then
		Controls.FoundPantheonIGEImage:SetTexture("Assets/DLC/Expansion/UI/Art/Notification/NotificationIconsFreePantheon.dds");
		Controls.FoundPantheonIGEImageAlpha:SetTexture("Assets/DLC/Expansion/UI/Art/Notification/NotificationIconsFreePantheonGlow2.dds");

		Controls.FoundReligionIGEImage:SetTexture("Assets/DLC/Expansion/UI/Art/Notification/NotificationIconsFreeFoundReligion.dds");
		Controls.FoundReligionIGEImageAlpha:SetTexture("Assets/DLC/Expansion/UI/Art/Notification/NotificationIconsFreeFoundReligionGlow2.dds");

		Controls.EnhanceReligionIGEImage:SetTexture("Assets/DLC/Expansion/UI/Art/Notification/NotificationIconsFreeEnhanceReligion.dds");
		Controls.EnhanceReligionIGEImageAlpha:SetTexture("Assets/DLC/Expansion/UI/Art/Notification/NotificationIconsFreeEnhanceReligionGlow2.dds");
	end

	Events.NotificationAdded.Add(OnNotificationAdded);
	Events.NotificationRemoved.Add(NotificationRemoved);
	Events.GameplaySetActivePlayer.Add(OnNotificationPanelActivePlayerChanged);

	OnNotificationPanelActivePlayerChanged()
	UI.RebroadcastNotifications();
	ProcessStackSizes();
end
LuaEvents.IGE_Showing.Add(OnShowing);

-------------------------------------------------------------------------------------------------
local function OnClosing()
	Events.NotificationAdded.Remove(OnNotificationAdded);
	Events.NotificationRemoved.Remove(NotificationRemoved);
	Events.GameplaySetActivePlayer.Remove(OnNotificationPanelActivePlayerChanged);
end
LuaEvents.IGE_Closing.Add(OnClosing);
