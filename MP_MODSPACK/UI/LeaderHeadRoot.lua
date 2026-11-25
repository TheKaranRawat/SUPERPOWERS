----------------------------------------------------------------        
----------------------------------------------------------------        

include( "IconSupport" );
include( "GameplayUtilities" );
include( "InfoTooltipInclude" );

local g_iAIPlayer = -1;
local g_iAITeam = -1;

local g_DiploUIState = -1;

----------------------------------------------------------------
-- CONFIGURATION (seconds; set to 0 to disable a fade)
----------------------------------------------------------------
local FADE_IN_SECONDS  = 0.6;
local FADE_OUT_SECONDS = 0.5;

-- Fade the 3D leader/background scene too (via a black layer behind the UI)
local FADE_BACKGROUND = true;

local g_bSceneShown = false;     -- leader scene already faded in (avoids a black dip when returning from Trade/Discuss)
local g_bClosing = false;        -- true while the fade-out is running
local g_fFadeOutElapsed = 0;

local g_iRootMode = 0;
local g_iTradeMode = 1;
local g_iDiscussionMode = 2;

local g_strLeaveScreenText = Locale.ConvertTextKey("TXT_KEY_DIPLOMACY_ANYTHING_ELSE");

local offsetOfString = 32;
local bonusPadding = 16
local innerFrameWidth = 654;
local outerFrameWidth = 650;
local offsetsBetweenFrames = 4;

----------------------------------------------------------------        
-- FADE HELPERS
-- Purely cosmetic and local: nothing here touches game state or sends network
-- messages, so it cannot desync. The only gameplay call (RequestLeaveLeader)
-- is made exactly once, after the fade-out finishes.
-- The per-frame update handler is only installed while fading out.
----------------------------------------------------------------        
local function SetAnimSpeed( anim, seconds )
	-- Anim "Speed" is 1/duration. pcall so a missing method falls back to the XML default.
	if seconds > 0 then
		pcall( anim.SetSpeed, anim, 1 / seconds );
	end
end

local function PlayFadeIn()
	-- Background layer: only when the leader view is freshly opened
	Controls.OverlayOutAnim:Stop();
	Controls.OverlayOutAnim:SetToBeginning();		-- clear
	Controls.OverlayInAnim:Stop();
	Controls.OverlayInAnim:SetToBeginning();		-- black
	if FADE_BACKGROUND and not g_bSceneShown and FADE_IN_SECONDS > 0 then
		SetAnimSpeed( Controls.OverlayInAnim, FADE_IN_SECONDS );
		Controls.OverlayInAnim:Play();
	else
		Controls.OverlayInAnim:SetToEnd();			-- clear
	end
	g_bSceneShown = true;
	
	Controls.FadeOutAnim:Stop();
	Controls.FadeOutAnim:SetToBeginning();		-- alpha 1
	Controls.FadeInAnim:Stop();
	Controls.FadeInAnim:SetToBeginning();		-- alpha 0
	if FADE_IN_SECONDS > 0 then
		SetAnimSpeed( Controls.FadeInAnim, FADE_IN_SECONDS );
		Controls.FadeInAnim:Play();
	else
		Controls.FadeInAnim:SetToEnd();
	end
end

local function CancelClose()
	if g_bClosing then
		g_bClosing = false;
		ContextPtr:ClearUpdate();
		Controls.FadeOutAnim:Stop();
		Controls.FadeOutAnim:SetToBeginning();	-- back to fully visible
		Controls.OverlayOutAnim:Stop();
		Controls.OverlayOutAnim:SetToBeginning();	-- background clear again
	end
end

-- Dequeue the popup; optionally tell the game we are leaving the leader view
local function FinishClose( bRequestLeave )
	g_bClosing = false;
	g_bSceneShown = false;
	ContextPtr:ClearUpdate();
	Controls.OverlayOutAnim:Stop();
	Controls.OverlayOutAnim:SetToBeginning();
	UIManager:DequeuePopup( ContextPtr );
	UI.SetLeaderHeadRootUp( false );
	if bRequestLeave then
		UI.RequestLeaveLeader();
	end
end

local function OnFadeOutUpdate( fDTime )
	g_fFadeOutElapsed = g_fFadeOutElapsed + fDTime;
	if g_fFadeOutElapsed >= FADE_OUT_SECONDS then
		FinishClose( true );
	end
end

