--==========================================================
-- Tech Tree Popup
-- Re-written by bc1 using Notepad++
-- capture choose tech & steal tech popup events
-- fix escape/enter popup exit code
-- support Technology_ORPrereqTechs in addition to Technology_PrereqTechs
-- code is common except for vanila gk_mode needs to be set false
--==========================================================

Events.SequenceGameInitComplete.Add(function()

include "UserInterfaceSettings"
local UserInterfaceSettings = UserInterfaceSettings

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfo = GameInfoCache

g_UseSmallIcons = true
include "TechButtonInclude" -- includes "IconHookup"
local IconHookup = IconHookup
local GatherInfoAboutUniqueStuff = GatherInfoAboutUniqueStuff
local AddSmallButtonsToTechButton = AddSmallButtonsToTechButton
local freeString = freeString
local lockedString = lockedString

--==========================================================
-- Minor lua optimizations
--==========================================================

local abs = math.abs
local max = math.max
local min = math.min
local pairs = pairs

local ButtonPopupTypes = ButtonPopupTypes
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local Game = Game
local GameInfoTechnologies = GameInfo.Technologies
local GameInfoTypes = GameInfoTypes
local L = Locale.ConvertTextKey
local Locale = Locale
local Mouse = Mouse
local Network_SendResearch = Network.SendResearch
local Players = Players
local PopupPriority_InGameUtmost = PopupPriority.InGameUtmost
local Teams = Teams
local UI = UI
local UIManager = UIManager

local gk_mode = Players[0].GetNumTechsToSteal ~= nil

local g_scienceEnabled = not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)

local g_popupInfoType, g_stealingTechTargetPlayer
local g_stealingTechTargetPlayerID = -1

local g_techButtons = {}
local g_eraBlocks = {}

local g_maxSmallButtons = 5

local g_blockSizeX = 270	-- tech block width
local g_blockOffsetX = 64
local g_blockSpacingY = 68	-- tech block vertical spacing
local g_blockOffsetY = 32 - 5*g_blockSpacingY
local g_blockSpacingX = g_blockSizeX + 96

local g_maxTechNameLength = 22 - Locale.Length(L"TXT_KEY_TURNS")

local CloseTechTree

-------------------------------------------------
-- Tech Pipe Management
-------------------------------------------------

