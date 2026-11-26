--==========================================================
-- Written by bc1 using Notepad++
-- Include for EUI context
--==========================================================

print( "Loading EUI tooltip server..." )

local UserInterfaceSettings = UserInterfaceSettings -- global defined by EUI_context
local GameInfo = GameInfoCache -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query

local IsCiv5 = InStrategicView ~= nil
local IsCivBE = not IsCiv5
local IsCiv5notVanilla = Game.GetReligionName ~= nil
local IsCiv5BNW = IsCiv5 and Game.GetActiveLeague ~= nil
local IsCiv5BNW_BE = IsCiv5BNW or IsCivBE

if IsCiv5BNW then
	include "GreatPeopleIcons"
end
local GreatPeopleIcons = GreatPeopleIcons

include "StackInstanceManager"

include "IconHookup"
local IconHookup = IconHookup
local CivIconHookup = CivIconHookup

include "ScanGP"
local ScanGP = ScanGP

include "ShortUnitTip"
local ShortUnitTip = ShortUnitTip

include "GetUnitBuildProgressData"
local GetUnitBuildProgressData = GetUnitBuildProgressData

include "ScratchDeal"
local ScratchDeal = ScratchDeal
local PopScratchDeal = PopScratchDeal
local PushScratchDeal = PushScratchDeal

include "CityStateStatusHelper"
local GetAllyToolTip = GetAllyToolTip
local GetActiveQuestToolTip = GetActiveQuestToolTip
local GetCityStateStatusToolTip = GetCityStateStatusToolTip

include "InfoTooltipInclude"
local GetHelpTextForUnit = GetHelpTextForUnit
local GetHelpTextForBuilding = GetHelpTextForBuilding
local GetHelpTextForProject = GetHelpTextForProject
local GetHelpTextForProcess = GetHelpTextForProcess
local GetHelpTextForImprovement = GetHelpTextForImprovement
local GetFoodTooltip = GetFoodTooltip
local GetGoldTooltip = IsCiv5 and GetGoldTooltip or GetEnergyTooltip
local GetScienceTooltip = GetScienceTooltip
local GetProductionTooltip = GetProductionTooltip
local GetCultureTooltip = GetCultureTooltip
local GetFaithTooltip = GetFaithTooltip
local GetReligionTooltip = GetReligionTooltip
local GetTourismTooltip = GetTourismTooltip
local GetMoodInfo = GetMoodInfo
local GetHelpTextForPlayerPerk = GetHelpTextForPlayerPerk -- BE only
local GetHelpTextForAffinity = GetHelpTextForAffinity -- BE only

include "TechHelpInclude"
local GetHelpTextForTech = GetHelpTextForTech

include "ShowProgress"
local ShowProgressToolTip = ShowProgressToolTip

--==========================================================
-- Minor lua optimizations
--==========================================================

local print = print
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local ceil = math.ceil
local floor = math.floor
local min = math.min
local max = math.max
local modf = math.modf
local insert = table.insert
local concat = table.concat
local format = string.format

local PreGame = PreGame
local Game = Game
local GetActivePlayer = Game.GetActivePlayer
local GetActiveTeam = Game.GetActiveTeam
local GetResourceUsageType = Game.GetResourceUsageType
local GameOptionTypes = GameOptionTypes
local GameInfoActions = GameInfoActions
local GameInfoTypes = GameInfoTypes
local GetPlot = Map.GetPlot
local PlotDirection = Map.PlotDirection
local L = Locale.ConvertTextKey
local Matchmaking = Matchmaking
local Network = Network
local OptionsManager = OptionsManager
local Players = Players
local Teams = Teams
local GetHeadSelectedCity = UI.GetHeadSelectedCity
local GetHeadSelectedUnit = UI.GetHeadSelectedUnit
local GetUnitPortraitIcon = UI.GetUnitPortraitIcon
local GetMousePos = UIManager.GetMousePos
local TradeableItems = TradeableItems
local DomainTypes = DomainTypes

local NUM_YIELD_TYPES_minus1 = YieldTypes.NUM_YIELD_TYPES - 1
local RESOURCEUSAGE_STRATEGIC = ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC
local RESOURCEUSAGE_LUXURY = ResourceUsageTypes.RESOURCEUSAGE_LUXURY
local RESOURCEUSAGE_BONUS = ResourceUsageTypes.RESOURCEUSAGE_BONUS
local TRADE_ITEM_RESOURCES = TradeableItems.TRADE_ITEM_RESOURCES
local ACTIONSUBTYPE_BUILD = ActionSubTypes.ACTIONSUBTYPE_BUILD
local ACTIONSUBTYPE_PROMOTION = ActionSubTypes.ACTIONSUBTYPE_PROMOTION
local RELIGION_PANTHEON = ReligionTypes and ReligionTypes.RELIGION_PANTHEON
local MOVE_DENOMINATOR = GameDefines.MOVE_DENOMINATOR
local MAX_CIV_PLAYERS_minus1 = GameDefines.MAX_CIV_PLAYERS - 1
local MAX_MAJOR_CIVS = GameDefines.MAX_MAJOR_CIVS
local DOF_EXPIRATION_TIME = GameDefines.DOF_EXPIRATION_TIME or 50
local MINOR_CIV_QUEST_CONNECT_RESOURCE = MinorCivQuestTypes.MINOR_CIV_QUEST_CONNECT_RESOURCE


local ORDER_TRAIN = OrderTypes.ORDER_TRAIN
local ORDER_CONSTRUCT = OrderTypes.ORDER_CONSTRUCT
local ORDER_CREATE = OrderTypes.ORDER_CREATE
local ORDER_MAINTAIN = OrderTypes.ORDER_MAINTAIN

local g_scienceTextColor = IsCiv5 and "[COLOR:33:190:247:255]" or "[COLOR_MENU_BLUE]"
local g_currencyIcon = IsCiv5 and "[ICON_GOLD]" or "[ICON_ENERGY]"
local g_currencyString = IsCiv5 and "GOLD" or "ENERGY"
local g_yieldCurrency = IsCiv5 and YieldTypes.YIELD_GOLD or YieldTypes.YIELD_ENERGY
--local g_maintenanceCurrency = IsCiv5 and "GoldMaintenance" or "EnergyMaintenance"
--local g_happinessIcon = IsCiv5 and "[ICON_HAPPY]" or "[ICON_HEALTH]"
local g_happinessString = IsCiv5 and "HAPPINESS" or "HEALTH"

local g_ItemTooltipControls = {}
TTManager:GetTypeControlTable( "EUI_ItemTooltip", g_ItemTooltipControls )

local g_UnitTooltipControls = {}
TTManager:GetTypeControlTable( "EUI_UnitTooltip", g_UnitTooltipControls )

local g_UnitActionTooltipControls = {}
TTManager:GetTypeControlTable( "EUI_UnitAction", g_UnitActionTooltipControls )

local g_CivilizationTooltipControls = {}
TTManager:GetTypeControlTable( "EUI_CivilizationTooltip", g_CivilizationTooltipControls )

local g_CityProductionTooltipControls = {}
TTManager:GetTypeControlTable( "EUI_CityProductionTooltip", g_CityProductionTooltipControls )

local g_CityGrowthTooltipControls = {}
TTManager:GetTypeControlTable( "EUI_CityGrowthTooltip", g_CityGrowthTooltipControls )

local g_TechProgressToolTipControls = {}
TTManager:GetTypeControlTable( "EUI_TopPanelProgressTooltip", g_TechProgressToolTipControls )

local g_isCityStateLeaders, g_isBasicHelp, g_isScienceEnabled, g_isReligionEnabled, g_isHappinessEnabled, g_isPoliciesEnabled, g_isHealthEnabled, g_isEspionageDisabled, g_isAlwaysWar, g_isOneCityChallenge

do
	Controls.UnitTooltipTimer:RegisterAnimCallback( function()
		g_UnitTooltipControls.PromotionText:SetHide( false )
		g_UnitTooltipControls.IconStack:SetWrapWidth( 32 )
		g_UnitTooltipControls.IconStack:CalculateSize()
		g_UnitTooltipControls.Box:DoAutoSize()
	end)

	local GetTooltip2Seconds = OptionsManager.GetTooltip2Seconds
	local function UpdateOptions()
		g_isScienceEnabled = not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)
		g_isPoliciesEnabled = not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES)
		g_isHappinessEnabled = IsCiv5 and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS)
		g_isReligionEnabled = IsCiv5notVanilla and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)
		g_isHealthEnabled = not IsCiv5 and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HEALTH)
		g_isEspionageDisabled = Game.IsOption(GameOptionTypes.GAMEOPTION_NO_ESPIONAGE)
		g_isAlwaysWar = Game.IsOption( GameOptionTypes.GAMEOPTION_ALWAYS_WAR )
		g_isOneCityChallenge = Game.IsOption(GameOptionTypes.GAMEOPTION_ONE_CITY_CHALLENGE)
		g_isBasicHelp = IsCivBE or not OptionsManager.IsNoBasicHelp()
		Controls.UnitTooltipTimer:SetToBeginning()
		Controls.UnitTooltipTimer:SetPauseTime( GetTooltip2Seconds() / 100 )
		g_isCityStateLeaders = UserInterfaceSettings.CityStateLeaders ~= 0
	end
	Events.GameOptionsChanged.Add( UpdateOptions )
	UpdateOptions()
end

local g_PromotionIconIM = StackInstanceManager( "PromotionIcon", "Image", g_UnitTooltipControls.IconStack )

function cleanupTable( t )
	t[-1] = nil
	return t
end

local g_yieldString = cleanupTable{
	[YieldTypes.YIELD_FOOD or -1] = "TXT_KEY_BUILD_FOOD_STRING",
	[YieldTypes.YIELD_PRODUCTION or -1] = "TXT_KEY_BUILD_PRODUCTION_STRING",
	[YieldTypes.YIELD_GOLD or -1] = "TXT_KEY_BUILD_GOLD_STRING",
	[YieldTypes.YIELD_SCIENCE or -1] = "TXT_KEY_BUILD_SCIENCE_STRING",
	[YieldTypes.YIELD_CULTURE or -1] = "TXT_KEY_BUILD_CULTURE_STRING",
	[YieldTypes.YIELD_FAITH or -1] = "TXT_KEY_BUILD_FAITH_STRING",
}

local g_infoSource = cleanupTable{
	[ ActionSubTypes.ACTIONSUBTYPE_PROMOTION or -1 ] = GameInfo.UnitPromotions,
	[ ActionSubTypes.ACTIONSUBTYPE_INTERFACEMODE or -1 ] = GameInfo.InterfaceModes,
	[ ActionSubTypes.ACTIONSUBTYPE_MISSION or -1 ] = GameInfo.Missions,
	[ ActionSubTypes.ACTIONSUBTYPE_COMMAND or -1 ] = GameInfo.Commands,
	[ ActionSubTypes.ACTIONSUBTYPE_AUTOMATE or -1 ] = GameInfo.Automates,
	[ ActionSubTypes.ACTIONSUBTYPE_BUILD or -1 ] = GameInfo.Builds,
	[ ActionSubTypes.ACTIONSUBTYPE_CONTROL or -1 ] = GameInfo.Controls,
}

local g_cityFocusTooltips = cleanupTable{
	[CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE or -1] = L"TXT_KEY_CITYVIEW_FOCUS_BALANCED_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD or -1] = L"TXT_KEY_CITYVIEW_FOCUS_FOOD_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION or -1] = L"TXT_KEY_CITYVIEW_FOCUS_PROD_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD or -1] = L"TXT_KEY_CITYVIEW_FOCUS_GOLD_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE or -1] = L"TXT_KEY_CITYVIEW_FOCUS_RESEARCH_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE or -1] = L"TXT_KEY_CITYVIEW_FOCUS_CULTURE_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE or -1] = L"TXT_KEY_CITYVIEW_FOCUS_GREAT_PERSON_TEXT",
	[CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH or -1] = L"TXT_KEY_CITYVIEW_FOCUS_FAITH_TEXT",
}

local g_activityMissions = cleanupTable{
	--[ActivityTypes.ACTIVITY_AWAKE or -1] = nil,
	[ActivityTypes.ACTIVITY_HOLD or -1] = false, --GameInfo.Missions.MISSION_SKIP, -- only when moves left > 0
	--[ActivityTypes.ACTIVITY_SLEEP or -1] = GameInfo.Missions.MISSION_SLEEP, -- can be sleep or fortify
	[ActivityTypes.ACTIVITY_HEAL or -1] = GameInfo.Missions.MISSION_HEAL,
	[ActivityTypes.ACTIVITY_SENTRY or -1] = GameInfo.Missions.MISSION_ALERT,
	[ActivityTypes.ACTIVITY_INTERCEPT or -1] = GameInfo.Missions.MISSION_AIRPATROL,
	--[ActivityTypes.ACTIVITY_MISSION or -1] = GameInfo.Missions.MISSION_MOVE_TO,
}

local g_maximumAcquirePlotArea = (GameDefines.MAXIMUM_ACQUIRE_PLOT_DISTANCE+1) * GameDefines.MAXIMUM_ACQUIRE_PLOT_DISTANCE * 3
local g_maximumAcquirePlotPerimeter = GameDefines.MAXIMUM_ACQUIRE_PLOT_DISTANCE * 6

if Map.GetPlot(0,0).GetCityPurchaseID then
	CityPlots = function( city, m )
		local cityID = city:GetID()
		local cityOwnerID = city:GetOwner()
		if not m then m = 0 end
		local n = g_maximumAcquirePlotArea
		local p = g_maximumAcquirePlotPerimeter
		return function()
			repeat
				for i = m, n do
					local plot = city:GetCityIndexPlot( i )
					if plot	and plot:GetOwner() == cityOwnerID and plot:GetCityPurchaseID() == cityID then
						m = i+1
						return plot
					end
				end
				-- if no owned plots were found in previous ring then we're done
				if m <= n-p+1 then
					return
				end
				-- plots found, search next ring
				m = n + 1	--first plot of next ring
				p = p + 6	--perimeter of next ring
				n = n + p	--last plot of next ring
			until false
		end
	end
else
	CityPlots = function( city, i )
		if not i then i = 0 end
		return function()
			while i <= g_maximumAcquirePlotArea do
				local plot = city:GetCityIndexPlot( i )
				i = i+1
				if plot	and plot:GetWorkingCity() == city then
					return plot
				end
			end
		end
	end
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
local function ColorizeSigned( x )
	if x > 0 then
		return "[COLOR_POSITIVE_TEXT]+" .. x .. "[ENDCOLOR]"
	elseif x < 0 then
		return "[COLOR_WARNING_TEXT]" .. x .. "[ENDCOLOR]"
	else
		return "0"
	end
end
local function ColorizeAbs( x )
	if x > 0 then
		return "[COLOR_POSITIVE_TEXT]" .. x .. "[ENDCOLOR]"
	elseif x < 0 then
		return "[COLOR_WARNING_TEXT]" .. -x .. "[ENDCOLOR]"
	else
		return "0"
	end
end