----------------------------------------------------------------        
-- LEADER MESSAGE HANDLER
----------------------------------------------------------------        
function LeaderMessageHandler( iPlayer, iDiploUIState, szLeaderMessage, iAnimationAction, iData1 )
	
	g_DiploUIState = iDiploUIState;
	
	g_iAIPlayer = iPlayer;
	g_iAITeam = Players[g_iAIPlayer]:GetTeam();

	LuaEvents.LeaderStatsSetPlayer(g_iAIPlayer)
	
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local pActiveTeam = Teams[pActivePlayer:GetTeam()];
	
	CivIconHookup( iPlayer, 64, Controls.ThemSymbolShadow, Controls.CivIconBG, Controls.CivIconShadow, false, true );
		
	-- Update title even if we're not in this mode, as we could exit to it somehow
	local player = Players[iPlayer];
	local strTitleText = GameplayUtilities.GetLocalizedLeaderTitle(player);
	Controls.TitleText:SetText(strTitleText);
	
	local playerLeaderInfo = GameInfo.Leaders[player:GetLeaderType()];
	
	-- Mood
	local iApproach = pActivePlayer:GetApproachTowardsUsGuess(g_iAIPlayer);
	local strMoodText = Locale.ConvertTextKey("TXT_KEY_EMOTIONLESS");
	
	if (pActiveTeam:IsAtWar(g_iAITeam)) then
		strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_WAR" );
	elseif (Players[g_iAIPlayer]:IsDenouncingPlayer(Game.GetActivePlayer())) then
		strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_DENOUNCING" );	
	elseif (Players[g_iAIPlayer]:WasResurrectedThisTurnBy(Game.GetActivePlayer())) then
		strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_LIBERATED" );		
	else
		if( iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_WAR ) then
			strMoodText = Locale.ConvertTextKey( "TXT_KEY_WAR_CAPS" );
		elseif( iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_HOSTILE ) then
			strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_HOSTILE", playerLeaderInfo.Description  );
		elseif( iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_GUARDED ) then
			strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_GUARDED", playerLeaderInfo.Description  );
		elseif( iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_AFRAID ) then
			strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_AFRAID", playerLeaderInfo.Description  );
		elseif( iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_FRIENDLY ) then
			strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_FRIENDLY", playerLeaderInfo.Description  );
		elseif( iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_NEUTRAL ) then
			strMoodText = Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_NEUTRAL", playerLeaderInfo.Description );
		end
	end
	
	Controls.MoodText:SetText(strMoodText);
	
	local strMoodInfo = GetMoodInfo(g_iAIPlayer);
	Controls.MoodText:SetToolTipString(strMoodInfo);
	
	local bMyMode = false;
	
	-- See if we're in this screen
	if (g_DiploUIState == DiploUIStateTypes.DIPLO_UI_STATE_DEFAULT_ROOT) then
		bMyMode = true;
	elseif (iDiploUIState == DiploUIStateTypes.DIPLO_UI_STATE_WAR_DECLARED_BY_HUMAN) then
		bMyMode = true;
	elseif (iDiploUIState == DiploUIStateTypes.DIPLO_UI_STATE_PEACE_MADE_BY_HUMAN) then
		bMyMode = true;
	end
	
	-- A new message while fading out means the screen is still wanted: cancel the close
	CancelClose();
	
	-- Are we in this screen's mode?
	if (bMyMode) then					
		UI.SetLeaderHeadRootUp( true );
		Controls.LeaderSpeech:SetText( szLeaderMessage );		
		-- Resize the height of the box to fit the text
		local contentSize = Controls.LeaderSpeech:GetSize().y + offsetOfString + bonusPadding;
		Controls.LeaderSpeechBorderFrame:SetSizeY( contentSize );
		Controls.LeaderSpeechFrame:SetSizeY( contentSize - offsetsBetweenFrames );
		
	else
		Controls.LeaderSpeech:SetText( g_strLeaveScreenText );		-- Seed the text box with something reasonable so that we don't get leftovers from somewhere else
		
	end
	
	UIManager:QueuePopup( ContextPtr, PopupPriority.LeaderHead );
    
end
Events.AILeaderMessage.Add( LeaderMessageHandler );


----------------------------------------------------------------        
-- BACK
----------------------------------------------------------------        
function OnReturn()
	if g_bClosing then
		return;		-- already fading out; ignore repeated clicks / keypresses
	end
	
	-- Nothing visible to fade (e.g. a sub-screen is up) or fade disabled: close immediately
	if FADE_OUT_SECONDS <= 0 or Controls.RootOptions:IsHidden() or ContextPtr:IsHidden() then
		FinishClose( true );
		return;
	end
	
	g_bClosing = true;
	g_fFadeOutElapsed = 0;
	-- Tell the stats panel to slide/fade out now, while this screen is still visible.
	-- (LeaderStatsHide only fires after the screen is hidden, which is too late to animate.)
	-- UI-only event; passes the fade-out length so the panel can finish in time.
	LuaEvents.LeaderStatsClose( FADE_OUT_SECONDS );
	SetAnimSpeed( Controls.FadeOutAnim, FADE_OUT_SECONDS );
	Controls.FadeOutAnim:SetToBeginning();
	Controls.FadeOutAnim:Play();
	if FADE_BACKGROUND then
		SetAnimSpeed( Controls.OverlayOutAnim, FADE_OUT_SECONDS );
		Controls.OverlayOutAnim:SetToBeginning();
		Controls.OverlayOutAnim:Play();
	end
	ContextPtr:SetUpdate( OnFadeOutUpdate );
