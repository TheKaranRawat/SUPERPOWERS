-- Demographics popup: optimized pass (based on bc1's version)
do

include "IconHookup"
local CivIconHookup = CivIconHookup

--==========================================================
-- Minor lua optimizations
--==========================================================
local math_min, math_max = math.min, math.max

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
local YIELD_FOOD = YieldTypes.YIELD_FOOD
local YIELD_PRODUCTION = YieldTypes.YIELD_PRODUCTION

local m_PopupInfo, m_ReplayContext
local m_IsShown = false -- guards turn-timer semaphore + event registration
local m_PercentTechs = 100 / math_max( 1, #GameInfo.Technologies )

--==========================================================
-- Data getters (defined once, no per-refresh closures)
--==========================================================
local function GetPopulation( p ) return p:GetTotalPopulation() end
local function GetFood( p ) return p:CalculateTotalYield( YIELD_FOOD ) end
local function GetProduction( p ) return p:CalculateTotalYield( YIELD_PRODUCTION ) end
local function GetGold( p ) return p:CalculateGrossGold() end
local function GetLand( p ) return p:GetNumPlots() end
local function GetMight( p ) return p:GetMilitaryMight() end
local function GetApproval( p )
	return math_min( 100, math_max( 0, 60 + p:GetExcessHappiness() * 3 ) )
end
local function GetLiteracy( p )
	local teamTechs = Teams[ p:GetTeam() ]:GetTeamTechs()
	if TECH_WRITING and not teamTechs:HasTech( TECH_WRITING ) then
		return 0
	end
	return teamTechs:GetNumTechsKnown() * m_PercentTechs
end

local m_Entries = {
	{ name = "TXT_KEY_DEMOGRAPHICS_POPULATION", tip = "TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE", get = GetPopulation, fmt = "#,###,###,###'[ICON_CITIZEN]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_FOOD",       tip = "TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE",       get = GetFood,       fmt = "#,###,###,###'[ICON_FOOD]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_PRODUCTION", tip = "TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE", get = GetProduction, fmt = "#,###,###,###'[ICON_PRODUCTION]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_GOLD",       tip = "TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE",       get = GetGold,       fmt = "#,###,###,###'[ICON_GOLD]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_LAND",                                                        get = GetLand,       fmt = "#,###,###,###" },
	{ name = "TXT_KEY_REPLAY_DATA_MILITARYMIGHT",                                                get = GetMight,      fmt = "#,###,###,###'[ICON_STRENGTH]'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_APPROVAL",                                                    get = GetApproval,   fmt = "#'%'" },
	{ name = "TXT_KEY_DEMOGRAPHICS_LITERACY",                                                    get = GetLiteracy,   fmt = "#'%'" },
}

for _, entry in ipairs( m_Entries ) do
	local instance = {}
	ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack )
	instance.Name:LocalizeAndSetText( entry.name )
	if entry.tip then
		instance.ValueTT:LocalizeAndSetToolTip( entry.tip )
		instance.BestTT:LocalizeAndSetToolTip( entry.tip )
		instance.AverageTT:LocalizeAndSetToolTip( entry.tip )
		instance.WorstTT:LocalizeAndSetToolTip( entry.tip )
	end
	entry.instance = instance
end
Controls.MainStack:CalculateSize()
Controls.MainStack:ReprocessAnchoring()
Controls.BigStack:ReprocessAnchoring()

--==========================================================
-- Refresh
--==========================================================
-- Reused tables: no garbage generated per refresh
local m_Players, m_IconIDs = {}, {}

-- Build the list of living major civs ONCE per refresh (was 8x) and
-- resolve "has the active player met them" ONCE per civ (was 2x per entry).
local function CollectPlayers( activePlayerID, activeTeam )
	local count = 0
	for i = 0, MAX_MAJOR_CIVS - 1 do -- was 0..MAX_MAJOR_CIVS (off by one)
		local player = Players[i]
		if player and player:IsAlive() and not player:IsMinorCiv() then
			count = count + 1
			m_Players[count] = player
			m_IconIDs[count] = ( i == activePlayerID or activeTeam:IsHasMet( player:GetTeam() ) ) and i or -1
		end
	end
	return count
end

local function RefreshEntry( entry, activePlayer, activeIconID, count )
	local get, fmt, instance = entry.get, entry.fmt, entry.instance
	local playerVal = get( activePlayer )
	local rank = 1
	local highest, highestIcon = playerVal, activeIconID
	local lowest, lowestIcon = playerVal, activeIconID
	local accum = 0

	for n = 1, count do
		local player = m_Players[n]
		local value = ( player == activePlayer ) and playerVal or get( player )
		accum = accum + value
		if value > playerVal then rank = rank + 1 end
		if value > highest then highest, highestIcon = value, m_IconIDs[n] end
		if value <= lowest then lowest, lowestIcon = value, m_IconIDs[n] end
	end

	-- avoid NaN if the active player is dead/observing and nobody is counted
	local average = count > 0 and accum / count or playerVal

	instance.Value:SetText( ToNumber( playerVal, fmt ) )
	CivIconHookup( highestIcon, 32, instance.BestIcon, instance.BestIconBG, instance.BestIconShadow, false, true )
	instance.Best:SetText( ToNumber( highest, fmt ) )
	instance.Average:SetText( ToNumber( average, fmt ) )
	CivIconHookup( lowestIcon, 32, instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow, false, true )
	instance.Worst:SetText( ToNumber( lowest, fmt ) ) -- was LocalizeAndSetText on a number string
	instance.Rank:SetText( ToNumber( rank, "#" ) )
end

local function RefreshScreen()
	local activePlayerID = GetActivePlayer()
	local activePlayer = Players[ activePlayerID ]
	if not activePlayer then return end
	local activeTeam = Teams[ activePlayer:GetTeam() ]

	local count = CollectPlayers( activePlayerID, activeTeam )
	for i = count + 1, #m_Players do -- drop stale refs from a previous, larger refresh
		m_Players[i], m_IconIDs[i] = nil, nil
	end

	for i = 1, #m_Entries do
		RefreshEntry( m_Entries[i], activePlayer, activePlayerID, count )
	end
	CivIconHookup( activePlayerID, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true )
end

--==========================================================
-- Show / hide
--==========================================================
ContextPtr:SetShowHideHandler( function( isHide, isInit )
	if isInit then return end
	if isHide then
		Events.SerialEventGameMessagePopupProcessed.CallImmediate( BUTTONPOPUP_DEMOGRAPHICS, 0 )
		if m_IsShown then -- balanced: exactly one dec per inc, one Remove per Add
			m_IsShown = false
			Events.NewGameTurn.Remove( RefreshScreen )
			UI.decTurnTimerSemaphore()
		end
		if m_ReplayContext then
			m_ReplayContext:SetHide( true )
		end
	else
		if not m_IsShown then
			m_IsShown = true
			UI.incTurnTimerSemaphore()
			Events.NewGameTurn.Add( RefreshScreen )
		end
		if m_PopupInfo then
			Events.SerialEventGameMessagePopupShown( m_PopupInfo )
		end
		RefreshScreen()
		if m_ReplayContext then
			m_ReplayContext:ChangeParent( ContextPtr )
			m_ReplayContext:SetHide( false )
		end
	end
end )

local function ClosePopup()
	UIManager:DequeuePopup( ContextPtr )
end

if ContextPtr:GetID() == "EndGameDemographics" then
	Controls.BGBlock:SetHide( true )
	Controls.InGameSet:SetHide( true )
else
	m_ReplayContext = ContextPtr:LookUpControl( "../EndGameMenu/EndGameReplay" )
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
	end )
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
-- Hotseat/MP: close when the active player changes so one player's data isn't shown to the next
Events.GameplaySetActivePlayer.Add( ClosePopup )
end