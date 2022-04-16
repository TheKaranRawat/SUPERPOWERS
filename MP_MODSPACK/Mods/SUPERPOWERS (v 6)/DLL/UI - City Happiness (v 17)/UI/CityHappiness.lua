print("This is the 'UI - City Happiness' mod script.")

include("IconSupport")
include("InstanceManager")

local bIsRegistered = false

local g_ActivePanel = "Buildings"

local g_BuildingsManager = InstanceManager:new("Buildings", "BuildingsStack", Controls.BuildingsStack)
local g_AnnexedManager = InstanceManager:new("Buildings", "BuildingsStack", Controls.CourthousesStack)
local g_PuppetsManager = InstanceManager:new("Buildings", "BuildingsStack", Controls.PuppetsStack)


function GetPlayerBuildingsHappiness(iPlayer)
  local pPlayer = Players[iPlayer]
  g_BuildingsManager:ResetInstances()

  local coreCities = GetCoreCities(pPlayer)
  table.sort(coreCities, SortByUnhappiness)

  local happinessBuildings = GetHappinessBuildings(pPlayer)
  local iReligion = pPlayer:GetReligionCreatedByPlayer()

  for _,city in ipairs(coreCities) do
    GetBuildingsHappinessDetails(pPlayer, city, g_BuildingsManager:GetInstance(), happinessBuildings, iReligion)
  end

  Controls.BuildingsStack:CalculateSize()
  Controls.BuildingsScrollPanel:CalculateInternalSize()
end

