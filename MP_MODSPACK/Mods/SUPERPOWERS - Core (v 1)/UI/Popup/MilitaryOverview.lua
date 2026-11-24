-------------------------------------------------
-- Military
-------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );

local m_MilitaryIM = InstanceManager:new( "UnitInstance", "Root", Controls.MilitaryStack );
local m_CivilianIM = InstanceManager:new( "UnitInstance", "Root", Controls.CivilianStack );

local m_SortTable;
local eName     = 0;
local eStatus   = 1;
local eMovement = 2;
local eMoves    = 3;
local eStrength = 4;
local eRanged   = 5;

local m_SortMode = eName;
local m_bSortReverse = false;

local m_PopupInfo = nil;

-- Set true to write unhandled input messages to Lua.log (to find your mouse side button code)
local DEBUG_INPUT = false;


-------------------------------------------------
-- Open / Close Animation Settings
-------------------------------------------------
local FADE_TIME      = 0.25;  -- seconds for the fade (in and out)
local SLIDE_DURATION = 0.30;  -- seconds for the slide (in and out)
local SLIDE_DISTANCE = 40;    -- pixels travelled. Positive = slides up from below,
                              -- negative = slides down from above, 0 = no slide.

-- Resting Y offset of the main panel. Must match the Offset="0,36" on MainGrid in the XML.
local PANEL_BASE_Y   = 36;

-- Guard against bad config values
FADE_TIME      = math.max( FADE_TIME or 0, 0 );
SLIDE_DURATION = math.max( SLIDE_DURATION or 0, 0 );
SLIDE_DISTANCE = SLIDE_DISTANCE or 0;

local MAX_FRAME_DT = 0.05;    -- clamp per-frame time step so a lag spike can't skip the animation

-- UI-only state. Nothing here touches game state, so it is safe in multiplayer / hotseat.
local m_Fade       = 1;       -- current fade progress  (0 = hidden, 1 = shown)
local m_Slide      = 1;       -- current slide progress (0 = offset, 1 = at rest)
local m_AnimTarget = 1;       -- 1 = opening, 0 = closing
local m_bClosing   = false;

local function Ease( t )
    return t * t * (3 - 2 * t);   -- smoothstep
end

local function Step( value, target, dt, duration )
    if duration <= 0 then
        return target;
    end
    if value < target then
        return math.min( value + dt / duration, target );
    else
        return math.max( value - dt / duration, target );
    end
end

local function ApplyAnimation()
    local fade = Ease( m_Fade );
    Controls.BGBlock:SetAlpha( fade );
    Controls.MainGrid:SetAlpha( fade );
    if SLIDE_DISTANCE ~= 0 then
        Controls.MainGrid:SetOffsetVal( 0, PANEL_BASE_Y + SLIDE_DISTANCE * (1 - Ease( m_Slide )) );
    end
end

-- Per-frame update. Only registered while an animation is running.
local function OnUpdate( fDTime )
    local dt = math.min( math.max( fDTime or 0, 0 ), MAX_FRAME_DT );
    m_Fade  = Step( m_Fade,  m_AnimTarget, dt, FADE_TIME );
    m_Slide = Step( m_Slide, m_AnimTarget, dt, SLIDE_DURATION );
    ApplyAnimation();

    if m_Fade == m_AnimTarget and m_Slide == m_AnimTarget then
        ContextPtr:ClearUpdate();            -- idle: no per-frame cost
        if m_bClosing then
            m_bClosing = false;
            UIManager:DequeuePopup( ContextPtr );
        end
    end
end

-- target: 1 = animate in, 0 = animate out. Continues from the current values, so reversing mid-animation is seamless.
local function StartAnimation( target )
    m_AnimTarget = target;
    m_bClosing   = (target == 0);
    ContextPtr:SetUpdate( OnUpdate );
end


-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )
	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_MILITARY_OVERVIEW ) then
    	m_PopupInfo = popupInfo;
    	
    	if( m_bClosing ) then
    	    StartAnimation( 1 );
    	    return;
    	end
    	
		if( m_PopupInfo.Data1 == 1 ) then
        	if( ContextPtr:IsHidden() == false ) then
        	    OnClose();
            else
            	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
        	end
    	else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.MilitaryOverview );
    	end
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Close (animated)
-------------------------------------------------------------------------------
function OnClose()
    if m_bClosing or ContextPtr:IsHidden() then
        return;
    end
    if FADE_TIME <= 0 and SLIDE_DURATION <= 0 then
        UIManager:DequeuePopup( ContextPtr );
        return;
    end
    StartAnimation( 0 );
end

-- Close with no animation (e.g. active player changed in hotseat)
function OnCloseImmediate()
    m_bClosing = false;
    ContextPtr:ClearUpdate();
    UIManager:DequeuePopup( ContextPtr );
end