local function append( t, text )
	t[#t] = t[#t] .. text
end

local function insertLocalizedIfNonZero( t, textKey, ... )
	if ... ~= 0 then
		return insert( t, L( textKey, ... ) )
	end
end

local function insertLocalizedBulletIfNonZero( t, a, b, ... )
	if tonumber( b ) then
		if b ~= 0 then
			return insert( t, "[ICON_BULLET]" .. L( a, b, ... ) )
		end
	elseif ... ~= 0 then
		return insert( t, a .. L( b, ... ) )
	end
end

local function GetItemPortraitIcon( GameInfoItems, itemID )
	local item = GameInfoItems and GameInfoItems[itemID]
	if item then
		return item.PortraitIndex or item.IconIndex, item.IconAtlas
	end
end

local function UnitColor( s )
	return "[COLOR_UNIT_TEXT]"..s.."[ENDCOLOR]"
end

local function BuildingColor( s )
	return "[COLOR_YIELD_FOOD]"..s.."[ENDCOLOR]"
end

local function PolicyColor( s )
	return "[COLOR_MAGENTA]"..s.."[ENDCOLOR]"
end

local function TechColor( s )
	return "[COLOR_CYAN]"..s.."[ENDCOLOR]"
end

local function ReligionColor( s )
	return "[COLOR_WHITE]"..s.."[ENDCOLOR]"
end

local function TooltipSelect( tooltipTable, control, ... )
	local tooltip = tooltipTable[ control:GetID() ]
	if tooltip then
		return tooltip( ... )
	end
end

local function ShowTextToolTipAndPicture( tip, index, altlas )
	local controls = g_ItemTooltipControls
	controls.Text:SetText( tip )
	controls.PortraitFrame:SetHide( not ( altlas and IconHookup( index, 256, altlas, controls.Portrait ) ) )
	controls.PortraitFrame:SetAnchor( GetMousePos() > 300 and "L,T" or "R,T" )
	controls.Box:DoAutoSize()
end
LuaEvents.ShowTextToolTipAndPicture.Add( ShowTextToolTipAndPicture )

local function ShowTextToolTip( ... )
	return ShowTextToolTipAndPicture( ... and concat( {...}, "[NEWLINE]----------------[NEWLINE]" ) )
end

--==========================================================
-- Resource Tooltip
--==========================================================

local function ShowResourceToolTip( resourceID, tips )
	local resource = GameInfo.Resources[ resourceID ]
	if resource then
		local activePlayerID = GetActivePlayer()
		local activeTeamID = GetActiveTeam()
		local activePlayer = Players[activePlayerID]
		local activeTeam = Teams[activeTeamID]
		local activeCivilizationID = activePlayer:GetCivilizationType()
		local activeCivilization = GameInfo.Civilizations[ activeCivilizationID ]
		local activeTeamTechs = activeTeam:GetTeamTechs()

		local resourceID = resource.ID
		local numResourceUsed = activePlayer:GetNumResourceUsed( resourceID )
		local numResourceAvailable = activePlayer:GetNumResourceAvailable( resourceID, true )	-- same as (total - used)
		local numResourceExport = activePlayer:GetResourceExport( resourceID )
		local numResourceImport = activePlayer:GetResourceImport( resourceID ) + activePlayer:GetResourceFromMinors( resourceID )
		local numResourceLocal = activePlayer:GetNumResourceTotal( resourceID, false ) + numResourceExport

--	if resourceID and GetResourceUsageType(resourceID) == RESOURCEUSAGE_STRATEGIC then

		insert( tips, ColorizeAbs(numResourceAvailable) .. resource.IconString .. " " .. Locale.ToUpper(resource._Name) )
		insert( tips, "----------------" )

		----------------------------
		-- Local Resources in Cities  Input
		----------------------------
		insert( tips, "" )
		insert( tips, Colorize(numResourceLocal) .. " " .. L"TXT_KEY_EO_LOCAL_RESOURCES" )

		-- Resources from city terrain
		for city in activePlayer:Cities() do
			local numConnectedResource = 0
			local numUnconnectedResource = 0
			for plot in CityPlots( city ) do
				local numResource = plot:GetNumResource()
				if numResource > 0  and resourceID == plot:GetResourceType( activeTeamID ) then
					if plot:IsCity() or (not plot:IsImprovementPillaged() and plot:IsResourceConnectedByImprovement( plot:GetImprovementType() )) then
						numConnectedResource = numConnectedResource + numResource
					else
						numUnconnectedResource = numUnconnectedResource + numResource
					end
				end
			end
			local tip = ""
			if numConnectedResource > 0 then
				tip = " " .. ColorizeAbs( numConnectedResource ) .. resource.IconString
			end
			if numUnconnectedResource > 0 then
				tip = tip .. " " .. ColorizeAbs( -numUnconnectedResource ) .. resource.IconString
			end
			if #tip > 0 then
				insert( tips, "[ICON_BULLET]" .. city:GetName() .. tip )
			end
		end
		if IsCiv5notVanilla then
			-- Resources from buildings
			local tipIndex = #tips
			for row in GameInfo.Building_ResourceQuantity{ ResourceType = resource.Type } do
				local building = GameInfo.Buildings[ row.BuildingType ]
				local numResource = row.Quantity
				if building and numResource and numResource > 0 then
					local buildingID = building.ID
					-- count how many such buildings player has
					local numExisting = activePlayer:CountNumBuildings( buildingID )
					-- count how many such units player is building
					local numBuilds = 0
					for city in activePlayer:Cities() do
						if city:GetProductionBuilding() == buildingID then
							numBuilds = numBuilds + 1
						end
					end
					-- can player build this building someday ?
					--[[
					local canBuildSomeday
					-- check whether this Unit has been blocked out by the civ XML
					local buildingOverride = GameInfo.Civilization_BuildingClassOverrides{ CivilizationType = activeCivilization.Type, BuildingClassType = building.BuildingClass }()
					if buildingOverride then
						canBuildSomeday = buildingOverride.BuildingType == building.Type
					else
						canBuildSomeday = GameInfo.BuildingClasses[ building.BuildingClass ].DefaultBuilding == building.Type
					end
					if canBuildSomeday and
						-- no espionage buildings for a non-espionage game
						( ( g_isEspionageDisabled and building.IsEspionage )
						-- is building obsolete by tech?
						or ( building.ObsoleteTech and activeTeamTechs:HasTech( GameInfoTypes[building.ObsoleteTech] ) ) )
					then
						canBuildSomeday = false
					end
					]]--
					if canBuildSomeday or numExisting > 0 or numBuilds > 0 then
						local totalResource = (numExisting + numBuilds) * numResource
						local tip = "[COLOR_YIELD_FOOD]" .. building._Name .. "[ENDCOLOR]"
						if canBuildSomeday then
							local tech = building.PrereqTech and GameInfo.Technologies[ building.PrereqTech ]
							if tech and not activeTeamTechs:HasTech( tech.ID ) then
								tip = tip .. " [COLOR_CYAN]" .. tech._Name .. "[ENDCOLOR]"
							end
							local policyBranch = building.PolicyBranchType and GameInfo.PolicyBranchTypes[ building.PolicyBranchType ]
							if policyBranch and not activePlayer:GetPolicyBranchChosen( policyBranch.ID ) then
								tip = tip .. " [COLOR_MAGENTA]" .. policyBranch._Name .. "[ENDCOLOR]"
							end
						end
						if totalResource > 0 then
							tipIndex = tipIndex+1
							-- insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  numExisting .. " (+" .. numBuilds .. ") " .. tip )
							-- insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  numExisting .. " x " .. perbuild .. " " .. tip )
							local perbuild = totalResource/numExisting
							insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  perbuild .. resource.IconString .. " x " .. numExisting .. " " .. tip )
						else
							insert( tips, "[ICON_BULLET] (" .. numResource .. "/" .. tip .. ")" )
						end
					end
				end
			end
		end
		----------------------------
		-- Import & Export Breakdown
		----------------------------

		-- Get specified resource traded with the active player

		local itemType, duration, finalTurn, data1, data2, data3, flag1, fromPlayerID
		local gameTurn = Game.GetGameTurn()-1
		local Exports = {}
		local Imports = {}
		for playerID = 0, MAX_MAJOR_CIVS-1 do
			Exports[ playerID ] = {}
			Imports[ playerID ] = {}
		end
		PushScratchDeal()
		for i = 0, UI.GetNumCurrentDeals( activePlayerID ) - 1 do
			UI.LoadCurrentDeal( activePlayerID, i )
			local otherPlayerID = ScratchDeal:GetOtherPlayer( activePlayerID )
			ScratchDeal:ResetIterator()
			repeat
				if IsCiv5BNW_BE then
					itemType, duration, finalTurn, data1, data2, data3, flag1, fromPlayerID = ScratchDeal:GetNextItem()
				else
					itemType, duration, finalTurn, data1, data2, fromPlayerID = ScratchDeal:GetNextItem()
				end
				-- data1 is resourceID, data2 is quantity

				if itemType == TRADE_ITEM_RESOURCES and data1 == resourceID and data2 then
					if fromPlayerID == activePlayerID then
						Exports[otherPlayerID][finalTurn] = (Exports[otherPlayerID][finalTurn] or 0) + data2
					else
						Imports[fromPlayerID][finalTurn] = (Imports[fromPlayerID][finalTurn] or 0) + data2
					end
				end
			until not itemType
		end
		PopScratchDeal()

		----------------------------
		-- Resource Imports
		----------------------------
		if numResourceImport > 0 then
			insert( tips, "" )
			insert( tips, Colorize(numResourceImport) .. " " .. L"TXT_KEY_RESOURCES_IMPORTED" )
			for playerID, row in pairs( Imports ) do
				local tip = ""
				for turn, quantity in pairs( row ) do
					if quantity > 0 then
						tip = tip .. " " .. quantity .. resource.IconString .. "(" .. turn - gameTurn .. ")"
					end
				end
				if #tip > 0 then
					insert( tips, "[ICON_BULLET]" .. Players[ playerID ]:GetCivilizationShortDescription() .. tip )
				end
			end
			for minorID = MAX_MAJOR_CIVS, MAX_CIV_PLAYERS_minus1 do
				local minor = Players[ minorID ]
				if minor and minor:IsAlive() and minor:GetAlly() == activePlayerID then
					local quantity = minor:GetResourceExport(resourceID)
					if quantity > 0 then
						insert( tips, "[ICON_BULLET]" .. minor:GetCivilizationShortDescription() .. " " .. quantity .. resource.IconString )
					end
				end
			end
		end
		----------------------------
		-- Resource Exports
		----------------------------
		if numResourceExport > 0 then
			insert( tips, "" )
			insert( tips, Colorize(-numResourceExport) .. " " .. L"TXT_KEY_RESOURCES_EXPORTED" )
			for playerID, row in pairs( Exports ) do
				local tip = ""
				for turn, quantity in pairs( row ) do
					if quantity > 0 then
						tip = tip .. " " .. quantity .. resource.IconString .. "(" .. turn - gameTurn .. ")"
					end
				end
				if #tip > 0 then
					insert( tips, "[ICON_BULLET]" .. Players[ playerID ]:GetCivilizationShortDescription() .. tip )
				end
			end
		end

		----------------------------
		-- Resource Usage Breakdown  /Output
		----------------------------
		insert( tips, "" )
		insert( tips, (numResourceUsed~=0 and (Colorize(-numResourceUsed) .. " ") or"") .. L"TXT_KEY_PEDIA_REQ_RESRC_LABEL" )
		local tipIndex = #tips

		for unit in GameInfo.Units() do
			local unitID = unit.ID
			local numResource = Game.GetNumResourceRequiredForUnit( unitID, resourceID )
			if numResource > 0 then
				-- count how many such units player has
				local numExisting = 0
				for unit in activePlayer:Units() do
					if unit:GetUnitType() == unitID then
						numExisting = numExisting + 1
					end
				end
				-- count how many such units player is building
				local numBuilds = 0
				for city in activePlayer:Cities() do
					for i=0, city:GetOrderQueueLength()-1 do
						local queuedOrderType, queuedItemType = city:GetOrderFromQueue( i )
						if queuedOrderType == ORDER_TRAIN and queuedItemType == unitID then
							numBuilds = numBuilds + 1
						end
					end
				end
				-- can player build this unit someday ?
				--[[
				local canBuildSomeday = true
				if IsCiv5BNW_BE then
					-- does player trait prohibits training this unit ?
					local leader = GameInfo.Leaders[ activePlayer:GetLeaderType() ]
					for leaderTrait in GameInfo.Leader_Traits{ LeaderType = leader.Type } do
						if GameInfo.Trait_NoTrain{ UnitClassType = unit.Class, TraitType = leaderTrait.TraitType }() then
							canBuildSomeday = false
							break
						end
					end
				end
				if canBuildSomeday then
					-- check whether this Unit has been blocked out by the civ XML unit override
					local unitOverride = GameInfo.Civilization_UnitClassOverrides{ CivilizationType = activeCivilization.Type, UnitClassType = unit.Class }()
					if unitOverride then
						canBuildSomeday = unitOverride.UnitType == unit.Type
					else
						canBuildSomeday = GameInfo.UnitClasses[ unit.Class ].DefaultUnit == unit.Type
					end
				end
				canBuildSomeday = canBuildSomeday and not (
					-- one City Challenge?
					( g_isOneCityChallenge and (unit.Found or unit.FoundAbroad) )
					-- Faith Requirements?
					or ( g_isReligionEnabled and (unit.FoundReligion or unit.SpreadReligion or unit.RemoveHeresy) )
					-- obsolete by tech?
					or ( unit.ObsoleteTech and activeTeamTechs:HasTech( GameInfoTypes[unit.ObsoleteTech] ) )
				)
				]]--
				if canBuildSomeday or numExisting > 0 or numBuilds > 0 then
					local totalResource = (numExisting + numBuilds) * numResource
					local tip = "[COLOR_YELLOW]" .. unit._Name .. "[ENDCOLOR]"
					if canBuildSomeday then
						-- Tech requirements
						local tech = unit.PrereqTech and GameInfo.Technologies[ unit.PrereqTech ]
						if tech and not activeTeamTechs:HasTech( tech.ID ) then
							tip = format( "%s [COLOR_CYAN]%s[ENDCOLOR]", tip, tech._Name )
						end
						-- Policy Requirement
						local policy = IsCiv5BNW and unit.PolicyType and GameInfo.Policies[ unit.PolicyType ]
						if policy and not activePlayer:HasPolicy( policy.ID ) then
							tip = format( "%s [COLOR_MAGENTA]%s[ENDCOLOR]", tip, policy._Name )
						end
						if IsCivBE then
							-- Affinity Level Requirements
							for affinityPrereq in GameInfo.Unit_AffinityPrereqs{ UnitType = unit.Type } do
								local affinityInfo = (tonumber( affinityPrereq.Level) or 0 ) > 0 and GameInfo.Affinity_Types[ affinityPrereq.AffinityType ]
								if affinityInfo and activePlayer:GetAffinityLevel( affinityInfo.ID ) < affinityPrereq.Level then
									tip = format("%s [%s]%i%s%s[ENDCOLOR]", tip, affinityInfo.ColorType, affinityPrereq.Level, affinityInfo.IconString or "???", affinityInfo._Name )
								end
							end
						end
					end
					if totalResource > 0 then
						tipIndex = tipIndex+1
						--insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  numExisting .. " (+" .. numBuilds .. ") " .. tip )
						local perbuild = totalResource/numExisting
						insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  perbuild .. resource.IconString .. " x " .. numExisting .. " " .. tip )
					else
						insert( tips, "[ICON_BULLET] (" .. numResource .. "/" .. tip .. ")" )
					end
				end
			end
		end
		for building in GameInfo.Buildings() do
			local buildingID = building.ID
			local numResource = Game.GetNumResourceRequiredForBuilding( buildingID, resourceID )
			if numResource > 0 then
				-- count how many such buildings player has
				local numExisting = activePlayer:CountNumBuildings( buildingID )
				-- count how many such units player is building
				local numBuilds = 0
				for city in activePlayer:Cities() do
					for i=0, city:GetOrderQueueLength()-1 do
						local queuedOrderType, queuedItemType = city:GetOrderFromQueue( i )
						if queuedOrderType == ORDER_CONSTRUCT and queuedItemType == buildingID then
							numBuilds = numBuilds + 1
						end
					end
				end
				-- can player build this building someday ?
				--[[
				local canBuildSomeday
				-- check whether this Unit has been blocked out by the civ XML
				local buildingOverride = GameInfo.Civilization_BuildingClassOverrides{ CivilizationType = activeCivilization.Type, BuildingClassType = building.BuildingClass }()
				if buildingOverride then
					canBuildSomeday = buildingOverride.BuildingType == building.Type
				else
					canBuildSomeday = GameInfo.BuildingClasses[ building.BuildingClass ].DefaultBuilding == building.Type
				end
				canBuildSomeday = canBuildSomeday and not (
					-- no espionage buildings for a non-espionage game
					( g_isEspionageDisabled and building.IsEspionage )
					-- Has obsolete tech?
					or ( IsCiv5 and building.ObsoleteTech and activeTeamTechs:HasTech( GameInfoTypes[building.ObsoleteTech] ) )
				)
				]]--
				if canBuildSomeday or numExisting > 0 or numBuilds > 0 then
					local totalResource = (numExisting + numBuilds) * numResource
					local tip = "[COLOR_YIELD_FOOD]" .. building._Name .. "[ENDCOLOR]"
					if canBuildSomeday then
						local tech = GameInfo.Technologies[ building.PrereqTech ]
						if tech and not activeTeamTechs:HasTech( tech.ID ) then
							tip = format( "%s [COLOR_CYAN]%s[ENDCOLOR]", tip, tech._Name )
						end
						local policyBranch = IsCiv5BNW and building.PolicyBranchType and GameInfo.PolicyBranchTypes[ building.PolicyBranchType ]
						if policyBranch and not activePlayer:GetPolicyBranchChosen( policyBranch.ID ) then
							tip = format( "%s [COLOR_MAGENTA]%s[ENDCOLOR]", tip, policyBranch._Name )
						end
						if IsCivBE then
							-- Affinity Level Requirements
							for affinityPrereq in GameInfo.Building_AffinityPrereqs{ BuildingType = building.Type } do
								local affinityInfo = (tonumber( affinityPrereq.Level) or 0 ) > 0 and GameInfo.Affinity_Types[ affinityPrereq.AffinityType ]
								if affinityInfo and activePlayer:GetAffinityLevel( affinityInfo.ID ) < affinityPrereq.Level then
									tip = format("%s [%s]%i%s%s[ENDCOLOR]", tip, affinityInfo.ColorType, affinityPrereq.Level, affinityInfo.IconString or "???", affinityInfo._Name )
								end
							end
						end
					end
					if totalResource > 0 then
						tipIndex = tipIndex+1						
						--insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  numExisting .. " (+" .. numBuilds .. ") " .. tip )
						local perbuild = totalResource/numExisting
						insert( tips, tipIndex, "[ICON_BULLET]" .. totalResource .. resource.IconString .. " = " ..  perbuild .. resource.IconString .. " x " .. numExisting .. " " .. tip )
					else
						insert( tips, "[ICON_BULLET] (" .. numResource .. "/" .. tip .. ")" )
					end
				end
			end
		end
		local resourceHappiness = resource.Happiness or 0
		if resourceHappiness > 0 then
			insert( tips, resourceHappiness .. "[ICON_HAPPINESS_1]" )
		end
		for city in activePlayer:Cities() do
			if city:GetResourceDemanded() == resourceID and city:GetWeLoveTheKingDayCounter() < 1 then
				insert( tips, "[ICON_CITIZEN] " .. city:GetName() )
			end
		end
		for minorPlayerID = MAX_MAJOR_CIVS, MAX_CIV_PLAYERS_minus1 do
			local minorPlayer = Players[minorPlayerID]
			if ( IsCiv5notVanilla or minorPlayer:GetActiveQuestForPlayer()==MINOR_CIV_QUEST_CONNECT_RESOURCE ) and minorPlayer:GetQuestData1(activePlayerID, MINOR_CIV_QUEST_CONNECT_RESOURCE) == resourceID then
				insert( tips, "[ICON_CITY_STATE] " .. minorPlayer:GetCivilizationShortDescription() )
			end
		end
		----------------------------
		-- Available for Import
		----------------------------
		local tipIndex = #tips
		local totalResource = 0
		for playerID = 0, MAX_CIV_PLAYERS_minus1 do

			local player = Players[playerID]
			local isMinorCiv = player:IsMinorCiv()

			-- Valid player? - Can't be us, has to be alive, and has to be met
			if playerID ~= activePlayerID
				and player:IsAlive()
				and activeTeam:IsHasMet( player:GetTeam() )
				and not (isMinorCiv and player:IsAllies(activePlayerID))
			then
				local numResource = ( isMinorCiv and player:GetNumResourceTotal(resourceID, false) + player:GetResourceExport( resourceID ) )
					or ( ScratchDeal:IsPossibleToTradeItem(playerID, activePlayerID, TRADE_ITEM_RESOURCES, resourceID, 1) and player:GetNumResourceAvailable(resourceID, false) ) or 0
				if numResource > 0 then
					totalResource = totalResource + numResource
					insert( tips, "[ICON_BULLET]" .. player:GetCivilizationShortDescription() .. " " .. numResource .. resource.IconString )
				end
			end
		end
		if totalResource > 0 then
			insert( tips, tipIndex+1, "" )
			insert( tips, tipIndex+2, "----------------")
			insert( tips, tipIndex+3, totalResource .. " " .. L"TXT_KEY_EO_RESOURCES_AVAILBLE" )
		end
		return ShowTextToolTipAndPicture( concat( tips, "[NEWLINE]" ), resource.PortraitIndex, resource.IconAtlas )
	end
end

LuaEvents.ResourceToolTip.Add( function( control )
	ShowResourceToolTip( control:GetVoid1(), {} )
end)

--==========================================================
-- Civilization Tooltips
--==========================================================
do

local function ShowCivilizationToolTip( toolTip, playerID )
	g_CivilizationTooltipControls.Text:SetText( toolTip )
	g_CivilizationTooltipControls.Box:DoAutoSize()
	local isMinorCiv, isMajorCiv
	local player = Players[ playerID ]
	if player then
		if player:IsMinorCiv() then
			local minorCivInfo = GameInfo.MinorCivilizations[ player:GetMinorCivType() ]
			if minorCivInfo and g_isCityStateLeaders then
				if Locale.HasTextKey( "TXT_KEY_CSL_ICON_"..minorCivInfo.Type ) then
--					g_CivilizationTooltipControls.Leader:SetTextureSizeVal( 200, 200 )
--					g_CivilizationTooltipControls.Leader:SetTextureOffsetVal( 0, 0 )
					isMinorCiv = g_CivilizationTooltipControls.Leader:SetTexture( L("TXT_KEY_CSL_ICON_"..minorCivInfo.Type) )
--[[
				else
					local row = GameInfo.Civilization_CityNames{ CityName = "TXT_KEY_CITY_NAME"..minorCivInfo.Type:sub(10,99) }()
--print( minorCivInfo.Type, row and row.CityName )
					local leader = row and GameInfo.Civilization_Leaders{ CivilizationType = row.CivilizationType }()
					leader = leader and GameInfo.Leaders[ leader.LeaderheadType ]
--print( minorCivInfo.Type, leader and leader.Type )
					if leader then
						g_CivilizationTooltipControls.Leader:SetTextureSizeVal( 254, 254 )
						isMinorCiv = IconHookup( leader.PortraitIndex, 256, leader.IconAtlas, g_CivilizationTooltipControls.Leader )
					end
--]]
				end
			end
		else
			local leader = GameInfo.Leaders[ player:GetLeaderType() ]
			isMajorCiv = leader and IconHookup( leader.PortraitIndex, g_CivilizationTooltipControls.Portrait:GetSizeY(), leader.IconAtlas, g_CivilizationTooltipControls.Portrait )
			CivIconHookup( playerID, g_CivilizationTooltipControls.CivIconBG:GetSizeY(), g_CivilizationTooltipControls.CivIcon, g_CivilizationTooltipControls.CivIconBG, g_CivilizationTooltipControls.CivIconShadow, false, true )
		end
	end
	g_CivilizationTooltipControls.MajorCiv:SetHide( not isMajorCiv )
	g_CivilizationTooltipControls.MinorCiv:SetHide( not isMinorCiv )
end

local function TooltipWithRemainingTurns( toolTip, remainingTurns )
	toolTip = L( toolTip )
	if remainingTurns and remainingTurns > 0 then
		toolTip = toolTip .. " (" .. L( "TXT_KEY_STR_TURNS", remainingTurns ) .. ")"
	end
	return toolTip
end

