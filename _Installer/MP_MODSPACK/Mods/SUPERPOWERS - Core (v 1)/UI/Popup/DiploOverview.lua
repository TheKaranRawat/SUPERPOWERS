include( "IconSupport" );
-------------------------------------------------
-- Diplomatic
-------------------------------------------------

local m_CurrentPanel = Controls.RelationsPanel;
local m_PopupInfo = nil;

-------------------------------------------------
-- OPEN/CLOSE ANIMATION (slide + fade)
-- UI-only: no game state, no network calls, no Game.Rand, so it cannot
-- desync multiplayer. The per-frame update is registered only while an
-- animation is running and is removed as soon as it finishes.
-------------------------------------------------
-- ====== CONFIGURATION ======
local ANIMATIONS_ENABLED = true;	-- false = instant open/close like the original
local SLIDE_DURATION     = 0.25;	-- seconds for the slide (0 = no slide)
local SLIDE_DISTANCE     = 40;		-- pixels travelled during the slide
local SLIDE_FROM         = "BOTTOM";	-- side it slides in from / out to: "BOTTOM", "TOP", "LEFT", "RIGHT"
local FADE_DURATION      = 0.20;	-- seconds for the fade (0 = no fade)
local DEBUG_INPUT        = false;	-- true = write every key/mouse message to Lua.log (to find button codes)
-- ===========================

local MAX_FRAME_DT = 0.1;	-- clamp so a hitch/lag spike never makes the screen jump
local g_AnimTotal  = math.max( SLIDE_DURATION, FADE_DURATION );
local g_AnimTime   = 0;		-- 0 = fully closed look, g_AnimTotal = fully open look
local g_AnimDir    = 0;		-- +1 opening, -1 closing, 0 idle
local g_bClosing   = false;	-- closing animation in progress (ignore repeat close requests)
local g_bAlphaOK   = true;	-- flips to false if the engine lacks SetAlpha on containers
local g_LastX, g_LastY, g_LastA = nil, nil, nil;

local g_SlideDX, g_SlideDY = 0, 0;
do
	local dir = string.upper( SLIDE_FROM or "BOTTOM" );
	if     dir == "LEFT"  then g_SlideDX, g_SlideDY = -1, 0;
	elseif dir == "RIGHT" then g_SlideDX, g_SlideDY = 1, 0;
	elseif dir == "TOP"   then g_SlideDX, g_SlideDY = 0, -1;
	else                       g_SlideDX, g_SlideDY = 0, 1; end
end

local function EaseOutCubic( x )
	local inv = 1 - x;
	return 1 - inv * inv * inv;
end

local function Progress( t, duration )
	if duration <= 0 then
		return ( t > 0 ) and 1 or 0;
	end
	local p = t / duration;
	if p < 0 then p = 0 elseif p > 1 then p = 1 end
	return p;
end

-- Applies the visual state for animation time t. Skips engine calls when nothing changed.
local function ApplyAnimState( t )
	local remaining = ( 1 - EaseOutCubic( Progress( t, SLIDE_DURATION ) ) ) * SLIDE_DISTANCE;
	local x = math.floor( remaining * g_SlideDX + 0.5 );
	local y = math.floor( remaining * g_SlideDY + 0.5 );
	local a = ( FADE_DURATION > 0 ) and Progress( t, FADE_DURATION ) or 1;

	if x ~= g_LastX or y ~= g_LastY then
		Controls.AnimHolder:SetOffsetVal( x, y );
		g_LastX, g_LastY = x, y;
	end
	if g_bAlphaOK and a ~= g_LastA then
		local setAlpha = Controls.AnimHolder.SetAlpha;
		if setAlpha == nil or not pcall( setAlpha, Controls.AnimHolder, a ) then
			g_bAlphaOK = false;	-- degrade gracefully to slide-only
		end
		g_LastA = a;
	end
end

local function StopAnimUpdate()
	g_AnimDir = 0;
	ContextPtr:ClearUpdate();
end

local function OnAnimUpdate( fDTime )
	if fDTime > MAX_FRAME_DT then fDTime = MAX_FRAME_DT; end
	g_AnimTime = g_AnimTime + g_AnimDir * fDTime;

	if g_AnimDir > 0 and g_AnimTime >= g_AnimTotal then
		g_AnimTime = g_AnimTotal;
		ApplyAnimState( g_AnimTime );
		StopAnimUpdate();
	elseif g_AnimDir < 0 and g_AnimTime <= 0 then
		g_AnimTime = 0;
		ApplyAnimState( g_AnimTime );
		StopAnimUpdate();
		g_bClosing = false;
		UIManager:DequeuePopup( ContextPtr );	-- closing animation done: really close now
	else
		ApplyAnimState( g_AnimTime );
	end
end

local function StartOpenAnimation()
	g_bClosing = false;
	Controls.AnimHolder:SetSizeVal( UIManager:GetScreenSizeVal() );	-- cover the screen (handles resolution changes)
	if ANIMATIONS_ENABLED and g_AnimTotal > 0 then
		g_AnimTime = 0;
		ApplyAnimState( g_AnimTime );
		g_AnimDir = 1;
		ContextPtr:SetUpdate( OnAnimUpdate );
	else
		StopAnimUpdate();
		g_AnimTime = g_AnimTotal;
		ApplyAnimState( g_AnimTime );
	end