end
Controls.BackButton:RegisterCallback( Mouse.eLClick, OnReturn );


----------------------------------------------------------------        
----------------------------------------------------------------        
function OnLeavingLeader()
    -- The game is leaving leader mode (e.g. turn change, war declared): close now, no fade,
    -- and do not request leave again.
	FinishClose( false );
end
Events.LeavingLeaderViewMode.Add( OnLeavingLeader );


local oldCursor = 0;

----------------------------------------------------------------        
-- SHOW/HIDE
----------------------------------------------------------------        
function OnShowHide( bHide )
	
	-- Showing Screen
	if (not bHide) then
	
		Controls.RootOptions:SetHide( not UI.GetLeaderHeadRootUp() );
		
		local pActiveTeam = Teams[Game.GetActiveTeam()];
		
		-- Hide or show war/peace button
		if (not pActiveTeam:CanChangeWarPeace(g_iAITeam)) then
			Controls.WarButton:SetHide(true);
		else
			Controls.WarButton:SetHide(false);
		end
		
		-- Hide or show the demand button
		if (Game.GetActiveTeam() == g_iAITeam) then
			Controls.DemandButton:SetHide(true);
		else
			Controls.DemandButton:SetHide(false);
		end
		
		-- Fade in only when the root options are what is being shown
		if (UI.GetLeaderHeadRootUp()) then
			PlayFadeIn();
		end
		
		oldCursor = UIManager:SetUICursor(0); -- make sure we start with the default cursor
		
	    if (g_iAITeam ~= -1) then
			local bAtWar = pActiveTeam:IsAtWar(g_iAITeam);
			
			if (bAtWar) then
				Controls.WarButton:SetText( Locale.ConvertTextKey( "TXT_KEY_DIPLO_NEGOTIATE_PEACE" ));
				Controls.TradeButton:SetDisabled(true);
				Controls.DemandButton:SetDisabled(true);
				Controls.DiscussButton:SetDisabled(true);
				
				local iLockedWarTurns = pActiveTeam:GetNumTurnsLockedIntoWar(g_iAITeam);
				
				-- Not locked into war
				if (iLockedWarTurns == 0) then
					Controls.WarButton:SetDisabled(false);
					Controls.WarButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_DIPLO_NEGOTIATE_PEACE_TT" ));
				-- Locked into war
				else
					Controls.WarButton:SetDisabled(true);
					Controls.WarButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_DIPLO_NEGOTIATE_PEACE_BLOCKED_TT", iLockedWarTurns ));
				end
			else
				Controls.WarButton:SetText( Locale.ConvertTextKey( "TXT_KEY_DIPLO_DECLARE_WAR" ));
				Controls.TradeButton:SetDisabled(false);
				Controls.DemandButton:SetDisabled(false);
				Controls.DiscussButton:SetDisabled(false);
				
				if (pActiveTeam:IsForcePeace(g_iAITeam)) then
					Controls.WarButton:SetDisabled(true);
					Controls.WarButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAY_NOT_ATTACK" ));
				elseif (not pActiveTeam:CanDeclareWar(g_iAITeam)) then
					Controls.WarButton:SetDisabled(true);
					Controls.WarButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAY_NOT_ATTACK_MOD" ));
				else
					Controls.WarButton:SetDisabled(false);
					Controls.WarButton:SetToolTipString( Locale.ConvertTextKey( "TXT_KEY_DIPLO_DECLARES_WAR_TT" ));
				end
				
			end
		end
		
	-- Hiding Screen
	else
		CancelClose();
		UIManager:SetUICursor(oldCursor); -- make sure we retrun the cursor to the previous state
		--Controls.LeaderSpeech:SetText( g_strLeaveScreenText );		-- Seed the text box with something reasonable so that we don't get leftovers from somewhere else
		LuaEvents.LeaderStatsHide()
	end
end
ContextPtr:SetShowHideHandler( OnShowHide );


----------------------------------------------------------------        
-- Key Down Processing
---------------------------------------------------------------- 
--[[ old        
function InputHandler( uiMsg, wParam, lParam )
    if( uiMsg == KeyEvents.KeyDown )
    then
        if( wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN ) then
			OnReturn();
        end
    end
    return true;
end
ContextPtr:SetInputHandler( InputHandler );
]]--

