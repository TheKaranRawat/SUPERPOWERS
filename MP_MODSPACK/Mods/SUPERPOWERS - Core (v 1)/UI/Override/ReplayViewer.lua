--==========================================================
-- Re-written by bc1 using Notepad++
--==========================================================

do

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfo = GameInfoCache or GameInfo

include "IconHookup"
local IconHookup = IconHookup

include "GameCalendarUtilities.lua"
local GetShortDateString = GetShortDateString

include "StackInstanceManager"

--==========================================================
-- Minor lua optimizations
--==========================================================

local collectgarbage = collectgarbage
local ipairs = ipairs
local math = math
local next = next
local pairs = pairs
local print = print
local concat = table.concat
local insert = table.insert
local tostring = tostring

local ContextPtr = ContextPtr
local Controls = Controls
local Game = Game
local MAX_CIV_PLAYERS = GameDefines.MAX_CIV_PLAYERS
--local LocaleCompare = Locale.Compare
local L = Locale.Lookup
local Map = Map
local Mouse = Mouse
local Players = Players
local Teams = Teams
local UI = UI
local UIManager = UIManager

--==========================================================
-- Functions
--==========================================================
----------------
-- RGB : %
-- Hue: degrees
-- Saturation: %
-- Luminance: %
local function RGBtoHSL( r, g, b )
	local minV = math.min(r,g,b)
	local maxV = math.max(r,g,b)
	local l = maxV + minV
	local delta = maxV - minV

	if delta == 0 then
		return 0, 0, l*.5
	else
		local h,s
		if l > 1 then
			s = delta / (2 - l)
		else
			s = delta / l
		end
		if r == maxV then
			h = (g - b)/delta
		elseif g == maxV then
			h = 2 + (b - r)/delta
		elseif b == maxV then
			h = 4 + (r - g)/delta
		end
		return h*60, s, l*.5
	end
end
----------------
-- Hue: degrees
-- Saturation: %
-- Luminance: %
-- RGB : %
local function HSLtoRGB( h, s, l )
	if s == 0 then
		return l, l, l
	end
	local x
	if l < .5 then
		x = l * (1+s)
	else
		x = l + s - l*s
	end
	local y = 2*l - x
	local function f(r)
		r = (r/360)%1
		if 6*r < 1 then
			return y + (x-y)*6*r
		elseif 2*r < 1 then
			return x
		elseif 3*r < 2 then
			return y + (x-y)*(4-6*r)
		else
			return y
		end
	end
	return f(h+120), f(h), f(h-120)
end

local function RGBpack( r, g, b )
	return { Red=r, Green=g, Blue=b, Alpha=1 }
end

local function RGBunpack( color )
	return color.Red, color.Green, color.Blue
end

local function GetInfoType( info )
	return info and info.Type
end

--==========================================================
-- Globals
--==========================================================

local g_ReplayMessageInstanceManager = StackInstanceManager( "ReplayMessageInstance", "Base", Controls.ReplayMessageStack )
local g_GraphLegendInstanceManager = StackInstanceManager( "GraphLegendInstance", "GraphLegend", Controls.GraphLegendStack )
local g_LineSegmentInstanceManager = StackInstanceManager( "GraphLineInstance","LineSegment", Controls.GraphCanvas )
local g_LineSegmentInstanceManager2 = StackInstanceManager( "GraphLineInstance","LineSegment", Controls.GraphCanvas )
local g_LabelInstanceManager = StackInstanceManager( "Label","Label", Controls.GraphCanvas )
local g_LabelInstanceManager2 = StackInstanceManager( "Label","Label", Controls.GraphCanvas )

local g_GraphReplayData = {}
local g_AllPlayerInfo = {}
local g_ReplayMessages, g_PlayerInfo, g_MapPrimaryPlayerColors, g_MapSecondaryPlayerColors, g_MapReplayPlots, g_MapWidth, g_MapHeight, g_InitialTurn, g_FinalTurn, g_StartYear, g_CalendarType, g_GameSpeedType, g_ShowEverything
if Game then
	g_MapWidth, g_MapHeight = Map.GetGridSize()
	g_StartYear = Game.GetStartYear()
	g_InitialTurn = Game.GetStartTurn()
	g_CalendarType = GetInfoType( GameInfo.Calendars[ Game.GetCalendar() ] ) or "CALENDAR_DEFAULT"
	g_GameSpeedType = GetInfoType( GameInfo.GameSpeeds[ Game.GetGameSpeedType() ] ) or "GAMESPEED_STANDARD"
