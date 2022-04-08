include( "InstanceManager" );

local g_instanceMap = {};
local g_InstanceManager = InstanceManager:new( "AlertMessageInstance", "AlertMessageLabel", Controls.AlertStack );
local g_PopupIM = InstanceManager:new( "PopupText", "Anchor", Controls.PopupTextContainer );

local alertTable = {};
local mustRefreshAlerts = false;


-------------------------------------------------------------------------------------------------
function AddPopupText( worldPosition, text, delay )
    local instance = g_PopupIM:GetInstance();
    instance.Anchor:SetWorldPosition( worldPosition );
    instance.Text:SetText( text );
    instance.AlphaAnimOut:RegisterAnimCallback( KillPopupText );
    instance.Anchor:BranchResetAnimation();
    instance.SlideAnim:SetPauseTime( delay );
    instance.AlphaAnimIn:SetPauseTime( delay );
    instance.AlphaAnimOut:SetPauseTime( delay + 0.75 );
    
    g_InstanceMap[ tostring( instance.AlphaAnimOut ) ] = instance;
end
--Events.AddPopupTextEvent.Add( AddPopupText );

-------------------------------------------------------------------------------------------------
function KillPopupText( control )

	local szKey = tostring( control );
    local instance = g_InstanceMap[ szKey ];
    
    if( instance == nil ) then
        print( "Error killing popup text" );
    else
        g_PopupIM:ReleaseInstance( instance );
        g_InstanceMap[ szKey ] = null;
    end
end

-------------------------------------------------------------------------------------------------
function KillAllPopupText( )

	for i, v in pairs(g_InstanceMap) do
		if (v ~= nil) then
	        g_PopupIM:ReleaseInstance( v );
		end
	end
	g_InstanceMap = {};
end

-------------------------------------------------------------------------------------------------
function OnGameplayAlertMessage( text )
	local newAlert = {};
	newAlert.text = text;
	newAlert.elapsedTime = 0;
	newAlert.shownYet = false;
	table.insert(alertTable,newAlert);
	mustRefreshAlerts = true;
end
--Events.GameplayAlertMessage.Add( OnGameplayAlertMessage );
LuaEvents.IGE_FloatingMessage.Add(OnGameplayAlertMessage)

-------------------------------------------------------------------------------------------------
function OnUpdate(fDTime)

	if #alertTable > 0 then
		for i, v in ipairs( alertTable ) do
			if v.shownYet == true then
				v.elapsedTime = v.elapsedTime + fDTime;
			end
			if v.elapsedTime >= 8 then
				mustRefreshAlerts = true;
			end
		end
		
		if mustRefreshAlerts then
			local newAlertTable = {};
			g_InstanceManager:ResetInstances();
			for i, v in ipairs( alertTable ) do
				if v.elapsedTime < 8 then
					v.shownYet = true;
					table.insert( newAlertTable, v );
				end
			end
			alertTable = newAlertTable;
			for i, v in ipairs( alertTable ) do
				local controlTable = g_InstanceManager:GetInstance();
				controlTable.AlertMessageLabel:SetText( v.text );
				Controls.AlertStack:CalculateSize();
				Controls.AlertStack:ReprocessAnchoring();
			end
		end

	end
	
	mustRefreshAlerts = false;
	
end
ContextPtr:SetUpdate( OnUpdate );
