-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
print("IGE_PlayersPanel");
IGE = {};

local majorPlayerItemManager = CreateInstanceManager("PlayerInstance", "Button", Controls.MajorPlayersList);
local minorPlayerItemManager = CreateInstanceManager("PlayerInstance", "Button", Controls.MinorPlayersList);

local data = {};
local actions = nil;
local isVisible = false;
local currentActionID = 1;


--===============================================================================================
-- EVENTS
--===============================================================================================
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	SetPlayersData(data, {});

	if not IGE_HasGodsAndKings then
		Controls.FoundPantheonButton:SetHide(true);
		Controls.FoundReligionButton:SetHide(true);
		Controls.FaithContainer:SetHide(true);
		Controls.FreeTechButton:SetOffsetVal(0, 20);
	end

	Resize(Controls.Container);
	Resize(Controls.ScrollPanel);

	actions =
	{
		{ text = L("TXT_KEY_IGE_MEET"),						filter = CanMeet,			handler = Meet,				none=L("TXT_KEY_IGE_MEET_NONE") },
		{ text = L("TXT_KEY_IGE_FORM_TEAM"),				filter = CanFormTeam,		handler = FormTeam,			none=L("TXT_KEY_IGE_FORM_TEAM_NONE") },
		{ text = L("TXT_KEY_IGE_MAKE_PEACE"),				filter = CanMakePeace,		handler = MakePeace,		none=L("TXT_KEY_IGE_MAKE_PEACE_NONE") },
		{ text = L("TXT_KEY_IGE_SIGN_DOF") ,				filter = CanMakeDoF,		handler = MakeDoF,			none=L("TXT_KEY_IGE_SIGN_DOF_NONE") },
		{ text = L("TXT_KEY_IGE_MAX_MINOR_INFLUENCE"),		filter = CanAllyMinor,		handler = AllyMinor,		none=L("TXT_KEY_IGE_MAX_MINOR_INFLUENCE_NONE")},
		{ text = L("TXT_KEY_IGE_FLAG_STATE_LIBERATED"),		filter = CanFlagLiberated,	handler = FlagLiberated,	none=L("TXT_KEY_IGE_FLAG_STATE_LIBERATED_NONE") },
		{ text = L("TXT_KEY_IGE_SET_EMBARGO"),				filter = CanSetEmbargo,		handler = SetEmbargo,		none=L("TXT_KEY_IGE_TWO_SIDES_NONE") },
		{ text = L("TXT_KEY_IGE_DENOUNCE"),					filter = CanDenounce,		handler = Denounce,			none=L("TXT_KEY_IGE_DENOUNCE_NONE")},
		{ text = L("TXT_KEY_IGE_DENOUNCED_BY"),				filter = CanBeDenounced,	handler = MakeDenounced,	none=L("TXT_KEY_IGE_DENOUNCED_BY_NONE") },
		{ text = L("TXT_KEY_IGE_DECLARE_WAR"),				filter = CanDeclareWar,		handler = DeclareWar,		none=L("TXT_KEY_IGE_TWO_SIDES_NONE") },
		{ text = L("TXT_KEY_IGE_DECLARE_WAR_BY"),			filter = CanBeDeclaredWar,	handler = MakeDeclaredWar,	none=L("TXT_KEY_IGE_TWO_SIDES_NONE") },
	};

    for i, v in ipairs(actions) do
        local instance = {};
        Controls.PullDown:BuildEntry("InstanceOne", instance);
        instance.Button:SetText(v.text);
        instance.Button:SetVoid1(i);
    end
    Controls.PullDown:CalculateInternals();

	LuaEvents.IGE_RegisterTab("PLAYERS",  L("TXT_KEY_IGE_PLAYERS_PANEL"), 3, "change",  "")
end
LuaEvents.IGE_Initialize.Add(OnInitialize)

-------------------------------------------------------------------------------------------------
function OnSelectedPanel(ID)
	isVisible = (ID == "PLAYERS");
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel);

