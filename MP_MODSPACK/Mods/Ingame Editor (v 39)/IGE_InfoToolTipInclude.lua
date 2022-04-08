--===============================================================================================
-- CODE FROM INFOTOOLTIPINCLUDE.LUA MERGED HERE
-- They were not included into some of the VEM/CivUP versions.
-- Also required for G&K compatibility.
--===============================================================================================
GetYieldTooltipHelper = GetYieldTooltipHelper or function(pCity, iYieldType, strIcon)
	
	local strModifiers = "";
	
	-- Base Yield
	local iBaseYield = pCity:GetBaseYieldRate(iYieldType);

	local iYieldPerPop = pCity:GetYieldPerPopTimes100(iYieldType);
	if (iYieldPerPop ~= 0) then
		iYieldPerPop = iYieldPerPop * pCity:GetPopulation();
		iYieldPerPop = iYieldPerPop / 100;
		
		iBaseYield = iBaseYield + iYieldPerPop;
	end

	-- Total Yield
	local iTotalYield;
	
	-- Food is special
	if (iYieldType == YieldTypes.YIELD_FOOD) then
		iTotalYield = pCity:FoodDifferenceTimes100() / 100;
	else
		iTotalYield = pCity:GetYieldRateTimes100(iYieldType) / 100;
	end
	
	-- Yield modifiers string
	strModifiers = strModifiers .. pCity:GetYieldModifierTooltip(iYieldType);
	
	-- Build tooltip
	local strYieldToolTip = GetYieldTooltip(pCity, iYieldType, iBaseYield, iTotalYield, strIcon, strModifiers);
	
	return strYieldToolTip;
end


-------------------------------------------------------------------------------------------------
GetYieldTooltip = GetYieldTooltip or function(pCity, iYieldType, iBase, iTotal, strIconString, strModifiersString)
	
	local strYieldBreakdown = "";
	
	-- Base Yield from terrain
	local iYieldFromTerrain = pCity:GetBaseYieldRateFromTerrain(iYieldType);
	if (iYieldFromTerrain ~= 0) then
		strYieldBreakdown = strYieldBreakdown .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_FROM_TERRAIN", iYieldFromTerrain, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end
	
	-- Base Yield from Buildings
	local iYieldFromBuildings = pCity:GetBaseYieldRateFromBuildings(iYieldType);
	if (iYieldFromBuildings ~= 0) then
		strYieldBreakdown = strYieldBreakdown .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_FROM_BUILDINGS", iYieldFromBuildings, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end
	
	-- Base Yield from Specialists
	local iYieldFromSpecialists = pCity:GetBaseYieldRateFromSpecialists(iYieldType);
	if (iYieldFromSpecialists ~= 0) then
		strYieldBreakdown = strYieldBreakdown .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_FROM_SPECIALISTS", iYieldFromSpecialists, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end
	
	-- Base Yield from Misc
	local iYieldFromMisc = pCity:GetBaseYieldRateFromMisc(iYieldType);
	if (iYieldFromMisc ~= 0) then
		if (iYieldType == YieldTypes.YIELD_SCIENCE) then
			strYieldBreakdown = strYieldBreakdown .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_FROM_POP", iYieldFromMisc, strIconString);
		else
			strYieldBreakdown = strYieldBreakdown .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_FROM_MISC", iYieldFromMisc, strIconString);
		end
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end
	
	-- Base Yield from Pop
	local iYieldPerPop = pCity:GetYieldPerPopTimes100(iYieldType);
	if (iYieldPerPop ~= 0) then
		local iYieldFromPop = iYieldPerPop * pCity:GetPopulation();
		iYieldFromPop = iYieldFromPop / 100;
		
		strYieldBreakdown = strYieldBreakdown .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_FROM_POP_EXTRA", iYieldFromPop, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end
	
	local strExtraBaseString = "";
	
	-- Food eaten by pop
	local iYieldEaten = 0;
	if (iYieldType == YieldTypes.YIELD_FOOD) then
		iYieldEaten = pCity:FoodConsumption(true, 0);
		if (iYieldEaten ~= 0) then
			--strModifiers = strModifiers .. "[NEWLINE]";
			--strModifiers = strModifiers .. "[ICON_BULLET]" .. L("TXT_KEY_YIELD_EATEN_BY_POP", iYieldEaten, "[ICON_FOOD]");
			--strModifiers = strModifiers .. "[NEWLINE]----------------[NEWLINE]";
			
			strExtraBaseString = strExtraBaseString .. "   " .. L("TXT_KEY_FOOD_USAGE", iBase, iYieldEaten);
			
			local iFoodSurplus = pCity:GetYieldRate(YieldTypes.YIELD_FOOD) - iYieldEaten;
			iBase = iFoodSurplus;
			
			--if (iFoodSurplus >= 0) then
				--strModifiers = strModifiers .. L("TXT_KEY_YIELD_AFTER_EATEN", iFoodSurplus, "[ICON_FOOD]");
			--else
				--strModifiers = strModifiers .. L("TXT_KEY_YIELD_AFTER_EATEN_NEGATIVE", iFoodSurplus, "[ICON_FOOD]");
			--end
		end
	end
	
	local strTotal;
	if (iTotal >= 0) then
		strTotal = L("TXT_KEY_YIELD_TOTAL", iTotal, strIconString);
	else
		strTotal = L("TXT_KEY_YIELD_TOTAL_NEGATIVE", iTotal, strIconString);
	end
	
	strYieldBreakdown = strYieldBreakdown .. "----------------";
	
	-- Build combined string
	if (iBase ~= iTotal or strExtraBaseString ~= "") then
		local strBase = L("TXT_KEY_YIELD_BASE", iBase, strIconString) .. strExtraBaseString;
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]" .. strBase;
	end
	
	-- Modifiers
	if (strModifiersString ~= "") then
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]----------------" .. strModifiersString .. "[NEWLINE]----------------";
	end
	strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]" .. strTotal;
	
	return strYieldBreakdown;

