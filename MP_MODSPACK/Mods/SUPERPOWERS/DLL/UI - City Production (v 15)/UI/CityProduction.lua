print("This is the 'UI - City Production' mod script.")

include("IconSupport")
include("InstanceManager")

local g_ProductionManager = InstanceManager:new("CityProduction", "City", Controls.ProductionStack)

local g_SortTable = {}
local g_ActiveSort = "status"
local g_ReverseSort = false

local g_StatusIcons = {"[ICON_CAPITAL]", "", "[ICON_OCCUPIED]", "[ICON_PUPPET]", "[ICON_RESISTANCE]", "[ICON_RAZING]"}
local g_StatusToolTips = {"TXT_KEY_CP_STATUS_CAPITAL_TT", "", "TXT_KEY_CP_STATUS_OCCUPIED_TT", "TXT_KEY_CP_STATUS_PUPPET_TT", "TXT_KEY_CP_STATUS_RESISTANCE_TT", "TXT_KEY_CP_STATUS_RAZING_TT"}

local g_ControllablePuppets = false


function OnSort(sort)
  if (sort == g_ActiveSort) then
    g_ReverseSort = not g_ReverseSort
  else
    g_ReverseSort = not (sort == "name" or sort == "status" or sort == "buildTurns")
    g_ActiveSort = sort
  end

  Controls.ProductionStack:SortChildren(SortByValue)
end
Controls.SortPop:RegisterCallback(Mouse.eLClick, function() OnSort("pop") end)
Controls.SortIcon:RegisterCallback(Mouse.eLClick, function() OnSort("status") end)
Controls.SortName:RegisterCallback(Mouse.eLClick, function() OnSort("name") end)
Controls.SortProduction:RegisterCallback(Mouse.eLClick, function() OnSort("production") end)
Controls.SortFood:RegisterCallback(Mouse.eLClick, function() OnSort("food") end)
Controls.SortScience:RegisterCallback(Mouse.eLClick, function() OnSort("science") end)
Controls.SortGold:RegisterCallback(Mouse.eLClick, function() OnSort("gold") end)
Controls.SortCulture:RegisterCallback(Mouse.eLClick, function() OnSort("culture") end)
Controls.SortFaith:RegisterCallback(Mouse.eLClick, function() OnSort("faith") end)
Controls.AllFocusDefault:RegisterCallback(Mouse.eLClick, function() OnSort("focusDefault") end)
Controls.AllFocusProduction:RegisterCallback(Mouse.eLClick, function() OnSort("focusProduction") end)
Controls.AllFocusFood:RegisterCallback(Mouse.eLClick, function() OnSort("focusFood") end)
Controls.AllFocusScience:RegisterCallback(Mouse.eLClick, function() OnSort("focusScience") end)
Controls.AllFocusGold:RegisterCallback(Mouse.eLClick, function() OnSort("focusGold") end)
Controls.AllFocusCulture:RegisterCallback(Mouse.eLClick, function() OnSort("focusCulture") end)
Controls.AllFocusFaith:RegisterCallback(Mouse.eLClick, function() OnSort("focusFaith") end)
Controls.AllFocusGP:RegisterCallback(Mouse.eLClick, function() OnSort("focusGP") end)
Controls.SortManualTiles:RegisterCallback(Mouse.eLClick, function() OnSort("manualTiles") end)
Controls.SortManualSpecialists:RegisterCallback(Mouse.eLClick, function() OnSort("manualSpecialists") end)
Controls.SortManualGrowth:RegisterCallback(Mouse.eLClick, function() OnSort("manualGrowth") end)
Controls.SortBuildIcon:RegisterCallback(Mouse.eLClick, function() OnSort("buildInfo") end)
Controls.SortBuildProgress:RegisterCallback(Mouse.eLClick, function() OnSort("buildProgress") end)
Controls.SortBuildTurns:RegisterCallback(Mouse.eLClick, function() OnSort("buildTurns") end)

