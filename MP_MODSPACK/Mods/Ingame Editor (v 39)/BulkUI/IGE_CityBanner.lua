-- Released under GPL v3
--------------------------------------------------------------
include("IGE_Utils");
include("IconSupport");
include("InstanceManager");
include("InfoTooltipInclude");
include("IGE_InfoToolTipInclude")
print("loaded");

local cityManager = InstanceManager:new("CityBanner",  "Anchor", Controls.CityBanners);
local iActivePlayer = nil;

local defaultErrorTextureSheet48 = "CityBannerProductionImage.dds";
local nullOffset = Vector2( 0, 0 );

local instances = {};
local playerStride = 1000;

-------------------------------------------------------------------------------------------------
local function RefreshCityDamage(instance, iDamage)
	local iMaxDamage = GameDefines.MAX_CITY_HIT_POINTS;
	local iHealthPercent = 1 - (iDamage / iMaxDamage);

    instance.CityBannerHealthBar:SetPercent(iHealthPercent);
    
	---- Health bar color based on amount of damage
	local tBarColor = {};
    if iHealthPercent > 0.66 then
        tBarColor.x = 0;
        tBarColor.y = 1;
        tBarColor.z = 0;
        tBarColor.w = 1;
        instance.CityBannerHealthBar:SetFGColor( tBarColor );
    elseif iHealthPercent > 0.33 then
        tBarColor.x = 1;
        tBarColor.y = 1;
        tBarColor.z = 0;
        tBarColor.w = 1;
        instance.CityBannerHealthBar:SetFGColor( tBarColor );
    else
        tBarColor.x = 1;
        tBarColor.y = 0;
        tBarColor.z = 0;
        tBarColor.w = 1;
        instance.CityBannerHealthBar:SetFGColor( tBarColor );
    end
    
    -- Show or hide the Health Bar as necessary
    if (iDamage == 0) then
		instance.CityBannerHealthBarBase:SetHide( true );
		instance.CityBannerHealthBar:SetHide( true );
	else
		instance.CityBannerHealthBarBase:SetHide( false );
		instance.CityBannerHealthBar:SetHide( false );
    end
end

-------------------------------------------------------------------------------------------------
function DoResizeBanner(BannerInstance)

	-- Just in case
	BannerInstance.NameStack:CalculateSize();
	BannerInstance.NameStack:ReprocessAnchoring();

	local iWidth = BannerInstance.NameStack:GetSizeX();
		
	-- If this control doesn't exist, then we're using the active player banner as opposed to the other player.
	-- NOTE:	There are rare instances when the active player will change (hotseat, autoplay) so just checking
	--			the active player is not good enough.
	if (BannerInstance.CityBannerBaseFrame == nil) then
		iWidth = iWidth + 115;	-- Offset for human player's banners

		BannerInstance.CityBannerBackgroundIcon:SetSizeX(iWidth);
		BannerInstance.CityBannerButtonGlow:SetSizeX(iWidth);
		BannerInstance.CityBannerButtonBase:SetSizeX(iWidth);
		
	else
		iWidth = iWidth + 50;	-- Offset for other player's banners
		BannerInstance.CityBannerBaseFrame:SetSizeX(iWidth);
	end

	BannerInstance.BannerButton:SetSizeX(iWidth);
	BannerInstance.CityBannerBackground:SetSizeX(iWidth);
	BannerInstance.CityBannerBackgroundHL:SetSizeX(iWidth);
	
	BannerInstance.BannerButton:ReprocessAnchoring();
	BannerInstance.NameStack:ReprocessAnchoring();
end

