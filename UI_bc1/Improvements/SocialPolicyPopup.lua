--==========================================================
-- SocialPolicy Chooser Popup
-- Modified by bc1 from 1.0.3.276 code using Notepad++
--==========================================================

Events.SequenceGameInitComplete.Add(function()

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfoPolicies = GameInfoCache.Policies
local GameInfoPolicyBranchTypes = GameInfoCache.PolicyBranchTypes
local GameInfoEras = GameInfoCache.Eras
local GameInfoPrereqPolicies = GameInfoCache.Policy_PrereqPolicies

include "IconHookup"
local IconHookup = IconHookup
local CivIconHookup = CivIconHookup

--==========================================================
-- Minor lua optimizations
--==========================================================

local ipairs = ipairs
local abs = math.abs
local ceil = math.ceil
local huge = math.huge
local min = math.min
local print = print
local tostring = tostring
local insert = table.insert
local concat = table.concat

local ButtonPopupTypes = ButtonPopupTypes
local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local GetActivePlayer = Game.GetActivePlayer
local IsOption = Game.IsOption
local GameDefines = GameDefines
local GameInfoTypes = GameInfoTypes
local GameOptionTypes = GameOptionTypes
local KeyEvents = KeyEvents
local Keys = Keys
local ToUpper = Locale.ToUpper
local L = Locale.ConvertTextKey
local eLClick = Mouse.eLClick
local eRClick = Mouse.eRClick
local Network = Network
local OptionsManager = OptionsManager
local Players = Players
local PopupPriority = PopupPriority
local PublicOpinionTypes = PublicOpinionTypes
local Teams = Teams
local incTurnTimerSemaphore = UI.incTurnTimerSemaphore
local decTurnTimerSemaphore = UI.decTurnTimerSemaphore
local UIManager = UIManager

local bnw_mode = Game.GetActiveLeague ~= nil

local g_PolicyBranchPanels = {
	POLICY_BRANCH_LIBERTY = Controls.LibertyPanel,
	POLICY_BRANCH_TRADITION = Controls.TraditionPanel,
	POLICY_BRANCH_HONOR = Controls.HonorPanel,
	POLICY_BRANCH_PIETY = Controls.PietyPanel,
	POLICY_BRANCH_AESTHETICS = Controls.AestheticsPanel,
	POLICY_BRANCH_PATRONAGE = Controls.PatronagePanel,
	POLICY_BRANCH_COMMERCE = Controls.CommercePanel,
	POLICY_BRANCH_EXPLORATION = Controls.ExplorationPanel,
	POLICY_BRANCH_RATIONALISM = Controls.RationalismPanel,
	POLICY_BRANCH_FREEDOM = Controls.FreedomPanel,
	POLICY_BRANCH_ORDER = Controls.OrderPanel,
	POLICY_BRANCH_AUTOCRACY = Controls.AutocracyPanel,
}
local g_PopupInfo
local g_FullColor = {x = 1, y = 1, z = 1, w = 1}
local g_FadeColor = {x = 1, y = 1, z = 1, w = 0}
local g_FadeColorRV = {x = 1, y = 1, z = 1, w = 0.2}
local g_PolicyButtons = {}

local TabSelect
local g_Tabs = {
	SocialPolicies = {
		Button = Controls.TabButtonSocialPolicies,
		Panel = Controls.SocialPolicyPane,
		SelectHighlight = Controls.TabButtonSocialPoliciesHL,
	},
	Ideologies = {
		Button = Controls.TabButtonIdeologies,
		Panel = Controls.IdeologyPane,
		SelectHighlight = Controls.TabButtonIdeologiesHL,
	},
}

local g_IdeologyBackgrounds = {
	POLICY_BRANCH_AUTOCRACY = "SocialPoliciesAutocracy.dds",
	POLICY_BRANCH_FREEDOM = "SocialPoliciesFreedom.dds",
	POLICY_BRANCH_ORDER = "SocialPoliciesOrder.dds",
}

local PolicyTooltip = LuaEvents.PolicyTooltip.Call
local PolicyBranchTooltip = LuaEvents.PolicyBranchTooltip.Call
local TenetToolTip = LuaEvents.TenetToolTip.Call
local ShowTextToolTipAndPicture = LuaEvents.ShowTextToolTipAndPicture.Call

local function SetToolTipCallback( control, f )
	control:SetToolTipCallback( function( control )
		control:SetToolTipCallback( f )
		control:SetToolTipType( "EUI_ItemTooltip" )
	end)
end

local SearchForPediaEntry = Events.SearchForPediaEntry.Call

local function OnClose()
	UIManager:DequeuePopup( ContextPtr );
end
Controls.CloseButton:RegisterCallback( eLClick, OnClose );

-------------------------------------------------
-- Policy Selection
local function PolicySelect( policyID )

	--print("Clicked on Policy: " .. tostring(policyID));
	local policyInfo = GameInfoPolicies[ policyID ]
	local player = Players[GetActivePlayer()];
	if policyInfo and player then

		local bHasPolicy = player:HasPolicy(policyID);
		local bCanAdoptPolicy = player:CanAdoptPolicy(policyID);

		--print("bHasPolicy: " .. tostring(bHasPolicy));
		--print("bCanAdoptPolicy: " .. tostring(bCanAdoptPolicy));
		--print("Policy Blocked: " .. tostring(player:IsPolicyBlocked(policyID)));

		local bPolicyBlocked = false;

		-- If we can get this, OR we already have it, see if we can unblock it first
		if bHasPolicy or bCanAdoptPolicy then
			-- Policy blocked off right now? If so, try to activate
			if player:IsPolicyBlocked(policyID) then
				bPolicyBlocked = true;
				Events.SerialEventGameMessagePopup{ Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_POLICY_BRANCH_SWITCH, Data1 = GameInfoTypes[ policyInfo.PolicyBranchType ] }
			end
		end

		-- Can adopt Policy right now - don't try this if we're going to unblock the Policy instead
		if bCanAdoptPolicy and not bPolicyBlocked then
			Controls.Yes:SetVoids( policyID, 1 )
			Controls.PolicyConfirm:SetHide(false);
			Controls.BGBlock:SetHide(true);
		end
	end
end

local function PolicyPedia( policyID )
	SearchForPediaEntry( GameInfoPolicies[ policyID ]._Name )
end

-------------------------------------------------
-- Policy Branch Selection
local function PolicyBranchSelect( policyBranchID )

	--print("Clicked on PolicyBranch:", policyBranchID)

	local player = Players[GetActivePlayer()]
	if player and GameInfoPolicyBranchTypes[ policyBranchID ] then

		local bHasPolicyBranch = player:IsPolicyBranchUnlocked(policyBranchID);
		local bCanAdoptPolicyBranch = player:CanUnlockPolicyBranch(policyBranchID);

		--print("bHasPolicyBranch:", bHasPolicyBranch)
		--print("bCanAdoptPolicyBranch:", bCanAdoptPolicyBranch)
		--print("PolicyBranch Blocked:", player:IsPolicyBranchBlocked(policyBranchID))

		local bUnblockingPolicyBranch = false;

		-- If we can get this, OR we already have it, see if we can unblock it first
		if bHasPolicyBranch or bCanAdoptPolicyBranch then

			-- Policy Branch blocked off right now? If so, try to activate
			if player:IsPolicyBranchBlocked(policyBranchID) then
				bUnblockingPolicyBranch = true;
				Events.SerialEventGameMessagePopup{ Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_POLICY_BRANCH_SWITCH, Data1 = policyBranchID }
			end
		end

		-- Can adopt Policy Branch right now - don't try this if we're going to unblock the Policy Branch instead
		if bCanAdoptPolicyBranch and not bUnblockingPolicyBranch then
			Controls.Yes:SetVoids( policyBranchID, 0 )
			Controls.PolicyConfirm:SetHide(false);
			Controls.BGBlock:SetHide(true);
		end
	end
end

local function PolicyBranchPedia( policyBranchID )
	SearchForPediaEntry( GameInfoPolicyBranchTypes[ policyBranchID ]._Name )
end

-------------------------------------------------
-- Ideology Selection
if bnw_mode then
	include "StackInstanceManager"
	include "CommonBehaviors"

	local g_TenetInstanceManager = StackInstanceManager( "TenetChoice", "TenetButton", Controls.TenetStack )

	SetToolTipCallback( Controls.TenetConfirmYes, TenetToolTip )

	Controls.SwitchIdeologyButton:RegisterCallback( eLClick, function()
		local player = Players[GetActivePlayer()]
		local iAnarchyTurns = GameDefines["SWITCH_POLICY_BRANCHES_ANARCHY_TURNS"];
		local eCurrentIdeology = player:GetLateGamePolicyTree();
		local iCurrentIdeologyTenets = player:GetNumPoliciesInBranch(eCurrentIdeology);
		local iPreferredIdeologyTenets = iCurrentIdeologyTenets - GameDefines["SWITCH_POLICY_BRANCHES_TENETS_LOST"];
		if iPreferredIdeologyTenets < 0 then
			iPreferredIdeologyTenets = 0
		end
		local iUnhappiness = player:GetPublicOpinionUnhappiness();
		local strCurrentIdeology = GameInfoPolicyBranchTypes[eCurrentIdeology].Description;
		local ePreferredIdeology = player:GetPublicOpinionPreferredIdeology();
		local strPreferredIdeology = tostring((GameInfoPolicyBranchTypes[ePreferredIdeology] or {}).Description);
		Controls.LabelConfirmChangeIdeology:LocalizeAndSetText("TXT_KEY_POLICYSCREEN_CONFIRM_CHANGE_IDEOLOGY", iAnarchyTurns, iCurrentIdeologyTenets, strCurrentIdeology, iPreferredIdeologyTenets, strPreferredIdeology, iUnhappiness);
		Controls.ChangeIdeologyConfirm:SetHide(false);
	end)

	local function ChooseTenet( tenetID, tenetLevel )
		local tenet = GameInfoPolicies[ tenetID ]
		if tenet then
			Controls.TenetConfirmYes:SetVoids( tenetID, tenetLevel )
			Controls.LabelConfirmTenet:LocalizeAndSetText( "TXT_KEY_POLICYSCREEN_CONFIRM_TENET", tenet.Description )
			Controls.TenetConfirm:SetHide( false )
		end
	end

	function TenetSelect( tenetID, tenetLevel )
		local player = Players[GetActivePlayer()];
		if player then
			g_TenetInstanceManager:ResetInstances();
			for _,tenetID in ipairs(player:GetAvailableTenets(tenetLevel)) do
				local tenet = GameInfoPolicies[ tenetID ]
				if tenet then
					local instance = g_TenetInstanceManager:GetInstance();
					instance.TenetLabel:LocalizeAndSetText( tenet.Help or tenet.Description )
					local newHeight = instance.TenetLabel:GetSizeY() + 30;
					instance.TenetButton:SetSizeY( newHeight );
					instance.Box:SetSizeY( newHeight );
					instance.TenetButton:ReprocessAnchoring();
					instance.TenetButton:RegisterCallback( eLClick, ChooseTenet )
					instance.TenetButton:SetVoids( tenetID, tenetLevel )
				end
			end
			Controls.ChooseTenet:SetHide(false);
			Controls.BGBlock:SetHide(true);
		end
	end

	Controls.TenetCancelButton:RegisterCallback( eLClick, function()
		Controls.ChooseTenet:SetHide(true)
		Controls.BGBlock:SetHide(false)
	end)

	Controls.TenetConfirmYes:RegisterCallback( eLClick, function( tenetID )
		Controls.TenetConfirm:SetHide(true)
		Controls.ChooseTenet:SetHide(true)
		Controls.BGBlock:SetHide(false)
		if GameInfoPolicies[ tenetID ] then
			Network.SendUpdatePolicies( tenetID, true, true )
			Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY")
		end
	end)

	Controls.TenetConfirmNo:RegisterCallback( eLClick, function()
		Controls.TenetConfirm:SetHide(true)
		Controls.BGBlock:SetHide(false)
	end)

	Controls.ChangeIdeologyConfirmYes:RegisterCallback( eLClick, function()
		local player = Players[GetActivePlayer()]
		local ePreferredIdeology = player:GetPublicOpinionPreferredIdeology()
		Controls.ChangeIdeologyConfirm:SetHide(true)
		Network.SendChangeIdeology()
		if ePreferredIdeology < 0 then
			Events.SerialEventGameMessagePopup{ Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSE_IDEOLOGY }
			OnClose()
		end
		Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY")
	end)

	Controls.ChangeIdeologyConfirmNo:RegisterCallback( eLClick, function()
		Controls.ChangeIdeologyConfirm:SetHide(true)
	end)

	SetToolTipCallback( Controls.PublicOpinion, function()
		return ShowTextToolTipAndPicture( Players[GetActivePlayer()]:GetPublicOpinionTooltip() )
	end)

	SetToolTipCallback( Controls.PublicOpinionUnhappiness, function()
		return ShowTextToolTipAndPicture( Players[GetActivePlayer()]:GetPublicOpinionUnhappinessTooltip() )
	end)

	-- Register tabbing behavior and assign global TabSelect routine.
	TabSelect = RegisterTabBehavior( g_Tabs, g_Tabs.SocialPolicies )

	Controls.ToIdeologyTab:RegisterCallback( eLClick, function()
		TabSelect( g_Tabs.Ideologies )
	end)
end

-------------------------------------------------
-- Screen Refresh
local function UpdateDisplay()

	local player = Players[GetActivePlayer()];

	if not player then return end

	local pTeam = Teams[player:GetTeam()];


	local playerHasNoCities = player:GetNumCities() < 1


	local bShowAll = OptionsManager.GetPolicyInfo();

	Controls.NextCost:LocalizeAndSetText( "TXT_KEY_NEXT_POLICY_COST_LABEL", player:GetNextPolicyCost() )
	Controls.CurrentCultureLabel:LocalizeAndSetText( "TXT_KEY_CURRENT_CULTURE_LABEL", player:GetJONSCulture() )
	Controls.CulturePerTurnLabel:LocalizeAndSetText( "TXT_KEY_CULTURE_PER_TURN_LABEL", player:GetTotalJONSCulturePerTurn() )

	local cultureNeeded = player:GetNextPolicyCost() - player:GetJONSCulture()
	local culturePerTurn = player:GetTotalJONSCulturePerTurn()
	Controls.NextPolicyTurnLabel:LocalizeAndSetText( "TXT_KEY_NEXT_POLICY_TURN_LABEL", cultureNeeded <= 0 and 0 or ( culturePerTurn <= 0 and "?" or ceil( cultureNeeded / culturePerTurn ) ) )

	-- Player Title
	local dominantBranch = GameInfoPolicyBranchTypes[ player:GetDominantPolicyBranchForTitle() ]
	if dominantBranch then
		Controls.PlayerTitleLabel:SetHide(false);
		Controls.PlayerTitleLabel:LocalizeAndSetText( dominantBranch.Title, player:GetNameKey(), player:GetCivilizationShortDescriptionKey() );
	else
		Controls.PlayerTitleLabel:SetHide(true);
	end

	-- Free Policies
	local iNumFreePolicies = player:GetNumFreePolicies();
	if iNumFreePolicies > 0 then
		Controls.FreePoliciesLabel:LocalizeAndSetText( "TXT_KEY_FREE_POLICIES_LABEL", iNumFreePolicies );
		Controls.FreePoliciesLabel:SetHide( false );
	else
		Controls.FreePoliciesLabel:SetHide( true );
	end

	-- Adjust Policy Branches
	local policyBranchID
	for policyBranchInfo in GameInfoPolicyBranchTypes() do
		if not policyBranchInfo.PurchaseByLevel then

			policyBranchID = policyBranchInfo.ID
			local thisButton = Controls[ "BranchButton"..policyBranchID ]
			local thisBack = Controls[ "BranchBack"..policyBranchID ]
			local thisDisabledBox = Controls[ "DisabledBox"..policyBranchID ]
			local thisLockedBox = Controls[ "LockedBox"..policyBranchID ]
			local thisImageMask = Controls[ "ImageMask"..policyBranchID ]
			local thisDisabledMask = Controls[ "DisabledMask"..policyBranchID ]
			local thisLock = Controls[ "Lock"..policyBranchID ]

			-- Era Prereq
			local iEraPrereq = GameInfoTypes[ policyBranchInfo.EraPrereq ]
			local bEraLock = iEraPrereq and pTeam:GetCurrentEra() < iEraPrereq

			-- Branch is not yet unlocked
			if not player:IsPolicyBranchUnlocked( policyBranchID ) then

				-- Cannot adopt this branch right now
				if policyBranchInfo.LockedWithoutReligion and IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION) then

				elseif not player:CanUnlockPolicyBranch( policyBranchID ) then

					-- Not in prereq Era
					if bEraLock then
						thisButton:LocalizeAndSetText( GameInfoEras[iEraPrereq].Description )

					-- Don't have enough Culture Yet
					else
						thisButton:SetHide( false )
						thisButton:LocalizeAndSetText "TXT_KEY_POP_ADOPT_BUTTON"
					end

					thisLock:SetHide( false );
					thisButton:SetDisabled( true );
				-- Can adopt this branch right now
				else
					thisLock:SetHide( true );
					thisButton:SetDisabled( false );
					thisButton:SetHide( false );
					thisButton:LocalizeAndSetText "TXT_KEY_POP_ADOPT_BUTTON"
				end

				if playerHasNoCities then
					thisButton:SetDisabled(true);
				end

				thisBack:SetColor( g_FadeColor );
				thisLockedBox:SetHide(false);

				thisImageMask:SetHide(true);
				thisDisabledMask:SetHide(false);

			-- Branch is unlocked, but blocked by another branch
			elseif player:IsPolicyBranchBlocked( policyBranchID ) then
				thisButton:SetHide( false );
				thisBack:SetColor( g_FadeColor );
				thisLock:SetHide( false );
				thisLockedBox:SetHide(true);

			-- Branch is unlocked already
			else
				thisButton:SetHide( true );
				thisBack:SetColor( g_FullColor );
				thisLockedBox:SetHide(true);

				thisImageMask:SetHide(false);
				thisDisabledMask:SetHide(true);
			end

			-- If the player doesn't have the era prereq, then dim out the branch
			if bEraLock then
				thisDisabledBox:SetHide(false);
				thisLockedBox:SetHide(true);
			else
				thisDisabledBox:SetHide(true);
			end

			if bShowAll then
				thisDisabledBox:SetHide(true);
				thisLockedBox:SetHide(true);
			end
		end
	end

	-- Adjust Policy buttons
	local policyID, policyBranchInfo, instance, atlas, disabled, color
	for policyInfo in GameInfoPolicies() do

		policyBranchInfo = GameInfoPolicyBranchTypes[ policyInfo.PolicyBranchType ]

		-- If this is nil it means the Policy is a freebie handed out with the Branch, so don't display it
		if policyBranchInfo and not policyBranchInfo.PurchaseByLevel then
			policyID = policyInfo.ID
			instance = g_PolicyButtons[ policyID ]
			atlas = policyInfo.IconAtlas
			disabled = true
			color = g_FadeColorRV

			-- Player already has Policy
			if player:HasPolicy( policyID ) then
				color = g_FullColor
				atlas = policyInfo.IconAtlasAchieved

			elseif playerHasNoCities then

			-- Can adopt the Policy right now
			elseif player:CanAdoptPolicy( policyID ) then
				color = g_FullColor
				disabled = false
			end

			instance.MouseOverContainer:SetHide( disabled )
			instance.PolicyIcon:SetDisabled( disabled )
			instance.PolicyImage:SetColor( color )
			IconHookup( policyInfo.PortraitIndex, 64, atlas, instance.PolicyImage )
		end
	end

	-- Adjust Ideology
	if bnw_mode then

		CivIconHookup( player:GetID(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
		Controls.InfoStack2:ReprocessAnchoring();

		local ideologyID = player:GetLateGamePolicyTree();
		local upperLevelCount = ideologyID >=0 and huge or 0
		local tenetsPerLevel = { 7, 4, 3 }
		for tenetLevel = 1, 3 do
			local levelCount = 0
			local thisLevelTenets = {}
			for i = 1, tenetsPerLevel[tenetLevel] do
				local tenetID = player:GetTenet( ideologyID, tenetLevel, i )
				thisLevelTenets[i] = tenetID
				local buttonControl = Controls["IdeologyButton"..tenetLevel..i]
				local labelControl = Controls["IdeologyButtonLabel"..tenetLevel..i]
				local lockControl = Controls["Lock"..tenetLevel..i]

				buttonControl:SetDisabled( true )
				buttonControl:ClearCallback( eLClick )

				local tenet = GameInfoPolicies[ tenetID ]
				if tenet then
					levelCount = levelCount + 1
					labelControl:LocalizeAndSetText( tenet.Description )
					lockControl:SetHide( true )
				else
					if upperLevelCount > i and i == levelCount+1 then
						tenetID = -1
						labelControl:LocalizeAndSetText( "TXT_KEY_POLICYSCREEN_ADD_TENET" )
						lockControl:SetHide( true )
						if player:GetJONSCulture() >= player:GetNextPolicyCost() or player:GetNumFreePolicies() > 0 or player:GetNumFreeTenets() > 0 then
							buttonControl:RegisterCallback( eLClick, TenetSelect )
							buttonControl:SetDisabled( false )
						else
							tenetID = -2
						end
					else
						lockControl:SetHide( false )
						labelControl:SetString()
						if upperLevelCount == i then
							tenetID = -3
						else
							tenetID = -4
						end
					end
				end
				buttonControl:SetVoids( tenetID, tenetLevel )
				SetToolTipCallback( buttonControl, TenetToolTip )
			end
			Controls["Level"..tenetLevel.."Tenets"]:LocalizeAndSetText( "TXT_KEY_POLICYSCREEN_IDEOLOGY_L"..tenetLevel.."TENETS", levelCount )
			upperLevelCount = levelCount
		end

		local ideology = GameInfoPolicyBranchTypes[ideologyID];
		if ideology then

			-- Free Tenets
			local iNumFreeTenets = player:GetNumFreeTenets();
			if iNumFreeTenets > 0 then
				Controls.FreeTenetsLabel:LocalizeAndSetText( "TXT_KEY_FREE_TENETS_LABEL", iNumFreeTenets )
				Controls.FreeTenetsLabel:SetHide( false );
			else
				Controls.FreeTenetsLabel:SetHide( true );
			end

			local ideologyName = L("TXT_KEY_POLICYSCREEN_IDEOLOGY_TITLE", player:GetCivilizationAdjectiveKey(), ideology.Description);
			Controls.IdeologyHeader:SetText(ideologyName);
			Controls.IdeologyImage1:SetTexture(g_IdeologyBackgrounds[ideology.Type]);
			Controls.IdeologyImage2:SetTexture(g_IdeologyBackgrounds[ideology.Type]);


			Controls.TenetsStack:CalculateSize();
			Controls.TenetsStack:ReprocessAnchoring();

			local ideologyTitle = ToUpper(ideologyName);
			Controls.IdeologyTitle:SetText(ideologyTitle);
			Controls.ChooseTenetTitle:SetText(ideologyTitle);
			Controls.NoIdeology:SetHide(true);
			Controls.DisabledIdeology:SetHide(true);
			Controls.HasIdeology:SetHide(false);

			Controls.IdeologyGenericHeader:SetHide(true);
			Controls.IdeologyDetails:SetHide(false);

			local szOpinionString;
			local iOpinion = player:GetPublicOpinionType();
			if iOpinion == PublicOpinionTypes.PUBLIC_OPINION_DISSIDENTS then
				szOpinionString = L("TXT_KEY_CO_PUBLIC_OPINION_DISSIDENTS");
			elseif iOpinion == PublicOpinionTypes.PUBLIC_OPINION_CIVIL_RESISTANCE then
				szOpinionString = L("TXT_KEY_CO_PUBLIC_OPINION_CIVIL_RESISTANCE");
			elseif iOpinion == PublicOpinionTypes.PUBLIC_OPINION_REVOLUTIONARY_WAVE then
				szOpinionString = L("TXT_KEY_CO_PUBLIC_OPINION_REVOLUTIONARY_WAVE");
			else
				szOpinionString = L("TXT_KEY_CO_PUBLIC_OPINION_CONTENT");
			end
			Controls.PublicOpinion:SetText(szOpinionString);

			local iUnhappiness = -1 * player:GetPublicOpinionUnhappiness();
			local strPublicOpinionUnhappiness = tostring(0);
			if iUnhappiness < 0 then
				strPublicOpinionUnhappiness = L("TXT_KEY_CO_PUBLIC_OPINION_UNHAPPINESS", iUnhappiness);
				Controls.SwitchIdeologyButton:SetDisabled(false);
				local preferredIdeologyInfo = GameInfoPolicyBranchTypes[ player:GetPublicOpinionPreferredIdeology() ] or {}
				Controls.SwitchIdeologyButton:LocalizeAndSetToolTip( "TXT_KEY_POLICYSCREEN_CHANGE_IDEOLOGY_TT", preferredIdeologyInfo.Description or "???", -iUnhappiness, 2 )
			else
				Controls.SwitchIdeologyButton:SetDisabled( true )
				Controls.SwitchIdeologyButton:LocalizeAndSetToolTip( "TXT_KEY_POLICYSCREEN_CHANGE_IDEOLOGY_DISABLED_TT" )
			end
			Controls.PublicOpinionUnhappiness:SetText(strPublicOpinionUnhappiness);
			Controls.PublicOpinionHeader:SetHide(false);
			Controls.PublicOpinion:SetHide(false);
			Controls.PublicOpinionUnhappinessHeader:SetHide(false);
			Controls.PublicOpinionUnhappiness:SetHide(false);
			Controls.SwitchIdeologyButton:SetHide(false);
		else
			Controls.IdeologyImage1:SetTexture( "PolicyBranch_Ideology.dds" );
			Controls.HasIdeology:SetHide(true);
			Controls.IdeologyGenericHeader:SetHide(false);
			Controls.IdeologyDetails:SetHide(true);
			Controls.PublicOpinionHeader:SetHide(true);
			Controls.PublicOpinion:SetHide(true);
			Controls.PublicOpinionUnhappinessHeader:SetHide(true);
			Controls.PublicOpinionUnhappiness:SetHide(true);
			Controls.SwitchIdeologyButton:SetHide(true);

			local bDisablePolicies = IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES);
			Controls.NoIdeology:SetHide(bDisablePolicies);
			Controls.DisabledIdeology:SetHide(not bDisablePolicies);

		end
	else
		Controls.AnarchyBlock:SetHide( not player:IsAnarchy() );
	end
	Controls.InfoStack:ReprocessAnchoring();
end
Events.EventPoliciesDirty.Add( UpdateDisplay )

-------------------------------------------------
-- Initialization
local bDisablePolicies = IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES);
Controls.LabelPoliciesDisabled:SetHide(not bDisablePolicies);
Controls.InfoStack:SetHide(bDisablePolicies);
Controls.InfoStack2:SetHide(bDisablePolicies);

