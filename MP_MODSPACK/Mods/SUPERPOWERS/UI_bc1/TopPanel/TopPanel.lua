--==========================================================
-- TopPanel.lua
-- Modified by bc1 from 1.0.3.276 code using Notepad++
-- code is common using switches
-- compatible with Putmalk's Civ IV Diplomacy Features Mod v10
-- compatible with Gazebo's City-State Diplomacy Mod (CSD) for Brave New World v 23
--==========================================================

Events.SequenceGameInitComplete.Add(function()

include "UserInterfaceSettings"
local UserInterfaceSettings = UserInterfaceSettings

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfo = GameInfoCache

include "IconHookup"
local IconHookup = IconHookup

include "ScanGP"
local ScanGP = ScanGP

local IsCiv5 = InStrategicView ~= nil
local IsCiv5GKBNW = Game.GetReligionName ~= nil
local IsCiv5BNW = IsCiv5 and Game.GetActiveLeague ~= nil

--==========================================================
-- Minor lua optimizations
--==========================================================

local ceil = math.ceil
local floor = math.floor
local max = math.max
local os_date = os.date
local os_time = os.time
local next = next
local pairs = pairs
local tonumber = tonumber
local format = string.format
local concat = table.concat
local insert = table.insert
local count = table.count or	--Firaxis specific
function( t )
	local n=0
	for _ in pairs(t) do
		n=n+1
	end
	return n
end

local ButtonPopupTypes = ButtonPopupTypes
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local FaithPurchaseTypes = FaithPurchaseTypes
local Game = Game
local IsOption = Game.IsOption
local GetActivePlayer = Game.GetActivePlayer
local GetActiveTeam = Game.GetActiveTeam
local GameDefines = GameDefines
local GameInfoTypes = GameInfoTypes
local GameOptionTypes = GameOptionTypes
local HexToWorld = HexToWorld
local L = Locale.ConvertTextKey
local GetPlot = Map.GetPlot
local GetPlotByIndex = Map.GetPlotByIndex
local MapNumPlotsM1 = Map.GetNumPlots()-1
local eLClick = Mouse.eLClick
local eRClick = Mouse.eRClick
local Players = Players
local ToGridFromHex = ToGridFromHex
local ToHexFromGrid = ToHexFromGrid
local Teams = Teams
local UI = UI

local RESOURCEUSAGE_STRATEGIC = ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC

-------------------------------
-- Globals
-------------------------------

--[[
local g_activePlayerID, g_activePlayer, g_activeTeamID, g_activeTeam, g_activeCivilizationID, g_activeCivilization, g_activeTeamTechs
	local activePlayerID = GetActivePlayer()
	local activeTeamID = GetActiveTeam()
	local activePlayer = Players[activePlayerID]
	local activeTeam = Teams[activeTeamID]
	local activeCivilizationID = activePlayer:GetCivilizationType()
	local activeCivilization = GameInfo.Civilizations[ activeCivilizationID ]
	local activeTeamTechs = activeTeam:GetTeamTechs()
--]]

local g_isScienceEnabled, g_isPoliciesEnabled, g_isHappinessEnabled, g_isReligionEnabled, g_isHealthEnabled

local g_PlayerSettings = {}
local g_GoodyPlots = {}
local g_NaturalWonderPlots = {}
local g_NaturalWonder = {}
local g_NaturalWonderIndex

local g_ResourceIcons = {}
local g_isSmallScreen = UIManager:GetScreenSizeVal() < (IsCiv5BNW and 720 or 360)
local g_isPopupUp = false
local g_requestTopPanelUpdate

local g_clockFormats = { "%H:%M", "%I:%M %p", "%X", "%c" }
local g_clockFormat, g_alarmTime
local g_startTurn = Game.GetStartTurn()

local g_scienceTextColor = IsCiv5 and "[COLOR:33:190:247:255]" or "[COLOR_MENU_BLUE]"
local g_currencyIcon = IsCiv5 and "[ICON_GOLD]" or "[ICON_ENERGY]"
local g_currencyString = IsCiv5 and "GOLD" or "ENERGY"
--local g_happinessIcon = IsCiv5 and "[ICON_HAPPY]" or "[ICON_HEALTH]"

-------------------------------
-- Utilities
-------------------------------
local SearchForPediaEntry = Events.SearchForPediaEntry.Call
local GameMessagePopup = Events.SerialEventGameMessagePopup.Call
local function GamePopup( popupType, data2 )
	GameMessagePopup{ Type = popupType, Data1 = 1, Data2 = data2 }
end

local function Colorize( x )
	if x > 0 then
		return "[COLOR_POSITIVE_TEXT]" .. x .. "[ENDCOLOR]"
	elseif x < 0 then
		return "[COLOR_WARNING_TEXT]" .. x .. "[ENDCOLOR]"
	else
		return "0"
	end
end

-------------------------------------------------
-- Top Panel Update
-------------------------------------------------

local function UpdateTopPanelNow()

	g_requestTopPanelUpdate = false
	local activePlayer = Players[ GetActivePlayer() ]
	local activeTeamTechs = Teams[ GetActiveTeam() ]:GetTeamTechs()

	local Controls = Controls
	-----------------------------
	-- Update science stats
	-----------------------------
	if g_isScienceEnabled then

		local sciencePerTurn = activePlayer:GetScienceTimes100() / 100

		-- Gold being deducted from our Science ?
		if activePlayer:GetScienceFromBudgetDeficitTimes100() == 0 then
			-- Normal Science state
			Controls.SciencePerTurn:SetText( format( "%s+%.0f[ENDCOLOR][ICON_RESEARCH]", g_scienceTextColor, sciencePerTurn ) )
		else
			-- Science deductions
			Controls.SciencePerTurn:SetText( format( "[COLOR:255:0:60:255]+%.0f[ENDCOLOR][ICON_RESEARCH]", sciencePerTurn ) )
		end

		if IsCiv5 then
			local researchTurnsLeft
			local techID = activePlayer:GetCurrentResearch()

			if techID ~= -1 then
				-- research in progress
				local scienceNeeded = activePlayer:GetResearchCost( techID )
				if sciencePerTurn > 0 and scienceNeeded > 0 then
					researchTurnsLeft = activePlayer:GetResearchTurnsLeft( techID, true )
					local scienceProgress = activePlayer:GetResearchProgress( techID )
					Controls.ScienceBar:SetPercent( scienceProgress / scienceNeeded )
					Controls.ScienceBarShadow:SetPercent( (scienceProgress + sciencePerTurn) / scienceNeeded )
				end
			else
				-- not researching a tech
				techID = activeTeamTechs:GetLastTechAcquired()
			end

			Controls.ScienceTurns:SetText( researchTurnsLeft )
			Controls.ScienceBox:SetHide( not researchTurnsLeft )
			-- if we have one, update the tech picture
			local techInfo = GameInfo.Technologies[ techID ]
			Controls.TechIcon:SetHide(not (techInfo and IconHookup( techInfo.PortraitIndex, 45, techInfo.IconAtlas, Controls.TechIcon )) )
		end
	end

	-----------------------------
	-- Update Resources
	-----------------------------

	for resourceID, instance in pairs( g_ResourceIcons ) do
		if activePlayer:GetNumResourceTotal( resourceID, true ) ~= 0 or activeTeamTechs:HasTech( instance.TechRevealID ) then
			instance.Count:SetText( Colorize( activePlayer:GetNumResourceAvailable(resourceID, true) ) )
			instance.Image:SetHide( false )
		else
			instance.Image:SetHide( true )
		end
	end

	-----------------------------
	-- Update turn counter
	-----------------------------
	local gameTurn = Game.GetGameTurn()
	if g_startTurn > 0 then
		gameTurn = gameTurn .. "("..(gameTurn-g_startTurn)..")"
	end
	Controls.CurrentTurn:LocalizeAndSetText( "TXT_KEY_TP_TURN_COUNTER", gameTurn )

	local culturePerTurn, cultureProgress

	if IsCiv5 then
		-- Clever Firaxis...
		culturePerTurn = activePlayer:GetTotalJONSCulturePerTurn()
		cultureProgress = activePlayer:GetJONSCulture()

		-----------------------------
		-- Update gold stats
		-----------------------------

		Controls.GoldPerTurn:LocalizeAndSetText( "TXT_KEY_TOP_PANEL_GOLD", activePlayer:GetGold(), activePlayer:CalculateGoldRate() )

		-----------------------------
		-- Update Happy & Golden Age
		-----------------------------

		local unhappyProductionModifier = 0
		local unhappyFoodModifier = 0
		local unhappyGoldModifier = 0

		if g_isHappinessEnabled then

			local happinessText
			local excessHappiness = activePlayer:GetExcessHappiness()
			local turnsRemaining = ""

			if not activePlayer:IsEmpireUnhappy() then

				happinessText = format("[COLOR:60:255:60:255]%i[ENDCOLOR][ICON_HAPPINESS_1]", excessHappiness)

			elseif activePlayer:IsEmpireVeryUnhappy() then

				happinessText = format("[COLOR:255:60:60:255]%i[ENDCOLOR][ICON_HAPPINESS_4]", -excessHappiness)
				unhappyFoodModifier = GameDefines.VERY_UNHAPPY_GROWTH_PENALTY
				if not IsCiv5BNW then
					unhappyProductionModifier = GameDefines.VERY_UNHAPPY_PRODUCTION_PENALTY
				end

			else -- IsEmpireUnhappy

				happinessText = format("[COLOR:255:60:60:255]%i[ENDCOLOR][ICON_HAPPINESS_3]", -excessHappiness)
				unhappyFoodModifier = GameDefines.UNHAPPY_GROWTH_PENALTY
			end
			Controls.HappinessString:SetText(happinessText)

			if IsCiv5BNW and excessHappiness < 0 then
				unhappyProductionModifier = max( -excessHappiness * GameDefines.VERY_UNHAPPY_PRODUCTION_PENALTY_PER_UNHAPPY, GameDefines.VERY_UNHAPPY_MAX_PRODUCTION_PENALTY )
				unhappyGoldModifier = max( -excessHappiness * GameDefines.VERY_UNHAPPY_GOLD_PENALTY_PER_UNHAPPY, GameDefines.VERY_UNHAPPY_MAX_GOLD_PENALTY )
			end

			local goldenAgeTurns = activePlayer:GetGoldenAgeTurns()
			local happyProgress = activePlayer:GetGoldenAgeProgressMeter()
			local happyNeeded = activePlayer:GetGoldenAgeProgressThreshold()
			local happyProgressNext = happyProgress + excessHappiness

			if goldenAgeTurns > 0 then
				Controls.GoldenAgeAnim:SetHide(false)
				Controls.HappyBox:SetHide(true)
				turnsRemaining = goldenAgeTurns
			else
				Controls.GoldenAgeAnim:SetHide(true)
				if happyNeeded > 0 then
					Controls.HappyBar:SetPercent( happyProgress / happyNeeded )
					Controls.HappyBarShadow:SetPercent( happyProgressNext / happyNeeded )
					if excessHappiness > 0 then
						turnsRemaining = ceil((happyNeeded - happyProgress) / excessHappiness)
					end
					Controls.HappyBox:SetHide(false)
				else
					Controls.HappyBox:SetHide(true)
				end
			end

			Controls.HappyTurns:SetText(turnsRemaining)
		end

		-----------------------------
		-- Update Faith
		-----------------------------
		if g_isReligionEnabled then
			local faithPerTurn = activePlayer:GetTotalFaithPerTurn()
			local faithProgress = activePlayer:GetFaith()
			local faithProgressNext = faithProgress + faithPerTurn

			local faithTarget, faithNeeded

			local iconSize = 45
			local faithPurchaseType = activePlayer:GetFaithPurchaseType()
			local faithPurchaseIndex = activePlayer:GetFaithPurchaseIndex()
			local capitalCity = activePlayer:GetCapitalCity()

			if faithPurchaseType == FaithPurchaseTypes.FAITH_PURCHASE_UNIT then

				faithTarget = GameInfo.Units[ faithPurchaseIndex ]
				faithNeeded = faithTarget and capitalCity and capitalCity:GetUnitFaithPurchaseCost(faithTarget.ID, true)

			elseif faithPurchaseType == FaithPurchaseTypes.FAITH_PURCHASE_BUILDING then

				faithTarget = GameInfo.Buildings[ faithPurchaseIndex ]
				faithNeeded = faithTarget and capitalCity and capitalCity:GetBuildingFaithPurchaseCost(faithTarget.ID, true)

			elseif faithPurchaseType == FaithPurchaseTypes.FAITH_PURCHASE_SAVE_PROPHET then

				faithTarget = GameInfo.Units.UNIT_PROPHET
				faithNeeded = activePlayer:GetMinimumFaithNextGreatProphet()

			elseif activePlayer:GetCurrentEra() < GameInfoTypes.ERA_INDUSTRIAL then
				if activePlayer:CanCreatePantheon(false) then

					faithTarget = GameInfo.Religions.RELIGION_PANTHEON
					iconSize = 48
					faithNeeded = Game.GetMinimumFaithNextPantheon()

				elseif Game.GetNumReligionsStillToFound() > 0 then

					faithTarget = GameInfo.Units.UNIT_PROPHET
					faithNeeded = activePlayer:GetMinimumFaithNextGreatProphet()
				end
			end

			local turnsRemaining = ""
			if faithNeeded and faithNeeded > 0 then
				Controls.FaithBar:SetPercent( faithProgress / faithNeeded )
				Controls.FaithBarShadow:SetPercent( faithProgressNext / faithNeeded )
				if faithPerTurn > 0 then
					turnsRemaining = ceil((faithNeeded - faithProgress) / faithPerTurn )
				end
				Controls.FaithBox:SetHide(false)
				Controls.FaithString:SetText( format("+%i[ICON_PEACE]", faithPerTurn ) )
			else
				Controls.FaithBox:SetHide(true)
				Controls.FaithString:SetText( format("[ICON_PEACE]%i(+%i)", faithProgress, faithPerTurn ) )
			end

			Controls.FaithTurns:SetText( turnsRemaining )

			Controls.FaithIcon:SetHide( not (faithTarget and IconHookup(faithTarget.PortraitIndex, iconSize, faithTarget.IconAtlas, Controls.FaithIcon) ) )
		end

		-----------------------------
		-- Update Great People
		-----------------------------
		local gp = ScanGP( activePlayer )

		if gp then
			Controls.GpBar:SetPercent( gp.Progress / gp.Threshold )
			Controls.GpBarShadow:SetPercent( (gp.Progress+gp.Change) / gp.Threshold )
			Controls.GpTurns:SetText(gp.Turns)
			Controls.GpBox:SetHide(false)
			local gpUnit = GameInfo.Units[ gp.Class.DefaultUnit ]
			Controls.GpIcon:SetHide(not (gpUnit and IconHookup(gpUnit.PortraitIndex, 45, gpUnit.IconAtlas, Controls.GpIcon)))
			Controls.GpBox:SetHide(true)
			Controls.GpIcon:SetHide(true)
			Controls.GpTurns:SetText("")
		else
			Controls.GpBox:SetHide(true)
			Controls.GpIcon:SetHide(true)
			Controls.GpTurns:SetText("")
		end

		-----------------------------
		-- Update Alerts
		-----------------------------

		local unitSupplyProductionModifier = activePlayer:GetUnitProductionMaintenanceMod()
		local globalProductionModifier = unhappyProductionModifier + unitSupplyProductionModifier

		if globalProductionModifier < 0
			or unhappyFoodModifier < 0
			or unhappyGoldModifier < 0
		then
			local tips = {}

			if activePlayer:IsEmpireVeryUnhappy() then
				insert( tips, L"TXT_KEY_TP_EMPIRE_VERY_UNHAPPY" )

			elseif activePlayer:IsEmpireUnhappy() then
				insert( tips, L"TXT_KEY_TP_EMPIRE_UNHAPPY" )
			end

			if unitSupplyProductionModifier < 0 then
				insert( tips, L("TXT_KEY_UNIT_SUPPLY_REACHED_TOOLTIP", activePlayer:GetNumUnitsSupplied(), activePlayer:GetNumUnitsOutOfSupply(), -unitSupplyProductionModifier ) )
			end

			local warningText = ""
			if unhappyFoodModifier < 0 then
				warningText = format("%+g%%[ICON_FOOD]", unhappyFoodModifier )
			end
			if globalProductionModifier < 0 then
				warningText = warningText .. format("%+g%%[ICON_PRODUCTION]", globalProductionModifier )
			end
			if unhappyGoldModifier < 0 then
				if globalProductionModifier == unhappyGoldModifier then
					warningText = warningText .. g_currencyIcon
				else
					warningText = warningText .. format("%+g%%%s", unhappyGoldModifier, g_currencyIcon )
				end
			end
			Controls.WarningString:SetText( " [COLOR:255:60:60:255]" .. warningText .. "[ENDCOLOR]" )

			Controls.WarningString:SetToolTipString( concat( tips, "[NEWLINE][NEWLINE]" ) )
			Controls.WarningString:SetHide(false)
			Controls.UnitSupplyString:SetHide(false)
		else
			Controls.WarningString:SetHide(true)
			Controls.UnitSupplyString:SetHide(true)
		end

		-----------------------------
		-- Update date
		-----------------------------
		local date = Game.GetTurnString()

		if IsCiv5GKBNW and activePlayer:IsUsingMayaCalendar() then
			Controls.CurrentDate:LocalizeAndSetToolTip( "TXT_KEY_MAYA_DATE_TOOLTIP", activePlayer:GetMayaCalendarLongString(), date )
			date = activePlayer:GetMayaCalendarString()
		end
		Controls.CurrentDate:SetText( date )

		-----------------------------
		-- Update Tourism and
		-- International Trade Routes
		-----------------------------
		if IsCiv5BNW then
			Controls.InternationalTradeRoutes:SetText( format( "%i/%i[ICON_INTERNATIONAL_TRADE]", activePlayer:GetNumInternationalTradeRoutesUsed(), activePlayer:GetNumInternationalTradeRoutesAvailable() ) )
			Controls.TourismString:SetText( format( "%+i[ICON_TOURISM]", activePlayer:GetTourism() ) )
		end
	else
		-----------------------------
		-- Update affinity status
		-----------------------------
		Controls.Purity:LocalizeAndSetText( "TXT_KEY_AFFINITY_STATUS", GameInfo.Affinity_Types.AFFINITY_TYPE_PURITY.IconString, activePlayer:GetAffinityLevel( GameInfoTypes.AFFINITY_TYPE_PURITY ) )
		local percentToNextPurityLevel = activePlayer:GetAffinityPercentTowardsNextLevel( GameInfoTypes.AFFINITY_TYPE_PURITY )
		if activePlayer:GetAffinityPercentTowardsMaxLevel( GameInfoTypes.AFFINITY_TYPE_PURITY ) >= 100 then
			percentToNextPurityLevel = 100
		end
		Controls.PurityProgressBar:Resize(5, floor((percentToNextPurityLevel/100)*30))

		Controls.Harmony:LocalizeAndSetText( "TXT_KEY_AFFINITY_STATUS", GameInfo.Affinity_Types.AFFINITY_TYPE_HARMONY.IconString, activePlayer:GetAffinityLevel( GameInfoTypes.AFFINITY_TYPE_HARMONY ) )
		local percentToNextHarmonyLevel = activePlayer:GetAffinityPercentTowardsNextLevel( GameInfoTypes.AFFINITY_TYPE_HARMONY )
		if activePlayer:GetAffinityPercentTowardsMaxLevel( GameInfoTypes.AFFINITY_TYPE_HARMONY ) >= 100 then
			percentToNextHarmonyLevel = 100
		end
		Controls.HarmonyProgressBar:Resize(5, floor((percentToNextHarmonyLevel/100)*30))

		Controls.Supremacy:LocalizeAndSetText( "TXT_KEY_AFFINITY_STATUS", GameInfo.Affinity_Types.AFFINITY_TYPE_SUPREMACY.IconString, activePlayer:GetAffinityLevel( GameInfoTypes.AFFINITY_TYPE_SUPREMACY ) )
		local percentToNextSupremacyLevel = activePlayer:GetAffinityPercentTowardsNextLevel( GameInfoTypes.AFFINITY_TYPE_SUPREMACY )
		if activePlayer:GetAffinityPercentTowardsMaxLevel( GameInfoTypes.AFFINITY_TYPE_SUPREMACY ) >= 100 then
			percentToNextSupremacyLevel = 100
		end
		Controls.SupremacyProgressBar:Resize(5, floor((percentToNextSupremacyLevel/100)*30))

		-----------------------------
		-- Update energy stats
		-----------------------------

		Controls.GoldPerTurn:LocalizeAndSetText( "TXT_KEY_TOP_PANEL_ENERGY", activePlayer:GetEnergy(), activePlayer:CalculateGoldRate() )

		-----------------------------
		-- Update Health
		-----------------------------
		if g_isHealthEnabled then
			local excessHealth = activePlayer:GetExcessHealth()
			if excessHealth < 0 then
				Controls.HealthString:SetText( format("[COLOR_RED]%i[ENDCOLOR][ICON_HEALTH_3]", -excessHealth) )
			else
				Controls.HealthString:SetText( format("[COLOR_GREEN]%i[ENDCOLOR][ICON_HEALTH_1]", excessHealth) )
			end
--				SetAutoWidthGridButton( Controls.HealthString, strHealth, BUTTON_PADDING )
		end

		-- Clever Firaxis...
		culturePerTurn = activePlayer:GetTotalCulturePerTurn()
		cultureProgress = activePlayer:GetCulture()
	end

	-----------------------------
	-- Update Culture
	-----------------------------

	if g_isPoliciesEnabled then

		local cultureTheshold = activePlayer:GetNextPolicyCost()
		local cultureProgressNext = cultureProgress + culturePerTurn
		local turnsRemaining = ""

		if cultureTheshold > 0 then
			Controls.CultureBar:SetPercent( cultureProgress / cultureTheshold )
			Controls.CultureBarShadow:SetPercent( cultureProgressNext / cultureTheshold )
			if culturePerTurn > 0 then
				turnsRemaining = ceil((cultureTheshold - cultureProgress) / culturePerTurn )
			end
			Controls.CultureBox:SetHide(false)
		else
			Controls.CultureBox:SetHide(true)
		end

		Controls.CultureTurns:SetText(turnsRemaining)
		Controls.CultureString:SetText( format("[COLOR_MAGENTA]+%i[ENDCOLOR][ICON_CULTURE]", culturePerTurn ) )
	end

	Controls.TopPanelInfoStack:CalculateSize()
	Controls.TopPanelDiploStack:CalculateSize()
	Controls.TopPanelInfoStack:ReprocessAnchoring()
	Controls.TopPanelDiploStack:ReprocessAnchoring()
	Controls.TopPanelBarL:SetSizeX( Controls.TopPanelInfoStack:GetSizeX() + 15 )
	Controls.TopPanelBarR:SetSizeX( Controls.TopPanelDiploStack:GetSizeX() + 15 )
end

---------------
-- Civilopedia
---------------
Controls.CivilopediaButton:RegisterCallback( eLClick, function() SearchForPediaEntry( "" ) end )

---------------
-- Menu
---------------
Controls.MenuButton:RegisterCallback( eLClick, function()
	return UIManager:QueuePopup( LookUpControl( "/InGame/GameMenu" ), PopupPriority.InGameMenu )
end)

Controls.ExitCityScreen:RegisterCallback( eLClick, Events.SerialEventExitCityScreen.Call )

Events.SerialEventEnterCityScreen.Add( function()
	return Controls.ExitCityScreen:SetHide( false )
end)

Events.SerialEventExitCityScreen.Add( function()
	return Controls.ExitCityScreen:SetHide( true )
end)

-- Science
local function OnTechLClick()
	GamePopup( ButtonPopupTypes.BUTTONPOPUP_TECH_TREE, -1 )
end
local function OnTechRClick()
	local activePlayer = Players[ GetActivePlayer() ]
	local techInfo = GameInfo.Technologies[ activePlayer:GetCurrentResearch() ] or GameInfo.Technologies[ activePlayer:GetCurrentResearch() ]
	SearchForPediaEntry( techInfo and techInfo.Description or "TXT_KEY_TECH_HEADING1_TITLE" )	-- TXT_KEY_PEDIA_CATEGORY_3_LABEL
end

Controls.SciencePerTurn:RegisterCallback( eLClick, OnTechLClick )
Controls.SciencePerTurn:RegisterCallback( eRClick, OnTechRClick )
if IsCiv5 then
	Controls.TechIcon:RegisterCallback( eLClick, OnTechLClick )
	Controls.TechIcon:RegisterCallback( eRClick, OnTechRClick )
end

-- Gold
Controls.GoldPerTurn:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW ) end )
Controls.GoldPerTurn:RegisterCallback( eRClick, function() SearchForPediaEntry( format("TXT_KEY_%s_HEADING1_TITLE", g_currencyString) ) end )

