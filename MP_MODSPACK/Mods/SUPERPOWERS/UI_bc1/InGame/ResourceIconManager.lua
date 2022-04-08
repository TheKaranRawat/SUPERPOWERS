-------------------------------------------------
-- Resource Icon Manager
-------------------------------------------------
include( "InstanceManager" );
include( "ResourceTooltipGenerator" );
include( "IconSupport" );

local g_MaxResource = 200;
local g_SmallIcons = true;

local g_ResourceManager = InstanceManager:new( "ResourceIcon", "Anchor", Controls.ResourceIconContainer );

local g_ResourceIconOffsetX = -30; -- this is in world space and corresponds to the top-left vertex of the hex
local g_ResourceIconOffsetY = 15;  -- this is in world space and corresponds to the top-left vertex of the hex
local g_ResourceIconOffsetZ = 0;   -- this is in world space and corresponds to the top-left vertex of the hex

local g_bHideResourceIcons = not OptionsManager.GetResourceOn();
local g_bIsStrategicView   = false;

local g_ActiveSet = {};
local g_PerPlayerResourceTables = {};

local g_gridWidth, _ = Map.GetGridSize();
------------------------------------------------------------------
------------------------------------------------------------------
function IndexFromGrid( x, y )
    return x + (y * g_gridWidth);
end

------------------------------------------------------------------
------------------------------------------------------------------
function GridFromIndex( index )
	local y = math.floor(index / g_gridWidth);
    return (index - (y * g_gridWidth)), y;
end

------------------------------------------------------------------
------------------------------------------------------------------
function DestroyResource( index )
    local instance = g_ActiveSet[ index ];
    if ( instance ~= nil ) then
		g_ResourceManager:ReleaseInstance( instance );
        g_ActiveSet[ index ] = nil;
	end
end

-------------------------------------------------
-------------------------------------------------
function BuildResource( index, gridX, gridY, resourceType )

	DestroyResource(index);

	local instance = g_ResourceManager:GetInstance();
    	
	g_ActiveSet[ index ] = instance;
		
	local x, y, z = GridToWorld( gridX, gridY );
	instance.Anchor:SetWorldPositionVal( x + g_ResourceIconOffsetX,
										 y + g_ResourceIconOffsetY,
										 z + g_ResourceIconOffsetZ );
										 										 
	local resourceInfo;
	if (resourceType < g_MaxResource) then
		resourceInfo= GameInfo.Resources[resourceType];
	else
		resourceInfo = GameInfo.Features[resourceType - g_MaxResource];
	end

	IconHookup(resourceInfo.PortraitIndex, 64, resourceInfo.IconAtlas, instance.ResourceIcon);
	IconHookup(resourceInfo.PortraitIndex, 45, resourceInfo.IconAtlas, instance.ResourceIconSmall);
	instance.ResourceFrame:SetHide(g_SmallIcons == true);
	instance.ResourceFrameSmall:SetHide(g_SmallIcons == false);
	
	-- Tool Tip
	local plot = Map.GetPlot( gridX, gridY );
	local strToolTip = GenerateResourceToolTip(plot);
	if( strToolTip ~= nil ) then
		instance.ResourceIcon:SetToolTipString(strToolTip);
		instance.ResourceIconSmall:SetToolTipString(strToolTip);
	end
end