local blockSpacingX = 28
local blockSpacingY = 68
local blockOffsetX = 16 - blockSpacingX
local blockOffsetY = 12 - blockSpacingY
local connectorElbowSizeX = 19	-- connector texture width
local connectorElbowSizeY = 19	-- connector texture height
local connectorOffsetX = 3
local connectorStartOffsetY = blockOffsetY + 48 - 1
local connectorEndOffsetY = blockOffsetY + 1
local connectorElbowOffsetY = connectorEndOffsetY - connectorElbowSizeY
local connectorHorizontalOffsetY = connectorOffsetX + connectorElbowSizeX

local function GetConnectorPipe( panel, x, y, texture )
	local pipe = {}
	ContextPtr:BuildInstanceForControl( "ConnectorPipe", pipe, panel )
	pipe = pipe.ConnectorImage
	pipe:SetOffsetVal( x, y )
	pipe:SetTextureAndResize( texture )
	return pipe
end

local prereq, policy, x1, x2, y1, y2, height, width, panel, pipe, x, y, instance, thisButton

-- Create straight connector instances first
for row in GameInfoPrereqPolicies() do
	prereq = GameInfoPolicies[row.PrereqPolicy]
	policy = GameInfoPolicies[row.PolicyType]
	if policy and prereq then
		panel = g_PolicyBranchPanels[ policy.PolicyBranchType ]
		if panel then
			y1 = prereq.GridY*blockSpacingY + connectorStartOffsetY
			y2 = policy.GridY*blockSpacingY + connectorEndOffsetY

			width = abs( policy.GridX - prereq.GridX ) * blockSpacingX

			-- horizontal connector
			if width > 0 then
				y2 = y2 - connectorElbowSizeY
				width = width - connectorElbowSizeX
				if width > 0 then
					pipe = GetConnectorPipe( panel, min(policy.GridX, prereq.GridX) * blockSpacingX + connectorHorizontalOffsetY, y2, "Connect_H.dds" )
					x, y = pipe:GetSizeVal()
					pipe:SetSizeX( width )
					-- graphic engine bug workaround
					if width < x then
						pipe:SetTextureSizeVal( width, y )
						pipe:SetTexture( "Connect_H.dds" )
					end
				end
			end

			-- vertical connector
			height = y2 - y1
			if height > 0 then
				pipe = GetConnectorPipe( panel, prereq.GridX*blockSpacingX + connectorOffsetX, y1, "Connect_V.dds" )
				x, y = pipe:GetSizeVal()
				pipe:SetSizeY( height )
				-- graphic engine bug workaround
				if height < y then
					pipe:SetTextureSizeVal( x, height )
					pipe:SetTexture( "Connect_V.dds" )
				end
			end
		end
	end
