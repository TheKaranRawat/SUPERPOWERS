-------------------------------------------------
-- Notification Log Popup
-- Adds: fade + slide open/close animation (configurable),
--       right-click / mouse side-button (back) to close.
-------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local ANIMATION_ENABLED = true;   -- false = original instant open/close
local SLIDE_DURATION    = 0.25;   -- seconds for the slide (0 = no slide)
local SLIDE_DISTANCE    = 60;     -- pixels travelled during the slide (0 = no slide)
local SLIDE_FROM        = "BOTTOM"; -- "BOTTOM", "TOP", "LEFT" or "RIGHT": side the panel slides in from / out to
local FADE_DURATION     = 0.20;   -- seconds for the fade (0 = no fade)

local CLOSE_ON_RIGHT_CLICK = true;
local CLOSE_ON_MOUSE_BACK  = true;

-- Set true to write every unhandled input message to the Lua log.
-- Use it once to find out what your mouse side button sends, then turn it off.
local DEBUG_INPUT = false;

-- Notifications whose displayed text contains any of these are hidden from the log.
-- Lowercase, plain-text fragments (no patterns). Matching is case-insensitive.
local HIDDEN_NOTIFICATION_TEXT = {
	"over resource",   -- replace with a distinctive phrase from the real notification text
};

local function IsHiddenNotification( str )
	if str == nil then return false; end
	local lower = string.lower( str );
	for _, fragment in ipairs( HIDDEN_NOTIFICATION_TEXT ) do
		if string.find( lower, fragment, 1, true ) then
			return true;
		end
	end
	return false;
end

-------------------------------------------------
-- Internal constants / state
-------------------------------------------------
local BASE_X = 0;     -- must match the Offset of the main Grid in the XML
local BASE_Y = 36;
local MAX_FRAME_DT = 0.1;   -- clamp frame hitches so the animation never "jumps"

local STATE_IDLE    = 0;
local STATE_OPENING = 1;
local STATE_OPEN    = 2;
local STATE_CLOSING = 3;

local g_State        = STATE_IDLE;
local g_SlideProg    = 1;   -- 0 = fully off-screen, 1 = in place
local g_FadeProg     = 1;   -- 0 = transparent,      1 = opaque
local g_LastAlpha    = nil;
local g_LastX        = nil;
local g_LastY        = nil;

local g_NotificationInstanceManager = InstanceManager:new( "NotificationButton", "Button", Controls.NotificationButtonStack );
local m_PopupInfo = nil;

-- Slide direction vector (which way the panel starts offset from its resting place)
local g_SlideDirX, g_SlideDirY = 0, 1;
do
	local dir = string.upper( tostring( SLIDE_FROM ) );
	if     dir == "TOP"   then g_SlideDirX, g_SlideDirY =  0, -1;
	elseif dir == "LEFT"  then g_SlideDirX, g_SlideDirY = -1,  0;
	elseif dir == "RIGHT" then g_SlideDirX, g_SlideDirY =  1,  0;
	end
end

-------------------------------------------------
-- Animation helpers (purely local / cosmetic - never touches game state)
-------------------------------------------------
local function Smooth( p )
	return p * p * (3 - 2 * p);   -- smoothstep ease in/out
end

local function ApplyAnimation()
	local alpha = 1;
	local x, y  = BASE_X, BASE_Y;

	if ANIMATION_ENABLED then
		alpha = Smooth( g_FadeProg );
		local remaining = (1 - Smooth( g_SlideProg )) * SLIDE_DISTANCE;
		x = BASE_X + g_SlideDirX * remaining;
		y = BASE_Y + g_SlideDirY * remaining;
	end

	-- Only touch controls when a value actually changed
	if alpha ~= g_LastAlpha then
		g_LastAlpha = alpha;
		Controls.MainPanel:SetAlpha( alpha );
		Controls.BGBlock:SetAlpha( alpha );
	end
	if x ~= g_LastX or y ~= g_LastY then
		g_LastX, g_LastY = x, y;
		Controls.MainPanel:SetOffsetVal( x, y );
	end
