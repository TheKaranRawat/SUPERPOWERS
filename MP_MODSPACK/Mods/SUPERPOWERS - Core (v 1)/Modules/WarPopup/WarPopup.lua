-------------------------------------------------------
-- War Declaration Popup (with fade + slide transition)
-- UI only: no Network calls, no gameplay state changes, so it is MP-safe.
-- Every client receives the same WarStateChanged event and shows its own banner.
-------------------------------------------------------

-- ===== options =====
local DISPLAY_SECONDS      = 4     -- time the banner stays fully visible
local FADE_IN_SECONDS      = 1.2
local FADE_OUT_SECONDS     = 1.5
local SLIDE_PIXELS         = 250     -- banner slides down this far while fading in (up while fading out); 0 = fade only
local BASE_Y               = 50    -- must match the Offset Y of WarBox in WarPopup.xml
local ICON_SIZE            = 64     -- must match the icon Image sizes in WarPopup.xml
local SHOW_CITY_STATES     = false   -- also announce wars involving city-states
local ONLY_IF_MET_BOTH     = true   -- only announce wars between civs you have met (or that involve you)
local FIRST_TEAM_IS_AGGRESSOR = true -- WarStateChanged(team1, team2, true): team1 is assumed to be the declarer.
                                     -- If the names show up swapped in your game, set this to false.
-- ===================

include( "IconSupport" )	-- provides CivIconHookup

local L = Locale.ConvertTextKey

local g_ready = false
local g_queue = {}
local g_seen = {}
local g_seenTurn = -1

local g_state = nil		-- nil (idle) / "in" / "hold" / "out"
local g_stateStart = 0

local fadeControls = {
	Controls.WarBox, Controls.WarTitle, Controls.WarText, Controls.CloseButton,
	Controls.AggressorBG, Controls.AggressorShadow, Controls.AggressorIcon,
	Controls.DefenderBG, Controls.DefenderShadow, Controls.DefenderIcon,
}

local function Smooth( t )
	if t < 0 then t = 0 elseif t > 1 then t = 1 end
	return t * t * ( 3 - 2 * t )	-- smoothstep easing
end

local function ApplyVisual( p )	-- p: 0 = invisible, 1 = fully shown
	for i = 1, #fadeControls do
		fadeControls[i]:SetAlpha( p )
	end
	Controls.WarBox:SetOffsetY( BASE_Y - SLIDE_PIXELS * ( 1 - p ) )
end

local StartNext	-- forward declaration

local function SetState( state )
	g_state = state
	g_stateStart = os.clock()
end

local function OnUpdate()
	local now = os.clock()
	local t = now - g_stateStart
	if g_state == "in" then
		ApplyVisual( Smooth( t / FADE_IN_SECONDS ) )
		if t >= FADE_IN_SECONDS then
			ApplyVisual( 1 )
			SetState( "hold" )
		end
	elseif g_state == "hold" then
		if t >= DISPLAY_SECONDS then
			SetState( "out" )
		end
	elseif g_state == "out" then
		ApplyVisual( 1 - Smooth( t / FADE_OUT_SECONDS ) )
		if t >= FADE_OUT_SECONDS then
			Controls.WarBox:SetHide( true )
			StartNext()
		end
	end
end

function StartNext()
	local entry = table.remove( g_queue, 1 )
	if not entry then
		g_state = nil
		Controls.WarBox:SetHide( true )
		ContextPtr:ClearUpdate()
		return
	end
	Controls.WarText:SetText( entry.text )
	-- same call shape as the EUI city view's CivIconHookup (handles city-states too)
	CivIconHookup( entry.aggressorID, ICON_SIZE, Controls.AggressorIcon, Controls.AggressorBG, Controls.AggressorShadow, false, true )
	CivIconHookup( entry.defenderID, ICON_SIZE, Controls.DefenderIcon, Controls.DefenderBG, Controls.DefenderShadow, false, true )
	ApplyVisual( 0 )			-- set invisible BEFORE showing to avoid a one-frame flash
	Controls.WarBox:SetHide( false )
	SetState( "in" )
	ContextPtr:SetUpdate( OnUpdate )
end

local function Enqueue( entry )
	g_queue[ #g_queue + 1 ] = entry
	if not g_state then
		StartNext()
	end
end

-- OK button: fade out now (the next queued banner, if any, follows)
local function OnClose()
	if g_state and g_state ~= "out" then
		SetState( "out" )
	end
end

-- Returns the player that represents a team (its leader), or nil.
local function GetTeamPlayer( teamID )
	local team = Teams[ teamID ]
	if not team then return nil end
	return Players[ team:GetLeaderID() ]
end

local function GetTeamName( player )
	return L( player:GetCivilizationShortDescriptionKey() )
end

local function OnWarStateChanged( teamA, teamB, isAtWar )
	if not g_ready or not isAtWar then
		return
	end

	-- the event can fire once per direction; announce each pair once per turn
	local turn = Game.GetGameTurn()
	if turn ~= g_seenTurn then
		g_seenTurn = turn
		g_seen = {}
	end
	local key = math.min( teamA, teamB ) .. ":" .. math.max( teamA, teamB )
	if g_seen[ key ] then
		return
	end
	g_seen[ key ] = true

	local playerA, playerB = GetTeamPlayer( teamA ), GetTeamPlayer( teamB )
	if not playerA or not playerB then
		return
	end
	if playerA:IsBarbarian() or playerB:IsBarbarian() then
		return
	end
	if not SHOW_CITY_STATES and ( playerA:IsMinorCiv() or playerB:IsMinorCiv() ) then
		return
	end

	-- only tell the player about wars they can know about
	local activeTeamID = Game.GetActiveTeam()
	local involvesActive = ( teamA == activeTeamID or teamB == activeTeamID )
	if ONLY_IF_MET_BOTH and not involvesActive then
		local activeTeam = Teams[ activeTeamID ]
		if not ( activeTeam:IsHasMet( teamA ) and activeTeam:IsHasMet( teamB ) ) then
			return
		end
	end

	local aggressor, defender = playerA, playerB
	if not FIRST_TEAM_IS_AGGRESSOR then
		aggressor, defender = playerB, playerA
	end

	print( "WarPopup: war declared", turn, teamA, teamB )	-- check Lua.log to verify who the aggressor is
	Enqueue{
		text = GetTeamName( aggressor ) .. " has declared war on " .. GetTeamName( defender ) .. "!",
		aggressorID = aggressor:GetID(),
		defenderID = defender:GetID(),
	}
end

Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose )

-- ignore anything fired while the game is still loading
Events.SequenceGameInitComplete.Add( function()
	g_ready = true
end )

Events.WarStateChanged.Add( OnWarStateChanged )

-- clear queued banners if the active player changes (hotseat)
Events.GameplaySetActivePlayer.Add( function()
	g_queue = {}
	g_state = nil
	Controls.WarBox:SetHide( true )
	ContextPtr:ClearUpdate()
end )