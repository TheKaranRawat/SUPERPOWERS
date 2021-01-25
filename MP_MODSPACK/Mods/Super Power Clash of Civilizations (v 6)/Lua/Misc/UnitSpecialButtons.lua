

include( "UtilityFunctions.lua" )




-------------------------------------------------------------------Automation---------------------------------------------------
AllUnitsSleepButton = {
  Name = "All Units Idle",
  Title = "TXT_KEY_SP_UI_BTN_UNITSLEEP_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 14,
  ToolTip = "TXT_KEY_SP_UI_BTN_UNITSLEEP", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return unit:GetActivityType()== 0 
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
    return unit:GetBaseCombatStrength() <= 0 and unit:GetBaseCombatStrength() <= 0 and unit:GetDomainType() ~= DomainTypes.DOMAIN_AIR
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  		print ("Sleep pressed!")
  local player = Players[Game.GetActivePlayer()]
		if(player:IsHuman()) then --Only Effective for Human Players
	
		
			for unit in player:Units() do	
				local CombatType = unit:GetUnitCombatType()
				local DomainType = unit:GetDomainType()
				local unitType = unit:GetUnitType()	

				if (unit:MovesLeft() > 0 and unit:IsCombatUnit() and unit:GetActivityType()== 0 )then
				
					if (unitType == GameInfoTypes.UNIT_SCOUT) or (unitType == GameInfoTypes.UNIT_EXPLORERX) or (unitType == GameInfoTypes.UNIT_CARAVEL) then
--						unit:PushMission(GameInfoTypes.MISSION_ALERT)
						unit:DoCommand(CommandTypes["COMMAND_AUTOMATE"])-------Can't find the auto-explore yet?
	
							
					elseif (CombatType == GameInfoTypes.UNITCOMBAT_RECON) or (CombatType == GameInfoTypes.UNITCOMBAT_MELEE) or (CombatType == GameInfoTypes.UNITCOMBAT_GUN) then
						unit:PushMission(GameInfoTypes.MISSION_ALERT)
		
					else
						unit:PushMission(GameInfoTypes.MISSION_SLEEP)					
					end
					
				elseif (unit:MovesLeft() > 0 and unit:GetDomainType() == DomainTypes.DOMAIN_AIR ) then
					if 	(unit:CurrInterceptionProbability()> 0 and unit:GetCurrHitPoints()> 30 ) then
						unit:PushMission(GameInfoTypes.MISSION_AIRPATROL)
					else
						unit:PushMission(GameInfoTypes.MISSION_SLEEP)	
					end						
				end	
			end
		end		
  
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(AllUnitsSleepButton);










AllUnitsUpgradeButton = {
  Name = "All Units Upgrade",
  Title = "TXT_KEY_SP_UI_BTN_UNITUPGRADE_SHORT", -- or a TXT_KEY
  OrderPriority = 1000, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 15,
  ToolTip = "TXT_KEY_SP_UI_BTN_UNITUPGRADE", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return unit:CanUpgradeRightNow()
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
    return false
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  
	 print ("Upgrade pressed!")
  local player = Players[Game.GetActivePlayer()]
	if(player:IsHuman()) then --Only Effective for Human Players		
		for unit in player:Units() do
			if unit:CanUpgradeRightNow() then
				unit:DoCommand(CommandTypes["COMMAND_UPGRADE"])
			end
		end
	end		
  
  
  end
};

LuaEvents.UnitPanelActionAddin(AllUnitsUpgradeButton);











-------------------------------------------------------------------Special Missions---------------------------------------------------
--
--------Cancel TradeRoute
--CancelTradeButton = {
--  Name = "Cancel Trade Route",
--  Title = "TXT_KEY_SP_UI_BTN_UNITUPGRADE_SHORT", -- or a TXT_KEY
--  OrderPriority = 200, -- default is 200
--  IconAtlas = "UNIT_ACTION_ATLAS", -- 45 and 64 variations required
--  PortraitIndex = 63,
--  ToolTip = "TXT_KEY_SP_UI_BTN_UNITUPGRADE", -- or a TXT_KEY_ or a function
--  
-- 
--  
--  Condition = function(action, unit)
--   return unit:GetUnitType() == GameInfoTypes.UNIT_CARGO_SHIP or unit:GetUnitType() == GameInfoTypes.UNIT_CARAVAN
--  end, -- or nil or a boolean, default is true
--  
--  Disabled = function(action, unit)   
--    return unit:CanMove()
--  end, -- or nil or a boolean, default is false
--  
--  Action = function(action, unit, eClick) 
--  
--	print ("Cancel TradeRoute pressed!")
--	unit:Kill(false, -1)	
--  
--  
--  end
--};
--
--LuaEvents.UnitPanelActionAddin(CancelTradeButton);
--




----Settler joins the city
SettlerMissionButton = {
  Name = "Settler enter city",
  Title = "TXT_KEY_SP_BTNNOTE_SETTLER_INTO_CITY_SHORT", -- or a TXT_KEY
  OrderPriority = 300, -- default is 200
  IconAtlas = "UNIT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 40,
  ToolTip = "TXT_KEY_SP_BTNNOTE_SETTLER_INTO_CITY", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_SETTLER;
  end, -- or nil or a boolean, default is true
  Disabled = function(action, unit) 
    local plot = unit:GetPlot();
    if not plot:IsCity() then return true end;
    local city = plot:GetPlotCity()
    return not city or city:GetOwner() ~= unit:GetOwner();
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick)
    local plot = unit:GetPlot();
    local city = plot:GetPlotCity()
    local player = Players[unit:GetOwner()]
    if not city then return end

    local count = 1;
    if player:HasPolicy(GameInfo.Policies["POLICY_RESETTLEMENT"].ID) and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SETTLER_POP_3"].ID) then
      count = 3;
    end



    city:ChangePopulation(count,true);
    city:SetFood( 0 )
    unit:Kill();

    local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_SETTLER_INTO_CITY", unit:GetName(), city:GetName())
    local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_SETTLER_INTO_CITY_SHORT", unit:GetName(), city:GetName())
    player:AddNotification(NotificationTypes.NOTIFICATION_CITY_GROWTH, text, heading, unit:GetX(), unit:GetY())	  

  end,
};
LuaEvents.UnitPanelActionAddin(SettlerMissionButton);












