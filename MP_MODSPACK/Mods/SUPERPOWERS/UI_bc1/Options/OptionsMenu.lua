--==========================================================
-- Options Menu
-- Modified by bc1 from 1.0.3.276 code using Notepad++
-- add new options for EUI
--==========================================================

include "UserInterfaceSettings"
local UserInterfaceSettings = UserInterfaceSettings

--==========================================================
-- Minor lua optimizations
--==========================================================

local ipairs = ipairs
local floor = math.floor
local format = string.format
local insert = table.insert

local ContentManager = ContentManager
local ContentType = ContentType
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local GameStateTypes = GameStateTypes
local GetVolumeKnobIDFromName = GetVolumeKnobIDFromName
local GetVolumeKnobValue = GetVolumeKnobValue
local KeyEvents = KeyEvents
local Keys = Keys
local Locale = Locale
local L = Locale.ConvertTextKey
local Matchmaking = Matchmaking
local Mouse = Mouse
local Network = Network
local OptionsManager = OptionsManager
local PopupPriority = PopupPriority
local PreGame = PreGame
local SaveAudioOptions = SaveAudioOptions
local SetVolumeKnobValue = SetVolumeKnobValue
local SystemUpdateUIType = SystemUpdateUIType
local UI = UI
local UIManager = UIManager

local g_isInGame = ContextPtr:GetID() == "OptionsMenu_InGame"
local m_FullscreenResList = {};
local m_iResolutionCount;
local m_maxX, m_maxY = OptionsManager.GetMaxResolution();
local m_bInGameQuickCombatState_Cached = false;
local m_bInGameQuickMovementState_Cached = false;
local m_TutorialLevelText = {}

local m_PanelNames = {
	L"TXT_KEY_GAME_OPTIONS",
	L"TXT_KEY_INTERFACE_OPTIONS",
	L"TXT_KEY_VIDEO_OPTIONS",
	L"TXT_KEY_AUDIO_OPTIONS",
	L"TXT_KEY_MULTIPLAYER_OPTIONS",
}

local m_WindowResList = {
{ x=2560, y=2048, bWide=false },
{ x=2560, y=1600, bWide=true },
{ x=1920, y=1200, bWide=true },
{ x=1920, y=1080, bWide=true },
{ x=1680, y=1050, bWide=true },
{ x=1600, y=1200, bWide=false },
{ x=1440, y=900,  bWide=true  },
{ x=1400, y=1050, bWide=true  },
{ x=1366, y=768,  bWide=true },
{ x=1280, y=1024, bWide=false },
{ x=1280, y=960,  bWide=true  },
{ x=1280, y=800,  bWide=true  },
{ x=1024, y=768,  bWide=false },
}

local m_LeaderText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_MINIMUM",
L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_OverlayText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_ShadowText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_OFF",
L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_FOWText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_MINIMUM",
L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_TerrainDetailText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_MINIMUM",
L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_TerrainTessText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_TerrainShadowText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_OFF",
L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_WaterText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_MEDIUM",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_TextureQualityText = {
[0] = L"TXT_KEY_OPSCREEN_SETTINGS_LOW",
L"TXT_KEY_OPSCREEN_SETTINGS_HIGH",
}
local m_BindMouseText = {
[0] = L"TXT_KEY_NEVER",
L"TXT_KEY_FULLSCREEN_ONLY",
L"TXT_KEY_ALWAYS",
}
local m_MSAAText = {
[0] = L"TXT_KEY_OPSCREEN_MSAA_OFF",
L"TXT_KEY_OPSCREEN_MSAA_2X",
L"TXT_KEY_OPSCREEN_MSAA_4X",
L"TXT_KEY_OPSCREEN_MSAA_8X",
}
local m_MSAAMap = { [0] = 1, 2, 4, 8 }

local m_MSAAInvMap = { [0]=0, 0, 1, [4]=2, [8]=3 }

-- Store array of supported languages.
local g_Languages = Locale.GetSupportedLanguages();
local g_SpokenLanguages = Locale.GetSupportedSpokenLanguages();

-------------------------------------------------
-- Volume control
-------------------------------------------------
local g_VolumeSliders = {
	[GetVolumeKnobIDFromName("USER_VOLUME_MUSIC")or -1] = {
		SliderControl = Controls.MusicVolumeSlider,
		ValueControl = Controls.MusicVolumeSliderValue,
		Text = "TXT_KEY_OPSCREEN_MUSIC_SLIDER",
	},
	[GetVolumeKnobIDFromName("USER_VOLUME_SFX")or -1] = {
		SliderControl = Controls.EffectsVolumeSlider,
		ValueControl = Controls.EffectsVolumeSliderValue,
		Text = "TXT_KEY_OPSCREEN_SF_SLIDER",
	},
	[GetVolumeKnobIDFromName("USER_VOLUME_SPEECH")or -1] = {
		SliderControl = Controls.SpeechVolumeSlider,
		ValueControl = Controls.SpeechVolumeSliderValue,
		Text = "TXT_KEY_OPSCREEN_SPEECH_SLIDER",
	},
	[GetVolumeKnobIDFromName("USER_VOLUME_AMBIENCE")or -1] = {
		SliderControl = Controls.AmbienceVolumeSlider,
		ValueControl = Controls.AmbienceVolumeSliderValue,
		Text = "TXT_KEY_OPSCREEN_AMBIANCE_SLIDER",
	},
	[-1] = nil
}
local function ChangedVolumeLevel( volumeKnobID, volume )
	local volumeSlider = g_VolumeSliders[ volumeKnobID ]
	if volumeSlider then
		volumeSlider.ValueControl:LocalizeAndSetText( volumeSlider.Text, Locale.ToPercent( volume ) )
	end
end
--Events.AudioVolumeChanged.Add( OnGameChangedVolumeLevel );

local function OnUIVolumeSliderValueChanged( volume, volumeKnobID )
	SetVolumeKnobValue( volumeKnobID, volume )
	ChangedVolumeLevel( volumeKnobID, volume )
end

for volumeKnobID, volumeSlider in pairs( g_VolumeSliders ) do
	volumeSlider.SliderControl:RegisterSliderCallback( OnUIVolumeSliderValueChanged )
	volumeSlider.SliderControl:SetVoid1( volumeKnobID )
	local volume = GetVolumeKnobValue( volumeKnobID )
	volumeSlider.SliderControl:SetValue( volume )
	volumeSlider.ValueControl:LocalizeAndSetText( volumeSlider.Text, Locale.ToPercent( volume ) )
	volumeSlider.CachedVolume = volume
end

local function CacheAudioVolumes()
	for volumeKnobID, volumeSlider in pairs( g_VolumeSliders ) do
		volumeSlider.CachedVolume = GetVolumeKnobValue( volumeKnobID )
	end
end

local function RevertToCachedAudioVolumes()
	for volumeKnobID, volumeSlider in pairs( g_VolumeSliders ) do
		SetVolumeKnobValue( volumeKnobID, volumeSlider.CachedVolume )
	end
end

local function SetDefaultAudioVolumes()
	for volumeKnobID in pairs( g_VolumeSliders ) do
		SetVolumeKnobValue( volumeKnobID, 1 )
	end
end

Controls.AudioNextSong:RegisterCallback( Mouse.eLClick, function() Events.AudioDebugChangeMusic(true,false,false) end ) -- Play Next Song

