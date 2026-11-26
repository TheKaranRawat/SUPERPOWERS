-------------------------------------------------
-- Wonder popup
-------------------------------------------------

include( "IconSupport" );
include( "InfoTooltipInclude" );

-- Timing (seconds)
local m_fFadeInSeconds  = 0.7;   -- fade + slide in
local m_fHoldSeconds    = 15;     -- how long it stays fully visible
local m_fFadeOutSeconds = 0.7;   -- fade + slide out
local m_fSlideDistance  = 80;    -- pixels the popup slides (in from below, out downward)

local m_fAnimSeconds = m_fFadeInSeconds + m_fHoldSeconds + m_fFadeOutSeconds; -- total lifetime
local m_fScaleFactor = 0.5;
local m_fPct = 0;
local m_fTime = 0;
local m_bHasSplash = false;
local m_fOriginalSizeX = 0;
local m_fOriginalSizeY = 0;
local m_strAudioFile = "";
local m_PopupInfo = nil;

local lastBackgroundImage = "WonderConceptStonehedge.dds"

-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_WONDER_COMPLETED_ACTIVE_PLAYER ) then
		return;
	end
	
	if(Game == nil or Game.GetGameTurn() <= Game.GetStartTurn()) then
		return;
	end
	
	local iBuildingID = popupInfo.Data1;
	local thisBuilding = GameInfo.Buildings[ iBuildingID ];
	if( thisBuilding == nil ) then
    	return;
	end

	m_PopupInfo = popupInfo;

    m_bHasSplash = false;
    if( thisBuilding.WonderSplashImage ~= nil ) then
        m_bHasSplash = true;
    
        if( thisBuilding.WonderSplashAnchor ~= nil ) then
            Controls.WonderSplash:SetAnchor( thisBuilding.WonderSplashAnchor );
        else
            Controls.WonderSplash:SetAnchor( "T,R" );
        end
        Controls.WonderSplash:ReprocessAnchoring();
        lastBackgroundImage = thisBuilding.WonderSplashImage;
        Controls.WonderSplash:SetTextureAndResize( thisBuilding.WonderSplashImage );
    	
    	m_fOriginalSizeX, m_fOriginalSizeY = Controls.WonderSplash:GetSizeVal();
    	Controls.WonderSplash:SetSizeVal( m_fOriginalSizeX * (1 + m_fScaleFactor), m_fOriginalSizeY * (1 + m_fScaleFactor) );
    end

	IconHookup( thisBuilding.PortraitIndex, 128, thisBuilding.IconAtlas, Controls.WonderIcon)

    if( thisBuilding.Description ~= nil ) then
    	Controls.Title:SetText( Locale.ConvertTextKey( thisBuilding.Description ) );
    	Controls.LowerTitle:SetText( Locale.ConvertTextKey( thisBuilding.Description ) );
    	Controls.Title:SetHide( false );
    	Controls.LowerTitle:SetHide( false );
    else
    	Controls.Title:SetHide( true );
    	Controls.LowerTitle:SetHide( true );
	end
    if( thisBuilding.Quote ~= nil ) then
        Controls.Quote:SetText( Locale.ConvertTextKey( thisBuilding.Quote ) );
    	Controls.Quote:SetHide( false );
    else
    	Controls.Quote:SetHide( true );
    end

	-- Game Info
	local strGameInfo = thisBuilding.Help;

	if (strGameInfo == nil) then
		local bExcludeName = true;
		local bExcludeHeader = true;
		strGameInfo = GetHelpTextForBuilding(iBuildingID, bExcludeName, bExcludeHeader, false);
	end
    
    if( strGameInfo ~= nil ) then
        Controls.Stats:SetText( Locale.ConvertTextKey( strGameInfo ) );
    	Controls.Stats:SetHide( false );
    else
    	Controls.Stats:SetHide( true );
    end
    
	-- The animation timer starts in ShowHideHandler, once the popup is actually visible
	-- (it may sit in the popup queue behind other popups first).
	UIManager:QueuePopup( ContextPtr, PopupPriority.WonderPopup );
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