end

local function ResetVisualState()
	g_LastAlpha, g_LastX, g_LastY = nil, nil, nil;
	g_SlideProg = 1;
	g_FadeProg  = 1;
	ApplyAnimation();
end

local function StartOpening()
	if not ANIMATION_ENABLED then
		g_State = STATE_OPEN;
		ResetVisualState();
		return;
	end
	g_State     = STATE_OPENING;
	g_SlideProg = ( SLIDE_DURATION > 0 and SLIDE_DISTANCE ~= 0 ) and 0 or 1;
	g_FadeProg  = ( FADE_DURATION  > 0 ) and 0 or 1;
	g_LastAlpha, g_LastX, g_LastY = nil, nil, nil;
	ApplyAnimation();   -- apply start frame before the first render (no flash)
end

-- Step one progress value toward its target; durations <= 0 jump immediately
local function Step( prog, dt, duration, target )
	if duration <= 0 then
		return target;
	end
	local delta = dt / duration;
	if target > prog then
		prog = prog + delta;
		if prog > target then prog = target; end
	else
		prog = prog - delta;
		if prog < target then prog = target; end
	end
	return prog;
end

-- Runs every frame while the popup is visible; returns immediately when idle/open
function OnUpdate( fDTime )
	if g_State ~= STATE_OPENING and g_State ~= STATE_CLOSING then
		return;
	end

	local dt = fDTime or 0;
	if dt > MAX_FRAME_DT then dt = MAX_FRAME_DT; end
	if dt < 0 then dt = 0; end

	local target = ( g_State == STATE_OPENING ) and 1 or 0;
	g_SlideProg = Step( g_SlideProg, dt, SLIDE_DURATION, target );
	g_FadeProg  = Step( g_FadeProg,  dt, FADE_DURATION,  target );
	ApplyAnimation();

	if g_SlideProg == target and g_FadeProg == target then
		if g_State == STATE_OPENING then
			g_State = STATE_OPEN;
		else
			g_State = STATE_IDLE;
			UIManager:DequeuePopup( ContextPtr );   -- ShowHideHandler restores visuals
		end
	end
end
ContextPtr:SetUpdate( OnUpdate );