-- Culture
Controls.CultureString:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY ) end )
Controls.CultureString:RegisterCallback( eRClick, function() SearchForPediaEntry( "TXT_KEY_CULTURE_HEADING1_TITLE" ) end )	-- TXT_KEY_PEDIA_CATEGORY_8_LABEL

if IsCiv5 then
	-- Great People
	Controls.GpIcon:RegisterCallback( eLClick,
	function()
		local gp = ScanGP( Players[GetActivePlayer()] )
		if gp then
			return UI.DoSelectCityAtPlot( gp.City:Plot() )
		end
	end)
	Controls.GpIcon:RegisterCallback( eRClick,
	function()
		local gp = ScanGP( Players[GetActivePlayer()] )
		if gp then
			return SearchForPediaEntry( GameInfo.Units[ gp.Class.DefaultUnit ].Description )
		end
	end)
	-- Happiness
	Controls.HappinessString:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW, 2 ) end )
	Controls.HappinessString:RegisterCallback( eRClick, function() SearchForPediaEntry( "TXT_KEY_GOLD_HEADING1_TITLE" ) end )

	if IsCiv5GKBNW then
		-- Faith
		local function OnFaithLClick()
			return GamePopup( ButtonPopupTypes.BUTTONPOPUP_RELIGION_OVERVIEW )
		end
		local function OnFaithRClick()
			return SearchForPediaEntry( "TXT_KEY_CONCEPT_RELIGION_FAITH_EARNING_DESCRIPTION" )	-- TXT_KEY_PEDIA_CATEGORY_15_LABEL
		end
		Controls.FaithString:RegisterCallback( eLClick, OnFaithLClick )
		Controls.FaithString:RegisterCallback( eRClick, OnFaithRClick )
		Controls.FaithString:SetHide( false )
		Controls.FaithTurns:SetHide( false )
		Controls.FaithIcon:RegisterCallback( eLClick, OnFaithLClick )
		Controls.FaithIcon:RegisterCallback( eRClick, OnFaithRClick )
		Controls.FaithIcon:SetHide( false )
	end

	if IsCiv5BNW then
		-- Tourism
		Controls.TourismString:SetHide(false)
		Controls.TourismString:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_CULTURE_OVERVIEW, 4 ) end )
		Controls.TourismString:RegisterCallback( eRClick, function() SearchForPediaEntry( "TXT_KEY_CULTURE_TOURISM_HEADING2_TITLE" ) end )	-- TXT_KEY_CULTURE_TOURISM_AND_CULTURE_HEADING2_TITLE
		-- Trade routes
		Controls.InternationalTradeRoutes:SetHide(false)
		Controls.InternationalTradeRoutes:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_TRADE_ROUTE_OVERVIEW ) end )
		Controls.InternationalTradeRoutes:RegisterCallback( eRClick, function() SearchForPediaEntry( "TXT_KEY_TRADE_ROUTES_HEADING2_TITLE" ) end )	-- TXT_KEY_TRADE_ROUTES_HEADING2_TITLE
	end