function SortByValue(a, b)
  local entryA = g_SortTable[tostring(a)]
  local entryB = g_SortTable[tostring(b)]

  if (entryA == nil or entryB == nil) then
    return tostring(a) < tostring(b)
  end

  local valueA = entryA[g_ActiveSort]
  local valueB = entryB[g_ActiveSort]

  if (valueA == valueB) then
    valueA = entryA.name
    valueB = entryB.name
  elseif (g_ReverseSort) then
    valueA = entryB[g_ActiveSort]
    valueB = entryA[g_ActiveSort]
  end

  if (valueA == nil or valueB == nil) then
    return tostring(a) < tostring(b)
  end

  return valueA < valueB
end

function OnCity(pCity)
  -- From CityBannerManager
  if (pCity:IsPuppet()) then
    Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_ANNEX_CITY, Data1=pCity:GetID(), Data2=-1, Data3=-1, Option1=false, Option2=false})
  else
    UI.DoSelectCityAtPlot(pCity:Plot())
  end
end

function OnFocus(pCity, focusType)
  if (pCity:GetFocusType() ~= focusType) then
    print(string.format("Changing focus of %s to %i", pCity:GetName(), focusType))
    Network.SendSetCityAIFocus(pCity:GetID(), focusType)
  end
end

function OnFocusAll(focusType)
  for pCity in Players[Game.GetActivePlayer()]:Cities() do
    if (not pCity:IsPuppet()) then
      OnFocus(pCity, focusType)
    end
  end
end
Controls.AllFocusDefault:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE) end)
Controls.AllFocusProduction:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION) end)
Controls.AllFocusFood:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD) end)
Controls.AllFocusScience:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE) end)
Controls.AllFocusGold:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD) end)
Controls.AllFocusCulture:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE) end)
Controls.AllFocusFaith:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH) end)
Controls.AllFocusGP:RegisterCallback(Mouse.eRClick, function() OnFocusAll(CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE) end)


