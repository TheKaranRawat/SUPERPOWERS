--==========================================================
-- Tech Tree Popup
-- Re-written by bc1 using Notepad++
-- capture choose tech & steal tech popup events
-- fix escape/enter popup exit code
-- support Technology_ORPrereqTechs in addition to Technology_PrereqTechs
-- code is common except for vanila gk_mode needs to be set false
--
-- Added: fade + slide in from the bottom, fade + slide out on close
--        (Esc / Enter / right click / mouse side button)
-- Added: multiplayer / hot-seat safety and performance work (see notes in code)
-- Added: selectable easing curves for slide and fade, backdrop alpha via color
--==========================================================

--==========================================================
-- USER CONFIGURATION
--==========================================================
local TECH_TREE_ANIMATION = {
	Enabled           = true,	-- false = open/close instantly, no animation
	-- Fade and slide have their own timings, so the fade can be slower (or faster) than the slide.
	-- Animation is finished when the longer of the two is done. 0 = that part is instant.
	FadeInTime        = 0.5,	-- seconds for the whole panel to fade in
	FadeOutTime       = 0.5,	-- seconds for the whole panel to fade out
	SlideInTime       = 0.4,	-- seconds to slide in
	SlideOutTime      = 0.4,	-- seconds to slide out
	SlideDistance     = 720,	-- pixels the panel travels. Positive = comes up from below, negative = comes down from above
	-- Easing curves. Choices: "Smoothstep", "Smootherstep", "OutCubic", "OutQuint", "OutExpo", "InOutQuint"
	-- Closing plays the curve in reverse (out-curves become slow start, fast exit).
	SlideCurve        = "OutQuint",		-- curve for the slide
	FadeEase          = "Smootherstep",	-- curve for the fade (avoid OutExpo / OutQuint here, the fade barely reads)
	FadeCurve         = 1.0,	-- extra power applied to the fade: 1 = none; above 1 stays transparent longer then fades in late, below 1 fades in early
	BackdropSlides    = true,	-- true = the dark backdrop slides with the panel, false = it only fades (stays full screen)
	CloseOnRightClick = true,	-- right click on empty space closes the tech tree (right click on a tech still opens the Pedia)
	CloseOnSideButton1 = true,	-- mouse side button 1 (usually "Back") closes the tech tree
	CloseOnSideButton2 = false,	-- mouse side button 2 (usually "Forward") closes the tech tree
}
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

-- popup / animation state
local g_isShown = false	-- our context is queued in the popup manager (includes the fade-out)
local g_isClosing = false	-- fade-out in progress; the game side of the popup is already released
local g_needsFullRefresh = true	-- small buttons must be rebuilt on next open (active player changed)

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

			if startY < endY then -- elbow case: prereq above, tech below (down-right turn)

				AddElbowPipe( elbowX + connectorElbowOffsetX2, startY*blockSpacingY + connectorOffsetY1, 72, 0 )	-- upper corner
				AddElbowPipe( elbowX + connectorElbowOffsetX1, endY*blockSpacingY + connectorOffsetY2 , 0, 72 )		-- lower corner

			elseif startY > endY then -- elbow case: prereq below, tech above (up-right turn)

				AddElbowPipe( elbowX + connectorElbowOffsetX1, endY*blockSpacingY + connectorOffsetY1, 0, 0 )		-- upper corner
				AddElbowPipe( elbowX + connectorElbowOffsetX2, startY*blockSpacingY + connectorOffsetY2, 72, 72 )	-- lower corner
			end
		end
	end
end

-------------------------------------------------
-- Mouse Click Management
-------------------------------------------------

local function TechSelected( techID )
	if g_isClosing then return end	-- ignore clicks while fading out
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
-- Performance: per-player values are fetched once per refresh (not once per tech),
-- and controls are only touched when their state actually changed.
local STATE_RESEARCHED, STATE_FREE, STATE_CURRENT, STATE_AVAILABLE, STATE_UNAVAILABLE, STATE_LOCKED = 1, 2, 3, 4, 5, 6
local g_techState = {}		-- techID -> STATE_*
local g_techClickable = {}	-- techID -> boolean
local g_techQueueText = {}	-- techID -> queue label text (nil = hidden)
local g_techTurnText = {}	-- techID -> turns label text (false = hidden)
local g_lastEra