-----------------Unit Transformation

-----Caravel and Explorer

CaravelToExplorerButton = {
  Name = "Caravel to Explorer",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_CARAVELTOEXPLORER_SHORT", -- or a TXT_KEY
  OrderPriority = 300, -- default is 200
  IconAtlas = "UNIT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 15,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_CARAVELTOEXPLORER", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return unit:CanMove() and unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_CARAVEL.ID
  end, -- or nil or a boolean, default is true
    
  Disabled = function(action, unit) 
    local plot = unit:GetPlot();
 
    if not plot:IsAdjacentToLand() then return true end;    
  end, -- or nil or a boolean, default is false
    
  Action = function(action, unit, eClick) 
  	local plotX = unit:GetX()
	local plotY = unit:GetY()	
   	local player = Players[unit:GetOwner()]
   	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_SPAIN"] then
   		local NewUnit = player:InitUnit(GameInfoTypes.UNIT_SPANISH_CONQUISTADOR, plotX, plotY, UNITAI_EXPLORE)	
   		NewUnit:JumpToNearestValidPlot()
   	else
		local NewUnit = player:InitUnit(GameInfoTypes.UNIT_EXPLORERX, plotX, plotY, UNITAI_EXPLORE)	
		NewUnit:JumpToNearestValidPlot()
	end
		
   	unit:Kill()
  	
  
  
  end
};
LuaEvents.UnitPanelActionAddin(CaravelToExplorerButton);





-----Launch UAV

UnitLaunchUavButton = {
  Name = "Launch UAV",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_LAUNCH_UAV_SHORT", -- or a TXT_KEY
  OrderPriority = 300, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 45,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_LAUNCH_UAV", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
  	local player = Players[unit:GetOwner()]
 	local pTeam = Teams[player:GetTeam()]
  
   return unit:CanMove() and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID) and pTeam:IsHasTech(GameInfoTypes["TECH_ARTIFICIAL_INTELLIGENCE"])
  end, -- or nil or a boolean, default is true
    
  Disabled = function(action, unit) 
    local plot = unit:GetPlot();
 
    if plot:GetTerrainType() == GameInfo.Terrains.TERRAIN_OCEAN.ID  then return true end;    
  end, -- or nil or a boolean, default is false
    
  Action = function(action, unit, eClick) 
  	local plotX = unit:GetX()
	local plotY = unit:GetY()	
	local plot = unit:GetPlot()
   	local player = Players[unit:GetOwner()]
  
	local NewUnit = player:InitUnit(GameInfoTypes.UNIT_UAV, plotX, plotY, UNITAI_EXPLORE)	

	
		
   	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_DRONE_CARRIER"].ID,false)
  	if plot:GetPlotType() == PlotTypes.PLOT_LAND then
 	   NewUnit:JumpToNearestValidPlot()   
  	end
  end
};
LuaEvents.UnitPanelActionAddin(UnitLaunchUavButton);








-----Worker to Militia

WorkerToMilitiaButton = {
  Name = "Worker to Militia",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_WORKERTOMILITIA_SHORT", -- or a TXT_KEY
  OrderPriority = 300, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 44,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_WORKERTOMILITIA", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return unit:CanMove() and unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_WORKER.ID
  end, -- or nil or a boolean, default is true
 
 
  Disabled = function(action, unit) 
    local plot = unit:GetPlot()
    local player = Players[unit:GetOwner()]
   
    if not plot:IsFriendlyTerritory(player) then 
        return true       
    end 
    
    if plot:GetNumUnits() > 1 then
        return true       
    end 
    
    if plot:IsWater() then
        return true       
    end 
    
    
  end, -- or nil or a boolean, default is false
  
  
  
  Action = function(action, unit, eClick) 
  	local plot = unit:GetPlot()
  	
  	local plotX = plot:GetX()
	local plotY = plot:GetY()	
  	
   	local player = Players[unit:GetOwner()]
   	
   	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_WARRIOR")   	
    local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
        
    while (sUpgradeUnitType ~= nil) do
       sUnitType = sUpgradeUnitType
       sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
    end
	
	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], plotX, plotY, UNITAI_DEFENSE)	

	
	if plot:GetNumUnits() > 2 then
       NewUnit:JumpToNearestValidPlot()      
    end 
	
	NewUnit:SetMoves(0)	
   	unit:Kill()
   	
	
  
  end
};
LuaEvents.UnitPanelActionAddin(WorkerToMilitiaButton);






