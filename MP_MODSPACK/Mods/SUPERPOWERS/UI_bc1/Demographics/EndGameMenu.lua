----------------------------------------------------------------
-- Modified by bc1 from 1.0.3.276 code using Notepad++
----------------------------------------------------------------
include "IconHookup"
include "CommonBehaviors"

local m_StrAudio, m_EndGameType, m_EndGameTeam, m_IsAllowBack, m_AnimUpdate
local m_fTime = 0;
local m_deferredDisplayTime = 0;

local m_AllowBack = {
	[ EndGameTypes.Time or -1 ] = true,
	[ EndGameTypes.Technology or -1 ] = true,
	[ EndGameTypes.Domination or -1 ] = true,
	[ EndGameTypes.Culture or -1 ] = true,
	[ EndGameTypes.Diplomatic or -1 ] = true,
	[ EndGameTypes.Loss or -1 ] = true,
}
local m_TutorialGame = {
	[ EndGameTypes.Tutorial1 or -1 ] = true,
	[ EndGameTypes.Tutorial2 or -1 ] = true,
	[ EndGameTypes.Tutorial3 or -1 ] = true,
	[ EndGameTypes.Tutorial4 or -1 ] = true,
	[ EndGameTypes.Tutorial5 or -1 ] = true,
--	[ EndGameTypes.Technology or -1 ] = true,
}
local m_EndGameText = {
	[ EndGameTypes.Tutorial1 or -1 ] = "TXT_KEY_TUTORIAL_1_COMPLETE",
	[ EndGameTypes.Tutorial2 or -1 ] = "TXT_KEY_TUTORIAL_2_COMPLETE",
	[ EndGameTypes.Tutorial3 or -1 ] = "TXT_KEY_TUTORIAL_3_COMPLETE",
	[ EndGameTypes.Tutorial4 or -1 ] = "TXT_KEY_TUTORIAL_4_COMPLETE",
	[ EndGameTypes.Tutorial5 or -1 ] = "TXT_KEY_TUTORIAL_5_COMPLETE",
	[ EndGameTypes.Time or -1 ] = "TXT_KEY_VICTORY_FLAVOR_TIME",
	[ EndGameTypes.Technology or -1 ] = "TXT_KEY_VICTORY_FLAVOR_TECHNOLOGY",
	[ EndGameTypes.Domination or -1 ] = "TXT_KEY_VICTORY_FLAVOR_DOMINATION",
	[ EndGameTypes.Culture or -1 ] = "TXT_KEY_VICTORY_FLAVOR_CULTURE",
	[ EndGameTypes.Diplomatic or -1 ] = "TXT_KEY_VICTORY_FLAVOR_DIPLOMACY",
}
local m_VictoryType = {
	[ EndGameTypes.Time or -1 ] = "VICTORY_TIME",
	[ EndGameTypes.Technology or -1 ] = "VICTORY_SPACE_RACE",
	[ EndGameTypes.Domination or -1 ] = "VICTORY_DOMINATION",
	[ EndGameTypes.Culture or -1 ] = "VICTORY_CULTURAL",
	[ EndGameTypes.Diplomatic or -1 ] = "VICTORY_DIPLOMATIC",
}

----------------------------------------------------------------
local function OnBack()
	if m_IsAllowBack then
		Network.SendExtendedGame()
	end
	if m_IsAllowBack ~= false then
		UIManager:DequeuePopup( ContextPtr )
		Controls.BackgroundImage:UnloadTexture()
	end
end

local function EndGameMenu( a, b, c, d, e )
	Controls.Ranking:SetHide( a )
	Controls.EndGameReplay:SetHide( b )
	Controls.EndGameDemographics:SetHide( c )
	Controls.GameOverContainer:SetHide( d )
	Controls.BackgroundImage:SetColor{x=1,y=1,z=1,w=e}
end
Controls.GameOverButton:RegisterCallback( Mouse.eLClick, function() EndGameMenu( true, true, true, false, 1 ) end )
Controls.DemographicsButton:RegisterCallback( Mouse.eLClick, function() EndGameMenu( true, true, false, true, 0.125 ) end )
Controls.ReplayButton:RegisterCallback( Mouse.eLClick, function() EndGameMenu( true, false, true, true, 0.125 ) end )
Controls.RankingButton:RegisterCallback( Mouse.eLClick, function() EndGameMenu( false, true, true, true, 0.125 ) end )
Controls.BeyondButton:RegisterCallback( Mouse.eLClick, function() Steam.ActivateGameOverlayToStore(65980) end )
Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );

Controls.MainMenuButton:RegisterCallback( Mouse.eLClick,
function()
	UIManager:DequeuePopup( ContextPtr )

	if Game.IsHotSeat() and Game.CountHumanPlayersAlive() > 0 then
		local iActivePlayer = Game.GetActivePlayer();
		-- If the player is not alive, but there are other humans in the game that are
		-- find the next human player alive and make them the active player
		if not Players[iActivePlayer]:IsAlive() then
			local m = GameDefines.MAX_MAJOR_CIVS
			for i = iActivePlayer+1, iActivePlayer+m-1 do
				local iNextPlayer = i % m
				local player = Players[iNextPlayer];
				if player:IsAlive() and player:IsHuman() then
					Game.SetActivePlayer( iNextPlayer )
					-- Restore the game state
					Game.SetGameState( GameplayGameStateTypes.GAMESTATE_ON )
					UIManager:DequeuePopup( ContextPtr )
					return
				end
			end
		end
	end
	Events.ExitToMainMenu();
end)