-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_NOTIFICATION_LOG ) then
		return;
	end

	local playerID = Game.GetActivePlayer();
	local player = Players[playerID];
	if player == nil then
		return;
	end

	-- Set Civ Icon
	CivIconHookup( playerID, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

	m_PopupInfo = popupInfo;

	g_NotificationInstanceManager:ResetInstances();

	local numNotifications = player:GetNumNotifications();
	for i = numNotifications - 1, 0, -1
	do
		local str = player:GetNotificationStr( i );
		if not IsHiddenNotification( str ) then
			local index = player:GetNotificationIndex( i );
			local turn = player:GetNotificationTurn( i );
			local dismissed = player:GetNotificationDismissed( i );
			AddNotificationButton(index, str, turn, dismissed);
		end
	end

	Controls.NotificationButtonStack:CalculateSize();
	Controls.NotificationButtonStack:ReprocessAnchoring();
	Controls.NotificationScrollPanel:CalculateInternalSize();

	if( m_PopupInfo.Data1 == 1 ) then
    	if( ContextPtr:IsHidden() == false ) then
    	    OnClose();
        else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
    	end
	else
		if( ContextPtr:IsHidden() == false and g_State == STATE_CLOSING ) then
			-- Re-requested while fading out: just fade back in from where we are
			g_State = STATE_OPENING;
		else
    		UIManager:QueuePopup( ContextPtr, PopupPriority.NotificationLog );
		end
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AddNotificationButton( id, description, turn, dismissed )

	local controlTable = g_NotificationInstanceManager:GetInstance();
	controlTable.NotificationText:SetText(description);
	controlTable.NotificationTurnText:SetText(Locale.ConvertTextKey("TXT_KEY_TP_TURN_COUNTER", turn));
    controlTable.Button:SetVoid1( id ); -- indicates type
    controlTable.Button:SetVoid2( 0 );
    controlTable.Button:SetDisabled( dismissed );

    controlTable.TextStack:CalculateSize();
    controlTable.TextStack:ReprocessAnchoring();

    local sizeY = controlTable.TextStack:GetSizeY()
    controlTable.Button:SetSizeY(sizeY);
    controlTable.TextAnim:SetSizeY(sizeY);
    controlTable.TextHL:SetSizeY(sizeY);

    controlTable.Button:RegisterCallback( Mouse.eLClick, NotificationSelected );
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function NotificationSelected (id)
    CloseImmediate();      -- no fade here: ActivateNotification may open another screen
	UI.ActivateNotification(id);
end

-------------------------------------------------------------------------------
-- Animated close (falls back to instant when animation is disabled)
-------------------------------------------------------------------------------
function OnClose ()
	if ContextPtr:IsHidden() then
		return;
	end
	if g_State == STATE_CLOSING then
		return;   -- already on its way out
	end
	if not ANIMATION_ENABLED then
		UIManager:DequeuePopup( ContextPtr );
		return;
	end
	g_State = STATE_CLOSING;
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

-------------------------------------------------------------------------------
-- Instant close (selection, active-player change)
-------------------------------------------------------------------------------
function CloseImmediate ()
	g_State = STATE_IDLE;
	UIManager:DequeuePopup( ContextPtr );
end


-------------------------------------------------------------------------------
-- Input
-------------------------------------------------------------------------------
-- Build message sets once. Looked up by name so a missing enum entry in this
-- build of the game is simply ignored instead of raising an error.
local function CollectMouseMsgs( names )
	local set = {};
	for _, name in ipairs( names ) do
		local v = MouseEvents[name];
		if v ~= nil then set[v] = true; end
	end
	return set;
end

local RIGHT_CLICK_CLOSE   = CollectMouseMsgs{ "RButtonUp" };
local RIGHT_CLICK_SWALLOW = CollectMouseMsgs{ "RButtonDown", "RButtonDblClick" };
local SIDE_BUTTON_CLOSE   = CollectMouseMsgs{ "XButton1Down", "XButtonDown" };
local SIDE_BUTTON_SWALLOW = CollectMouseMsgs{ "XButton1Up", "XButtonUp", "XButton2Down", "XButton2Up" };

local BACK_KEYS = {};
for _, name in ipairs{ "VK_BROWSER_BACK", "VK_XBUTTON1" } do
	local v = Keys[name];
	if v ~= nil then BACK_KEYS[v] = true; end
end

function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyDown then
		if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN or ( CLOSE_ON_MOUSE_BACK and BACK_KEYS[wParam] ) then
			OnClose();
			return true;
		end
		return false;
	end

	if CLOSE_ON_RIGHT_CLICK then
		if RIGHT_CLICK_CLOSE[uiMsg] then
			OnClose();
			return true;
		elseif RIGHT_CLICK_SWALLOW[uiMsg] then
			return true;   -- keep the right-click from reaching the game underneath
		end
	end

	if CLOSE_ON_MOUSE_BACK then
		if SIDE_BUTTON_CLOSE[uiMsg] then
			OnClose();
			return true;
		elseif SIDE_BUTTON_SWALLOW[uiMsg] then
			return true;
		end
	end

	if DEBUG_INPUT and uiMsg ~= MouseEvents.MouseMove then
		print( "NotificationLogPopup input: uiMsg=" .. tostring(uiMsg) .. " wParam=" .. tostring(wParam) .. " lParam=" .. tostring(lParam) );
	end

	return false;
end
ContextPtr:SetInputHandler( InputHandler );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	StartOpening();
        	if m_PopupInfo ~= nil then
        		Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        	end
        else
            g_State = STATE_IDLE;
            ResetVisualState();   -- leave the panel fully visible/in place for next time
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_NOTIFICATION_LOG, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnActivePlayerChanged()
	CloseImmediate();
end
Events.GameplaySetActivePlayer.Add( OnActivePlayerChanged );