-------------------------------------------------
-------------------------------------------------
Controls.AcceptButton:RegisterCallback( Mouse.eLClick,
function()
	UserInterfaceSettings.ScreenAutoClose = Controls.AutoCloseCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.CityAdvisor = Controls.CityAdvisorCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.Clock = Controls.ClockCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.CityRibbon = Controls.CityRibbonCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.UnitRibbon = Controls.UnitRibbonCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.FlagPromotions = Controls.FlagPromotionsCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.CivilizationRibbon = Controls.CivRibbonCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.PredictiveRange = Controls.PredictiveRangeCheckbox:IsChecked() and 1 or 0
	UserInterfaceSettings.CityStateLeaders = Controls.CSLCheckbox:IsChecked() and 1 or 0

	OptionsManager.CommitGameOptions()
	OptionsManager.CommitGraphicsOptions()
	SaveAudioOptions()

	if g_isInGame then

		local bCanCommit = false;
		if PreGame.IsMultiplayerGame() then
			if Matchmaking.IsHost() then
				-- If we are the host of a game, we can change the quick states
				bCanCommit = true;
			end
		else
			bCanCommit = true;
		end

		if bCanCommit then
			local options = {};
			if m_bInGameQuickCombatState_Cached ~= PreGame.GetQuickCombat() then
				insert(options, { "GAMEOPTION_QUICK_COMBAT", m_bInGameQuickCombatState_Cached });
			end

			if m_bInGameQuickMovementState_Cached ~= PreGame.GetQuickMovement() then
				insert(options, { "GAMEOPTION_QUICK_MOVEMENT", m_bInGameQuickMovementState_Cached });
			end

			Network.SendGameOptions(options);
		end
	end

	--update local caches because the hide handler will set values back to cached versions
	CacheAudioVolumes()

	local bResolutionChanged = OptionsManager.HasUserChangedResolution();
	local bGraphicsChanged = OptionsManager.HasUserChangedGraphicsOptions();

	if bResolutionChanged then
		OnApplyRes();
	end

	if bGraphicsChanged then
		Controls.GraphicsChangedPopup:SetHide(false);
	end

	if not bGraphicsChanged and not bResolutionChanged then
		OnBack();
	end
end)

-------------------------------------------------
-------------------------------------------------
local function OnCancel()
	OptionsManager.SyncGameOptionsCache();
	OptionsManager.SyncGraphicsOptionsCache();
	OptionsManager.SyncResolutionOptionsCache();
	RevertToCachedAudioVolumes();
	OnBack();
end
Controls.CancelButton:RegisterCallback( Mouse.eLClick, OnCancel );

-------------------------------------------------
-------------------------------------------------
Controls.DefaultButton:RegisterCallback( Mouse.eLClick,
function()
	OptionsManager.ResetDefaultGameOptions();
	OptionsManager.ResetDefaultGraphicsOptions();
	SetDefaultAudioVolumes();
	UpdateOptionsDisplay();
end)

-------------------------------------------------
-------------------------------------------------
local fullscreenRes;
local windowedResX, windowedResY = 0,0;
local msaaSetting;
local bFullscreen;

function SavePreviousResolutionSettings()
	fullscreenRes = OptionsManager.GetResolution_Cached();
	windowedResX, windowedResY = OptionsManager.GetWindowResolution_Cached();
	msaaSetting = OptionsManager.GetAASamples_Cached();
	bFullscreen = OptionsManager.GetFullscreen_Cached();
end

-------------------------------------------------
-------------------------------------------------
function RestorePreviousResolutionSettings()
	OptionsManager.SetResolution_Cached(fullscreenRes);
	OptionsManager.SetWindowResolution_Cached(windowedResX, windowedResY);
	OptionsManager.SetAASamples_Cached(msaaSetting);
	OptionsManager.SetFullscreen_Cached(bFullscreen);
	if OptionsManager.HasUserChangedResolution() then
		OptionsManager.CommitResolutionOptions();
	end
	UpdateGraphicsOptionsDisplay();
end

-------------------------------------------------
-- If we hear a multiplayer game invite was sent, exit
-- so we don't interfere with the transition
-------------------------------------------------
function OnMultiplayerGameInvite()
   	if not ContextPtr:IsHidden() then
		OnCancel();
	end
end

Events.MultiplayerGameLobbyInvite.Add( OnMultiplayerGameInvite );
Events.MultiplayerGameServerInvite.Add( OnMultiplayerGameInvite );

-------------------------------------------------
-------------------------------------------------
local g_fTimer;
function OnUpdate( fDTime )

	g_fTimer = g_fTimer - fDTime;
	if g_fTimer <= 0 then
		ContextPtr:ClearUpdate();
		OnCountdownNo();
	else
		Controls.CountdownTimer:SetText( format( "%i", g_fTimer + 1 ) );
	end
end


-------------------------------------------------
-------------------------------------------------
local g_bIsResolutionCountdown = true;
function ShowResolutionCountdown()
	g_fTimer = 20;
	ContextPtr:SetUpdate( OnUpdate );
	Controls.Countdown:SetHide(false);
	Controls.CountdownMessage:LocalizeAndSetText( "TXT_KEY_OPSCREEN_RESOLUTION_TIMER" )
	Controls.CountYes:LocalizeAndSetText( "TXT_KEY_YES_BUTTON" )
	Controls.CountNo:LocalizeAndSetText( "TXT_KEY_NO_BUTTON" )
	Controls.CountdownTimer:SetText( "20" );
	Controls.LabelStack:CalculateSize();
	Controls.LabelStack:ReprocessAnchoring();
	g_bIsResolutionCountdown = true;
end

-------------------------------------------------
-------------------------------------------------
local g_chosenLanguage = 0;
function ShowLanguageCountdown()
	g_fTimer = 20;
	ContextPtr:SetUpdate( OnUpdate );
	Controls.Countdown:SetHide(false);
	Controls.CountdownMessage:SetText( Locale.LookupLanguage(g_Languages[g_chosenLanguage].Type, "TXT_KEY_OPSCREEN_LANGUAGE_TIMER") );

	local YesText = format( "%s (%s)",
		Locale.LookupLanguage( g_Languages[g_chosenLanguage].Type, "TXT_KEY_YES_BUTTON"),
		L"TXT_KEY_YES_BUTTON" );
	Controls.CountYes:SetText( YesText );

	local NoText = format( "%s (%s)",
		Locale.LookupLanguage( g_Languages[g_chosenLanguage].Type, "TXT_KEY_NO_BUTTON"),
		L"TXT_KEY_NO_BUTTON" );
	Controls.CountNo:SetText( NoText );

	Controls.CountdownTimer:SetText( "20" );
	Controls.LabelStack:CalculateSize();
	Controls.LabelStack:ReprocessAnchoring();
	g_bIsResolutionCountdown = false;
end

-------------------------------------------------
-------------------------------------------------
function OnApplyRes()
	if OptionsManager.HasUserChangedResolution() then
		ShowResolutionCountdown()
		OptionsManager.CommitResolutionOptions();
		UpdateGraphicsOptionsDisplay();
	end
end
Controls.ApplyResButton:RegisterCallback( Mouse.eLClick, OnApplyRes );

-------------------------------------------------
-------------------------------------------------
function OnOptionsEvent()
	UIManager:QueuePopup( ContextPtr, PopupPriority.OptionsMenu );
end