function UpdateData(iPlayer)
  local pPlayer = Players[iPlayer]
	CivIconHookup(iPlayer, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true)

  g_ProductionManager:ResetInstances()
  g_SortTable = {}

  Controls.PuppetWarning:SetHide(true)

  for pCity in pPlayer:Cities() do
    local instance = g_ProductionManager:GetInstance()
    local sort = {}
    g_SortTable[tostring(instance.City)] = sort

    sort.pop = pCity:GetPopulation()
    instance.Pop:SetText(pCity:GetPopulation())
    local iStatus = pCity:IsRazing() and 6 or
                    pCity:IsResistance() and 5 or
                    pCity:IsPuppet() and 4 or
                   (pCity:IsOccupied() and not pCity:IsNoOccupiedUnhappiness()) and 3 or
                    pCity:IsCapital() and 1 or 2
    sort.status = iStatus
    instance.Icon:SetText(g_StatusIcons[iStatus])
    instance.Icon:SetToolTipString(Locale.ConvertTextKey(g_StatusToolTips[iStatus]))
    sort.name = pCity:GetName()
    instance.Name:SetText(pCity:GetName())
    instance.Name:RegisterCallback(Mouse.eLClick, function() OnCity(pCity) end)

		local productionYield = pCity:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
    sort.production = math.floor(productionYield + (productionYield * (pCity:GetProductionModifier() / 100)))
    instance.Production:SetText(sort.production)
    sort.food = pCity:FoodDifference()
    if (sort.food >= 0) then
      instance.Food:SetText(sort.food)
    else
      instance.Food:SetText(string.format("[COLOR_WARNING_TEXT]%i[ENDCOLOR]", sort.food))
    end
    sort.science = pCity:GetYieldRate(YieldTypes.YIELD_SCIENCE)
    instance.Science:SetText(sort.science)
    sort.gold = pCity:GetYieldRate(YieldTypes.YIELD_GOLD)
    instance.Gold:SetText(sort.gold)
    sort.culture = pCity:GetJONSCulturePerTurn()
    instance.Culture:SetText(sort.culture)
    sort.faith = pCity:GetFaithPerTurn()
    instance.Faith:SetText(sort.faith)

    local focusType = pCity:GetFocusType()
    sort.focusDefault = (focusType == CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE) and 1 or 0
    instance.FocusDefault:SetText((focusType == CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE) and "[ICON_RANGE_STRENGTH]" or "[ICON_BULLET]")
    instance.FocusDefault:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.NO_CITY_AI_FOCUS_TYPE) end)
    sort.focusProduction = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION) and 1 or 0
    instance.FocusProduction:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION) and "[ICON_PRODUCTION]" or "[ICON_BULLET]")
    instance.FocusProduction:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION) end)
    sort.focusFood = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD) and 1 or 0
    instance.FocusFood:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD) and "[ICON_FOOD]" or "[ICON_BULLET]")
    instance.FocusFood:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD) end)
    sort.focusScience = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE) and 1 or 0
    instance.FocusScience:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE) and "[ICON_RESEARCH]" or "[ICON_BULLET]")
    instance.FocusScience:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE) end)
    sort.focusGold = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD) and 1 or 0
    instance.FocusGold:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD) and "[ICON_GOLD]" or "[ICON_BULLET]")
    instance.FocusGold:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD) end)
    sort.focusCulture = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE) and 1 or 0
    instance.FocusCulture:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE) and "[ICON_CULTURE]" or "[ICON_BULLET]")
    instance.FocusCulture:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE) end)
    sort.focusFaith = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH) and 1 or 0
    instance.FocusFaith:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH) and "[ICON_PEACE]" or "[ICON_BULLET]")
    instance.FocusFaith:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FAITH) end)
    sort.focusGP = (focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE) and 1 or 0
    instance.FocusGP:SetText((focusType == CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE) and "[ICON_GREAT_PEOPLE]" or "[ICON_BULLET]")
    instance.FocusGP:RegisterCallback(Mouse.eLClick, function() OnFocus(pCity, CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PEOPLE) end)

    if (pCity:IsPuppet() and g_ControllablePuppets == false and focusType ~= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD) then
      Controls.PuppetWarning:SetHide(false)
    end

    sort.manualTiles = (pCity:GetNumForcedWorkingPlots() > 0) and 1 or 0
    instance.ManualTiles:SetText((sort.manualTiles == 1) and "[ICON_LOCKED]" or "")
    instance.ManualTiles:SetToolTipString((sort.manualTiles == 1) and Locale.ConvertTextKey("TXT_KEY_CP_MANUAL_TILES_TT") or "")
    sort.manualSpecialists = pCity:IsNoAutoAssignSpecialists() and 1 or 0
    instance.ManualSpecialists:SetText((sort.manualSpecialists == 1) and "[ICON_CITIZEN]" or "")
    instance.ManualSpecialists:SetToolTipString((sort.manualSpecialists == 1) and Locale.ConvertTextKey("TXT_KEY_CP_MANUAL_CITIZENS_TT") or "")
    sort.manualGrowth = pCity:IsForcedAvoidGrowth() and 1 or 0
    instance.ManualGrowth:SetText((sort.manualGrowth == 1) and "[ICON_TEAM_2]" or "")
    instance.ManualGrowth:SetToolTipString((sort.manualGrowth == 1) and Locale.ConvertTextKey("TXT_KEY_CP_MANUAL_GROWTH_TT") or "")

		local unitProduction = pCity:GetProductionUnit()
		local buildingProduction = pCity:GetProductionBuilding()
		local projectProduction = pCity:GetProductionProject()
		local processProduction = pCity:GetProductionProcess()

    local buildInfo = nil

		if (unitProduction ~= -1) then
			buildInfo = GameInfo.Units[unitProduction]
      sort.buildProgress, sort.buildTurns = UpdateProduction(pCity, instance.BuildProgress, instance.BuildTurns)
		elseif (buildingProduction ~= -1) then
			buildInfo = GameInfo.Buildings[buildingProduction]
      sort.buildProgress, sort.buildTurns = UpdateProduction(pCity, instance.BuildProgress, instance.BuildTurns)
		elseif (projectProduction ~= -1) then
			buildInfo = GameInfo.Projects[projectProduction]
      sort.buildProgress, sort.buildTurns = UpdateProduction(pCity, instance.BuildProgress, instance.BuildTurns)
    else
      instance.BuildProgress:SetHide(true)
      instance.BuildTurns:SetHide(true)
      sort.buildProgress = -1
      sort.buildTurns = 9999

		  if (processProduction ~= -1) then
			  buildInfo = GameInfo.Processes[processProduction]
      end
		end

    if (buildInfo ~= nil) then
      sort.buildInfo = buildInfo.Type

      if (IconHookup(buildInfo.PortraitIndex, 45, buildInfo.IconAtlas, instance.BuildImage)) then
        instance.BuildImage:SetHide(false)
        instance.BuildImage:SetToolTipString(Locale.ConvertTextKey(buildInfo.Description))
      else
        instance.BuildImage:SetHide(true)
      end
    else
      sort.buildInfo = ""
      instance.BuildImage:SetHide(true)
    end
  end

  Controls.ProductionStack:SortChildren(SortByValue)
  Controls.ProductionStack:CalculateSize()
  Controls.ProductionScrollPanel:CalculateInternalSize()