function InputHandler( uiMsg, wParam, lParam )
    if( uiMsg == KeyEvents.KeyDown )
    then
        if( wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN ) then
            OnReturn();
        end

    -- mouse side button acts as return
    elseif( uiMsg == 523 ) then   -- WM_XBUTTONDOWN
        local xButton = math.floor( wParam / 65536 ) % 256   -- high word
        if xButton == 0 then xButton = wParam end            -- fallback if already unpacked
        if xButton == 1 then   -- same button as the other screens; use 1 for the other one
            OnReturn();
        end
    end
    return true;
end
ContextPtr:SetInputHandler( InputHandler );


----------------------------------------------------------------        
----------------------------------------------------------------        
function OnDiscuss()
	if g_bClosing then return; end
	Controls.LeaderSpeech:SetText( g_strLeaveScreenText );		-- Seed the text box with something reasonable so that we don't get leftovers from somewhere else
		
	Game.DoFromUIDiploEvent( FromUIDiploEventTypes.FROM_UI_DIPLO_EVENT_HUMAN_WANTS_DISCUSSION, g_iAIPlayer, 0, 0 );
end
Controls.DiscussButton:RegisterCallback( Mouse.eLClick, OnDiscuss );


----------------------------------------------------------------        
----------------------------------------------------------------        
function OnTrade()
	if g_bClosing then return; end
	-- This calls into CvDealAI and sets up the initial state of the UI
	Players[g_iAIPlayer]:DoTradeScreenOpened();
	
	Controls.LeaderSpeech:SetText( g_strLeaveScreenText );		-- Seed the text box with something reasonable so that we don't get leftovers from somewhere else
	
    UI.OnHumanOpenedTradeScreen(g_iAIPlayer);
end
Controls.TradeButton:RegisterCallback( Mouse.eLClick, OnTrade );


----------------------------------------------------------------        
----------------------------------------------------------------        
function OnDemand()
	if g_bClosing then return; end
	
	Controls.LeaderSpeech:SetText( g_strLeaveScreenText );		-- Seed the text box with something reasonable so that we don't get leftovers from somewhere else
	
    UI.OnHumanDemand(g_iAIPlayer);
end
Controls.DemandButton:RegisterCallback( Mouse.eLClick, OnDemand );


----------------------------------------------------------------        
----------------------------------------------------------------        
function OnWarOrPeace()
	if g_bClosing then return; end
	
    local bAtWar = Teams[Game.GetActiveTeam()]:IsAtWar(g_iAITeam);
    
	-- Asking for Peace (currently at war) - bring up the trade screen
    if (bAtWar) then
	    Game.DoFromUIDiploEvent( FromUIDiploEventTypes.FROM_UI_DIPLO_EVENT_HUMAN_NEGOTIATE_PEACE, g_iAIPlayer, 0, 0 );
		
    -- Declaring War (currently at peace)
	else
		UI.AddPopup{ Type = ButtonPopupTypes.BUTTONPOPUP_DECLAREWARMOVE, Data1 = g_iAITeam, Option1 = true};
    end
    
end
Controls.WarButton:RegisterCallback( Mouse.eLClick, OnWarOrPeace );


----------------------------------------------------------------        
----------------------------------------------------------------        
function WarStateChangedHandler( iTeam1, iTeam2, bWar )
	
	-- Active player changed war state with this AI
	if (iTeam1 == Game.GetActiveTeam() and iTeam2 == g_iAITeam) then
		
		if (bWar) then
			Controls.WarButton:SetText( Locale.ConvertTextKey( "TXT_KEY_DIPLO_NEGOTIATE_PEACE" ));
			Controls.TradeButton:SetDisabled(true);
			Controls.DemandButton:SetDisabled(true);
			Controls.DiscussButton:SetDisabled(true);
		else
			Controls.WarButton:SetText(Locale.ConvertTextKey( "TXT_KEY_DIPLO_DECLARE_WAR" ));
			Controls.TradeButton:SetDisabled(false);
			Controls.DemandButton:SetDisabled(false);
			Controls.DiscussButton:SetDisabled(false);
		end
		
	end
	
end
Events.WarStateChanged.Add( WarStateChangedHandler );

---------------------------------------------------------------------------------------
-- Support for Modded Add-in UI's
---------------------------------------------------------------------------------------
g_uiAddins = {};
for addin in Modding.GetActivatedModEntryPoints("DiplomacyUIAddin") do
	local addinFile = Modding.GetEvaluatedFilePath(addin.ModID, addin.Version, addin.File);
	local addinPath = addinFile.EvaluatedPath;
	
	-- Get the absolute path and filename without extension.
	local extension = Path.GetExtension(addinPath);
	local path = string.sub(addinPath, 1, #addinPath - #extension);
	
	table.insert(g_uiAddins, ContextPtr:LoadNewContext(path));
end