-------------------------------------------------------------------------------------------------
local function SetUpMinorMeter(status, instance, minorColor)
    local value;
	
	if( status < GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"] ) then
		value = status / GameDefines["MINOR_FRIENDSHIP_AT_WAR"];
	elseif( status < GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"] ) then
		value = (status - GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"]) / (GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"] - GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"]);
	elseif( status < GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"] ) then
		value = (status - GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"]) / (GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"] - GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"]);
	else
		value = (status - GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"]) / (GameDefines["FRIENDSHIP_THRESHOLD_MAX"] - GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"]);
	end
	
	instance.StatusMeterFrame:SetHide(value == 0);
	instance.StatusMeter:SetPercent( value );
end

-------------------------------------------------------------------------------------------------
local function GetCityStateStatus(pPlayer, iForPlayer, bWar)
	
	-- Status
	local strStatusTT = "";
	local strShortDescKey = pPlayer:GetCivilizationShortDescriptionKey();
	
	local iInfluenceChangeThisTurn = pPlayer:GetFriendshipChangePerTurnTimes100(iForPlayer) / 100;
	
	if (pPlayer:IsAllies(iForPlayer)) then		-- Allies
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_ALLIES"),
										  pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer), 
										  GameDefines["FRIENDSHIP_THRESHOLD_MAX"] - GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"]); 
		
		local strTempTT = Locale.ConvertTextKey("TXT_KEY_ALLIES_CSTATE_TT", strShortDescKey, iInfluenceChangeThisTurn);
		
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" .. strTempTT;
		
	elseif (pPlayer:IsFriends(iForPlayer)) then		-- Friends
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_FRIENDS"),
										    pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer),
										    GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"] - GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"]);
		
		local strTempTT = Locale.ConvertTextKey("TXT_KEY_FRIENDS_CSTATE_TT", strShortDescKey, iInfluenceChangeThisTurn);
		
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" .. strTempTT;
		
	elseif (pPlayer:IsMinorPermanentWar(iActiveTeam)) then		-- Permanent War
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_ANGRY"),
										    pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer), GameDefines["MINOR_FRIENDSHIP_AT_WAR"]);
										    
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_PERMANENT_WAR_CSTATE_TT", strShortDescKey);
		
	elseif (pPlayer:IsPeaceBlocked(iActiveTeam)) then		-- Peace blocked by being at war with ally
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_ANGRY"),
										    pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer), GameDefines["MINOR_FRIENDSHIP_AT_WAR"]);
										    
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_PEACE_BLOCKED_CSTATE_TT", strShortDescKey);
		
	elseif (bWar) then		-- War
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_ANGRY"),
										    pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer), GameDefines["MINOR_FRIENDSHIP_AT_WAR"]);
										    
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" ..Locale.ConvertTextKey("TXT_KEY_WAR_CSTATE_TT", strShortDescKey);
		
	elseif (pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer) < 0) then		-- Angry
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_ANGRY"),
										    pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer), GameDefines["MINOR_FRIENDSHIP_AT_WAR"]);
										    
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_ANGRY_CSTATE_TT", strShortDescKey, iInfluenceChangeThisTurn);
		
	else		-- Neutral
		strStatusTT = Locale.ConvertTextKey("TXT_KEY_DIPLO_STATUS_TT", Locale.ConvertTextKey(strShortDescKey), Locale.ConvertTextKey("TXT_KEY_CITY_STATE_PERSONALITY_NEUTRAL"),
										    pPlayer:GetMinorCivFriendshipWithMajor(iForPlayer) - GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"], 
											GameDefines["FRIENDSHIP_THRESHOLD_FRIENDS"] - GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"]);
										    
		strStatusTT = strStatusTT .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_NEUTRAL_CSTATE_TT", strShortDescKey);
	end
	
	return strStatusTT;
end

-------------------------------------------------------------------------------------------------
local function UpdateCityBanner(city)
	local ID = playerStride * city:GetOwner() + city:GetID();
	local iActiveTeam = Players[iActivePlayer]:GetTeam();
	local owner = Players[city:GetOwner()];

	-- Tooltip for owner status
	local strToolTip = "";
	if iActiveTeam == owner:GetTeam() then
		strToolTip = "";
	elseif not Teams[iActiveTeam]:IsHasMet(owner:GetTeam()) then
		strToolTip = L("TXT_KEY_HAVENT_MET");
	elseif Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_WAR) then
		strToolTip = L("TXT_KEY_ALWAYS_AT_WAR_WITH_CITY");
	elseif owner:IsMinorCiv() then
		local strShortDescKey = owner:GetCivilizationShortDescriptionKey();
		local bWar = Teams[iActiveTeam]:IsAtWar(team);
		strToolTip = GetCityStateStatus(owner, iActivePlayer, bWar);
	end

	-- Retrieve or create banner
	local instance = instances[ID];
	if not instance then
		instance = cityManager:GetInstance();
		instances[ID] = instance;

	    instance.BannerButton:RegisterCallback(Mouse.eLClick, OnBannerClick);
	    instance.BannerButton:SetVoid1(city:GetX());
	    instance.BannerButton:SetVoid2(city:GetY());
	    
    	instance.CityBannerProductionButton:RegisterCallback( Mouse.eLClick, OnProdClick );
    	instance.CityBannerProductionButton:SetVoid1(city:GetOwner());
    	instance.CityBannerProductionButton:SetVoid2(city:GetID());
	end
	
	-- Get colors
	local success, primaryColor, secondaryColor = pcall(owner.GetPlayerColors, owner);
	if not success then
		primaryColor = {x = 0, y = 0, z = 0, w = 0.7};
		secondaryColor = {x = 1, y = 1, z = 1, w = 0.7};
	end
	if owner:IsMinorCiv() then
		primaryColor, secondaryColor = secondaryColor, primaryColor;
	end
	local backgroundColor = {x = secondaryColor.x, y = secondaryColor.y, z = secondaryColor.z, w = 0.7};
	
	-- Background colors
	instance.CityBannerBackground:SetColor(backgroundColor);
	instance.RightBackground:SetColor( backgroundColor );
	instance.LeftBackground:SetColor( backgroundColor );
	
	-- Text colors
	local textColor = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 1};
	local textColor200 = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 0.7};	
	local textColorShadow = {x = 0, y = 0, z = 0, w = 0.5};
	local textColorSoft = {x = 1, y = 1, z = 1, w = 0.5};

	instance.CityProductionName:SetColor(textColor200, 0);
	instance.CityName:SetColor(textColor, 0);
	instance.CityName:SetColor(textColorShadow, 1);
	instance.CityName:SetColor(textColorSoft, 2);
    
	-- Update name
	local cityName = city:GetNameKey();
	local localizedCityName = L(cityName);
	local convertedKey = Locale.ToUpper(localizedCityName);
		
	local isCapital = city:IsCapital() or Players[city:GetOriginalOwner()]:IsMinorCiv();
	if city:IsCapital() and not owner:IsMinorCiv() then
		convertedKey = "[ICON_CAPITAL]" .. convertedKey;
	end

	instance.CityName:SetText(convertedKey);

	-- Update religion
	if IGE_HasGodsAndKings then
		local eReligion = city:GetReligiousMajority();
		
		instance.ReligiousIcon:SetTexture("assets/DLC/Expansion/UI/Art/Icons/ReligiousSymbolsWhite32_Expansion.dds");
		instance.ReligiousIconShadow:SetTexture("assets/DLC/Expansion/UI/Art/Icons/ReligiousSymbolsWhite32_Expansion.dds");

		if (eReligion >= 0) then
			local religion = GameInfo.Religions[eReligion];
			if religion then
				IconHookup( religion.PortraitIndex, 32, religion.IconAtlas, instance.ReligiousIcon );
				IconHookup( religion.PortraitIndex, 32, religion.IconAtlas, instance.ReligiousIconShadow );
			end
		end	
		
		local religionToolTip = "";
		if(GetReligionTooltip) then
			religionToolTip = GetReligionTooltip(city);
		end	
		
		if (religionToolTip ~= "") then
			strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]" .. religionToolTip;
		end
		instance.BannerButton:SetToolTipString(strToolTip);
	
		if (instance.ReligiousIcon ~= nil) then
			instance.ReligiousIcon:SetToolTipString(religionToolTip);
		end		
			
		local bHasReligion = (eReligion >= 0);
		if (instance.ReligiousIcon ~= nil) then
			instance.ReligiousIconContainer:SetHide(not bHasReligion);
		end
	else
		instance.ReligiousIconContainer:SetHide(true);
	end
	DoResizeBanner(instance);

	-- Connected to capital?
	if (not city:IsCapital() and owner:IsCapitalConnectedToCity(city) and not city:IsBlockaded()) then
		instance.ConnectedIcon:SetHide(false);
		instance.ConnectedIcon:SetToolTipString(L("TXT_KEY_CITY_CONNECTED"));
	else
		instance.ConnectedIcon:SetHide(true);
	end
			
	-- Blockaded
	if city:IsBlockaded() then
		instance.BlockadedIcon:SetHide(false);
		instance.BlockadedIcon:SetToolTipString(L("TXT_KEY_CITY_BLOCKADED"));
	else
		instance.BlockadedIcon:SetHide(true);
	end
		
	-- Being Razed
	if city:IsRazing() then
		instance.RazingIcon:SetHide(false);
		instance.RazingIcon:SetToolTipString(L( "TXT_KEY_CITY_BURNING", tostring(city:GetRazingTurns()) ));
	else
		instance.RazingIcon:SetHide(true);
	end
		
	-- In Resistance
	if city:IsResistance() then
		instance.ResistanceIcon:SetHide(false);
		instance.ResistanceIcon:SetToolTipString(L( "TXT_KEY_CITY_RESISTANCE", tostring(city:GetResistanceTurns()) ));
	else
		instance.ResistanceIcon:SetHide(true);
	end

	-- Puppet Status
	if city:IsPuppet() then
		instance.PuppetIcon:SetHide(false);
		instance.PuppetIcon:SetToolTipString(L("TXT_KEY_CITY_PUPPET"));
	else
		instance.PuppetIcon:SetHide(true);
	end
		
	-- Occupation Status
	if city:IsOccupied() and not city:IsNoOccupiedUnhappiness() then
		instance.OccupiedIcon:SetHide(false);
		instance.OccupiedIcon:SetToolTipString(L( "TXT_KEY_CITY_OCCUPIED"));
	else
		instance.OccupiedIcon:SetHide(true);
	end
	instance.IconsStack:ReprocessAnchoring();
		
	-- Strength
	local cityStrengthStr = math.floor(city:GetStrengthValue() / 100);
	instance.CityStrength:SetText(cityStrengthStr);

	-- Population
	local cityPopulation = math.floor(city:GetPopulation());
	instance.CityPopulation:SetText(cityPopulation);
		
	-- Damage
	RefreshCityDamage(instance, city:GetDamage());		

	-- Growth time
	local cityGrowth = city:GetFoodTurnsLeft();
			
	if (city:IsFoodProduction() or city:FoodDifferenceTimes100() == 0) then
		cityGrowth = "-";
		instance.LeftBackground:SetToolTipString(L("TXT_KEY_CITY_STOPPED_GROWING_TT", localizedCityName, cityPopulation));
	elseif city:FoodDifferenceTimes100() < 0 then
		cityGrowth = "[COLOR_WARNING_TEXT]-[ENDCOLOR]";
		instance.LeftBackground:SetToolTipString(L("TXT_KEY_CITY_STARVING_TT",localizedCityName ));
	else
		instance.LeftBackground:SetToolTipString(L("TXT_KEY_CITY_WILL_GROW_TT", localizedCityName, cityPopulation, cityPopulation+1, cityGrowth));
	end
	instance.CityGrowth:SetText(cityGrowth);
		
	-- Production time
	local buildGrowth = "-";
	if city:IsProduction() and not city:IsProductionProcess() then
		if city:GetCurrentProductionDifferenceTimes100(false, false) > 0 then
			buildGrowth = city:GetProductionTurnsLeft();
		end
	end
	instance.BuildGrowth:SetText(buildGrowth);
		
	-- Growth meter
	if instance.GrowthBar then
		local iCurrentFood = city:GetFood();
		local iFoodNeeded = city:GrowthThreshold();
		local iFoodPerTurn = city:FoodDifference();
		local iCurrentFoodPlusThisTurn = iCurrentFood + iFoodPerTurn;
			
		local fGrowthProgressPercent = iCurrentFood / iFoodNeeded;
		local fGrowthProgressPlusThisTurnPercent = iCurrentFoodPlusThisTurn / iFoodNeeded;
		if (fGrowthProgressPlusThisTurnPercent > 1) then
			fGrowthProgressPlusThisTurnPercent = 1
		end
			
		instance.GrowthBar:SetPercent( fGrowthProgressPercent );
		instance.GrowthBarShadow:SetPercent( fGrowthProgressPlusThisTurnPercent );
	end
		
	-- Production meter
	local iCurrentProduction = city:GetProduction();
	local iProductionNeeded = city:GetProductionNeeded();
	local iProductionPerTurn = city:GetYieldRate(YieldTypes.YIELD_PRODUCTION);
	if (city:IsFoodProduction()) then
		iProductionPerTurn = iProductionPerTurn + city:GetYieldRate(YieldTypes.YIELD_FOOD) - city:FoodConsumption(true);
	end
	local iCurrentProductionPlusThisTurn = iCurrentProduction + iProductionPerTurn;
			
	local fProductionProgressPercent = iCurrentProduction / iProductionNeeded;
	local fProductionProgressPlusThisTurnPercent = iCurrentProductionPlusThisTurn / iProductionNeeded;
	if (fProductionProgressPlusThisTurnPercent > 1) then
		fProductionProgressPlusThisTurnPercent = 1
	end
			
	instance.ProductionBar:SetPercent( fProductionProgressPercent );
	instance.ProductionBarShadow:SetPercent( fProductionProgressPlusThisTurnPercent );

	-- Production name
	local cityProductionName = city:GetProductionNameKey();
	if cityProductionName == nil or string.len(cityProductionName) == 0 then
		cityProductionName = "TXT_KEY_PRODUCTION_NO_PRODUCTION";
	end
		
	convertedKey = L(cityProductionName);
	instance.CityProductionName:SetText(convertedKey);
			
	if cityProductionName == "TXT_KEY_PRODUCTION_NO_PRODUCTION" then
		instance.RightBackground:SetToolTipString(L( "TXT_KEY_CITY_NOT_PRODUCING", localizedCityName));
	else
		local productionTurnsLeft = city:GetProductionTurnsLeft();
		local tooltipString;
		if productionTurnsLeft > 99 then
			tooltipString = L(L("TXT_KEY_CITY_CURRENTLY_PRODUCING_99PLUS_TT", localizedCityName, cityProductionName));
		else
			tooltipString = L(L("TXT_KEY_CITY_CURRENTLY_PRODUCING_TT", localizedCityName, cityProductionName, productionTurnsLeft));
		end
					
		instance.RightBackground:SetToolTipString(tooltipString);
	end
	
	-- Production icon
	local unitProduction = city:GetProductionUnit();
	local buildingProduction = city:GetProductionBuilding();
	local projectProduction = city:GetProductionProject();
	local processProduction = city:GetProductionProcess();
	local noProduction = false;

	if unitProduction ~= -1 then
		local thisUnitInfo = GameInfo.Units[unitProduction];
		if IconHookup( thisUnitInfo.PortraitIndex, 45, thisUnitInfo.IconAtlas, instance.CityBannerProductionImage ) then
			instance.CityBannerProductionImage:SetHide( false );
		else
			instance.CityBannerProductionImage:SetHide( true );
		end
	elseif buildingProduction ~= -1 then
		local thisBuildingInfo = GameInfo.Buildings[buildingProduction];
		if IconHookup( thisBuildingInfo.PortraitIndex, 45, thisBuildingInfo.IconAtlas, instance.CityBannerProductionImage ) then
			instance.CityBannerProductionImage:SetHide( false );
		else
			instance.CityBannerProductionImage:SetHide( true );
		end
	elseif projectProduction ~= -1 then
		local thisProjectInfo = GameInfo.Projects[projectProduction];
		if IconHookup( thisProjectInfo.PortraitIndex, 45, thisProjectInfo.IconAtlas, instance.CityBannerProductionImage ) then
			instance.CityBannerProductionImage:SetHide( false );
		else
			instance.CityBannerProductionImage:SetHide( true );
		end
	elseif processProduction ~= -1 then
		local thisProcessInfo = GameInfo.Processes[processProduction];
		if IconHookup( thisProcessInfo.PortraitIndex, 45, thisProcessInfo.IconAtlas, instance.CityBannerProductionImage ) then
			instance.CityBannerProductionImage:SetHide( false );
		else
			instance.CityBannerProductionImage:SetHide( true );
		end
	else -- really should have an error texture
		instance.CityBannerProductionImage:SetHide(true);
	end
		
	-- Set tool tip
	instance.BannerButton:SetToolTipString(strToolTip);

	-- Minor civilization status meter
	if not owner:IsMinorCiv() then
		instance.StatusMeterFrame:SetHide( true );
	else
		SetUpMinorMeter(owner:GetMinorCivFriendshipWithMajor(iActivePlayer), instance, textColor);
	end
		
	-- Perform layout
	instance.IconsStack:CalculateSize();
	instance.IconsStack:ReprocessAnchoring();
	local wx, wy, wz = GridToWorld(city:GetX(), city:GetY());
	instance.Anchor:SetWorldPositionVal(wx, wy, wz + 35);