end

-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_DIPLOMATIC_OVERVIEW ) then
		m_PopupInfo = popupInfo;
		if( m_PopupInfo.Data1 == 1 ) then
        	if( ContextPtr:IsHidden() == false ) then
        	    OnClose();
            else
            	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
        	end
    	else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.DiploOverview );
    	end
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnDeals()
	-- Set Tabs
	Controls.DealsSelectHighlight:SetHide(false);
	Controls.RelationsSelectHighlight:SetHide(true);
	Controls.GlobalSelectHighlight:SetHide(true);
	
	-- Set Panels
    Controls.RelationsPanel:SetHide( true );
    Controls.DealsPanel:SetHide( false );
    Controls.GlobalPanel:SetHide( true );
    m_CurrentPanel = Controls.DealsPanel;
end
Controls.DealsButton:RegisterCallback( Mouse.eLClick, OnDeals );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnRelations()
	-- Set Tabs
	Controls.DealsSelectHighlight:SetHide(true);
	Controls.RelationsSelectHighlight:SetHide(false);
	Controls.GlobalSelectHighlight:SetHide(true);
	
	-- Set Panels
    Controls.RelationsPanel:SetHide( false );
    Controls.DealsPanel:SetHide( true );
    Controls.GlobalPanel:SetHide( true );
    m_CurrentPanel = Controls.RelationsPanel;
end
Controls.RelationsButton:RegisterCallback( Mouse.eLClick, OnRelations );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnGlobal()
	-- Set Tabs
	Controls.DealsSelectHighlight:SetHide(true);
	Controls.RelationsSelectHighlight:SetHide(true);
	Controls.GlobalSelectHighlight:SetHide(false);
	
	-- Set Panels
    Controls.RelationsPanel:SetHide( true );
    Controls.DealsPanel:SetHide( true );
    Controls.GlobalPanel:SetHide( false );
    m_CurrentPanel = Controls.GlobalPanel;
end
Controls.GlobalPoliticsButton:RegisterCallback( Mouse.eLClick, OnGlobal );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnClose()
    if( g_bClosing ) then return; end	-- already animating out

    if( not ANIMATIONS_ENABLED or g_AnimTotal <= 0 or ContextPtr:IsHidden() ) then
        StopAnimUpdate();
        UIManager:DequeuePopup( ContextPtr );
        return;
    end

    g_bClosing = true;
    g_AnimDir = -1;	-- if still opening, this simply reverses from the current position
    ContextPtr:SetUpdate( OnAnimUpdate );
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose);

-- Closes immediately with no animation (used when the active player changes).
function OnCloseInstant()
    g_bClosing = false;
    StopAnimUpdate();
    UIManager:DequeuePopup( ContextPtr );
end

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(OnCloseInstant);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- True for right click and the extra mouse buttons. Every name is nil-checked,
-- so a name this game version doesn't have is simply never matched.
function IsCloseMouseMessage( uiMsg, wParam )
    local m = MouseEvents;
    if m ~= nil then
        if uiMsg == m.RButtonDown or uiMsg == m.RButtonUp
        or uiMsg == m.XButtonDown or uiMsg == m.XButtonUp then
            return true;
        end
    end
    -- Some setups deliver the side buttons as key messages.
    if uiMsg == KeyEvents.KeyDown or uiMsg == KeyEvents.KeyUp then
        if wParam ~= nil and ( wParam == Keys.VK_XBUTTON1 or wParam == Keys.VK_XBUTTON2 or wParam == Keys.VK_BROWSER_BACK ) then
            return true;
        end
    end
    return false;
end

-- Also register right click directly on the controls, in case the input handler never sees the message.
local function OnRightClickControl()
    OnClose();
end
if Controls.MainGrid ~= nil then pcall( Controls.MainGrid.RegisterCallback, Controls.MainGrid, Mouse.eRClick, OnRightClickControl ); end
if Controls.BGBlock  ~= nil then pcall( Controls.BGBlock.RegisterCallback,  Controls.BGBlock,  Mouse.eRClick, OnRightClickControl ); end

if DEBUG_INPUT then
    pcall( function() for k, v in pairs( MouseEvents ) do print( "MouseEvents." .. tostring( k ) .. " = " .. tostring( v ) ); end end );
end

function InputHandler( uiMsg, wParam, lParam )
    if DEBUG_INPUT and uiMsg ~= MouseEvents.MouseMove then
        print( "DiploOverview input: uiMsg=" .. tostring( uiMsg ) .. " wParam=" .. tostring( wParam ) .. " lParam=" .. tostring( lParam ) );
    end

    -- Right click / mouse side buttons close the screen (with the closing animation).
    if IsCloseMouseMessage( uiMsg, wParam ) then
        OnClose();	-- ignored if already closing
        return true;	-- swallow the matching "up" message too, so it doesn't reach the map
    end

    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose();
            return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
	-- Set player icon at top of screen
	CivIconHookup( Game.GetActivePlayer(), 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	-- trigger the show/hide handler to update state
        	m_CurrentPanel:SetHide( false );
        	StartOpenAnimation();
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
        	-- Fully hidden: make sure no animation state or update callback is left behind.
        	g_bClosing = false;
        	g_AnimTime = 0;
        	StopAnimUpdate();
        	UI.decTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_DIPLOMATIC_OVERVIEW, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

OnRelations();