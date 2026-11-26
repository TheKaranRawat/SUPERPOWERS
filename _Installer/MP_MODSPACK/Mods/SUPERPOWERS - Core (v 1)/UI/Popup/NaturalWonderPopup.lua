-------------------------------------------------
-- Natural Wonder Popup (replaced with alert message)
-- Never shows a popup; prints an on-screen alert instead.
-------------------------------------------------

local POPUP_TYPE = ButtonPopupTypes.BUTTONPOPUP_NATURAL_WONDER_REWARD;

-- Plots already announced, so a repeated event can't spam alerts
local m_Announced = {};

-------------------------------------------------
-- Tell the engine this popup is "done" so its popup queue never stalls
-------------------------------------------------
local function MarkProcessed()
	Events.SerialEventGameMessagePopupProcessed.CallImmediate( POPUP_TYPE, 0 );
end

-------------------------------------------------
-- On popup request
-------------------------------------------------
function OnPopup( popupInfo )

	if popupInfo.Type ~= POPUP_TYPE then
		return;
	end

	local x = popupInfo.Data1;
	local y = popupInfo.Data2;
	local iFinderGold = popupInfo.Data3 or 0;

	-- Local UI only: read-only lookups, no gameplay state touched (MP safe)
	local plot = Map.GetPlot( x, y );
	if plot then
		local plotKey = x .. "," .. y;
		if not m_Announced[plotKey] then
			m_Announced[plotKey] = true;

			local info = GameInfo.Features[ plot:GetFeatureType() ];
			if info and info.NaturalWonder then
				local msg = Locale.ConvertTextKey( "TXT_KEY_POP_NATURAL_WONDER_FOUND" )
					.. " " .. Locale.ConvertTextKey( info.Description );
				if iFinderGold > 0 then
					msg = msg .. " (+" .. iFinderGold .. " [ICON_GOLD])";
				end
				Events.GameplayAlertMessage( msg );
			end
		end
	end

	-- Never queue the popup; release the engine's pending popup slot
	MarkProcessed();
end
Events.SerialEventGameMessagePopup.Add( OnPopup );

-------------------------------------------------
-- Reset de-dupe cache when the active player changes (hotseat / new game)
-------------------------------------------------
function OnActivePlayerChanged()
	m_Announced = {};
end
Events.GameplaySetActivePlayer.Add( OnActivePlayerChanged );