end

local g_ReplayMapTurn
local g_GraphPanelDataSetType = GetInfoType( GameInfo.ReplayDataSets()() )
local g_MessageTypesAllowed = {true, false, true, true, true, true}
--	REPLAY_MESSAGE_MAJOR_EVENT,	REPLAY_MESSAGE_CITY_FOUNDED, REPLAY_MESSAGE_PLOT_OWNER_CHANGE, REPLAY_MESSAGE_CITY_CAPTURED, REPLAY_MESSAGE_CITY_DESTROYED, REPLAY_MESSAGE_RELIGION_FOUNDED, REPLAY_MESSAGE_PANTHEON_FOUNDED
--local g_ColorBlack = {Type = "COLOR_BLACK", Red = 0, Green = 0, Blue = 0, Alpha = 1,}
--local g_ColorWhite = {Type = "COLOR_WHITE", Red = 1, Green = 1, Blue = 1, Alpha = 1,}
local g_CurrentPanelIndex = 1 -- demographics

local g_ReplayInfoPulldown = Controls.ReplayInfoPulldown
local g_ReplayInfoPulldownButton = g_ReplayInfoPulldown:GetButton()

local function DrawReplayMap( percent )
	local currentTurn
	if tonumber(percent) then
		currentTurn = math.floor((g_FinalTurn - g_InitialTurn)*percent) + g_InitialTurn
	else
		currentTurn = g_ReplayMapTurn + 1
	end
	if currentTurn > g_FinalTurn or currentTurn < g_InitialTurn then
		currentTurn = g_InitialTurn
	end
	g_ReplayMapTurn = currentTurn

	local plotOwners = {}
	local plotCities = {}
	local messages = {}
	-- Iterate replay info messages until current turn to determine plot owners and cities
	for _, message in ipairs(g_ReplayMessages) do
		local messageType = message.Type
		if message.Turn >= currentTurn then
			if message.Turn == currentTurn then
				if message.Text~="" and (g_ShowEverything or (g_MessageTypesAllowed[messageType]) and g_PlayerInfo[message.Player]) then
					insert( messages, message.Text )
				end
			else
				break
			end
		end
		if messageType == 1 or	-- REPLAY_MESSAGE_CITY_FOUNDED
			messageType == 3 then -- REPLAY_MESSAGE_CITY_CAPTURED
			for _, plot in pairs( message.Plots ) do
				plotCities[plot.Y * g_MapWidth + plot.X] = message.Player
			end

		elseif messageType == 4 then -- REPLAY_MESSAGE_CITY_DESTROYED
			for _, plot in pairs( message.Plots ) do
				plotCities[plot.Y * g_MapWidth + plot.X] = nil
			end

		elseif messageType == 2 then	-- REPLAY_MESSAGE_PLOT_OWNER_CHANGE
			for _, plot in pairs( message.Plots ) do
				plotOwners[plot.Y * g_MapWidth + plot.X] = message.Player
			end
		end
	end

	--print("Drawing Map at Turn ", currentTurn)
	Controls.TurnMessages:SetText( concat(messages,"[NEWLINE]") )