Controls.CloseButton:RegisterCallback( Mouse.eLClick, function() OnClose(); end );

-- Right click on the panel or outside it closes the screen
local function OnRightClick() OnClose(); end
Controls.PanelCatcher:RegisterCallback( Mouse.eRClick, OnRightClick );
Controls.OutsideCatcher:RegisterCallback( Mouse.eRClick, OnRightClick );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local eKeyDown     = KeyEvents.KeyDown;
local eMouseMove   = MouseEvents.MouseMove;
local eRButtonUp   = MouseEvents.RButtonUp;
local eXButtonUp   = MouseEvents.XButtonUp;          -- may be nil in this engine
local eBrowserBack = Keys.VK_BROWSER_BACK;           -- may be nil
local eBrowserFwd  = Keys.VK_BROWSER_FORWARD;        -- may be nil

function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == eMouseMove then
        return false;
    end

    if uiMsg == eKeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN
        or wParam == 5 or wParam == 6                       -- mouse side buttons as VK_XBUTTON1/2
        or (eBrowserBack ~= nil and wParam == eBrowserBack)
        or (eBrowserFwd  ~= nil and wParam == eBrowserFwd) then
            OnClose();
            return true;
        end
    elseif uiMsg == eRButtonUp or (eXButtonUp ~= nil and uiMsg == eXButtonUp) then
        OnClose();
        return true;
    end

    if DEBUG_INPUT then
        print( "MilitaryOverview input: uiMsg=" .. tostring(uiMsg) .. " wParam=" .. tostring(wParam) );
    end
    return false;
end
ContextPtr:SetInputHandler( InputHandler );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function UnitClicked(unitID)
    local pSelectedUnit = UI:GetHeadSelectedUnit();
    if( pSelectedUnit ~= nil and
        pSelectedUnit:GetID() == unitID ) then
        UI.LookAtSelectionPlot(0);
    else
	    Events.SerialEventUnitFlagSelected( Game:GetActivePlayer(), unitID );
    end
end
        

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function UpdateScreen()

    local iPlayer = Game.GetActivePlayer();
    local pPlayer = Players[ iPlayer ];
    
    --------------------------------------------------------
    -- Great General Progress
    local fThreshold = pPlayer:GreatGeneralThreshold();
    local fProgress  = pPlayer:GetCombatExperience();
    Controls.GPMeter:SetPercent( fProgress / fThreshold );
    Controls.GPBox:LocalizeAndSetToolTip( "TXT_KEY_MO_GENERAL_TT", fProgress, fThreshold );
    
    --------------------------------------------------------
    -- Great Admiral Progress
    fThreshold = pPlayer:GreatAdmiralThreshold();
    fProgress  = pPlayer:GetNavalCombatExperience();
    Controls.GAMeter:SetPercent( fProgress / fThreshold );
    Controls.GABox:LocalizeAndSetToolTip( "TXT_KEY_MO_ADMIRAL_TT", fProgress, fThreshold );
    
    --------------------------------------------------------
    -- Supply Details
    Controls.HandicapSupplyValue:SetText(   pPlayer:GetNumUnitsSuppliedByHandicap() );
    Controls.CitiesSupplyValue:SetText(     pPlayer:GetNumUnitsSuppliedByCities() );
    Controls.PopulationSupplyValue:SetText( pPlayer:GetNumUnitsSuppliedByPopulation() );
    Controls.SupplyCapValue:SetText(        pPlayer:GetNumUnitsSupplied() );
    Controls.SupplyUseValue:SetText(        pPlayer:GetNumUnits() );
    
    local iSupplyDeficit = pPlayer:GetNumUnitsOutOfSupply();
    local bInDeficit = (iSupplyDeficit ~= 0 );
    
    if( not bInDeficit ) then
		Controls.SupplyRemainingValue:SetText( pPlayer:GetNumUnitsSupplied() - pPlayer:GetNumUnits() );
    else
	    Controls.SupplyDeficitValue:SetText( iSupplyDeficit );
	    Controls.SupplyDeficitPenaltyValue:SetText( pPlayer:GetUnitProductionMaintenanceMod() .. "%" );
    end
    
    Controls.SupplyRemaining:SetHide( bInDeficit );
    Controls.SupplyDeficit:SetHide( not bInDeficit );
    Controls.DeficitPenalty:SetHide( not bInDeficit );
    
    
    --------------------------------------------------------
    -- Unit List
    BuildUnitList();