----------------------------------------------------------------
-- Key Down Processing
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				OnBack()
			end
			return true
		end
	end)
end

----------------------------------------------------------------
ContextPtr:SetUpdate(
function( fDTime )
	-- Cap the delta time to eliminate overshooting because of delays in processing.
	local fMaxDTime = fDTime;
	if (fMaxDTime > 0.1) then
		fMaxDTime = 0.1;
	end

	-- Delaying the display so we can see some animation?
	if m_deferredDisplayTime > 0 then
		-- Yes, hide the UI
		Controls.BGBlock:SetHide(true);
		Controls.BGWin:SetHide(true);
		m_deferredDisplayTime = m_deferredDisplayTime - fMaxDTime;
		if m_deferredDisplayTime <= 0 then
			Controls.BGBlock:SetHide(false);
			Controls.BGWin:SetHide(false);
			m_deferredDisplayTime = 0;
		end
	else
		local fNewTime = m_fTime + fMaxDTime
		if m_StrAudio and m_fTime < 2 and fNewTime >= 2 then
			-- print("Play audio:", m_StrAudio);
			Events.AudioPlay2DSound(m_StrAudio)
		end
		if m_AnimUpdate and m_AnimUpdate(fMaxDTime) then
			m_AnimUpdate = nil
		end
		m_fTime = fNewTime
	end

end)

----------------------------------------------------------------
ContextPtr:SetShowHideHandler(
function( isHide, isInit )
	Controls.BackgroundImage:UnloadTexture()
	if not isInit then
		if isHide then
			UI.decTurnTimerSemaphore()
		else
			UI.incTurnTimerSemaphore()
			UIManager:SetUICursor( 0 );
			Controls.EndGameReplay:ChangeParent( ContextPtr )

			local endGameType = m_EndGameType
			local isTutorialGame = false
			local isHideBeyondEarth = true
			local playerID = Game.GetActivePlayer();
			local player = Players[playerID];

			if m_EndGameTeam == Game.GetActiveTeam() then
				Controls.EndGameText:LocalizeAndSetText( m_EndGameText[ endGameType ] or "TXT_KEY_VICTORY_BANG" )
				isTutorialGame = m_TutorialGame[ endGameType ]
				if endGameType == EndGameTypes.Technology then
					m_deferredDisplayTime = 7
					isHideBeyondEarth = false
				end
				local victoryType = m_VictoryType[ endGameType ]
				m_IsAllowBack = victoryType and PreGame.GetGameOption("GAMEOPTION_NO_EXTENDED_PLAY") ~= 1
				--print(victoryType);
				local victoryInfo = GameInfo.Victories[ victoryType or "VICTORY_TIME" ]
				if victoryInfo then
					m_StrAudio = victoryInfo.Audio
					Controls.BackgroundImage:SetTexture( victoryInfo.VictoryBackground )
				else
					m_StrAudio = nil
				end
			else
				Controls.EndGameText:LocalizeAndSetText( "TXT_KEY_VICTORY_FLAVOR_LOSS" ) -- TXT_KEY_DEFEAT_BANG
				Controls.BackgroundImage:SetTexture( "Victory_Defeat.dds" )
				m_IsAllowBack = m_AllowBack[ endGameType ] and not Game:IsNetworkMultiPlayer() and player:IsAlive() and PreGame.GetGameOption("GAMEOPTION_NO_EXTENDED_PLAY") ~= 1
				m_StrAudio = "AS2D_VICTORY_SPEECH_LOSS"
			end

			CivIconHookup( playerID, 80, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true )
			Controls.BackButton:SetDisabled( m_IsAllowBack == false )
			Controls.RankingButton:SetHide( isTutorialGame )
			Controls.ReplayButton:SetHide( isTutorialGame )
			Controls.DemographicsButton:SetHide( isTutorialGame )
			Controls.GameOverContainer:SetSizeY( Controls.EndGameText:GetSizeY() + 30 )
			if Controls.BeyondButton then
				Controls.BeyondButton:SetHide( isHideBeyondEarth )
				Controls.ButtonStack:CalculateSize()
				Controls.ButtonStack:ReprocessAnchoring()
			end
			-- Display a continue button if there are other players left in the game
			Controls.MainMenuButton:LocalizeAndSetText( Game.IsHotSeat() and Game.CountHumanPlayersAlive() > 0 and not player:IsAlive() and "TXT_KEY_MP_PLAYER_CHANGE_CONTINUE" or "TXT_KEY_MENU_EXIT_TO_MAIN" )

			m_AnimUpdate = ZoomOutEffect{
				SplashControl = Controls.BackgroundImage,
				ScaleFactor = 0.5,
				AnimSeconds = 3
			}
			m_fTime = 0;
		end
	end
end)

----------------------------------------------------------------
Events.EndGameShow.Add(
function( endGameType, team )
	m_EndGameType = endGameType
	m_EndGameTeam = team
	if ContextPtr:IsHidden() then
		UIManager:QueuePopup( ContextPtr, PopupPriority.EndGameMenu )
	end
end)
