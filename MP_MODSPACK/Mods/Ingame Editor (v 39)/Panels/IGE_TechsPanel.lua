-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
print("IGE_TechsPanel");
IGE = nil;

local instances = {};
local eraInstances = {};
local eraManager = CreateInstanceManager("EraInstance", "Root", Controls.MainList );
local pipeManager = CreateInstanceManager("ConnectorInstance", "Root", Controls.ScrollPanel);
local techManager = CreateInstanceManager("TechInstance", "Button", Controls.MainList);
local fallbackEraManager = CreateInstanceManager("FallbackEraInstance", "Root", Controls.MainList );
local fallbackTechManagers = {};

local data = {};
local isVisible = false;
local hideDisabledTechs = false;
local hideTechsWithNegativeCoords = false;

local profiles = {};
local currentProfile = 1;
table.insert(profiles, { name = L("TXT_KEY_IGE_TECHS_COMPATIBILITY_NONE"), filter = function(t) return true end });
table.insert(profiles, { name = L("TXT_KEY_IGE_TECHS_COMPATIBILITY_STANDARD"), filter = function(t) return ((t.gridX > 0) and (t.gridY > 0)) end });
table.insert(profiles, { name = L("TXT_KEY_IGE_TECHS_COMPATIBILITY_NIGHTS"), filter = function(t) return not t.disable end });



--===============================================================================================
-- CORE EVENTS
--===============================================================================================
function InitializeHelp()
	print("IGE_TechsPanel.InitializeHelp");
	for _, v in pairs(data.techsByTypes) do
		v.help = GetIGEHelpTextForTech(v)
		AppendIDAndTypeToHelp(v)
	end
end

-------------------------------------------------------------------------------------------------
function InitializeControls()
	local sizeX = 196;
	local paddingX = 300;
	local offsetX = (paddingX - sizeX) / 2;
	local deltaEra = 20;

	-- Eras
	local last = 0;
	local offset = 0;
	local lastEraMax = 0;
	for i, era in ipairs(data.eras) do
		if #era.techs > 0 then
			local instance = (data.canUseVanillaLogicForTechs and eraManager or fallbackEraManager):GetInstance();
			if instance then
				instance.Button:RegisterCallback(Mouse.eLClick, function() EraClickHandler(era) end);
				eraInstances[i] = instance;
				last = i;

				if data.canUseVanillaLogicForTechs then
					instance.ButtonLabel:SetText(era.name);
					instance.CurrentLabel:SetText(era.name);
					instance.FutureLabel:SetText(era.name);
					instance.OldLabel:SetText(era.name);

					-- Update size
					local eramax = lastEraMax;
					for j, tech in ipairs(era.techs) do
						if tech.visible then
							local x = (tech.gridX - 1) * paddingX + offsetX;
							eramax = math.max(eramax, x + sizeX + offsetX); 
						end
					end
					local width = 0;
					if lastEraMax < eramax then 
						width = eramax - lastEraMax;
					end

					instance.Root:SetHide(width <= 0);
					instance.Root:SetOffsetX(lastEraMax);
					instance.Root:SetSizeX(width);
					instance.Button:SetSizeX(width);
					instance.ButtonContent:SetSizeX(width);
					instance.OldBar:SetSizeX(width);
					instance.OldBlock:SetSizeX(width);
					instance.CurrentBlock:SetSizeX(width);
					instance.CurrentInnerBar:SetSizeX(width);
					instance.CurrentBar:SetSizeX(width);
					instance.FutureBlock:SetSizeX(width);
					lastEraMax = eramax;
				else
					fallbackTechManagers[i] = CreateInstanceManager("FallbackTechInstance", "Button", instance.List );
					instance.Header:SetText(era.name);
					instance.ButtonLabel:SetText(era.name);
					instances[era] = {};
				end
			end
		end
	end
	eraInstances[last].Separator:SetHide(true);

	-- Technologies
	if data.canUseVanillaLogicForTechs then
		local xmin, xmax = UpdateGraph(data.techs, techManager, pipeManager, instances, sizeX, 38, paddingX, 38, offsetX - deltaEra, 27, true);
		Controls.MainList:SetSizeX(xmax);
		Controls.MainList:SetSizeY(Controls.MainStack:GetSizeY());
		Controls.ScrollPanel:SetSizeY(Controls.MainStack:GetSizeY());
		Controls.ScrollPanel:SetOffsetVal(8,0);
		Controls.CompatibilityStack:SetHide(true);

		for i, tech in ipairs(data.techs) do
			if tech.visible then
				local instance = instances[tech];

				TruncateString(instance.AlreadyResearchedName, 130, tech.name);
				TruncateString(instance.UnavailableName, 130, tech.name);
				TruncateString(instance.AvailableName, 130, tech.name);
				TruncateString(instance.LockedName, 130, tech.name);

				instance.Portrait:SetTexture(tech.smallTexture);
				instance.Portrait:SetTextureOffset(tech.smallTextureOffset);
				instance.Button:SetToolTipCallback(function() ToolTipHandler(tech) end);
				instance.Button:RegisterCallback(Mouse.eLClick, function() ClickHandler(tech) end);
			end
		end
	end

	-- Compatibility profiles
    for i, v in ipairs(profiles) do
        local instance = {};
        Controls.CompatibilityPullDown:BuildEntry("InstanceOne", instance);
        instance.Button:SetText(v.name);
        instance.Button:SetVoid1(i);
    end
    Controls.CompatibilityPullDown:CalculateInternals();