--			Controls.MapScrollPanel:CalculateInternalSize()
	Controls.TurnLabel:SetText( L("TXT_KEY_TP_TURN_COUNTER", currentTurn) .. "  " .. GetShortDateString(currentTurn, g_CalendarType, g_GameSpeedType, g_StartYear) )
	Controls.TurnSlider:SetValue( (currentTurn - g_InitialTurn)/(g_FinalTurn - g_InitialTurn) )

	local ReplayMap = Controls.ReplayMap
	local SetPlot = ReplayMap.SetPlot

	local _, plot, plotColor, plotTerrainID
	local iceFeatureID = GameInfo.Features.FEATURE_ICE.ID
	local snowTerrainID = GameInfo.Terrains.TERRAIN_SNOW.ID
	local coastTerrainID = GameInfo.Terrains.TERRAIN_COAST.ID
	local oceanTerrainID = GameInfo.Terrains.TERRAIN_OCEAN.ID

	local GetPlotByIndex, GetTerrainType, GetFeatureType, team
	local x1 = 0
	local y1 = 0
	local w = g_MapWidth
	local h = g_MapHeight
	local x2 = w-1
	local y2 = h-1
	local x3, x4
	local IsRevealed = function() return true end
	if Map then
		GetPlotByIndex = Map.GetPlotByIndex
		GetTerrainType = GetPlotByIndex(0).GetTerrainType
		GetFeatureType = GetPlotByIndex(0).GetFeatureType
		team = Game.GetActiveTeam()
		if not g_ShowEverything then
			-- We need to resize the map to the area the player has seen
			IsRevealed = GetPlotByIndex(0).IsRevealed
			local GetPlot = Map.GetPlot
			local player = Players[ Game.GetActivePlayer() ]
			local startPlot = player:GetStartingPlot()
			local rX = {}
			local rY = {}
			x4 = x2
			x1 = startPlot:GetX()
			x2 = x1
			y1 = startPlot:GetY()
			y2 = y1
			-- Project revealed plots along X and Y axis
			for y = 0, g_MapHeight - 1 do
				for x = 0, g_MapWidth - 1 do
					if IsRevealed( GetPlot( x, y ), team ) then
						rX[x] = true
						rY[y] = true
					end
				end
			end
			-- Determine the extent of exploration from starting plot
			-- Do only map X wrap cases... nobody lives on donut planet
			while rX[x1-1] do x1=x1-1 end	-- base case	__███S███__
			while rX[x2+1] do x2=x2+1 end
			w = x2-x1+1
			if x1>1 and rX[0] then			-- wrap case 1	█____███S██
				x3, x4 = 0, 0
				while rX[x4+1] do x4=x4+1 end
				w = w+x4+1
			elseif x2<x4 and rX[x4] then	-- wrap case 2	██S███____█
				x1, x2, x3, x4 = x4, x4, x1, x2
				while rX[x1-1] do x1=x1-1 end
				w = w+x2-x1+1
			end
			while rY[y1-1] do y1=y1-1 end
			while rY[y2+1] do y2=y2+1 end
			h = y2-y1+1
		end
	elseif g_MapReplayPlots then
		GetPlotByIndex = function(idx)
			local _, plot = next( g_MapReplayPlots[idx+1] )
			return plot
		end
		--{ TerrainType, NEOfRiver, WOfRiver, PlotType, FeatureType, NWOfRiver }
		GetTerrainType = function( plot ) return plot.TerrainType end
		GetFeatureType = function( plot ) return plot.FeatureType end
	else
		print("Error: could not find map replay data")
		return
	end
	ReplayMap:SetMapSize(w, h, 0, -1)
	local x, cx1, cx2, cx3
	local bias = y1%2 --adjust for odd starting row
	local idx = (y1-1)*g_MapWidth
	local cityColors = g_MapPrimaryPlayerColors
	local plotColors = g_MapSecondaryPlayerColors
	for y = 0, h-1 do
		x = 0
		idx = idx+g_MapWidth - bias
		bias = -bias
		cx1, cx2, cx3 = x1, x2, x3
		repeat -- once for base case (x3 is nil), twice for wrap cases 1 & 2
			for idx = idx+cx1, idx+cx2 do
				plot = GetPlotByIndex( idx )
				if IsRevealed( plot, team ) then
					plotTerrainID = GetTerrainType( plot )
					-- ice looks like sh*t, change to snow
					if GetFeatureType( plot ) == iceFeatureID then
						plotTerrainID = snowTerrainID
					-- coast is too bright, change to ocean
					elseif plotTerrainID == coastTerrainID then
						plotTerrainID = oceanTerrainID
					end
					-- do we have a city here or does this plot belong to someone
					plotColor = cityColors[plotCities[idx]] or plotColors[plotOwners[idx]]
					if plotColor then
						-- city or plot owner
						SetPlot( ReplayMap, x, y, plotTerrainID, plotColor.Red, plotColor.Green, plotColor.Blue, plotTerrainID == oceanTerrainID and .75 or 1 ) -- dim ocean/coast ownership a bit
					else
						-- vacant unowned plot
						SetPlot( ReplayMap, x, y, plotTerrainID )
					end
				else
					-- unrevealed plot
					SetPlot( ReplayMap, x, y, -1 )
				end
				x = x+1
			end
			-- cx3 is nil'ed so we exit next time
			cx1, cx2, cx3 = cx3, x4
		until not cx1
	end
end
Controls.MapTimer:RegisterAnimCallback( DrawReplayMap )
Controls.TurnSlider:RegisterSliderCallback( DrawReplayMap )