else
	Controls.HealthString:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW, 2 ) end )
	Controls.HealthString:RegisterCallback( eRClick, function() SearchForPediaEntry( "TXT_KEY_GOLD_HEADING1_TITLE" ) end )
	Controls.Harmony:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW, 2 ) end )
	Controls.Harmony:RegisterCallback( eRClick, function() SearchForPediaEntry( GameInfo.Affinity_Types.AFFINITY_TYPE_HARMONY.Description ) end )
	Controls.Purity:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW, 2 ) end )
	Controls.Purity:RegisterCallback( eRClick, function() SearchForPediaEntry( GameInfo.Affinity_Types.AFFINITY_TYPE_PURITY.Description ) end )
	Controls.Supremacy:RegisterCallback( eLClick, function() GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW, 2 ) end )
	Controls.Supremacy:RegisterCallback( eRClick, function() SearchForPediaEntry( GameInfo.Affinity_Types.AFFINITY_TYPE_SUPREMACY.Description ) end )
end

-------------------------------------------------
-- Strategic Resources Tooltips & Click Actions
-------------------------------------------------

--[[
for _, texture in pairs{ NATURAL_WONDERS = "SV_NaturalWonders.dds", IMPROVEMENT_BARBARIAN_CAMP	= "SV_BarbarianCamp.dds", GOODY_HUT = "SV_AncientRuins.dds", RESOURCE_ARTIFACTS = "SV_AntiquitySite.dds", RESOURCE_HIDDEN_ARTIFACTS = "SV_AntiquitySite_Night.dds", FEATURE_FALLOUT = "SV_Fallout.dds" } do
	local instance = {}
	ContextPtr:BuildInstanceForControlAtIndex( "ResourceInstance", instance, Controls.TopPanelDiploStack, 7 )
	instance.Image:SetTexture( texture )
	instance.Image:SetTextureSizeVal( 160, 160 )
	instance.Image:NormalizeTexture()
	instance.Image:SetHide( false )
end
--]]