local function AddTechPipes( techPairs, pipeColor )

	local blockSpacingX = g_blockSpacingX
	local blockSpacingY = g_blockSpacingY
	local connectorEndOffsetX = g_blockOffsetX
	local connectorStartOffsetX = connectorEndOffsetX + g_blockSizeX
	local connectorOffsetY = g_blockOffsetY

	local connectorOffsetY0 = connectorOffsetY + 3
	local connectorOffsetY1 = connectorOffsetY + 10
	local connectorOffsetY2 = connectorOffsetY1 - 15
	local connectorElbowBiasX = 12
	local connectorElbowSizeX = 32+connectorElbowBiasX	-- TechPipeInstance texture width plus offest
	local connectorElbowSizeY = 42+15	-- TechPipeInstance texture height
	local connectorElbowDeltaX = 27 + connectorElbowSizeX -- 27 = (96-connectorElbowSizeX)/2 + 1
	local connectorElbowOffsetX2 = connectorEndOffsetX - connectorElbowDeltaX
	local connectorElbowOffsetX1 = connectorElbowOffsetX2 + connectorElbowBiasX

	local function GetPipeWithoutColor()
		local pipe = {}
		ContextPtr:BuildInstanceForControl( "TechPipeInstance", pipe, Controls.TechTreeScrollPanel )
		return pipe.TechPipeIcon
	end

	local GetPipe = pipeColor and
		function()
			local pipe = GetPipeWithoutColor()
			pipe:SetColor( pipeColor )
			return pipe
		end
	or GetPipeWithoutColor

	local function GetTexturedPipe( x, y, texture )
		local pipe = GetPipe()
		pipe:SetOffsetVal( x, y )
		pipe:SetTextureAndResize( texture )
		return pipe
	end

	local function AddElbowPipe( x, y, t_x, t_y )
		local pipe = GetPipe()
		pipe:SetOffsetVal( x, y )
		pipe:SetTextureOffsetVal( t_x, t_y )
	end

	local prereq, tech, elbowX, startX, endX, startY, endY, sizeY, sizeX

	-- add straight connectors first
	for row in techPairs() do
		prereq = GameInfoTechnologies[row.PrereqTech]
		tech = GameInfoTechnologies[row.TechType]
		if tech and prereq then
			startX = prereq.GridX*blockSpacingX + connectorStartOffsetX
			endX = tech.GridX*blockSpacingX + connectorEndOffsetX

			sizeY = abs( tech.GridY - prereq.GridY )

			if sizeY > 0 then
				elbowX = endX - connectorElbowDeltaX
				-- vertical connector
				sizeY = sizeY * blockSpacingY - connectorElbowSizeY
				if sizeY > 0 then
					GetTexturedPipe( elbowX + connectorElbowBiasX, (tech.GridY + prereq.GridY) * blockSpacingY / 2 + connectorOffsetY0, "TechBranchV.dds" ):SetSizeY( sizeY )
				end
				-- horizontal end connector
				endX, sizeX = elbowX, endX - elbowX - connectorElbowSizeX
				if sizeX > 0 then
					GetTexturedPipe( elbowX + connectorElbowSizeX, tech.GridY*blockSpacingY + connectorOffsetY, "TechBranchH.dds" ):SetSizeX( sizeX )
				end
			end

			-- horizontal main connector
			if endX > startX then
				GetTexturedPipe( startX, prereq.GridY*blockSpacingY + connectorOffsetY, "TechBranchH.dds" ):SetSizeX( endX - startX )
			end
		end
	end

	-- add elbow connectors on top
	for row in techPairs() do
		prereq = GameInfoTechnologies[row.PrereqTech]
		tech = GameInfoTechnologies[row.TechType]
		if tech and prereq then
			elbowX = tech.GridX*blockSpacingX
			startY = prereq.GridY
			endY = tech.GridY

			if startY < endY then -- elbow case ¯¯¯¯¯¯|__

				AddElbowPipe( elbowX + connectorElbowOffsetX2, startY*blockSpacingY + connectorOffsetY1, 72, 0 )	-- ¯|
				AddElbowPipe( elbowX + connectorElbowOffsetX1, endY*blockSpacingY + connectorOffsetY2 , 0, 72 )		--  |_

			elseif startY > endY then -- elbow case ______|¯¯

				AddElbowPipe( elbowX + connectorElbowOffsetX1, endY*blockSpacingY + connectorOffsetY1, 0, 0 )		--  |¯
				AddElbowPipe( elbowX + connectorElbowOffsetX2, startY*blockSpacingY + connectorOffsetY2, 72, 72 )	-- _|
			end
		end
	end
end

-------------------------------------------------
-- Mouse Click Management
-------------------------------------------------

local function TechSelected( techID )
	if GameInfoTechnologies[ techID ] then
		local activePlayer = Players[ Game.GetActivePlayer() ]
		local shift = UIManager:GetShift()
		if g_stealingTechTargetPlayer then
			if activePlayer:CanResearch( techID )
				and activePlayer:GetNumTechsToSteal( g_stealingTechTargetPlayerID ) > 0
				and Teams[ g_stealingTechTargetPlayer:GetTeam() ]:IsHasTech( techID )
			then
				Network_SendResearch( techID, 0, g_stealingTechTargetPlayerID, shift )
				CloseTechTree()
			end
		else
			Network_SendResearch( techID, activePlayer:GetNumFreeTechs(), -1, shift )
			if not shift and g_popupInfoType == ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH and UserInterfaceSettings.ScreenAutoClose ~= 0 then
				CloseTechTree()
			end
		end
	end
end

local function TechPedia( techID )
	local tech = GameInfoTechnologies[ techID ]
	Events.SearchForPediaEntry( tech and tech.Description )
end

local TechTooltipCall = LuaEvents.TechTooltip.Call

local function ToolTipCallback( button )
	return TechTooltipCall( button:GetVoid1() )
end

local function ToolTipSetup( button )
	button:SetToolTipCallback( ToolTipCallback )
	button:SetToolTipType( "EUI_ItemTooltip" )
end

-------------------------------------------------
-- Display Refresh
local function RefreshDisplay( isFullRefresh )

	-- update the tech buttons
	local currentEra = 0
	local techID, thisTechButton, canResearchThisTech, turnText, researchPerTurn
	local activePlayer = Players[Game.GetActivePlayer()]
	local activeTeamTechs = Teams[ Game.GetActiveTeam() ]:GetTeamTechs()
	for tech in GameInfoTechnologies() do
		techID = tech.ID
		thisTechButton = g_techButtons[ techID ]
		canResearchThisTech = activePlayer:CanResearch( techID )
		turnText = L( "TXT_KEY_STR_TURNS", activePlayer:GetResearchTurnsLeft( techID, true ) )
		researchPerTurn = activePlayer:GetScience()

		-- Rebuild the small buttons if needed
		if isFullRefresh then
			AddSmallButtonsToTechButton( thisTechButton, tech, g_maxSmallButtons, 45 )
		end

		local showAlreadyResearched, showFreeTech, showCurrentlyResearching, showAvailable, showUnavailable, showLocked, queueUpdate, queueText, turnLabel, isClickable