end

-- Create elbow connector intances next
for row in GameInfoPrereqPolicies() do
	prereq = GameInfoPolicies[row.PrereqPolicy]
	policy = GameInfoPolicies[row.PolicyType]
	if policy and prereq then
		panel = g_PolicyBranchPanels[ policy.PolicyBranchType ]
		if panel then
			x1 = prereq.GridX
			x2 = policy.GridX
			y = policy.GridY*blockSpacingY + connectorElbowOffsetY
			if x1 > x2 then
				GetConnectorPipe( panel, x1*blockSpacingX + connectorOffsetX, y, "Connect_JonCurve_BottomRight.dds" )	--		_|
				GetConnectorPipe( panel, x2*blockSpacingX + connectorOffsetX, y, "Connect_JonCurve_TopLeft.dds" )		--	|¯
			elseif x1 < x2 then
				GetConnectorPipe( panel, x1*blockSpacingX + connectorOffsetX, y, "Connect_JonCurve_BottomLeft.dds" )	--	|_
				GetConnectorPipe( panel, x2*blockSpacingX + connectorOffsetX, y, "Connect_JonCurve_TopRight.dds" )		--		¯|
			end
		end
	end
end

-- Create policy button instances last
for policyInfo in GameInfoPolicies() do
	panel = g_PolicyBranchPanels[ policyInfo.PolicyBranchType ]
	-- If this is nil it means the Policy is a freebie handed out with the Branch, so don't display it
	if panel then
		instance = {}
		ContextPtr:BuildInstanceForControl( "PolicyButton", instance, panel )
		-- store this away for later
		g_PolicyButtons[ policyInfo.ID ] = instance
		thisButton = instance.PolicyIcon
		thisButton:SetOffsetVal( policyInfo.GridX*blockSpacingX+blockOffsetX, policyInfo.GridY*blockSpacingY+blockOffsetY )
		thisButton:SetVoid1( policyInfo.ID )
		thisButton:RegisterCallback( eLClick, PolicySelect )
		thisButton:RegisterCallback( eRClick, PolicyPedia )
		SetToolTipCallback( thisButton, PolicyTooltip )
	end