--[[
for _, texture in pairs{  RESOURCE_MANPOWER = "sv_electricity.dds" } do
	local instance = {}
	ContextPtr:BuildInstanceForControlAtIndex( "ResourceInstance", instance, Controls.TopPanelDiploStack, 7 )
	instance.Image:SetTexture( texture )
	instance.Image:SetTextureSizeVal( 160, 160 )
	instance.Image:NormalizeTexture()
	instance.Image:SetHide( false )
end
--]]

local function CreateIcon( index, texture, ToolTipHandler, OnLClick, OnRClick, ID )
	
	local instance = {}
	ContextPtr:BuildInstanceForControlAtIndex( "ResourceInstance", instance, Controls.TopPanelDiploStack, index )
	
	
	-- manpower resource icon
	if ID == 42 then
		instance.Image:SetTexture( "manpower.dds" )
		instance.Image:SetTextureSizeVal( 160, 160 )
		instance.Image:NormalizeTexture()

	-- nanomat icon
	elseif ID == 46 then
		instance.Image:SetTexture( "nanomat.dds" )
		instance.Image:SetTextureSizeVal( 160, 160 )
		instance.Image:NormalizeTexture()	
	
	-- electricity icon
	elseif ID == 43 then
		instance.Image:SetTexture( "sv_electricity.dds" )
		instance.Image:SetTextureSizeVal( 160, 160 )
		instance.Image:NormalizeTexture()
	
	-- consumer goods icon
	elseif ID == 44 then
		instance.Image:SetTexture( "bluricon.dds" )
		instance.Image:SetTextureSizeVal( 160, 160 )
		instance.Image:NormalizeTexture()
	
	else	
		instance.Image:SetTexture( texture )
		instance.Image:SetTextureSizeVal( 160, 160 )
		instance.Image:NormalizeTexture()
	end
	
	--TOOLTIP ASSIGNMENT
	--skip manpower tooltip
	if ID == 42 then
		--instance.Count:SetToolTipType()
		instance.Count:SetToolTipCallback( ToolTipHandler )
	
	elseif ToolTipHandler then		
		--instance.Count:SetToolTipType()
		instance.Count:SetToolTipCallback( ToolTipHandler )
	else
		instance.Count:SetToolTipType()
	end
	instance.Count:RegisterCallback( eLClick, OnLClick )
	instance.Count:RegisterCallback( eRClick, OnRClick )
	instance.Count:SetVoid1( ID )
	return instance