----------------------------------------------------------------
-- Animation (UI-only: never touches gameplay state, so it is safe in multiplayer)
----------------------------------------------------------------
local m_fFadeOutStart = m_fFadeInSeconds + m_fHoldSeconds;
local m_bHoldApplied = false;   -- true once the fully-visible state has been applied
local m_bZoomDone = false;      -- true once the splash is back at its original size
local MAX_FRAME_DT = 0.1;       -- ignore lag spikes so the animation never "jumps"

local function ApplyPopupState( fAlpha, fOffsetY )
    local container = Controls.PopupContainer;
    container:SetAlpha( fAlpha );
    container:SetOffsetVal( 0, fOffsetY );
end

local function UpdateSplashZoom()
    if( not m_bHasSplash or m_bZoomDone ) then
        return;
    end
    local fZoomPct = m_fTime / m_fAnimSeconds;
    if( fZoomPct >= 1 ) then
        m_bZoomDone = true;
        Controls.WonderSplash:SetSizeVal( m_fOriginalSizeX, m_fOriginalSizeY );
    else
        local fInv = 1 - fZoomPct;
        local fScale = 1 + (fInv * fInv * m_fScaleFactor);
        Controls.WonderSplash:SetSizeVal( m_fOriginalSizeX * fScale, m_fOriginalSizeY * fScale );
    end
end

local function ResetAnimation()
    m_fTime = 0;
    m_fPct = 0;
    m_bHoldApplied = false;
    m_bZoomDone = false;
    ApplyPopupState( 0, m_fSlideDistance );
    UpdateSplashZoom();
    ContextPtr:SetUpdate( OnUpdate );
end

----------------------------------------------------------------
----------------------------------------------------------------
function OnUpdate( fDTime )
    if( fDTime > MAX_FRAME_DT ) then
        fDTime = MAX_FRAME_DT;
    end
    m_fTime = m_fTime + fDTime;
    m_fPct = m_fTime / m_fAnimSeconds;

    if( m_fTime < m_fFadeInSeconds ) then
        -- Fade / slide in (ease-out)
        local p = m_fTime / m_fFadeInSeconds;
        local inv = 1 - p;
        local e = 1 - inv * inv * inv;
        ApplyPopupState( e, m_fSlideDistance * (1 - e) );
    elseif( m_fTime < m_fFadeOutStart ) then
        -- Hold: set the final state once, then do nothing but the splash zoom
        if( not m_bHoldApplied ) then
            m_bHoldApplied = true;
            ApplyPopupState( 1, 0 );
        end
    elseif( m_fTime < m_fAnimSeconds ) then
        -- Fade / slide out (ease-in)
        local p = (m_fTime - m_fFadeOutStart) / m_fFadeOutSeconds;
        local e = p * p;
        ApplyPopupState( 1 - e, m_fSlideDistance * e );
    else
        -- Finished: stop updating and close automatically
        ContextPtr:ClearUpdate();
        OnClose();
        return;
    end

    UpdateSplashZoom();
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnClose()
    ContextPtr:ClearUpdate();
    if( not ContextPtr:IsHidden() ) then
        UIManager:DequeuePopup( ContextPtr );
    end
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Windows message ids for the mouse side buttons (WM_XBUTTONDOWN / WM_XBUTTONUP)
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
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
    if( not bInitState ) then
        Controls.WonderSplash:UnloadTexture();
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	if( m_PopupInfo ~= nil ) then
        		Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        	end
			Controls.WonderSplash:SetTextureAndResize( lastBackgroundImage );
			if( m_bHasSplash ) then
				m_fOriginalSizeX, m_fOriginalSizeY = Controls.WonderSplash:GetSizeVal();
				Controls.WonderSplash:SetSizeVal( m_fOriginalSizeX * (1 + m_fScaleFactor), m_fOriginalSizeY * (1 + m_fScaleFactor) );
			end
			ResetAnimation();
        else
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_WONDER_COMPLETED_ACTIVE_PLAYER, 0);
            ContextPtr:ClearUpdate();
            ApplyPopupState( 0, m_fSlideDistance );  -- no flash of the old popup next time
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(OnClose);