-------------------------------------------------------------------------------------------------
function OnPullDownSelectionChanged(ID)
	currentActionID = ID;
	OnUpdate();
end
Controls.PullDown:RegisterSelectionCallback(OnPullDownSelectionChanged);

-------------------------------------------------------------------------------------------------
UpdateGold = HookNumericBox("Gold", 
	function() return Players[IGE.currentPlayerID]:GetGold() end, 
	function(amount) Players[IGE.currentPlayerID]:SetGold(amount) end, 
	0, nil, 100);

UpdateCulture = HookNumericBox("Culture", 
	function() return Players[IGE.currentPlayerID]:GetJONSCulture() end, 
	function(amount) Players[IGE.currentPlayerID]:SetJONSCulture(amount) end, 
	0, nil, 100);

if IGE_HasGodsAndKings then
	UpdateFaith = HookNumericBox("Faith", 
		function() return Players[IGE.currentPlayerID]:GetFaith() end, 
		function(amount) Players[IGE.currentPlayerID]:SetFaith(amount) end, 
		0, nil, 100);
end

--===============================================================================================
-- UPDATE
--===============================================================================================
function UpdatePlayers()
	local sourceID = IGE.currentPlayerID;

	local anyMinor = false;
	local anyMajor = false;
	local action = actions[currentActionID];
	for i, v in ipairs(data.allPlayers) do
		if v.ID ~= sourceID then
			v.visible, v.enabled, v.help = action.filter(sourceID, v.ID);

			if v.isCityState then
				anyMinor = anyMinor or v.visible;
			else
				anyMajor = anyMajor or v.visible;
			end
		else
			v.visible = false;
		end
	end

	Controls.NoPlayerLabel:SetText("[COLOR_POSITIVE_TEXT]"..action.none.."[ENDCOLOR]");
	Controls.NoPlayerLabel:SetHide(anyMinor or anyMajor);
	Controls.MajorPlayersList:SetHide(not anyMajor);
	Controls.MinorPlayersList:SetHide(not anyMinor);

	table.sort(data.majorPlayers, DefaultSort);
	table.sort(data.minorPlayers, DefaultSort);

	local handler = action.handler
	UpdateList(data.majorPlayers, majorPlayerItemManager, function(v) PlayerClickHandler(handler, sourceID, v.ID) end);
	UpdateList(data.minorPlayers, minorPlayerItemManager, function(v) PlayerClickHandler(handler, sourceID, v.ID) end);
end

-------------------------------------------------------------------------------------------------
function OnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	LuaEvents.IGE_SetMouseMode(IGE_MODE_NONE);

	-- Update controls
	local pPlayer = IGE.currentPlayer;
	UpdateGold(pPlayer:GetGold());
	UpdateCulture(pPlayer:GetJONSCulture());
	if IGE_HasGodsAndKings then
		UpdateFaith(pPlayer:GetFaith());

		-- Count beliefs to detect religion enhancement
		local beliefs = 0;
		local religionID = pPlayer:GetReligionCreatedByPlayer();
		if pPlayer:HasCreatedReligion() then
			for i,v in ipairs(Game.GetBeliefsInReligion(religionID)) do
				beliefs = beliefs + 1;
			end
		end
		local hasEnhancedReligion = (beliefs >= 5);

		local stage = 0;
		if (hasEnhancedReligion) then stage = 3;
		elseif (pPlayer:HasCreatedReligion()) then stage = 2;
		elseif (pPlayer:HasCreatedPantheon()) then stage = 1;
		end

		Controls.EnhanceReligionButton:SetDisabled(stage ~= 2);
		Controls.EnhanceReligionButton:SetHide(stage < 2);

		Controls.FoundReligionButton:SetDisabled((stage ~= 1) or (Game.GetNumReligionsStillToFound() == 0));
		Controls.FoundReligionButton:SetHide(stage ~= 1);

		Controls.FoundPantheonButton:SetDisabled(stage ~= 0);
		Controls.FoundPantheonButton:SetHide(stage ~= 0);
	end
	Controls.PullDown:GetButton():SetText(actions[currentActionID].text);
	UpdatePlayers();

	-- Resize
	Controls.PlayersStack:CalculateSize();
	Controls.PlayersStack:ReprocessAnchoring();
	Controls.ActionsStack:CalculateSize();
	Controls.ActionsStack:ReprocessAnchoring();
	Controls.Stack:CalculateSize();
	Controls.Stack:ReprocessAnchoring();

    Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 36);