-------------------------------------------------
-------------------------------------------------
local g_isContextPtrHidden = true
local g_needsInitializing = true
ContextPtr:SetShowHideHandler(
function( isHide, isInit )
	if isInit and g_isInGame and g_needsInitializing then
		Events.EventOpenOptionsScreen.Add( OnOptionsEvent )
		g_needsInitializing = false
	end
	if g_isContextPtrHidden ~= isHide then
		g_isContextPtrHidden = isHide

		if not isHide then
			RefreshTutorialLevelOptions();
			--options menu is being shown
			OptionsManager.SyncGameOptionsCache();
			OptionsManager.SyncGraphicsOptionsCache();
			OptionsManager.SyncResolutionOptionsCache();

			if g_isInGame then
				m_bInGameQuickCombatState_Cached = PreGame.GetQuickCombat();
				m_bInGameQuickMovementState_Cached = PreGame.GetQuickMovement();
			end

			CacheAudioVolumes();
			SavePreviousResolutionSettings();
			UpdateOptionsDisplay();

			if g_isInGame and (PreGame.IsMultiplayerGame() or PreGame.IsHotSeatGame()) then
				Controls.TutorialPull:SetDisabled( true );
				Controls.TutorialPull:SetAlpha( 0.5 );
				Controls.ResetTutorialButton:SetDisabled(true);
				Controls.ResetTutorialButton:SetAlpha( 0.5 );
			else
				Controls.TutorialPull:SetDisabled( false );
				Controls.TutorialPull:SetAlpha( 1.0 );
				Controls.ResetTutorialButton:SetDisabled(false);
				Controls.ResetTutorialButton:SetAlpha( 1.0 );
			end

			if g_isInGame and PreGame.IsMultiplayerGame() and not Matchmaking.IsHost() then
				-- Not this host, disable
				Controls.MPQuickCombatCheckbox:SetDisabled( true );
				Controls.MPQuickCombatCheckbox:SetAlpha( 0.5 );
				Controls.MPQuickMovementCheckbox:SetDisabled(true);
				Controls.MPQuickMovementCheckbox:SetAlpha( 0.5 );
			else
				Controls.MPQuickCombatCheckbox:SetDisabled( false );
				Controls.MPQuickCombatCheckbox:SetAlpha( 1.0 );
				Controls.MPQuickMovementCheckbox:SetDisabled(false);
				Controls.MPQuickMovementCheckbox:SetAlpha( 1.0 );
			end

			if g_isInGame then
				Controls.BGBlock:SetHide( false );
				Controls.VideoPanelBlock:SetHide( false );
				Controls.LanguagePull:SetDisabled( true );
				Controls.LanguagePull:SetAlpha( 0.5 );
				Controls.SpokenLanguagePull:SetDisabled(true);
				Controls.SpokenLanguagePull:SetAlpha( 0.5 );
			else
				Controls.VideoPanelBlock:SetHide( true );
				Controls.BGBlock:SetHide( true );
			end
		else
			--options menu is being hidden
			RevertToCachedAudioVolumes();
		end
	end
end)

-------------------------------------------------
-------------------------------------------------
function OnBack()
	if( Controls.GraphicsChangedPopup:IsHidden() and
		Controls.Countdown:IsHidden() ) then
		UIManager:DequeuePopup( ContextPtr );
	end

	Controls.GraphicsChangedPopup:SetHide(true);
	OnCountdownNo();
end
--Controls.CancelButton:RegisterCallback( Mouse.eLClick, OnBack );


-------------------------------------------------
-------------------------------------------------
function OnCategory( which )
	Controls.GamePanel:SetHide(  which ~= 1 );
	Controls.IFacePanel:SetHide( which ~= 2 );
	Controls.VideoPanel:SetHide( which ~= 3 );
	Controls.AudioPanel:SetHide( which ~= 4 );
	Controls.MultiplayerPanel:SetHide( which ~= 5 );

	Controls.GameHighlight:SetHide(  which ~= 1 );
	Controls.IFaceHighlight:SetHide( which ~= 2 );
	Controls.VideoHighlight:SetHide( which ~= 3 );
	Controls.AudioHighlight:SetHide( which ~= 4 );
	Controls.MultiplayerHighlight:SetHide( which ~= 5 );

	Controls.TitleLabel:SetText( m_PanelNames[ which ] );
end
Controls.GameButton:RegisterCallback(  Mouse.eLClick, OnCategory );
Controls.IFaceButton:RegisterCallback( Mouse.eLClick, OnCategory );
Controls.VideoButton:RegisterCallback( Mouse.eLClick, OnCategory );
Controls.AudioButton:RegisterCallback( Mouse.eLClick, OnCategory );
Controls.MultiplayerButton:RegisterCallback( Mouse.eLClick, OnCategory );

OnCategory( 1 );



Controls.Tooltip1TimerSlider:SetValue(OptionsManager.GetTooltip1Seconds()/1000)
Controls.Tooltip1TimerSlider:RegisterSliderCallback(
function(value)
	local i = floor(value * 100) * 10
	Controls.Tooltip1TimerLength:LocalizeAndSetText( "TXT_KEY_OPSCREEN_TOOLTIP_1_TIMER_LENGTH", i / 100 )
	OptionsManager.SetTooltip1Seconds_Cached(i)
end)

Controls.Tooltip2TimerSlider:SetValue(OptionsManager.GetTooltip2Seconds()/1000)
Controls.Tooltip2TimerSlider:RegisterSliderCallback(
function(value)
	local i = floor(value * 100) * 10
	Controls.Tooltip2TimerLength:LocalizeAndSetText( "TXT_KEY_OPSCREEN_TOOLTIP_2_TIMER_LENGTH", i / 100 )
	OptionsManager.SetTooltip2Seconds_Cached(i)
end)

-------------------------------------------------
-- Countdown handlers
-------------------------------------------------
function OnCountdownYes()
	if g_bIsResolutionCountdown == true then
		--just hide the menu
		Controls.Countdown:SetHide(true);
		SavePreviousResolutionSettings();
	else
		--apply language, reload UI
		Locale.SetCurrentLanguage( g_Languages[g_chosenLanguage].Type );
		Events.SystemUpdateUI( SystemUpdateUIType.ReloadUI );
	end
	--turn off timer
	ContextPtr:ClearUpdate();
end
Controls.CountYes:RegisterCallback( Mouse.eLClick, OnCountdownYes );

function OnCountdownNo()
	if g_bIsResolutionCountdown == true then
		--here we revert resolution options to some old options
		Controls.Countdown:SetHide(true);
		RestorePreviousResolutionSettings();
	else
		--revert language to current setting
		Controls.Countdown:SetHide(true);
		Controls.LanguagePull:GetButton():SetText(Locale.GetCurrentLanguage().DisplayName);
	end
	--turn off timer
	ContextPtr:ClearUpdate();
end
Controls.CountNo:RegisterCallback( Mouse.eLClick, OnCountdownNo );

function OnGraphicsChangedOK()
	--close the menu
	Controls.GraphicsChangedPopup:SetHide(true);
	OnBack();
end
Controls.GraphicsChangedOK:RegisterCallback( Mouse.eLClick, OnGraphicsChangedOK );

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
-- Display updating
----------------------------------------------------------------