local function DrawGraph()
	local dataSetType = g_GraphPanelDataSetType
	local minTurn = g_InitialTurn
	local maxTurn = g_FinalTurn
	local activePlayer = Game and Game.GetActivePlayer() or 0

	g_LineSegmentInstanceManager:ResetInstances()
	g_LabelInstanceManager:ResetInstances()

	-- Determine the maximum score for displayed players
	local maxScore = -math.huge
	local minScore = math.huge
	local scores, replayData, player
	for playerID, playerInfo in pairs(g_PlayerInfo) do
		if playerInfo.GraphLegendCheck:IsChecked() then
			scores = playerInfo.Scores
			if scores then
				replayData = scores
			else
				replayData = g_GraphReplayData[ playerID ]
				if not replayData then
					player = Players[ playerID ]
					replayData = player and player:GetReplayData() or {}
					g_GraphReplayData[ playerID ] = replayData
				end
				replayData = replayData[dataSetType] or {}
			end
			for _, score in pairs( replayData ) do
				if scores then
					score = score[dataSetType]
				end
				if score then
					if score > maxScore then
						maxScore = score
					end
					if score < minScore then
						minScore = score
					end
				end
			end
		end
	end
	--print("Drawing graphs for", dataSetType, "min score", minScore, "max score", maxScore )
	local range = maxScore - minScore
	-- Sample data to prevent too many segments
	local step = math.ceil((maxTurn-minTurn)/70)
	if range > 0 and step > 0 then	-- this usually means that there were no values for that dataset.

		Controls.NoGraphData:SetHide( true )
		local power10 = math.ceil( math.log(range)/math.log(10) )
		local increment = 1
		if power10 > 1 then		-- we only want increments >= 1
			increment = 10^(power10-1)
			while range/increment < 5 and increment%2==0 do	-- we want at least 5 increments, but whole
				increment = increment/2
			end
		end
		minScore = math.floor( minScore/increment ) * increment
		maxScore = math.ceil( maxScore/increment ) * increment
		range = maxScore - minScore

		local graphWidth, graphHeight = Controls.GraphCanvas:GetSizeVal()
		local scaleX = graphWidth / math.max(maxTurn - minTurn, 1)
		local scaleY = graphHeight / range
		local label, y1, y2, lineSegment, lineWidth, color, r, g, b, a
		local x0 = graphWidth
		local x1 = x0+5
		local y0 = minScore * scaleY
		Controls.Negative:SetHide( y0>=0 )
		Controls.Negative:SetSizeY( -y0 )
		y0 = y0 + graphHeight

		for i = 0, range/increment do
			y1 = graphHeight - i*increment*scaleY
			lineSegment = g_LineSegmentInstanceManager:GetInstance()
			lineSegment = lineSegment.LineSegment
			lineSegment:SetStartVal( x0, y1 )
			lineSegment:SetEndVal( x1, y1 )
			lineSegment:SetColorVal( 1, 1, 1, 0.5 )
			lineSegment:SetWidth( 1 )
			label = g_LabelInstanceManager:GetInstance()
			label = label.Label
			label:SetText( i*increment + minScore )
			label:SetOffsetVal( x1+5, y1-5 )
		end

		x0 = -minTurn * scaleX
		-- Sample data until stopTurn, then full data until maxTurn
		local stopTurn = maxTurn - (step>1 and 30 or 0)
		local dt, turn1, turn2, x1, x2
		for playerID, playerInfo in pairs(g_PlayerInfo) do
			scores = playerInfo.Scores
			replayData = playerInfo.GraphLegendCheck:IsChecked() and ( scores or g_GraphReplayData[ playerID ][ dataSetType ] )
			--print("Drawing graph for player ID", playerID, playerInfo.CivShortDescription or civ.ShortDescription, replayData, step )
			if replayData then
				color = playerInfo.ColorFGXVector4
				r, g, b, a = color.x, color.y, color.z, color.w
				y1 = nil
				lineWidth = activePlayer == playerID and 3 or 1
				dt = step
				turn1 = minTurn
				turn2 = stopTurn
				repeat
					for turn = turn1, turn2, dt do
						y2 = replayData[turn]
						if scores and y2 then
							y2 = y2[dataSetType]
						end
						if y2 then
							x2 = turn*scaleX + x0
							if y1 then
								lineSegment = g_LineSegmentInstanceManager:GetInstance()
								lineSegment = lineSegment.LineSegment
								lineSegment:SetStartVal( x1, y0 - y1*scaleY )
								lineSegment:SetEndVal( x2, y0 - y2*scaleY )
								lineSegment:SetColorVal( r, g, b, a )
								lineSegment:SetWidth( lineWidth )
							end
							x1 = x2
						end
						y1 = y2
					end
					if dt>1 then
						dt = 1
						turn1 = turn2 + dt
						turn2 = maxTurn
					else
						break
					end
				until false
			end
		end
	else
		Controls.NoGraphData:SetHide( false )
	end
