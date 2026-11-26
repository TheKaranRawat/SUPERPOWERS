-------------------------------------------------
-- Technology Award Popup
-------------------------------------------------
include( "InstanceManager" );
include( "TechButtonInclude" );

local maxSmallButtons = 5;

-------------------------------------------------
-- Animation settings (seconds / pixels)
-- Set a duration to 0 to disable that animation.
-------------------------------------------------
local ANIM_IN_DURATION  = 0.40;   -- fade + slide in time
local ANIM_OUT_DURATION = 0.40;   -- fade + slide out time
local kSlideInDist      = 270;    -- pixels the popup travels while sliding in
local kSlideOutDist     = 270;    -- pixels the popup travels while sliding out
local kSlideDirX        = 0;      -- slide direction the popup comes from / leaves to:
local kSlideDirY        = 1;      --   (1,0) = right, (-1,0) = left, (0,1) = below, (0,-1) = above
local ANIM_FADE         = true;   -- fade alpha along with the slide

-- list any localized strings that we are going to need a bunch

-- I'll need these before I'm done
-- KWG: Not all these are used.  Are they referenced in the includes?
local playerID = Game.GetActivePlayer();	
local player = Players[playerID];
local civType = GameInfo.Civilizations[player:GetCivilizationType()].Type;
local activeTeamID = Game.GetActiveTeam();
local activeTeam = Teams[activeTeamID];

local storedPopupInfo = {};

GatherInfoAboutUniqueStuff( civType );

local m_PopupInfo = nil;

-------------------------------------------------------------------------------
-- Animation state
-------------------------------------------------------------------------------
local baseX, baseY = Controls.OuterGrid:GetOffsetVal();  -- resting position
local animProgress = 1;     -- 0 = hidden, 1 = fully shown
local animDir      = 0;     -- 1 = opening, -1 = closing, 0 = idle
local isClosing    = false;
local animDist     = kSlideInDist;  -- slide distance of the animation currently playing

local function ApplyAnim( p )
	local e = p * p * (3 - 2 * p);  -- smoothstep easing
	if ANIM_FADE then
		Controls.OuterGrid:SetAlpha( e );
	else
		Controls.OuterGrid:SetAlpha( 1 );
	end
	local d = animDist * (1 - e);
	Controls.OuterGrid:SetOffsetVal( baseX + kSlideDirX * d, baseY + kSlideDirY * d );
end

-- Actually removes the popup (no animation)
local function FinishClose()
	isClosing = false;
	animDir = 0;
	ContextPtr:ClearUpdate();
	UIManager:DequeuePopup( ContextPtr );
end

local function OnAnimUpdate( fDTime )
	if animDir == 0 then
		return;
	end

	local duration = ANIM_IN_DURATION;
	if animDir < 0 then
		duration = ANIM_OUT_DURATION;
	end

	if duration <= 0 then
		animProgress = (animDir > 0) and 1 or 0;
	else
		animProgress = animProgress + animDir * fDTime / duration;
	end

	if animDir > 0 and animProgress >= 1 then
		animProgress = 1;
		animDir = 0;
		ApplyAnim( animProgress );
		ContextPtr:ClearUpdate();
	elseif animDir < 0 and animProgress <= 0 then
		animProgress = 0;
		ApplyAnim( animProgress );
		FinishClose();
	else
		ApplyAnim( animProgress );
	end
end

local function StartOpenAnim()
	isClosing = false;
	animDist = kSlideInDist;
	if ANIM_IN_DURATION <= 0 then
		animProgress = 1;
		animDir = 0;
		ApplyAnim( 1 );
		ContextPtr:ClearUpdate();
	else
		animProgress = 0;
		animDir = 1;
		ApplyAnim( 0 );  -- start hidden so there is no one-frame flash
		ContextPtr:SetUpdate( OnAnimUpdate );
	end
end