end

    
--------------------------------------------------------
--------------------------------------------------------
function BuildUnitList()

    m_SortTable = {};
    
    local iPlayer = Game.GetActivePlayer();
    local pPlayer = Players[ iPlayer ];
    
    local bFoundMilitary = false;
    local bFoundCivilian = false;
    
    local pSelectedUnit = UI:GetHeadSelectedUnit();
    local iSelectedUnit = -1;
    if( pSelectedUnit ~= nil ) then
        iSelectedUnit = pSelectedUnit:GetID();
    end
    
    m_MilitaryIM:ResetInstances();
    m_CivilianIM:ResetInstances();
    
    for unit in pPlayer:Units()
    do
        local instance;
        local iUnit = unit:GetID();
        
        if( unit:GetUnitCombatType() ~= -1 or unit:CanNuke()) then
            instance = m_MilitaryIM:GetInstance();
            bFoundMilitary = true;
        else
            instance = m_CivilianIM:GetInstance();
            bFoundCivilian = true;
        end
        
        local sortEntry = {};
        m_SortTable[ tostring( instance.Root ) ] = sortEntry;
        
        instance.Button:RegisterCallback( Mouse.eLClick, UnitClicked );
        instance.Button:RegisterCallback( Mouse.eRClick, OnRightClick );
        instance.Button:SetVoid1( unit:GetID() );
        
        sortEntry.DisplayName = Locale.Lookup(unit:GetNameKey());
        instance.UnitName:SetText( sortEntry.DisplayName );
        
        if( unit:MovesLeft() > 0 ) then
            instance.Button:SetAlpha( 1.0 );
        else
            instance.Button:SetAlpha( 0.6 );
        end
        
        instance.SelectionFrame:SetHide( not (iSelectedUnit == iUnit) );
       
        sortEntry.hasPromotion = unit:CanPromote(); 
        instance.PromotionIndicator:SetHide( not sortEntry.hasPromotion );

        ---------------------------------------------------------
        -- Status field
        local buildType = unit:GetBuildType();
        local activityType = unit:GetActivityType();
        if( unit:IsEmbarked() ) then
            sortEntry.status = "TXT_KEY_UNIT_STATUS_EMBARKED";
            instance.Status:SetHide( false );
                        
        elseif( unit:IsGarrisoned()) then
			sortEntry.status = "TXT_KEY_MISSION_GARRISON";
            instance.Status:SetHide( false );
            
        elseif( unit:IsAutomated()) then
			if(unit:IsWork()) then
				sortEntry.status = "TXT_KEY_ACTION_AUTOMATE_BUILD";
				instance.Status:SetHide( false );
			else
				sortEntry.status = "TXT_KEY_ACTION_AUTOMATE_EXPLORE";
				instance.Status:SetHide( false );
			end
					
		elseif( activityType == ActivityTypes.ACTIVITY_HEAL ) then
			sortEntry.status = "TXT_KEY_MISSION_HEAL";
			instance.Status:SetHide( false );
			
		elseif( activityType == ActivityTypes.ACTIVITY_SENTRY ) then
			sortEntry.status = "TXT_KEY_MISSION_ALERT";
			instance.Status:SetHide( false );
			
        elseif( unit:GetFortifyTurns() > 0 ) then
            sortEntry.status = "TXT_KEY_UNIT_STATUS_FORTIFIED";
            instance.Status:SetHide( false );
            
        elseif( activityType == ActivityTypes.ACTIVITY_SLEEP ) then
			sortEntry.status = "TXT_KEY_MISSION_SLEEP";
			instance.Status:SetHide( false );
            
        elseif( buildType ~= -1) then -- this is a worker who is actively building something
    		local thisBuild = GameInfo.Builds[buildType];
    		local civilianUnitStr = Locale.ConvertTextKey(thisBuild.Description);
    		local iTurnsLeft = unit:GetPlot():GetBuildTurnsLeft(buildType,Game.GetActivePlayer(), 0, 0);	
    		local iTurnsTotal = unit:GetPlot():GetBuildTurnsTotal(buildType);	
    		if (iTurnsLeft < 4000 and iTurnsLeft > 0) then
    			civilianUnitStr = civilianUnitStr.." ("..tostring(iTurnsLeft)..")";
    		end
            sortEntry.status = civilianUnitStr;
            instance.Status:SetHide( false );
            
    	else
            sortEntry.status = nil;
            instance.Status:SetHide( true );
        end
        if( sortEntry.status ~= nil ) then
            instance.Status:LocalizeAndSetText( sortEntry.status );
        else
            instance.Status:SetText( "" );
        end
        
               
	    local move_denominator = GameDefines["MOVE_DENOMINATOR"];
	    local moves_left = math.floor(unit:MovesLeft() / move_denominator);
	    local max_moves = math.floor(unit:MaxMoves() / move_denominator);
	    
        if( moves_left == max_moves ) then
            instance.MovementPip:SetTextureOffsetVal( 0, 0 );
        elseif( moves_left == 0 ) then
            instance.MovementPip:SetTextureOffsetVal( 0, 96 );
        else
            instance.MovementPip:SetTextureOffsetVal( 0, 32 );
        end
	    
        sortEntry.movement = moves_left;
        sortEntry.moves = max_moves;
        instance.Movement:SetText( moves_left .. "/" .. max_moves );
        
        sortEntry.strength = unit:GetBaseCombatStrength();
        if( sortEntry.strength == 0 ) then
            instance.Strength:SetText( "-" );
        else
            instance.Strength:SetText( sortEntry.strength );
        end
        
        sortEntry.ranged = unit:GetBaseRangedCombatStrength();
        if( sortEntry.ranged == 0 ) then
            instance.RangedAttack:SetText( "-" );
        else
            instance.RangedAttack:SetText( sortEntry.ranged );
        end
        
        sortEntry.unit = unit;
    end

    if( bFoundMilitary and bFoundCivilian ) then
        Controls.CivilianSeperator:SetHide( false );
    else
        Controls.CivilianSeperator:SetHide( true );
    end
    
    Controls.MilitaryStack:CalculateSize();
    Controls.CivilianStack:CalculateSize();
    
    Controls.MainStack:CalculateSize();
    Controls.ScrollPanel:CalculateInternalSize();
    
    Controls.ScrollPanel:ReprocessAnchoring();
