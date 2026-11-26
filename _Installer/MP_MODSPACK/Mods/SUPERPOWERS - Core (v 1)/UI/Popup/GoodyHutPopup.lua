-------------------------------------------------
-- Goody Hut Popup
-- Shows the reward as an on-screen alert instead of a popup
-------------------------------------------------

-------------------------------------------------
-- On Display
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_GOODY_HUT_REWARD ) then
		return;
	end

	local iGoodyType = popupInfo.Data1;
	local pGoodyInfo = GameInfo.GoodyHuts[iGoodyType];

	local strText = "";

	if (pGoodyInfo.Type == "GOODY_GOLD" or pGoodyInfo.Type == "GOODY_CULTURE" or pGoodyInfo.Type == "GOODY_PANTHEON_FAITH" or pGoodyInfo.Type == "GOODY_PROPHET_FAITH") then
		-- These rewards include an amount in their text
		strText = Locale.ConvertTextKey(pGoodyInfo.Description, popupInfo.Data2);
	else
		strText = Locale.ConvertTextKey(pGoodyInfo.Description);
	end

	Events.GameplayAlertMessage(strText);

	-- Tell the game the popup has been dealt with
	Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_GOODY_HUT_REWARD, 0);
end
Events.SerialEventGameMessagePopup.Add( OnPopup );