end

local function InitializePlayerData( playersInfo )

--[[
	local playerReplayColors = {}
	local function SumSquares( x, y, z )
		return x*x + y*y + z*z
	end
	local function ColorDistanceToBlack( color )
		return SumSquares( color.Red,  color.Green, color.Blue )
	end
	local function ColorDistance( color1, color2 )
		return SumSquares( color1.Red - color2.Red, color1.Green - color2.Green, color1.Blue - color2.Blue )
	end
	local function ColorDelta( color )
		local r, g, b  = color.Red, color.Green, color.Blue
		local a = (r+g+b)/3
		return math.max( (r-a), (g-a), (b-a) )
	end
	local function IsUniqueColor( playerColor )
		-- Distance against black
		if ColorDistanceToBlack( playerColor ) < .1 then
			return false
		else
			for _, color in pairs( playerReplayColors ) do
				if ColorDistance( playerColor, color ) < .05 then
					return false
				end
			end
			return true
		end
	end
--]]
	g_GraphLegendInstanceManager:ResetInstances()
	g_MapPrimaryPlayerColors = {}
	g_MapSecondaryPlayerColors = {}
	local playerInfo, civ, isMinorCiv, instance, dimming, playerColors, primaryColor, secondaryColor, h, s, l, h1, s1, l1, r, g, b --, color, color1
	for playerID = 0, MAX_CIV_PLAYERS do
		playerInfo = playersInfo[ playerID ]
		if playerInfo then
			playerColors = GameInfo.PlayerColors[ playerInfo.PlayerColor ]
			primaryColor = GameInfo.Colors[playerColors.PrimaryColor]
			secondaryColor = GameInfo.Colors[playerColors.SecondaryColor]
			h1, s1, l1 = RGBtoHSL( RGBunpack( primaryColor ) )
			h, s, l = RGBtoHSL( RGBunpack( secondaryColor ) )
--print( playerInfo.Civilization, h1, s1, l1, h, s, l, "Primary Color", RGBunpack( primaryColor ), "Secondary color", RGBunpack( secondaryColor ) )
			if s1/(l1+2) > s/(l+2)+.1 then
				h, s, l = h1, s1, l1
			end
--print( playerInfo.Civilization, h, s, l, h1, s1, l1 )
--[[
			if ColorDelta( color1 ) >= ColorDelta( color )+.5 then
				color, color1 = color1, color
			end
			if not IsUniqueColor( color ) then
				if IsUniqueColor( color1 ) then
					color = color1
				else
					for color1 in GameInfo.Colors() do
						if IsUniqueColor( color1 ) then
							color = color1
							break
						end
					end
				end
			end
			playerReplayColors[ playerID ] = color
--]]
			r, g, b = HSLtoRGB( h, s, math.max(l,.1) )
			playerInfo.ColorFGXVector4 = { x=r, y=g, z=b, w=1 }
			instance = g_GraphLegendInstanceManager:GetInstance()
			playerInfo.GraphLegendCheck = instance.ShowHide
			playerInfo.GraphLegend = instance.GraphLegend
			civ = GameInfo.Civilizations[playerInfo.Civilization]
			if civ then
				isMinorCiv = civ.Type == "CIVILIZATION_MINOR"
				IconHookup( civ.PortraitIndex, 32, civ.IconAtlas, instance.LegendIcon )
				instance.LegendName:LocalizeAndSetText( playerInfo.CivShortDescription or civ.ShortDescription )
			end
			instance.LegendLine:SetColorVal( r, g, b, 1 )
			instance.ShowHide:SetCheck( not isMinorCiv )
			instance.ShowHide:RegisterCheckHandler( DrawGraph )
			--print("Graph legend for player ID", playerID, playerInfo.CivShortDescription or civ.ShortDescription, playerInfo.GraphLegendCheck )
			-- Cache map player colors
			-- Reverse and dim colors for minor civs.
			if isMinorCiv then
				primaryColor = secondaryColor
				dimming = .5
			else
				dimming = 1
			end
			g_MapSecondaryPlayerColors[playerID] = {
					Red = secondaryColor.Red * dimming,
					Green = secondaryColor.Green * dimming,
					Blue = secondaryColor.Blue * dimming,
					Alpha = 1.0
			}
			g_MapPrimaryPlayerColors[playerID] = {
					Red = primaryColor.Red,
					Green = primaryColor.Green,
					Blue = primaryColor.Blue,
					Alpha = 0.8
			}
		end
	end