function GetPlayerAnnexedHappiness(iPlayer)
  local pPlayer = Players[iPlayer]
  local iCourtHouse = GetPlayerCourthouse(pPlayer)
  g_AnnexedManager:ResetInstances()

  local annexedCities = GetAnnexedCities(pPlayer)
  table.sort(annexedCities, SortByUnhappiness)

  if (#annexedCities == 0) then
    Controls.CourthousesScrollPanel:SetHide(true)
    Controls.NoCourthousesLabel:SetHide(false)
  else
    Controls.CourthousesScrollPanel:SetHide(false)
    Controls.NoCourthousesLabel:SetHide(true)

    -- As we change the players expenditure in GetAnnexedHappinessDetails() while calculating happiness from Courthouses
    -- we must hide the courthouses panel to stop it being updated again within the update loop as the top panel gold changes
    Controls.CourthousesPanel:SetHide(true)
    for _,city in ipairs(annexedCities) do
      GetAnnexedHappinessDetails(pPlayer, city, g_AnnexedManager:GetInstance(), false, iCourtHouse)
    end
    Controls.CourthousesPanel:SetHide(false)
  end

  Controls.CourthousesStack:CalculateSize()
  Controls.CourthousesScrollPanel:CalculateInternalSize()
end

function GetPlayerPuppetsHappiness(iPlayer)
  local pPlayer = Players[iPlayer]
  local iCourtHouse = GetPlayerCourthouse(pPlayer)
  g_PuppetsManager:ResetInstances()

  local puppetCities = GetPuppetCities(pPlayer)
  table.sort(puppetCities, SortByUnhappiness)

  if (#puppetCities == 0) then
    Controls.PuppetsScrollPanel:SetHide(true)
    Controls.NoPuppetsLabel:SetHide(false)
  else
    Controls.PuppetsScrollPanel:SetHide(false)
    Controls.NoPuppetsLabel:SetHide(true)

    -- As we change the players expenditure in GetAnnexedHappinessDetails() while calculating happiness from Courthouses
    -- we must hide the puppets panel to stop it being updated again within the update loop as the top panel gold changes
    Controls.PuppetsPanel:SetHide(true)
    for _,city in ipairs(puppetCities) do
      GetAnnexedHappinessDetails(pPlayer, city, g_PuppetsManager:GetInstance(), true, iCourtHouse)
    end
    Controls.PuppetsPanel:SetHide(false)
  end

  Controls.PuppetsStack:CalculateSize()
  Controls.PuppetsScrollPanel:CalculateInternalSize()
end

function GetPlayerCourthouse(pPlayer)
  local iCourtHouse = GameInfoTypes.BUILDING_COURTHOUSE

  for row in DB.Query("SELECT b.ID FROM Buildings b, Civilization_BuildingClassOverrides c WHERE b.BuildingClass = c.BuildingClassType AND b.Type='BUILDING_COURTHOUSE' AND c.CivilizationType=?", GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type) do
    iCourtHouse = row.ID
  end

  return iCourtHouse
end

function GetCoreCities(pPlayer)
  local cities = {}

  for pCity in pPlayer:Cities() do
    if (not(pCity:IsPuppet() or pCity:IsRazing())) then
      local sName = pCity:GetName()
      if (pCity:IsCapital()) then
        sName = "[ICON_CAPITAL]" .. sName
      end
      table.insert(cities, {pCity=pCity, name=sName, unhappiness=LocalUnhappiness(pPlayer, pCity)})
    end
  end

  return cities
end

function GetAnnexedCities(pPlayer)
  local cities = {}

  for pCity in pPlayer:Cities() do
    if (pCity:IsOccupied() and not pCity:IsNoOccupiedUnhappiness()) then
      table.insert(cities, {pCity=pCity, name=pCity:GetName(), unhappiness=LocalUnhappiness(pPlayer, pCity)})
    end
  end

  return cities
end

function GetPuppetCities(pPlayer)
  local cities = {}

  for pCity in pPlayer:Cities() do
    if (pCity:IsPuppet()) then
      table.insert(cities, {pCity=pCity, name=pCity:GetName(), unhappiness=LocalUnhappiness(pPlayer, pCity)})
    end
  end

  return cities
end


function GetBuildingsHappinessDetails(pPlayer, city, instance, happinessBuildings, iReligion)
  local iCurrentBuilding = city.pCity:GetProductionBuilding()
  local sCurrentBuilding = ""

  instance.Name:SetText(city.name)
  if (iCurrentBuilding ~= -1) then
    sCurrentBuilding = Locale.ConvertTextKey("TXT_KEY_HAPPINESS_CITY_NAME_TT", Locale.ConvertTextKey(GameInfo.Buildings[iCurrentBuilding].Description))
  end
  instance.Name:SetToolTipString(sCurrentBuilding)

  local sHappy, iHappy
  if (city.unhappiness >= 0) then
    sHappy = "[ICON_HAPPINESS_1]"
    iHappy = city.unhappiness
  elseif (city.unhappiness > -10) then
    sHappy = "[ICON_HAPPINESS_3]"
    iHappy = -1 * city.unhappiness
  else
    sHappy = "[ICON_HAPPINESS_4]"
    iHappy = -1 * city.unhappiness
  end
  instance.Happy:SetText(sHappy .. Locale.ToNumber(iHappy, "#.##"))

  instance.B1:SetHide(true)
  instance.B2:SetHide(true)
  instance.B3:SetHide(true)
  instance.B4:SetHide(true)

  if (city.unhappiness < 0) then
    iHappy = math.ceil(-1 * city.unhappiness)

    local iB = 1
    for _, building in ipairs(CouldBuy(city.pCity, happinessBuildings, iReligion)) do
      local base = nil

      if (iB <= 4) then
        local box = instance[string.format("B%i", iB)]
        local iLimit = math.min(building.happiness, iHappy)

        if (iCurrentBuilding == building.id) then
          box:SetAlpha(0.4)
          box:SetToolTipString(sCurrentBuilding)
        else
          box:SetAlpha(1.0)
          box:SetToolTipString("")
        end

        box:SetHide(false)
		  	IconHookup(building.Index, 45, building.Atlas, instance[string.format("B%i_Icon", iB)])

        local iCost, sCostIcon
        if (building.cost > 0) then
          sCostIcon = "[ICON_GOLD]"
          iCost = building.cost
        else
          sCostIcon = "[ICON_PEACE]"
          iCost = building.faith
        end
        instance[string.format("B%i_Cost", iB)]:SetText(string.format("%s%i", sCostIcon, iCost))

        local button = instance[string.format("B%i_Button", iB)]
        button:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_HAPPINESS_BUY_BUILDING_TT", Locale.ConvertTextKey(GameInfo.Buildings[building.id].Description), iLimit, sCostIcon, iCost))
        button:RegisterCallback(Mouse.eLClick, function() BuyBuilding(city, building) end)

        for i = 1, 5, 1 do
          instance[string.format("B%i_Happy%i", iB, i)]:SetHide(i > iLimit)
        end

        iB = iB + 1
      end
    end
  end
end

function GetAnnexedHappinessDetails(pPlayer, city, instance, bPuppet, iCourtHouse)
  instance.Name:SetText((bPuppet and "[ICON_PUPPET]" or "[ICON_OCCUPIED]") .. city.name)
  local sHappy, iHappy
  if (city.unhappiness >= 0) then
    sHappy = "[ICON_HAPPINESS_1]"
    iHappy = city.unhappiness
  elseif (city.unhappiness > -10) then
    sHappy = "[ICON_HAPPINESS_3]"
    iHappy = -1 * city.unhappiness
  else
    sHappy = "[ICON_HAPPINESS_4]"
    iHappy = -1 * city.unhappiness
  end
  instance.Happy:SetText(sHappy .. Locale.ToNumber(iHappy, "#.##"))

  instance.B1:SetHide(true)
  instance.B2:SetHide(true)
  instance.B3:SetHide(true)
  instance.B4:SetHide(true)

  local building = GameInfo.Buildings[iCourtHouse]
  local pCity = city.pCity

  local iHappyBefore = pPlayer:GetExcessHappiness()
--  pCity:SetPuppet(false)

  if (pCity:IsCanPurchase(true, true, -1, building.ID, -1, YieldTypes.YIELD_GOLD)) then
    local iCost = pCity:GetBuildingPurchaseCost(building.ID)

    pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_COURTHOUSE, 1)
    local iHappyAfter = pPlayer:GetExcessHappiness()
    pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_COURTHOUSE, 0)

    local iHappiness = iHappyAfter - iHappyBefore

    instance.B1:SetHide(false)
  	IconHookup(building.PortraitIndex, 45, building.IconAtlas, instance.B1_Icon)
    instance.B1_Cost:SetText(string.format("[ICON_GOLD]%i", iCost))

    local button = instance.B1_Button
    button:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_HAPPINESS_BUY_BUILDING_TT", Locale.ConvertTextKey(building.Description), iHappiness, "[ICON_GOLD]", iCost))
    button:RegisterCallback(Mouse.eLClick, function() BuyBuilding(city, {id=building.ID, cost=iCost}) end)

    for i = 1, 5, 1 do
      instance[string.format("B1_Happy%i", i)]:SetHide(i > iHappiness)
    end

    instance.B1_HappyPlus:SetHide(iHappiness <= 5)
  end