end

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	SetTechnologiesData(data);
	CheckLayoutForTechs(data);
	SetBuildingsData(data);
	SetUnitsData(data);
	InitializeHelp();

	Resize(Controls.MainStack);
	Resize(Controls.ScrollPanel);
	Resize(Controls.Container);

	InitializeControls();

	local tt = L("TXT_KEY_IGE_TECHS_PANEL_HELP");
	LuaEvents.IGE_RegisterTab("TECHS", L("TXT_KEY_IGE_TECHS_PANEL"), 4, "change",  tt);
end
LuaEvents.IGE_Initialize.Add(OnInitialize)

-------------------------------------------------------------------------------------------------
function OnSelectedPanel(ID)
	isVisible = (ID == "TECHS");
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel);

-------------------------------------------------------------------------------------------------
function ClickHandler(tech)
	local pTeam = Teams[IGE.currentPlayer:GetTeam()];
	local newValue = not pTeam:IsHasTech(tech.ID);

	-- Toggle one tech
	if not UIManager:GetShift() then
		pTeam:SetHasTech(tech.ID, newValue, IGE.currentPlayerID, true, true);

	-- Add the tech and all of its prereq
	elseif newValue then
		local added = { tech };
		
		while #added ~= 0 do
			local added2 = {};
			for _, tech in ipairs(added) do
				pTeam:SetHasTech(tech.ID, true, IGE.currentPlayerID, true, true);

				for _, prereq in ipairs(tech.prereqs) do
					if not pTeam:IsHasTech(prereq.ID) then 
						table.insert(added2, prereq);
					end
				end
			end
			added = added2;
		end

	-- Remove the tech and all of its children
	else
		local count = 1;
		local removed = {};
		removed[tech.ID] = true;

		while count ~= 0 do
			for id in pairs(removed) do
				pTeam:SetHasTech(id, false, IGE.currentPlayerID, true, true);
			end

			count = 0;
			local removed2 = {};
			for _, tech in ipairs(data.techs) do
				if pTeam:IsHasTech(tech.ID) then
					for _, prereq in ipairs(tech.prereqs) do
						if removed[prereq.ID] then 
							removed2[tech.ID] = true;
							count = count + 1;
						end
					end
				end
			end

			removed = removed2;
		end
	end
	OnUpdate();
end

-------------------------------------------------------------------------------------------------
function EraClickHandler(era)
	local pTeam = Teams[IGE.currentPlayer:GetTeam()];
	for _, v in ipairs(era.techs) do
		pTeam:SetHasTech(v.ID, true, IGE.currentPlayerID, true, true);
	end
	OnUpdate();
end

--===============================================================================================
-- UPDATE
--===============================================================================================
function UpdateCore()
	local pPlayer = IGE.currentPlayer;
	local pTeam = Teams[pPlayer:GetTeam()];
	local filter = profiles[currentProfile].filter;
	Controls.CompatibilityPullDown:GetButton():SetText(profiles[currentProfile].name);

	-- Eras
	local offset = 0;
	for i, era in ipairs(data.eras) do
		local completed = 0;
		local visible = false;
		for j, tech in ipairs(era.techs) do

			-- Update tech visibility
			tech.visible = true;
			if not data.canUseVanillaLogicForTechs then
				tech.visible = filter(tech);
			end
			visible = visible or tech.visible;

			-- Is era completed?
			if pTeam:IsHasTech(tech.ID) then
				completed = completed + 1;
			end
		end

		-- Update header
		local instance = eraInstances[i];
		if instance then
			if data.canUseVanillaLogicForTechs then
				instance.Button:SetDisabled(completed == #era.techs);
				instance.CurrentAnim:SetHide(completed == 0 or completed == #era.techs);
				instance.CurrentBar:SetHide(completed == 0 or completed == #era.techs);
				instance.OldBlock:SetHide(completed < #era.techs);
				instance.FutureBlock:SetHide(completed > 0);
			else
				instance.Root:SetHide(not visible);
				instance.Root:SetOffsetX(offset);

				local width = UpdateList(era.techs, fallbackTechManagers[i], ClickHandler, nil, instances[era]);
				offset = offset + width + 10;

				instance.HeaderArea:SetSizeX(width + 10);
				instance.HeaderBackground:SetSizeX(width + 10);
				instance.ButtonContent:SetSizeX(width + 10);
				instance.Button:SetSizeX(width + 10);
				instance.Root:SetSizeX(width + 10);
				Controls.MainList:SetSizeX(offset);
			end
		end
	end

	-- Techs
	for i, tech in ipairs(data.techs) do
		local isKnown = pTeam:IsHasTech(tech.ID);
		local locked = tech.disable;
		local canLearn = true;
		for _, prereq in ipairs(tech.prereqs) do
			canLearn = canLearn and pTeam:IsHasTech(prereq.ID);
		end

		if data.canUseVanillaLogicForTechs then
			local instance = instances[tech];
			instance.AlreadyResearched:SetHide(not isKnown);
			instance.Locked:SetHide(isKnown or not locked);
			instance.Available:SetHide(isKnown or locked or not canLearn);
			instance.Unavailable:SetHide(isKnown or locked or canLearn);
		else
			local instance = instances[tech.era][tech];
			instance.CheckMark:SetHide(not isKnown);
			instance.NameLabel:SetAlpha((canLearn or IsKnown) and 1 or 0.6);
			TruncateString(instance.NameLabel, 154, tech.label or tech.name);
		end
	end

	-- Update scroll view
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();
    Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 36);
end

-------------------------------------------------------------------------------------------------
function OnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	LuaEvents.IGE_SetMouseMode(IGE_MODE_NONE);
	UpdateCore();
end
LuaEvents.IGE_Update.Add(OnUpdate);

-------------------------------------------------------------------------------------------------
function OnPullDownSelectionChanged(ID)
	currentProfile = ID;
	OnUpdate();
end
Controls.CompatibilityPullDown:RegisterSelectionCallback(OnPullDownSelectionChanged);