function UpdateGameOptionsDisplay()

	Controls.AutoCloseCheckbox:SetCheck( UserInterfaceSettings.ScreenAutoClose ~= 0 )
	Controls.CityAdvisorCheckbox:SetCheck( UserInterfaceSettings.CityAdvisor ~= 0 )
	Controls.ClockCheckbox:SetCheck( UserInterfaceSettings.Clock ~= 0 )
	Controls.CityRibbonCheckbox:SetCheck( UserInterfaceSettings.CityRibbon ~= 0 )
	Controls.UnitRibbonCheckbox:SetCheck( UserInterfaceSettings.UnitRibbon ~= 0 )
	Controls.FlagPromotionsCheckbox:SetCheck( UserInterfaceSettings.FlagPromotions ~= 0 )
	Controls.CivRibbonCheckbox:SetCheck( UserInterfaceSettings.CivilizationRibbon ~= 0 )
	Controls.PredictiveRangeCheckbox:SetCheck( UserInterfaceSettings.PredictiveRange ~= 0 )
	Controls.CSLCheckbox:SetCheck( UserInterfaceSettings.CityStateLeaders ~= 0 )
	Controls.NoCitizenWarningCheckbox:SetCheck( OptionsManager.IsNoCitizenWarning_Cached() );
	Controls.AutoWorkersDontReplaceCB:SetCheck( OptionsManager.IsAutoWorkersDontReplace_Cached() );
	Controls.AutoWorkersDontRemoveFeaturesCB:SetCheck( OptionsManager.IsAutoWorkersDontRemoveFeatures_Cached() );
	Controls.NoRewardPopupsCheckbox:SetCheck( OptionsManager.IsNoRewardPopups_Cached() );
	Controls.NoBasicHelpCheckbox:SetCheck( OptionsManager.IsNoBasicHelp_Cached() );
	Controls.NoTileRecommendationsCheckbox:SetCheck( OptionsManager.IsNoTileRecommendations_Cached() );
	Controls.CivilianYieldsCheckbox:SetCheck( OptionsManager.IsCivilianYields_Cached() );
	Controls.SinglePlayerAutoEndTurnCheckBox:SetCheck(OptionsManager.GetSinglePlayerAutoEndTurnEnabled_Cached());
	Controls.MultiplayerAutoEndTurnCheckbox:SetCheck(OptionsManager.GetMultiplayerAutoEndTurnEnabled_Cached());
	Controls.QuickSelectionAdvCheckbox:SetCheck( OptionsManager.GetQuickSelectionAdvanceEnabled_Cached() );

	if g_isInGame then
		if PreGame.IsMultiplayerGame() or PreGame.IsHotSeatGame() then
			Controls.SPQuickCombatCheckBox:SetCheck(OptionsManager.GetSinglePlayerQuickCombatEnabled_Cached());
			Controls.SPQuickMovementCheckBox:SetCheck(OptionsManager.GetSinglePlayerQuickMovementEnabled_Cached());
			Controls.MPQuickCombatCheckbox:SetCheck(m_bInGameQuickCombatState_Cached);
			Controls.MPQuickMovementCheckbox:SetCheck(m_bInGameQuickMovementState_Cached);
		else
			Controls.SPQuickCombatCheckBox:SetCheck(m_bInGameQuickCombatState_Cached);
			Controls.SPQuickMovementCheckBox:SetCheck(m_bInGameQuickMovementState_Cached);
			Controls.MPQuickCombatCheckbox:SetCheck(OptionsManager.GetMultiplayerQuickCombatEnabled_Cached());
			Controls.MPQuickMovementCheckbox:SetCheck(OptionsManager.GetMultiplayerQuickMovementEnabled_Cached());
		end
	else
		Controls.SPQuickCombatCheckBox:SetCheck(OptionsManager.GetSinglePlayerQuickCombatEnabled_Cached());
		Controls.SPQuickMovementCheckBox:SetCheck(OptionsManager.GetSinglePlayerQuickMovementEnabled_Cached());
		Controls.MPQuickCombatCheckbox:SetCheck(OptionsManager.GetMultiplayerQuickCombatEnabled_Cached());
		Controls.MPQuickMovementCheckbox:SetCheck(OptionsManager.GetMultiplayerQuickMovementEnabled_Cached());
	end

	Controls.Tooltip1TimerLength:LocalizeAndSetText( "TXT_KEY_OPSCREEN_TOOLTIP_1_TIMER_LENGTH", OptionsManager.GetTooltip1Seconds_Cached() / 100 )
	Controls.Tooltip2TimerLength:LocalizeAndSetText( "TXT_KEY_OPSCREEN_TOOLTIP_2_TIMER_LENGTH", OptionsManager.GetTooltip2Seconds_Cached() / 100 )

	Controls.ZoomCheck:SetCheck( OptionsManager.GetStraightZoom_Cached() );
	Controls.PolicyInfo:SetCheck( OptionsManager.GetPolicyInfo_Cached() );
	Controls.AutoUnitCycleCheck:SetCheck( OptionsManager.GetAutoUnitCycle_Cached() );
	Controls.ScoreListCheck:SetCheck( OptionsManager.GetScoreList_Cached() );
	Controls.MPScoreListCheck:SetCheck( OptionsManager.GetMPScoreList_Cached() );

	Controls.AutosaveTurnsEdit:SetText( OptionsManager.GetTurnsBetweenAutosave_Cached() );
	Controls.AutosaveMaxEdit:SetText( OptionsManager.GetNumAutosavesKept_Cached() );
	Controls.BindMousePull:GetButton():SetText( m_BindMouseText[ OptionsManager.GetBindMouseMode_Cached() ] );

	local iTutorialLevel = OptionsManager.GetTutorialLevel_Cached();
	if iTutorialLevel < 0 then
		iTutorialLevel = #m_TutorialLevelText;
	end
	Controls.TutorialPull:GetButton():SetText( m_TutorialLevelText[ iTutorialLevel ] );

	Controls.LanguagePull:GetButton():SetText(Locale.GetCurrentLanguage().DisplayName);
	Controls.SpokenLanguagePull:GetButton():SetText(Locale.GetCurrentSpokenLanguage().DisplayName); --TODO: make this work like its friends -KS

	for volumeKnobID, volumeSlider in pairs( g_VolumeSliders ) do
		local volume = GetVolumeKnobValue( volumeKnobID )
		volumeSlider.SliderControl:SetValue( volume )
		volumeSlider.ValueControl:LocalizeAndSetText( volumeSlider.Text, Locale.ToPercent( volume ) )
	end

	Controls.DragSpeedSlider:SetValue( OptionsManager.GetDragSpeed_Cached() / 2 );
	Controls.DragSpeedValue:LocalizeAndSetText( "TXT_KEY_DRAG_SPEED", OptionsManager.GetDragSpeed_Cached() )
	Controls.PinchSpeedSlider:SetValue( OptionsManager.GetPinchSpeed_Cached() / 2 );
	Controls.PinchSpeedValue:LocalizeAndSetText( "TXT_KEY_PINCH_SPEED", OptionsManager.GetPinchSpeed_Cached() )

	if OptionsManager.GetAutoUIAssets_Cached() then
		Controls.AutoUIAssetsCheck:SetCheck( true );
		Controls.SmallUIAssetsCheck:SetCheck( false );
		Controls.SmallUIAssetsCheck:SetDisabled( true );
		Controls.SmallUIAssetsCheck:SetAlpha( 0.5 );
	else
		Controls.AutoUIAssetsCheck:SetCheck( false );
		Controls.SmallUIAssetsCheck:SetDisabled( false );
		Controls.SmallUIAssetsCheck:SetAlpha( 1.0 );
		Controls.SmallUIAssetsCheck:SetCheck( OptionsManager.GetSmallUIAssets_Cached() );
	end

	Controls.EnableMapInertiaCheck:SetCheck( OptionsManager.GetEnableMapInertia_Cached() );
	Controls.SkipIntroVideoCheck:SetCheck( OptionsManager.GetSkipIntroVideo_Cached() );

	Controls.Tooltip1TimerSlider:SetValue(OptionsManager.GetTooltip1Seconds_Cached()/1000);
	Controls.Tooltip2TimerSlider:SetValue(OptionsManager.GetTooltip2Seconds_Cached()/1000);