--[[
		if canResearchThisTech then
			for iAdvisorLoop = 0, AdvisorTypes.NUM_ADVISOR_TYPES - 1, 1 do
				local pControl = nil;
				if (iAdvisorLoop == AdvisorTypes.ADVISOR_ECONOMIC) then			
					pControl = thisTechButtonInstance.EconomicRecommendation;
				elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_MILITARY) then
					pControl = thisTechButtonInstance.MilitaryRecommendation;			
				elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_SCIENCE) then
					pControl = thisTechButtonInstance.ScienceRecommendation;
				elseif (iAdvisorLoop == AdvisorTypes.ADVISOR_FOREIGN) then
					pControl = thisTechButtonInstance.ForeignRecommendation;
				end
			
				if (pControl) then
					pControl:SetHide(not Game.IsTechRecommended(tech.ID, iAdvisorLoop));
				end
			end
		end
--]]
		if activeTeamTechs:HasTech( techID ) then
		-- the active player already has this tech
			showAlreadyResearched = true
			-- update the era marker for this tech
			local eraID = GameInfoTypes[tech.Era]
			if eraID and currentEra < eraID then
				currentEra = eraID
			end

		elseif g_stealingTechTargetPlayer or activePlayer:GetNumFreeTechs() > 0 then
		-- Stealing a tech or Choosing a free tech
			if canResearchThisTech and ( 
				( g_stealingTechTargetPlayer and Teams[ g_stealingTechTargetPlayer:GetTeam() ]:IsHasTech( techID ) )
				or (not g_stealingTechTargetPlayer and (not gk_mode or activePlayer:CanResearchForFree( techID ))) )
			then
				showFreeTech = true
				turnLabel = thisTechButton.FreeTurns
				queueText = freeString	-- update queue number to say "FREE"
				isClickable = true
			else
				showLocked = true
			end

		-- the active player is currently researching this one
		elseif activePlayer:GetCurrentResearch() == techID then
			showCurrentlyResearching = true
			turnLabel = thisTechButton.CurrentlyResearchingTurns
			queueUpdate = activePlayer:GetLengthResearchQueue() > 1	-- update queue number if needed
			isClickable = true -- to clear research queue
--[[
			-- turn on the meter
			local currentResearchProgress = activePlayer:GetResearchProgress( techID )
			local researchNeeded = activePlayer:GetResearchCost( techID )
			local currentResearchPlusThisTurn = currentResearchProgress + researchPerTurn
			local researchProgressPercent = currentResearchProgress / researchNeeded
			local researchProgressPlusThisTurnPercent = min( 1, currentResearchPlusThisTurn / researchNeeded )
--]]
		-- the active player can research this one right now if he wants
		elseif canResearchThisTech and g_scienceEnabled then
			showAvailable = true
			turnLabel = thisTechButton.AvailableTurns
			queueUpdate = true	-- update queue number if needed
			isClickable = true

		elseif activePlayer:CanEverResearch( techID ) and g_scienceEnabled then
		-- currently unavailable
			showUnavailable = true
			queueUpdate = true	-- update queue number if needed
			turnLabel = thisTechButton.UnavailableTurns
			isClickable = true  -- shift clickable
		else
			showLocked = true
		end
		thisTechButton.AlreadyResearched:SetHide( not showAlreadyResearched )
		thisTechButton.FreeTech:SetHide( not showFreeTech )
		thisTechButton.CurrentlyResearching:SetHide( not showCurrentlyResearching )
		thisTechButton.Available:SetHide( not showAvailable )
		thisTechButton.Unavailable:SetHide( not showUnavailable )
		thisTechButton.Locked:SetHide( not showLocked )
		if showLocked then
			queueText = lockedString	-- have queue number say "LOCKED"
		elseif queueUpdate then
			local queuePosition = activePlayer:GetQueuePosition( techID )
			if queuePosition ~= -1 then
				queueText = queuePosition
			end
		end
		if queueText then
			thisTechButton.TechQueueLabel:SetText( queueText )
		end
		thisTechButton.TechQueue:SetHide( not queueText )
		if isClickable then
			thisTechButton.TechButton:RegisterCallback( Mouse.eLClick, TechSelected )
			for buttonNum = 1, g_maxSmallButtons do
				thisTechButton["B"..buttonNum]:RegisterCallback( Mouse.eLClick, TechSelected )
			end
		else
			thisTechButton.TechButton:ClearCallback( Mouse.eLClick )
			for buttonNum = 1, g_maxSmallButtons do
				thisTechButton["B"..buttonNum]:ClearCallback( Mouse.eLClick )
			end
		end
		if turnLabel then
			if researchPerTurn > 0 and g_scienceEnabled then
				turnLabel:SetText( turnText )
				turnLabel:SetHide( false )
			else
				turnLabel:SetHide( true )
			end
		end
	end

	-- update the era panels
	for eraID, eraBlock in pairs( g_eraBlocks ) do
		eraBlock.OldBar:SetHide( eraID >= currentEra )
		eraBlock.CurrentBlock:SetHide( eraID ~= currentEra )
		eraBlock.CurrentTop:SetHide( eraID ~= currentEra )
		eraBlock.FutureBlock:SetHide( eraID <= currentEra )
	end