end



local function FindOnMap( list, index, nameFunc )
	local plot
	index, plot = next( list, index )
	if not plot then
		index, plot = next( list, index )
	end
	if plot then
		UI.LookAt( plot )
		local hex = ToHexFromGrid{ x=plot:GetX(), y=plot:GetY() }
		Events.GameplayFX( hex.x, hex.y, -1 )
		Events.AddPopupTextEvent( HexToWorld( hex ), nameFunc( plot ) or "*", 0 )
	end
	return index
end

	
			
-------------------------------------------------
-- Initialization
-------------------------------------------------
local function OnResourceLClick()
	return GamePopup( ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW )
end
local function OnResourceRClick( resourceID )
	return SearchForPediaEntry( GameInfo.Resources[ resourceID ]._Name )
end
for resource in GameInfo.Resources() do
	local resourceID = resource.ID
	if Game.GetResourceUsageType( resourceID ) == RESOURCEUSAGE_STRATEGIC then
					
		local instance = CreateIcon( 9, resource._Texture, LuaEvents.ResourceToolTip.Call, OnResourceLClick, OnResourceRClick, resourceID )
		if instance then
			instance.TechRevealID = GameInfoTypes[resource.TechReveal]
			g_ResourceIcons[ resourceID ] = instance
		end
	end