end

function UpdateProduction(pCity, meter, turns)
  local iTotalProd = pCity:GetProductionNeeded()
  local iCurrentProd = math.floor(pCity:GetProductionTimes100() / 100)
  local iTurnProd = pCity:GetCurrentProductionDifferenceTimes100(false, false) / 100
  
  local fProdThisTurn = (iTotalProd > 0) and (iCurrentProd / iTotalProd) or 0
  local fProdNextTurn = (iTotalProd > 0) and ((iCurrentProd + iTurnProd) / iTotalProd) or 0
  if (fProdNextTurn > 1) then fProdNextTurn = 1 end
  meter:SetPercents(fProdThisTurn, fProdNextTurn)
  meter:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_CP_BUILD_PROGRESS_TT", iCurrentProd, iTotalProd))
  
  local iTurns = pCity:GetProductionTurnsLeft()
  if (iTurns > 99) then
    turns:SetText("[ICON_PLUS]")
  else
    turns:SetText(tostring(iTurns))
  end

  meter:SetHide(false)
  turns:SetHide(false)

  return fProdThisTurn, iTurns
end

function OnClose()
  ContextPtr:SetHide(true)
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose)

function InputHandler(uiMsg, wParam, lParam)
  if (uiMsg == KeyEvents.KeyDown) then
    if (wParam == Keys.VK_ESCAPE) then
      OnClose()
      return true
    end
  end
end
ContextPtr:SetInputHandler(InputHandler)

function OnCityViewUpdate()
  if (not ContextPtr:IsHidden()) then
    UpdateData(Game.GetActivePlayer())
  end
end
Events.SerialEventCityInfoDirty.Add(OnCityViewUpdate)
LuaEvents.CityProductionDisplay.Add(function() ContextPtr:SetHide(false) end)

local wasHidden
function OnEnterCityScreen()
  wasHidden = ContextPtr:IsHidden()
  ContextPtr:SetHide(true);
end
Events.SerialEventEnterCityScreen.Add(OnEnterCityScreen)

function OnExitCityScreen()
  ContextPtr:SetHide(wasHidden)
end
Events.SerialEventExitCityScreen.Add(OnExitCityScreen)

function ShowHideHandler(bIsHide, bInitState)
  if (not bInitState and not bIsHide) then
    OnCityViewUpdate()
  end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)

ContextPtr:SetHide(true)


function OnDiploCornerPopup()
  ContextPtr:SetHide(false)
end

function OnAdditionalInformationDropdownGatherEntries(additionalEntries)
  table.insert(additionalEntries, {text=Locale.ConvertTextKey("TXT_KEY_CP_DIPLO_CORNER_HOOK"), call=OnDiploCornerPopup, art="EUI_DC45_CityProduction.dds"})
end
LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries)
LuaEvents.RequestRefreshAdditionalInformationDropdownEntries()

if (GameInfo.CustomModOptions ~= nil) then
	for row in GameInfo.CustomModOptions{Name = "UI_CITY_PRODUCTION"} do
		g_ControllablePuppets = (row.Value == 1)
	end
end
print(string.format("Puppets %s controllable", (g_ControllablePuppets and "are" or "are NOT")))