end
if Game then
	for playerID, player in pairs( Players ) do
		if player:IsEverAlive() then
			g_AllPlayerInfo[playerID] = {
				Civilization = player:GetCivilizationType(),
--				Leader = player:GetLeaderType(),
				PlayerColor = player:GetPlayerColor(),
--				Difficulty = player:GetHandicapType(),
--				LeaderName = player:GetName(),
--				CivDescription = player:GetCivilizationDescription(),
				CivShortDescription = player:GetCivilizationShortDescription(),
--				CivAdjective = player:GetCivilizationAdjective(),
			}
		end
	end
	InitializePlayerData( g_AllPlayerInfo )
end

local Panels = { 
-- Graphs Panel
[-1]={
	Title = L"TXT_KEY_REPLAY_VIEWER_GRAPHS_TITLE",
	Tooltip = L"TXT_KEY_REPLAY_VIEWER_GRAPHS_TT",
	Panel = Controls.GraphsPanel,

	Refresh = function()

		-- Refresh HorizontalScales
		local graphWidth, graphHeight = Controls.GraphCanvas:GetSizeVal()
		local minTurn = g_InitialTurn
		local maxTurn = g_FinalTurn

		local range = math.max(maxTurn - minTurn,1)
		local scaleX = graphWidth / range

		local power10 = math.ceil( math.log(range)/math.log(10) )
		local increment = 1
		if power10 > 1 then		-- we don't want increments < 1
			increment = 10^(power10-1)
			if range/increment < 6 then
				increment = increment/2
			end
		end
		minTurn = math.floor( minTurn/increment ) * increment
		maxTurn = math.ceil( maxTurn/increment ) * increment

		g_LineSegmentInstanceManager2:ResetInstances()
		g_LabelInstanceManager2:ResetInstances()
		local i0 = g_InitialTurn - minTurn
		local x0 = -i0*scaleX
		local y0 = graphHeight
		local y1 = y0+5
		local y2 = y1+5

		local x1, label, lineSegment
		for i = i0, range/increment do
			x1 = x0 + i*increment*scaleX
			lineSegment = g_LineSegmentInstanceManager2:GetInstance()
			lineSegment = lineSegment.LineSegment
			lineSegment:SetStartVal( x1, y0 )
			lineSegment:SetEndVal( x1, y1 )
			lineSegment:SetColorVal( 1, 1, 1, 0.5 )
			lineSegment:SetWidth( 1 )
			label = g_LabelInstanceManager2:GetInstance()
			label = label.Label
--				label:SetText( i*increment + minTurn )
			label:SetText(GetShortDateString(i*increment + minTurn, g_CalendarType, g_GameSpeedType, g_StartYear))
			label:SetOffsetVal( x1-label:GetSizeX()/2, y2 )
		end

		Controls.GraphLegendStack:CalculateSize()
		Controls.GraphLegendStack:ReprocessAnchoring()
		Controls.GraphLegendScrollPanel:CalculateInternalSize()
		g_ReplayInfoPulldownButton:LocalizeAndSetText( GameInfo.ReplayDataSets[ g_GraphPanelDataSetType ].Description )
		DrawGraph()
	end
},
-- Map Panel
{
	Title = L"TXT_KEY_REPLAY_VIEWER_MAP_TITLE",
	Tooltip = L"TXT_KEY_REPLAY_VIEWER_MAP_TT",
	Panel = Controls.MapPanel,
	Refresh = function()
		if not g_ReplayMessages then
			if Game then
				g_ReplayMessages = Game.GetReplayMessages()
				g_FinalTurn = Game.GetGameTurn()
			else
				g_ReplayMessages = {}
			end
		end
		DrawReplayMap( 1 ) -- 0-1 = begin-end
	end,
},
-- Messages Panel
{
	Title = L"TXT_KEY_REPLAY_VIEWER_MESSAGES_TITLE",
	Tooltip = L"TXT_KEY_REPLAY_VIEWER_MESSAGES_TT",
	Panel = Controls.MessagesPanel,
	Refresh = function()
		if not g_ReplayMessages then
			if Game then
				g_ReplayMessages = Game.GetReplayMessages()
				g_FinalTurn = Game.GetGameTurn()
			else
				return
			end
		end
		local playersInfo = g_PlayerInfo
		local messageInstance, playerInfo
		g_ReplayMessageInstanceManager:ResetInstances()
		for _, message in ipairs(g_ReplayMessages) do
			if message.Text and #message.Text > 0 and (g_ShowEverything or g_MessageTypesAllowed[message.Type]) then
				playerInfo = playersInfo[message.Player]
				if playerInfo then
					messageInstance = g_ReplayMessageInstanceManager:GetInstance()
					messageInstance.MessageText:SetText( tostring(message.Turn) .. " - " .. message.Text )
					messageInstance.Base:SetSizeY( messageInstance.MessageText:GetSizeY() + 10 )
					messageInstance.MessageText:SetColor( playerInfo.ColorFGXVector4, 0 )
				end
			end
		end
		Controls.ReplayMessageStack:CalculateSize()
		Controls.ReplayMessageStack:ReprocessAnchoring()
		Controls.ReplayMessageScrollPanel:CalculateInternalSize()
	end
},
}
-- Demographics Panel
if Game then
	insert( Panels, 1, {
		Title = L"TXT_KEY_DEMOGRAPHICS",
		Tooltip = L"TXT_KEY_DEMOGRAPHICS",
		Panel = LookUpControl( "/InGame/Demographics/BigStack" ),
		Refresh = function() end,
	} )