-----Militia to Worker

MilitiaToWorkerButton = {
  Name = "Militia to Worker",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_MILITIATOWORKER_SHORT", -- or a TXT_KEY
  OrderPriority = 300, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 43,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_MILITIATOWORKER", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
  			if unit:CanMove() and unit:GetDomainType()== DomainTypes.DOMAIN_LAND and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_MILITIA_COMBAT"].ID) then
  				return true
  			end
  			
  			if unit:GetUnitType() == GameInfoTypes.UNIT_AZTEC_JAGUAR or unit:GetUnitType() == GameInfoTypes.UNIT_POLYNESIAN_MAORI_WARRIOR then
  				if unit:CanMove() then
  					return true
  				end
  			end
  			
  		
  end, -- or nil or a boolean, default is true
 
 
  Disabled = function(action, unit) 
    local plot = unit:GetPlot()
    local player = Players[unit:GetOwner()]
   
    if not plot:IsFriendlyTerritory(player) then 
        return true       
    end 
    
    if plot:GetNumUnits() > 1 then
        return true       
    end 
    
    if plot:IsWater() then
        return true       
    end 
    
    
  end, -- or nil or a boolean, default is false
  
  
  
  Action = function(action, unit, eClick) 
  	local plot = unit:GetPlot()
  	
  	local plotX = plot:GetX()
	local plotY = plot:GetY()	
  	
   	local player = Players[unit:GetOwner()]
   	
   	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_WORKER")   	
	
	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], plotX, plotY, UNITAI_WORKER)	

	
	if plot:GetNumUnits() > 2 then
       NewUnit:JumpToNearestValidPlot()      
    end 
	
	NewUnit:SetMoves(0)	
   	unit:Kill()
   	
	
  
  end
};
LuaEvents.UnitPanelActionAddin(MilitiaToWorkerButton);




------Purchase Missiles on units
--
--BuyMissileMissionButton = {
--  Name = "Quick Missile Purchase",
--  Title = "TXT_KEY_SP_BTNNOTE_QUICK_BUY_MISSILE_SHORT", -- or a TXT_KEY
--  OrderPriority = 200, -- default is 200
--  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
--  PortraitIndex = 5,
--  ToolTip = "TXT_KEY_SP_BTNNOTE_QUICK_BUY_MISSILE", -- or a TXT_KEY_ or a function
--  Condition = function(action, unit)
--    return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_MISSILE_CRUISER or unit:GetUnitType() == GameInfoTypes.UNIT_NUCLEAR_SUBMARINE ;
--  end, -- or nil or a boolean, default is true
--  Disabled = function(action, unit) 
--    local plot = unit:GetPlot()
--    local player = Players[unit:GetOwner()]
--   	local pTeam = Teams[player:GetTeam()]
--    if not plot:IsFriendlyTerritory(player) then 
--     return true       
--    end 
--    
--   	if player:GetGold() < 1000 then
--    	return true
--    end 
--    
--
--	if not pTeam:IsHasTech(GameInfoTypes["TECH_ADVANCED_BALLISTICS"]) then
--    	return true
--    end 
--       
--     if unit:IsFull() then
--    	return true
--    end 
--       
--    return not plot:IsFriendlyTerritory(player)
--  end, -- or nil or a boolean, default is false
--  
--  Action = function(action, unit, eClick)  
--    local plot = unit:GetPlot()  
--    local player = Players[unit:GetOwner()]     
--    local NewUnitID = GameInfoTypes.UNIT_GUIDED_MISSILE    
--  	local NewUnit = player:InitUnit(NewUnitID, plot:GetX(), plot:GetY(),UNITAI_MISSILE_AIR)
--	local player = Players[Game.GetActivePlayer()]
--	
--    player:ChangeGold(-1000)
--    NewUnit:SetMoves(0)
--  
--  end
--};
--
--LuaEvents.UnitPanelActionAddin(BuyMissileMissionButton);







-----------------Recon Airunits Bonus
AllUnitsSleepButton = {
  Name = "Recon Airunits Bonus",
  Title = "TXT_KEY_SP_UI_BTN_AIR_RECON_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 20,
  ToolTip = "TXT_KEY_SP_UI_BTN_AIR_RECON", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_SR71_BLACKBIRD
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
    return not unit:CanMove() 
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  
  unit:SetMoves(0)
  	
  local player = Players[Game.GetActivePlayer()]
  
	if player ~= nil then 
	
		for unit in player:Units() do	
			local CombatType = unit:GetUnitCombatType()
			if unit:GetDomainType() == DomainTypes.DOMAIN_AIR then
	
				if CombatType == GameInfoTypes.UNITCOMBAT_FIGHTER or CombatType == GameInfoTypes.UNITCOMBAT_ARCHER then
						unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_BLACKBIRD_RECON"].ID, true)
						print ("Air Recon Set for all air units!")
					end						
				end	
			end
		end
	end		
  
	
  
  
  
};