end

local function NaturalWonderInfo( plot )
	local row = g_NaturalWonder[ plot:GetFeatureType() ] 
	return row and row._Name
end

local g_NaturalWonderIcon = CreateIcon( 9, "SV_NaturalWonders.dds",
		nil,
--			setTextToolTip( L"TXT_KEY_ADVISOR_DISCOVERED_NATURAL_WONDER_DISPLAY" )
		function()
			g_NaturalWonderIndex = FindOnMap( g_NaturalWonderPlots, g_NaturalWonderIndex, NaturalWonderInfo )
		end,
		function()
			return SearchForPediaEntry( NaturalWonderInfo( g_NaturalWonderPlots[g_NaturalWonderIndex or next(g_NaturalWonderPlots)] ) )
		end,
		-1 )

Events.NaturalWonderRevealed.Add( function( hexX, hexY )
print("NaturalWonderRevealed at", ToGridFromHex( hexX, hexY ) )
	local plot = GetPlot( ToGridFromHex( hexX, hexY ) )
	if plot then
		local index = plot:GetPlotIndex()
		g_NaturalWonderPlots[ index ] = plot
		g_NaturalWonderIcon.Image:SetHide( false )
		g_NaturalWonderIcon.Count:SetText( count( g_NaturalWonderPlots ) )
	end
end )