--  pCity:SetPuppet(bPuppet)
end


function LocalUnhappiness(pPlayer, pCity)
  return pCity:GetLocalHappiness() - (pPlayer:GetUnhappinessFromCityForUI(pCity)/100)
end

function CouldBuy(pCity, happinessBuildings, iReligion)
  local buildings = {}

  for _,building in pairs(happinessBuildings) do
    local iBuilding = building.ID
    local buildingClass = GameInfo.BuildingClasses[building.BuildingClass]

    if (pCity:IsCanPurchase(true, true, -1, iBuilding, -1, YieldTypes.YIELD_GOLD)) then
      if (not(buildingClass.MaxGlobalInstances > 0 or buildingClass.MaxPlayerInstances == 1 or buildingClass.MaxTeamInstances > 0)) then
        table.insert(buildings, {id=iBuilding, cost=pCity:GetBuildingPurchaseCost(iBuilding), faith=0, happiness=building.Happiness, Atlas=building.IconAtlas, Index=building.PortraitIndex})
      end
    elseif (pCity:IsCanPurchase(true, true, -1, iBuilding, -1, YieldTypes.YIELD_FAITH)) then
      if (not(buildingClass.MaxGlobalInstances > 0 or buildingClass.MaxPlayerInstances > 0 or buildingClass.MaxTeamInstances > 0)) then
        if ((pCity:GetNumFollowers(iReligion) >= building.Followers) and
            (pCity:GetPopulation() >= building.Population)) then
          table.insert(buildings, {id=iBuilding, cost=0, faith=pCity:GetBuildingFaithPurchaseCost(iBuilding), happiness=building.Happiness, Atlas=building.IconAtlas, Index=building.PortraitIndex})
        end
      end
    end
  end

  table.sort(buildings, SortByEffectiveness)

  return buildings
end