LuaEvents.UnitPanelActionAddin(AllUnitsSleepButton);







--Fast Movement Switch

UnitFastMoveMentnButton = {
  Name = "Fast Movement On",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_FASTMOVEMENT_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 17,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_FASTMOVEMENT", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_RAPID_MARCH"].ID) and unit:CanMove() and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NUMIDIAN_MARCH"].ID) 
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_RAPID_MARCH"].ID) 
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  	
   	
	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_RAPID_MARCH"].ID, true)
	
--	unit:ChangeMoves (300)
	unit:SetMoves(unit:GetMoves()*2)
	unit:SetMadeAttack(true)
   	print ("Fast Movement On!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(UnitFastMoveMentnButton);





----Full Attack Mode Switch

UnitFullAttackOnButton = {
  Name = "Full Attack Mode On",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_FULLATTACK_ON_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "UNIT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 12,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_FULLATTACK_ON", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID) and unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_CRUSADER_ARTILLERY or not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID) and unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_SUPER_BATTLESHIP 
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID) or not unit:CanMove() 
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  	
   	
   	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID, true)
   	unit:SetMoves(1)
   	print ("Full Attack On!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(UnitFullAttackOnButton);


UnitFullAttackOffButton = {
  Name = "Full Attack Mode Off",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_FULLATTACK_OFF_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 12,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_FULLATTACK_OFF", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID) ;
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)     
    return not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID) ;
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  	
   	
   	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID, false)
   	unit:SetMoves(0)
   	print ("Full Attack Off!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(UnitFullAttackOffButton);





--Target Marking

UnitTargetMarkingButton = {
  Name = "Target Marking",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_TARGETMARKING_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 16,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_TARGETMARKING", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
   return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_STEALTH_HELICOPTER
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
    return unit:GetNumEnemyUnitsAdjacent (unit) < 1
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
  	local unitX = unit:GetX()
	local unitY = unit:GetY()	
   	
	for i = 0, 5 do
			local adjPlot = Map.PlotDirection(unitX, unitY, i)
			if (adjPlot ~= nil) then 
				local pUnit = adjPlot:GetUnit(0)			
				if (pUnit ~= nil) then	
					local iActivePlayer = Players[unit:GetOwner()]	
					local pPlayer = Players[pUnit:GetOwner()]	
									
					if PlayersAtWar(iActivePlayer,pPlayer) and not pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_ANTI_DEBUFF"].ID) then		
						pUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_MARKED_TARGET"].ID, true)
												
						local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_TARGET_MARKED_SHORT")
						local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_TARGET_MARKED")
						iActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC , text, heading, unitX, unitY)						
					else
						print ("Not at war!")
					end		
				end    
			end		    
		end
		
--	unit:ChangeMoves (-170)
	unit:SetMoves(unit:GetMoves()-100)
   	
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(UnitTargetMarkingButton);








----Air EVAC


UnitEVACButton = {
  Name = "Air EVAC",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_AIREVAC_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 11,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_AIREVAC", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
    return unit:GetUnitType() == GameInfoTypes.UNIT_TASKFORCE_141 and unit:CanMove() 
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)     
    return false
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
 	local player = Players[unit:GetOwner()]
  	local pCity = player:GetCapitalCity()
   	local pPlot = pCity
   	unit:SetXY(pPlot:GetX(), pPlot:GetY())
   	unit:JumpToNearestValidPlot() 
   	unit:SetMoves(0)
   	print ("Evac!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(UnitEVACButton);










-----------------------------------------------------Special Forces-----------------------------------------------------------------------

--------Riot Control


UnitRiotControlButton = {
  Name = "Riot Control",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_RIOT_CONTROL_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 9,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_RIOT_CONTROL", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SP_FORCE_I"].ID) and unit:CanMove() 
  end, -- or nil or a boolean, default is true
  
 Disabled = function(action, unit) 
    local plot = unit:GetPlot();
    if not plot:IsCity() then return true end;
    local city = plot:GetPlotCity()
    return not city or city:GetOwner() ~= unit:GetOwner() or not city:IsResistance() or city:GetResistanceTurns() < 3;
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
	local plot = unit:GetPlot()
    local city = plot:GetPlotCity()
    local player = Players[unit:GetOwner()]
    if not city then return end
    city:ChangeResistanceTurns(-1)
    unit:SetMoves(0)    
    unit:ChangeExperience(1)	
    
   	print ("Riot Control!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(UnitRiotControlButton);



ReconTargetGuideButton = {
  Name = "Recon Target Guide",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_RECON_TARGET_GUIDE_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 18,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_RECON_TARGET_GUIDE", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SP_FORCE_II"].ID) or unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_GREAT_ADMIRAL"].ID) and unit:CanMove() 
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
  	local plot = unit:GetPlot() 
  	local unitCount = plot:GetNumUnits()
  	
  	if unitCount <= 1 then
    	return true 
    end
    
--   	for i = 0, unitCount-1, 1 do  
--  		local pFoundUnit = plot:GetUnit(i)	 
--  		if pFoundUnit:GetID() ~= pDefendingUnit:GetID() then	
--	  		if not pFoundUnit:IsRanged() then
--	  			return true 
--	  		end
--  		end
--	end

  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
   	local plot = unit:GetPlot()	
   	local unitCount = plot:GetNumUnits()
   	for i = 0, unitCount-1, 1 do   	
   		local pFoundUnit = plot:GetUnit(i)	
   		if pFoundUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_SIEGE or pFoundUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_BOMBER or pFoundUnit:GetUnitCombatType()== GameInfoTypes.UNITCOMBAT_NAVALRANGED then			
		   print ("Found Ranged Unit in the same tile!")		   
		   pFoundUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_TRAGET_CLEARSHOOT_3"].ID, true)	
		   unit:SetMoves(0)	
   		end
   	end
   
   	
   	print ("Target Guided!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(ReconTargetGuideButton);



--------Stealth Operation Switch
--UnitStealthOnButton = {
--  Name = "Stealth Operation on",
--  Title = "TXT_KEY_SP_BTNNOTE_UNIT_STEALTH_ON_SHORT", -- or a TXT_KEY
--  OrderPriority = 200, -- default is 200
--  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
--  PortraitIndex = 20,
--  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_STEALTH_ON", -- or a TXT_KEY_ or a function
--  
-- 
--  
--  Condition = function(action, unit)
--    return not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_STEALTH_OPERATION"].ID) and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SP_FORCE_II"].ID) 
--  end, -- or nil or a boolean, default is true
--  
-- Disabled = function(action, unit)  
--   
--    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_STEALTH_OPERATION"].ID) or not unit:CanMove() 
--  end, -- or nil or a boolean, default is false
--  
--  Action = function(action, unit, eClick) 	
--    unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_STEALTH_OPERATION"].ID, true)  
--   	print ("Stealth On!")	
--  end
--};
--
--LuaEvents.UnitPanelActionAddin(UnitStealthOnButton);
--
--
--
--UnitStealthOffButton = {
--  Name = "Stealth Operation off",
--  Title = "TXT_KEY_SP_BTNNOTE_UNIT_STEALTH_OFF_SHORT", -- or a TXT_KEY
--  OrderPriority = 200, -- default is 200
--  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
--  PortraitIndex = 21,
--  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_STEALTH_OFF", -- or a TXT_KEY_ or a function
--  
--  
-- Condition = function(action, unit)
--    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_STEALTH_OPERATION"].ID) ;
--  end, -- or nil or a boolean, default is true
--  
--  Disabled = function(action, unit)     
--    return not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_STEALTH_OPERATION"].ID) ;
--  end, -- or nil or a boolean, default is false
--  
--  Action = function(action, unit, eClick) 	
--    unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_STEALTH_OPERATION"].ID, false)  
--    unit:SetMoves(0)
--   	print ("Stealth Off!")	
--  end
--};
--
--LuaEvents.UnitPanelActionAddin(UnitStealthOffButton);