end

-- Set Yes & No policy choice confirmation handlers
Controls.Yes:RegisterCallback( eLClick, function( policyID, isAdoptingPolicy )
	Controls.PolicyConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
	if GameInfoPolicies[ policyID ] then
		Network.SendUpdatePolicies( policyID, isAdoptingPolicy > 0, true);
		Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");
	end
end)
SetToolTipCallback( Controls.Yes, function(control) (control:GetVoid2()>0 and PolicyTooltip or PolicyBranchTooltip)( control ) end )

Controls.No:RegisterCallback( eLClick, function()
	Controls.PolicyConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
end)

-- Handlers for the horrible hardcoded static branch buttons
for policyBranchInfo in GameInfoPolicyBranchTypes() do
	if not policyBranchInfo.PurchaseByLevel then
		thisButton = Controls["BranchButton"..policyBranchInfo.ID]
		thisButton:SetVoid1( policyBranchInfo.ID )
		thisButton:RegisterCallback( eLClick, PolicyBranchSelect )
		thisButton:RegisterCallback( eRClick, PolicyBranchPedia )
		SetToolTipCallback( thisButton, PolicyBranchTooltip )
	end
end

-- Display Mode Toggle
Controls.PolicyInfo:RegisterCheckHandler( function( bIsChecked )
	local bUpdateScreen = bIsChecked ~= OptionsManager.GetPolicyInfo()
	OptionsManager.SetPolicyInfo_Cached( bIsChecked );
	OptionsManager.CommitGameOptions();
	if bUpdateScreen then
		Events.EventPoliciesDirty();
	end
end)