local function RefreshDisplay( isFullRefresh )

	local currentEra = 0
	local activePlayer = Players[ Game.GetActivePlayer() ]
	local activeTeamTechs = Teams[ Game.GetActiveTeam() ]:GetTeamTechs()

	-- values that are the same for every tech
	local numFreeTechs = activePlayer:GetNumFreeTechs()
	local currentResearchID = activePlayer:GetCurrentResearch()
	local showTurns = g_scienceEnabled and activePlayer:GetScience() > 0
	local hasResearchQueue = activePlayer:GetLengthResearchQueue() > 1
	local stealingTeam = g_stealingTechTargetPlayer and Teams[ g_stealingTechTargetPlayer:GetTeam() ]
	local isPickingFreeTech = g_stealingTechTargetPlayer or numFreeTechs > 0

	for tech in GameInfoTechnologies() do
		local techID = tech.ID
		local thisTechButton = g_techButtons[ techID ]

		-- Rebuild the small buttons if needed
		if isFullRefresh then
			AddSmallButtonsToTechButton( thisTechButton, tech, g_maxSmallButtons, 45 )
			g_techClickable[ techID ] = nil	-- force callbacks to be registered again
		end

		local state, turnLabel, queueText, queueUpdate, isClickable

		if activeTeamTechs:HasTech( techID ) then
		-- the active player already has this tech
			state = STATE_RESEARCHED
			-- update the era marker for this tech
			local eraID = GameInfoTypes[tech.Era]
			if eraID and currentEra < eraID then
				currentEra = eraID
			end
		else
			local canResearchThisTech = activePlayer:CanResearch( techID )

			if isPickingFreeTech then
			-- Stealing a tech or Choosing a free tech
				if canResearchThisTech and (
					( stealingTeam and stealingTeam:IsHasTech( techID ) )
					or ( not g_stealingTechTargetPlayer and ( not gk_mode or activePlayer:CanResearchForFree( techID ) ) ) )
				then
					state = STATE_FREE
					turnLabel = thisTechButton.FreeTurns
					queueText = freeString	-- update queue number to say "FREE"
					isClickable = true
				else
					state = STATE_LOCKED
				end

			-- the active player is currently researching this one
			elseif currentResearchID == techID then
				state = STATE_CURRENT
				turnLabel = thisTechButton.CurrentlyResearchingTurns
				queueUpdate = hasResearchQueue	-- update queue number if needed
				isClickable = true -- to clear research queue

			-- the active player can research this one right now if he wants
			elseif canResearchThisTech and g_scienceEnabled then
				state = STATE_AVAILABLE
				turnLabel = thisTechButton.AvailableTurns
				queueUpdate = true	-- update queue number if needed
				isClickable = true

			elseif g_scienceEnabled and activePlayer:CanEverResearch( techID ) then
			-- currently unavailable
				state = STATE_UNAVAILABLE
				queueUpdate = true	-- update queue number if needed
				turnLabel = thisTechButton.UnavailableTurns
				isClickable = true  -- shift clickable
			else
				state = STATE_LOCKED
			end
		end

		-- show only the panel for the current state
		if g_techState[ techID ] ~= state then
			g_techState[ techID ] = state
			g_techTurnText[ techID ] = nil	-- the turns label is a different control now
			thisTechButton.AlreadyResearched:SetHide( state ~= STATE_RESEARCHED )
			thisTechButton.FreeTech:SetHide( state ~= STATE_FREE )
			thisTechButton.CurrentlyResearching:SetHide( state ~= STATE_CURRENT )
			thisTechButton.Available:SetHide( state ~= STATE_AVAILABLE )
			thisTechButton.Unavailable:SetHide( state ~= STATE_UNAVAILABLE )
			thisTechButton.Locked:SetHide( state ~= STATE_LOCKED )
		end

		-- queue number
		if state == STATE_LOCKED then
			queueText = lockedString	-- have queue number say "LOCKED"
		elseif queueUpdate then
			local queuePosition = activePlayer:GetQueuePosition( techID )
			if queuePosition ~= -1 then
				queueText = queuePosition
			end
		end
		if g_techQueueText[ techID ] ~= queueText then
			g_techQueueText[ techID ] = queueText
			if queueText then
				thisTechButton.TechQueueLabel:SetText( queueText )
			end
			thisTechButton.TechQueue:SetHide( not queueText )
		end

		-- click handlers (only re-registered when clickability changes)
		isClickable = isClickable and true or false
		if g_techClickable[ techID ] ~= isClickable then
			g_techClickable[ techID ] = isClickable
			if isClickable then
				thisTechButton.TechButton:RegisterCallback( Mouse.eLClick, TechSelected )
				for buttonNum = 1, g_maxSmallButtons do
					thisTechButton[ "B"..buttonNum ]:RegisterCallback( Mouse.eLClick, TechSelected )
				end
			else
				thisTechButton.TechButton:ClearCallback( Mouse.eLClick )
				for buttonNum = 1, g_maxSmallButtons do
					thisTechButton[ "B"..buttonNum ]:ClearCallback( Mouse.eLClick )
				end
			end
		end

		-- turns label (the research-turns query is only made for techs that show it)
		if turnLabel then
			local turnText = showTurns and L( "TXT_KEY_STR_TURNS", activePlayer:GetResearchTurnsLeft( techID, true ) ) or false
			if g_techTurnText[ techID ] ~= turnText then
				g_techTurnText[ techID ] = turnText
				if turnText then
					turnLabel:SetText( turnText )
				end
				turnLabel:SetHide( not turnText )
			end
		end
	end

	-- update the era panels
	if isFullRefresh or g_lastEra ~= currentEra then
		g_lastEra = currentEra
		for eraID, eraBlock in pairs( g_eraBlocks ) do
			eraBlock.OldBar:SetHide( eraID >= currentEra )
			eraBlock.CurrentBlock:SetHide( eraID ~= currentEra )
			eraBlock.CurrentTop:SetHide( eraID ~= currentEra )
			eraBlock.FutureBlock:SetHide( eraID <= currentEra )
		end
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
-- Open / close animation
-- Driven by a per-frame update that is ONLY registered while animating.
-- The animation is purely visual (local UI): it never touches game state,
-- so it cannot cause a multiplayer desync.
-------------------------------------------------
local g_backdrop = Controls.Backdrop		-- dim layer: fades (and slides if BackdropSlides)
local g_slideRoot = Controls.SlideRoot		-- tech tree: fades and slides
local g_slideProgress = 0	-- 0 = hidden, 1 = fully shown
local g_fadeProgress = 0	-- 0 = hidden, 1 = fully shown
local g_animDir = 0		-- 1 = opening, -1 = closing, 0 = idle
local g_lastAlpha, g_lastOffset