----------Emergency Heal

EmergencyHealButton = {
  Name = "Emergency Heal",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_EMERGENCY_HEAL_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 19,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_EMERGENCY_HEAL", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
    return not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FULL_FIRE"].ID) and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SP_FORCE_III"].ID) and unit:CanMove()
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
  	local plot = unit:GetPlot() 
  	local unitCount = plot:GetNumUnits()
   	for i = 0, unitCount-1, 1 do   	
   		local pFoundUnit = plot:GetUnit(i)	
   		if pFoundUnit:GetCurrHitPoints() == 100 and pFoundUnit:GetID() ~= unit:GetID() then   		
   			return true   
   		else 
   			return false				
   		end	
	end      
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
   	local plot = unit:GetPlot()	
   	local unitCount = plot:GetNumUnits()
   	for i = 0, unitCount-1, 1 do   	
   		local pFoundUnit = plot:GetUnit(i)	
   		if pFoundUnit:GetCurrHitPoints() < 100 and Players[unit:GetOwner()] == Players[pFoundUnit:GetOwner()] and pFoundUnit:GetDomainType()== DomainTypes.DOMAIN_LAND then			
		   pFoundUnit:ChangeDamage(-50)
		   unit:SetMoves(0)
   		end
   	end
   
   	
   	print ("Emergency Heal!")
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(EmergencyHealButton);


