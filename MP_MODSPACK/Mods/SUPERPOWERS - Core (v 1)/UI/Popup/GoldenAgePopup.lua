-------------------------------------------------
-- Golden Age Popup
-- Compact toast: fades + slides in from the top, holds, then slides out.
-- UI-only: touches no gameplay state, so it cannot cause multiplayer desyncs.
-------------------------------------------------

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local POPUP_HEIGHT     = 160;  -- Height of the popup in pixels (configurable)
local POPUP_WIDTH      = 460;  -- Width of the popup in pixels
local POPUP_TOP_MARGIN = 160;   -- Gap between the top of the screen and the popup (clears the top bar)
local HOLD_TIME        = 4.0;  -- Seconds the popup stays fully visible before sliding out

-------------------------------------------------
-- STATE
-------------------------------------------------
local STATE_NONE = 0;
local STATE_IN   = 1;  -- sliding / fading in
local STATE_HOLD = 2;  -- fully visible, counting down
local STATE_OUT  = 3;  -- sliding / fading out

local ANIM_START_GUARD = 0.1;  -- seconds to wait before trusting IsStopped()
local MAX_FRAME_DELTA  = 0.1;  -- clamp frame time so a lag spike can't skip the hold

local m_PopupInfo = nil;
local m_State     = STATE_NONE;
local m_Timer     = 0;

-- Cache control references (avoids a Controls table lookup every frame)
local g_SlideAnim = Controls.SlideAnim;
local g_FadeAnim  = Controls.FadeAnim;

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function IsAnimDone()
	return g_SlideAnim:IsStopped() and g_FadeAnim:IsStopped();
end

local function ClosePopup()
	if m_State == STATE_NONE then
		return;  -- already closed/hidden, nothing to do
	end
	m_State = STATE_NONE;
	ContextPtr:ClearUpdate();
	UIManager:DequeuePopup( ContextPtr );
end

local function BeginSlideOut()
	if m_State == STATE_OUT or m_State == STATE_NONE then
		return;
	end
	m_State = STATE_OUT;
	m_Timer = 0;
	g_SlideAnim:Reverse();
	g_FadeAnim:Reverse();
end

local function StartSlideIn()
	m_State = STATE_IN;
	m_Timer = 0;
	g_SlideAnim:SetToBeginning();
	g_FadeAnim:SetToBeginning();
	g_SlideAnim:Play();
	g_FadeAnim:Play();
	ContextPtr:SetUpdate( OnUpdate );  -- per-frame callback only runs while visible
end

-------------------------------------------------
-- Per-frame update: drives the in -> hold -> out sequence
-- (only registered while the popup is on screen)
-------------------------------------------------
function OnUpdate( fDTime )

	if m_State == STATE_NONE then
		ContextPtr:ClearUpdate();
		return;
	end

	if fDTime > MAX_FRAME_DELTA then
		fDTime = MAX_FRAME_DELTA;
	end
	m_Timer = m_Timer + fDTime;

	if m_State == STATE_IN then
		if m_Timer > ANIM_START_GUARD and IsAnimDone() then
			m_State = STATE_HOLD;
			m_Timer = 0;
		end

	elseif m_State == STATE_HOLD then
		if m_Timer >= HOLD_TIME then
			BeginSlideOut();
		end

	elseif m_State == STATE_OUT then
		if m_Timer > ANIM_START_GUARD and IsAnimDone() then
			ClosePopup();
		end
	end
end

-------------------------------------------------
-- On Display
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_GOLDEN_AGE_REWARD ) then
		return;
	end
	
	m_PopupInfo = popupInfo;
	Controls.DescriptionLabel:SetText( Locale.ConvertTextKey( "TXT_KEY_GOLDEN_AGE_FLAVOR" ) );

	-- Apply configurable layout
	Controls.MainGrid:SetSizeVal( POPUP_WIDTH, POPUP_HEIGHT );
	Controls.MainGrid:SetOffsetVal( 0, POPUP_TOP_MARGIN );

	if m_State ~= STATE_NONE then
		-- Already on screen (e.g. a second golden age message arrived): restart the
		-- animation instead of queuing again, so ShowHideHandler stays balanced.
		StartSlideIn();
		return;
	end

	-- ShowHideHandler starts the animation once the popup is actually shown
	UIManager:QueuePopup( ContextPtr, PopupPriority.GoldenAge );
end
Events.SerialEventGameMessagePopup.Add( OnPopup );

----------------------------------------------------------------        
-- Input processing
----------------------------------------------------------------        

-------------------------------------------------------------------------------
-- Close button / Escape / Enter slide the popup out early
-------------------------------------------------------------------------------
function OnCloseButtonClicked ()
	BeginSlideOut();
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButtonClicked );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose();
            return true;
        end

    -- right click closes the screen
    elseif uiMsg == MouseEvents.RButtonUp then
        OnClose();
        return true;

    -- mouse side button closes the screen
    elseif uiMsg == 523 then   -- WM_XBUTTONDOWN
        local xButton = math.floor( wParam / 65536 ) % 256   -- high word
        if xButton == 0 then xButton = wParam end            -- fallback if already unpacked
        if xButton == 1 then   -- same button as the other screens; use 1 for the other one
            OnClose();
            return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );


-------------------------------------------------------------------------------
-- Note: the turn timer semaphore is intentionally NOT held. This popup needs no
-- input, so pausing the multiplayer turn timer for it would only penalize other
-- players' pacing (and a stuck popup could freeze the timer).
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

    if( not bInitState ) then
        if( not bIsHide ) then
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        	StartSlideIn();
        else
        	m_State = STATE_NONE;
        	ContextPtr:ClearUpdate();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_GOLDEN_AGE_REWARD, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed (hotseat): close immediately
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(ClosePopup);