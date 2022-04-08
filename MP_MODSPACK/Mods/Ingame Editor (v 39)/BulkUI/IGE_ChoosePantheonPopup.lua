include( "IconSupport" );
include( "InstanceManager" );

-- Used for Piano Keys
local ltBlue = {19/255,32/255,46/255,120/255};
local dkBlue = {12/255,22/255,30/255,120/255};

local g_ItemManager = InstanceManager:new( "ItemInstance", "Button", Controls.ItemStack );
local bHidden = true;

local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal()
local spWidth, spHeight = Controls.ItemScrollPanel:GetSizeVal();

-- Original UI designed at 1050px 
local heightOffset = screenSizeY - 1020;

spHeight = spHeight + heightOffset;
Controls.ItemScrollPanel:SetSizeVal(spWidth, spHeight); 
Controls.ItemScrollPanel:CalculateInternalSize();
Controls.ItemScrollPanel:ReprocessAnchoring();

local g_player;
local bpWidth, bpHeight = Controls.BottomPanel:GetSizeVal();
bpHeight = bpHeight + heightOffset 

Controls.BottomPanel:SetSizeVal(bpWidth, bpHeight);
Controls.BottomPanel:ReprocessAnchoring();


-------------------------------------------------------------------------------------------------
function OnPopupMessage(player)
	g_player = player;
   	UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy );
end
LuaEvents.IGE_ChoosePantheonPopup.Add(OnPopupMessage);

-------------------------------------------------------------------------------------------------
function OnClose()
	g_player = nil;
    UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

-------------------------------------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if (wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE) then
			if(Controls.ChooseConfirm:IsHidden())then
	            OnClose();
	        else
				Controls.ChooseConfirm:SetHide(true);
           	end
			return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------------------------
function RefreshList()
	g_ItemManager:ResetInstances();
		
	local pPlayer = g_player;
	CivIconHookup( pPlayer:GetID(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
	
	local availablePantheonBeliefs = {};
	for i,v in ipairs(Game.GetAvailablePantheonBeliefs()) do
		local belief = GameInfo.Beliefs[v];
		if(belief ~= nil) then
			table.insert(availablePantheonBeliefs, {
				ID = belief.ID,
				Name = Locale.Lookup(belief.ShortDescription),
				Description = Locale.Lookup(belief.Description),
			});
		end
	end
		
	-- Sort pantheons by their description.
	table.sort(availablePantheonBeliefs, function(a,b) return Locale.Compare(a.Name, b.Name) < 0; end);
	
	local bTickTock = false;
	for i, pantheon in ipairs(availablePantheonBeliefs) do
		local itemInstance = g_ItemManager:GetInstance();
		itemInstance.Name:SetText(pantheon.Name);
		--itemInstance.Button:SetToolTipString(pantheon.Description);
		itemInstance.Description:SetText(pantheon.Description);
		
		itemInstance.Button:RegisterCallback(Mouse.eLClick, function() SelectPantheon(pantheon.ID); end);
	
		if(bTickTock == false) then
			itemInstance.Box:SetColorVal(unpack(ltBlue));
		else
			itemInstance.Box:SetColorVal(unpack(dkBlue));
		end
		
		local buttonWidth, buttonHeight = itemInstance.Button:GetSizeVal();
		local descWidth, descHeight = itemInstance.Description:GetSizeVal();
		
		local newHeight = descHeight + 40;	
	
		
		itemInstance.Button:SetSizeVal(buttonWidth, newHeight);
		itemInstance.Box:SetSizeVal(buttonWidth + 20, newHeight);
		itemInstance.BounceAnim:SetSizeVal(buttonWidth + 20, newHeight + 5);
		itemInstance.BounceGrid:SetSizeVal(buttonWidth + 20, newHeight + 5);
		
				
		bTickTock = not bTickTock;
	end
	
	Controls.ItemStack:CalculateSize();
	Controls.ItemStack:ReprocessAnchoring();
	Controls.ItemScrollPanel:CalculateInternalSize();
end

-------------------------------------------------------------------------------------------------
function SelectPantheon(beliefID) 
	g_BeliefID = beliefID;
	local belief = GameInfo.Beliefs[beliefID];
	Controls.ConfirmText:LocalizeAndSetText("TXT_KEY_CONFIRM_PANTHEON", belief.ShortDescription);
	Controls.ChooseConfirm:SetHide(false);
end

-------------------------------------------------------------------------------------------------
function OnYes( )
	Controls.ChooseConfirm:SetHide(true);
	
	Game.FoundPantheon(g_player:GetID(), g_BeliefID);
	Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");	
	LuaEvents.IGE_Update();
	
	OnClose();	
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );

-------------------------------------------------------------------------------------------------
function OnNo( )
	Controls.ChooseConfirm:SetHide(true);
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );

-------------------------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
	bHidden = bIsHide;
    if( not bInitState ) then
        if( not bIsHide ) then
			Controls.IGE_LeftDecor:SetTexture("LeftPortraitDecor128.dds");
			Controls.IGE_LeftDecorImage:SetTexture("NotificationPantheon128.dds");
			Controls.CivIcon:SetTexture("CivSymbolsColor512.dds");
			Controls.IGE_ConfirmIconAlpha:SetTexture("NotificationPantheon80.dds");
        	RefreshList();
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

-------------------------------------------------------------------------------------------------
function OnActivePlayerChanged()
	if (not Controls.ChooseConfirm:IsHidden()) then
		Controls.ChooseConfirm:SetHide(true);
    end
	OnClose();
end
LuaEvents.IGE_SelectedPlayer.Add(OnActivePlayerChanged);