end
Events.GameOptionsChanged.Add(UpdateGameOptionsDisplay);


----------------------------------------------------------------
----------------------------------------------------------------
function UpdateGraphicsOptionsDisplay()
	--resolution options
	BuildFSResPulldown();
	BuildWResPulldown();

	local bIsFullscreen = OptionsManager.GetFullscreen_Cached();
	Controls.FullscreenCheck:SetCheck( bIsFullscreen );
	Controls.FSResolutionPull:SetHide( not bIsFullscreen);
	Controls.WResolutionPull:SetHide( bIsFullscreen );

	local kResInfo = m_FullscreenResList[ OptionsManager.GetResolution_Cached() ];
	if kResInfo then
		Controls.FSResolutionPull:GetButton():SetText( kResInfo.Width .. "x" .. kResInfo.Height .. "   " .. kResInfo.Refresh .. " Hz" );
	end

	local x, y = OptionsManager.GetWindowResolution_Cached();
	Controls.WResolutionPull:GetButton():SetText( x .. "x" .. y );
	Controls.MSAAPull:GetButton():SetText( m_MSAAText[ m_MSAAInvMap[OptionsManager.GetAASamples_Cached()] ] );

	--graphics options
	Controls.VSyncCheck:SetCheck( OptionsManager.GetVSync_Cached() );
	Controls.HDStratCheck:SetCheck( OptionsManager.GetHDStrategicView_Cached() );
	Controls.GPUDecodeCheck:SetCheck( OptionsManager.GetGPUTextureDecode_Cached() );
	if not OptionsManager.IsGPUTextureDecodeSupported() then
		Controls.GPUDecodeCheck:SetDisabled( true );
		Controls.GPUDecodeCheck:SetAlpha( 0.5 );
	end

	Controls.MinimizeGrayTilesCheck:SetCheck( OptionsManager.GetMinimizeGrayTiles_Cached() );
	Controls.FadeShadowsCheck:SetCheck( OptionsManager.GetFadeShadows_Cached() );

	Controls.LeaderPull:GetButton():SetText( m_LeaderText[ OptionsManager.GetLeaderQuality_Cached() ] );
	Controls.OverlayPull:GetButton():SetText( m_OverlayText[ OptionsManager.GetOverlayLevel_Cached() ] );
	Controls.ShadowPull:GetButton():SetText( m_ShadowText[ OptionsManager.GetShadowLevel_Cached() ] );
	Controls.FOWPull:GetButton():SetText( m_FOWText[ OptionsManager.GetFOWLevel_Cached() ] );
	Controls.TerrainDetailPull:GetButton():SetText( m_TerrainDetailText[ OptionsManager.GetTerrainDetailLevel_Cached() ] );
	Controls.TerrainTessPull:GetButton():SetText( m_TerrainTessText[ OptionsManager.GetTerrainTessLevel_Cached() ] );
	Controls.TerrainShadowPull:GetButton():SetText( m_TerrainShadowText[ OptionsManager.GetTerrainShadowQuality_Cached() ] );
	Controls.WaterPull:GetButton():SetText( m_WaterText[ OptionsManager.GetWaterQuality_Cached() ] );
	Controls.TextureQualityPull:GetButton():SetText( m_TextureQualityText[ OptionsManager.GetTextureQuality_Cached() ] );
end
Events.GraphicsOptionsChanged.Add(UpdateGraphicsOptionsDisplay);


----------------------------------------------------------------
----------------------------------------------------------------
function UpdateMultiplayerOptionsDisplay()
	Controls.TurnNotifySteamInviteCheckbox:SetCheck(OptionsManager.GetTurnNotifySteamInvite_Cached());
	Controls.TurnNotifyEmailCheckbox:SetCheck(OptionsManager.GetTurnNotifyEmail_Cached());
	Controls.TurnNotifyEmailAddressEdit:SetText(OptionsManager.GetTurnNotifyEmailAddress_Cached());
	Controls.TurnNotifySmtpEmailEdit:SetText(OptionsManager.GetTurnNotifySmtpEmailAddress_Cached());
	Controls.TurnNotifySmtpHostEdit:SetText(OptionsManager.GetTurnNotifySmtpHost_Cached());
	Controls.TurnNotifySmtpPortEdit:SetText(OptionsManager.GetTurnNotifySmtpPort_Cached());
	Controls.TurnNotifySmtpUserEdit:SetText(OptionsManager.GetTurnNotifySmtpUsername_Cached());
	Controls.TurnNotifySmtpPassEdit:SetText(OptionsManager.GetTurnNotifySmtpPassword_Cached());
	Controls.TurnNotifySmtpPassRetypeEdit:SetText(OptionsManager.GetTurnNotifySmtpPassword_Cached());
	Controls.TurnNotifySmtpTLS:SetCheck(OptionsManager.GetTurnNotifySmtpTLS_Cached());
	if OptionsManager.GetLANNickName_Cached then
		Controls.LANNickNameEdit:SetText(OptionsManager.GetLANNickName_Cached());
	end
	ValidateSmtpPassword(); -- Update passwords match label
end


----------------------------------------------------------------
----------------------------------------------------------------
function UpdateOptionsDisplay()
	UpdateGameOptionsDisplay();
	UpdateGraphicsOptionsDisplay();
	UpdateMultiplayerOptionsDisplay();
end


----------------------------------------------------------------
-- Game Options Handlers
----------------------------------------------------------------
Controls.ResetTutorialButton:RegisterCallback( Mouse.eLClick, OptionsManager.ResetTutorial )

Controls.NoCitizenWarningCheckbox:RegisterCheckHandler( OptionsManager.SetNoCitizenWarning_Cached )
Controls.AutoWorkersDontReplaceCB:RegisterCheckHandler( OptionsManager.SetAutoWorkersDontReplace_Cached )
Controls.AutoWorkersDontRemoveFeaturesCB:RegisterCheckHandler( OptionsManager.SetAutoWorkersDontRemoveFeatures_Cached )
Controls.NoRewardPopupsCheckbox:RegisterCheckHandler( OptionsManager.SetNoRewardPopups_Cached )
Controls.NoTileRecommendationsCheckbox:RegisterCheckHandler( OptionsManager.SetNoTileRecommendations_Cached )
Controls.CivilianYieldsCheckbox:RegisterCheckHandler( OptionsManager.SetCivilianYields_Cached )
Controls.NoBasicHelpCheckbox:RegisterCheckHandler( OptionsManager.SetNoBasicHelp_Cached )
Controls.QuickSelectionAdvCheckbox:RegisterCheckHandler( OptionsManager.SetQuickSelectionAdvanceEnabled_Cached )
Controls.AutosaveTurnsEdit:RegisterCallback( OptionsManager.SetTurnsBetweenAutosave_Cached )
Controls.AutosaveMaxEdit:RegisterCallback( OptionsManager.SetNumAutosavesKept_Cached )
Controls.ZoomCheck:RegisterCheckHandler( OptionsManager.SetStraightZoom_Cached )
--Controls.GridCheck:RegisterCheckHandler( OptionsManager.SetGridOn_Cached )
Controls.SinglePlayerAutoEndTurnCheckBox:RegisterCheckHandler( OptionsManager.SetSinglePlayerAutoEndTurnEnabled_Cached )
Controls.MultiplayerAutoEndTurnCheckbox:RegisterCheckHandler( OptionsManager.SetMultiplayerAutoEndTurnEnabled_Cached )
Controls.PolicyInfo:RegisterCheckHandler( OptionsManager.SetPolicyInfo_Cached )
Controls.AutoUnitCycleCheck:RegisterCheckHandler( OptionsManager.SetAutoUnitCycle_Cached )
Controls.ScoreListCheck:RegisterCheckHandler( OptionsManager.SetScoreList_Cached )
Controls.MPScoreListCheck:RegisterCheckHandler( OptionsManager.SetMPScoreList_Cached )
Controls.EnableMapInertiaCheck:RegisterCheckHandler( OptionsManager.SetEnableMapInertia_Cached )
Controls.SkipIntroVideoCheck:RegisterCheckHandler( OptionsManager.SetSkipIntroVideo_Cached )

