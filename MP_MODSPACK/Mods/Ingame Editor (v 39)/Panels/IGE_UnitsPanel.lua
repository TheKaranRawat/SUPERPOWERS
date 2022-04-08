-- Released under GPL v3
--------------------------------------------------------------
include("IGE_API_All");
print("IGE_UnitsPanel");
IGE = nil;


local civilianUnits = {};
local civilianUnitManager = nil;
local civilianGroupInstance = nil;

local religiousUnits = {};
local religiousUnitManager = nil;
local religiousGroupInstance = nil;

local groupInstances = {};
local unitItemManagers = {};
local eraItemManager = CreateInstanceManager("GroupInstance", "Stack", Controls.EraList );

local data = {};
local isVisible = false;
local currentUnit = nil;
local currentLevel = 1;

local civilianClasses = {}
civilianClasses["UNITCLASS_SETTLER"] = true;
civilianClasses["UNITCLASS_WORKER"] = true;
civilianClasses["UNITCLASS_WORKBOAT"] = true;


--===============================================================================================
-- CORE EVENTS
--===============================================================================================
local function OnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function OnInitialize()
	print("IGE_UnitsPanel.OnInitialize");
	SetUnitsData(data);
	SetReligionsData(data);

	Resize(Controls.Container);
	Resize(Controls.ScrollPanel);

	civilianGroupInstance = eraItemManager:GetInstance();
	if civilianGroupInstance then
		civilianUnitManager = CreateInstanceManager("ListItemInstance", "Button", civilianGroupInstance.List );
		civilianGroupInstance.Header:SetText(L("TXT_KEY_IGE_CIVILIAN_UNITS"));
	end

	if IGE_HasGodsAndKings then
		religiousGroupInstance = eraItemManager:GetInstance();
		if religiousGroupInstance then
			religiousUnitManager = CreateInstanceManager("ListItemInstance", "Button", religiousGroupInstance.List );
			religiousGroupInstance.Header:SetText(L("TXT_KEY_IGE_RELIGIOUS_UNITS"));
			religiousGroupInstance.HeaderBackground:SetToolTipString(L("TXT_KEY_IGE_RELIGIOUS_UNITS_HELP"));
		end
	end

	-- Create era groups
	local last = 0;
	for i, v in ipairs(data.eras) do
		if #v.units > 0 then
			local instance = eraItemManager:GetInstance();
			if instance then
				local manager = CreateInstanceManager("ListItemInstance", "Button", instance.List );
				instance.Header:SetText(v.name);
				groupInstances[i] = instance;
				unitItemManagers[i] = manager;
				last = i;
			end
		end
	end
	groupInstances[last].Separator:SetHide(true);

	-- Extract civilian & religious units
	for _, era in ipairs(data.eras) do
		local i = 1;
		local units0 = era.units;
		while true do
			if not units0[i] then break end
			local unit = units0[i];
			if unit.religious then
				table.remove(units0, i);
				if not unit.isGreatPeople then
					for _, religion in pairs(data.religions) do
						if religion.ID > 0 then
							local c = clone(unit);
							c.religion = religion.ID;
							c.priority = religion.ID;
							c.subtitle = L(Game.GetReligionName(religion.ID));
							c.name = religion.iconString.." "..c.name.."*";
							c.note = L("TXT_KEY_IGE_RELIGIOUS_UNITS_WARNING");
							table.insert(religiousUnits, c);
						end
					end
				end
			elseif civilianClasses[unit.class] or unit.isGreatPeople then
				table.remove(units0, i);
				table.insert(civilianUnits, unit);
				if civilianClasses[unit.class] then unit.priority = 100 end
			else
				i = i + 1;
			end
		end
	end
	currentUnit = data.unitsByTypes["UNIT_WORKER"];

	local tt = L("TXT_KEY_IGE_UNITS_PANEL_HELP");
	LuaEvents.IGE_RegisterTab("UNITS", L("TXT_KEY_IGE_UNITS_PANEL"), 2, "paint",  tt, currentUnit)
	print("IGE_UnitsPanel.OnInitialize - Done");
end
LuaEvents.IGE_Initialize.Add(OnInitialize)

-------------------------------------------------------------------------------------------------
function OnSelectedPanel(ID)
	isVisible = (ID == "UNITS");
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel);

