-- Released under GPL v3
--------------------------------------------------------------
print("IGE_ConfirmPopup");

local yesCallback = nil;

function OnYes()
	ContextPtr:SetHide(true);
	UIManager:DequeuePopup(ContextPtr);
	yesCallback();
end
Controls.Yes:RegisterCallback(Mouse.eLClick, OnYes);

function OnNo()
	ContextPtr:SetHide(true);
	UIManager:DequeuePopup(ContextPtr);
end
Controls.No:RegisterCallback(Mouse.eLClick, OnNo);

function OnPopup(text, _yesCallback)
	yesCallback = _yesCallback;
	Controls.Message:SetText(text);
	UIManager:QueuePopup(ContextPtr, PopupPriority.eUtmost);
	ContextPtr:SetHide(false);
end
LuaEvents.IGE_ConfirmPopup.Add(OnPopup);

function OnInput(uiMsg, wParam, lParam)
	if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
			OnNo();
            return true;
        end
    end
end
ContextPtr:SetInputHandler(OnInput);