----------------------------------------------------------------
----------------------------------------------------------------
function OnSinglePlayerQuickCombatCheck( bIsChecked )
	if g_isInGame then
		if not PreGame.IsMultiplayerGame() and not PreGame.IsHotSeatGame() then
			-- In a single player game, store for updating the current game option
			m_bInGameQuickCombatState_Cached = bIsChecked;
		end
	end
	OptionsManager.SetSinglePlayerQuickCombatEnabled_Cached(bIsChecked);
end
Controls.SPQuickCombatCheckBox:RegisterCheckHandler(OnSinglePlayerQuickCombatCheck);

----------------------------------------------------------------
----------------------------------------------------------------
function OnSinglePlayerQuickMovementCheck( bIsChecked )
	if g_isInGame then
		if not PreGame.IsMultiplayerGame() and not PreGame.IsHotSeatGame() then
			-- In a single player game, store for updating the current game option
			m_bInGameQuickMovementState_Cached = bIsChecked;
		end
	end
	OptionsManager.SetSinglePlayerQuickMovementEnabled_Cached(bIsChecked);
end
Controls.SPQuickMovementCheckBox:RegisterCheckHandler(OnSinglePlayerQuickMovementCheck);

----------------------------------------------------------------
----------------------------------------------------------------
function OnMultiplayerQuickCombatCheck( bIsChecked )
	if g_isInGame then
		if PreGame.IsMultiplayerGame() or PreGame.IsHotSeatGame() then
			-- In a multiplayer game, store for updating the current game option
			m_bInGameQuickCombatState_Cached = bIsChecked;
		end
	end
	OptionsManager.SetMultiplayerQuickCombatEnabled_Cached(bIsChecked);
end
Controls.MPQuickCombatCheckbox:RegisterCheckHandler(OnMultiplayerQuickCombatCheck);

----------------------------------------------------------------
----------------------------------------------------------------
function OnMultiplayerQuickMovementCheck( bIsChecked )
	if g_isInGame then
		if PreGame.IsMultiplayerGame() or PreGame.IsHotSeatGame() then
			-- In a multiplayer game, store for updating the current game option
			m_bInGameQuickMovementState_Cached = bIsChecked;
		end
	end
	OptionsManager.SetMultiplayerQuickMovementEnabled_Cached(bIsChecked);
end
Controls.MPQuickMovementCheckbox:RegisterCheckHandler(OnMultiplayerQuickMovementCheck);

----------------------------------------------------------------
----------------------------------------------------------------
Controls.AutoUIAssetsCheck:RegisterCheckHandler(
function( bIsChecked )
	OptionsManager.SetAutoUIAssets_Cached( bIsChecked );
	--mini dispaly update here
	if bIsChecked then
		Controls.SmallUIAssetsCheck:SetCheck( false );
		Controls.SmallUIAssetsCheck:SetDisabled( true );
		Controls.SmallUIAssetsCheck:SetAlpha( 0.5 );
	elseif UI.GetCurrentGameState() == GameStateTypes.CIV5_GS_MAIN_MENU then
		Controls.SmallUIAssetsCheck:SetDisabled( false );
		Controls.SmallUIAssetsCheck:SetAlpha( 1.0 );
		Controls.SmallUIAssetsCheck:SetCheck( OptionsManager.GetSmallUIAssets_Cached() );
	end
end)



----------------------------------------------------------------
----------------------------------------------------------------
function OnBindMousePull( level )
	OptionsManager.SetBindMouseMode_Cached( level );
	Controls.BindMousePull:GetButton():SetText( m_BindMouseText[ OptionsManager.GetBindMouseMode_Cached() ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnLanguagePull( level )
	level = level + 1; --offset because the pulldown is 0-based.
	Controls.LanguagePull:GetButton():SetText( g_Languages[level].DisplayName );
	g_chosenLanguage = level;
	ShowLanguageCountdown();
end

function OnSpokenLanguagePull( level ) --TODO: hook this up too! -KS
	level = level + 1;
	Locale.SetCurrentSpokenLanguage( g_SpokenLanguages[level].Type );
	Controls.SpokenLanguagePull:GetButton():SetText( g_SpokenLanguages[level].DisplayName );
end

----------------------------------------------------------------
----------------------------------------------------------------
function OnTutorialPull( level )
	local iTutorialLevel = level;

	local bExpansion2Active = ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY);
	local bExpansion1Active = ContentManager.IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType.GAMEPLAY);
	if bExpansion1Active and not bExpansion2Active then
		if iTutorialLevel == 4 then
			iTutorialLevel = -1;
		end
	elseif bExpansion2Active then
		if iTutorialLevel == 5 then
			iTutorialLevel = -1;
		end
	else
		if iTutorialLevel == 3 then
			iTutorialLevel = -1;
		end
	end
	OptionsManager.SetTutorialLevel_Cached(iTutorialLevel);
	Controls.TutorialPull:GetButton():SetText( m_TutorialLevelText[ level ] );
end


----------------------------------------------------------------
-- Graphics Options Handlers
----------------------------------------------------------------

Controls.SmallUIAssetsCheck:RegisterCheckHandler( OptionsManager.SetSmallUIAssets_Cached )
Controls.HDStratCheck:RegisterCheckHandler( OptionsManager.SetHDStrategicView_Cached )
Controls.GPUDecodeCheck:RegisterCheckHandler( OptionsManager.SetGPUTextureDecode_Cached )
Controls.MinimizeGrayTilesCheck:RegisterCheckHandler( OptionsManager.SetMinimizeGrayTiles_Cached )
Controls.FadeShadowsCheck:RegisterCheckHandler( OptionsManager.SetFadeShadows_Cached )
Controls.VSyncCheck:RegisterCheckHandler( OptionsManager.SetVSync_Cached )

----------------------------------------------------------------
----------------------------------------------------------------
Controls.FullscreenCheck:RegisterCheckHandler(
function( bIsChecked )
	OptionsManager.SetFullscreen_Cached( bIsChecked );
	Controls.FSResolutionPull:SetHide( not bIsChecked );
	Controls.WResolutionPull:SetHide( bIsChecked );

end)


----------------------------------------------------------------
----------------------------------------------------------------
function OnLeaderPull( level )
	OptionsManager.SetLeaderQuality_Cached( level );
	Controls.LeaderPull:GetButton():SetText( m_LeaderText[ level ] );
end