end

-------------------------------------------------
-- find the range of columns that each era takes
-- and add the era panels to the background
local eraBlockX = -g_blockSpacingX-32
local eraID, eraBlock, eraBlockWidth
for tech in GameInfoTechnologies() do
	eraID = GameInfoTypes[tech.Era]
	eraBlock = g_eraBlocks[eraID]
	if eraBlock then
		if tech.GridX < eraBlock.minGridX then
			eraBlock.minGridX = tech.GridX
		end
		if tech.GridX > eraBlock.maxGridX then
			eraBlock.maxGridX = tech.GridX
		end
	else
		g_eraBlocks[eraID] = { minGridX = tech.GridX, maxGridX = tech.GridX }
	end
end

for era in GameInfo.Eras() do
	eraID = era.ID
	eraBlock = g_eraBlocks[eraID]
	if eraBlock then
		ContextPtr:BuildInstanceForControl( "EraBlockInstance", eraBlock, Controls.EraStack )
		eraBlock.OldLabel:SetText( era._Name )
		eraBlock.CurrentLabel:SetText( era._Name )
		eraBlock.FutureLabel:SetText( era._Name )

		eraBlockWidth = eraBlock.maxGridX * g_blockSpacingX
		eraBlockWidth, eraBlockX = eraBlockWidth - eraBlockX, eraBlockWidth

		eraBlock.EraBlock:SetSizeX( eraBlockWidth )
		eraBlock.OldBar:SetSizeX( eraBlockWidth )
		eraBlock.OldBlock:SetSizeX( eraBlockWidth )
		eraBlock.CurrentBlock:SetSizeX( eraBlockWidth )
		eraBlock.CurrentBlock2:SetSizeX( eraBlockWidth )
		eraBlock.CurrentTop:SetSizeX( eraBlockWidth )
		eraBlock.CurrentTop1:SetSizeX( eraBlockWidth )
		eraBlock.CurrentTop2:SetSizeX( eraBlockWidth )
		eraBlock.FutureBlock:SetSizeX( eraBlockWidth )
	end
end

-------------------------------------------------
-- add the tech button pipes
-------------------------------------------------
AddTechPipes( GameInfo.Technology_PrereqTechs )
AddTechPipes( GameInfo.Technology_ORPrereqTechs, { x=1.0, y=1.0, z=0.0, w=0.5 } )

-------------------------------------------------
-- add the tech buttons
for tech in GameInfoTechnologies() do
	local thisTechButton = {}
	local techID = tech.ID
	ContextPtr:BuildInstanceForControl( "TechButtonInstance", thisTechButton, Controls.TechTreeScrollPanel )

	-- store this instance off for later
	g_techButtons[techID] = thisTechButton

	-- add the input handler to this button
	thisTechButton.TechButton:SetVoid1( techID )
	thisTechButton.TechButton:RegisterCallback( Mouse.eRClick, TechPedia )
	thisTechButton.TechButton:SetToolTipCallback( ToolTipSetup )