local floor = math.floor

-- Easing curves: each maps progress 0..1 to eased 0..1 (0 -> 0, 1 -> 1)
local CURVES = {
	Smoothstep   = function( t ) return t * t * (3 - 2 * t) end,
	Smootherstep = function( t ) return t * t * t * (t * (t * 6 - 15) + 10) end,
	OutCubic     = function( t ) local u = 1 - t return 1 - u * u * u end,
	OutQuint     = function( t ) local u = 1 - t return 1 - u * u * u * u * u end,
	OutExpo      = function( t ) return t <= 0 and 0 or t >= 1 and 1 or 1 - 2 ^ (-10 * t) end,
	InOutQuint   = function( t )
		if t < 0.5 then return 16 * t * t * t * t * t end
		local u = -2 * t + 2
		return 1 - u * u * u * u * u / 2
	end,
}

-- The backdrop is a Box whose darkness comes from its Color attribute, which SetAlpha does not scale.
-- So its alpha is driven through the color instead.
local BACKDROP_COLOR = { x = 0, y = 0, z = 0, w = 1 }	-- r,g,b from the XML: Color="0,0,0,220"
local BACKDROP_MAX_ALPHA = 220 / 255	-- keep in sync with the alpha in the XML

local function ApplyAnimation()
	local cfg = TECH_TREE_ANIMATION
	local alpha = ( CURVES[ cfg.FadeEase ] or CURVES.Smootherstep )( g_fadeProgress )
	local curve = cfg.FadeCurve
	if curve and curve ~= 1 and alpha > 0 then
		alpha = alpha ^ curve
	end
	local slide = ( CURVES[ cfg.SlideCurve ] or CURVES.Smootherstep )( g_slideProgress )
	local offset = floor( (1 - slide) * cfg.SlideDistance + 0.5 )
	if alpha ~= g_lastAlpha then
		g_lastAlpha = alpha
		BACKDROP_COLOR.w = alpha * BACKDROP_MAX_ALPHA
		g_backdrop:SetColor( BACKDROP_COLOR )
		g_slideRoot:SetAlpha( alpha )
	end
	if offset ~= g_lastOffset then
		g_lastOffset = offset
		g_slideRoot:SetOffsetVal( 0, offset )
		g_backdrop:SetOffsetVal( 0, cfg.BackdropSlides and offset or 0 )
	end
