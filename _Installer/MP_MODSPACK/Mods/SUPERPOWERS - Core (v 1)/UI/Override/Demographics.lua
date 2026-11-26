-- Demographics popup: optimized pass (based on bc1's version)
-- + fade/slide open & close animation, right-click to close
do

include "IconHookup"
local CivIconHookup = CivIconHookup

--==========================================================
-- USER CONFIGURATION
--==========================================================
local SLIDE_DURATION  = 0.25   -- seconds the slide takes (0 = no slide)
local SLIDE_DISTANCE  = 60     -- pixels the panel travels (0 = no slide)
local SLIDE_DIRECTION = "up"   -- where the panel slides in FROM: "up", "down", "left", "right"
                               --   "up"   = starts above its resting place and slides down into it
                               --   "down" = starts below and slides up
local FADE_DURATION   = 0.20   -- seconds the fade takes (0 = no fade)
-- Closing uses the same settings, played in reverse.

--==========================================================
-- Minor lua optimizations
--==========================================================
local math_min, math_max = math.min, math.max

local BUTTONPOPUP_DEMOGRAPHICS = ButtonPopupTypes.BUTTONPOPUP_DEMOGRAPHICS
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local GetActivePlayer = Game.GetActivePlayer
local MAX_MAJOR_CIVS = GameDefines.MAX_MAJOR_CIVS
local Players = Players
local PopupPriority = PopupPriority
local TECH_WRITING = GameInfoTypes.TECH_WRITING
local Teams = Teams
local ToNumber = Locale.ToNumber
local UI = UI
local UIManager = UIManager
local YIELD_FOOD = YieldTypes.YIELD_FOOD
local YIELD_PRODUCTION = YieldTypes.YIELD_PRODUCTION

local m_PopupInfo, m_ReplayContext
local m_RequestedGraph  
local m_IsShown = false -- guards turn-timer semaphore + event registration
local m_PercentTechs = 100 / math_max( 1, #GameInfo.Technologies )

--==========================================================
-- Data getters (defined once, no per-refresh closures)
--==========================================================
local function GetPopulation( p ) return p:GetTotalPopulation() end
local function GetFood( p ) return p:CalculateTotalYield( YIELD_FOOD ) end
local function GetProduction( p ) return p:CalculateTotalYield( YIELD_PRODUCTION ) end
local function GetGold( p ) return p:CalculateGrossGold() end
local function GetLand( p ) return p:GetNumPlots() end
local function GetMight( p ) return p:GetMilitaryMight() end
local function GetApproval( p )
	return math_min( 100, math_max( 0, 60 + p:GetExcessHappiness() * 3 ) )
end
local function GetLiteracy( p )
	local teamTechs = Teams[ p:GetTeam() ]:GetTeamTechs()
	if TECH_WRITING and not teamTechs:HasTech( TECH_WRITING ) then
		return 0
	end
	return teamTechs:GetNumTechsKnown() * m_PercentTechs
end

local m_Entries = {
	{ name = "TXT_KEY_DEMOGRAPHICS_POPULATION", tip = "TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE", get = GetPopulation, fmt = "#,###,###,###'[ICON_CITIZEN]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_FOOD",       tip = "TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE",       get = GetFood,       fmt = "#,###,###,###'[ICON_FOOD]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_PRODUCTION", tip = "TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE", get = GetProduction, fmt = "#,###,###,###'[ICON_PRODUCTION]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_GOLD",       tip = "TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE",       get = GetGold,       fmt = "#,###,###,###'[ICON_GOLD]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_LAND",                                                        get = GetLand,       fmt = "#,###,###,###" },
	{ name = "TXT_KEY_REPLAY_DATA_MILITARYMIGHT",                                                get = GetMight,      fmt = "#,###,###,###'[ICON_STRENGTH]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_APPROVAL",                                                    get = GetApproval,   fmt = "#'%'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_LITERACY",                                                    get = GetLiteracy,   fmt = "#'%'" },
}

for _, entry in ipairs( m_Entries ) do
	local instance = {}
	ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack )
	instance.Name:LocalizeAndSetText( entry.name )
	if entry.tip then
		instance.ValueTT:LocalizeAndSetToolTip( entry.tip )
		instance.BestTT:LocalizeAndSetToolTip( entry.tip )
		instance.AverageTT:LocalizeAndSetToolTip( entry.tip )
		instance.WorstTT:LocalizeAndSetToolTip( entry.tip )
	end
	entry.instance = instance
end
Controls.MainStack:CalculateSize()
Controls.MainStack:ReprocessAnchoring()
Controls.BigStack:ReprocessAnchoring()

--==========================================================
-- Refresh
--==========================================================
-- Reused tables: no garbage generated per refresh
local m_Players, m_IconIDs = {}, {}

-- Build the list of living major civs ONCE per refresh (was 8x) and
-- resolve "has the active player met them" ONCE per civ (was 2x per entry).
local function CollectPlayers( activePlayerID, activeTeam )
	local count = 0
	for i = 0, MAX_MAJOR_CIVS - 1 do -- was 0..MAX_MAJOR_CIVS (off by one)
		local player = Players[i]
		if player and player:IsAlive() and not player:IsMinorCiv() then
			count = count + 1
			m_Players[count] = player
			m_IconIDs[count] = ( i == activePlayerID or activeTeam:IsHasMet( player:GetTeam() ) ) and i or -1
		end
	end
	return count
end

local function RefreshEntry( entry, activePlayer, activeIconID, count )
	local get, fmt, instance = entry.get, entry.fmt, entry.instance
	local playerVal = get( activePlayer )
	local rank = 1
	local highest, highestIcon = playerVal, activeIconID
	local lowest, lowestIcon = playerVal, activeIconID
	local accum = 0

	for n = 1, count do
		local player = m_Players[n]
		local value = ( player == activePlayer ) and playerVal or get( player )
		accum = accum + value
		if value > playerVal then rank = rank + 1 end
		if value > highest then highest, highestIcon = value, m_IconIDs[n] end
		if value <= lowest then lowest, lowestIcon = value, m_IconIDs[n] end
	end

	-- avoid NaN if the active player is dead/observing and nobody is counted
	local average = count > 0 and accum / count or playerVal

	instance.Value:SetText( ToNumber( playerVal, fmt ) )
	CivIconHookup( highestIcon, 32, instance.BestIcon, instance.BestIconBG, instance.BestIconShadow, false, true )
	instance.Best:SetText( ToNumber( highest, fmt ) )
	instance.Average:SetText( ToNumber( average, fmt ) )
	CivIconHookup( lowestIcon, 32, instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow, false, true )
	instance.Worst:SetText( ToNumber( lowest, fmt ) ) -- was LocalizeAndSetText on a number string
	instance.Rank:SetText( ToNumber( rank, "#" ) )
end

local function RefreshScreen()
	local activePlayerID = GetActivePlayer()
	local activePlayer = Players[ activePlayerID ]
	if not activePlayer then return end
	local activeTeam = Teams[ activePlayer:GetTeam() ]

	local count = CollectPlayers( activePlayerID, activeTeam )
	for i = count + 1, #m_Players do -- drop stale refs from a previous, larger refresh
		m_Players[i], m_IconIDs[i] = nil, nil
	end

	for i = 1, #m_Entries do
		RefreshEntry( m_Entries[i], activePlayer, activePlayerID, count )
	end
	CivIconHookup( activePlayerID, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true )
end

--==========================================================
-- Open / close animation (fade + slide)
--==========================================================
-- Every control in this list is animated together, each from its own resting
-- offset (captured once so we can always return to it exactly).
--   "InGameSet" = the panel frame (also holds the close button, civ icon and title)
--   "BigStack"  = the column headers + data rows (lives in a separate container)
-- BGBlock (the dimming backdrop) is deliberately NOT listed, so it stays static.
-- If some part of the panel still stays put, add its control ID here.
local ANIMATED_CONTROL_IDS = { "BigStack", "InGameSet" }

local m_AnimControls = {}
for _, id in ipairs( ANIMATED_CONTROL_IDS ) do
	local ctrl = Controls[ id ]
	if ctrl then
		local x, y = ctrl:GetOffsetVal()
		m_AnimControls[ #m_AnimControls + 1 ] = { control = ctrl, baseX = x or 0, baseY = y or 0 }
	end
end

-- Unit vector pointing from the resting place to the slide start position
local m_DirX, m_DirY = 0, 0
do
	local dir = string.lower( SLIDE_DIRECTION or "up" )
	if     dir == "up"    then m_DirY = -1
	elseif dir == "down"  then m_DirY =  1
	elseif dir == "left"  then m_DirX = -1
	elseif dir == "right" then m_DirX =  1
	else                       m_DirY = -1 end
end

local m_Anim = nil -- nil when idle, otherwise { mode = "in"|"out", t = elapsed seconds }
local m_TotalAnimTime = math_max( SLIDE_DURATION, FADE_DURATION, 0 )

-- ease-out cubic: fast start, gentle landing (used for both directions
-- since closing is simply the same curve run in reverse)
local function Ease( x )
	if x <= 0 then return 0 end
	if x >= 1 then return 1 end
	local inv = 1 - x
	return 1 - inv * inv * inv
end

local function Progress( elapsed, duration )
	if duration <= 0 then return 1 end
	return math_min( 1, elapsed / duration )
end

-- shown: 0 = fully hidden/offset, 1 = fully visible/at rest
local function ApplyAnimState( fadeShown, slideShown )
	local away = SLIDE_DISTANCE * ( 1 - slideShown )
	for i = 1, #m_AnimControls do
		local a = m_AnimControls[i]
		a.control:SetAlpha( fadeShown )
		a.control:SetOffsetVal( a.baseX + m_DirX * away, a.baseY + m_DirY * away )
	end
end

local function ResetAnimState()
	m_Anim = nil
	ContextPtr:ClearUpdate()
	ApplyAnimState( 1, 1 )
end

local function OnAnimUpdate( deltaTime )
	if not m_Anim then
		ContextPtr:ClearUpdate()
		return
	end
	m_Anim.t = m_Anim.t + deltaTime
	local fade  = Ease( Progress( m_Anim.t, FADE_DURATION ) )
	local slide = Ease( Progress( m_Anim.t, SLIDE_DURATION ) )
	local finished = m_Anim.t >= m_TotalAnimTime

	if m_Anim.mode == "in" then
		ApplyAnimState( fade, slide )
		if finished then
			ResetAnimState()
		end
	else -- "out"
		ApplyAnimState( 1 - fade, 1 - slide )
		if finished then
			ResetAnimState()
			UIManager:DequeuePopup( ContextPtr ) -- hide handler does the rest
		end
	end
end

local function StartAnim( mode )
	if m_TotalAnimTime <= 0 then
		ResetAnimState()
		return false
	end
	m_Anim = { mode = mode, t = 0 }
	if mode == "in" then
		ApplyAnimState( 0, 0 ) -- start from hidden so there's no one-frame flash
	elseif ContextPtr:GetID() ~= "EndGameDemographics" then
		-- the replay viewer panel is overlaid on this screen: have it fade out in sync
		LuaEvents.ReplayViewerAnimateOut()
	end
	ContextPtr:SetUpdate( OnAnimUpdate )
	return true
end

--==========================================================
-- Closing
--==========================================================
-- Immediate close (no animation): used when the screen must vanish at once,
-- e.g. hotseat player change.
local function ClosePopupNow()
	ResetAnimState()
	UIManager:DequeuePopup( ContextPtr )
end

-- Animated close: plays the fade/slide out, then dequeues.
local function ClosePopup()
	if ContextPtr:IsHidden() then return end
	if m_Anim and m_Anim.mode == "out" then return end -- already closing
	if not StartAnim( "out" ) then
		UIManager:DequeuePopup( ContextPtr )
	end
end

--==========================================================
-- Show / hide
--==========================================================
ContextPtr:SetShowHideHandler( function( isHide, isInit )
	if isInit then return end
	if isHide then
		ResetAnimState() -- never leave the panel faded/offset for the next open
		Events.SerialEventGameMessagePopupProcessed.CallImmediate( BUTTONPOPUP_DEMOGRAPHICS, 0 )
		if m_IsShown then -- balanced: exactly one dec per inc, one Remove per Add
			m_IsShown = false
			Events.NewGameTurn.Remove( RefreshScreen )
			UI.decTurnTimerSemaphore()
		end
		if m_ReplayContext then
			m_ReplayContext:SetHide( true )
		end
	else
		if not m_IsShown then
			m_IsShown = true
			UI.incTurnTimerSemaphore()
			Events.NewGameTurn.Add( RefreshScreen )
		end
		if m_PopupInfo then
			Events.SerialEventGameMessagePopupShown( m_PopupInfo )
		end
		RefreshScreen()
		StartAnim( "in" )
		if m_ReplayContext then
			m_ReplayContext:ChangeParent( ContextPtr )
			m_ReplayContext:SetHide( false )
			print( "DEMO: show handler, replayContext=", m_ReplayContext, "requested=", m_RequestedGraph )
			if m_RequestedGraph then
				LuaEvents.ReplaySelectGraph( m_RequestedGraph )
				m_RequestedGraph = nil
			end
		end
	end
end )

if ContextPtr:GetID() == "EndGameDemographics" then
	Controls.BGBlock:SetHide( true )
	Controls.InGameSet:SetHide( true )
else
	m_ReplayContext = ContextPtr:LookUpControl( "../EndGameMenu/EndGameReplay" )
	-- right-click inside the replay viewer overlay asks us to close (ClosePopup ignores repeats)
	LuaEvents.ReplayViewerRequestClose.Add( ClosePopup )
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	local RButtonDown = MouseEvents.RButtonDown
	local RButtonUp = MouseEvents.RButtonUp
	local WM_XBUTTONDOWN = 523

	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				ClosePopup()
			end
			return true

		-- right click closes the popup (swallow the press too so it doesn't leak to the map)
		elseif uiMsg == RButtonDown then
			return true
		elseif uiMsg == RButtonUp then
			ClosePopup()
			return true

		-- mouse side button closes the popup
		elseif uiMsg == WM_XBUTTONDOWN then
			local xButton = math.floor( wParam / 65536 ) % 256   -- high word
			if xButton == 0 then xButton = wParam end            -- fallback if already unpacked
			if xButton == 1 then   -- same button as the other screens; use 1 for the other one
				ClosePopup()
				return true
			end
		end
	end )
	AddSerialEventGameMessagePopup( function( popupInfo )
		if popupInfo.Type == BUTTONPOPUP_DEMOGRAPHICS then
			m_PopupInfo = popupInfo
			m_RequestedGraph = popupInfo.Data2 ~= 0 and popupInfo.Data2 or nil
			print( "DEMO: popup received, Data1=", popupInfo.Data1, "Data2=", popupInfo.Data2, "requested=", m_RequestedGraph )
			if popupInfo.Data1 == 1 then
				if not ContextPtr:IsHidden() then
					ClosePopup()
				else
					UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost )
				end
			else
				UIManager:QueuePopup( ContextPtr, PopupPriority.Demographics )
			end
		end
	end, BUTTONPOPUP_DEMOGRAPHICS )
end

Controls.BackButton:RegisterCallback( Mouse.eLClick, ClosePopup )
-- Hotseat/MP: close immediately when the active player changes so one player's data isn't shown to the next
Events.GameplaySetActivePlayer.Add( ClosePopupNow )
end