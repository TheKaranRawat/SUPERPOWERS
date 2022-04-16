-- Lua Script1
-- Author: robk
-- DateCreated: 10/7/2010 10:35:53 PM
--------------------------------------------------------------

include("InfoAddictLib");
include("IconSupport");




-- Main function to select panels, called by the OnStuff() functions
-- below.

function PanelSelector(panel)

 
	if (panel == "trading") then
    Controls.TradeOpsSelectHighlight:SetHide(false);
    Controls.TradeOpsPanel:SetHide(false);
  else
    Controls.TradeOpsSelectHighlight:SetHide(true);
    Controls.TradeOpsPanel:SetHide(true);
  end;
  

  if (panel == "relations") then
    Controls.CivRelationsSelectHighlight:SetHide(false);
    Controls.CivRelationsPanel:SetHide(false);
  else
    Controls.CivRelationsSelectHighlight:SetHide(true);
    Controls.CivRelationsPanel:SetHide(true);
  end;
  
  if (panel == "citystates") then
    Controls.CityStatesSelectHighlight:SetHide(false);
    Controls.CityStatesPanel:SetHide(false);
  else
    Controls.CityStatesSelectHighlight:SetHide(true);
    Controls.CityStatesPanel:SetHide(true);
  end;

  

  

end




-- Display the Civ relations graph panel when the civ relations button
-- is selected.

function OnCivRelations()
  PanelSelector("relations");    
end
Controls.CivRelationsButton:RegisterCallback( Mouse.eLClick, OnCivRelations );

-- Trade Ops panel
function OnTrading()
  PanelSelector("trading");    
end
Controls.TradeOpsButton:RegisterCallback( Mouse.eLClick, OnTrading );

-- City States panel
function OnCityStates()
  PanelSelector("citystates");    
end
Controls.CityStatesButton:RegisterCallback( Mouse.eLClick, OnCityStates );



-- Close it down
-- Depending on how it was opened - Aristos
function OnClose()
	-- If called from within diplo - Aristos
	if UIManager:IsModal(ContextPtr) then
		UIManager:PopModal(ContextPtr);
	-- or from the top panel
	else
		ContextPtr:SetHide(true);
	end
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose);


-- InputHandler: let's hit ESC to close the window.

function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose();
            return true;
		end
    end
end
ContextPtr:SetInputHandler( InputHandler );


local oldCursor = 0;

function OnShowHide( bIsHide ) --, bInitState )
	
  if (not bIsHide) then

    oldCursor = UIManager:SetUICursor(0);   -- remember the cursor state
	--OnCivRelations();
    -- Modify the title if we're in cheat mode
    if (seeEveryone()) then
      Controls.TitleLabel:SetText("Info Addict: Cheat Mode");
    end;

    -- Set player icon at top of screen
	  CivIconHookup( Game.GetActivePlayer(), 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

  else
    UIManager:SetUICursor(oldCursor);  -- restore the cursor state
  end;

end
ContextPtr:SetShowHideHandler( OnShowHide );


-- Trigger the historical panel so that's the default when the panel
-- first pops up.

OnCivRelations();