end



--===============================================================================================
-- EVENTS
--===============================================================================================
function OnCityCreated(hexPos)
    local gridPosX, gridPosY = ToGridFromHex(hexPos.x, hexPos.y);
	local plot = Map.GetPlot(gridPosX, gridPosY);
	UpdateCityBanner(plot:GetPlotCity());
end

-------------------------------------------------------------------------------------------------
function OnCityDestroyed(hexPos, playerID, cityID, newPlayerID)
	print("OnCityDestroyed:", tostring(playerID), tostring(cityID), tostring(newPlayerID))
	local ID = playerStride * playerID + cityID;
	local instance = instances[ID];
	cityManager:ReleaseInstance(instance);
	instances[ID] = nil;
end

-------------------------------------------------------------------------------------------------
function OnCitySetDamage(iPlayerID, iCityID, iDamage, iPreviousDamage)
	local ID = playerStride * iPlayerID + iCityID;
	local instance = instances[ID];
	RefreshCityDamage(instance, iDamage);
end

-------------------------------------------------------------------------------------------------
function OnSpecificCityInfoDirty(iPlayerID, iCityID, eUpdateType)
	local player = Players[iPlayerID];
	local city = player:GetCityByID(iCityID);
	UpdateCityBanner(city);
end

-------------------------------------------------------------------------------------------------
function OnAllCityDirty()
	cityManager:ResetInstances();
	instances = {};
    local i = 0;
    local player = Players[i];
    while player ~= nil do
        if player:IsAlive() then
            for city in player:Cities() do
    			OnCityCreated( ToHexFromGrid( Vector2( city:GetX(), city:GetY() ) ), player:GetID(), city:GetID() );
            end
        end

        i = i + 1;
        player = Players[i];
    end