function GetHappinessBuildings(pPlayer)
  local buildings = {}

  -- Buildings that grant direct happiness
  for building in GameInfo.Buildings() do
    if (building.Happiness > 0) then
      buildings[building.ID] = {ID=building.ID, BuildingClass=building.BuildingClass, Happiness=building.Happiness, IconAtlas=building.IconAtlas, PortraitIndex=building.PortraitIndex, Population=0, Followers=0}
    end
  end

  -- Buildings that grant happiness as a result of having a policy
  for row in DB.Query("SELECT p.PolicyType, b.ID, p.Happiness FROM Buildings b, Policy_BuildingClassHappiness p WHERE p.BuildingClassType = b.BuildingClass") do
    if (pPlayer:HasPolicy(GameInfoTypes[row.PolicyType])) then
      local building = GameInfo.Buildings[row.ID]
      buildings[building.ID] = {ID=building.ID, BuildingClass=building.BuildingClass, Happiness=row.Happiness, IconAtlas=building.IconAtlas, PortraitIndex=building.PortraitIndex, Population=0, Followers=0}
    end
  end

  local beliefs = GetPlayerBeliefs(pPlayer)

  -- Buildings that grant happiness as a result of having a belief
  for row in DB.Query("SELECT p.BeliefType, b.ID, p.Happiness, x.MinPopulation, x.MinFollowers FROM Buildings b, Belief_BuildingClassHappiness p, Beliefs x WHERE p.BuildingClassType = b.BuildingClass AND p.BeliefType = x.Type") do
    if (beliefs[GameInfoTypes[row.BeliefType]]) then
      local building = GameInfo.Buildings[row.ID]
      buildings[building.ID] = {ID=building.ID, BuildingClass=building.BuildingClass, Happiness=row.Happiness, IconAtlas=building.IconAtlas, PortraitIndex=building.PortraitIndex, Population=row.MinPopulation, Followers=row.MinFollowers}
    end
  end

  -- Buildings that grant happiness as a result of having a building (usually a World Wonder)
  for row in DB.Query("SELECT p.BuildingType, b.ID, p.Happiness FROM Buildings b, Building_BuildingClassHappiness p WHERE p.BuildingClassType = b.BuildingClass") do
    if (pPlayer:CountNumBuildings(GameInfoTypes[row.BuildingType]) > 0) then
      local building = GameInfo.Buildings[row.ID]
      buildings[building.ID] = {ID=building.ID, BuildingClass=building.BuildingClass, Happiness=row.Happiness, IconAtlas=building.IconAtlas, PortraitIndex=building.PortraitIndex, Population=0, Followers=0}
    end
  end

  return buildings
end

function BuyBuilding(city, building)
  local pCity = city.pCity
  local iYield = (building.cost > 0) and YieldTypes.YIELD_GOLD or YieldTypes.YIELD_FAITH

  if (pCity:IsPuppet()) then
    pCity:SetPuppet(false)
  end

  if (pCity:IsCanPurchase(true, true, -1, building.id, -1, iYield)) then
    Game.CityPurchaseBuilding(pCity, building.id, iYield)
  end
end

function GetPlayerBeliefs(pPlayer)
  local beliefs = {}

  if (pPlayer:HasCreatedReligion()) then
    for _,belief in ipairs(Game.GetBeliefsInReligion(pPlayer:GetReligionCreatedByPlayer())) do
      beliefs[belief] = true
    end
  elseif (pPlayer:HasCreatedPantheon()) then
    beliefs[pPlayer:GetBeliefInPantheon()] = true
  end

  return beliefs
end

function SortByEffectiveness(a, b)
  local valueA, valueB

  -- Group by cost type (gold or faith) then sort by greatest happiness, then by lowest cost
  if (a.cost > 0) then
    if (b.cost > 0) then
      -- Both gold cost
      if (a.happiness == b.happiness) then
        if (a.cost == b.cost) then
          -- Same happiness, same cost, use their names!
          valueA = GameInfo.Buildings[b.id].Type
          valueB = GameInfo.Buildings[a.id].Type
        else
          valueA = b.cost
          valueB = a.cost
        end
      else
        valueA = a.happiness
        valueB = b.happiness
      end
    else
      -- A gold, B faith
      valueA = 1
      valueB = 0
    end
  elseif (b.cost > 0) then
    -- B gold, A faith
    valueA = 0
    valueB = 1
  else
    -- Both faith
    if (a.happiness == b.happiness) then
      if (a.faith == b.faith) then
        -- Same happiness, same cost, use their names!
        valueA = GameInfo.Buildings[b.id].Type
        valueB = GameInfo.Buildings[a.id].Type
      else
        valueA = b.faith
        valueB = a.faith
      end
    else
      valueA = a.happiness
      valueB = b.happiness
    end
  end

  return valueA > valueB
end

function SortByUnhappiness(a, b)
  local valueA = a.unhappiness
  local valueB = b.unhappiness

  if (valueA == valueB) then
    valueA = a.name
    valueB = b.name
  end
    
  return valueA < valueB
end