local function UpdateTopPanel()
	g_requestTopPanelUpdate = true
end

local function UpdateOptions()
	g_clockFormat = UserInterfaceSettings.Clock ~= 0 and g_clockFormats[ UserInterfaceSettings.ClockMode or 1 ]
	Controls.CurrentTime:SetHide( not g_clockFormat )
	g_isScienceEnabled = not IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)
	g_isPoliciesEnabled = not IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES)
	g_isHappinessEnabled = IsCiv5 and not IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS)
	g_isReligionEnabled = IsCiv5GKBNW and not IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)
	g_isHealthEnabled = not IsCiv5 and not IsOption(GameOptionTypes.GAMEOPTION_NO_HEALTH)
	UpdateTopPanel()
end

for row in GameInfo.Features() do
	if row.NaturalWonder then
		g_NaturalWonder[ row.ID ] = row
	end
end

local function SetActivePlayer()
	local activePlayerID = GetActivePlayer()
	local activeTeamID = GetActiveTeam()
	local t = g_PlayerSettings[ activePlayerID ]
	if not t then
		t = { GoodyPlots = {}, NaturalWonderPlots = {} }
		local GetPlotByIndex = GetPlotByIndex
		local plot
		for index = 0, MapNumPlotsM1 do
			plot = GetPlotByIndex( index )
			if plot and plot:IsRevealed( activeTeamID ) then
				if plot:IsGoody() then
					t.GoodyPlots[ index ] = plot
				elseif plot:HasBarbarianCamp() then
				elseif g_NaturalWonder[ plot:GetFeatureType() ] then
					t.NaturalWonderPlots[ index ] = plot
				end
			end
		end
		g_PlayerSettings[ activePlayerID ] = t
	end
	g_NaturalWonderPlots = t.NaturalWonderPlots
	g_NaturalWonderIndex = nil
	g_GoodyPlots = t.GoodyPlots
	local n = count( g_NaturalWonderPlots )
	g_NaturalWonderIcon.Image:SetHide( n<1 )
	g_NaturalWonderIcon.Count:SetText( n )
	UpdateOptions()