--	if g_scienceEnabled then
--		thisTechButton.TechButton:RegisterCallback( Mouse.eLClick, TechSelected )
--	end

	-- position
	thisTechButton.TechButton:SetOffsetVal( tech.GridX*g_blockSpacingX + g_blockOffsetX, tech.GridY*g_blockSpacingY + g_blockOffsetY )

	-- name
	local techName = Locale.TruncateString( tech._Name, g_maxTechNameLength, true )
	thisTechButton.AlreadyResearchedTechName:SetText( techName )
	thisTechButton.CurrentlyResearchingTechName:SetText( techName )
	thisTechButton.AvailableTechName:SetText( techName )
	thisTechButton.UnavailableTechName:SetText( techName )
	thisTechButton.LockedTechName:SetText( techName )
	thisTechButton.FreeTechName:SetText( techName )

	-- picture
	thisTechButton.TechPortrait:SetHide( not IconHookup( tech.PortraitIndex, 64, tech.IconAtlas, thisTechButton.TechPortrait ) )

	for buttonNum = 1, g_maxSmallButtons do
		thisTechButton["B"..buttonNum]:SetVoid1( techID )
	end
end

-------------------------------------------------
-- Resize the panel to fit the contents, and the scroll bar for the display size
-------------------------------------------------
Controls.TechTreeScrollBar:SetSizeX( Controls.TechTreeScrollPanel:GetSizeX() - 150 )
Controls.EraStack:CalculateSize()
Controls.EraStack:ReprocessAnchoring()
Controls.TechTreeScrollPanel:CalculateInternalSize()

-------------------------------------------------
-- Close Tech Tree
-------------------------------------------------
CloseTechTree = function()
	if g_popupInfoType then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate(g_popupInfoType, 0)
		g_popupInfoType = false
		UI.decTurnTimerSemaphore()
	end
	g_stealingTechTargetPlayerID, g_stealingTechTargetPlayer = -1
	UIManager:DequeuePopup( ContextPtr )
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, CloseTechTree )

-------------------------------------------------
-- Open Tech Tree
AddSerialEventGameMessagePopup( function( popupInfo )
	if popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH then
		g_stealingTechTargetPlayerID = -1
	elseif popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_TECH_TREE or popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TECH_TO_STEAL then
		g_stealingTechTargetPlayerID = gk_mode and popupInfo.Data2 or -1
	else
		return
	end
	g_stealingTechTargetPlayer = Players[ g_stealingTechTargetPlayerID ]

	Events.SerialEventGameMessagePopupShown( popupInfo )

	if g_popupInfoType then
		return CloseTechTree()
	else
		g_popupInfoType = popupInfo.Type
		UIManager:QueuePopup( ContextPtr, PopupPriority_InGameUtmost )
		UI.incTurnTimerSemaphore()
		-- initialize scrollbar position
		if Controls.TechTreeScrollPanel:GetScrollValue() == 0 then
			local pPlayer = Players[Game.GetActivePlayer()]
			local techID = pPlayer:GetCurrentResearch()
			local dx = 0
			if techID < 0 then
				techID = Teams[pPlayer:GetTeam()]:GetTeamTechs():GetLastTechAcquired()
				dx = 1
			end
			local tech = GameInfoTechnologies[techID]
			local x = tech and tech.GridX
			if x then
				Controls.TechTreeScrollPanel:SetScrollValue( min(1,max(0,( (x + dx)*g_blockSpacingX/Controls.TechTreeScrollPanel:GetSizeX() - 0.5) / max(1,1/Controls.TechTreeScrollPanel:GetRatio() - 1) ) ) )
			end
		end
		return RefreshDisplay()
	end
end, ButtonPopupTypes.BUTTONPOPUP_TECH_TREE, ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH, ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TECH_TO_STEAL )

Events.SerialEventResearchDirty.Add( RefreshDisplay )

-------------------------------------------------
-- Key Down Processing
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				CloseTechTree()
			end
			return true
		end
	end)
end

-------------------------------------------------
-- Initialize active player data
local function InitActivePlayerData()
	-- make TechButtonInclude gather info about this active player's unique units and buldings
	local civ = GameInfo.Civilizations[Players[ Game.GetActivePlayer() ]:GetCivilizationType()]
	GatherInfoAboutUniqueStuff( civ and civ.Type )
	return RefreshDisplay( true )
end
InitActivePlayerData()

Events.GameplaySetActivePlayer.Add( function()
	-- So some extra stuff gets re-built on the refresh call
	if g_popupInfoType then
		CloseTechTree() -- so the next active player does not have to
	end
	InitActivePlayerData()
end)

end)