end

-------------------------------------------------------------------------------------------------
GetHelpTextForUnit = GetHelpTextForUnit or function(iUnitID, bIncludeRequirementsInfo)
	local pUnitInfo = GameInfo.Units[iUnitID];
	
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local pActiveTeam = Teams[Game.GetActiveTeam()];

	local strHelpText = "";
	
	-- Name
	strHelpText = strHelpText .. Locale.ToUpper(L( pUnitInfo.Description ));
	
	-- Cost
	strHelpText = strHelpText .. "[NEWLINE]----------------[NEWLINE]";
	strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_COST", pActivePlayer:GetUnitProductionNeeded(iUnitID));
	-- Moves
	strHelpText = strHelpText .. "[NEWLINE]";
	strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_MOVEMENT", pUnitInfo.Moves);
	
	-- Range
	local iRange = pUnitInfo.Range;
	if (iRange ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_RANGE", iRange);
	end
	
	-- Ranged Strength
	local iRangedStrength = pUnitInfo.RangedCombat;
	if (iRangedStrength ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_RANGED_STRENGTH", iRangedStrength);
	end
	
	-- Strength
	local iStrength = pUnitInfo.Combat;
	if (iStrength ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_STRENGTH", iStrength);
	end
	
	-- Resource Requirements
	local iNumResourcesNeededSoFar = 0;
	local iNumResourceNeeded;
	local iResourceID;
	for pResource in GameInfo.Resources() do
		iResourceID = pResource.ID;
		iNumResourceNeeded = Game.GetNumResourceRequiredForUnit(iUnitID, iResourceID);
		if (iNumResourceNeeded > 0) then
			-- First resource required
			if (iNumResourcesNeededSoFar == 0) then
				strHelpText = strHelpText .. "[NEWLINE]";
				strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_RESOURCES_REQUIRED");
				strHelpText = strHelpText .. " " .. iNumResourceNeeded .. " " .. pResource.IconString .. " " .. L(pResource.Description);
			else
				strHelpText = strHelpText .. ", " .. iNumResourceNeeded .. " " .. pResource.IconString .. " " .. L(pResource.Description);
			end
			
			-- JON: Not using this for now, the formatting is better when everything is on the same line
			--iNumResourcesNeededSoFar = iNumResourcesNeededSoFar + 1;
		end
 	end
	
	-- Pre-written Help text
	if (not pUnitInfo.Help) then
		print("Invalid unit help");
		print(strHelpText);
	else
		local strWrittenHelpText = L( pUnitInfo.Help );
		if (strWrittenHelpText ~= nil and strWrittenHelpText ~= "") then
			-- Separator
			strHelpText = strHelpText .. "[NEWLINE]----------------[NEWLINE]";
			strHelpText = strHelpText .. strWrittenHelpText;
		end	
	end
	
	
	-- Requirements?
	if (bIncludeRequirementsInfo) then
		if (pUnitInfo.Requirements) then
			strHelpText = strHelpText .. L( pUnitInfo.Requirements );
		end
	end
	
	return strHelpText;
end
-------------------------------------------------------------------------------------------------
GetHelpTextForBuilding = GetHelpTextForBuilding or function(iBuildingID, bExcludeName, bExcludeHeader, bNoMaintenance)
	local pBuildingInfo = GameInfo.Buildings[iBuildingID];
	
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local pActiveTeam = Teams[Game.GetActiveTeam()];
	
	local buildingClass = GameInfo.Buildings[iBuildingID].BuildingClass;
	local buildingClassID = GameInfo.BuildingClasses[buildingClass].ID;
	
	
	local strHelpText = "";
	
	if (not bExcludeHeader) then
		
		if (not bExcludeName) then
			-- Name
			strHelpText = strHelpText .. Locale.ToUpper(L( pBuildingInfo.Description ));
			strHelpText = strHelpText .. "[NEWLINE]----------------[NEWLINE]";
		end
		
		-- Cost
		local iCost = pActivePlayer:GetBuildingProductionNeeded(iBuildingID);
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_COST", iCost);
		
		-- Maintenance
		if (not bNoMaintenance) then
			local iMaintenance = pBuildingInfo.GoldMaintenance;
			if (iMaintenance ~= nil and iMaintenance ~= 0) then
				strHelpText = strHelpText .. "[NEWLINE]";
				strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_MAINTENANCE", iMaintenance);
			end
		end
		
	end
	
	-- Happiness (from all sources)
	local iHappinessTotal = 0;
	local iHappiness = pBuildingInfo.Happiness;
	if (iHappiness ~= nil) then
		iHappinessTotal = iHappinessTotal + iHappiness;
	end
	local iHappiness = pBuildingInfo.UnmoddedHappiness;
	if (iHappiness ~= nil) then
		iHappinessTotal = iHappinessTotal + iHappiness;
	end
	iHappinessTotal = iHappinessTotal + pActivePlayer:GetExtraBuildingHappinessFromPolicies(iBuildingID);
	if (iHappinessTotal ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_HAPPINESS", iHappinessTotal);
	end
	
	-- Culture
	local iCulture;
	if IGE_HasGodsAndKings then
		iCulture = Game.GetBuildingYieldChange(iBuildingID, YieldTypes.YIELD_CULTURE); -- G&K
	else
		iCulture = pBuildingInfo.Culture;
	end
	if (iCulture ~= nil and iCulture ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_CULTURE", iCulture);
	end
	
	-- Defense
	local iDefense = pBuildingInfo.Defense;
	if (iDefense ~= nil and iDefense ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_DEFENSE", iDefense / 100);
	end
	
	-- Food
	local iFood = Game.GetBuildingYieldChange(iBuildingID, YieldTypes.YIELD_FOOD);
	if (iFood ~= nil and iFood ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_FOOD", iFood);
	end
	
	-- Gold Mod
	local iGold = Game.GetBuildingYieldModifier(iBuildingID, YieldTypes.YIELD_GOLD);
	iGold = iGold + pActivePlayer:GetPolicyBuildingClassYieldModifier(buildingClassID, YieldTypes.YIELD_GOLD);
	
	if (iGold ~= nil and iGold ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_GOLD", iGold);
	end
	
	-- Gold Change
	iGold = Game.GetBuildingYieldChange(iBuildingID, YieldTypes.YIELD_GOLD);
	if (iGold ~= nil and iGold ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_GOLD_CHANGE", iGold);
	end
	
	
	
	-- Science
	local iScience = Game.GetBuildingYieldModifier(iBuildingID, YieldTypes.YIELD_SCIENCE);
	iScience = iScience + pActivePlayer:GetPolicyBuildingClassYieldModifier(buildingClassID, YieldTypes.YIELD_SCIENCE);
	if (iScience ~= nil and iScience ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_SCIENCE", iScience);
	end
	
	-- Science
	local iScienceChange = Game.GetBuildingYieldChange(iBuildingID, YieldTypes.YIELD_SCIENCE);
	if (iScienceChange ~= nil and iScienceChange ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_SCIENCE_CHANGE", iScienceChange);
	end
	
	-- Production
	local iProduction = Game.GetBuildingYieldModifier(iBuildingID, YieldTypes.YIELD_PRODUCTION);
	iProduction = iProduction + pActivePlayer:GetPolicyBuildingClassYieldModifier(buildingClassID, YieldTypes.YIELD_PRODUCTION);
	if (iProduction ~= nil and iProduction ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_PRODUCTION", iProduction);
	end

	-- Production Change
	local iProd = Game.GetBuildingYieldChange(iBuildingID, YieldTypes.YIELD_PRODUCTION);
	if (iProd ~= nil and iProd ~= 0) then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_PRODUCTION_CHANGE", iProd);
	end
	
	-- Faith
	if IGE_HasGodsAndKings then
		local iFaith = Game.GetBuildingYieldChange(iBuildingID, YieldTypes.YIELD_FAITH); -- G&K
		if (iFaith ~= nil and iFaith ~= 0) then
			strHelpText = strHelpText .. "[NEWLINE]";
			strHelpText = strHelpText .. L("TXT_KEY_PRODUCTION_BUILDING_FAITH", iCulture);
		end
	end

	-- Great People
	local specialistType = pBuildingInfo.SpecialistType;
	if specialistType ~= nil then
		local iNumPoints = pBuildingInfo.GreatPeopleRateChange;
		if (iNumPoints > 0) then
			strHelpText = strHelpText .. "[NEWLINE]";
			strHelpText = strHelpText .. "[ICON_GREAT_PEOPLE] " .. L(GameInfo.Specialists[specialistType].GreatPeopleTitle) .. " " .. iNumPoints;
		end
		
		if(pBuildingInfo.SpecialistCount > 0) then
			strHelpText = strHelpText .. "[NEWLINE]";
			
			-- Append a key such as TXT_KEY_SPECIALIST_ARTIST_SLOTS
			local specialistSlotsKey = GameInfo.Specialists[specialistType].Description .. "_SLOTS";
			strHelpText = strHelpText .. "[ICON_GREAT_PEOPLE] " .. L(specialistSlotsKey) .. " " .. pBuildingInfo.SpecialistCount;
		end
		
		
	end
	
	-- Pre-written Help text
	if (pBuildingInfo.Help ~= nil) then
		local strWrittenHelpText = L( pBuildingInfo.Help );
		if (strWrittenHelpText ~= nil and strWrittenHelpText ~= "") then
			-- Separator
			strHelpText = strHelpText .. "[NEWLINE]----------------[NEWLINE]";
			strHelpText = strHelpText .. strWrittenHelpText;
		end
	end
	
	return strHelpText;
end

-------------------------------------------------------------------------------------------------
GetFoodTooltip = GetFoodTooltip or function(pCity)
	
	local iYieldType = YieldTypes.YIELD_FOOD;
	local strFoodToolTip = "";
	
	if (not OptionsManager.IsNoBasicHelp()) then
		strFoodToolTip = strFoodToolTip .. L("TXT_KEY_FOOD_HELP_INFO");
		strFoodToolTip = strFoodToolTip .. "[NEWLINE][NEWLINE]";
	end
	
	local fFoodProgress = pCity:GetFoodTimes100() / 100;
	local iFoodNeeded = pCity:GrowthThreshold();
	
	strFoodToolTip = strFoodToolTip .. L("TXT_KEY_FOOD_PROGRESS", fFoodProgress, iFoodNeeded);
	
	strFoodToolTip = strFoodToolTip .. "[NEWLINE][NEWLINE]";
	strFoodToolTip = strFoodToolTip .. GetYieldTooltipHelper(pCity, iYieldType, "[ICON_FOOD]");
	
	return strFoodToolTip;
end

-------------------------------------------------------------------------------------------------
GetGoldTooltip = GetGoldTooltip or function(pCity)
	
	local iYieldType = YieldTypes.YIELD_GOLD;

	local strGoldToolTip = "";
	if (not OptionsManager.IsNoBasicHelp()) then
		strGoldToolTip = strGoldToolTip .. L("TXT_KEY_GOLD_HELP_INFO");
		strGoldToolTip = strGoldToolTip .. "[NEWLINE][NEWLINE]";
	end
	
	strGoldToolTip = strGoldToolTip .. GetYieldTooltipHelper(pCity, iYieldType, "[ICON_GOLD]");
	
	return strGoldToolTip;
end

-------------------------------------------------------------------------------------------------
GetScienceTooltip = GetScienceTooltip or function(pCity)
	
	local strScienceToolTip = "";

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)) then
		strScienceToolTip = L("TXT_KEY_TOP_PANEL_SCIENCE_OFF_TOOLTIP");
	else

		local iYieldType = YieldTypes.YIELD_SCIENCE;
	
		if (not OptionsManager.IsNoBasicHelp()) then
			strScienceToolTip = strScienceToolTip .. L("TXT_KEY_SCIENCE_HELP_INFO");
			strScienceToolTip = strScienceToolTip .. "[NEWLINE][NEWLINE]";
		end
	
		strScienceToolTip = strScienceToolTip .. GetYieldTooltipHelper(pCity, iYieldType, "[ICON_RESEARCH]");
	end
	
	return strScienceToolTip;
end

-------------------------------------------------------------------------------------------------
GetProductionTooltip = GetProductionTooltip or function(pCity)

	local iBaseProductionPT = pCity:GetBaseYieldRate(YieldTypes.YIELD_PRODUCTION);
	local iProductionPerTurn = pCity:GetCurrentProductionDifferenceTimes100(false, false) / 100;--pCity:GetYieldRate(YieldTypes.YIELD_PRODUCTION);
	local strCodeToolTip = pCity:GetYieldModifierTooltip(YieldTypes.YIELD_PRODUCTION);
	
	local strProductionBreakdown = GetYieldTooltip(pCity, YieldTypes.YIELD_PRODUCTION, iBaseProductionPT, iProductionPerTurn, "[ICON_PRODUCTION]", strCodeToolTip);
	
	-- Basic explanation of production
	local strProductionHelp = "";
	if (not OptionsManager.IsNoBasicHelp()) then
		strProductionHelp = strProductionHelp .. L("TXT_KEY_PRODUCTION_HELP_INFO");
		strProductionHelp = strProductionHelp .. "[NEWLINE][NEWLINE]";
		--Controls.ProductionButton:SetToolTipString(L("TXT_KEY_CITYVIEW_CHANGE_PROD_TT"));
	else
		--Controls.ProductionButton:SetToolTipString(L("TXT_KEY_CITYVIEW_CHANGE_PROD"));
	end
	
	return strProductionHelp .. strProductionBreakdown;
end

-------------------------------------------------------------------------------------------------
GetCultureTooltip = GetCultureTooltip or function(pCity)
	
	local strCultureToolTip = "";
	
	if (not OptionsManager.IsNoBasicHelp()) then
		strCultureToolTip = strCultureToolTip .. L("TXT_KEY_CULTURE_HELP_INFO");
		strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
	end
	
	local bFirst = true;
	
	-- Culture from Buildings
	local iCultureFromBuildings = pCity:GetJONSCulturePerTurnFromBuildings();
	if (iCultureFromBuildings ~= 0) then
		
		-- Spacing
		if (bFirst) then
			bFirst = false;
		else
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
		end
		
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_FROM_BUILDINGS", iCultureFromBuildings);
	end
	
	-- Culture from Policies
	local iCultureFromPolicies = pCity:GetJONSCulturePerTurnFromPolicies();
	if (iCultureFromPolicies ~= 0) then
		
		-- Spacing
		if (bFirst) then
			bFirst = false;
		else
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
		end
		
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_FROM_POLICIES", iCultureFromPolicies);
	end
	
	-- Culture from Specialists
	local iCultureFromSpecialists = pCity:GetJONSCulturePerTurnFromSpecialists();
	if (iCultureFromSpecialists ~= 0) then
		
		-- Spacing
		if (bFirst) then
			bFirst = false;
		else
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
		end
		
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_FROM_SPECIALISTS", iCultureFromSpecialists);
	end
	
	-- Culture from Terrain
	local iCultureFromTerrain = 0;
	if IGE_HasGodsAndKings then
		iCultureFromTerrain = pCity:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_CULTURE);
	else
		iCultureFromTerrain = pCity:GetJONSCulturePerTurnFromTerrain();
	end
	if (iCultureFromTerrain ~= 0) then
		
		-- Spacing
		if (bFirst) then
			bFirst = false;
		else
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
		end
		
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_FROM_TERRAIN", iCultureFromTerrain);
	end

	-- Culture from Traits
	local iCultureFromTraits = pCity:GetJONSCulturePerTurnFromTraits();
	if (iCultureFromTraits ~= 0) then
		
		-- Spacing
		if (bFirst) then
			bFirst = false;
		else
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
		end
		
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_FROM_TRAITS", iCultureFromTraits);
	end
	
	-- Empire Culture modifier
	local iAmount = Players[pCity:GetOwner()]:GetCultureCityModifier();
	if (iAmount ~= 0) then
		strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_PLAYER_MOD", iAmount);
	end
	
	-- City Culture modifier
	local iAmount = pCity:GetCultureRateModifier();
	if (iAmount ~= 0) then
		strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
		strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_CITY_MOD", iAmount);
	end
	
	-- Culture Wonders modifier
	if (pCity:GetNumWorldWonders() > 0) then
		iAmount = Players[pCity:GetOwner()]:GetCultureWonderMultiplier();
		
		if (iAmount ~= 0) then
			strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
			strCultureToolTip = strCultureToolTip .. "[ICON_BULLET]" .. L("TXT_KEY_CULTURE_WONDER_BONUS", iAmount);
		end
	end
	
	-- Tile growth
	local iCulturePerTurn = pCity:GetJONSCulturePerTurn();
	local iCultureStored = pCity:GetJONSCultureStored();
	local iCultureNeeded = pCity:GetJONSCultureThreshold();

	strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
	strCultureToolTip = strCultureToolTip .. L("TXT_KEY_CULTURE_INFO", iCultureStored, iCultureNeeded);
	
	if iCulturePerTurn > 0 then
		local iCultureDiff = iCultureNeeded - iCultureStored;
		local iCultureTurns = math.ceil(iCultureDiff / iCulturePerTurn);
		strCultureToolTip = strCultureToolTip .. " " .. L("TXT_KEY_CULTURE_TURNS", iCultureTurns);
	end
	
	return strCultureToolTip;
end

-------------------------------------------------------------------------------------------------
GetIGEHelpTextForUnit = function(row, activePlayer)
	local help = "";
	help = help..L("TXT_KEY_PRODUCTION_COST", activePlayer:GetUnitProductionNeeded(row.ID));
	help = help.."[NEWLINE]"..L("TXT_KEY_PRODUCTION_MOVEMENT", row.Moves);
	if (row.Range ~= 0) then
		help = help.."[NEWLINE]"..L("TXT_KEY_PRODUCTION_RANGE", row.Range);
	end
	if (row.RangedCombat ~= 0) then
		help = help.."[NEWLINE]"..L("TXT_KEY_PRODUCTION_RANGED_STRENGTH", row.RangedCombat);
	end
	if (row.Combat ~= 0) then
		help = help.."[NEWLINE]"..L("TXT_KEY_PRODUCTION_STRENGTH", row.Combat);
	end
	if row.Help then
		local subHelp = L(row.Help);
		if (strWrittenHelpText ~= nil and strWrittenHelpText ~= "") then
			help = help.."[NEWLINE]"..subHelp;
		end
	end
	if (row.Requirements) then
		help = help.."[NEWLINE]"..L(row.Requirements);
	end
	return help
end

-------------------------------------------------------------------------------------------------
GetIGEHelpTextForTech = function(tech)
	local help = "";

	if #tech.prereqs > 0 then
		help = L("TXT_KEY_IGE_TECH_PREREQ").." "..implode(tech.prereqs, "name", ", ");
	end

	if #tech.buildings > 0 then
		if help ~= "" then 
			help = help.."[NEWLINE]";
		end
		help = help.."[COLOR_CYAN][ICON_BULLET]"..implode(tech.buildings, "name", "[NEWLINE][ICON_BULLET]").."[ENDCOLOR]";
	end

	if #tech.wonders > 0 then
		if help ~= "" then 
			help = help.."[NEWLINE]";
		end
		help = help.."[COLOR_XP_BLUE][ICON_BULLET]"..implode(tech.wonders, "name", "[NEWLINE][ICON_BULLET]").."[ENDCOLOR]";
	end

	if #tech.units > 0 then
		if help ~= "" then 
			help = help.."[NEWLINE]";
		end
		help = help.."[COLOR_UNIT_TEXT][ICON_BULLET]"..implode(tech.units, "name", "[NEWLINE][ICON_BULLET]").."[ENDCOLOR]";
	end

	if help ~= "" then help = help.."[NEWLINE]" end
	return help
end