-------------------------------------------------------------------------------------------------
function TryPurchaseReligiousUnit(pPlayer, plot, start)
	local faith = pPlayer:GetFaith();
	local movedUnits = nil;

	-- Get first city that can train
	for i = start, pPlayer:GetNumCities() - 1, 1 do
		local city = pPlayer:GetCityByID(i);
		if city and (city:GetReligiousMajority() == currentUnit.religion) then

			-- Add cost
			local faithCost = city:GetUnitFaithPurchaseCost(currentUnit.ID, true);
			pPlayer:SetFaith(faith + faithCost);

			-- Move city units
			print("moving units");
			movedUnits = {};
			local cityPlot = city:Plot();

			-- Do it backward because some units are actually not moved and would cause an infinite loop. Fuck Civ5.
			for i = cityPlot:GetNumUnits() - 1, 0, -1 do
				local movedUnit = cityPlot:GetUnit(i);
				table.insert(movedUnits, movedUnit);
				movedUnit:SetXY(plot:GetX(), plot:GetY());
				print(movedUnit:GetUnitType());
			end

			-- Try purchase
			-- Sucess can sometimes be true while it should be false. Does not happen in the production popup, only here. Most puzzling civ5 bug ever. Fuck civ5.
			local success = city:IsCanPurchase(false, false, currentUnit.ID, -1, -1, YieldTypes.YIELD_FAITH) and city:IsCanPurchase(true, true, currentUnit.ID, -1, -1, YieldTypes.YIELD_FAITH);

			if success then
				print("purchasing unit");
				Game.CityPurchaseUnit(city, currentUnit.ID, YieldTypes.YIELD_FAITH);

				-- Schedule a check to know whether it was a success or not (faith is not immediately updated)
				LuaEvents.IGE_Schedule(5, nil, function()

					-- Did it fail?
					if pPlayer:GetFaith() ~= faith then
						pPlayer:SetFaith(faith);
						TryPurchaseReligiousUnit(pPlayer, plot, i + 1);
						return;
					end

					-- So it's a success, move the unit
					print("try to move the religious unit");
					local cityPlot = city:Plot();
					for i = 0, cityPlot:GetNumUnits() -1, 1 do
						local unit = cityPlot:GetUnit(i);
						
						if unit and (unit:GetUnitType() == currentUnit.ID and unit:GetReligion() == currentUnit.religion) then
							if (unit.SetReligion) then
								print("Woot ! Firaxis finally added a SetReligion");
							end

							print("final move");
							unit:SetXY(plot:GetX(), plot:GetY());
							break;
						end
					end
				end);
			end

			-- Move units back
			print("moving units back");
			for _, v in ipairs(movedUnits) do
				v:SetXY(cityPlot:GetX(), cityPlot:GetY());
			end

			-- This may be a false positive but quit anyway
			if success then return end
		end
	end

	-- Fail
	pPlayer:SetFaith(faith);
	LuaEvents.IGE_FloatingMessage(L("TXT_KEY_IGE_RELIGIOUS_UNITS_ERROR"));
	print("no city could create the unit");
end

-------------------------------------------------------------------------------------------------
function CreateUnit(plot)
	local pUnit;
	local pPlayer = Players[IGE.currentPlayerID];

	if currentUnit.religious then
		if not pPlayer:IsHuman() then return end
		TryPurchaseReligiousUnit(pPlayer, plot, 0);
	else
		-- Regular unit, just use a good old and straight cheat
		pUnit = pPlayer:InitUnit(currentUnit.ID, plot:GetX(), plot:GetY());

		if currentLevel ~= 1 then
			local xp = GetXPForLevel(currentLevel);
			pUnit:SetExperience(xp);
			pUnit:SetPromotionReady(true);
		end
	end

end

-------------------------------------------------------------------------------------------------
function OnPlop(mouseButtonDown, plot, shift)
	if not isVisible then return end

	if not shift then
		CreateUnit(plot);
	else
		-- Kill top unit
		local count = plot:GetNumUnits();
		if count > 0 then
			local pUnit = plot:GetUnit(count - 1);
			pUnit:Kill();
		end
	end
end
LuaEvents.IGE_Plop.Add(OnPlop);

-------------------------------------------------------------------------------------------------
function ClickHandler(unit)
	currentUnit = unit;
	OnUpdate();
	LuaEvents.IGE_SetTabData("UNITS", currentUnit);
end

--===============================================================================================
-- UPDATE
--===============================================================================================
UpdateLevel = HookNumericBox("Level", 
	function() return currentLevel end, 
	function(amount) currentLevel = amount end, 
	1, nil, 1);

-------------------------------------------------------------------------------------------------
function UpdateUnitList(units, itemManager, instance)
	for _, unit in ipairs(units) do 
		unit.selected = (unit == currentUnit);
		unit.label = unit.name;
	end

	UpdateHierarchizedList(units, itemManager, ClickHandler);

	-- Resize
	local width = instance.List:GetSizeX();
	instance.HeaderBackground:SetSizeX(width + 10);
end

-------------------------------------------------------------------------------------------------
function OnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	if currentUnit then
		LuaEvents.IGE_SetMouseMode(IGE_MODE_PLOP);
	else
		LuaEvents.IGE_SetMouseMode(IGE_MODE_NONE);
	end

	UpdateLevel(currentLevel);

	-- Religious units
	if IGE_HasGodsAndKings then
		local validReligions = {};
		if IGE.currentPlayer:IsHuman() then
			for pCity in IGE.humanPlayer:Cities() do
				validReligions[pCity:GetReligiousMajority()] = true;
			end
		end

		for _, v in ipairs(religiousUnits) do
			v.visible = validReligions[v.religion];
			v.enabled = true;
		end

		UpdateUnitList(religiousUnits, religiousUnitManager, religiousGroupInstance);
	end

	-- Units
	UpdateUnitList(civilianUnits, civilianUnitManager, civilianGroupInstance);
	for i, era in ipairs(data.eras) do
		if #era.units > 0 then
			UpdateUnitList(era.units, unitItemManagers[i], groupInstances[i]);
		end
	end	

	-- Resize
	local availableWidth = Controls.Container:GetSizeX();
	Controls.ScrollPanel:SetSizeX(availableWidth - 16);

	Controls.EraList:CalculateSize();
	Controls.EraList:ReprocessAnchoring();
    Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollPanel:ReprocessAnchoring();

	availableWidth = Controls.ScrollPanel:GetSizeX();
	Controls.ScrollBar:SetSizeX(availableWidth - 36);
end
LuaEvents.IGE_Update.Add(OnUpdate);