end
SetActivePlayer()

Controls.TopPanelBar:SetHide( not g_isSmallScreen )
Controls.TopPanelBarL:SetHide( g_isSmallScreen )
Controls.TopPanelBarR:SetHide( g_isSmallScreen )
Controls.TopPanelMask:SetHide( true )
local TopPanelTooltip = LuaEvents.TopPanelTooltips.Call
for k in ("SciencePerTurn TechIcon GoldPerTurn GpIcon HappinessString GoldenAgeString CultureString FaithString FaithIcon TourismString InternationalTradeRoutes HealthString Harmony Purity Supremacy"):gmatch("(%S*)%s*") do
	if Controls[k] then Controls[k]:SetToolTipCallback( TopPanelTooltip ) end
end

-------------------------------------------------
-- Use an animation control to control refresh (not per frame!)
-- Periodic refresh Speed is determined by "Timer" AlphaAnim in xml
-------------------------------------------------
Controls.Timer:RegisterAnimCallback( function()

	if g_alarmTime and os_time() >= g_alarmTime then
		g_alarmTime = nil
		UI.AddPopup{ Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
			Data1 = 800,	-- WrapWidth
			Option1 = true, -- show TopImage
			Text = os_date( g_clockFormat ) }
	end

	if g_clockFormat then
		Controls.CurrentTime:SetText( os_date( g_clockFormat ) )
	end

	if g_isPopupUp ~= UI.IsPopupUp() then
		Controls.TopPanelMask:SetHide( g_isPopupUp or g_isSmallScreen )
		g_isPopupUp = not g_isPopupUp
		UpdateTopPanelNow()

	elseif g_requestTopPanelUpdate then
		UpdateTopPanelNow()
	end
end)

Events.SerialEventGameDataDirty.Add( UpdateTopPanel )
Events.SerialEventTurnTimerDirty.Add( UpdateTopPanel )
Events.SerialEventCityInfoDirty.Add( UpdateTopPanel )
Events.SerialEventImprovementCreated.Add( UpdateTopPanel )	-- required to update happiness & resources if a resource got hooked up
Events.GameplaySetActivePlayer.Add( SetActivePlayer )
Events.GameOptionsChanged.Add( UpdateOptions )

-------------------------------------------------
-- Alarm Clock
-------------------------------------------------

for clockFormatIndex, clockFormat in ipairs( g_clockFormats ) do
	local instance = {}
	ContextPtr:BuildInstanceForControl( "ClockOptionInstance", instance, Controls.ClockOptions )
	instance = instance.ClockOption
	instance:GetTextButton():SetText( os_date( clockFormat ) )
	instance:SetCheck( g_clockFormat == clockFormat )
	instance:RegisterCheckHandler(
	function( isChecked )
		if isChecked then
			UserInterfaceSettings.ClockMode = clockFormatIndex
			UpdateOptions()
		end
	end)
end
local function GetAlarmOptions()
	g_alarmTime = nil
	local time = tonumber( UserInterfaceSettings.AlarmTime ) or 0
	local t = os_date( "*t", time )
	if t then
		Controls.AlarmHours:SetText( format( "%2d", t.hour ) )
		Controls.AlarmMinutes:SetText( format( "%2d", t.min ) )
		if time > os_time() + 1 and UserInterfaceSettings.AlarmIsOff == 0 then
			g_alarmTime = time
		end
	end
	Controls.AlarmCheckBox:SetCheck( g_alarmTime )
end
GetAlarmOptions()
Controls.ClockOptions:CalculateSize()
Controls.ClockOptionsPanel:SetSizeY( Controls.ClockOptions:GetSizeY() + 88 )

Controls.CurrentTime:RegisterCallback( eLClick,
function()
	Controls.ClockOptionsPanel:SetHide( not Controls.ClockOptionsPanel:IsHidden() )
end)

Controls.ClockOptionsPanelClose:RegisterCallback( eLClick,
function()
	Controls.ClockOptionsPanel:SetHide( true )
end)

local function SetAlarmOptions()
	local time = os_date("*time")
	time.hour = tonumber( Controls.AlarmHours:GetText() ) or 0
	time.min = tonumber( Controls.AlarmMinutes:GetText() ) or 0
	time = os_time(time)

	if time < os_time()+2 then
		time = time + 86400	-- 1 day in seconds
	end
	UserInterfaceSettings.AlarmTime = time
	UserInterfaceSettings.AlarmIsOff = Controls.AlarmCheckBox:IsChecked() and 0 or 1 -- reversed since off by default !

	GetAlarmOptions()
end

Controls.AlarmHours:RegisterCallback( SetAlarmOptions )
Controls.AlarmMinutes:RegisterCallback( SetAlarmOptions )
Controls.AlarmCheckBox:RegisterCheckHandler( SetAlarmOptions )

end)