end


-------------------------------------------------
-------------------------------------------------
function SortFunction( a, b )
    local valueA, valueB;
    local entryA = m_SortTable[ tostring( a ) ];
    local entryB = m_SortTable[ tostring( b ) ];

    if (entryA == nil) or (entryB == nil) then 
		if entryA and (entryB == nil) then
			return false;
		elseif (entryA == nil) and entryB then
			return true;
		else
			if( m_bSortReverse ) then
				return tostring(a) > tostring(b); -- gotta do something deterministic
			else
				return tostring(a) < tostring(b); -- gotta do something deterministic
			end
        end;
    else
		if( m_SortMode == eName ) then
			valueA = entryA.DisplayName;
			valueB = entryB.DisplayName;
		elseif( m_SortMode == eStatus ) then
			valueA = entryA.status or "";
			valueB = entryB.status or "";
			
			if(valueA ~= valueB) then
				if(m_bSortReverse) then
					return Locale.Compare(valueA, valueB) == -1;
				else
					return Locale.Compare(valueA, valueB) == 1;
				end
			end
			
		elseif( m_SortMode == eMovement ) then
			valueA = entryA.movement;
			valueB = entryB.movement;
		elseif( m_SortMode == eMoves ) then
			valueA = entryA.moves;
			valueB = entryB.moves;
		elseif( m_SortMode == eStrength ) then
			valueA = entryA.strength;
			valueB = entryB.strength;
		elseif( m_SortMode == eRanged ) then
			valueA = entryA.ranged;
			valueB = entryB.ranged;
		end
	    
		if( valueA == valueB ) then
			valueA = entryA.unit:GetID();
			valueB = entryB.unit:GetID();
		end
	   
		if( m_bSortReverse ) then
			return valueA > valueB;
		else
			return valueA < valueB;
		end
	end
end


-------------------------------------------------
-------------------------------------------------
function OnSort( type )
    if( m_SortMode == type ) then
        m_bSortReverse = not m_bSortReverse;
    else
        m_bSortReverse = false;
    end
    
    m_SortMode = type;
    Controls.MilitaryStack:SortChildren( SortFunction );
    Controls.CivilianStack:SortChildren( SortFunction );
end
Controls.SortName:RegisterCallback( Mouse.eLClick, OnSort );
Controls.SortStatus:RegisterCallback( Mouse.eLClick, OnSort );
Controls.SortMovement:RegisterCallback( Mouse.eLClick, OnSort );
Controls.SortMoves:RegisterCallback( Mouse.eLClick, OnSort );
Controls.SortStrength:RegisterCallback( Mouse.eLClick, OnSort );
Controls.SortRanged:RegisterCallback( Mouse.eLClick, OnSort );
Controls.SortName:SetVoid1( eName );
Controls.SortStatus:SetVoid1( eStatus );
Controls.SortMovement:SetVoid1( eMovement );
Controls.SortMoves:SetVoid1( eMoves );
Controls.SortStrength:SetVoid1( eStrength );
Controls.SortRanged:SetVoid1( eRanged );

        
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

	-- Set player icon at top of screen
	CivIconHookup( 0, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
    UpdateScreen();

    if( not bInitState ) then
        if( not bIsHide ) then
        	m_Fade = 0; m_Slide = 0;
        	ApplyAnimation();
        	StartAnimation( 1 );
        	UI.incTurnTimerSemaphore();
			m_bSortReverse = not m_bSortReverse;
        	OnSort( m_SortMode );
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
            m_bClosing = false;
            ContextPtr:ClearUpdate();
            m_Fade = 1; m_Slide = 1;
            ApplyAnimation();
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_MILITARY_OVERVIEW, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(OnCloseImmediate);