-----------------------------------------------------Rods from Gods-----------------------------------------------------------------------
GlobalStrikeButton = {
  Name = "Global Strike",
  Title = "TXT_KEY_SP_BTNNOTE_GLOBAL_STRIKE_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 10,
  ToolTip = "TXT_KEY_SP_BTNNOTE_GLOBAL_STRIKE", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_ORBITAL_STRIKE
  end, -- or nil or a boolean, default is true
  
--  Disabled = function(action, unit) 
--    
--    return 
--  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
    
     unit:SetMoves(0)
    
	  for playerID,player in pairs(Players) do
		 if player ~= nil and player:GetNumCities() >= 1 then
			if not player:IsHuman() then
				if PlayerAtWarWithHuman(player) then
					for city in player:Cities() do
						local CityMaxHP = city:GetMaxHitPoints()
						city:SetDamage (CityMaxHP)
						print ("Global Strike!")	
					end
				end
			end
		 end
	  end
  
  end
  
};
LuaEvents.UnitPanelActionAddin(GlobalStrikeButton);



-----------------------------------------------------Hacker-----------------------------------------------------------------------

HackingMissionButton = {
  Name = "Hacking Mission",
  Title = "TXT_KEY_SP_BTNNOTE_HACKING_MISSION_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 30,
  ToolTip = "TXT_KEY_SP_BTNNOTE_HACKING_MISSION", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_HACKER
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
  
  
    local plot = unit:GetPlot()
    
    if plot:IsFriendlyTerritory(player) then
       return true          
    end
    
    local unitOwner = Players[unit:GetOwner()]
     
    local plotOwner = Players[plot:GetOwner()]
    if plotOwner == nil then
    	print ("Netrual Tile!")
       return true          
    end
    
--    local iTeam = Teams[unitOwner:GetTeam()]
--	local eTeamIndex = Teams[plotOwner:GetTeam()]
--	
--    
--    if iTeam:IsAtWar(eTeamIndex) then 
--        return false
--    else 
--    	return true          
--    end
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick)  
 local plot = unit:GetPlot()
  local unitOwner = Players[unit:GetOwner()]
    local plotOwnerID = plot:GetOwner()    
    
    if plotOwnerID == nil then
    	print ("Netrual Tile!")
       return         
    end
    
    local plotOwner = Players[plot:GetOwner()]
    if plotOwner == nil then
    	print ("Netrual Tile!")
       return true          
    end
    
    local iTeam = Teams[unitOwner:GetTeam()]
	local eTeamIndex = plotOwner:GetTeam()
	
	
    if iTeam:IsAtWar(eTeamIndex) then 
    	plotOwner:SetAnarchyNumTurns(2)
    	print ("Hacking success!")
    	unit:Kill()
	end
  end
};

LuaEvents.UnitPanelActionAddin(HackingMissionButton);




-----------------------------------------------------Units Group Moving-----------------------------------------------------------------------


----Legion Group Movement (Same Plot)
LegionSamePlotButton = {
  Name = "Same Plot Movement",
  Title = "TXT_KEY_SP_BTNNOTE_SAME_PLOT_MOVEMEMT_SHORT", -- or a TXT_KEY
  OrderPriority = 10000, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 40,
  ToolTip = "TXT_KEY_SP_BTNNOTE_SAME_PLOT_MOVEMEMT", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:IsCombatUnit() and not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID);
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
    
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID)
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
    
    if not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID) then
    	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, true)	
    end
    
	local unitX = unit:GetX()
	local unitY = unit:GetY()
	local pPlot = Map.GetPlot(unitX, unitY)
	local unitCount = pPlot:GetNumUnits()
	for i = 0, unitCount-1, 1 do
		local pFoundUnit = pPlot:GetUnit(i)	
		if pFoundUnit ~= nil and pFoundUnit:GetID() and pFoundUnit:IsCombatUnit()and pFoundUnit:GetDomainType()== unit:GetDomainType() then	
			pFoundUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, true)	
			print ("Unit In group - same tile!")			
		end
	end	
  	 
  end,
};
LuaEvents.UnitPanelActionAddin(LegionSamePlotButton);



----Legion Group Movement (All Units around)
LegionGroupButton = {
  Name = "Legion Group Movement",
  Title = "TXT_KEY_SP_BTNNOTE_LEGION_GROUP_MOVEMEMT_SHORT", -- or a TXT_KEY
  OrderPriority = 10000, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 25,
  ToolTip = "TXT_KEY_SP_BTNNOTE_LEGION_GROUP_MOVEMEMT", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:IsCombatUnit() and not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID);
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
    
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID)
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
    
    if not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID) then
    	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, true)	
    end
    
	local unitX = unit:GetX()
	local unitY = unit:GetY()
	local pPlot = Map.GetPlot(unitX, unitY)
	local unitCount = pPlot:GetNumUnits()
	for i = 0, unitCount-1, 1 do
		local pFoundUnit = pPlot:GetUnit(i)	
		if pFoundUnit ~= nil and pFoundUnit:GetID() and pFoundUnit:IsCombatUnit()and pFoundUnit:GetDomainType()== unit:GetDomainType() then	
			pFoundUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, true)	
			print ("Unit In group - same tile!")			
		end
	end	
   	for i = 0, 5 do
		local adjPlot = Map.PlotDirection(unitX, unitY, i)
		if (adjPlot ~= nil) then
			
			local pUnit = adjPlot:GetUnit(0)
			local unitCountAdj = adjPlot:GetNumUnits()	
			if pUnit ~= nil and pUnit:IsCombatUnit() and pUnit:CanMove() and pUnit:GetDomainType()== unit:GetDomainType() then
				if not pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID) then
					pUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, true)
				end	
				print ("Unit In group-around!")
			
				for i = 0, unitCount-1, 1 do
					local pFoundUnit = adjPlot:GetUnit(i)					
					if pFoundUnit ~= nil and pFoundUnit:IsCombatUnit() and pFoundUnit:CanMove() and pFoundUnit:GetDomainType()== unit:GetDomainType() then
						if not pFoundUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID) then
							pFoundUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, true)	
						end
						print ("Unit In group-around same tile!")					
					end
				end
			end    
		end		    
	end


  end,
};
LuaEvents.UnitPanelActionAddin(LegionGroupButton);




