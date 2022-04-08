-- Released under GPL v3
--------------------------------------------------------------
include("FLuaVector");
include("IGE_API_All");
print("IGE_PoliciesPanel");
IGE = nil;

local pipeManagers = {};
local itemManagers = {};
local groupManager = CreateInstanceManager("BranchInstance", "Root", Controls.MainList );

local BranchInstances = {};
local instances = {};

local data = {};
local isVisible = false;

local fullColor = {x = 1, y = 1, z = 1, w = 1};
local fadeColorRV = {x = 1, y = 1, z = 1, w = 0.2};


--===============================================================================================
-- CORE EVENTS
--===============================================================================================
function InitializeControls()
	local frist = true;
	for i, branch in ipairs(data.policyBranches) do
		local BranchInstance = groupManager:GetInstance();

		if BranchInstance then
			BranchInstances[i] = BranchInstance;

			BranchInstance.Title:SetText(branch.name);
			BranchInstance.Root:SetToolTipString(branch.help);
			BranchInstance.AdoptButton:SetText(L("TXT_KEY_POP_ADOPT_BUTTON"));
			BranchInstance.TopAdoptButton:RegisterCallback(Mouse.eLClick, function() AdoptClickHandler(branch) end);
			BranchInstance.TopAdoptButton:SetToolTipString(branch.help);

			local itemManager, pipeManager = nil;
			instances[i] = {};

			if branch.canUseVanillaLogic then
				pipeManager = CreateInstanceManager("ConnectorInstance", "Root", BranchInstance.Panel);
				itemManager = CreateInstanceManager("PolicyInstance", "Root", BranchInstance.Panel);

				local xmin, xmax = UpdateGraph(branch.policies, itemManager, pipeManager, instances[i], 48, 48, 28, 68, 0, 0, false);
				BranchInstance.Panel:SetSizeX(xmax - xmin);
				BranchInstance.Panel:SetOffsetX(-xmin);
			else
				itemManager = CreateInstanceManager("FallbackPolicyInstance", "Button", BranchInstance.Panel);
				local width = UpdateList(branch.policies, itemManager, ClickHandler, nil, instances[i]);
				if width > 170 then
					BranchInstance.BlackMask:SetSizeX(width + 20);
					BranchInstance.ImageMask:SetSizeX(width + 20);
					BranchInstance.Root:SetSizeX(width + 20);
				end
			end

			itemManagers[i] = itemManager;
			pipeManagers[i] = pipeManager;
			BranchInstance.Root:ReprocessAnchoring();

			if first then
				BranchInstance.Separator:SetHide(true);
				first = false;
			end
		end
	end

	-- Size update
	local width = Controls.MainList:GetSizeX();
	Controls.UpperSeparator:SetSizeX(width);
	Controls.LowerSeparator:SetSizeX(width);
    Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 52);
end

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	print("IGE_PoliciesPanel.OnInitialize");
	SetPoliciesData(data);
	CheckLayoutForPolicies(data);

	Resize(Controls.Container);
	Resize(Controls.ScrollPanel);

	InitializeControls();

	Controls.MainList:CalculateSize();

	LuaEvents.IGE_RegisterTab("POLICIES", L("TXT_KEY_IGE_SOCIAL_POLICIES_PANEL"), 5, "change",  "");
	print("IGE_PoliciesPanel.OnInitialize - Done");
end
LuaEvents.IGE_Initialize.Add(OnInitialize)

-------------------------------------------------------------------------------------------------
function OnSelectedPanel(ID)
	isVisible = (ID == "POLICIES");
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel);


-------------------------------------------------------------------------------------------------
function ClickHandler(policy)
	local newValue = not IGE.currentPlayer:HasPolicy(policy.ID);
	IGE.currentPlayer:SetHasPolicy(policy.ID, newValue);
	UpdateFinisherStatus(policy.branch);
	OnUpdate();
end

-------------------------------------------------------------------------------------------------
function AdoptClickHandler(branch)
	local newValue = not IGE.currentPlayer:IsPolicyBranchUnlocked(branch.ID);
	IGE.currentPlayer:SetPolicyBranchUnlocked(branch.ID, newValue);
	if branch.opener then
		IGE.currentPlayer:SetHasPolicy(branch.opener.ID, newValue);
	end
	UpdateFinisherStatus(branch);
	OnUpdate();
end

-------------------------------------------------------------------------------------------------
function UpdateFinisherStatus(branch)
	if not branch.finisher then return end

	-- The branch must be unlocked and all of its policies (except finishers and openers) must have been adopted.
	local enabled = IGE.currentPlayer:IsPolicyBranchUnlocked(branch.ID);
	for _, policy in ipairs(branch.policies) do
		if (not policy.isOpener) and (not policy.isFinisher) then
			enabled = enabled and IGE.currentPlayer:HasPolicy(policy.ID);
		end
	end

	IGE.currentPlayer:SetHasPolicy(branch.finisher.ID, newValue);
end

--===============================================================================================
-- UPDATE
--===============================================================================================
function UpdateCore()
    local pPlayer = IGE.currentPlayer;
    local pTeam = Teams[pPlayer:GetTeam()];
    
	-- Scan branches
	for i, branch in ipairs(data.policyBranches) do
		local BranchInstance = BranchInstances[i];
		local isUnlocked = pPlayer:IsPolicyBranchUnlocked(branch.ID)
		local canUnlock = pPlayer:CanUnlockPolicyBranch(branch.ID)

		BranchInstance.AdoptButton:SetDisabled(isUnlocked);

		-- Scan policies
		for j, policy in ipairs(branch.policies) do
			local instance = instances[i][policy];
			if instance then
				local hasPolicy = pPlayer:HasPolicy(policy.ID);
				local canAdopt = isUnlocked and not hasPolicy;
				for _, prereq in ipairs(policy.prereqs) do
					canAdopt = canAdopt and pPlayer:HasPolicy(prereq.ID);
				end

				if branch.canUseVanillaLogic then
					instance.ButtonChrome:SetDisabled(hasPolicy or not canAdopt);

					instance.Button:RegisterCallback(Mouse.eLClick, function() ClickHandler(policy) end);
					instance.Button:SetToolTipString(policy.help);

					instance.Image:SetTextureOffset(hasPolicy and policy.achievedTextureOffset or policy.textureOffset);
					instance.Image:SetTexture(hasPolicy and policy.achievedTexture or policy.texture);
					instance.Image:SetColor((hasPolicy or canAdopt) and fullColor or fadeColorRV);
				else
					instance.CheckMark:SetHide(not hasPolicy);
					instance.NameLabel:SetAlpha((canAdopt or hasPolicy) and 1 or 0.5);
					TruncateString(instance.NameLabel, 116, policy.name);
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------------------
function OnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	LuaEvents.IGE_SetMouseMode(IGE_MODE_NONE);
	UpdateCore();
end
LuaEvents.IGE_Update.Add(OnUpdate);
