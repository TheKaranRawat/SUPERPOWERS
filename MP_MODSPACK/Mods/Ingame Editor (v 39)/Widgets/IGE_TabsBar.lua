-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
print("IGE_TabsBar");
IGE = nil;

local editTabItemManager = CreateInstanceManager("TabInstance", "Root", Controls.EditTabsStack);
local paintTabItemManager = CreateInstanceManager("TabInstance", "Root", Controls.PaintTabsStack);
local changeTabItemManager = CreateInstanceManager("TabInstance", "Root", Controls.ChangeTabsStack);

local smallLayout = false;
local currentTabID = nil;
local currentPanelID = nil;
local reportedMultipleVersions = false;
local groups = { edit = {}, paint = {}, change = {} };
local tabs = {};
local data = {};

-------------------------------------------------------------------------------------------------
function SetTab(ID)
	currentPanelID = ID;
	if ID ~= "PLAYER_SELECTION" then currentTabID = ID end
	LuaEvents.IGE_SelectedPanel(ID);
	LuaEvents.IGE_Update();
end
LuaEvents.IGE_SetTab.Add(SetTab);

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	print("IGE_TabsBar.OnInitialize");
	SetPlayersData(data, {});

	Resize(Controls.Container);
	Resize(Controls.TabsGrid);

	local sizeX, sizeY = UIManager:GetScreenSizeVal();
	if sizeX < 1280 then
		Controls.Label_Edit:SetOffsetX(0);
		Controls.Label_Paint:SetOffsetX(0);
		Controls.Label_Change:SetOffsetX(0);
		Controls.EditTabsStack:SetOffsetX(0);
		Controls.PaintTabsStack:SetOffsetX(0);
		Controls.ChangeTabsStack:SetOffsetX(0);
	end

	if sizeY < 1000 then
		smallLayout = true;
		LowerSizeY(Controls.Container, 16);
		LowerSizeY(Controls.TabsGrid, 16);
		LowerSizeY(Controls.TabsStack, 16);
		LowerSizeY(Controls.PlayerButton, 16);
		LowerSizeY(Controls.PlayerBackground, 16);
		LowerSizeY(Controls.PlayerHover, 16);
		LowerSizeY(Controls.PlayerContainer, 16);

		Controls.PlayerImage:SetSizeX(45);
		Controls.PlayerImage:SetSizeY(45);

		Controls.TabsStack:ReprocessAnchoring();
		Controls.PlayerContainer:ReprocessAnchoring();

		editTabItemManager = CreateInstanceManager("SmallTabInstance", "Root", Controls.EditTabsStack);
		paintTabItemManager = CreateInstanceManager("SmallTabInstance", "Root", Controls.PaintTabsStack);
		changeTabItemManager = CreateInstanceManager("SmallTabInstance", "Root", Controls.ChangeTabsStack);
	end
	print("IGE_TabsBar.OnInitialize - Done");
end
LuaEvents.IGE_Initialize.Add(OnInitialize);

-------------------------------------------------------------------------------------------------
function OnRegisterTab(_id, _name, _icon, _group, _toolTip, _topData)
	local header = "[COLOR_POSITIVE_TEXT]".._name.."[ENDCOLOR]";
	_toolTip = _toolTip and header.."[NEWLINE]".._toolTip or header;
	local iconSize = smallLayout and 45 or 64;

	local tab = 
	{ 
		ID = _id, 
		name = _name, 
		icon = _icon, 
		group = _group,
		toolTip = _toolTip,
		topData = _topData,
		texture = (smallLayout and "Art/IgeMenuIcons45.dds" or "Art/IgeMenuIcons64.dds"),
		textureOffset = Vector2(iconSize * _icon, iconSize),
		visible = true,
	};

	if tabs[_id] then
		
	end
	tabs[_id] = tab;
	table.insert(groups[_group], tab);

	if currentPanelID == nil then
		currentPanelID = _id;
		currentTabID = _id;
		LuaEvents.IGE_SelectedPanel(_id);
	end
end
LuaEvents.IGE_RegisterTab.Add(OnRegisterTab);

-------------------------------------------------------------------------------------------------
function OnSetTabData(ID, data)
	tabs[ID].topData = data;
	OnUpdate();
end
LuaEvents.IGE_SetTabData.Add(OnSetTabData);

-------------------------------------------------------------------------------------------------
function OnUpdate()
	for k, v in pairs(tabs) do
		v.selected = (currentPanelID == k);
	end

	UpdateGeneric(groups.edit, editTabItemManager, function(v) SetTab(v.ID) end);
	UpdateGeneric(groups.paint, paintTabItemManager, function(v) SetTab(v.ID) end);
	UpdateGeneric(groups.change, changeTabItemManager, function(v) SetTab(v.ID) end);

	Controls.EditTabsStack:CalculateSize();
	Controls.PaintTabsStack:CalculateSize();
	Controls.ChangeTabsStack:CalculateSize();
	Controls.TabsStack:CalculateSize();

	-- German fix (names were too long)
	while Controls.TabsStack:GetSizeX() > Controls.TabsGrid:GetSizeX() do
		Controls.Label_Edit:SetOffsetX(Controls.Label_Edit:GetOffsetVal() - 10);
		Controls.Label_Paint:SetOffsetX(Controls.Label_Paint:GetOffsetVal() - 10);
		Controls.Label_Change:SetOffsetX(Controls.Label_Change:GetOffsetVal() - 10);
		Controls.TabsStack:ReprocessAnchoring();
	end

	local playerData = data.playersByID[IGE.currentPlayerID];
	if smallLayout then
		Controls.PlayerImage:SetTexture(playerData.texture);
		Controls.PlayerImage:SetTextureOffset(playerData.textureOffset);
	else
		Controls.PlayerImage:SetTexture(playerData.texture);
		Controls.PlayerImage:SetTextureOffset(playerData.textureOffset);
	end
	Controls.PlayerLabel:SetText(playerData.label or playerData.name);
end
LuaEvents.IGE_Update.Add(OnUpdate);

-------------------------------------------------------------------------------------------------
local function OnClosePlayerSelection()
	SetTab(currentTabID);
end
LuaEvents.IGE_ClosePlayerSelection.Add(OnClosePlayerSelection);

-------------------------------------------------------------------------------------------------
local function OnOpenPlayerSelectionClick()
	if currentPanelID == "PLAYER_SELECTION" then
		SetTab(currentTabID);
	else
		SetTab("PLAYER_SELECTION");
	end
end
Controls.PlayerButton:RegisterCallback(Mouse.eLClick, OnOpenPlayerSelectionClick);