----Remove from Legion
LegionLeaveButton = {
  Name = "Remove from Legion",
  Title = "TXT_KEY_SP_BTNNOTE_REMOVE_FROM_LEGION_SHORT", -- or a TXT_KEY
  OrderPriority = 10000, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 41,
  ToolTip = "TXT_KEY_SP_BTNNOTE_REMOVE_FROM_LEGION", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID);
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
    return 
    false
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
    
    local player = Players[unit:GetOwner()]
    
    for unit in player:Units() do	
	    if unit ~= nil and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID) then
	    	unit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_LEGION_GROUP"].ID, false)	
	    end
    end
    print ("Unit left group!")		

  	 
  end,
};
LuaEvents.UnitPanelActionAddin(LegionLeaveButton);






-----------------------------------------------------Great People-----------------------------------------------------------------------




----------remove Debuff

MoralBoostButton = {
  Name = "Moral Boost",
  Title = "TXT_KEY_SP_BTNNOTE_UNIT_MORAL_BOOST_SHORT", -- or a TXT_KEY
  OrderPriority = 200, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 22,
  ToolTip = "TXT_KEY_SP_BTNNOTE_UNIT_MORAL_BOOST", -- or a TXT_KEY_ or a function
  
 
  
  Condition = function(action, unit)
    return unit:CanMove() and unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.ID or unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_GREAT_ADMIRAL.ID or unit:GetUnitType()== GameInfoTypes["UNIT_POLISH_PZLW3_HELICOPTER"] or unit:GetUnitType()== GameInfoTypes["UNIT_HUN_SHAMAN"]
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit)   
  	local plot = unit:GetPlot() 
  	local unitCount = plot:GetNumUnits()
  	if unitCount <=1 then
  		return true  
  	end
--   	for i = 0, unitCount-1, 1 do   	
--   		local pFoundUnit = plot:GetUnit(i)	   		
--   		if pFoundUnit:GetID() ~= unit:GetID() then   		
--   			return false 
--   		else 
--   			return true			
--   		end	
--	end      
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick) 
   	local plot = unit:GetPlot()	
   	local unitCount = plot:GetNumUnits()
   	
   	local Penetration1ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_1"].ID
	local Penetration2ID = GameInfo.UnitPromotions["PROMOTION_PENETRATION_2"].ID
	local SlowDown1ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_1"].ID
	local SlowDown2ID = GameInfo.UnitPromotions["PROMOTION_MOVEMENT_LOST_2"].ID
	local MoralWeaken1ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_1"].ID
	local MoralWeaken2ID = GameInfo.UnitPromotions["PROMOTION_MORAL_WEAKEN_2"].ID
	local LoseSupplyID = GameInfo.UnitPromotions["PROMOTION_LOSE_SUPPLY"].ID	
	local MarkedTargetID = GameInfo.UnitPromotions["PROMOTION_MARKED_TARGET"].ID
			
			
			
   	for i = 0, unitCount-1, 1 do   	
   		local pFoundUnit = plot:GetUnit(i)	
   		if Players[unit:GetOwner()] == Players[pFoundUnit:GetOwner()] then
   			if pFoundUnit:IsHasPromotion(Penetration1ID) or pFoundUnit:IsHasPromotion(SlowDown1ID) or pFoundUnit:IsHasPromotion(MoralWeaken1ID) or pFoundUnit:IsHasPromotion(LoseSupplyID) or pFoundUnit:IsHasPromotion(MarkedTargetID) then
		   	pFoundUnit:SetHasPromotion(Penetration1ID, false)
			pFoundUnit:SetHasPromotion(Penetration2ID, false)
			pFoundUnit:SetHasPromotion(SlowDown1ID, false)
			pFoundUnit:SetHasPromotion(SlowDown2ID, false)
			pFoundUnit:SetHasPromotion(MoralWeaken1ID, false)
			pFoundUnit:SetHasPromotion(MoralWeaken2ID, false)
			pFoundUnit:SetHasPromotion(LoseSupplyID, false)
			pFoundUnit:SetHasPromotion(MarkedTargetID, false) 
			print ("Moral Boost!")
			unit:SetMoves(0)
			end
   		end
   	end
   

   	
	
  
  
  end
};

LuaEvents.UnitPanelActionAddin(MoralBoostButton);