end

local function SetProgress( value )
	g_slideProgress = value
	g_fadeProgress = value
end

-- Release the game side of the popup. Safe to call more than once.
local function ReleasePopup()
	if g_popupInfoType then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate( g_popupInfoType, 0 )
		g_popupInfoType = false
		UI.decTurnTimerSemaphore()
	end
	g_stealingTechTargetPlayerID, g_stealingTechTargetPlayer = -1
end

-- Remove our context from the popup manager once it is fully faded out.
local function FinishClose()
	ContextPtr:ClearUpdate()
	g_animDir = 0
	SetProgress( 0 )
	g_isClosing = false
	ApplyAnimation()
	if g_isShown then
		g_isShown = false
		UIManager:DequeuePopup( ContextPtr )
	end
end

-- move a 0..1 progress value toward target (1 or 0) over 'duration' seconds; 0 duration = instant
local function Step( value, target, dt, duration )
	if not duration or duration <= 0 then return target end
	if target > value then
		value = value + dt / duration
		return value > target and target or value
	else
		value = value - dt / duration
		return value < target and target or value
	end
end

local function OnUpdate( fDTime )
	if g_animDir == 0 then
		return ContextPtr:ClearUpdate()
	end
	if fDTime > 0.1 then fDTime = 0.1 end	-- a frame hitch must not skip the animation
	local cfg = TECH_TREE_ANIMATION
	local target = g_animDir > 0 and 1 or 0
	local fadeTime = g_animDir > 0 and cfg.FadeInTime or cfg.FadeOutTime
	local slideTime = g_animDir > 0 and cfg.SlideInTime or cfg.SlideOutTime
	g_fadeProgress = Step( g_fadeProgress, target, fDTime, fadeTime )
	g_slideProgress = Step( g_slideProgress, target, fDTime, slideTime )
	if g_fadeProgress == target and g_slideProgress == target then
		if g_animDir < 0 then
			return FinishClose()
		end
		g_animDir = 0
		ContextPtr:ClearUpdate()	-- nothing runs per frame while the screen is idle
	end
	ApplyAnimation()
end

-- Returns true if the animation completed immediately (disabled / zero time)
local function StartAnimation( dir )
	local cfg = TECH_TREE_ANIMATION
	local fadeTime = dir > 0 and cfg.FadeInTime or cfg.FadeOutTime
	local slideTime = dir > 0 and cfg.SlideInTime or cfg.SlideOutTime
	if not cfg.Enabled or ( (not fadeTime or fadeTime <= 0) and (not slideTime or slideTime <= 0) ) then
		g_animDir = 0
		SetProgress( dir > 0 and 1 or 0 )
		ContextPtr:ClearUpdate()
		ApplyAnimation()
		return true
	end
	g_animDir = dir
	ContextPtr:SetUpdate( OnUpdate )
	return false
end

-------------------------------------------------
-- Close Tech Tree
-- The game side (popup processed, turn timer) is released immediately, so a
-- fade-out can never hold up the popup queue or the multiplayer turn timer.
-- instant = true skips the animation (active player change, forced hide)
-------------------------------------------------
CloseTechTree = function( instant )
	if g_isClosing and not instant then return end	-- already closing
	ReleasePopup()
	if not g_isShown then return end
	if instant then
		return FinishClose()
	end
	g_isClosing = true
	if StartAnimation( -1 ) then
		return FinishClose()
	end
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, function() return CloseTechTree() end )