function UpdatePanels()
  if (Controls.BuildingsPanel:IsHidden() == false) then
    GetPlayerBuildingsHappiness(Game.GetActivePlayer())
  elseif (Controls.CourthousesPanel:IsHidden() == false) then
    GetPlayerAnnexedHappiness(Game.GetActivePlayer())
  elseif (Controls.PuppetsPanel:IsHidden() == false) then
    GetPlayerPuppetsHappiness(Game.GetActivePlayer())
  end
end

function OnHappiness()
  local iPlayer = Game.GetActivePlayer()
	-- Set player icon at top of screen
	CivIconHookup(iPlayer, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true)

  if (g_ActivePanel == "Buildings") then
    OnBuildingsButton()
--  elseif (g_ActivePanel == "Puppets") then
--    OnPuppetsButton()
  else
    OnCourthousesButton()
  end

  Controls.CityHappiness:SetHide(false)
end
LuaEvents.CityHappinessDisplay.Add(OnHappiness)

function OnBuildingsButton()
  g_ActivePanel = "Buildings"

  Controls.BuildingsPanel:SetHide(false)
  Controls.CourthousesPanel:SetHide(true)
  Controls.PuppetsPanel:SetHide(true)

  Controls.BuildingsSelectHighlight:SetHide(false)
  Controls.CourthousesSelectHighlight:SetHide(true)
--  Controls.PuppetsSelectHighlight:SetHide(true)

  GetPlayerBuildingsHappiness(Game.GetActivePlayer())
end
Controls.BuildingsButton:RegisterCallback(Mouse.eLClick, OnBuildingsButton)

function OnCourthousesButton()
  g_ActivePanel = "Courthouses"

  Controls.BuildingsPanel:SetHide(true)
  Controls.CourthousesPanel:SetHide(false)
  Controls.PuppetsPanel:SetHide(true)

  Controls.BuildingsSelectHighlight:SetHide(true)
  Controls.CourthousesSelectHighlight:SetHide(false)
--  Controls.PuppetsSelectHighlight:SetHide(true)

  GetPlayerAnnexedHappiness(Game.GetActivePlayer())
end
Controls.CourthousesButton:RegisterCallback(Mouse.eLClick, OnCourthousesButton)

function OnPuppetsButton()
  g_ActivePanel = "Puppets"

  Controls.BuildingsPanel:SetHide(true)
  Controls.CourthousesPanel:SetHide(true)
  Controls.PuppetsPanel:SetHide(false)

  Controls.BuildingsSelectHighlight:SetHide(true)
  Controls.CourthousesSelectHighlight:SetHide(true)
--  Controls.PuppetsSelectHighlight:SetHide(false)

  GetPlayerPuppetsHappiness(Game.GetActivePlayer())
end
--Controls.PuppetsButton:RegisterCallback(Mouse.eLClick, OnPuppetsButton)

function OnClose()
  Controls.CityHappiness:SetHide(true)
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose)

function InputHandler(uiMsg, wParam, lParam)
  -- Only process keyboard events if the pop-up window is visible
  if (Controls.CityHappiness:IsHidden() == false) then
    if (uiMsg == KeyEvents.KeyDown) then
      if (wParam == Keys.VK_ESCAPE) then
        OnClose()
        return true
      end
    end
  end
end
ContextPtr:SetInputHandler(InputHandler)

function SetActivePlayer(iPlayer, iPrevPlayer)
  if (not bIsRegistered) then
    -- This doesn't want to play nicely at load time!
	local control = ContextPtr:LookUpControl("/InGame/TopPanel/HappinessString")
    
	if (control) then
	  control:RegisterCallback(Mouse.eLClick, OnHappiness)
	  bIsRegistered = true
      Events.GameplaySetActivePlayer.Remove(SetActivePlayer)
	else
	  print("/InGame/TopPanel/HappinessString is nil!")
	end
  end
end
Events.GameplaySetActivePlayer.Add(SetActivePlayer)


function Initialise()
  if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS) == false) then
    Events.SerialEventGameDataDirty.Add(UpdatePanels)
	SetActivePlayer(0)

    OnClose()
    ContextPtr:SetHide(false)
  else
    ContextPtr:SetHide(true)
  end
end

Initialise()

function OnAdditionalInformationDropdownGatherEntries(additionalEntries)
  table.insert(additionalEntries, {text=Locale.ConvertTextKey("TXT_KEY_HAPPINESS_DIPLO_CORNER_HOOK"), call=OnHappiness, art="EUI_DC45_CityHappiness.dds",})
end
LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries)
LuaEvents.RequestRefreshAdditionalInformationDropdownEntries()