-- Key Down Processing
do
	local VK_RETURN = Keys.VK_RETURN
	local VK_ESCAPE = Keys.VK_ESCAPE
	local KeyDown = KeyEvents.KeyDown
	ContextPtr:SetInputHandler( function( uiMsg, wParam )
		if uiMsg == KeyDown then
			if wParam == VK_ESCAPE or wParam == VK_RETURN then
				if bnw_mode then
					if Controls.PolicyConfirm:IsHidden() and Controls.TenetConfirm:IsHidden() and Controls.ChooseTenet:IsHidden() and Controls.ChangeIdeologyConfirm:IsHidden() then
						OnClose();
					elseif Controls.TenetConfirm:IsHidden() then
						Controls.ChooseTenet:SetHide(true);
						Controls.PolicyConfirm:SetHide(true);
						Controls.BGBlock:SetHide(false);
					else
						Controls.TenetConfirm:SetHide(true);
					end
				elseif Controls.PolicyConfirm:IsHidden() then
					OnClose();
				else
					Controls.PolicyConfirm:SetHide(true);
					Controls.BGBlock:SetHide(false);
				end
			end
			return true
		end
	end)
end

-- Show/hide handler
ContextPtr:SetShowHideHandler( function( bIsHide, bInitState )
	if not bInitState then
		Controls.PolicyInfo:SetCheck( OptionsManager.GetPolicyInfo() );
		if not bIsHide then
			incTurnTimerSemaphore();
			Events.SerialEventGameMessagePopupShown(g_PopupInfo);
		else
			decTurnTimerSemaphore();
			Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY, 0);
		end
	end