----------------------------------------------------------------
----------------------------------------------------------------
function OnOverlayPull( level )
	OptionsManager.SetOverlayLevel_Cached( level );
	Controls.OverlayPull:GetButton():SetText( m_OverlayText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnShadowPull( level )
	OptionsManager.SetShadowLevel_Cached( level );
	Controls.ShadowPull:GetButton():SetText( m_ShadowText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnFOWPull( level )
	OptionsManager.SetFOWLevel_Cached( level );
	Controls.FOWPull:GetButton():SetText( m_FOWText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnTerrainDetailPull( level )
	OptionsManager.SetTerrainDetailLevel_Cached( level );
	Controls.TerrainDetailPull:GetButton():SetText( m_TerrainDetailText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnTerrainTessPull( level )
	OptionsManager.SetTerrainTessLevel_Cached( level );
	Controls.TerrainTessPull:GetButton():SetText( m_TerrainTessText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnTerrainShadowPull( level )
	OptionsManager.SetTerrainShadowQuality_Cached( level );
	Controls.TerrainShadowPull:GetButton():SetText( m_TerrainShadowText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnWaterPull( level )
	OptionsManager.SetWaterQuality_Cached( level );
	Controls.WaterPull:GetButton():SetText( m_WaterText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnTextureQualityPull( level )
	OptionsManager.SetTextureQuality_Cached( level );
	Controls.TextureQualityPull:GetButton():SetText( m_TextureQualityText[ level ] );
end


----------------------------------------------------------------
----------------------------------------------------------------
Controls.WResolutionPull:RegisterSelectionCallback(
function( index )
	local kResInfo = m_WindowResList[ index ];

	if kResInfo then
		OptionsManager.SetWindowResolution_Cached( kResInfo.x, kResInfo.y );
		Controls.WResolutionPull:GetButton():SetText( kResInfo.x .. "x" .. kResInfo.y );
	end

end)


----------------------------------------------------------------
----------------------------------------------------------------
Controls.FSResolutionPull:RegisterSelectionCallback(
function( index )
	local kResInfo = m_FullscreenResList[ index ];

	OptionsManager.SetResolution_Cached( index );
	Controls.FSResolutionPull:GetButton():SetText( kResInfo.Width .. "x" .. kResInfo.Height .. "   " .. kResInfo.Refresh .. " Hz" );

	OptionsManager.SetWindowResolution_Cached( kResInfo.Width, kResInfo.Height );
	Controls.WResolutionPull:GetButton():SetText( kResInfo.Width .. "x" .. kResInfo.Height );

end)

----------------------------------------------------------------
----------------------------------------------------------------
Controls.MSAAPull:RegisterSelectionCallback(
function( level )
	OptionsManager.SetAASamples_Cached( m_MSAAMap[level] );
	Controls.MSAAPull:GetButton():SetText( m_MSAAText[ level ] );
end)


----------------------------------------------------------------
-- Multiplayer Options Handlers
----------------------------------------------------------------
Controls.TurnNotifySteamInviteCheckbox:RegisterCheckHandler( OptionsManager.SetTurnNotifySteamInvite_Cached )
Controls.TurnNotifyEmailCheckbox:RegisterCheckHandler( OptionsManager.SetTurnNotifyEmail_Cached )
Controls.TurnNotifyEmailAddressEdit:RegisterCallback( OptionsManager.SetTurnNotifyEmailAddress_Cached )
Controls.TurnNotifySmtpEmailEdit:RegisterCallback( OptionsManager.SetTurnNotifySmtpEmailAddress_Cached )
Controls.TurnNotifySmtpHostEdit:RegisterCallback( OptionsManager.SetTurnNotifySmtpHost_Cached )
Controls.TurnNotifySmtpPortEdit:RegisterCallback( OptionsManager.SetTurnNotifySmtpPort_Cached )
Controls.TurnNotifySmtpUserEdit:RegisterCallback( OptionsManager.SetTurnNotifySmtpUsername_Cached )
Controls.LANNickNameEdit:RegisterCallback( OptionsManager.SetLANNickName_Cached )
Controls.TurnNotifySmtpTLS:RegisterCheckHandler( OptionsManager.SetTurnNotifySmtpTLS_Cached )

----------------------------------------------------------------
function ValidateSmtpPassword()
	if( Controls.TurnNotifySmtpPassEdit:GetText() and Controls.TurnNotifySmtpPassRetypeEdit:GetText() and
		Controls.TurnNotifySmtpPassEdit:GetText() == Controls.TurnNotifySmtpPassRetypeEdit:GetText() ) then
		-- password editboxes match.
		OptionsManager.SetTurnNotifySmtpPassword_Cached( Controls.TurnNotifySmtpPassEdit:GetText() );
		Controls.StmpPasswordMatchLabel:LocalizeAndSetText( "TXT_KEY_OPSCREEN_TURN_NOTIFY_SMTP_PASSWORDS_MATCH" )
		Controls.StmpPasswordMatchLabel:LocalizeAndSetToolTip( "TXT_KEY_OPSCREEN_TURN_NOTIFY_SMTP_PASSWORDS_MATCH_TT" )
		Controls.StmpPasswordMatchLabel:SetColorByName( "Green_Chat" );
	else
		-- password editboxes do not match.
		Controls.StmpPasswordMatchLabel:LocalizeAndSetText( "TXT_KEY_OPSCREEN_TURN_NOTIFY_SMTP_PASSWORDS_NOT_MATCH" )
		Controls.StmpPasswordMatchLabel:LocalizeAndSetToolTip( "TXT_KEY_OPSCREEN_TURN_NOTIFY_SMTP_PASSWORDS_NOT_MATCH_TT" )
		Controls.StmpPasswordMatchLabel:SetColorByName( "Magenta_Chat" );
	end
end
Controls.TurnNotifySmtpPassEdit:RegisterCallback( ValidateSmtpPassword );
Controls.TurnNotifySmtpPassRetypeEdit:RegisterCallback( ValidateSmtpPassword );

----------------------------------------------------------------
-- Pulldowns
----------------------------------------------------------------

function BuildSinglePulldown( pulldown, textTable )
	local controlTable;
	for i = 0, #textTable do
		controlTable = {};
		pulldown:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText( textTable[i] );
		controlTable.Button:SetVoid1( i );
	end
	pulldown:CalculateInternals();
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildLeaderQualityPulldown()

	local controlTable;

	local size = #m_LeaderText;
	if UI.IsDX9() then
		size = size-1;        -- disallow high leaders on DX9, across the board
	end

	for i = 0, size do

		controlTable = {};
		Controls.LeaderPull:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText( m_LeaderText[i] );
		controlTable.Button:SetVoid1( i );

		-- disallow medium leaders on certain low-end machines
		if i == 2 and not UI.AreMediumLeadersAllowed() then
			controlTable.Button:SetDisabled(true);
			controlTable.Button:SetAlpha(.3);
		end

	end

	Controls.LeaderPull:CalculateInternals();

end

----------------------------------------------------------------
----------------------------------------------------------------
function BuildMSAAPulldown()
	local controlTable;
	for i = 0, #m_MSAAText do
		controlTable = {};
		Controls.MSAAPull:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText( m_MSAAText[i] );
		controlTable.Button:SetVoid1( i );
		if not OptionsManager.IsAALevelSupported(m_MSAAMap[i]) then
			controlTable.Button:SetDisabled(true);
			controlTable.Button:SetAlpha(.3);
		end
	end
	Controls.MSAAPull:CalculateInternals();
end

----------------------------------------------------------------
----------------------------------------------------------------
function BuildWResPulldown()
	Controls.WResolutionPull:ClearEntries();
	m_maxX, m_maxY = OptionsManager.GetMaxResolution();

	for i, kResInfo in ipairs( m_WindowResList ) do
		if( kResInfo.x <= m_maxX and
			kResInfo.y <= m_maxY ) then

			local controlTable = {};
			Controls.WResolutionPull:BuildEntry( "InstanceOne", controlTable );

			controlTable.Button:SetText( kResInfo.x .. "x" .. kResInfo.y );
			controlTable.Button:SetVoid1( i );
		end
	end

	Controls.WResolutionPull:CalculateInternals();
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildFSResPulldown()

	Controls.FSResolutionPull:ClearEntries();
	local count = #m_FullscreenResList;

	for i = count, 0, -1 do
		local kResInfo = m_FullscreenResList[i];

			--[[
			print( "Testing Mode: " .. kResInfo.Width .. " "
						.. kResInfo.Height .. " "
						.. kResInfo.Adapter .. " "
						.. kResInfo.Display .. " "
						.. kResInfo.Scale .. " "
						.. kResInfo.Refresh );
			--]]

		if( kResInfo.Height >= 768 and
			kResInfo.Adapter == 0 ) then

			local controlTable = {};
			Controls.FSResolutionPull:BuildEntry( "InstanceOne", controlTable );

			controlTable.Button:SetText( kResInfo.Width .. "x" .. kResInfo.Height .. "   " .. kResInfo.Refresh .. " Hz" );
			controlTable.Button:SetVoid1( i );
		end
	end

	Controls.FSResolutionPull:CalculateInternals();
end


----------------------------------------------------------------
-- build the internal list of fullscreen modes
----------------------------------------------------------------
m_iResolutionCount = UIManager:GetResCount();
for i = 0, m_iResolutionCount - 1 do
	local width, height, refresh, scale, display, adapter = UIManager:GetResInfo( i );
	m_FullscreenResList[i] = {	Width = width,
					Height = height,
					Refresh = refresh,
					Display = display,
					Adapter = adapter };
end

function RefreshTutorialLevelOptions()
	local TutorialLevels = {};
	insert(TutorialLevels, Locale.Lookup("TXT_KEY_OPSCREEN_TUTORIAL_LOW"));
	insert(TutorialLevels, Locale.Lookup("TXT_KEY_OPSCREEN_TUTORIAL_MEDIUM"));

	local bExpansion1Active = ContentManager.IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType.GAMEPLAY);
	local bExpansion2Active = ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY);

	if bExpansion1Active or bExpansion2Active then
		insert(TutorialLevels, Locale.Lookup("TXT_KEY_OPSCREEN_TUTORIAL_NEW_TO_XP"));
	end

	if bExpansion2Active then
		insert(TutorialLevels, Locale.Lookup("TXT_KEY_OPSCREEN_TUTORIAL_NEW_TO_XP2"));
	end

	insert(TutorialLevels, Locale.Lookup("TXT_KEY_OPSCREEN_TUTORIAL_HIGH"));
	insert(TutorialLevels, Locale.Lookup("TXT_KEY_OPSCREEN_TUTORIAL_OFF"));

	m_TutorialLevelText = {};
	for i,v in ipairs(TutorialLevels) do
		m_TutorialLevelText[i - 1] = v;
	end

	Controls.TutorialPull:ClearEntries();
	BuildSinglePulldown(Controls.TutorialPull, m_TutorialLevelText);
end

----------------------------------------------------------------
-- add the machine's desktop resolution just in case they're
-- running something weird
----------------------------------------------------------------
local bFound
for _, kResInfo in ipairs( m_WindowResList ) do
	if( kResInfo.x == m_maxX and
		kResInfo.y == m_maxY ) then
		bFound = true;
	end
end
if not bFound then
	m_WindowResList[0] = { x=m_maxX, y=m_maxY };
end

RefreshTutorialLevelOptions()
do
-- Build Pulldowns
	BuildFSResPulldown();
	BuildWResPulldown();
	BuildMSAAPulldown();

	--BuildSinglePulldown( Controls.TutorialPull, m_TutorialLevelText );
	Controls.TutorialPull:RegisterSelectionCallback( OnTutorialPull );

	BuildSinglePulldown( Controls.OverlayPull, m_OverlayText );
	Controls.OverlayPull:RegisterSelectionCallback( OnOverlayPull );

	BuildSinglePulldown( Controls.ShadowPull, m_ShadowText );
	Controls.ShadowPull:RegisterSelectionCallback( OnShadowPull );

	BuildSinglePulldown( Controls.FOWPull, m_FOWText );
	Controls.FOWPull:RegisterSelectionCallback( OnFOWPull );

	BuildSinglePulldown( Controls.TerrainDetailPull, m_TerrainDetailText );
	Controls.TerrainDetailPull:RegisterSelectionCallback( OnTerrainDetailPull );

	BuildSinglePulldown( Controls.TerrainTessPull, m_TerrainTessText );
	Controls.TerrainTessPull:RegisterSelectionCallback( OnTerrainTessPull );

	BuildSinglePulldown( Controls.TerrainShadowPull, m_TerrainShadowText );
	Controls.TerrainShadowPull:RegisterSelectionCallback( OnTerrainShadowPull );

	BuildSinglePulldown( Controls.WaterPull, m_WaterText );
	Controls.WaterPull:RegisterSelectionCallback( OnWaterPull );

	BuildSinglePulldown( Controls.TextureQualityPull, m_TextureQualityText );
	Controls.TextureQualityPull:RegisterSelectionCallback( OnTextureQualityPull );


	----------------------------------------------------------------
	-- leader detail pull (special case)
	BuildLeaderQualityPulldown();
	Controls.LeaderPull:RegisterSelectionCallback( OnLeaderPull );
	----------------------------------------------------------------


	BuildSinglePulldown( Controls.BindMousePull, m_BindMouseText );
	Controls.BindMousePull:RegisterSelectionCallback( OnBindMousePull );

	local languageTable = {};
	for i,v in ipairs(g_Languages) do
		languageTable[i - 1] = v.DisplayName;
	end
	BuildSinglePulldown( Controls.LanguagePull, languageTable);
	Controls.LanguagePull:RegisterSelectionCallback( OnLanguagePull );


	local spokenLanguageTable = {};
	for i,v in ipairs(g_SpokenLanguages) do
		spokenLanguageTable[i - 1] = v.DisplayName;
	end

	BuildSinglePulldown( Controls.SpokenLanguagePull, spokenLanguageTable);
	Controls.SpokenLanguagePull:RegisterSelectionCallback( OnSpokenLanguagePull );
end
UpdateOptionsDisplay();

----------------------------------------------------------------
----------------------------------------------------------------
function OnDragSpeedSlider( fSpeed )
	local iSpeed = floor(fSpeed*20 + 2) / 10
	OptionsManager.SetDragSpeed_Cached( iSpeed )
	Controls.DragSpeedValue:LocalizeAndSetText( "TXT_KEY_DRAG_SPEED", iSpeed )
end
Controls.DragSpeedSlider:RegisterSliderCallback( OnDragSpeedSlider )
Controls.DragSpeedSlider:SetValue( OptionsManager.GetDragSpeed() / 2 )
Controls.DragSpeedValue:LocalizeAndSetText( "TXT_KEY_DRAG_SPEED", OptionsManager.GetDragSpeed() )


----------------------------------------------------------------
----------------------------------------------------------------
function OnPinchSpeedSlider( fSpeed )
	local iSpeed = floor(fSpeed*20 + 2) / 10
	OptionsManager.SetPinchSpeed_Cached( iSpeed )
	Controls.PinchSpeedValue:LocalizeAndSetText( "TXT_KEY_PINCH_SPEED", iSpeed )
end
Controls.PinchSpeedSlider:RegisterSliderCallback( OnPinchSpeedSlider )
Controls.PinchSpeedSlider:SetValue( OptionsManager.GetPinchSpeed() / 2 )
Controls.PinchSpeedValue:LocalizeAndSetText( "TXT_KEY_PINCH_SPEED", OptionsManager.GetPinchSpeed() )