end

--==========================================================
local function OnBack()
	UIManager:DequeuePopup( ContextPtr )
	-- Dump tables
	g_GraphReplayData = {}
	g_MapReplayPlots = nil
	g_PlayerInfo = nil
	g_ReplayMessages = nil
	collectgarbage()
end

local function OnPausePlay()
	if Controls.MapTimer:IsStopped() then
		Controls.MapTimer:Play()
	else
		Controls.MapTimer:Stop()
	end
end

--==========================================================
local function SetCurrentPanel( panelIndex )
	g_CurrentPanelIndex = panelIndex
	ContextPtr:ClearUpdate()
	Controls.MapTimer:Stop()
	for i, panel in pairs( Panels ) do
		if i==panelIndex then
			g_ReplayInfoPulldownButton:SetText( panel.Title )
			g_ReplayInfoPulldownButton:SetToolTipString( panel.ToolTip )
			panel.Panel:SetHide( false )
			panel.Refresh()
		else
			panel.Panel:SetHide(true)
		end
	end
end

local function RefreshPanels()
	g_GraphReplayData = {}
	g_ReplayMessages = nil
	g_FinalTurn = Game.GetGameTurn()
	g_ShowEverything = Game.GetWinner() ~= -1 or Game.IsDebugMode() or Players[ Game.GetActivePlayer() ]:IsObserver()
	if g_ShowEverything then
		g_PlayerInfo = g_AllPlayerInfo
	else
		local activeTeam = Teams[Game.GetActiveTeam()]
		g_PlayerInfo = {}
		for playerID, player in pairs( Players ) do
			if player:IsEverAlive() and activeTeam:IsHasMet( player:GetTeam() ) then
				g_PlayerInfo[playerID] = g_AllPlayerInfo[playerID]
			end
		end
	end
	for playerID, playerInfo in pairs( g_AllPlayerInfo ) do
		playerInfo.GraphLegend:SetHide( not g_PlayerInfo[ playerID ] )
	end
	SetCurrentPanel( g_CurrentPanelIndex )
end

local function SetGraphDataSet( dataSetIndex )
	g_GraphPanelDataSetType = GameInfo.ReplayDataSets[ dataSetIndex ].Type
	SetCurrentPanel( -1 ) -- Graph
end

--==========================================================
-- Initialization
--==========================================================
ContextPtr:SetShowHideHandler( function( isHide )
	ContextPtr:ClearUpdate()
	Controls.MapTimer:Stop()
	if Game then
		if isHide then
			Events.NewGameTurn.Remove( RefreshPanels )
		else
			RefreshPanels()
			Events.NewGameTurn.Add( RefreshPanels )
		end
	end
end)

-- Key Down Processing
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local VK_SPACE = Keys.VK_SPACE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_SPACE then
				OnPausePlay()
				return true
			elseif not Game and ( wParam == VK_ESCAPE or wParam == VK_RETURN ) then
				OnBack()
				return true
			end
		end
	end)
end

Controls.FrontEndReplayViewer:SetHide( Game )
Controls.BackButton:RegisterCallback(Mouse.eLClick, OnBack)
Controls.MapCloseButton:RegisterCallback(Mouse.eLClick, OnBack)
Controls.PlayPauseButton:RegisterCallback(Mouse.eLClick, OnPausePlay)

