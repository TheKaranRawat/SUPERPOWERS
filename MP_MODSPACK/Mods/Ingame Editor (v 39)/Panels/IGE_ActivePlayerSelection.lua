-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
print("IGE_ActivePlayerSelection");
IGE = nil;

local majorPlayerItemManager = CreateInstanceManager("MajorPlayerInstance", "Button", Controls.MajorPlayerList);
local minorPlayerItemManager = CreateInstanceManager("MinorPlayerInstance", "Button", Controls.MinorPlayerList);

local panelID = "PLAYER_SELECTION";
local isVisible = false;
local data = {};

-------------------------------------------------------------------------------------------------
function OnSelectedPanel(ID)
	isVisible = (ID == panelID);
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel)

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	Resize(Controls.Container);
	Resize(Controls.ScrollPanel);
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 6);
	SetPlayersData(data, { none=false });
end
LuaEvents.IGE_Initialize.Add(OnInitialize);

-------------------------------------------------------------------------------------------------
function OnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	for k, v in pairs(data.allPlayers) do
		v.selected = false;
		v.visible = (v.ID >= 0 and Players[v.ID]:IsAlive());
		if v.ID == IGE.initialPlayerID then
			v.priority = 10;
			v.label = L("TXT_KEY_YOU").." - "..v.civilizationName;
		elseif v.isBarbarians then
			v.label = v.civilizationName;
			v.priority = 1;
		else
			v.label = v.civilizationName and v.name.." - "..v.civilizationName or v.name;
			v.priority = 2;
		end
	end

	table.sort(data.majorPlayers, DefaultSort);
	table.sort(data.minorPlayers, DefaultSort);
	--for k, v in ipairs(data.majorPlayers) do print(v.name) end

	UpdateList(data.majorPlayers, majorPlayerItemManager, function(v) LuaEvents.IGE_SelectPlayer(v.ID) end);
	UpdateList(data.minorPlayers, minorPlayerItemManager, function(v) LuaEvents.IGE_SelectPlayer(v.ID) end);

	Controls.Stack:CalculateSize();
	local offset = (Controls.ScrollPanel:GetSizeX() - Controls.Stack:GetSizeX()) / 2;
	Controls.Stack:SetOffsetVal(offset > 0 and offset or 0, 0);

	Controls.Stack:ReprocessAnchoring();
	Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollDown:SetHide(offset > 0);
	Controls.ScrollBar:SetHide(offset > 0);
	Controls.ScrollUp:SetHide(offset > 0);
end
LuaEvents.IGE_Update.Add(OnUpdate);
