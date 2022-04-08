-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
include("IGE_API_Rivers");
include("IGE_API_Terrain");
print("IGE_RiversElement");
IGE = nil

local currentPlot = nil;
local riverButtonTexture = "Art\\IgeTile256Base.dds";
local riverButtonTextureCW = "Art\\IgeTile256CW.dds";
local riverButtonTextureCCW = "Art\\IgeTile256CCW.dds";

-------------------------------------------------------------------------------------------------
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function UpdateRiverStatus(button, plot, side)
	if plot then 
		local rotation = GetFlowRotation(plot, side);

		if rotation == CWRotation then
			button:SetTexture(riverButtonTextureCW);
		elseif rotation == CCWRotation then
			button:SetTexture(riverButtonTextureCCW);
		else
			button:SetTexture(riverButtonTexture);
		end
	else
		button:SetTexture(riverButtonTexture);
	end
end

-------------------------------------------------------------------------------------------------
function Update()
	if currentPlot then
		UpdateRiverStatus(Controls.River_NW_Img, currentPlot, "NW");
		UpdateRiverStatus(Controls.River_NE_Img, currentPlot, "NE");
		UpdateRiverStatus(Controls.River_W_Img, currentPlot, "W");
		UpdateRiverStatus(Controls.River_E_Img, currentPlot, "E");
		UpdateRiverStatus(Controls.River_SW_Img, currentPlot, "SW");
		UpdateRiverStatus(Controls.River_SE_Img, currentPlot, "SE");

		Controls.RiverVertex_N:SetHide(not IsRiverEntryPoint(currentPlot, "N"));
		Controls.RiverVertex_NW:SetHide(not IsRiverEntryPoint(currentPlot, "NW"));
		Controls.RiverVertex_NE:SetHide(not IsRiverEntryPoint(currentPlot, "NE"));
		Controls.RiverVertex_SW:SetHide(not IsRiverEntryPoint(currentPlot, "SW"));
		Controls.RiverVertex_SE:SetHide(not IsRiverEntryPoint(currentPlot, "SE"));
		Controls.RiverVertex_S:SetHide(not IsRiverEntryPoint(currentPlot, "S"));
	end
end
LuaEvents.IGE_Update.Add(Update);

-------------------------------------------------------------------------------------------------
function ToggleRiver(side)
	local backup = BackupPlot(currentPlot);
	ToggleRiverFlow(currentPlot, side);
	LuaEvents.IGE_PushUndoStack({ backup });
	LuaEvents.IGE_ModifiedPlot(currentPlot);

	for neighbor in Neighbors(currentPlot) do
		LuaEvents.IGE_ModifiedPlot(neighbor);
	end
	Update();
end

Controls.River_W:RegisterCallback(Mouse.eLClick,  function() ToggleRiver("W") end);
Controls.River_NW:RegisterCallback(Mouse.eLClick, function() ToggleRiver("NW") end);
Controls.River_NE:RegisterCallback(Mouse.eLClick, function() ToggleRiver("NE") end);
Controls.River_E:RegisterCallback(Mouse.eLClick,  function() ToggleRiver("E") end);
Controls.River_SE:RegisterCallback(Mouse.eLClick, function() ToggleRiver("SE") end);
Controls.River_SW:RegisterCallback(Mouse.eLClick, function() ToggleRiver("SW") end);
--Controls.RiverBox:SetToolTipCallback(function() ToolTipHandler(river) end);

-------------------------------------------------------------------------------------------------
function OnSelectedPlot(plot)
	currentPlot = plot;
	Update();
end
LuaEvents.IGE_SelectedPlot.Add(OnSelectedPlot)