-------------------------------------------------
-------------------------------------------------
function OnResourceAdded( hexPosX, hexPosY, ImprovementType, ResourceType )
	if ResourceType > -1 then
		local gridX, gridY  = ToGridFromHex( hexPosX, hexPosY );
        local plot = Map.GetPlot( gridX, gridY );
		
		----------------SP Hide fish and natrual gas icon, there are too many!!!!!!!-------- 
		if plot:GetImprovementType() >= 0 then
			if ResourceType == GameInfoTypes.RESOURCE_FISH or ResourceType == GameInfoTypes.RESOURCE_NATRUALGAS then
				return
			end	
		end	
		----------------SP Hide fish and natrual gas icon, there are too many!!!!!!  END-------- 

		-- Because we will get this message at load time as well as while the game is
		-- in progress, if this is a hotseat game, add the resource icons for all players
		-- This should be safe to do for a game with a single human, but its a bit slower so we'll keep it separate.
		if ( PreGame.IsHotSeatGame() ) then
			local bIsBuilt = false;
			for iPlayerID = 0, GameDefines.MAX_PLAYERS do
				local pPlayer = Players[iPlayerID];
				if( pPlayer ~= nil and pPlayer:IsHuman() ) then
					if( plot:IsRevealed( pPlayer:GetTeam(), false ) ) then
						-- Build the icon
						local index = IndexFromGrid( gridX, gridY );
						-- Only need to build the resource if the active team can see this
						if( not bIsBuilt and pPlayer:GetTeam() == Game.GetActiveTeam() ) then
							BuildResource( index, gridX, gridY, ResourceType );
							bIsBuilt = true;
						end
						
						-- Store the resource for the player
						if (g_PerPlayerResourceTables[ iPlayerID ] == nil) then
							g_PerPlayerResourceTables[ iPlayerID ] = {};
						end
						
						local playerResourceTable = g_PerPlayerResourceTables[ iPlayerID ];		
						playerResourceTable[index] = ResourceType;
					end
				end
			end
		else
			if( not plot:IsRevealed( Game.GetActiveTeam(), false ) ) then
				return;
			end

			-- Build the icon
			local index = IndexFromGrid( gridX, gridY );
			BuildResource( index, gridX, gridY, ResourceType );
			
			-- Store the resource for the current player
			local iPlayerID = Game.GetActivePlayer();		
			if (g_PerPlayerResourceTables[ iPlayerID ] == nil) then
				g_PerPlayerResourceTables[ iPlayerID ] = {};
			end
			
			local playerResourceTable = g_PerPlayerResourceTables[ iPlayerID ];		
			playerResourceTable[index] = ResourceType;			
		end
    end
end
Events.SerialEventRawResourceIconCreated.Add( OnResourceAdded )

-------------------------------------------------
-------------------------------------------------
function OnResourceRemoved( hexPosX, hexPosY )
	local gridX, gridY  = ToGridFromHex( hexPosX, hexPosY );
    local plot = Map.GetPlot( gridX, gridY );

	if( not plot:IsRevealed( Game.GetActiveTeam(), false ) ) then
		return;
	end

	-- Remove the icon
	local index = IndexFromGrid( gridX, gridY );
	DestroyResource(index);
	
	-- Remove the resource from the current player
	local iPlayerID = Game.GetActivePlayer();		
	
	local playerResourceTable = g_PerPlayerResourceTables[ iPlayerID ];		
	if (g_PerPlayerResourceTables[ iPlayerID ] ~= nil) then
		playerResourceTable[index] = nil;
	end
		
end
Events.SerialEventRawResourceIconDestroyed.Add( OnResourceRemoved )
LuaEvents.SerialEventRawResourceIconDestroyed.Add(OnResourceRemoved)

-------------------------------------------------
-------------------------------------------------
function OnWonderAdded( gridX, gridY, WonderType, bAllPlayers )
	print(string.format("Natural Wonder %d added at (%d, %d)", WonderType, gridX, gridY))

	if WonderType > -1 then
        local plot = Map.GetPlot( gridX, gridY );

		if ( PreGame.IsHotSeatGame() or bAllPlayers ) then
			local bIsBuilt = false;
			for iPlayerID = 0, GameDefines.MAX_PLAYERS do
				local pPlayer = Players[iPlayerID];
				if( pPlayer ~= nil and pPlayer:IsHuman() ) then
					if( plot:IsRevealed( pPlayer:GetTeam(), false ) ) then
						-- Build the icon
						local index = IndexFromGrid( gridX, gridY );
						-- Only need to build the wonder if the active team can see this
						if( not bIsBuilt and pPlayer:GetTeam() == Game.GetActiveTeam() ) then
							BuildResource( index, gridX, gridY, WonderType + g_MaxResource);
							bIsBuilt = true;
						end
						
						-- Store the wonder for the player
						if (g_PerPlayerResourceTables[ iPlayerID ] == nil) then
							g_PerPlayerResourceTables[ iPlayerID ] = {};
						end
						
						local playerResourceTable = g_PerPlayerResourceTables[ iPlayerID ];		
						playerResourceTable[index] = WonderType + g_MaxResource;
					end
				end
			end
		else
			if( not plot:IsRevealed( Game.GetActiveTeam(), false ) ) then
				return;
			end

			-- Build the icon
			local index = IndexFromGrid( gridX, gridY );
			BuildResource( index, gridX, gridY, WonderType + g_MaxResource);
			
			-- Store the wonder for the current player
			local iPlayerID = Game.GetActivePlayer();		
			if (g_PerPlayerResourceTables[ iPlayerID ] == nil) then
				g_PerPlayerResourceTables[ iPlayerID ] = {};
			end
			
			local playerResourceTable = g_PerPlayerResourceTables[ iPlayerID ];		
			playerResourceTable[index] = WonderType + g_MaxResource;			
		end
    end
