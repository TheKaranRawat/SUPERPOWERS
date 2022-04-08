-- Re-written by bc1 using Notepad++
do

include "IconHookup"
local CivIconHookup = CivIconHookup

--==========================================================
-- Minor lua optimizations
--==========================================================

local math = math

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
local YieldTypes = YieldTypes

local m_PopupInfo, m_ReplayContext
local m_PercentTechs = 100 / #GameInfo.Technologies

local function BuildEntry( name, tooltip )
	local instance = {}
	ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack )
	instance.Name:LocalizeAndSetText( name )
	instance.ValueTT:LocalizeAndSetToolTip( tooltip )
	instance.BestTT:LocalizeAndSetToolTip( tooltip )
	instance.AverageTT:LocalizeAndSetToolTip( tooltip )
	instance.WorstTT:LocalizeAndSetToolTip( tooltip )
	return instance
end

local m_Instances = {
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_POPULATION", "TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE" ),
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_FOOD", "TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE" ),
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_PRODUCTION", "TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE" ),
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_GOLD", "TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE" ),
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_LAND" ), --"TXT_KEY_DEMOGRAPHICS_LAND_MEASURE" )
	BuildEntry( "TXT_KEY_REPLAY_DATA_MILITARYMIGHT" ),
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_APPROVAL" ),
	BuildEntry( "TXT_KEY_DEMOGRAPHICS_LITERACY" ),
}
Controls.MainStack:CalculateSize()
Controls.MainStack:ReprocessAnchoring()
Controls.BigStack:ReprocessAnchoring()

local function SetIcon( player, otherPlayerID, ... )
	CivIconHookup( Teams[ player:GetTeam() ]:IsHasMet( Players[otherPlayerID]:GetTeam() ) and otherPlayerID or -1, ... )
end

local function RefreshEntry( n, activePlayer, activePlayerID, data, template )
	local playerVal = data(activePlayer)
	local rank = 1
	local highest = playerVal
	local highestID = activePlayerID
	local lowest = playerVal
	local lowestID = activePlayerID
	local accum = 0
	local count = 0
	local value, player
	for i = 0, MAX_MAJOR_CIVS do
		player = Players[i]
		if player:IsAlive() and not player:IsMinorCiv() then
			value = data(player)
			count = count + 1
			accum = accum + value
			if value > playerVal then
				rank = rank + 1
			end
			if value > highest then
				highest = value
				highestID = i
			end
			if value <= lowest then
				lowest = value
				lowestID = i
			end
	   end
	end

	local instance = m_Instances[n]
	instance.Value:SetText( ToNumber( playerVal, template ))
	SetIcon( activePlayer, highestID, 32, instance.BestIcon, instance.BestIconBG, instance.BestIconShadow, false, true )
	instance.Best:SetText( ToNumber( highest, template ) )
	instance.Average:SetText( ToNumber( accum / count, template ) )
	SetIcon( activePlayer, lowestID, 32, instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow, false, true )
	instance.Worst:LocalizeAndSetText( ToNumber( lowest, template ) )
	instance.Rank:SetText( ToNumber( rank, "#" ) )
end

local function CalculateGrossFood( player )
	return player:CalculateTotalYield(YieldTypes.YIELD_FOOD)
end

local function CalculateGrossProduction( player )
	return player:CalculateTotalYield(YieldTypes.YIELD_PRODUCTION)
end

local function CalculateHappiness( player )
	return math.min(100, math.max(0, 60 + player:GetExcessHappiness() * 3))
end

local function CalculateLitteracy(player)
	local teamTechs = Teams[ player:GetTeam() ]:GetTeamTechs()
	return ((not TECH_WRITING or teamTechs:HasTech( TECH_WRITING )) and teamTechs:GetNumTechsKnown() or 0)*m_PercentTechs
end

local function RefreshScreen()
	local activePlayerID = GetActivePlayer()
	local activePlayer = Players[ activePlayerID ]
	RefreshEntry( 1, activePlayer, activePlayerID, activePlayer.GetTotalPopulation, "#,###,###,###'[ICON_CITIZEN]'" )
	RefreshEntry( 2, activePlayer, activePlayerID, CalculateGrossFood, "#,###,###,###'[ICON_FOOD]'" )
	RefreshEntry( 3, activePlayer, activePlayerID, CalculateGrossProduction, "#,###,###,###'[ICON_PRODUCTION]'" )
	RefreshEntry( 4, activePlayer, activePlayerID, activePlayer.CalculateGrossGold, "#,###,###,###'[ICON_GOLD]'" )
	RefreshEntry( 5, activePlayer, activePlayerID, activePlayer.GetNumPlots, "#,###,###,###" )
	RefreshEntry( 6, activePlayer, activePlayerID, activePlayer.GetMilitaryMight, "#,###,###,###'[ICON_STRENGTH]'" )
--	RefreshEntry( 6, activePlayer, activePlayerID, function(activePlayer) return math.sqrt( activePlayer:GetMilitaryMight() ) * 2000 end, "#,###,###,###" )
	RefreshEntry( 7, activePlayer, activePlayerID, CalculateHappiness, "#'%'" )
	RefreshEntry( 8, activePlayer, activePlayerID, CalculateLitteracy, "#'%'" )
	CivIconHookup( activePlayerID, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true )
end

ContextPtr:SetShowHideHandler( function( isHide, isInit )
	if not isInit then
		if isHide then
			Events.SerialEventGameMessagePopupProcessed.CallImmediate(BUTTONPOPUP_DEMOGRAPHICS, 0)
			Events.NewGameTurn.Remove( RefreshScreen )
			UI.decTurnTimerSemaphore()
			if m_ReplayContext then
				m_ReplayContext:SetHide( true )
			end
		else
			UI.incTurnTimerSemaphore()
			if m_PopupInfo then
				Events.SerialEventGameMessagePopupShown( m_PopupInfo )
			end
			RefreshScreen()
			Events.NewGameTurn.Add( RefreshScreen )
			if m_ReplayContext then
				m_ReplayContext:ChangeParent( ContextPtr )
				m_ReplayContext:SetHide( false )
			end
		end
	end
end)

local function ClosePopup()
	UIManager:DequeuePopup( ContextPtr )
end

if ContextPtr:GetID() == "EndGameDemographics" then
	Controls.BGBlock:SetHide( true )
	Controls.InGameSet:SetHide( true )
else
	m_ReplayContext = ContextPtr:LookUpControl( "../EndGameMenu/EndGameReplay" )
	-- Key Down Processing
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				ClosePopup()
			end
			return true
		end
	end)
	AddSerialEventGameMessagePopup( function( popupInfo )
		if popupInfo.Type == BUTTONPOPUP_DEMOGRAPHICS then
			m_PopupInfo = popupInfo
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
Events.GameplaySetActivePlayer.Add( ClosePopup )
end