-- Released under GPL v3
--------------------------------------------------------------
print("loaded");

function OnMinimapClick(_, _, _, x, y )
    Events.MinimapClickedEvent(x, y);
end
Controls.Minimap:RegisterCallback( Mouse.eLClick, OnMinimapClick );

-------------------------------------------------------------------------------------------------
function OnStrategicViewClick()
    ToggleStrategicView();
end
Controls.StrategicViewButton:RegisterCallback(Mouse.eLClick, OnStrategicViewClick);

-------------------------------------------------------------------------------------------------
local function OnStrategicViewStateChanged(bStrategicView)
	if bStrategicView then
		Controls.StrategicViewButton:SetTexture( "assets/UI/Art/Icons/MainWorldButton.dds" );
		Controls.StrategicMO:SetTexture( "assets/UI/Art/Icons/MainWorldButton.dds" );
		Controls.StrategicHL:SetTexture( "assets/UI/Art/Icons/MainWorldButtonHL.dds" );
	else
		Controls.StrategicViewButton:SetTexture( "assets/UI/Art/Icons/MainStrategicButton.dds" );
		Controls.StrategicMO:SetTexture( "assets/UI/Art/Icons/MainStrategicButton.dds" );
		Controls.StrategicHL:SetTexture( "assets/UI/Art/Icons/MainStrategicButtonHL.dds" );
	end
end
Events.StrategicViewStateChanged.Add(OnStrategicViewStateChanged);

-------------------------------------------------------------------------------------------------
local function OnMinimapInfo( uiHandle, width, height, paddingX )
    Controls.Minimap:SetTextureHandle( uiHandle );
    Controls.Minimap:SetSizeVal( width, height );
end



--===============================================================================================
-- HOOKS
--===============================================================================================
local function OnShowing()
	Events.MinimapTextureBroadcastEvent.Add(OnMinimapInfo);
	UI:RequestMinimapBroadcast();
end
LuaEvents.IGE_Showing.Add(OnShowing);

-------------------------------------------------------------------------------------------------
local function OnClosing()
	Events.MinimapTextureBroadcastEvent.Remove(OnMinimapInfo);
end
LuaEvents.IGE_Closing.Add(OnClosing);