end)

-- Active player change handler
Events.GameplaySetActivePlayer.Add( function()
	if bnw_mode then
		if not Controls.PolicyConfirm:IsHidden() or not Controls.TenetConfirm:IsHidden() or not Controls.ChangeIdeologyConfirm:IsHidden() then
			Controls.TenetConfirm:SetHide(true);
			Controls.ChangeIdeologyConfirm:SetHide(true);
			Controls.PolicyConfirm:SetHide(true);
			Controls.BGBlock:SetHide(false);
		end
	elseif not Controls.PolicyConfirm:IsHidden() then
		Controls.PolicyConfirm:SetHide(true);
		Controls.BGBlock:SetHide(false);
	end
	OnClose();
end)

-------------------------------------------------
-- Hookup Popup
AddSerialEventGameMessagePopup( function(popupInfo)
	if popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY then
		g_PopupInfo = popupInfo;
		UpdateDisplay();
		if bnw_mode then
			local player = Players[GetActivePlayer()]
			if g_PopupInfo.Data2 == 2 or (player and player:GetNumFreeTenets() > 0) then
				TabSelect( g_Tabs.Ideologies )
			else
				TabSelect( g_Tabs.SocialPolicies )
			end
		end
		if g_PopupInfo.Data1 == 1 then
			if ContextPtr:IsHidden() then
				UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost )
			else
				OnClose()
			end
		else
			UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy )
		end
	end
end, ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY )

end)