-- Build panel selection pulldown
g_ReplayInfoPulldown:ClearEntries()
for i, panel in ipairs(Panels) do
	local controlTable = {}
	g_ReplayInfoPulldown:BuildEntry( "InstanceOne", controlTable )
	controlTable.Button:SetText( panel.Title )
	controlTable.Button:SetToolTipString( panel.ToolTip )
	controlTable.Button:RegisterCallback( Mouse.eLClick, SetCurrentPanel )
	controlTable.Button:SetVoid1( i )
end

-- Build graph data set pulldown
--local graphEntries = {}
for replayDataSet in GameInfo.ReplayDataSets() do
--	insert(graphEntries, replayDataSet)
--end
--table.sort( graphEntries, function(a,b) return LocaleCompare(a.Description, b.Description) == -1 end )
--for _, replayDataSet in ipairs(graphEntries) do
	local controlTable = {}
	g_ReplayInfoPulldown:BuildEntry( "InstanceOne", controlTable )
	controlTable.Button:LocalizeAndSetText( replayDataSet.Description )
	controlTable.Button:SetVoid1( replayDataSet.ID )
	controlTable.Button:RegisterCallback( Mouse.eLClick, SetGraphDataSet )
end
g_ReplayInfoPulldown:CalculateInternals()

local screenX, screenY = UIManager:GetScreenSizeVal()
--	local screenX2, screenY2 = Controls.ReplayMap:GetSizeVal()
--	local offsetY, offsetY2 = 0, Controls.ReplayMap:GetOffsetX()

local xAbsoluteOffset = screenX * 0.5 - Controls.MainPanel:GetSizeX() * 0.5
						+ Controls.GraphsPanel:GetOffsetX() + Controls.GraphDisplay:GetOffsetX()
local yAbsoluteOffset = screenY * 0.5 - Controls.MainPanel:GetSizeY() * 0.5
						+ Controls.GraphsPanel:GetOffsetY() + Controls.GraphDisplay:GetOffsetY()
local horizontalMouseCrosshair = Controls.HorizontalMouseCrosshair
local verticalMouseCrosshair = Controls.VerticalMouseCrosshair

local function MoveMouseCrossHairs()
	local x, y = UIManager:GetMousePos()
	verticalMouseCrosshair:SetOffsetX( x - xAbsoluteOffset )
	horizontalMouseCrosshair:SetOffsetY( y - yAbsoluteOffset )
end
--[[
Controls.MapMinimize:RegisterCallback( Mouse.eLClick, function()
	Controls.ReplayMap:SetSizeVal( screenX, screenY )
	Controls.ReplayMap:SetOffsetY( offsetY )
	Controls.ReplayMap:SetMapSize( 1,1,1,1 )
--		Controls.TurnSlider:SetAndCall( Controls.TurnSlider:GetValue() )
	screenX, screenY, offsetY, screenX2, screenY2, offsetY2 = screenX2, screenY2, offsetY2, screenX, screenY, offsetY
end)
--]]
Controls.GraphCanvas:RegisterCallback( Mouse.eMouseEnter, function()
	ContextPtr:SetUpdate( MoveMouseCrossHairs )
	verticalMouseCrosshair:SetHide( false )
	horizontalMouseCrosshair:SetHide( false )
end)
Controls.GraphCanvas:RegisterCallback( Mouse.eMouseExit, function()
	verticalMouseCrosshair:SetHide( true )
	horizontalMouseCrosshair:SetHide( true )
	ContextPtr:ClearUpdate()
end)
LuaEvents.ReplayViewer_LoadReplay.Add( function( replayFile )
print( "ReplayViewer_LoadReplay", replayFile )
	local replayInfo = UI.GetReplayInfo( replayFile )
	g_MapReplayPlots = replayInfo.Plots
	g_ReplayMessages = replayInfo.Messages
	g_PlayerInfo = replayInfo.PlayerInfo
	g_MapWidth = replayInfo.MapWidth
	g_MapHeight = replayInfo.MapHeight
	g_StartYear = replayInfo.StartYear
	g_InitialTurn = replayInfo.InitialTurn
	g_FinalTurn = replayInfo.FinalTurn
	g_CalendarType = GetInfoType( GameInfo.Calendars, replayInfo.Calendar ) or "CALENDAR_DEFAULT"
	g_GameSpeedType = GetInfoType( GameInfo.GameSpeeds, replayInfo.GameSpeed ) or "GAMESPEED_STANDARD"
	g_ShowEverything = true
	InitializePlayerData( g_PlayerInfo )
	print( "Loaded replay info from file:", replayFile )
	SetCurrentPanel( 1 ) -- Map
end)
end