end

--===============================================================================================
-- INPUTS
--===============================================================================================
function OnBannerClick(x, y)
end

-------------------------------------------------------------------------------------------------
function OnProdClick(playerID, cityID)
	if playerID == Game.GetActivePlayer() then
		local player = Players[playerID];
		local city = player:GetCityByID(cityID);

		if city then
			local popupInfo = {
					Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
					Data1 = cityID,
					Data2 = -1,
					Data3 = -1,
					Option1 = false,
					Option2 = false;
				}
			Events.SerialEventGameMessagePopup(popupInfo);
		end
	end
end

--===============================================================================================
-- HOOKS
--===============================================================================================
local function OnShowing()
	iActivePlayer = Game.GetActivePlayer();
	Events.SerialEventCityCreated.Add(OnCityCreated);
	Events.SerialEventCityCaptured.Add(OnCityDestroyed);
	Events.SerialEventCityInfoDirty.Add(OnAllCityDirty);
	Events.SerialEventCityDestroyed.Add(OnCityDestroyed);
	Events.SerialEventCitySetDamage.Add(OnCitySetDamage);
	Events.SpecificCityInfoDirty.Add(OnSpecificCityInfoDirty);

	OnAllCityDirty();
end
LuaEvents.IGE_Showing.Add(OnShowing);

-------------------------------------------------------------------------------------------------
local function OnClosing()
	Events.SerialEventCityCreated.Remove(OnCityCreated);
	Events.SerialEventCityCaptured.Remove(OnCityDestroyed);
	Events.SerialEventCityInfoDirty.Remove(OnAllCityDirty);
	Events.SerialEventCityDestroyed.Remove(OnCityDestroyed);
	Events.SerialEventCitySetDamage.Remove(OnCitySetDamage);
	Events.SpecificCityInfoDirty.Remove(OnSpecificCityInfoDirty);
end
LuaEvents.IGE_Closing.Add(OnClosing);