end
LuaEvents.RIM_WonderAdded.Add(OnWonderAdded)

-------------------------------------------------
-------------------------------------------------
function OnRequestYieldDisplay( type )

    if( type == YieldDisplayTypes.USER_ALL_RESOURCE_ON ) then
        g_bHideResourceIcons = false;
    elseif( type == YieldDisplayTypes.USER_ALL_RESOURCE_OFF ) then
        g_bHideResourceIcons = true;
    end
    
    if( not g_bIsStrategicView ) then
        Controls.ResourceIconContainer:SetHide( g_bHideResourceIcons );
    end
end
Events.RequestYieldDisplay.Add( OnRequestYieldDisplay );


-------------------------------------------------
-------------------------------------------------
function OnStrategicViewStateChanged( bStrategicView )
    g_bIsStrategicView = bStrategicView;
    if( bStrategicView ) then
        Controls.ResourceIconContainer:SetHide( true );
    else
        Controls.ResourceIconContainer:SetHide( g_bHideResourceIcons );
    end
end
Events.StrategicViewStateChanged.Add(OnStrategicViewStateChanged);

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnActivePlayerChanged(iActivePlayer, iPrevActivePlayer)
	
	-- Reset the resource data.
	for index, pResource in pairs( g_ActiveSet ) do
        DestroyResource( index );
   	end

	-- Rebuild with the current player's stored data.
	local playerResourceTable = g_PerPlayerResourceTables[ iActivePlayer ];
	if (playerResourceTable ~= nil) then
		for index, resource in pairs( playerResourceTable ) do
			local gridX, gridY = GridFromIndex(index);
			BuildResource( index, gridX, gridY, resource );
   		end
	else
		g_PerPlayerResourceTables[ iActivePlayer ] = {}
		AddWonderIcons()
   	end
end
Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged);

-------------------------------------------------
-------------------------------------------------
function ResetPlayerResources(iActivePlayer)
  for index, pResource in pairs(g_ActiveSet) do
    DestroyResource(index)
  end

  g_PerPlayerResourceTables[iActivePlayer] = nil
end
LuaEvents.RIM_ResetPlayerResources.Add(ResetPlayerResources)

-------------------------------------------------
-------------------------------------------------
function AddWonderIcons()
  local mapWidth, mapHeight = Map.GetGridSize()
  for x = 0, mapWidth-1 do
    for y = 0, mapHeight-1 do
      local pPlot = Map.GetPlot(x, y)
	  local iFeature = pPlot:GetFeatureType()

	  if (iFeature ~= -1 and GameInfo.Features[iFeature].NaturalWonder) then
        OnWonderAdded(x, y, iFeature, true)
      end
    end
  end
end

-------------------------------------------------
-------------------------------------------------
function OnSetSize(small)
  g_SmallIcons = small;

  if (g_ActiveSet) then
    for index, instance in pairs( g_ActiveSet ) do
      if (instance) then
        instance.ResourceFrame:SetHide(g_SmallIcons == true);
        instance.ResourceFrameSmall:SetHide(g_SmallIcons == false);
      end
	end
  end
end
LuaEvents.RIM_SetSize.Add(OnSetSize)