local function TooltipAndGetRemainingTurns( toolTip, tradeableItemID, fromPlayerID, toPlayerID )
	PushScratchDeal()
	local activePlayerID = GetActivePlayer()
	for i = 0, UI.GetNumCurrentDeals( activePlayerID ) - 1 do
		UI.LoadCurrentDeal( activePlayerID, i )
		if not toPlayerID or toPlayerID == activePlayerID or toPlayerID == ScratchDeal:GetOtherPlayer( activePlayerID ) then
			ScratchDeal:ResetIterator()
			local itemID
			repeat
				local item = { ScratchDeal:GetNextItem() }
				itemID = item[1]
				if itemID == tradeableItemID and item[#item] == fromPlayerID then
					PopScratchDeal()
					return TooltipWithRemainingTurns( toolTip, item[3] - Game.GetGameTurn() + 1 )
				end
			until not itemID
		end
	end
	PopScratchDeal()
	return L(toolTip)
end

local function Pledge( playerID )
	local player = Players[ playerID ]
	local toolTip = L"TXT_KEY_POP_CSTATE_PLEDGE_TO_PROTECT"
	if player and player.CanMajorWithdrawProtection then
		toolTip = L( "TXT_KEY_NOTIFICATION_SUMMARY_QUEST_COMPLETE_PLEDGE_TO_PROTECT", player:GetCivilizationShortDescriptionKey() )
		if player:CanMajorWithdrawProtection( GetActivePlayer() ) then
			toolTip = toolTip .. "[NEWLINE][NEWLINE]" .. L"TXT_KEY_POP_CSTATE_REVOKE_PROTECTION_TT"
		else
			toolTip = toolTip .. L("TXT_KEY_POP_CSTATE_REVOKE_PROTECTION_DISABLED_COMMITTED_TT", player:GetTurnLastPledgedProtectionByMajor( GetActivePlayer() ) + 10 - Game.GetGameTurn() )
		end
	end
	return toolTip
end

local CivilizationToolTips = { 

	Button = function( playerID )
		local player = Players[ playerID ]
		if player:IsMinorCiv() then
			return GetCityStateStatusToolTip( GetActivePlayer(), playerID, true )
		else
			return GetMoodInfo( playerID, true )
		end
	end;

	Quests = function( playerID )
		return GetActiveQuestToolTip( GetActivePlayer(), playerID )
	end;

	Ally = function( playerID )
		return GetAllyToolTip( GetActivePlayer(), playerID )
	end;

	Pledge1 = Pledge,
	Pledge2 = Pledge,

	Spy = function( playerID )
		local player = Players[ playerID ]
		local activePlayer = Players[ GetActivePlayer() ]
		if player and activePlayer then
			local spy
			for _, s in ipairs( activePlayer:GetEspionageSpies() ) do
				local plot = GetPlot( s.CityX, s.CityY )
				local city = plot and plot:GetPlotCity()
				if city and city:GetOwner() == playerID then
					spy = s
					break
				end
			end
			if spy then
				return L( "TXT_KEY_CITY_SPY_CITY_STATE_TT", spy.Rank, spy.Name, player:GetCivilizationShortDescriptionKey(), spy.Rank, spy.Name)
			end
		end
	end;

	DeclarationOfFriendship = function( playerID )
		local toolTipKey = "TXT_KEY_DIPLOMACY_FRIENDSHIP_ADV_QUEST"
		local activePlayer = Players[ GetActivePlayer() ]
		if activePlayer and activePlayer.GetDoFCounter then
			return TooltipWithRemainingTurns( toolTipKey, DOF_EXPIRATION_TIME - activePlayer:GetDoFCounter( playerID ) )
		else
			return L(toolTipKey)
		end
	end;

	ResearchAgreement = function( playerID )
		return TooltipAndGetRemainingTurns( "TXT_KEY_DO_RESEARCH_AGREEMENT", TradeableItems.TRADE_ITEM_RESEARCH_AGREEMENT, playerID )
	end;

	DefenseAgreement = function( playerID )
		return TooltipAndGetRemainingTurns( "TXT_KEY_DO_PACT", TradeableItems.TRADE_ITEM_DEFENSIVE_PACT, playerID )
	end;

	TheirBordersClosed = function()
		return L"TXT_KEY_EUI_CLOSED_BORDERS_THEIR"	--( "Their borders are closed" )
	end;

	OurBordersClosed = function()
		return L"TXT_KEY_EUI_CLOSED_BORDERS_YOUR"	--( "Your borders are closed" )
	end;

	TheirBordersOpen = function( playerID )
		local toolTip = "TXT_KEY_EUI_OPEN_BORDERS_THEIR"
		if not Locale.HasTextKey( toolTip ) then
			toolTip = L( "TXT_KEY_DO_THEY_PROVIDE", "TXT_KEY_DO_OPEN_BORDERS" )
		end
		return TooltipAndGetRemainingTurns( toolTip, TradeableItems.TRADE_ITEM_OPEN_BORDERS, playerID )
	end;

	OurBordersOpen = function( playerID )
		local toolTip = "TXT_KEY_EUI_OPEN_BORDERS_YOUR"
		if not Locale.HasTextKey( toolTip ) then
			toolTip = L( "TXT_KEY_DO_WE_PROVIDE", "TXT_KEY_DO_OPEN_BORDERS" )
		end
		return TooltipAndGetRemainingTurns( toolTip, TradeableItems.TRADE_ITEM_OPEN_BORDERS, GetActivePlayer(), playerID )
	end;

	ActivePlayer = function()
		return L"TXT_KEY_YOU"
	end;

	War = function( playerID )
		local player = Players[ playerID ]
		local activeTeam = Teams[ GetActiveTeam() ]
		if player and activeTeam then
			local tips = { L( "TXT_KEY_AT_WAR_WITH", player:GetCivilizationShortDescriptionKey() ) }
			local teamID = player:GetTeam()
			local lockedWarTurns = activeTeam:GetNumTurnsLockedIntoWar( teamID )
			if lockedWarTurns > 0 then
				insert( tips, L( "TXT_KEY_DIPLO_NEGOTIATE_PEACE_BLOCKED_TT", lockedWarTurns ) )
			elseif not activeTeam:CanChangeWarPeace( teamID ) then
				insert( tips, L"TXT_KEY_PEACE_BLOCKED" )
			end
-- todo TradeableItems.TRADE_ITEM_THIRD_PARTY_WAR & permanent war
			return concat( tips, "[NEWLINE]" )
		end
	end;

	Score = function( playerID )
		local player = Players[ playerID ]
		if player then
			local tips = { L"TXT_KEY_POP_SCORE" .. " " .. player:GetScore(),	--TXT_KEY_VP_SCORE
						"----------------",
						L("TXT_KEY_DIPLO_MY_SCORE_CITIES", player:GetScoreFromCities() ),
						L("TXT_KEY_DIPLO_MY_SCORE_POPULATION", player:GetScoreFromPopulation() ),
						L("TXT_KEY_DIPLO_MY_SCORE_LAND", player:GetScoreFromLand() ),
						L("TXT_KEY_DIPLO_MY_SCORE_WONDERS", player:GetScoreFromWonders() ) }
			if g_isScienceEnabled then
				insert( tips, L("TXT_KEY_DIPLO_MY_SCORE_TECH", player:GetScoreFromTechs() ) )
				insert( tips, L("TXT_KEY_DIPLO_MY_SCORE_FUTURE_TECH", player:GetScoreFromFutureTech() ) )
			end
			if g_isReligionEnabled then
				insert( tips, L("TXT_KEY_DIPLO_MY_SCORE_RELIGION", player:GetScoreFromReligion() ) )
			end
			if g_isPoliciesEnabled and player.GetScoreFromPolicies then
				insert( tips, L("TXT_KEY_DIPLO_MY_SCORE_POLICIES", player:GetScoreFromPolicies() ) )
			end
			if player.GetScoreFromGreatWorks then
				insert( tips, L("TXT_KEY_DIPLO_MY_SCORE_GREAT_WORKS", player:GetScoreFromGreatWorks() ) )
			end
			if PreGame.GetLoadWBScenario() then
				for i = 1, 4 do
					local key = "TXT_KEY_DIPLO_MY_SCORE_SCENARIO"..i
					if Locale.HasTextKey( key ) then
						insert( tips, L( key, player["GetScoreFromScenario"..i](player) ) )
					end
				end
			end
			return concat( tips, "[NEWLINE]" )
		end
	end;

	Gold = function( playerID )
		local player = Players[ playerID ]
		if player then
			local team = Teams[ player:GetTeam() ]
			if team and team:IsAtWar( GetActiveTeam() ) then
				return L"TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_WAR"
			elseif not player.IsDoF or player:IsDoF( GetActivePlayer() ) then
				return L"TXT_KEY_REPLAY_DATA_TOTALGOLD"
			else
				return L"TXT_KEY_REPLAY_DATA_GOLDPERTURN"
			end
		end
	end;

	TheirTradeItems = function( playerID )
		local player = Players[ playerID ]
		if player then
			-- Resources available from them
			local activePlayerID = GetActivePlayer()
			local tips = { L( "TXT_KEY_DIPLO_ITEMS_LABEL", player:GetCivilizationAdjective() ) }
			for usage = RESOURCEUSAGE_LUXURY, RESOURCEUSAGE_STRATEGIC, RESOURCEUSAGE_STRATEGIC - RESOURCEUSAGE_LUXURY do
				for resource in GameInfo.Resources{ ResourceUsage = usage } do
					-- IsPossibleToTradeItem includes check on min quantity, banned luxes and obsolete strategics
					if ScratchDeal:IsPossibleToTradeItem( playerID, activePlayerID, TRADE_ITEM_RESOURCES, resource.ID, 1 ) then
						local a, b = player:GetNumResourceAvailable( resource.ID, true ), player:GetNumResourceAvailable( resource.ID )
						insert( tips, format( a == b and "%i%s%s" or "%i%s%s (%i)", a, resource.IconString, resource._Name, b ) )
					end
				end
			end
			return concat( tips, "[NEWLINE]" )
		end
	end;

	OurTradeItems = function( playerID )
		local player = Players[ playerID ]
		if player then
			local activePlayerID = GetActivePlayer()
			local activePlayer = Players[ activePlayerID ]
			local tips = { L"TXT_KEY_DIPLO_YOUR_ITEMS_LABEL" }
			-- Resources available from us
			for usage = RESOURCEUSAGE_LUXURY, RESOURCEUSAGE_STRATEGIC, RESOURCEUSAGE_STRATEGIC - RESOURCEUSAGE_LUXURY do
				for resource in GameInfo.Resources{ ResourceUsage = usage } do
					-- IsPossibleToTradeItem includes check on min quantity, banned luxes and obsolete strategics
					if ScratchDeal:IsPossibleToTradeItem( activePlayerID, playerID, TRADE_ITEM_RESOURCES, resource.ID, 1 )
						and player:GetNumResourceAvailable( resource.ID, true ) <= player:GetNumCities() -- game limit on AI trading of strategics; no effect on luxes
					then
						local a, b = activePlayer:GetNumResourceAvailable( resource.ID, true ), activePlayer:GetNumResourceAvailable( resource.ID )
						insert( tips, format( a == b and "%i%s%s" or "%i%s%s (%i)", a, resource.IconString, resource._Name, b ) )
					end
				end
			end
			return concat( tips, "[NEWLINE]" ), activePlayerID
		end
	end;

	Host = function()
		return L"TXT_KEY_HOST"
	end;

	Connection = function( playerID )
		local player = Players[ playerID ]
		if player then
			local toolTip
			if Network.IsPlayerHotJoining(playerID) then
				toolTip = L"TXT_KEY_MP_PLAYER_CONNECTING"
			elseif player:IsConnected() then
				toolTip = L"TXT_KEY_MP_PLAYER_CONNECTED"
			else
				toolTip = L"TXT_KEY_MP_PLAYER_NOTCONNECTED"
			end
			if Matchmaking.GetHostID() == playerID then
				toolTip = L"TXT_KEY_HOST" .. ", "..toolTip
			end
			local playerInfo
			local ping = ""
			if playerID == GetActivePlayer() then
				playerInfo = Network.GetLocalTurnSliceInfo()
			else
				playerInfo = Network.GetPlayerTurnSliceInfo( playerID )
			end
			if PreGame.IsInternetGame() then
				ping = Network.GetPingTime( playerID )
				if ping < 0 then
					ping = ""
				elseif ping == 0 then
					ping= L"TXT_KEY_STAGING_ROOM_UNDER_1_MS"
				elseif ping < 1000 then
					ping = ping .. L"TXT_KEY_STAGING_ROOM_TIME_MS"
				else
					ping = ("%.2f"):format( ping / 1000) .. L"TXT_KEY_STAGING_ROOM_TIME_S"
				end
				if ping>"" then
					ping = L"TXT_KEY_ACTION_PING".." "..ping.." "
				end
			end
			return toolTip .. "[NEWLINE][NEWLINE]"..ping.."Network turn slice: "
				.. playerInfo.Shortest .. " ("
				.. playerInfo.Average .. ") "
				.. playerInfo.Longest
		end
	end;

	Diplomacy = function( playerID )
		if UI.ProposedDealExists( playerID, GetActivePlayer() ) then
			return L"TXT_KEY_DIPLO_REQUEST_INCOMING"
		elseif UI.ProposedDealExists( GetActivePlayer(), playerID ) then
			return L"TXT_KEY_DIPLO_REQUEST_OUTGOING"
		end
	end;
}-- /CivilizationToolTips

LuaEvents.CivilizationToolTips.Add( function( control, playerID )
	local toolTip, ID = TooltipSelect( CivilizationToolTips, control, playerID )
	ShowCivilizationToolTip( toolTip, ID or playerID )
end)

end

--==========================================================
-- Unit Action Tooltip
--==========================================================
LuaEvents.UnitActionToolTip.Add( function( button )

	local activePlayerID = GetActivePlayer()
	local activePlayer = Players[ activePlayerID ]
	local activeTeamID = GetActiveTeam()
	local activeTeam = Teams[ activeTeamID ]
	local unit = GetHeadSelectedUnit()
	local actionID = button:GetVoid1()
	local action = GameInfoActions[actionID]

	if unit and activePlayer and activeTeam and action then
		local activeTechs = activeTeam:GetTeamTechs()
		local actionType = action.Type

		local unitPlot = unit:GetPlot()
		local x = unit:GetX()
		local y = unit:GetY()

		if actionType == "MISSION_FOUND" then
			g_UnitActionTooltipControls.UnitActionIcon:SetTextureOffsetVal( 0, 0 )
			g_UnitActionTooltipControls.UnitActionIcon:SetTexture( "BuildCity64.dds" )
		else
			local info = g_infoSource[ action.SubType ]
			info = info and info[ actionType ]
			if info then
				IconHookup( info.IconIndex or info.PortraitIndex, 64, info.IconAtlas, g_UnitActionTooltipControls.UnitActionIcon )
			end
		end

		-- Able to perform action
		local gameCanHandleAction = Game.CanHandleAction( actionID, unitPlot, false )

		-- Build data
		local isBuild = action.SubType == ACTIONSUBTYPE_BUILD
		local buildID = action.MissionData
		local build = GameInfo.Builds[ buildID ]

		-- Improvement data
		local improvement = build and GameInfo.Improvements[ build.ImprovementType ]
		local improvementID = improvement and improvement.ID

		-- Feature data
		local featureID = unitPlot:GetFeatureType()
		local feature = GameInfo.Features[ featureID ]

		-- Route data
		local route = build and GameInfo.Routes[ build.RouteType ]

		local strBuildTurnsString = ""
		local toolTip = {}
		local disabledTip = {}

		-- Upgrade unit
		if actionType == "COMMAND_UPGRADE" then

			local upgradeUnitTypeID = unit:GetUpgradeUnitType()
			local unitUpgradePrice = unit:UpgradePrice(upgradeUnitTypeID)
			local unitUpgradeInfo = GameInfo.Units[upgradeUnitTypeID]

			if unitUpgradeInfo then
				insert( toolTip, L( "TXT_KEY_UPGRADE_HELP", UnitColor( unitUpgradeInfo._Name ), unitUpgradePrice ) )
				insert( toolTip, "----------------" )
				insert( toolTip, GetHelpTextForUnit( upgradeUnitTypeID, true ) )
			end

			if not gameCanHandleAction then
				insert( toolTip, "----------------" )

				-- Can't upgrade because we're outside our territory
				if unitPlot:GetOwner() ~= unit:GetOwner() then
					insert( disabledTip, L"TXT_KEY_UPGRADE_HELP_DISABLED_TERRITORY" )
				end

				-- Can't upgrade because we're outside of a city
				if unit:GetDomainType() == DomainTypes.DOMAIN_AIR and not unitPlot:IsCity() then
					insert( disabledTip, L"TXT_KEY_UPGRADE_HELP_DISABLED_CITY" )
				end

				-- Can't upgrade because we lack the Gold
				if unitUpgradePrice > activePlayer:GetGold() then
					insert( disabledTip, L"TXT_KEY_UPGRADE_HELP_DISABLED_GOLD" )
				end

				-- Can't upgrade because we lack the Resources
				local resourcesNeeded = {}
				for resource in GameInfo.Resources() do
					local numResourceNeededToUpgrade = unit:GetNumResourceNeededToUpgrade(resource.ID)
					if numResourceNeededToUpgrade > 0 and numResourceNeededToUpgrade > activePlayer:GetNumResourceAvailable(resource.ID) then
						insert( resourcesNeeded, numResourceNeededToUpgrade .. " " .. resource.IconString .. " " .. resource._Name )
					end
				end
				if #resourcesNeeded > 0 then
					insert( disabledTip, L( "TXT_KEY_UPGRADE_HELP_DISABLED_RESOURCES", concat( resourcesNeeded, ", " ) ) )
				end

				-- if we can't upgrade due to stacking
				if unitPlot:GetNumFriendlyUnitsOfType(unit) > 1 then
					insert( disabledTip, L"TXT_KEY_UPGRADE_HELP_DISABLED_STACKING" )
				end
			end

		elseif actionType == "MISSION_ALERT" and not unit:IsEverFortifyable() then

			insert( toolTip, L"TXT_KEY_MISSION_ALERT_NO_FORTIFY_HELP" )

		-- Golden Age
		elseif actionType == "MISSION_GOLDEN_AGE" then

			insert( toolTip, L(  "TXT_KEY_MISSION_START_GOLDENAGE_HELP", unit:GetGoldenAgeTurns() ) )

		-- Spread Religion -- gk+ only
		elseif actionType == "MISSION_SPREAD_RELIGION" then

			local eMajorityReligion = unit:GetMajorityReligionAfterSpread()
			insert( toolTip, L"TXT_KEY_MISSION_SPREAD_RELIGION_HELP" )
			insert( toolTip, "----------------" )
			insert( toolTip, L("TXT_KEY_MISSION_SPREAD_RELIGION_RESULT", Game.GetReligionName(unit:GetReligion()), unit:GetNumFollowersAfterSpread() ) .. " " ..
					( eMajorityReligion < RELIGION_PANTHEON and L"TXT_KEY_MISSION_MAJORITY_RELIGION_NONE" or L("TXT_KEY_MISSION_MAJORITY_RELIGION", Game.GetReligionName(eMajorityReligion) ) ) )

		-- Create Great Work -- bnw only
		elseif actionType == "MISSION_CREATE_GREAT_WORK" then

			insert( toolTip, L"TXT_KEY_MISSION_CREATE_GREAT_WORK_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				local eGreatWorkSlotType = unit:GetGreatWorkSlotType()
				local building = GameInfo.Buildings[ activePlayer:GetBuildingOfClosestGreatWorkSlot(x, y, eGreatWorkSlotType) ]
				local city = activePlayer:GetCityOfClosestGreatWorkSlot(x, y, eGreatWorkSlotType)
				insert( toolTip, L( "TXT_KEY_MISSION_CREATE_GREAT_WORK_RESULT", building and building.Description or "???", city and city:GetNameKey() or "???" ) )
			end

		-- Paradrop
		elseif actionType == "INTERFACEMODE_PARADROP" then

			insert( toolTip, L( "TXT_KEY_INTERFACEMODE_PARADROP_HELP_WITH_RANGE", unit:GetDropRange() ) )

		-- Sell Exotic Goods -- bnw only
		elseif actionType == "MISSION_SELL_EXOTIC_GOODS" then

			insert( toolTip, L"TXT_KEY_MISSION_SELL_EXOTIC_GOODS_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				insert( toolTip, "+" .. unit:GetExoticGoodsGoldAmount() .. "[ICON_GOLD]" )
				insert( toolTip, L( "TXT_KEY_EXPERIENCE_POPUP", unit:GetExoticGoodsXPAmount() ) )
			end

		-- Great Scientist, bnw only
		elseif actionType == "MISSION_DISCOVER" then

			insert( toolTip, L"TXT_KEY_MISSION_DISCOVER_TECH_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				insert( toolTip, "+" .. unit:GetDiscoverAmount() .. "[ICON_RESEARCH]" )
			end

		-- Great Engineer, bnw only
		elseif actionType == "MISSION_HURRY" then

			insert( toolTip, L"TXT_KEY_MISSION_HURRY_PRODUCTION_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				insert( toolTip, "+" .. unit:GetHurryProduction(unitPlot) .. "[ICON_PRODUCTION]" )
			end

		-- Great Merchant, bnw only
		elseif actionType == "MISSION_TRADE" then

			insert( toolTip, L"TXT_KEY_MISSION_CONDUCT_TRADE_MISSION_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				insert( toolTip, "+" .. unit:GetTradeInfluence(unitPlot) .. "[ICON_INFLUENCE]" )
				insert( toolTip, "+" .. unit:GetTradeGold(unitPlot) .. "[ICON_GOLD]" )
			end

		-- Great Writer, bnw only
		elseif actionType == "MISSION_GIVE_POLICIES" then

			insert( toolTip, L"TXT_KEY_MISSION_GIVE_POLICIES_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				insert( toolTip, "+" .. unit:GetGivePoliciesCulture() .. "[ICON_CULTURE]" )
			end

		-- Great Musician, bnw only
		elseif actionType == "MISSION_ONE_SHOT_TOURISM" then

			insert( toolTip, L"TXT_KEY_MISSION_ONE_SHOT_TOURISM_HELP" )
			if gameCanHandleAction then
				insert( toolTip, "----------------" )
				insert( toolTip, "+" .. unit:GetBlastTourism() .. "[ICON_TOURISM]" )
			end

		-- Delete unit
		elseif actionType == "COMMAND_DELETE" then
			insert( toolTip, L( "TXT_KEY_SCRAP_HELP", unit:GetScrapGold() ) )

		-- Cannned help text
		elseif ( action.Help or "" ) ~= "" then
			insert( toolTip, L(action.Help) )
		end

		-- Not able to perform action
		if not gameCanHandleAction then

			-- Worker build
			if isBuild then

				-- Don't have Tech for Build?
				if improvement or route then
					-- Figure out what the name of the thing is that we're looking at
					local strImpRouteKey = (improvement and improvement.Description) or (route and route.Description) or ""

					local prereqTech = GameInfo.Technologies[build.PrereqTech]
					if prereqTech and not activeTechs:HasTech(prereqTech.ID) then
						insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_PREREQ_TECH", prereqTech.Description, strImpRouteKey ) )
					end

					if improvement then
						-- Trying to build something and are not adjacent to our territory? gk+ only
						if improvement.InAdjacentFriendly and unitPlot:GetTeam() ~= unit:GetTeam() and not unitPlot:IsAdjacentTeam(unit:GetTeam(), true) then
							insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_NOT_IN_ADJACENT_TERRITORY", strImpRouteKey ) )
						end
						-- Trying to build something in a City-State's territory? bnw only
						if improvement.OnlyCityStateTerritory then
							local unitPlotOwner = Players[unitPlot:GetOwner()]
							if not( unitPlotOwner and unitPlotOwner:IsMinorCiv() ) then
								insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_NOT_IN_CITY_STATE_TERRITORY", strImpRouteKey ) )
							end
						end
						-- Trying to build something outside of our territory?
						if improvement.OutsideBorders == false and unitPlot:GetTeam() ~= unit:GetTeam() then
							insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_OUTSIDE_TERRITORY", strImpRouteKey ) )
						end
						-- Trying to build something that requires an adjacent luxury? bnw only
						if improvement.AdjacentLuxury then
							local adjacentPlot
							for direction = 0, 5 do  -- DirectionTypes.NUM_DIRECTION_TYPES-1
								adjacentPlot = PlotDirection(x, y, direction)
								if adjacentPlot then
									local eResourceType = adjacentPlot:GetResourceType()
									if eResourceType ~= -1 then
										if GetResourceUsageType(eResourceType) == RESOURCEUSAGE_LUXURY then
											insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_NO_ADJACENT_LUXURY", strImpRouteKey ) )
											break
										end
									end
								end
							end
						end
						-- Trying to build something where we can't have two adjacent? bnw only
						if improvement.NoTwoAdjacent then
							local adjacentPlot
							for direction = 0, 5 do -- DirectionTypes.NUM_DIRECTION_TYPES-1
								adjacentPlot = PlotDirection(x, y, direction)
								if adjacentPlot then
									if adjacentPlot:GetImprovementType() == improvementID or adjacentPlot:GetBuildProgress(buildID) > 0 then
										insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_CANNOT_BE_ADJACENT", strImpRouteKey ) )
										break
									end
								end
							end
						end
					end -- improvement
				end -- improvement or route

				-- Build blocked by a feature here?
				if activePlayer:IsBuildBlockedByFeature(buildID, featureID) then
					for row in GameInfo.BuildFeatures{ BuildType = build.Type, FeatureType = feature.Type } do
						local pFeatureTech = GameInfo.Technologies[row.PrereqTech]
						insert( disabledTip, L( "TXT_KEY_BUILD_BLOCKED_BY_FEATURE", pFeatureTech.Description, feature.Description ) )
					end
				end

			-- Not a Worker build, use normal disabled help from XML
			else
				if actionType == "MISSION_FOUND" and activePlayer:IsEmpireVeryUnhappy() then
					insert( disabledTip, L"TXT_KEY_MISSION_BUILD_CITY_DISABLED_UNHAPPY" )

				elseif actionType == "MISSION_CULTURE_BOMB" and activePlayer:GetCultureBombTimer() > 0 then
					insert( disabledTip, L( "TXT_KEY_MISSION_CULTURE_BOMB_DISABLED_COOLDOWN", activePlayer:GetCultureBombTimer() ) )

				elseif action.DisabledHelp and action.DisabledHelp ~= "" then
					insert( disabledTip, L( action.DisabledHelp ) )
				end
			end

			if #disabledTip > 0 then
				insert( toolTip, "[COLOR_WARNING_TEXT]" .. concat( disabledTip, "[NEWLINE]" ) .. "[ENDCOLOR]" )
			end
		end

		-- Is this a Worker build?
		if isBuild then

			local turnsRemaining = GetUnitBuildProgressData( unitPlot, buildID, unit )
			if turnsRemaining > 0 then
				strBuildTurnsString = " ... " .. L("TXT_KEY_STR_TURNS", turnsRemaining )
			end

			-- Extra Yield from this build

			for yieldID = 0, NUM_YIELD_TYPES_minus1 do
				local yieldChange = unitPlot:GetYieldWithBuild( buildID, yieldID, false, activePlayerID ) - unitPlot:CalculateYield(yieldID)

				if yieldChange > 0 then
					insert( toolTip, "[COLOR_POSITIVE_TEXT]+" .. L( g_yieldString[yieldID], yieldChange) )
				elseif  yieldChange < 0 then
					insert( toolTip, "[COLOR_NEGATIVE_TEXT]" .. L( g_yieldString[yieldID], yieldChange) )
				end
			end

			-- Resource connection
			if improvement then
				local resourceID = unitPlot:GetResourceType( activeTeamID )
				local resource = GameInfo.Resources[resourceID]
				if resource
					and unitPlot:IsResourceConnectedByImprovement( improvementID )
					and GetResourceUsageType(resourceID) ~= RESOURCEUSAGE_BONUS
				then
					insert( toolTip, L( "TXT_KEY_BUILD_CONNECTS_RESOURCE", resource.IconString, resource.Description ) )
				end
			end

			-- Production for clearing a feature
			if feature and unitPlot:IsBuildRemovesFeature(buildID) then
				local tip = L( "TXT_KEY_BUILD_FEATURE_CLEARED", feature.Description )
				local featureProduction = unitPlot:GetFeatureProduction( buildID, activeTeamID )
				if featureProduction > 0 then
					tip = tip .. L( "TXT_KEY_BUILD_FEATURE_PRODUCTION", featureProduction )
					local city = unitPlot:GetWorkingCity()
					if city then
						tip = tip .. " (".. city:GetName()..")"
					end
				end
				insert( toolTip, tip )
			end
		end

		-- Tooltip
		g_UnitActionTooltipControls.UnitActionHelp:SetText( concat( toolTip, "[NEWLINE]" ) )

		-- Title
		g_UnitActionTooltipControls.UnitActionText:SetText( "[COLOR_POSITIVE_TEXT]" .. L( tostring( action.TextKey or actionType ) ) .. "[ENDCOLOR]".. strBuildTurnsString )

		-- HotKey
		if action.HotKey and action.HotKey ~= "" and action.SubType ~= ACTIONSUBTYPE_PROMOTION then
			g_UnitActionTooltipControls.UnitActionHotKey:SetText( "("..tostring(action.HotKey)..")" )
		else
			g_UnitActionTooltipControls.UnitActionHotKey:SetText()
		end

		-- Autosize tooltip
		g_UnitActionTooltipControls.UnitActionMouseover:DoAutoSize()
		local mouseoverSizeX = g_UnitActionTooltipControls.UnitActionMouseover:GetSizeX()
		if mouseoverSizeX < 350 then
			g_UnitActionTooltipControls.UnitActionMouseover:SetSizeX( 350 )
		end

	else
		g_UnitActionTooltipControls.UnitActionMouseover:SetHide( true )
	end
end)

--==========================================================
-- Unit Tooltips
--==========================================================
do
local function UnitToolTip( unit )
	if unit then
		local controls = g_UnitTooltipControls
		local toolTipString = ShortUnitTip( unit )
		local playerID = unit:GetOwner()
		if playerID == GetActivePlayer() then
			toolTipString = toolTipString .. "[NEWLINE]".. L("TXT_KEY_UNIT_EXPERIENCE_INFO", unit:GetLevel(), unit:GetExperience(), unit:ExperienceNeeded() ) .. L"TXT_KEY_UPANEL_CLICK_TO_SELECT"
		end
		controls.Text:SetText( toolTipString )

		local iconIndex, iconAtlas = GetUnitPortraitIcon( unit )
		IconHookup( iconIndex, 256, iconAtlas, controls.UnitPortrait )
		CivIconHookup( playerID, 64, controls.CivIcon, controls.CivIconBG, controls.CivIconShadow, false, true )
		local i = 0
		local promotionText = {}
		local promotionIcon
		g_PromotionIconIM:ResetInstances()
		if not( unit.IsTrade and unit:IsTrade() ) then
			for unitPromotion in GameInfo.UnitPromotions() do
				if unit:IsHasPromotion(unitPromotion.ID) and unitPromotion.ShowInUnitPanel ~= false then
					promotionIcon = g_PromotionIconIM:GetInstance()
					IconHookup( unitPromotion.PortraitIndex, 32, unitPromotion.IconAtlas, promotionIcon.Image )
					insert( promotionText, unitPromotion._Name )
				end
			end
		end
		controls.PortraitFrame:SetAnchor( GetMousePos() > 300 and "L,T" or "R,T" )
		controls.PromotionText:SetText( concat( promotionText, "[NEWLINE]" ) )
		controls.PromotionText:SetHide( #promotionText ~= 1 )
		controls.IconStack:SetWrapWidth( ceil( i / ceil( i / 10 ) ) * 26 )
		controls.IconStack:CalculateSize()
		controls.Box:DoAutoSize()
		Controls.UnitTooltipTimer:SetToBeginning()
		Controls.UnitTooltipTimer:Reverse()
	end
end
LuaEvents.UnitToolTip.Add( UnitToolTip )
LuaEvents.UnitFlagToolTip.Add( function( button )
	local player = Players[ button:GetVoid1() ]
	UnitToolTip( player and player:GetUnitByID( button:GetVoid2() ) )
end)

local UnitToolTips = {
	Button = UnitToolTip,
	MovementPip = function( unit )
		return ShowTextToolTip( unit and format( "%s %.3g / %g [ICON_MOVES]", L"TXT_KEY_UPANEL_MOVEMENT", unit:MovesLeft() / MOVE_DENOMINATOR, unit:MaxMoves() / MOVE_DENOMINATOR )
--[[
.." GetActivityType="..(function(a) for k, v in pairs( ActivityTypes ) do if v==a then return k end end return "unknown" end)(unit:GetActivityType())
.." GetFortifyTurns="..tostring(unit:GetFortifyTurns())
.." HasMoved="..tostring(unit:HasMoved())
.." IsReadyToMove="..tostring(unit:IsReadyToMove())
.." IsWaiting="..tostring(unit:IsWaiting())
.." IsAutomated="..tostring(unit:IsAutomated())
--]]
		)
	end,
	Mission = function( unit )
		local status = "Unkown unit activity"
		if unit then
			local buildID = unit:GetBuildType()
			if buildID ~= -1 then -- this is a worker who is actively building something
				status = ( GameInfo.Builds[ buildID ]._Name or "???" ).. " (".. GetUnitBuildProgressData( unit:GetPlot(), buildID, unit ) ..")"

			elseif unit:IsEmbarked() then
				status = L"TXT_KEY_MISSION_EMBARK_HELP" --"TXT_KEY_UNIT_STATUS_EMBARKED"

			elseif unit:IsAutomated() then
				if unit:IsWork() then
					status = L"TXT_KEY_ACTION_AUTOMATE_BUILD"
				elseif unit.IsTrade and unit:IsTrade() then
					status = L"TXT_KEY_ACTION_AUTOMATE_TRADE"
				else
					status = L"TXT_KEY_ACTION_AUTOMATE_EXPLORE"
				end

			else
				local activityType = unit:GetActivityType()
				local info = g_activityMissions[ activityType ]
				if not info then
					if unit:MovesLeft() > 0 then
						if info == false then
							info = GameInfo.Missions.MISSION_SKIP
						elseif unit:IsGarrisoned() then
							info = GameInfo.Missions.MISSION_GARRISON
						elseif unit:IsEverFortifyable() then
--							info = GameInfo.Missions.MISSION_FORTIFY
							status = format( "%s %+i%%[ICON_STRENGTH]", L"TXT_KEY_UNIT_STATUS_FORTIFIED", unit:FortifyModifier() )
						else
							info = GameInfo.Missions.MISSION_SLEEP
						end
					else
						info = GameInfo.Missions.MISSION_MOVE_TO
					end
				end
				if info then
					status = L(info.Help)
				end
			end
		else
			status = "Error - cannot find unit"
		end
		return ShowTextToolTip( status )
	end,
}
LuaEvents.UnitToolTips.Add( function( ... ) return TooltipSelect( UnitToolTips, ... ) end )

end
--==========================================================
-- Unit Type Tooltip
--==========================================================
LuaEvents.UnitPanelItemTooltip.Add( function( control, itemID )
	return ShowTextToolTipAndPicture( GetHelpTextForUnit( itemID, true ), GetUnitPortraitIcon( itemID, GetActivePlayer() ) )
end)

--==========================================================
-- City Banner & Ribbon Tooltips
--==========================================================

local function CityIsCapital( city )
	local ownerID = city:GetOwner()
	local owner = Players[ ownerID ]
	local originalOwnerID = city:GetOriginalOwner()
	local originalOwner = Players[ originalOwnerID ]
	local activePlayerID = GetActivePlayer()
	local cityNameKey = city:GetNameKey()
	if city:IsOriginalCapital() then
		if ownerID == originalOwnerID then
			if ownerID == activePlayerID then
				return L( "TXT_KEY_VP_DIPLO_TT_YOU_CONTROL_YOUR_CAPITAL", cityNameKey )
			else
				return L( "TXT_KEY_VP_DIPLO_TT_SOMEONE_CONTROLS_THEIR_CAPITAL", owner:GetName(), cityNameKey )
			end
		end
	else
		for playerID, player in pairs( Players ) do
			for city in player:Cities() do
				if city:IsOriginalCapital() and city:GetOriginalOwner() == originalOwnerID then
					cityNameKey = city:GetNameKey()
					ownerID = playerID
					owner = player
					player = nil
					break
				end
			end
			if not player then
				break
			end
		end
	end
	if ownerID == activePlayerID then
		return L( "TXT_KEY_VP_DIPLO_TT_YOU_CONTROL_OTHER_PLAYER_CAPITAL", cityNameKey, originalOwner:GetCivilizationShortDescriptionKey() )
	elseif originalOwnerID == activePlayerID then
		return L( "TXT_KEY_VP_DIPLO_TT_OTHER_PLAYER_CONTROLS_YOUR_CAPITAL", owner:GetName(), cityNameKey )
	else
		return L( "TXT_KEY_VP_DIPLO_TT_OTHER_PLAYER_CONTROLS_OTHER_PLAYER_CAPITAL", owner:GetName(), cityNameKey, originalOwner:GetCivilizationShortDescriptionKey() )
	end
end

local function CityProduction( city )
	local tip, iconIndex, iconAtlas
	local orderID, itemID = city:GetOrderFromQueue()
	local isProducing = true
	if orderID == ORDER_TRAIN then
		iconIndex, iconAtlas = GetUnitPortraitIcon( itemID, city:GetOwner() )
		tip = GetHelpTextForUnit( itemID, true )

	elseif orderID == ORDER_CONSTRUCT then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Buildings, itemID )
		tip = GetHelpTextForBuilding( itemID, false, false, city:GetNumFreeBuilding(itemID) > 0, city )

	elseif orderID == ORDER_CREATE then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Projects, itemID )
		tip = GetHelpTextForProject( itemID, true )

	elseif orderID == ORDER_MAINTAIN then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Processes, itemID )
		tip = GetHelpTextForProcess( itemID, true )
		isProducing = false
--		if tip and city:GetOrderQueueLength() > 0 then
	else
		tip = L( "TXT_KEY_CITY_NOT_PRODUCING", city:GetName() )
		isProducing = false
	end
	local change = city:GetCurrentProductionDifferenceTimes100( false, false )	-- bIgnoreFood, bool bOverflow
	return ShowProgressToolTip( g_CityProductionTooltipControls, 256, iconIndex, iconAtlas, tip,
		isProducing and city:GetProductionTurnsLeft(),
		city:GetProductionNeeded() * 100,
		city:GetProductionTimes100() + city:GetCurrentProductionDifferenceTimes100( false, true ) - change,	-- bIgnoreFood, bool bOverflow
		change )
end

local CityToolTips = {
	-- CityBanner ToolTip
	CityBannerButton = function( city )
		local cityOwnerID = city:GetOwner()
		local cityOwner = Players[ cityOwnerID ]
		local cityTeamID = city:GetTeam()
		local activeTeamID = GetActiveTeam()
		local activeTeam = Teams[ activeTeamID ]
		local tip = ""

		-- city resources
		local resources = {}
		for plot in CityPlots( city ) do
			if plot	and plot:IsRevealed( activeTeamID, true )
			then
				local resourceID = plot:GetResourceType( activeTeamID )
				local numResource = plot:GetNumResource()
				if numResource > 0 then
					if not plot:IsCity() and (plot:IsImprovementPillaged() or not plot:IsResourceConnectedByImprovement( plot:GetImprovementType() )) then
						numResource = numResource / 65536
					end
					resources[ resourceID ] = ( resources[ resourceID ] or 0 ) + numResource
				end
			end
		end
		for resourceID, numResource in pairs( resources ) do
			local resource = GameInfo.Resources[ resourceID ]
			if resource then
				local numConnected, numNotConnected = modf( numResource )
				numNotConnected = numNotConnected * 65536
				local usageID = GetResourceUsageType( resourceID )
				if usageID == RESOURCEUSAGE_STRATEGIC
					or usageID == RESOURCEUSAGE_LUXURY
				then
					if numConnected > 0 then
						tip = tip .. " [COLOR_POSITIVE_TEXT]" .. numConnected .. "[ENDCOLOR]" .. resource.IconString
					end
					if numNotConnected > 0 then
						tip = tip .. " [COLOR_WARNING_TEXT]" .. numNotConnected .. "[ENDCOLOR]" .. resource.IconString
					end
				end
			end
		end

		if cityTeamID == activeTeamID then

			local cultureStored = city:GetJONSCultureStored()
			local cultureNeeded = city:GetJONSCultureThreshold()
			local culturePerTurn = city:GetJONSCulturePerTurn()
			if culturePerTurn > 0 then
				tip = tip .. "[NEWLINE][COLOR_MAGENTA]" .. L("TXT_KEY_CITYVIEW_TURNS_TILL_TILE_TEXT", max(ceil((cultureNeeded - cultureStored ) / culturePerTurn), 1) ) .. "[ENDCOLOR]"
			else
				tip = tip .. " 0 [ICON_CULTURE]"
			end

			if city.GetReligiousMajority and city:GetReligiousMajority() < 0 then
				local religionTip =  GetReligionTooltip( city )
				if religionTip and religionTip>"" then
					tip = tip .. "[NEWLINE]" .. religionTip
				end
			end

			if g_isBasicHelp then
				if cityOwnerID == GetActivePlayer() then
					tip = tip .. "[NEWLINE]" .. L"TXT_KEY_CITY_ENTER_CITY_SCREEN"
				else
					tip = tip .. "[NEWLINE]" .. L"TXT_KEY_CITY_TEAMMATE"
				end
			end

		elseif activeTeam:IsHasMet( cityTeamID ) then
			if city.GetReligiousMajority and city:GetReligiousMajority() < 0 then
				local religionTip =  GetReligionTooltip( city )
				if religionTip and religionTip>"" then
					tip = tip .. "[NEWLINE]" .. religionTip
				end
			end
			if cityOwner.GetWarmongerPreviewString and activeTeam:IsAtWar( cityTeamID ) then
				tip = tip .. "[NEWLINE]"----------------[NEWLINE]"
						.. cityOwner:GetWarmongerPreviewString(city:GetOwner())
				if city:GetOriginalOwner() ~= city:GetOwner() then
					tip = tip .. "[NEWLINE]"----------------[NEWLINE]"
							.. cityOwner:GetLiberationPreviewString(city:GetOriginalOwner())
				end
			elseif g_isAlwaysWar then
				tip = tip .. "[NEWLINE]" .. L"TXT_KEY_ALWAYS_AT_WAR_WITH_CITY"
			end
		end
		return tip
	end,

	CityBannerRightBackground = function( city )
		local tip = ""
		local cityOwnerID = city and city:GetOwner()
		local cityOwner = Players[ cityOwnerID ]
		local activeTeam = Teams[ GetActiveTeam() ]
		if cityOwner then
			if activeTeam and activeTeam:IsHasMet( cityOwner:GetTeam() ) then

				if cityOwner:IsMinorCiv() then
					tip = GetCityStateStatusToolTip( GetActivePlayer(), cityOwnerID, true )
				else
					tip = GetMoodInfo( cityOwnerID, true )
				end

				if g_isBasicHelp then
					tip = L"TXT_KEY_TALK_TO_PLAYER" .. "[NEWLINE][NEWLINE]" .. tip
				end
			else
				-- Players we have not met
				tip = L"TXT_KEY_HAVENT_MET"
			end
		end
		return tip
	end,

	BuildGrowth = function( city )
		return ShowTextToolTip( L( "TXT_KEY_CITY_CURRENTLY_PRODUCING_TT", city:GetName(), city:GetProductionNameKey(), city:GetProductionTurnsLeft() ), GetProductionTooltip( city ) )
	end,

	CityGrowth = function( city )
		local tip
		local foodPerTurnTimes100 = city:FoodDifferenceTimes100()
		if foodPerTurnTimes100 < 0 then
			tip = L( "TXT_KEY_NTFN_CITY_STARVING", city:GetName() )
		elseif city:IsForcedAvoidGrowth() then
			tip = L"TXT_KEY_CITYVIEW_FOCUS_AVOID_GROWTH_TEXT"
		elseif city:IsFoodProduction() or foodPerTurnTimes100 == 0 then
			tip = L"TXT_KEY_CITYVIEW_STAGNATION_TEXT"
		else
			tip = L( "TXT_KEY_CITYVIEW_TURNS_TILL_CITIZEN_TEXT", city:GetFoodTurnsLeft() )
		end
		return ShowTextToolTip( tip, GetFoodTooltip( city ) )
	end,

	BorderGrowth = function( city )
		return ShowTextToolTip( city:GetName(),
					L("TXT_KEY_CITYVIEW_TURNS_TILL_TILE_TEXT", ceil( (city:GetJONSCultureThreshold() - city:GetJONSCultureStored()) / city:GetJONSCulturePerTurn() ) ),
					GetCultureTooltip( city ) )
	end,
	CityReligion = function( city )
		return GetReligionTooltip( city )
	end,
	CityFocus = function( city )
		return city and g_cityFocusTooltips[city:GetFocusType()]
	end,

	CityQuests = function( city )
		local cityOwnerID = city:GetOwner()
		local cityOwner = Players[ cityOwnerID ]
		local activePlayerID = GetActivePlayer()
		local tip
		if cityOwner and cityOwner:IsMinorCiv() then
			tip = GetActiveQuestToolTip( activePlayerID, cityOwnerID )
		else
			-- We love the king
			local resource = GameInfo.Resources[ city:GetResourceDemanded() ]
			local weLoveTheKingDayCounter = city:GetWeLoveTheKingDayCounter()
			if weLoveTheKingDayCounter > 0 then
				tip = L( "TXT_KEY_CITYVIEW_WLTKD_COUNTER", weLoveTheKingDayCounter )
			elseif resource then
				return ShowResourceToolTip( resource.ID, { L( "TXT_KEY_CITYVIEW_RESOURCE_DEMANDED", resource.IconString .. " " .. resource._Name ) } )
			end
		end
		return tip
	end,

	CityIsPuppet = function( city )
		local cityOwnerID = city:GetOwner()
		local cityOwner = Players[ cityOwnerID ]
		if cityOwner.MayNotAnnex and cityOwner:MayNotAnnex() or cityOwnerID ~= GetActivePlayer() then
			return L"TXT_KEY_CITY_PUPPET"
		else
			return L"TXT_KEY_CITY_PUPPET".."[NEWLINE][NEWLINE]"..L"TXT_KEY_CITY_ANNEX_TT"
		end
	end,
	CityIsRazing = function( city )
		return L( "TXT_KEY_CITY_BURNING", city:GetRazingTurns() )
	end,
	CityIsResistance = function( city )
		return L( "TXT_KEY_CITY_RESISTANCE", city:GetResistanceTurns() )
	end,
	CityIsConnected = function( city )
		local tip = L"TXT_KEY_CITY_CONNECTED"
		local cityOwner = Players[ city:GetOwner() ]
		if cityOwner then
			tip = format("%s (%+g[ICON_GOLD])", tip, (cityOwner.GetRouteGoldTimes100 or cityOwner.GetCityConnectionRouteGoldTimes100)( cityOwner, city ) / 100 )
		end
		return tip
	end,
	CityIsBlockaded = function()
		return L"TXT_KEY_CITY_BLOCKADED"
	end,
	CityIsOccupied = function()
		return L"TXT_KEY_CITY_OCCUPIED"
	end,

	CityIsCapital = CityIsCapital,
	CityIsOriginalCapital = CityIsCapital,

	CivIndicator = function( city )
		local cityOwnerID = city:GetOwner()
		local originalCityOwnerID = city:GetOriginalOwner()
		if cityOwnerID == originalCityOwnerID then
			return GetAllyToolTip( GetActivePlayer(), cityOwnerID )
		else
			return L( "TXT_KEY_POPUP_CITY_CAPTURE_INFO_LIBERATE", Players[originalCityOwnerID]:GetCivilizationShortDescription() )
		end
	end,

	CityProductionBG = CityProduction,
	Button = CityProduction,

	CityPopulation = function( city )
		local foodStored100 = city:GetFoodTimes100()
		local foodPerTurn100 = city:FoodDifferenceTimes100( true )
		local turnsToCityGrowth = city:GetFoodTurnsLeft()
		local iconIndex = 0
		if foodPerTurn100 < 0 then
			turnsToCityGrowth = floor( foodStored100 / -foodPerTurn100 ) + 1
			iconIndex = 5
		end
		return ShowProgressToolTip( g_CityGrowthTooltipControls, 256, iconIndex, "CITIZEN_ATLAS",
			city:GetPopulation(),
			turnsToCityGrowth,
			city:GrowthThreshold() * 100,
			foodStored100,
			foodPerTurn100
		)
	end,
}

LuaEvents.CityToolTips.Add( function( control, city )
	local toolTip = city and TooltipSelect( CityToolTips, control, city )
	return toolTip and ShowTextToolTip( city:GetName(), toolTip )
end)

--==========================================================
-- City View Tooltips
--==========================================================

LuaEvents.CityViewBuildingToolTip.Add( function( control )
	local buildingID = control:GetVoid1()
	local building = GameInfo.Buildings[ buildingID ]
	local city = GetHeadSelectedCity()
	return ShowTextToolTipAndPicture( city and GetHelpTextForBuilding( buildingID, false, false, city:GetNumFreeBuilding(buildingID) > 0, city ), building and building.PortraitIndex, building and building.IconAtlas )
end)

local function CityOrderItemTooltip( city, isDisabled, purchaseYieldID, orderID, itemID, _, isRepeat )
	local itemInfo, tip, strDisabledInfo, iconIndex, iconAtlas, isRealRepeat
	if city then
		local cityOwnerID = city:GetOwner()
		if orderID == ORDER_TRAIN then
			itemInfo = GameInfo.Units
			iconIndex, iconAtlas = GetUnitPortraitIcon( itemID, cityOwnerID )
			tip = GetHelpTextForUnit( itemID, true )
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

		elseif orderID == ORDER_CONSTRUCT then
			itemInfo = GameInfo.Buildings
			tip = GetHelpTextForBuilding( itemID, false, false, city:GetNumFreeBuilding(itemID) > 0, city )
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

		elseif orderID == ORDER_CREATE then
			itemInfo = GameInfo.Projects
			tip = GetHelpTextForProject( itemID, true )
		elseif orderID == ORDER_MAINTAIN then
			itemInfo = GameInfo.Processes
			tip = GetHelpTextForProcess( itemID, true )
			isRealRepeat = true
		else
			tip = L"TXT_KEY_PRODUCTION_NO_PRODUCTION"
		end
		if tip then
			if isRealRepeat then
				tip = "[ICON_TURNS_REMAINING]" .. tip
			end
			if strDisabledInfo and #strDisabledInfo > 0 then
				strDisabledInfo = (strDisabledInfo:gsub("^%[NEWLINE%]","")):gsub("^%[NEWLINE%]","")
--				if cash and cash < 0 then
--					strDisabledInfo = ("%s (%+i%s)"):format( strDisabledInfo, cash, icon )
--				end
				tip = "[COLOR_WARNING_TEXT]" .. strDisabledInfo .. "[ENDCOLOR][NEWLINE][NEWLINE]"..tip
			elseif purchaseYieldID then
				if not isDisabled then
					tip = "[COLOR_YELLOW]"..L"TXT_KEY_CITYVIEW_PURCHASE_TT".."[ENDCOLOR][NEWLINE][NEWLINE]"..tip
				end
			elseif isDisabled then
				tip = "[COLOR_YIELD_FOOD]"..L"TXT_KEY_CITYVIEW_QUEUE_PROD_TT".."[ENDCOLOR][NEWLINE][NEWLINE]"..tip
			end
		end
		local item = itemInfo and itemInfo[itemID]
		return ShowTextToolTipAndPicture( tip, iconIndex or (item and item.PortraitIndex), iconAtlas or (item and item.IconAtlas) )
	end
	return ShowTextToolTip( "Unknown city" )
end

LuaEvents.CityOrderItemTooltip.Add( CityOrderItemTooltip )

local CityViewToolTips = {
	ProdBox = GetProductionTooltip,
	FoodBox = GetFoodTooltip,
	PopulationBox = GetFoodTooltip,
	GoldBox = GetGoldTooltip,
	ScienceBox = GetScienceTooltip,
	CultureBox = GetCultureTooltip,
	FaithBox = GetFaithTooltip,
	TourismBox = GetTourismTooltip,
	ProductionPortraitButton = function() CityOrderItemTooltip( GetHeadSelectedCity(), false, false, GetHeadSelectedCity():GetOrderFromQueue( 0 ) ) end,
}

LuaEvents.CityViewToolTips.Add( function( control )
	local city = GetHeadSelectedCity()
	local toolTip = city and TooltipSelect( CityViewToolTips, control, city )
	return toolTip and ShowTextToolTip( toolTip )
end)


--==========================================================
-- Tech Tooltips
--==========================================================

LuaEvents.TechButtonTooltip.Add( function( orderID, itemID )
	local tip = "no tip found"
	local item, iconIndex, iconAtlas
	if orderID == ORDER_TRAIN then
		iconIndex, iconAtlas = GetUnitPortraitIcon( itemID, GetActivePlayer() )
		tip = GetHelpTextForUnit( itemID, true )

	elseif orderID == ORDER_CONSTRUCT then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Buildings, itemID )
		tip = GetHelpTextForBuilding( itemID )

	elseif orderID == ORDER_CREATE then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Projects, itemID )
		tip = GetHelpTextForProject( itemID, true )

	elseif orderID == ORDER_MAINTAIN then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Processes, itemID )
		tip = GetHelpTextForProcess( itemID, true )

	elseif orderID == 11 then
		iconIndex, iconAtlas = GetItemPortraitIcon( GameInfo.Resources, itemID )
		tip = L("TXT_KEY_REVEALS_RESOURCE_ON_MAP", GameInfo.Resources[itemID]._Name)

	elseif orderID == 12 then
		local build = GameInfo.Builds[ itemID ]
		if build then
			tip = build._Name
			item = GameInfo.Improvements[ build.ImprovementType ]
			if item then
				tip = GetHelpTextForImprovement( item.ID )
			else
				item = GameInfo.Routes[ build.RouteType ]
				if not item then
					item = GameInfo.BuildFeatures{ BuildType = build.Type }()
					item = item and GameInfo.Features[ item.FeatureType ]
				end
			end
			if item then
				iconIndex, iconAtlas = item.PortraitIndex, item.IconAtlas
			end
		end

	elseif orderID == 13 then
		item = GameInfo.Missions[ itemID ]
		if item then
			local entry = item.Type
			if entry == "MISSION_EMBARK" then
				item = GameInfo.Concepts.CONCEPT_MOVEMENT_EMBARKING
			elseif entry == "MISSION_ROUTE_TO" then
				item = GameInfo.Concepts.CONCEPT_WORKERS_ROADS_TRADE_ROUTES
			elseif entry == "MISSION_ESTABLISH_TRADE_ROUTE" then
				item = GameInfo.Concepts.CONCEPT_TRADE_ROUTES
			end
			if item then
				tip = item._Name
			end
		end

	elseif orderID == 14 then
		item = GameInfo.Terraform[ itemID ]
		if item then
			local entry = item.Type
			if entry == "TERRAFORM_ADD_MIASMA" then
				item = GameInfo.Concepts.CONCEPT_WORKERS_PLACE
			elseif entry == "TERRAFORM_CLEAR_MIASMA" then
				item = GameInfo.Concepts.CONCEPT_WORKERS_REMOVE
			else
				item = GameInfo.Features[ item.FeatureTypeChange ] or GameInfo.Terrains[ item.TerrainTypeChange ]
			end
			if item then
				tip = item._Name
			end
		end
	elseif orderID == 15 then
		tip = GetHelpTextForPlayerPerk( itemID, true )
	end
	return ShowTextToolTipAndPicture( tip, iconIndex, iconAtlas )
--	return ShowTextToolTipAndPicture( "This is button tooltip for order "..orderID.." item "..itemID.." icon "..tostring(iconIndex)..":"..tostring(iconAtlas).."[NEWLINE]"..tip, iconIndex, iconAtlas )
end)

LuaEvents.TechTooltip.Add( function( techID )
	return ShowTextToolTipAndPicture( GetHelpTextForTech( techID, Players[ GetActivePlayer() ]:CanResearch( techID ) ), GetItemPortraitIcon( GameInfo.Technologies, techID ) )
end)

--==========================================================
-- Policy Tooltips
--==========================================================

LuaEvents.PolicyTooltip.Add( function( control )
	local policyID = control:GetVoid1()
	local policyInfo = GameInfo.Policies[ policyID ]
	local player = Players[ GetActivePlayer() ]

	if policyInfo and player then

		-- Tooltip
		local tip = L( policyInfo.Help )

		-- Player already has Policy
		if player:HasPolicy( policyID ) then
			if player:IsPolicyBlocked( policyID ) then
				tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_BRANCH_BLOCKED")
			end

		-- Can adopt the Policy right now
		elseif player:CanAdoptPolicy( policyID ) then

		-- Policy is unlocked, but we lack culture
		elseif player:CanAdoptPolicy( policyID, true ) then
			-- Tooltip
			tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_CULTURE", player:GetNextPolicyCost())
		else
			-- Tooltip
			tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_CANNOT_UNLOCK")
		end
		return ShowTextToolTipAndPicture( tip, policyInfo.PortraitIndex, policyInfo.IconAtlas )
	end
end)

LuaEvents.PolicyBranchTooltip.Add( function( control )
	local policyBranchID = control:GetVoid1()
	local policyBranchInfo = GameInfo.PolicyBranchTypes[ policyBranchID ]
	local player = Players[ GetActivePlayer() ]

	if policyBranchInfo and player then

		local tip = L( policyBranchInfo.Help )

		-- Branch is unlocked
		if player:IsPolicyBranchUnlocked( policyBranchID ) then
			-- Branch is blocked by another branch
			if player:IsPolicyBranchBlocked( policyBranchID ) then
				tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_BRANCH_BLOCKED")
			end

		-- Cannot adopt this branch right now
		elseif policyBranchInfo.LockedWithoutReligion and not g_isReligionEnabled then
			tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_RELIGION");

		-- Can adopt this branch right now
		elseif player:CanUnlockPolicyBranch( policyBranchID ) then
			tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_BRANCH_UNLOCK_SPEND", player:GetNextPolicyCost())

		-- Branch is not yet unlocked
		else
			tip = tip .. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK")
			local eraPrereq = GameInfoTypes[ policyBranchInfo.EraPrereq ]
			-- Not in prereq Era
			if eraPrereq and Teams[player:GetTeam()]:GetCurrentEra() < eraPrereq then
				tip = tip .. " " .. L("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_ERA", GameInfo.Eras[eraPrereq].Description)
			-- Don't have enough Culture Yet
			else
				tip = tip .. " " .. L("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_CULTURE", player:GetNextPolicyCost())
			end
		end
		return ShowTextToolTip( tip )
	end
end)

LuaEvents.TenetToolTip.Add(	function ( control )
	local player = Players[ GetActivePlayer() ]
	local tip = "???"
	if player then
		local tenetID = control:GetVoid1()
		local tenetLevel = control:GetVoid2()
		local tenetInfo = GameInfo.Policies[ tenetID ]
		if tenetInfo then
			tip = L( tenetInfo.Help )
		else
			if tenetID == -1 then
				tip = L"TXT_KEY_POLICYSCREEN_ADD_TENET"
			elseif tenetID == -2 then
				tip = L( "TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_CULTURE", player:GetNextPolicyCost() )
			elseif tenetID == -3 then
				tip = "[ICON_LOCKED]" .. L( "TXT_KEY_POLICYSCREEN_NEED_L"..(tenetLevel-1).."_TENETS_TOOLTIP" )
			elseif tenetID == -4 then
				tip = "[ICON_LOCKED][COLOR_WARNING_TEXT]" .. L( "TXT_KEY_POLICYSCREEN_IDEOLOGY_LEVEL"..tenetLevel ) .. "[ENDCOLOR]"
			end
			local tips = { tip }
			for _,tenetID in ipairs( player:GetAvailableTenets( tenetLevel ) ) do
				tenetInfo = GameInfo.Policies[ tenetID ]
				if tenetInfo then
					insert( tips, L(tenetInfo.Help or tenetInfo.Description or "???") )
				end
			end
			tip = concat( tips, "[NEWLINE][NEWLINE]" )
		end
	end
	return ShowTextToolTip( tip )
end)


--==========================================================
-- TopPanel Tooltips
--==========================================================

local function ScienceTooltip()

	local tips = {}
	local tech, sciencePerTurn, researchTurnsLeft, researchCost, researchProgress, reseachLost

	if g_isScienceEnabled then

		local activePlayerID = GetActivePlayer()
		local activeTeamID = GetActiveTeam()
		local activePlayer = Players[activePlayerID]
		local activeTeam = Teams[activeTeamID]
		local activeTeamTechs = activeTeam:GetTeamTechs()

		local sciencePerTurnTimes100 = activePlayer:GetScienceTimes100()
		local techID = activePlayer:GetCurrentResearch()
		local recentTechID = activeTeamTechs:GetLastTechAcquired()

		if IsCiv5BNW and activePlayer:IsAnarchy() then
			insert( tips, L( "TXT_KEY_TP_ANARCHY", activePlayer:GetAnarchyNumTurns() ) )
			insert( tips, "" )
		end

		if techID ~= -1 then
		-- Are we researching something right now?
			tech = GameInfo.Technologies[ techID ]
			researchTurnsLeft = activePlayer:GetResearchTurnsLeft( techID, true )
			researchCost = activePlayer:GetResearchCost( techID )
			researchProgress = activePlayer:GetResearchProgress( techID )
			local tip = researchProgress .. "[ICON_RESEARCH]"
			if tech then
				tip = L( "TXT_KEY_PROGRESS_TOWARDS", g_scienceTextColor .. Locale.ToUpper( tech._Name ) .. "[ENDCOLOR]" ) .. " " .. tip .. "/ " .. researchCost .. "[ICON_RESEARCH]"
			end
			insert( tips, tip )

			if sciencePerTurnTimes100 > 0 then
				local scienceOverflowTimes100 = sciencePerTurnTimes100 * researchTurnsLeft + (researchProgress - researchCost) * 100
				local tip = g_scienceTextColor .. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", researchTurnsLeft ) ) .. "[ENDCOLOR] " .. format( "%+g", scienceOverflowTimes100 / 100 ) .. "[ICON_RESEARCH]"
				if researchTurnsLeft > 1 then
					tip = L( "TXT_KEY_STR_TURNS", researchTurnsLeft -1 ) .. " " .. format( "%+g", (scienceOverflowTimes100 - sciencePerTurnTimes100) / 100 ) .. "[ICON_RESEARCH]  " .. tip
				end
				insert( tips, tip )
			end

		elseif recentTechID ~= -1 then
		-- maybe we just finished something
			tech = GameInfo.Technologies[ recentTechID ]
			local tip = L"TXT_KEY_NOTIFICATION_SUMMARY_NEW_RESEARCH"
			if tech then
				tip = L"TXT_KEY_RESEARCH_FINISHED" .. " " .. g_scienceTextColor .. Locale.ToUpper( tech._Name ) .. "[ENDCOLOR], " .. tip
			end
			insert( tips, tip )
		end

		sciencePerTurn = sciencePerTurnTimes100 / 100
		reseachLost = activePlayer:GetScienceFromBudgetDeficitTimes100() / 100

		insert( tips, g_scienceTextColor )
		insert( tips, format( "%+g", sciencePerTurn ) .. "[ENDCOLOR] " .. L"TXT_KEY_REPLAY_DATA_SCIENCEPERTURN" )

		-- Science LOSS from Budget Deficits
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_BUDGET_DEFICIT", reseachLost )

		-- Science from Cities
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_CITIES", activePlayer:GetScienceFromCitiesTimes100(true) / 100 )

		-- Science from Trade Routes
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_ITR", ( activePlayer:GetScienceFromCitiesTimes100(false) - activePlayer:GetScienceFromCitiesTimes100(true) ) / 100 )

		-- Science from Other Players
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_MINORS", activePlayer:GetScienceFromOtherPlayersTimes100() / 100 )

		if IsCiv5 then
			-- Science from Happiness
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_HAPPINESS", activePlayer:GetScienceFromHappinessTimes100() / 100 )

			-- Science from Vassals / Compatibility with Putmalk's Civ IV Diplomacy Features Mod
			if activePlayer.GetScienceFromVassalTimes100 then
				insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_VASSALS", activePlayer:GetScienceFromVassalTimes100() / 100 )
			end

			-- Compatibility with Gazebo's City-State Diplomacy Mod (CSD) for Brave New World v23
			if activePlayer.GetScienceRateFromMinorAllies and activePlayer.GetScienceRateFromLeagueAid then
				insertLocalizedIfNonZero( tips, "TXT_KEY_MINOR_SCIENCE_FROM_LEAGUE_ALLIES", activePlayer:GetScienceRateFromMinorAllies() )
				insertLocalizedIfNonZero( tips, "TXT_KEY_SCIENCE_FUNDING_FROM_LEAGUE", activePlayer:GetScienceRateFromLeagueAid() )
			end

			-- Science from Research Agreements
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_RESEARCH_AGREEMENTS", activePlayer:GetScienceFromResearchAgreementsTimes100() / 100 )

			-- Show Research Agreements

			local itemType, duration, finalTurn, data1, data2, data3, flag1, fromPlayerID
			local gameTurn = Game.GetGameTurn() - 1
			local researchAgreementCounters = {}

			PushScratchDeal()
			for i = 0, UI.GetNumCurrentDeals( activePlayerID ) - 1 do
				UI.LoadCurrentDeal( activePlayerID, i )
				ScratchDeal:ResetIterator()
				repeat
					if IsCiv5BNW_BE then
						itemType, duration, finalTurn, data1, data2, data3, flag1, fromPlayerID = ScratchDeal:GetNextItem()
					else
						itemType, duration, finalTurn, data1, data2, fromPlayerID = ScratchDeal:GetNextItem()
					end
--local itemKey for k,v in pairs( TradeableItems ) do if itemType == v then itemKey = k break end end
--print( "Deal #", i, "item type", itemType, itemKey, "duration", duration, "finalTurn", finalTurn, "data1", data1, "data2", data2, "fromPlayerID", fromPlayerID)
					if itemType == TradeableItems.TRADE_ITEM_RESEARCH_AGREEMENT and fromPlayerID ~= activePlayerID then
						researchAgreementCounters[fromPlayerID] = finalTurn - gameTurn
						break
					end
				until not itemType
			end
			PopScratchDeal()

			local tipIndex = #tips

			for playerID = 0, MAX_MAJOR_CIVS-1 do

				local player = Players[playerID]
				local teamID = player:GetTeam()

				if playerID ~= activePlayerID and player:IsAlive() and activeTeam:IsHasMet(teamID) then

					-- has reseach agreement ?
					if activeTeam:IsHasResearchAgreement(teamID) then
						insert( tips, "[ICON_BULLET][COLOR_POSITIVE_TEXT]" .. player:GetName() .. "[ENDCOLOR]" )
						if researchAgreementCounters[playerID] then
							append( tips, " " .. g_scienceTextColor .. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", researchAgreementCounters[playerID] ) ) .. "[ENDCOLOR]" )
						end
					else
						insert( tips, "[ICON_BULLET][COLOR_WARNING_TEXT]" .. player:GetName() .. "[ENDCOLOR]" )
					end
				end
			end

			if #tips > tipIndex then
				insert( tips, tipIndex+1, "" )
				insert( tips, tipIndex+2, L"TXT_KEY_DO_RESEARCH_AGREEMENT" )
			end
		else
			-- Science from Health
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_HEALTH", activePlayer:GetScienceFromHealthTimes100() / 100 )

			-- Science from Culture Rate
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_CULTURE", activePlayer:GetScienceFromCultureTimes100() / 100 )

			-- Science from Diplomacy Rate
			local scienceFromDiplomacy = activePlayer:GetScienceFromDiplomacyTimes100() / 100
			if scienceFromDiplomacy > 0 then
				insert( tips, L( "TXT_KEY_TP_SCIENCE_FROM_DIPLOMACY", scienceFromDiplomacy ) )
			elseif scienceFromDiplomacy < 0 then
				insert( tips, L( "TXT_KEY_TP_NEGATIVE_SCIENCE_FROM_DIPLOMACY", -scienceFromDiplomacy ) )
			end
		end

		-- Let people know that building more cities makes techs harder to get
		if IsCiv5BNW_BE and g_isBasicHelp then
			insert( tips, "" )
			insert( tips, L( "TXT_KEY_TP_TECH_CITY_COST", Game.GetNumCitiesTechCostMod() * ( 100 + ( IsCivBE and activePlayer:GetNumCitiesResearchCostDiscount() or 0 ) ) / 100 ) )
		end
	else
		insert( tips, L"TXT_KEY_TOP_PANEL_SCIENCE_OFF" .. ": " .. L"TXT_KEY_TOP_PANEL_SCIENCE_OFF_TOOLTIP" )
	end

	ShowProgressToolTip( g_TechProgressToolTipControls, 256, tech and tech.PortraitIndex, tech and tech.IconAtlas,
		concat( tips, "[NEWLINE]" ),
		researchTurnsLeft,
		researchCost,
		researchProgress,
		sciencePerTurn,
		reseachLost )
end

-------------------------------------------------
-- Faith Tooltip (GK & BNW)
-------------------------------------------------
local function FaithTooltip()

	if g_isReligionEnabled then
		local activePlayerID = GetActivePlayer()
		local activePlayer = Players[activePlayerID]

		local tips = {}
		local faithPerTurn = activePlayer:GetTotalFaithPerTurn()

		if IsCiv5BNW_BE and activePlayer:IsAnarchy() then
			insert( tips, L( "TXT_KEY_TP_ANARCHY", activePlayer:GetAnarchyNumTurns() ) )
			insert( tips, "" )
		end

		insert( tips, L("TXT_KEY_TP_FAITH_ACCUMULATED", activePlayer:GetFaith()) )
		insert( tips, "" )
		insert( tips, "[COLOR_WHITE]" .. format("%+g", faithPerTurn ) .. "[ENDCOLOR] "
			.. L"TXT_KEY_YIELD_FAITH" .. "[ICON_PEACE] " .. L"TXT_KEY_GOLD_PERTURN_HEADING4_TITLE" )

		-- Faith from Cities
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_FAITH_FROM_CITIES", activePlayer:GetFaithPerTurnFromCities() )

		-- Faith from Outposts
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_FAITH_FROM_OUTPOSTS", IsCivBE and activePlayer:GetFaithPerTurnFromOutposts() or 0 )

		-- Faith from Minor Civs
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_FAITH_FROM_MINORS", activePlayer:GetFaithPerTurnFromMinorCivs() )

		-- Faith from Religion
		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_FAITH_FROM_RELIGION", activePlayer:GetFaithPerTurnFromReligion() )

		-- New World Deluxe Scenario ( you still need to delete TopPanel.lua from ...\Steam\SteamApps\common\sid meier's civilization v\assets\DLC\DLC_07\Scenarios\Conquest of the New World Deluxe\UI )
		if IsNewWorldDeluxeScenario then	-- global defined by EUI_context
			insert( tips, L"TXT_KEY_NEWWORLD_SCENARIO_TP_RELIGION_TOOLTIP" )
		else
			if activePlayer:HasCreatedPantheon() then
				if (Game.GetNumReligionsStillToFound() > 0 or activePlayer:HasCreatedReligion())
					and (activePlayer:GetCurrentEra() < GameInfoTypes.ERA_INDUSTRIAL)
				then
					insertLocalizedIfNonZero( tips, "TXT_KEY_TP_FAITH_NEXT_PROPHET", activePlayer:GetMinimumFaithNextGreatProphet() )
				end
			else
				if activePlayer:CanCreatePantheon(false) then
					insertLocalizedIfNonZero( tips, "TXT_KEY_TP_FAITH_NEXT_PANTHEON", Game.GetMinimumFaithNextPantheon() )
				else
					insert( tips, L"TXT_KEY_TP_FAITH_PANTHEONS_LOCKED" )
				end
			end

			insert( tips, "" )
			insert( tips, L( "TXT_KEY_TP_FAITH_RELIGIONS_LEFT", max( Game.GetNumReligionsStillToFound(), 0 ) ) )

			if activePlayer:GetCurrentEra() >= GameInfoTypes.ERA_INDUSTRIAL then
				insert( tips, "" )
				insert( tips, L( "TXT_KEY_TP_FAITH_NEXT_GREAT_PERSON", activePlayer:GetMinimumFaithNextGreatProphet() ) )
				local numTips = #tips
				local capitalCity = activePlayer:GetCapitalCity()
				if capitalCity then
					for unit in GameInfo.Units{Special = "SPECIALUNIT_PEOPLE"} do
						local unitID = unit.ID
						if capitalCity:GetUnitFaithPurchaseCost(unitID, true) > 0
							and activePlayer:IsCanPurchaseAnyCity(false, true, unitID, -1, YieldTypes.YIELD_FAITH)
							and activePlayer:DoesUnitPassFaithPurchaseCheck(unitID)
						then
							insert( tips, "[ICON_BULLET]" .. unit._Name )
						end
					end
				end

				if numTips == #tips then
					insert( tips, "[ICON_BULLET]" .. L"TXT_KEY_RO_YR_NO_GREAT_PEOPLE" )
				end
			end
		end
		return concat( tips, "[NEWLINE]" )
	else
		return L"TXT_KEY_TOP_PANEL_RELIGION_OFF_TOOLTIP"	--TXT_KEY_TOP_PANEL_RELIGION_OFF
	end
end

local TopPanelTooltips = {
	SciencePerTurn = ScienceTooltip,
	TechIcon = ScienceTooltip,
	GoldPerTurn = function()
		local activePlayerID = GetActivePlayer()
		local activeTeamID = GetActiveTeam()
		local activePlayer = Players[activePlayerID]
		local activeTeam = Teams[activeTeamID]

		local tips = {}

		local goldPerTurnFromDiplomacy = activePlayer:GetGoldPerTurnFromDiplomacy()
		local goldPerTurnFromOtherPlayers = max(0,goldPerTurnFromDiplomacy) * 100
		local goldPerTurnToOtherPlayers = -min(0,goldPerTurnFromDiplomacy)

		local goldPerTurnFromReligion = IsCiv5notVanilla and activePlayer:GetGoldPerTurnFromReligion() * 100 or 0
		local goldPerTurnFromCities = activePlayer:GetGoldFromCitiesTimes100()
		local cityConnectionGold = activePlayer:GetCityConnectionGoldTimes100()
		local playerTraitGold = 0
		local tradeRouteGold = 0
		local goldPerTurnFromPolicies = 0

		local unitCost = activePlayer:CalculateUnitCost()
		local unitSupply = activePlayer:CalculateUnitSupply()
		local buildingMaintenance = activePlayer:GetBuildingGoldMaintenance()
		local improvementMaintenance = activePlayer:GetImprovementGoldMaintenance()
		local vassalMaintenance = activePlayer.GetVassalGoldMaintenance and activePlayer:GetVassalGoldMaintenance() or 0	-- Compatibility with Putmalk's Civ IV Diplomacy Features Mod
		local routeMaintenance = 0
		local beaconEnergyDelta = 0

		if IsCiv5BNW_BE then
			tradeRouteGold = activePlayer:GetGoldFromCitiesMinusTradeRoutesTimes100()
			goldPerTurnFromCities, tradeRouteGold = tradeRouteGold, goldPerTurnFromCities - tradeRouteGold
			playerTraitGold = activePlayer:GetGoldPerTurnFromTraits() * 100
			if activePlayer:IsAnarchy() then
				insert( tips, L("TXT_KEY_TP_ANARCHY", activePlayer:GetAnarchyNumTurns() ) )
				insert( tips, "" )
			end
		end

		-- Total gold
		local totalIncome, totalWealth
		local explicitIncome = goldPerTurnFromCities + goldPerTurnFromOtherPlayers + cityConnectionGold + goldPerTurnFromReligion + tradeRouteGold + playerTraitGold
		if IsCiv5 then
			totalWealth = activePlayer:GetGold()
			totalIncome = explicitIncome
		else
			totalWealth = activePlayer:GetEnergy()
			totalIncome = activePlayer:CalculateGrossGoldTimes100() + goldPerTurnToOtherPlayers * 100
			goldPerTurnFromPolicies = activePlayer:GetGoldPerTurnFromPolicies()
			explicitIncome = explicitIncome + goldPerTurnFromPolicies
			routeMaintenance = activePlayer:GetRouteEnergyMaintenance()
			beaconEnergyDelta = activePlayer:GetBeaconEnergyCostPerTurn()
		end
		insert( tips, L( "TXT_KEY_TP_AVAILABLE_GOLD", totalWealth ) )
		local totalExpenses = unitCost + unitSupply + buildingMaintenance + improvementMaintenance + goldPerTurnToOtherPlayers + vassalMaintenance + routeMaintenance + beaconEnergyDelta
		insert( tips, "" )

		-- Gold per turn

		insert( tips, format( "[COLOR_YELLOW]%+g[ENDCOLOR] ", activePlayer:CalculateGoldRateTimes100() / 100 ) .. L(format("TXT_KEY_REPLAY_DATA_%sPERTURN", g_currencyString)) )

		-- Science LOSS from Budget Deficits

		insertLocalizedIfNonZero( tips, "TXT_KEY_TP_SCIENCE_FROM_BUDGET_DEFICIT", activePlayer:GetScienceFromBudgetDeficitTimes100() / 100 )

		-- Income

		insert( tips, "[COLOR_WHITE]" )
		insert( tips, L("TXT_KEY_TP_TOTAL_INCOME", totalIncome / 100 ) )
		insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_CITY_OUTPUT", goldPerTurnFromCities / 100 )

		if IsCiv5BNW_BE then
			insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_FROM_CITY_CONNECTIONS", g_currencyString), cityConnectionGold / 100 )
			insertLocalizedBulletIfNonZero( tips, IsCiv5 and "TXT_KEY_TP_GOLD_FROM_ITR" or "TXT_KEY_TP_ENERGY_FROM_TRADE_ROUTES", tradeRouteGold / 100 )
			insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_FROM_TRAITS", g_currencyString), playerTraitGold / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_ENERGY_FROM_POLICIES", goldPerTurnFromPolicies / 100 )
		else
			insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_FROM_TR", g_currencyString), cityConnectionGold / 100 )
		end

		insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_FROM_OTHERS", g_currencyString), goldPerTurnFromOtherPlayers / 100 )
		insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_FROM_RELIGION", g_currencyString), goldPerTurnFromReligion / 100 )
		insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_YIELD_FROM_UNCATEGORIZED", (totalIncome - explicitIncome) / 100 )
		insert( tips, "[ENDCOLOR]" )

		-- Spending

		insert( tips, "[COLOR:255:150:150:255]" .. L("TXT_KEY_TP_TOTAL_EXPENSES", totalExpenses ) )
		insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNIT_MAINT", unitCost )
		insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_UNIT_SUPPLY", g_currencyString), unitSupply )
		insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_BUILDING_MAINT", g_currencyString), buildingMaintenance )
		insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_TILE_MAINT", g_currencyString), improvementMaintenance )
		insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_ENERGY_ROUTE_MAINT", routeMaintenance )
		insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_GOLD_VASSAL_MAINT", vassalMaintenance )	-- Compatibility with Putmalk's Civ IV Diplomacy Features Mod
		insertLocalizedBulletIfNonZero( tips, format("TXT_KEY_TP_%s_TO_OTHERS", g_currencyString ), goldPerTurnToOtherPlayers )
		insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_ENERGY_TO_BEACON", beaconEnergyDelta )
		insert( tips, "[ENDCOLOR]" )

		-- show gold available for trade to the active player
		local tipIndex = #tips

		for playerID = 0, MAX_MAJOR_CIVS-1 do

			local player = Players[playerID]

			-- Valid player? - Can't be us, has to be alive, and has to be met
			if playerID ~= activePlayerID and player:IsAlive() and activeTeam:IsHasMet( player:GetTeam() ) then
				insert( tips, "[ICON_BULLET]" .. player:GetName() .. format("  %i%s(%+i)",
						ScratchDeal:GetGoldAvailable(playerID, -1), g_currencyIcon, player:CalculateGoldRate() ) )
			end
		end

		if #tips > tipIndex then
			insert( tips, tipIndex+1, "" )
			insert( tips, tipIndex+2, L"TXT_KEY_EO_RESOURCES_AVAILBLE" )
		end

		-- Basic explanation

		if g_isBasicHelp then
			insert( tips, "" )
			insert( tips, L( format("TXT_KEY_TP_%s_EXPLANATION", g_currencyString) ) )
		end

		return concat( tips, "[NEWLINE]" )
	end,
	GpIcon = function()
		local gp = ScanGP( Players[ GetActivePlayer() ] )
		if gp then
			local icon = GreatPeopleIcons and GreatPeopleIcons[ gp.Class.Type ] or "[ICON_GREAT_PEOPLE]"
			return L( "TXT_KEY_PROGRESS_TOWARDS", "[COLOR_YIELD_FOOD]" .. Locale.ToUpper( gp.Class._Name ) .. "[ENDCOLOR]" )
				.. " " .. gp.Progress .. icon .. " / " .. gp.Threshold .. icon .. "[NEWLINE]"
				.. gp.City:GetName() .. format( " %+g", gp.Change ) .. icon .. " " .. L"TXT_KEY_GOLD_PERTURN_HEADING4_TITLE"
				.. " [COLOR_YIELD_FOOD]" .. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", gp.Turns ) ) .. "[ENDCOLOR]"
		else
			return "No Great Person found..."
		end
	end,
	-------------------------------------------------
	-- Happiness Tooltip
	-------------------------------------------------
	HappinessString = function()

		if g_isHappinessEnabled then
			local activePlayerID = GetActivePlayer()
			local activeTeamID = GetActiveTeam()
			local activePlayer = Players[activePlayerID]
			local activeTeam = Teams[activeTeamID]

			local tips = {}

			local excessHappiness = activePlayer:GetExcessHappiness()

			if not activePlayer:IsEmpireUnhappy() then
				insert( tips, L("TXT_KEY_TP_TOTAL_HAPPINESS", excessHappiness) )
			elseif activePlayer:IsEmpireVeryUnhappy() then
				insert( tips, L("TXT_KEY_TP_TOTAL_UNHAPPINESS", "[ICON_HAPPINESS_4]", -excessHappiness) )
			else
				insert( tips, L("TXT_KEY_TP_TOTAL_UNHAPPINESS", "[ICON_HAPPINESS_3]", -excessHappiness) )
			end

			local policiesHappiness = activePlayer:GetHappinessFromPolicies()
			local resourcesHappiness = activePlayer:GetHappinessFromResources()
			local happinessFromExtraResources = activePlayer:GetHappinessFromResourceVariety()
			local extraLuxuryHappiness = activePlayer:GetExtraHappinessPerLuxury()
			local buildingHappiness = activePlayer:GetHappinessFromBuildings()

			local cityHappiness = 0
			local garrisonedUnitsHappiness = 0
			local minorCivHappiness = 0
			local religionHappiness = 0
			if IsCiv5notVanilla then
				cityHappiness = activePlayer:GetHappinessFromCities()
				minorCivHappiness = activePlayer:GetHappinessFromMinorCivs()
				religionHappiness = activePlayer:GetHappinessFromReligion()
			else
				garrisonedUnitsHappiness = activePlayer:GetHappinessFromGarrisonedUnits()
				-- Loop through all the Minors the active player knows
				for minorPlayerID = MAX_MAJOR_CIVS, MAX_CIV_PLAYERS_minus1 do
					minorCivHappiness = minorCivHappiness + activePlayer:GetHappinessFromMinor(minorPlayerID)
				end
			end
			local tradeRouteHappiness = activePlayer:GetHappinessFromTradeRoutes()
			local naturalWonderHappiness = activePlayer:GetHappinessFromNaturalWonders()
			local extraHappinessPerCity = activePlayer:GetExtraHappinessPerCity() * activePlayer:GetNumCities()
			local leagueHappiness = IsCiv5BNW_BE and activePlayer:GetHappinessFromLeagues() or 0
			local totalHappiness = activePlayer:GetHappiness()
			local happinessFromVassals = activePlayer.GetHappinessFromVassals and activePlayer:GetHappinessFromVassals() or 0	-- Compatibility with Putmalk's Civ IV Diplomacy Features Mod
			local handicapHappiness = totalHappiness - policiesHappiness - resourcesHappiness - cityHappiness - buildingHappiness - garrisonedUnitsHappiness - minorCivHappiness - tradeRouteHappiness - religionHappiness - naturalWonderHappiness - extraHappinessPerCity - leagueHappiness - happinessFromVassals	-- Compatibility with Putmalk's Civ IV Diplomacy Features Mod

			if activePlayer:IsEmpireVeryUnhappy() then

				if activePlayer:IsEmpireSuperUnhappy() then
					insert( tips, "[COLOR:255:60:60:255]" .. L"TXT_KEY_TP_EMPIRE_SUPER_UNHAPPY" .. "[ENDCOLOR]" )
				else
					insert( tips, "[COLOR:255:60:60:255]" .. L"TXT_KEY_TP_EMPIRE_VERY_UNHAPPY" .. "[ENDCOLOR]" )
				end
			elseif activePlayer:IsEmpireUnhappy() then

				insert( tips, "[COLOR:255:60:60:255]" .. L"TXT_KEY_TP_EMPIRE_UNHAPPY" .. "[ENDCOLOR]" )
			end
			-- Basic explanation of Happiness

			if g_isBasicHelp then
				insert( tips, L"TXT_KEY_TP_HAPPINESS_EXPLANATION" )
				insert( tips, "" )
			end

			-- Individual Resource Info

			local baseHappinessFromResources = 0
			local numHappinessResources = 0
			local availableResources = ""
			local missingResources = ""
			local Resources = GameInfo.Resources
			local luxuries = { ResourceUsage = RESOURCEUSAGE_LUXURY }

			for resource in Resources( luxuries ) do
				local resourceID = resource.ID

				local numResourceAvailable = activePlayer:GetNumResourceAvailable(resource.ID, true)
				if numResourceAvailable > 0 then
					local resourceHappiness = IsCiv5notVanilla and activePlayer:GetHappinessFromLuxury( resourceID ) or resource.Happiness	-- GetHappinessFromLuxury includes extra happiness
					if resourceHappiness > 0 then
						availableResources = availableResources
							.. " [COLOR_POSITIVE_TEXT]"
							.. numResourceAvailable
							.. "[ENDCOLOR]"
							.. resource.IconString
						numHappinessResources = numHappinessResources + 1
						baseHappinessFromResources = baseHappinessFromResources + resourceHappiness
					end
				elseif numResourceAvailable == 0 then
					missingResources = missingResources .. resource.IconString
				else
					missingResources = missingResources
						.. " [COLOR_WARNING_TEXT]"
						.. numResourceAvailable
						.. "[ENDCOLOR]"
						.. resource.IconString
				end
			end

			--------------
			-- Unhappiness
			local unhappinessFromPupetCities = activePlayer:GetUnhappinessFromPuppetCityPopulation()
			local unhappinessFromSpecialists = activePlayer:GetUnhappinessFromCitySpecialists()
			local unhappinessFromPop = activePlayer:GetUnhappinessFromCityPopulation() - unhappinessFromSpecialists - unhappinessFromPupetCities

			insert( tips, "[COLOR:255:150:150:255]" .. L( "TXT_KEY_TP_UNHAPPINESS_TOTAL", activePlayer:GetUnhappiness() ) )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_CITY_COUNT", activePlayer:GetUnhappinessFromCityCount() / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_CAPTURED_CITY_COUNT", activePlayer:GetUnhappinessFromCapturedCityCount() / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_POPULATION", unhappinessFromPop / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_PUPPET_CITIES", unhappinessFromPupetCities / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_SPECIALISTS", unhappinessFromSpecialists / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_OCCUPIED_POPULATION", activePlayer:GetUnhappinessFromOccupiedCities() / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_UNITS", activePlayer:GetUnhappinessFromUnits() / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_POLICIES", min(policiesHappiness,0) )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHAPPINESS_PUBLIC_OPINION", IsCiv5BNW_BE and activePlayer:GetUnhappinessFromPublicOpinion() or 0 )

			------------
			-- Happiness
			insert( tips, "[ENDCOLOR][COLOR:150:255:150:255]" )
			insert( tips, L("TXT_KEY_TP_HAPPINESS_SOURCES", totalHappiness ) )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_DIFFICULTY_LEVEL", handicapHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_POLICIES", max(policiesHappiness,0) )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_BUILDINGS", buildingHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_CITIES", cityHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_GARRISONED_UNITS", garrisonedUnitsHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_CONNECTED_CITIES", tradeRouteHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_STATE_RELIGION", religionHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_NATURAL_WONDERS", naturalWonderHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_CITY_COUNT", extraHappinessPerCity )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_CITY_STATE_FRIENDSHIP", minorCivHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_LEAGUES", leagueHappiness )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HAPPINESS_VASSALS", happinessFromVassals )	-- Compatibility with Putmalk's Civ IV Diplomacy Features Mod

			-- Happiness from Luxury Variety
			insertLocalizedBulletIfNonZero( tips, "          ", "TXT_KEY_TP_HAPPINESS_RESOURCE_VARIETY", happinessFromExtraResources )

			-- Extra Happiness from each Luxury
			insertLocalizedBulletIfNonZero( tips, "          ", "TXT_KEY_TP_HAPPINESS_EXTRA_PER_RESOURCE", extraLuxuryHappiness, numHappinessResources )

			-- Misc Happiness from Resources
			local miscHappiness = resourcesHappiness - baseHappinessFromResources - happinessFromExtraResources - (extraLuxuryHappiness * numHappinessResources)
			insertLocalizedBulletIfNonZero( tips, "          ", "TXT_KEY_TP_HAPPINESS_OTHER_SOURCES", miscHappiness )

			if #availableResources > 0 then
				insert( tips, "[ICON_BULLET]" .. L( "TXT_KEY_TP_HAPPINESS_FROM_RESOURCES", resourcesHappiness ) )
				insert( tips, "  " .. availableResources )
			end

			insert( tips, "[ENDCOLOR]" )


			----------------------------
			-- Local Resources in Cities
			local tip = ""
			for resource in Resources( luxuries ) do
				local resourceID = resource.ID
				local quantity = activePlayer:GetNumResourceTotal( resourceID, false ) + activePlayer:GetResourceExport( resourceID )
				if quantity > 0 then
					tip = tip .. " " .. ColorizeAbs( quantity ) .. resource.IconString
				end
			end
			insert( tips, L"TXT_KEY_EO_LOCAL_RESOURCES" .. (#tip > 0 and tip or (" : "..L"TXT_KEY_TP_NO_RESOURCES_DISCOVERED")) )

			----------------------------
			-- Resources from city terrain
			for city in activePlayer:Cities() do
				local numConnectedResource = {}
				local numUnconnectedResource = {}
				for plot in CityPlots( city ) do
					local resourceID = plot:GetResourceType( activeTeamID )
					local numResource = plot:GetNumResource()
					if numResource > 0
						and GetResourceUsageType( resourceID ) == RESOURCEUSAGE_LUXURY
					then
						if plot:IsCity() or (not plot:IsImprovementPillaged() and plot:IsResourceConnectedByImprovement( plot:GetImprovementType() )) then
							numConnectedResource[resourceID] = (numConnectedResource[resourceID] or 0) + numResource
						else
							numUnconnectedResource[resourceID] = (numUnconnectedResource[resourceID] or 0) + numResource
						end
					end
				end
				local tip = ""
				for resource in Resources( luxuries ) do
					local resourceID = resource.ID
					if (numConnectedResource[resourceID] or 0) > 0 then
						tip = tip .. " " .. ColorizeAbs( numConnectedResource[resourceID] ) .. resource.IconString
					end
					if (numUnconnectedResource[resourceID] or 0) > 0 then
						tip = tip .. " " .. ColorizeAbs( -numUnconnectedResource[resourceID] ) .. resource.IconString
					end
				end
				if #tip > 0 then
					insert( tips, "[ICON_BULLET]" .. city:GetName() .. tip )
				end
			end

			----------------------------
			-- Import & Export Breakdown
			local itemType, duration, finalTurn, data1, data2, data3, flag1, fromPlayerID
			local gameTurn = Game.GetGameTurn()-1
			local Exports = {}
			local Imports = {}
			for playerID = 0, MAX_MAJOR_CIVS-1 do
				Exports[ playerID ] = {}
				Imports[ playerID ] = {}
			end
			PushScratchDeal()
			for i = 0, UI.GetNumCurrentDeals( activePlayerID ) - 1 do
				UI.LoadCurrentDeal( activePlayerID, i )
				local otherPlayerID = ScratchDeal:GetOtherPlayer( activePlayerID )
				ScratchDeal:ResetIterator()
				repeat
					if IsCiv5BNW_BE then
						itemType, duration, finalTurn, data1, data2, data3, flag1, fromPlayerID = ScratchDeal:GetNextItem()
					else
						itemType, duration, finalTurn, data1, data2, fromPlayerID = ScratchDeal:GetNextItem()
					end
					-- data1 is resourceID, data2 is quantity

					if data2 and itemType == TRADE_ITEM_RESOURCES and GetResourceUsageType( data1 ) == RESOURCEUSAGE_LUXURY then
						local trade
						if fromPlayerID == activePlayerID then
							trade = Exports[otherPlayerID]
						else
							trade = Imports[fromPlayerID]
						end
						local resourceTrade = trade[ data1 ]
						if not resourceTrade then
							resourceTrade = {}
							trade[ data1 ] = resourceTrade
						end
						resourceTrade[finalTurn] = (resourceTrade[finalTurn] or 0) + data2
					end
				until not itemType
			end
			PopScratchDeal()

			----------------------------
			-- Imports
			local tip = ""
			for resource in Resources( luxuries ) do
				local resourceID = resource.ID
				local quantity = activePlayer:GetResourceImport( resourceID ) + activePlayer:GetResourceFromMinors( resourceID )
				if quantity > 0 then
					tip = tip .. " " .. ColorizeAbs( quantity ) .. resource.IconString
				end
			end
			if #tip > 0 then
				insert( tips, "" )
				insert( tips, L"TXT_KEY_RESOURCES_IMPORTED" .. tip )
				for playerID, array in pairs( Imports ) do
					local tip = ""
					for resourceID, row in pairs( array ) do
						for turn, quantity in pairs(row) do
							if quantity > 0 then
								tip = tip .. " " .. quantity .. Resources[ resourceID ].IconString .. "(" .. turn - gameTurn .. ")"
							end
						end
					end
					if #tip > 0 then
						insert( tips, "[ICON_BULLET]" .. Players[ playerID ]:GetCivilizationShortDescription() .. tip )
					end
				end
				for minorID = MAX_MAJOR_CIVS, MAX_CIV_PLAYERS_minus1 do
					local minor = Players[ minorID ]
					if minor and minor:IsAlive() and minor:GetAlly() == activePlayerID then
						local tip = ""
						for resource in Resources( luxuries ) do
							local quantity = minor:GetResourceExport(resource.ID)
							if quantity > 0 then
								tip = tip .. " " .. quantity .. resource.IconString
							end
						end
						if #tip > 0 then
							insert( tips, "[ICON_BULLET]" .. minor:GetCivilizationShortDescription() .. tip )
						end
					end
				end
			end

			----------------------------
			-- Exports
			local tip = ""
			for resource in Resources( luxuries ) do
				local resourceID = resource.ID
				local quantity = activePlayer:GetResourceExport( resourceID )
				if quantity > 0 then
					tip = tip .. " " .. ColorizeAbs( quantity ) .. resource.IconString
				end
			end
			if #tip > 0 then
				insert( tips, "" )
				insert( tips, L"TXT_KEY_RESOURCES_EXPORTED" .. tip )
				for playerID, array in pairs( Exports ) do
					local tip = ""
					for resourceID, row in pairs( array ) do
						for turn, quantity in pairs( row ) do
							if quantity > 0 then
								tip = tip .. " " .. quantity .. Resources[ resourceID ].IconString .. "(" .. turn - gameTurn .. ")"
							end
						end
					end
					if #tip > 0 then
						insert( tips, "[ICON_BULLET]" .. Players[ playerID ]:GetCivilizationShortDescription() .. tip )
					end
				end
			end
			-- show resources available for trade to the active player

--			insert( tips, L"TXT_KEY_DIPLO_ITEMS_LUXURY_RESOURCES" )
--			insert( tips, missingResources )
			insert( tips, "" )
			insert( tips, L"TXT_KEY_EO_RESOURCES_AVAILBLE" )

			----------------------------
			-- Available for Import
			for resource in Resources( luxuries ) do
				local resourceID = resource.ID
				local resources = {}
				for playerID = 0, MAX_CIV_PLAYERS_minus1 do

					local player = Players[playerID]
					local isMinorCiv = player:IsMinorCiv()

					-- Valid player? - Can't be us, has to be alive and met, can't be allied city state
					if playerID ~= activePlayerID
						and player:IsAlive()
						and activeTeam:IsHasMet( player:GetTeam() )
						and not (isMinorCiv and player:IsAllies( activePlayerID ))
					then


						local numResource = ( isMinorCiv and player:GetNumResourceTotal(resourceID, false) + player:GetResourceExport( resourceID ) )
							or ( ScratchDeal:IsPossibleToTradeItem( playerID, activePlayerID, TRADE_ITEM_RESOURCES, resourceID, 1 ) and player:GetNumResourceAvailable(resourceID, false) )
							or 0
						if numResource > 0 then
							insert( resources, player:GetCivilizationShortDescription() .. " " .. numResource .. resource.IconString )
						end
					end
				end
				if #resources > 0 then
					insert( tips, "[ICON_BULLET]" .. resource._Name .. ": " .. concat( resources, ", " ) )
				end
			end

			return concat( tips, "[NEWLINE]" )
		else
			return L"TXT_KEY_TOP_PANEL_HAPPINESS_OFF_TOOLTIP"
		end
	end,
	-------------------------------------------------
	-- Golden Age Tooltip
	-------------------------------------------------
	GoldenAgeString = function()

		if g_isHappinessEnabled then

			local activePlayerID = GetActivePlayer()
			local activePlayer = Players[activePlayerID]

			local tips = {}
			local goldenAgeTurns = activePlayer:GetGoldenAgeTurns()
			local happyProgress = activePlayer:GetGoldenAgeProgressMeter()
			local happyNeeded = activePlayer:GetGoldenAgeProgressThreshold()

			if goldenAgeTurns > 0 then
				if IsCiv5BNW and activePlayer:GetGoldenAgeTourismModifier() > 0 then
					insert( tips, Locale.ToUpper"TXT_KEY_UNIQUE_GOLDEN_AGE_ANNOUNCE" )
				else
					insert( tips, Locale.ToUpper"TXT_KEY_GOLDEN_AGE_ANNOUNCE" )
				end
				insert( tips, L( "TXT_KEY_TP_GOLDEN_AGE_NOW", goldenAgeTurns ) )
			else
				local excessHappiness = activePlayer:GetExcessHappiness()
				insert( tips, L( "TXT_KEY_PROGRESS_TOWARDS", "[COLOR_YELLOW]"
					.. Locale.ToUpper( "TXT_KEY_SPECIALISTSANDGP_GOLDENAGE_HEADING4_TITLE" )
					.. "[ENDCOLOR]" ) .. " " .. happyProgress .. " / " .. happyNeeded )
				if excessHappiness > 0 then
					insert( tips, L"TXT_KEY_MISSION_START_GOLDENAGE" .. ": [COLOR_YELLOW]"
						.. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", ceil((happyNeeded - happyProgress) / excessHappiness) ) )
						.. "[ENDCOLOR]"	.. "[NEWLINE][NEWLINE]" .. L("TXT_KEY_TP_GOLDEN_AGE_ADDITION", excessHappiness) )
				elseif excessHappiness < 0 then
					insert( tips, "[COLOR_WARNING_TEXT]" .. L("TXT_KEY_TP_GOLDEN_AGE_LOSS", -excessHappiness) .. "[ENDCOLOR]" )
				end
			end

			if g_isBasicHelp then
				insert( tips, "" )
				if IsCiv5notVanilla and activePlayer:IsGoldenAgeCultureBonusDisabled() then
					insert( tips, L"TXT_KEY_TP_GOLDEN_AGE_EFFECT_NO_CULTURE" )
				else
					insert( tips, L"TXT_KEY_TP_GOLDEN_AGE_EFFECT" )
				end
				if IsCiv5BNW and activePlayer:GetGoldenAgeTurns() > 0 and activePlayer:GetGoldenAgeTourismModifier() > 0 then
					insert( tips, "" )
					insert( tips, L"TXT_KEY_TP_CARNIVAL_EFFECT" )
				end
			end

			return concat( tips, "[NEWLINE]" )
		else
			return L"TXT_KEY_TOP_PANEL_HAPPINESS_OFF_TOOLTIP"
		end
	end,
	-------------------------------------------------
	-- Culture Tooltip
	-------------------------------------------------
	CultureString = function()
		if g_isPoliciesEnabled then
			local activePlayerID = GetActivePlayer()
			local activePlayer = Players[activePlayerID]

			local tips = {}
			local turnsRemaining = 1
			local cultureProgress, culturePerTurn, culturePerTurnForFree, culturePerTurnFromCities, culturePerTurnFromExcessHappiness, culturePerTurnFromTraits
			-- Firaxis Cleverness...
			if IsCiv5 then
				cultureProgress = activePlayer:GetJONSCulture()
				culturePerTurn = activePlayer:GetTotalJONSCulturePerTurn()
				culturePerTurnForFree = activePlayer:GetJONSCulturePerTurnForFree()
				culturePerTurnFromCities = activePlayer:GetJONSCulturePerTurnFromCities()
				culturePerTurnFromExcessHappiness = activePlayer:GetJONSCulturePerTurnFromExcessHappiness()
				culturePerTurnFromTraits = IsCiv5BNW and activePlayer:GetJONSCulturePerTurnFromTraits() or 0
			else
				cultureProgress = activePlayer:GetCulture()
				culturePerTurn = activePlayer:GetTotalCulturePerTurn()
				culturePerTurnForFree = activePlayer:GetCulturePerTurnForFree()
				culturePerTurnFromCities = activePlayer:GetCulturePerTurnFromCities()
				culturePerTurnFromExcessHappiness = activePlayer:GetCulturePerTurnFromExcessHealth()
				culturePerTurnFromTraits = activePlayer:GetCulturePerTurnFromTraits()
			end
			local cultureTheshold = activePlayer:GetNextPolicyCost()
			if cultureTheshold > cultureProgress then
				if culturePerTurn > 0 then
					turnsRemaining = ceil( (cultureTheshold - cultureProgress) / culturePerTurn)
				else
					turnsRemaining = "?"
				end
			end

			if IsCiv5BNW_BE and activePlayer:IsAnarchy() then
				insert( tips, L("TXT_KEY_TP_ANARCHY", activePlayer:GetAnarchyNumTurns()) )
				insert( tips, "" )
			end

			insert( tips, L( "TXT_KEY_PROGRESS_TOWARDS", "[COLOR_MAGENTA]" .. Locale.ToUpper"TXT_KEY_ADVISOR_SCREEN_SOCIAL_POLICY_DISPLAY" .. "[ENDCOLOR]" )
					.. " " .. cultureProgress .. "[ICON_CULTURE]/ " .. cultureTheshold .. "[ICON_CULTURE]" )

			if culturePerTurn > 0 then
				local cultureOverflow = culturePerTurn * turnsRemaining + cultureProgress - cultureTheshold
				local tip = "[COLOR_MAGENTA]" .. Locale.ToUpper( L( "TXT_KEY_STR_TURNS", turnsRemaining ) )
						.. "[ENDCOLOR]"	.. format( " %+g[ICON_CULTURE]", cultureOverflow )
				if turnsRemaining > 1 then
					tip = L( "TXT_KEY_STR_TURNS", turnsRemaining -1 )
						.. format( " %+g[ICON_CULTURE]  ", cultureOverflow - culturePerTurn )
						.. tip
				end
				insert( tips, tip )
			end

			insert( tips, "" )
			insert( tips, "[COLOR_MAGENTA]" .. format( "%+g", culturePerTurn )
					.. "[ENDCOLOR] " .. L"TXT_KEY_REPLAY_DATA_CULTUREPERTURN" )

			-- Culture for Free
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FOR_FREE", culturePerTurnForFree )

			-- Culture from Cities
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_CITIES", culturePerTurnFromCities )

			-- Culture from Excess Happiness / Health
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_" .. g_happinessString, culturePerTurnFromExcessHappiness )

			-- Culture from Traits
			insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_TRAITS", culturePerTurnFromTraits )

			if IsCiv5 then
				-- Culture from Minor Civs
				local culturePerTurnFromMinorCivs = activePlayer:GetJONSCulturePerTurnFromMinorCivs()
				insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_MINORS", culturePerTurnFromMinorCivs )

				-- Culture from Religion
				local culturePerTurnFromReligion = IsCiv5notVanilla and activePlayer:GetCulturePerTurnFromReligion() or 0
				insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_RELIGION", culturePerTurnFromReligion )

				-- Culture from bonus turns (League Project)
				local culturePerTurnFromBonusTurns = 0
				if IsCiv5BNW then
					culturePerTurnFromBonusTurns = activePlayer:GetCulturePerTurnFromBonusTurns()
					insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_BONUS_TURNS", culturePerTurnFromBonusTurns, activePlayer:GetCultureBonusTurns() )
				end

				-- Culture from Vassals / Compatibility with Putmalk's Civ IV Diplomacy Features Mod
				local culturePerTurnFromVassals = activePlayer.GetJONSCulturePerTurnFromVassals and activePlayer:GetJONSCulturePerTurnFromVassals() or 0
				insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_VASSALS", culturePerTurnFromVassals )

				-- Culture from Golden Age
				insertLocalizedIfNonZero( tips, "TXT_KEY_TP_CULTURE_FROM_GOLDEN_AGE", culturePerTurn - culturePerTurnForFree - culturePerTurnFromCities - culturePerTurnFromExcessHappiness - culturePerTurnFromMinorCivs - culturePerTurnFromReligion - culturePerTurnFromTraits - culturePerTurnFromBonusTurns - culturePerTurnFromVassals )	-- Compatibility with Putmalk's Civ IV Diplomacy Features Mod
			else
				-- Uncategorized Culture
				insertLocalizedIfNonZero( tips, "TXT_KEY_TP_YIELD_FROM_UNCATEGORIZED", culturePerTurn - culturePerTurnForFree - culturePerTurnFromCities - culturePerTurnFromExcessHappiness - culturePerTurnFromTraits )
			end

			-- Let people know that building more cities makes policies harder to get

			if g_isBasicHelp then
				insert( tips, "" )
				insert( tips, L("TXT_KEY_TP_CULTURE_CITY_COST", Game.GetNumCitiesPolicyCostMod() * ( 100 + ( IsCivBE and activePlayer:GetNumCitiesPolicyCostDiscount() or 0 ) ) / 100 ) )
			end
			return concat( tips, "[NEWLINE]" )
		else
			return L"TXT_KEY_TOP_PANEL_POLICIES_OFF_TOOLTIP"
		end
	end,
	FaithString = FaithTooltip,
	FaithIcon = FaithTooltip,
	-------------------------------------------------
	-- Tourism Tooltip (BNW)
	-------------------------------------------------
	TourismString = function()
		local activePlayerID = GetActivePlayer()
		local activePlayer = Players[activePlayerID]

		local totalGreatWorks = activePlayer:GetNumGreatWorks()
		local totalSlots = activePlayer:GetNumGreatWorkSlots()

		local tipText = L( "TXT_KEY_TOP_PANEL_TOURISM_TOOLTIP_1", totalGreatWorks )
				.. "[NEWLINE]"
				.. L( "TXT_KEY_TOP_PANEL_TOURISM_TOOLTIP_2", totalSlots - totalGreatWorks )

		local cultureVictory = GameInfo.Victories.VICTORY_CULTURAL
		if cultureVictory and PreGame.IsVictory(cultureVictory.ID) then
			local numInfluential = activePlayer:GetNumCivsInfluentialOn()
			local numToBeInfluential = activePlayer:GetNumCivsToBeInfluentialOn()
			tipText = tipText .. "[NEWLINE][NEWLINE]"
				.. L( "TXT_KEY_TOP_PANEL_TOURISM_TOOLTIP_3", L("TXT_KEY_CO_VICTORY_INFLUENTIAL_OF", numInfluential, numToBeInfluential) )
		end
		return tipText
	end,
	-------------------------------------------------
	-- International Trade Routes Tooltip (BNW)
	-------------------------------------------------
	InternationalTradeRoutes = function()
		local activePlayerID = GetActivePlayer()
		local activePlayer = Players[activePlayerID]

		local tipText = ""

		local numAvailableTradeUnits = activePlayer:GetNumAvailableTradeUnits(DomainTypes.DOMAIN_LAND)
		if numAvailableTradeUnits > 0 then
			local tradeUnitType = activePlayer:GetTradeUnitType(DomainTypes.DOMAIN_LAND)
			tipText = tipText .. L("TXT_KEY_TOP_PANEL_INTERNATIONAL_TRADE_ROUTES_TT_UNASSIGNED", numAvailableTradeUnits, GameInfo.Units[ tradeUnitType ]._Name) .. "[NEWLINE]"
		end

		local numAvailableTradeUnits = activePlayer:GetNumAvailableTradeUnits(DomainTypes.DOMAIN_SEA)
		if numAvailableTradeUnits > 0 then
			local tradeUnitType = activePlayer:GetTradeUnitType(DomainTypes.DOMAIN_SEA)
			tipText = tipText .. L("TXT_KEY_TOP_PANEL_INTERNATIONAL_TRADE_ROUTES_TT_UNASSIGNED", numAvailableTradeUnits, GameInfo.Units[ tradeUnitType ]._Name) .. "[NEWLINE]"
		end

		local usedTradeRoutes = activePlayer:GetNumInternationalTradeRoutesUsed()
		local availableTradeRoutes = activePlayer:GetNumInternationalTradeRoutesAvailable()

		if #tipText > 0 then
			tipText = tipText .. "[NEWLINE]"
		end
		tipText = L("TXT_KEY_TOP_PANEL_INTERNATIONAL_TRADE_ROUTES_TT", usedTradeRoutes, availableTradeRoutes)

		local strYourTradeRoutes = activePlayer:GetTradeYourRoutesTTString()
		if #strYourTradeRoutes > 0 then
			tipText = tipText .. "[NEWLINE][NEWLINE]"
					.. L"TXT_KEY_TOP_PANEL_ITR_ESTABLISHED_BY_PLAYER_TT"
					.. "[NEWLINE]"
					.. strYourTradeRoutes
		end

		local strToYouTradeRoutes = activePlayer:GetTradeToYouRoutesTTString()
		if #strToYouTradeRoutes > 0 then
			tipText = tipText .. "[NEWLINE][NEWLINE]"
					.. L"TXT_KEY_TOP_PANEL_ITR_ESTABLISHED_BY_OTHER_TT"
					.. "[NEWLINE]"
					.. strToYouTradeRoutes
		end

		return tipText
	end,
	-------------------------------------------------
	-- Health Tooltip (CivBE)
	-------------------------------------------------
	HealthString = function()
		if g_isHealthEnabled then
			local activePlayerID = GetActivePlayer()
			local activePlayer = Players[activePlayerID]

			local excessHealth = activePlayer:GetExcessHealth()
			local healthLevel = activePlayer:GetCurrentHealthLevel()
			local healthLevelInfo = GameInfo.HealthLevels[healthLevel]
			local colorPrefixText = "[COLOR_GREEN]"
			local iconStringText = "[ICON_HEALTH]"
			local rangeFactor = 1
			if excessHealth < 0 then
				colorPrefixText = "[COLOR_RED]"
				iconStringText = "[ICON_UNHEALTH]"
				rangeFactor = -1
			end
			local tips = { L("TXT_KEY_TP_HEALTH_SUMMARY", iconStringText, colorPrefixText, excessHealth * rangeFactor) }
			if healthLevelInfo.Help then
				insert( tips, L( healthLevelInfo.Help ) )
			end
			insert( tips, activePlayer:IsEmpireUnhealthy() and "[COLOR_WARNING_TEXT]" or "[COLOR_POSITIVE_TEXT]" )
			local cityYieldMods = {}
			local combatMod = 0
			local cityGrowthMod = 0
			local outpostGrowthMod = 0
			local cityIntrigueMod = 0
			for info in GameInfo.HealthLevels() do
				local healthLevelID = info.ID
				if activePlayer:IsAffectedByHealthLevel(healthLevelID) then
					for yieldID = 0, YieldTypes.NUM_YIELD_TYPES-1 do
						cityYieldMods[yieldID] = (cityYieldMods[yieldID] or 0) + Game.GetHealthLevelCityYieldModifier(healthLevelID, excessHealth, yieldID)
					end
					combatMod = combatMod + (info.CombatModifier or 0)
					cityGrowthMod = cityGrowthMod + Game.GetHealthLevelCityGrowthModifier(healthLevelID, excessHealth)
					outpostGrowthMod = outpostGrowthMod + Game.GetHealthLevelCityGrowthModifier(healthLevelID, excessHealth)
					cityIntrigueMod = cityIntrigueMod + Game.GetHealthLevelCityIntrigueModifier(healthLevelID, excessHealth)
				end
			end
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_LEVEL_EFFECT_COMBAT_MODIFIER", combatMod )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_LEVEL_EFFECT_CITY_GROWTH_MODIFIER", cityGrowthMod )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_LEVEL_EFFECT_OUTPOST_GROWTH_MODIFIER", outpostGrowthMod )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_LEVEL_EFFECT_CITY_INTRIGUE_MODIFIER", cityIntrigueMod )
			for yieldID = 0, YieldTypes.NUM_YIELD_TYPES-1 do
				local yieldInfo = GameInfo.Yields[ yieldID ]
				insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_LEVEL_EFFECT_CITY_YIELD_MODIFIER", yieldInfo and cityYieldMods[yieldID] or 0, yieldInfo.IconString, yieldInfo._Name )
			end
--			insert( tips, "[ENDCOLOR]" )

			--*** HEALTH Breakdown ***--
			local totalHealth		= activePlayer:GetHealth()
			local handicapInfo		= GameInfo.HandicapInfos[activePlayer:GetHandicapType()]
			local handicapHealth		= handicapInfo.BaseHealthRate
			local healthFromCities		= activePlayer:GetHealthFromCities()
			local extraCityHealth		= activePlayer:GetExtraHealthPerCity() * activePlayer:GetNumCities()
			local healthFromPolicies	= activePlayer:GetHealthFromPolicies()
			local healthFromTradeRoutes	= activePlayer:GetHealthFromTradeRoutes()
			--local healthFromNationalSecurityProject	= activePlayer:GetHealthFromNationalSecurityProject(); WRM: Add this in when we have a text string for it

			insert( tips, "[COLOR_WHITE]" )
			insert( tips, L( "TXT_KEY_TP_HEALTH_SOURCES", totalHealth ) )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_CITIES", healthFromCities )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_POLICIES", healthFromPolicies )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_CONNECTED_CITIES", healthFromTradeRoutes )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_CITY_COUNT", extraCityHealth )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_DIFFICULTY_LEVEL", handicapHealth )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_HEALTH_OTHER_SOURCES", totalHealth - handicapHealth - healthFromPolicies - healthFromCities - healthFromTradeRoutes - extraCityHealth )
			insert( tips, "[ENDCOLOR]" )

			--*** UNHEALTH Breakdown ***--
			local totalUnhealth			= activePlayer:GetUnhealth()
			local unhealthFromCities		= activePlayer:GetUnhealthFromCities()
			local unhealthFromUnits			= activePlayer:GetUnhealthFromUnits()
			local unhealthFromCityCount		= activePlayer:GetUnhealthFromCityCount()
			local unhealthFromConqueredCityCount	= activePlayer:GetUnhealthFromConqueredCityCount()
			local unhealthFromPupetCities		= activePlayer:GetUnhealthFromPuppetCityPopulation()
			local unhealthFromSpecialists		= activePlayer:GetUnhealthFromCitySpecialists()
			local unhealthFromPop			= activePlayer:GetUnhealthFromCityPopulation() - unhealthFromSpecialists - unhealthFromPupetCities
			local unhealthFromConqueredCities	= activePlayer:GetUnhealthFromConqueredCities()

			insert( tips, "[COLOR:255:150:150:255]" )
			insert( tips, L( "TXT_KEY_TP_UNHEALTH_TOTAL", totalUnhealth ) )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_CITIES", unhealthFromCities / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_CITY_COUNT", unhealthFromCityCount / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_CAPTURED_CITY_COUNT", unhealthFromConqueredCityCount / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_POPULATION", unhealthFromPop / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_PUPPET_CITIES", unhealthFromPupetCities / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_SPECIALISTS", unhealthFromSpecialists / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_OCCUPIED_POPULATION", unhealthFromConqueredCities / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_UNITS", unhealthFromUnits / 100 )
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_YIELD_FROM_UNCATEGORIZED", totalUnhealth - ( unhealthFromCities + unhealthFromCityCount + unhealthFromConqueredCityCount + unhealthFromPop + unhealthFromPupetCities + unhealthFromSpecialists + unhealthFromConqueredCities + unhealthFromUnits ) / 100 )
			insert( tips, "[ENDCOLOR]" )

			-- Overall Unhealth Mod
			local unhealthMod = activePlayer:GetUnhealthMod()
			if unhealthMod > 0 then -- Positive mod means more Unhealth - this is a bad thing!
				append( tips, "[COLOR:255:150:150:255]" )
			end
			insertLocalizedBulletIfNonZero( tips, "TXT_KEY_TP_UNHEALTH_MOD", unhealthMod )

			-- Basic explanation of Health
			insert( tips, "[ENDCOLOR]" )
			insert( tips, L( "TXT_KEY_TP_HEALTH_EXPLANATION", totalUnhealth ) )

			return concat( tips, "[NEWLINE]" )
		else
			return L"TXT_KEY_TOP_PANEL_HEALTH_OFF_TOOLTIP"
		end
	end,
	-------------------------------------------------
	-- Affinity Tooltips (CivBE)
	-------------------------------------------------
	Harmony = function() return GetHelpTextForAffinity( GameInfoTypes.AFFINITY_TYPE_HARMONY, Players[GetActivePlayer()] ) end,
	Purity = function() return GetHelpTextForAffinity( GameInfoTypes.AFFINITY_TYPE_PURITY, Players[GetActivePlayer()] ) end,
	Supremacy = function() return GetHelpTextForAffinity( GameInfoTypes.AFFINITY_TYPE_SUPREMACY, Players[GetActivePlayer()] ) end,
}

LuaEvents.TopPanelTooltips.Add( function( control )
	local toolTip = TooltipSelect( TopPanelTooltips, control )
	return toolTip and ShowTextToolTip( toolTip )
end)

print( "EUI tooltip server loaded." )