end
LuaEvents.IGE_Update.Add(OnUpdate);



--===============================================================================================
-- DIPLOMATIC HANDLERS
--===============================================================================================
function PlayerClickHandler(handler, sourceID, targetID)
	handler(sourceID, targetID);
	OnUpdate();
end

function AllClick()
	local handler = actions[currentActionID].handler;
	for i, v in ipairs(data.allPlayers) do
		if v.visible and v.enabled then
			handler(IGE.currentPlayerID, v.ID);
		end
	end
	OnUpdate();
end
Controls.AllButton:RegisterCallback(Mouse.eLClick, AllClick);

function NotifyDiplo(sourceID, targetID, type, summaryTexKey, detailsTxtKey)
	Players[sourceID]:AddNotification(type, 
		L("TXT_KEY_NOTIFICATION_CITY_WLTKD", Players[targetID]:GetCivilizationDescription()),
		L(summaryTexKey, Players[targetID]:GetCivilizationDescription()), nil, nil, targetID);
end

-------------------------------------------------------------------------------------------------
function CanMeet(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false ;
	else
		local visible = not GetTeam(sourceID):IsHasMet(GetTeamID(targetID));
		return visible, true;
	end
end

function CanFormTeam(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif GetTeamID(sourceID) == GetTeamID(targetID) then
		return true, false, L("TXT_KEY_IGE_ALREADY_IN_TEAM_ERROR") ;
	else
		return true, true;
	end
end

function CanMakePeace(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif not GetTeam(sourceID):IsAtWar(GetTeamID(targetID)) then
		return false;
	else
		return true, true;
	end
end

function CanMakeDoF(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[targetID]:IsMinorCiv() then 
		return false;
	elseif Players[sourceID]:IsDoF(targetID) then
		return true, false, L("TXT_KEY_IGE_ALREADY_UNDER_DOF_ERROR");
	else
		return true, true;
	end
end

function CanAllyMinor(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[sourceID]:IsMinorCiv() or not Players[targetID]:IsMinorCiv() then
		return false;
	elseif Players[targetID]:GetMinorCivFriendshipWithMajor(sourceID) >= GameDefines.FRIENDSHIP_THRESHOLD_MAX then
		return true, false, L("TXT_KEY_IGE_MAX_MINOR_INFLUENCE_ERROR");
	else
		return true, true;
	end
end

function CanDeclareWar(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif GetTeamID(sourceID) == GetTeamID(targetID) then
		return true, false, L("TXT_KEY_IGE_SAME_TEAM_ERROR");
	elseif GetTeam(sourceID):IsAtWar(GetTeamID(targetID)) then
		return true, false, L("TXT_KEY_IGE_ALREADY_AT_WAR_ERROR");
	else
		return true, true;
	end
end

function CanBeDeclaredWar(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	else
		return CanDeclareWar(targetID, sourceID);
	end
end

function CanDenounce(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[sourceID]:IsDenouncedPlayer(targetID) then
		return true, false, L("TXT_KEY_IGE_ALREADY_DENOUNCED_ERROR");
	else
		return true, true;
	end
end

function CanBeDenounced(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[targetID]:IsDenouncedPlayer(sourceID) then
		return true, false, L("TXT_KEY_IGE_ALREADY_DENOUNCED_BY_ERROR");
	else
		return true, true;
	end
end

function CanFlagLiberated(sourceID, targetID)
	if not Players[targetID]:IsMinorCiv() then
		return false;
	else
		return true, true;
	end
end

function CanSetEmbargo(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif GetTeamID(sourceID) == GetTeamID(targetID) then
		return true, false, L("TXT_KEY_IGE_SAME_TEAM_ERROR");
	elseif GetTeam(sourceID):IsAtWar(GetTeamID(targetID)) then
		return true, false, L("TXT_KEY_IGE_ALREADY_AT_WAR_ERROR");
	else
		return true, true;
	end
end

-------------------------------------------------------------------------------------------------
function Meet(sourceID, targetID)
	GetTeam(sourceID):Meet(GetTeamID(targetID), false);
end

function MakePeace(sourceID, targetID)
	GetTeam(sourceID):MakePeace(GetTeamID(targetID));
end

function FormTeam(sourceID, targetID)
	GetTeam(sourceID):AddTeam(GetTeamID(targetID));
	NotifyDiplo(sourceID, targetID, NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER, 
		L("TXT_KEY_IGE_NOTIFY_ALLIANCE_SHORT"),L("TXT_KEY_IGE_NOTIFY_ALLIANCE_LONG") );
end

function MakeDoF(sourceID, targetID)
	Players[sourceID]:DoForceDoF(targetID);
	NotifyDiplo(sourceID, targetID, NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER, 
		L("TXT_KEY_IGE_NOTIFY_DOF_SHORT"), L("TXT_KEY_IGE_NOTIFY_DOF_LONG"));
end

function AllyMinor(sourceID, targetID)
	local offset = GameDefines.FRIENDSHIP_THRESHOLD_MAX - Players[targetID]:GetMinorCivFriendshipWithMajor(sourceID);
	if offset > 0 then
		Players[targetID]:ChangeMinorCivFriendshipWithMajor(sourceID, offset);
	end
end

function DeclareWar(sourceID, targetID)
	GetTeam(sourceID):DeclareWar(GetTeamID(targetID));
end

function MakeDeclaredWar(sourceID, targetID)
	DeclareWar(targetID, sourceID);
end

function Denounce(sourceID, targetID)
	Players[sourceID]:DoForceDenounce(targetID);
end

function MakeDenounced(sourceID, targetID)
	Denounce(targetID, sourceID);
end

function SetEmbargo(sourceID, targetID)
	Players[sourceID]:StopTradingWithTeam(GetTeamID(targetID));
	NotifyDiplo(sourceID, targetID, NotificationTypes.NOTIFICATION_WAR_ACTIVE_PLAYER, L("TXT_KEY_IGE_NOTIFY_EMBARGO_SHORT"),L("TXT_KEY_IGE_NOTIFY_EMBARGO_LONG") );
end

function FlagLiberated(sourceID, targetID)
	Players[targetID]:DoMinorLiberationByMajor(sourceID);
end


--===============================================================================================
-- REGULAR HANDLERS
--===============================================================================================
local function TriggerGoldenAge(turns)
	local pPlayer = IGE.currentPlayer;
	local currentTurns = pPlayer:GetGoldenAgeTurns();
	pPlayer:ChangeGoldenAgeTurns(turns - currentTurns);
end

-------------------------------------------------------------------------------------------------
function OnGoldenAge10Click()
	TriggerGoldenAge(10);
end
Controls.GoldenAge10Button:RegisterCallback(Mouse.eLClick, OnGoldenAge10Click);

-------------------------------------------------------------------------------------------------
function OnGoldenAge250Click()
	TriggerGoldenAge(250);
end
Controls.GoldenAge250Button:RegisterCallback(Mouse.eLClick, OnGoldenAge250Click);

-------------------------------------------------------------------------------------------------
function OnTakeSeatClick()
	LuaEvents.IGE_ForceQuit(true);
end
Controls.TakeSeatButton:RegisterCallback(Mouse.eLClick, OnTakeSeatClick);

-------------------------------------------------------------------------------------------------
function OnUnexploreMapClick()
	LuaEvents.IGE_ForceRevealMap(false);
end
Controls.UnexploreMapButton:RegisterCallback(Mouse.eLClick, OnUnexploreMapClick);

-------------------------------------------------------------------------------------------------
function OnExploreMapClick()
	LuaEvents.IGE_ForceRevealMap(true, false);
end
Controls.ExploreMapButton:RegisterCallback(Mouse.eLClick, OnExploreMapClick);

-------------------------------------------------------------------------------------------------
function OnRevealMapClick()
	LuaEvents.IGE_ForceRevealMap(true, true);
end
Controls.RevealMapButton:RegisterCallback(Mouse.eLClick, OnRevealMapClick);

-------------------------------------------------------------------------------------------------
function OnKillUnitsClick()
	IGE.currentPlayer:KillUnits();
end
Controls.KillUnitsButton:RegisterCallback(Mouse.eLClick, OnKillUnitsClick);

-------------------------------------------------------------------------------------------------
function OnKillClick()
	local i = 0;
	while i == IGE.currentPlayerID or Players[i] == nil or not Players[i]:IsAlive() do
		i = i + 1;
	end

	local pPlayer = IGE.currentPlayer;
	LuaEvents.IGE_SelectPlayer(i);
	pPlayer:KillUnits();
	pPlayer:KillCities();
end
Controls.KillButton:RegisterCallback(Mouse.eLClick, OnKillClick);

-------------------------------------------------------------------------------------------------
function OnFreeTechClick()
	IGE.currentPlayer:SetNumFreeTechs(IGE.currentPlayer:GetNumFreeTechs() + 1);
	IGE.currentPlayer:AddNotification(NotificationTypes.NOTIFICATION_FREE_TECH, L("TXT_KEY_IGE_FREE_TECH_BUTTON"),L("TXT_KEY_IGE_FREE_TECH_BUTTON_HELP") );
	OnUpdate();
end
Controls.FreeTechButton:RegisterCallback(Mouse.eLClick, OnFreeTechClick);


-------------------------------------------------------------------------------------------------
function OnFreePolicyClick()
	IGE.currentPlayer:SetNumFreePolicies(IGE.currentPlayer:GetNumFreePolicies() + 1);
	IGE.currentPlayer:AddNotification(NotificationTypes.NOTIFICATION_FREE_POLICY, L("TXT_KEY_IGE_FREE_POLICY_BUTTON"), L("TXT_KEY_IGE_FREE_POLICY_BUTTON_HELP"));
	OnUpdate();
end
Controls.FreePolicyButton:RegisterCallback(Mouse.eLClick, OnFreePolicyClick);

-------------------------------------------------------------------------------------------------
function OnFoundPantheonClick()
	LuaEvents.IGE_ChoosePantheonPopup(IGE.currentPlayer);
end
Controls.FoundPantheonButton:RegisterCallback(Mouse.eLClick, OnFoundPantheonClick);

-------------------------------------------------------------------------------------------------
function OnFoundReligionClick()
	local capital = IGE.currentPlayer:GetCapitalCity();
	LuaEvents.IGE_ChooseReligionPopup(IGE.currentPlayer, capital, true);
end
Controls.FoundReligionButton:RegisterCallback(Mouse.eLClick, OnFoundReligionClick);

-------------------------------------------------------------------------------------------------
function OnEnhanceReligionClick()
	local capital = IGE.currentPlayer:GetCapitalCity();
	LuaEvents.IGE_ChooseReligionPopup(IGE.currentPlayer, capital, false);
end
Controls.EnhanceReligionButton:RegisterCallback(Mouse.eLClick, OnEnhanceReligionClick);

-------------------------------------------------------------------------------------------------
function OnNotificationAdded( Id, type, toolTip, strSummary, iGameValue, iExtraGameData )
	OnUpdate();
end
Events.NotificationAdded.Add(OnNotificationAdded);