-- Another popup (e.g. the Civilopedia opened by right clicking a tech) hides this context while the
-- tech tree is still logically open. Keep all state untouched while hidden and restore it on show.
local g_hiddenByOtherPopup = false
ContextPtr:SetShowHideHandler( function( isHide )
	if isHide then
		ContextPtr:ClearUpdate()	-- no per-frame updates while hidden
		g_hiddenByOtherPopup = g_isShown
	elseif g_isShown and g_hiddenByOtherPopup then
		g_hiddenByOtherPopup = false
		if g_isClosing then
			return FinishClose()	-- it was closing when hidden: finish now
		end
		-- shown again: snap to fully visible (an animation may have been interrupted)
		g_animDir = 0
		SetProgress( 1 )
		ApplyAnimation()
	end
end)

-------------------------------------------------
-- Open Tech Tree
AddSerialEventGameMessagePopup( function( popupInfo )
	local popupType = popupInfo.Type
	local targetPlayerID
	if popupType == ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH then
		targetPlayerID = -1
	elseif popupType == ButtonPopupTypes.BUTTONPOPUP_TECH_TREE or popupType == ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TECH_TO_STEAL then
		targetPlayerID = gk_mode and popupInfo.Data2 or -1
	else
		return
	end

	Events.SerialEventGameMessagePopupShown( popupInfo )

	if g_popupInfoType and not g_isClosing then
		-- already open: the same hotkey toggles it closed
		return CloseTechTree()
	end

	g_stealingTechTargetPlayerID = targetPlayerID
	g_stealingTechTargetPlayer = targetPlayerID and targetPlayerID >= 0 and Players[ targetPlayerID ] or nil

	g_popupInfoType = popupType
	UI.incTurnTimerSemaphore()

	if g_isShown then
		-- re-opened while fading out: our context is still queued, just fade back in from where we are
		g_isClosing = false
	else
		g_isShown = true
		SetProgress( 0 )
		ApplyAnimation()	-- start fully transparent so there is no one-frame flash
		UIManager:QueuePopup( ContextPtr, PopupPriority_InGameUtmost )
	end
	StartAnimation( 1 )

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

	local isFullRefresh = g_needsFullRefresh
	g_needsFullRefresh = false
	return RefreshDisplay( isFullRefresh )
end, ButtonPopupTypes.BUTTONPOPUP_TECH_TREE, ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH, ButtonPopupTypes.BUTTONPOPUP_CHOOSE_TECH_TO_STEAL )

-- Research changes happen constantly (every turn, every AI/player action that dirties research).
-- Nothing is visible while closed, and the next open does a full refresh anyway.
Events.SerialEventResearchDirty.Add( function()
	if g_isShown and not g_isClosing then
		return RefreshDisplay()
	end
end)

-------------------------------------------------
-- Input Processing
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	local RButtonUp = MouseEvents and MouseEvents.RButtonUp
	local WM_XBUTTONDOWN = 523

	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		local cfg = TECH_TREE_ANIMATION
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				CloseTechTree()
			end
			return true

		-- right click on empty space closes the tech screen
		-- (right clicking a tech is consumed by the tech button and opens the Pedia instead)
		elseif RButtonUp and uiMsg == RButtonUp then
			if cfg.CloseOnRightClick then
				CloseTechTree()
				return true
			end

		-- mouse side buttons close the tech screen
		elseif uiMsg == WM_XBUTTONDOWN then
			local xButton = floor( wParam / 65536 ) % 256   -- high word
			if xButton == 0 then xButton = wParam end            -- fallback if already unpacked
			if ( xButton == 1 and cfg.CloseOnSideButton1 ) or ( xButton == 2 and cfg.CloseOnSideButton2 ) then
				CloseTechTree()
				return true
			end
		end
	end)
end

-------------------------------------------------
-- Initialize active player data
-- The (expensive) rebuild of every tech's small buttons is deferred until the
-- screen is actually opened, so it does not slow down game load / player switches.
local function InitActivePlayerData()
	-- make TechButtonInclude gather info about this active player's unique units and buldings
	local civ = GameInfo.Civilizations[Players[ Game.GetActivePlayer() ]:GetCivilizationType()]
	GatherInfoAboutUniqueStuff( civ and civ.Type )
	g_needsFullRefresh = true
end
InitActivePlayerData()

Events.GameplaySetActivePlayer.Add( function()
	-- hot seat / observer switch: drop the screen at once (no animation) so the next player never sees it,
	-- and reset every cached control state because they all belong to the previous player
	CloseTechTree( true )
	g_techState, g_techClickable, g_techQueueText, g_techTurnText = {}, {}, {}, {}
	InitActivePlayerData()
end)

end)