local function StartCloseAnim()
	if isClosing then
		return;
	end
	isClosing = true;
	if ANIM_OUT_DURATION <= 0 then
		FinishClose();
	else
		-- If closed mid slide-in, keep the popup where it is on screen: find the
		-- progress value on the slide-out path that gives the same offset.
		if animDir > 0 and animProgress < 1 and kSlideOutDist > 0 then
			local e = animProgress * animProgress * (3 - 2 * animProgress);
			local d = animDist * (1 - e);
			local newE = 1 - math.min( d / kSlideOutDist, 1 );
			animProgress = 0.5 - math.sin( math.asin( 1 - 2 * newE ) / 3 );  -- inverse smoothstep
		end
		animDist = kSlideOutDist;
		animDir = -1;
		ContextPtr:SetUpdate( OnAnimUpdate );
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnPopup( popupInfo )

	if popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_TECH_AWARD then
		return;
	end
	
	if popupInfo.Data3 == -1 then
		return;
	end

	m_PopupInfo = popupInfo;

	local pTechInfo = GameInfo.Technologies[popupInfo.Data3];
	if pTechInfo == nil then
		return;
	end

	storedPopupInfo = popupInfo;

  	RefreshDisplay( pTechInfo );
  	
	UIManager:QueuePopup( ContextPtr, PopupPriority.TechAward );
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function RefreshDisplay( pTechInfo )
	if pTechInfo then
	
		local playerID = Game.GetActivePlayer();	
		local player = Players[playerID];
		
		-- Tech Name
		Controls.TechName:SetText( Locale.ConvertTextKey( pTechInfo.Description ) );
		
		-- Tech Quote
		Controls.TechQuote:SetText( Locale.ConvertTextKey( pTechInfo.Quote ) );
		
		-- if we have one, update the tech picture
		if IconHookup( pTechInfo.PortraitIndex, 256, pTechInfo.IconAtlas, Controls.TechIcon ) then
			Controls.TechIcon:SetHide( false );
		else
			Controls.TechIcon:SetHide( true );
		end
		
		-- Update the little icons
		techPediaSearchStrings = {};
		AddSmallButtonsToTechButton( Controls, pTechInfo, maxSmallButtons, 64 );
		Controls.BonusStack:CalculateSize();
		Controls.BonusStack:ReprocessAnchoring();
		-- if the code ever supports first place awards add a handler here
		
		-- Tech Info
		Controls.TechHelp:SetText( Locale.ConvertTextKey( pTechInfo.Help ) );
		
		Controls.OuterGrid:DoAutoSize();
	end	
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnContinueButtonClicked ()
	--Events.SerialEventGameMessagePopup( 
	--{
		--Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH; 
		--Data1 = storedPopupInfo.Data1; 
		--Data2 = storedPopupInfo.Data2; 
		--Data3 = storedPopupInfo.Data3; 
	--} );
	
	OnClose();
end
Controls.ContinueButton:RegisterCallback( Mouse.eLClick, OnContinueButtonClicked );

-------------------------------------------------------------------------------
-- Animated close (slides/fades out, then dequeues)
-------------------------------------------------------------------------------
function OnClose()
    StartCloseAnim();
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );


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
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        	StartOpenAnim();
        else
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_TECH_AWARD, 0);

            -- reset everything so the next show starts clean
            ContextPtr:ClearUpdate();
            animDir = 0;
            isClosing = false;
            animProgress = 1;
            ApplyAnim( 1 );
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnTechAwardActivePlayerChanged( iActivePlayer, iPrevActivePlayer )
	playerID = Game.GetActivePlayer();	
	player = Players[playerID];
	civType = GameInfo.Civilizations[player:GetCivilizationType()].Type;
	activeTeamID = Game.GetActiveTeam();
	activeTeam = Teams[activeTeamID];
	
	GatherInfoAboutUniqueStuff( civType );
	
	-- Make sure its closed so the next player doesn't see the previous players popup.
	-- Skip the animation here so it's gone instantly.
	FinishClose();
end

Events.GameplaySetActivePlayer.Add(OnTechAwardActivePlayerChanged);