----Build the JAPANESE DOJO in the city
BuildMilitaryAcademyButton = {
  Name = "Build JAPANESE DOJO",
  Title = "TXT_KEY_SP_BTNNOTE_BUILDING_JAPANESE_DOJO_SHORT", -- or a TXT_KEY
  OrderPriority = 1500, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 13,
  ToolTip = "TXT_KEY_SP_BTNNOTE_BUILDING_JAPANESE_DOJO", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:GetUnitType() == GameInfoTypes.UNIT_JAPANESE_SAMURAI;
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
    local plot = unit:GetPlot();
    if not plot:IsCity() then return true end;
    local city = plot:GetPlotCity()
    return not city or city:GetOwner() ~= unit:GetOwner() or city:IsHasBuilding(GameInfo.Buildings["BUILDING_JAPANESE_DOJO"].ID);
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick)
    local plot = unit:GetPlot();
    local city = plot:GetPlotCity()
    local player = Players[unit:GetOwner()]
    if not city then return end


    city:SetNumRealBuilding(GameInfoTypes["BUILDING_JAPANESE_DOJO"],1)
    unit:Kill();

  

  end,
};
LuaEvents.UnitPanelActionAddin(BuildMilitaryAcademyButton);





----Build the Military Academy in the city
BuildMilitaryAcademyButton = {
  Name = "Build Military Academy",
  Title = "TXT_KEY_SP_BTNNOTE_BUILDING_MILITARY_ACADEMY_SHORT", -- or a TXT_KEY
  OrderPriority = 1500, -- default is 200
  IconAtlas = "SPUINT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 13,
  ToolTip = "TXT_KEY_SP_BTNNOTE_BUILDING_MILITARY_ACADEMY", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_GREAT_GENERAL or unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_GREAT_ADMIRAL;
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
    local plot = unit:GetPlot();
    if not plot:IsCity() then return true end;
    local city = plot:GetPlotCity()
    return not city or city:GetOwner() ~= unit:GetOwner() or city:IsHasBuilding(GameInfo.Buildings["BUILDING_MILITARY_ACADEMY"].ID);
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick)
    local plot = unit:GetPlot();
    local city = plot:GetPlotCity()
    local player = Players[unit:GetOwner()]
    if not city then return end


    city:SetNumRealBuilding(GameInfoTypes["BUILDING_MILITARY_ACADEMY"],1)
    unit:Kill();

  

  end,
};
LuaEvents.UnitPanelActionAddin(BuildMilitaryAcademyButton);








----Satellite Launching
SatelliteLaunchingButton = {
  Name = "Satellite Launching",
  Title = "TXT_KEY_SP_BTNNOTE_SATELLITE_LAUNCHING_SHORT", -- or a TXT_KEY
  OrderPriority = 9999, -- default is 200
  IconAtlas = "UNIT_ACTION_ATLAS", -- 45 and 64 variations required
  PortraitIndex = 49,
  ToolTip = "TXT_KEY_SP_BTNNOTE_SATELLITE_LAUNCHING", -- or a TXT_KEY_ or a function
  Condition = function(action, unit)
    return unit:CanMove() and unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID) ;
  end, -- or nil or a boolean, default is true
  
  Disabled = function(action, unit) 
    local plot = unit:GetPlot();
    if not plot:IsCity() then return true end;
    local city = plot:GetPlotCity()
    return not city or city:GetOwner() ~= unit:GetOwner() or not city:IsCapital();
  end, -- or nil or a boolean, default is false
  
  Action = function(action, unit, eClick)
    local plot = unit:GetPlot();
    if not plot then 
    	return 
    end   
    
    local city = plot:GetPlotCity()    
    local player = Players[unit:GetOwner()]
 
    
    SatelliteLaunchEffects(unit,city,player)
    
    print ("Satellite Launched!")
    
    

  

  end,
};
LuaEvents.UnitPanelActionAddin(SatelliteLaunchingButton);






----Satellite Launching for AI
--
--function AISatelliteLaunching (iPlayer, iCity, iUnit, bGold, bFaith)
--	local player = Players[iPlayer]
--	if player == nil then
--		print ("No players")
--		return
--	end
--	
--	if player:IsHuman() then
--		return 
--	end
--	
--	if player:IsMinorCiv() then
--   		 	return 
--	end
--	
--	if player:IsBarbarian() then
--		return 
--	end
--	
--	if player:GetNumCities() < 1 then
--		return
--	end	
--	
--	if player:GetCurrentEra() <= 6 then
--		return
--	end	
--	
--
--	local city = player:GetCapitalCity()
--	local unit = player:GetUnitByID(iUnit)
--	
--	if not unit == nil and not unit:IsCombatUnit() then
--		if unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID) then 
--			SatelliteLaunchEffects (unit,city,player)
--			SatelliteEffectsGlobal(unit)
--			local UnitName = unit:GetName()
--			print ("AI has built a Satellite Unit:"..UnitName)
--		end
--	end
--
--end
--GameEvents.CityTrained.Add(AISatelliteLaunching)
--



--------------------------------------------------------------------------------------Utilities-----------------------------------------------------------------








print("UnitSpecialButtons Check success!")