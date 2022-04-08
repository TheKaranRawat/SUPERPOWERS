include("IconSupport")
include("SupportFunctions")
include("InstanceManager")
include("InfoTooltipInclude")

local isBNW = ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY)

local gPlayerIM = InstanceManager:new("TradeStatusInstance", "TradeBox", Controls.PlayerBox)
local gAiIM = InstanceManager:new("TradeStatusInstance", "TradeBox", Controls.AiStack)
local gCsIM = InstanceManager:new("CityStateInstance", "TradeBox", Controls.AiStack)

local gSortTable


function UpdateStatus()
	gPlayerIM:ResetInstances()
    gAiIM:ResetInstances()
    gCsIM:ResetInstances()
  
    local iPlayer = Game.GetActivePlayer()
    InitPlayer(iPlayer)
    InitAiList(iPlayer)
end


function ShowHideHandler(bIsHide, bIsInit)
  if (not bIsInit and not bIsHide) then
    UpdateStatus();
  end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)



function InitPlayer(iPlayer)
  GetCivControl(gPlayerIM, iPlayer, false)
end

function InitAiList(iPlayer)
  local pPlayer = Players[iPlayer]
  local pTeam = Teams[pPlayer:GetTeam()]
  local count = 0

  gSortTable = {}
  
  for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
    local pOtherPlayer = Players[iPlayerLoop]
    local iOtherTeam = pOtherPlayer:GetTeam()
    
    if (iPlayerLoop ~= iPlayer and pOtherPlayer:IsAlive()) then
      if (pTeam:IsHasMet(iOtherTeam)) then
        count = count+1
        GetCivControl(gAiIM, iPlayerLoop, true)
      end
    end
  end
	
  if (InitCsList()) then
    count = count+1
  end

  if (count == 0) then
    Controls.AiNoneMetText:SetHide(false)
    Controls.AiScrollPanel:SetHide(true)
  else
    Controls.AiNoneMetText:SetHide(true)
    Controls.AiScrollPanel:SetHide(false)

    Controls.AiStack:SortChildren(ByScore)
    Controls.AiStack:CalculateSize()
    Controls.AiStack:ReprocessAnchoring()
    Controls.AiScrollPanel:CalculateInternalSize()
  end
end

function InitCsList()
  local bCsMet = false

  local iActivePlayer = Game.GetActivePlayer()
  local pActivePlayer = Players[iActivePlayer]
  local pActiveTeam = Teams[pActivePlayer:GetTeam()]

  local controlTable = gCsIM:GetInstance()
  local iMaxY = controlTable.TradeBox:GetSizeY()

  for pLuxury in GameInfo.Resources() do
    if (pLuxury.Happiness > 0) then
      local sLuxControl = pLuxury.Type
      if (controlTable[sLuxControl] ~= nil) then
        controlTable[sLuxControl]:DestroyAllChildren()

        for iCsLoop = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS-1, 1 do
          local pCs = Players[iCsLoop]
    
          if (pCs:IsAlive() and pActiveTeam:IsHasMet(pCs:GetTeam())) then
            if (IsCsHasResource(pCs, pLuxury) or IsCsNearResource(pCs, pLuxury)) then
              local csTextControlTable = {}
              ContextPtr:BuildInstanceForControl("CityStateButtonInstance", csTextControlTable, controlTable[sLuxControl])

              csTextControlTable.CsLuxuryIcon:SetHide(true)
              csTextControlTable.CsTraitIcon:SetOffsetVal(-3,0)

              local sTrait = GameInfo.MinorCivilizations[pCs:GetMinorCivType()].MinorCivTrait
              csTextControlTable.CsTraitIcon:SetTexture(GameInfo.MinorCivTraits[sTrait].TraitIcon)
              local primaryColor, secondaryColor = pCs:GetPlayerColors()
              csTextControlTable.CsTraitIcon:SetColor({x = secondaryColor.x, y = secondaryColor.y, z = secondaryColor.z, w = 1})

              local sCsAlly = "TXT_KEY_CITY_STATE_NOBODY"

              local iCsAlly = pCs:GetAlly()
              if (iCsAlly ~= nil and iCsAlly ~= -1) then
                if (iCsAlly ~= iActivePlayer) then
                  if (pActiveTeam:IsHasMet(Players[iCsAlly]:GetTeam())) then
                    sCsAlly = Players[iCsAlly]:GetCivilizationShortDescriptionKey()
                  else
                    sCsAlly = "TXT_KEY_MISC_UNKNOWN"
                  end
                else
                  sCsAlly = "TXT_KEY_YOU"
                end
              end

              local sToolTip = Locale.ConvertTextKey(pCs:GetCivilizationShortDescriptionKey()) .. " (" .. Locale.ConvertTextKey(sCsAlly) .. ") " .. GetCsStrategics(pCs)
              sToolTip = string.format("%s %s", pLuxury.IconString, sToolTip)

              csTextControlTable.CsButton:SetToolTipString(sToolTip)
              csTextControlTable.CsButton:SetVoid1(iCsLoop)
              csTextControlTable.CsButton:RegisterCallback(Mouse.eLClick, OnCsSelected)
            end

            bCsMet = true
          end
        end

        controlTable[sLuxControl]:CalculateSize()
        controlTable[sLuxControl]:ReprocessAnchoring()

        controlTable[sLuxControl .. "_BOX"]:SetSizeY(math.max(30, controlTable[sLuxControl]:GetSizeY() + 3))

        iMaxY = math.max(iMaxY, controlTable[sLuxControl]:GetSizeY())
      end
    end
  end 

  if (not bCsMet) then
    controlTable.TradeBox:SetHide(true)
  else
    controlTable.TradeBox:SetHide(false)
    controlTable.TradeBox:SetSizeY(iMaxY+5)
  end

  return bCsMet
end

function GetCivControl(im, iPlayer, bCanTrade)
  local iActivePlayer = Game.GetActivePlayer()
  local pActivePlayer = Players[iActivePlayer]
  local iActiveTeam = pActivePlayer:GetTeam()
  local pActiveTeam = Teams[iActiveTeam]
  local bIsActivePlayer = (iActivePlayer == iPlayer)

  local pPlayer = Players[iPlayer]
  local iTeam = pPlayer:GetTeam()
  local pTeam = Teams[iTeam]
  local pCivInfo = GameInfo.Civilizations[pPlayer:GetCivilizationType()]
        
  local pDeal = UI.GetScratchDeal()

  local controlTable = im:GetInstance()
  local sortEntry = {}

  controlTable.TradeOps:SetHide(pActiveTeam:IsAtWar(iTeam) == true)
  controlTable.TradeWar:SetHide(pActiveTeam:IsAtWar(iTeam) == false)
  
  local cName = "";
  local cApproach = "";
  
  cName, cApproach = GetApproach(pActivePlayer, pPlayer, pCivInfo)

  controlTable.CivName:SetText(cName)
  CivIconHookup(iPlayer, 32, controlTable.CivSymbol, controlTable.CivIconBG, controlTable.CivIconShadow, false, true)
  controlTable.CivIconBG:SetHide(false)

  controlTable.CivButton:SetToolTipString(cApproach)

  if (bCanTrade) then        
    controlTable.CivButton:SetVoid1(iPlayer)
    controlTable.CivButton:RegisterCallback(Mouse.eLClick, OnCivSelected)

    gSortTable[tostring(controlTable.TradeBox)] = sortEntry
    sortEntry.PlayerID = iPlayer
  else
    controlTable.CivButtonHL:SetHide(true)
  end

  controlTable.RESOURCE_DYNAMIC:SetHide(true)
  controlTable.RESOURCE_DYNAMIC_TT = ""

  for pLuxury in GameInfo.Resources() do
    if (pLuxury.Happiness > 0) then
      local sText, sToolTip, iCount = GetLuxuryText(pPlayer, pLuxury, bIsActivePlayer)
      local control = controlTable[pLuxury.Type]

      if (control == nil) then
        Controls.RESOURCE_DYNAMIC_ICON:SetHide(false)

        if (iCount > 0) then
          control = controlTable.RESOURCE_DYNAMIC
          control:SetHide(false)

          sToolTip = sToolTip .. ": " .. sText

          if (controlTable.RESOURCE_DYNAMIC_TT ~= "") then
            sToolTip = controlTable.RESOURCE_DYNAMIC_TT .. "[NEWLINE]" .. sToolTip
          end

          controlTable.RESOURCE_DYNAMIC_TT = sToolTip

          control:SetText("[ICON_HAPPINESS_1]")
          control:SetToolTipString(sToolTip)
        end
      else
        control:SetText(sText)
        control:SetToolTipString(sToolTip)
      end
    end
  end 

  local sResearchIcon = ""
  local sResearchTip = ""
  if (bIsActivePlayer) then
    sResearchIcon = "[ICON_RESEARCH]"
    sResearchTip = "TXT_KEY_DO_TRADE_STATUS_RA_TT"
  else
    if (pDeal:IsPossibleToTradeItem(iPlayer, iActivePlayer, TradeableItems.TRADE_ITEM_RESEARCH_AGREEMENT, Game.GetDealDuration())) then
      sResearchIcon = "[ICON_RESEARCH]"
      sResearchTip = "TXT_KEY_DO_TRADE_STATUS_RA_YES_TT"
    elseif (pTeam:IsHasResearchAgreement(iActiveTeam)) then
      sResearchIcon = "[ICON_INFLUENCE]"
      sResearchTip = "TXT_KEY_DO_TRADE_STATUS_RA_NO_TT"
    end
  end
  controlTable.ResearchText:SetText(sResearchIcon)
  controlTable.ResearchText:SetToolTipString(Locale.ConvertTextKey(sResearchTip))

  local sEmbassyIcon = ""
  local sEmbassyTip = ""
  if (bIsActivePlayer) then
    sEmbassyIcon = "[ICON_CITY_STATE]"
    sEmbassyTip = "TXT_KEY_DO_TRADE_STATUS_EMBASSY_TT"
  else
    if (pDeal:IsPossibleToTradeItem(iPlayer, iActivePlayer, TradeableItems.TRADE_ITEM_ALLOW_EMBASSY, Game.GetDealDuration()) and
        pDeal:IsPossibleToTradeItem(iActivePlayer, iPlayer, TradeableItems.TRADE_ITEM_ALLOW_EMBASSY, Game.GetDealDuration())) then
      sEmbassyIcon = "[ICON_CITY_STATE]"
      sEmbassyTip = "TXT_KEY_DO_TRADE_STATUS_EMBASSY_YES_TT"
    elseif (pTeam:HasEmbassyAtTeam(iActiveTeam) and pActiveTeam:HasEmbassyAtTeam(iTeam)) then
      sEmbassyIcon = "[ICON_INFLUENCE]"
      sEmbassyTip = "TXT_KEY_DO_TRADE_STATUS_EMBASSY_NO_TT"
    elseif (pActiveTeam:HasEmbassyAtTeam(iTeam)) then
      sEmbassyIcon = "[ICON_CAPITAL]"
      sEmbassyTip = "TXT_KEY_DO_TRADE_STATUS_EMBASSY_US_TT"
    elseif (pTeam:HasEmbassyAtTeam(iActiveTeam)) then
      sEmbassyIcon = "[ICON_CAPITAL]"
      sEmbassyTip = "TXT_KEY_DO_TRADE_STATUS_EMBASSY_THEM_TT"
    end
  end
  controlTable.EmbassyText:SetText(sEmbassyIcon)
  controlTable.EmbassyText:SetToolTipString(Locale.ConvertTextKey(sEmbassyTip))

  local sBordersIcon = ""
  local sBordersTip = ""
  if (bIsActivePlayer) then
    sBordersIcon = "[ICON_TRADE]"
    sBordersTip = "TXT_KEY_DO_TRADE_STATUS_BORDERS_TT"
  else
    if (pDeal:IsPossibleToTradeItem(iPlayer, iActivePlayer, TradeableItems.TRADE_ITEM_OPEN_BORDERS, Game.GetDealDuration()) and
        pDeal:IsPossibleToTradeItem(iActivePlayer, iPlayer, TradeableItems.TRADE_ITEM_OPEN_BORDERS, Game.GetDealDuration())) then
      sBordersIcon = "[ICON_TRADE]"
      sBordersTip = "TXT_KEY_DO_TRADE_STATUS_BORDERS_YES_TT"
    elseif (pTeam:IsAllowsOpenBordersToTeam(iActiveTeam) and pActiveTeam:IsAllowsOpenBordersToTeam(iTeam)) then
      sBordersIcon = "[ICON_TRADE_WHITE]"
      sBordersTip = "TXT_KEY_DO_TRADE_STATUS_BORDERS_NO_TT"
    elseif (pTeam:IsAllowsOpenBordersToTeam(iActiveTeam)) then
      sBordersIcon = "[ICON_TRADE_WHITE]"
      sBordersTip = "TXT_KEY_DO_TRADE_STATUS_BORDERS_US_TT"
    elseif (pActiveTeam:IsAllowsOpenBordersToTeam(iTeam)) then
      sBordersIcon = "[ICON_TRADE_WHITE]"
      sBordersTip = "TXT_KEY_DO_TRADE_STATUS_BORDERS_THEM_TT"
    end
  end
  controlTable.BordersText:SetText(sBordersIcon)
  controlTable.BordersText:SetToolTipString(Locale.ConvertTextKey(sBordersTip))

  local sGoldText = string.format("[ICON_GOLD]%d / %d", pDeal:GetGoldAvailable(iPlayer, -1), pPlayer:CalculateGoldRate())
  local sGoldTip = "TXT_KEY_DO_TRADE_STATUS_GOLD_TT"
  controlTable.GoldText:SetText(sGoldText)
  controlTable.GoldText:SetToolTipString(Locale.ConvertTextKey(sGoldTip))

  return controlTable
end

function GetApproach(pActivePlayer, pPlayer, pCivInfo)
  local sApproach = ""
  local sName = ""
  local civDescription = Locale.ConvertTextKey(pCivInfo.ShortDescription)

  if (pActivePlayer:GetID() ~= pPlayer:GetID()) then
    if (Teams[pActivePlayer:GetTeam()]:IsAtWar(pPlayer:GetTeam())) then
      sApproach = Locale.ConvertTextKey("TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_WAR")
	  sName = string.format("[COLOR_RED]%s[ENDCOLOR]", civDescription)
    elseif (pPlayer:IsDenouncingPlayer(pActivePlayer:GetID())) then
      sApproach = Locale.ConvertTextKey("TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_DENOUNCING")
	  sName = string.format("[COLOR:225:125:0:255]%s[ENDCOLOR]", civDescription)
    else
      local iApproach = pActivePlayer:GetApproachTowardsUsGuess(pPlayer:GetID())
  
      if (iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_WAR) then
        sApproach = Locale.ConvertTextKey("TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_WAR")
		sName = string.format("[COLOR_RED]%s[ENDCOLOR]", civDescription)
      elseif (iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_HOSTILE) then
        sApproach = string.format("[COLOR:225:125:0:255]%s[ENDCOLOR]", Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_HOSTILE" ))
		sName = string.format("[COLOR:225:125:0:255]%s[ENDCOLOR]", civDescription)
      elseif (iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_GUARDED) then
        sApproach = string.format("[COLOR_YELLOW]%s[ENDCOLOR]", Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_GUARDED" ))
		sName = string.format("[COLOR_YELLOW]%s[ENDCOLOR]", civDescription)
      elseif (iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_NEUTRAL) then
        sApproach = Locale.ConvertTextKey("TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_NEUTRAL")
		sName = string.format("[COLOR_WHITE]%s[ENDCOLOR]", civDescription)
      elseif (iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_FRIENDLY) then
        sApproach = string.format("[COLOR_GREEN]%s[ENDCOLOR]", Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_FRIENDLY" ))
		sName = string.format("[COLOR_GREEN]%s[ENDCOLOR]", civDescription)
      elseif (iApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_AFRAID) then
        sApproach = string.format("[COLOR_MAGENTA]%s[ENDCOLOR]", Locale.ConvertTextKey( "TXT_KEY_DIPLO_MAJOR_CIV_DIPLO_STATE_AFRAID" ))
		sName = string.format("[COLOR_MAGENTA]%s[ENDCOLOR]", civDescription)
      end
    end
  else
	sName = string.format("[COLOR_CYAN]%s[ENDCOLOR]", civDescription)
  end

  if (sApproach ~= "") then
    sApproach = sApproach .. "[NEWLINE]" .. GetMoodInfo(pPlayer:GetID())
  end

  return sName, sApproach
end

function ByScore(a, b)
  local entryA = gSortTable[tostring(a)]
  local entryB = gSortTable[tostring(b)]

  if ((entryA == nil) or (entryB == nil)) then 
    if ((entryA ~= nil) and (entryB == nil)) then
      return true
    elseif ((entryA == nil) and (entryB ~= nil)) then
      return false
    else
      return (tostring(a) < tostring(b)) -- gotta do something!
    end
  end

  return (Players[entryA.PlayerID]:GetScore() > Players[entryB.PlayerID]:GetScore())
end


function GetLuxuryText(pPlayer, pLuxury, bIsActivePlayer)
  local iLuxury = pLuxury.ID

  local sColourStart = "[COLOR_GREY]"
  local sText = ""
  local sToolTip = ""
  local iTotal = 0

  if (IsAvailableLuxury(iLuxury)) then
    local iMinors  = pPlayer:GetResourceFromMinors(iLuxury)
    local iExports = pPlayer:GetResourceExport(iLuxury)
    local iImports = pPlayer:GetResourceImport(iLuxury)
    local iLocal   = pPlayer:GetNumResourceTotal(iLuxury, false) + iExports
    local iSurplus = iLocal - iExports

    iTotal = iLocal + iMinors + iImports - iExports

    if (bIsActivePlayer) then
      if (iSurplus > 0) then
        sColourStart = "[COLOR_GREEN]"
      end

      if (iTotal <= 0) then
        sToolTip = GetGoldenAgeCities(pPlayer, pLuxury)

        if (sToolTip ~= "") then
          sColourStart = "[COLOR_YELLOW]"
        else
          sColourStart = "[COLOR_RED]"
        end
      end

      if (sToolTip == "") then
        sToolTip = string.format("%s %s", pLuxury.IconString, Locale.ConvertTextKey(pLuxury.Description))
      end
    else
      local pActivePlayer = Players[Game.GetActivePlayer()]

      local iActiveMinors  = pActivePlayer:GetResourceFromMinors(iLuxury)
      local iActiveExports = pActivePlayer:GetResourceExport(iLuxury)
      local iActiveImports = pActivePlayer:GetResourceImport(iLuxury)
      local iActiveLocal   = pActivePlayer:GetNumResourceTotal(iLuxury, false) + iActiveExports

      local iActiveTotal   = iActiveLocal + iActiveMinors + iActiveImports - iActiveExports
      local iActiveSurplus = iActiveLocal - iActiveExports

      if (iSurplus > 1 and iActiveTotal <= 0) then
        sColourStart = "[COLOR_GREEN]"
      elseif (iTotal <=0 and iActiveSurplus > 0) then
        sColourStart = "[COLOR_RED]"
      end

      sToolTip = string.format("%s %s", pLuxury.IconString, Locale.ConvertTextKey(pLuxury.Description))
    end

    sText = string.format("%s%d[ENDCOLOR]", sColourStart, iTotal)
  else
    sText = string.format("%s-[ENDCOLOR]", sColourStart)

    sToolTip = Locale.ConvertTextKey("TXT_KEY_DO_TRADE_STATUS_UNAVAILABLE")
  end

  return sText, sToolTip, iTotal
end

function GetGoldenAgeCities(pPlayer, pLuxury)
  local sCityList = ""

  for pCity in pPlayer:Cities() do
    if (pCity:GetWeLoveTheKingDayCounter() == 0 and pCity:GetResourceDemanded(true) == pLuxury.ID) then
      if (sCityList ~= "") then
        sCityList = sCityList .. ", "
      end

      sCityList = sCityList .. pCity:GetName()
    end
  end

  return sCityList
end

function IsCsNearResource(pCs, pResource)
  local iCs = pCs:GetID()
  local pCapital = pCs:GetCapitalCity()
	
  if (pCapital ~= nil) then
    local thisX = pCapital:GetX()
    local thisY = pCapital:GetY()
		
    local iRange = 5
    local iCloseRange = 2
		
    for iDX = -iRange, iRange, 1 do
      for iDY = -iRange, iRange, 1 do
        local pTargetPlot = Map.GetPlotXY(thisX, thisY, iDX, iDY)
        
        if (pTargetPlot ~= nil) then
          local iOwner = pTargetPlot:GetOwner()
          
          if (iOwner == iCs or iOwner == -1) then
            local plotDistance = Map.PlotDistance(thisX, thisY, pTargetPlot:GetX(), pTargetPlot:GetY())
            
            if (plotDistance <= iRange and (plotDistance <= iCloseRange or iOwner == iCs)) then
              if (pTargetPlot:GetResourceType(pCs:GetTeam()) == pResource.ID) then
                return true
			  end
            end
          end
        end
      end
    end
  end

  return false
end

function IsCsHasResource(pCs, pResource)
  return (GetCsResourceCount(pCs, pResource) > 0)
end

function GetCsStrategics(pCs)
  local sStrategics = ""
	
  for pResource in GameInfo.Resources() do
    local iResource = pResource.ID

    if (Game.GetResourceUsageType(iResource) == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC) then
      iAmount = GetCsResourceCount(pCs, pResource)

      if (iAmount > 0) then
        if (sStrategics ~= "") then
          sStrategics = sStrategics .. ", "
        end

        sStrategics = sStrategics .. pResource.IconString .. " [COLOR_POSITIVE_TEXT]" .. iAmount .. "[ENDCOLOR]"
      end
    end
  end

  return sStrategics
end

function GetCsResourceCount(pCs, pResource)
  return pCs:GetNumResourceTotal(pResource.ID, false) + pCs:GetResourceExport(pResource.ID)
end

function OnCivSelected(iPlayer)
  if (Players[iPlayer]:IsHuman()) then
    Events.OpenPlayerDealScreenEvent(iPlayer)
  else
    UI.SetRepeatActionPlayer(iPlayer)
    UI.ChangeStartDiploRepeatCount(1)
    Players[iPlayer]:DoBeginDiploWithHuman()
  end
end

function OnCsSelected(iCs)
  local popupInfo = {
    Type = ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO,
    Data1 = iCs
  }
    
  Events.SerialEventGameMessagePopup(popupInfo)
end


-----
----- Helpers to determine if a luxury is available (also in Summary Luxuries)
-----
local gAvailableLuxuries = nil

function IsAvailableLuxury(resource)
  if (gAvailableLuxuries == nil) then
    GetAvailableLuxuries()
  end

  if (type(resource) == "table") then
    return gAvailableLuxuries[resource.ID]
  else
    return gAvailableLuxuries[resource]
  end
end

function GetAvailableLuxuries()
  gAvailableLuxuries = {}

  GetMapLuxuries()
  GetBuildingLuxuries()
  GetCsLuxuries()
  GetCivLuxuries()
end

function GetMapLuxuries()
  -- Any luxuries placed on the map
  for iPlot = 0, Map.GetNumPlots()-1, 1 do
    local pPlot = Map.GetPlotByIndex(iPlot)

    if (pPlot:GetResourceType() ~= -1) then
      local resource = GameInfo.Resources[pPlot:GetResourceType()]

      if (resource ~= nil and resource.ResourceClassType == "RESOURCECLASS_LUXURY") then
        gAvailableLuxuries[resource.ID] = true
        gAvailableLuxuries[resource.Type] = true
      end
    end
  end
end

function GetBuildingLuxuries()
  -- Any luxuries from buildings
  for buildingResource in GameInfo.Building_ResourceQuantity() do
    local resource = GameInfo.Resources[buildingResource.ResourceType]

    if (resource ~= nil and resource.ResourceClassType == "RESOURCECLASS_LUXURY") then
      gAvailableLuxuries[resource.ID] = true
      gAvailableLuxuries[resource.Type] = true
    end
  end
end

function GetCsLuxuries()
  -- Any luxuries from City States
  for iCs = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS-1, 1 do
    local pCs = Players[iCs]
    if (pCs:IsEverAlive() and pCs:GetMinorCivTrait() == MinorCivTraitTypes.MINOR_CIV_TRAIT_MERCANTILE) then
      local pPlot = pCs:GetStartingPlot()
      local resource = pPlot and GameInfo.Resources[pPlot:GetResourceType()]

      if (resource ~= nil and resource.ResourceClassType == "RESOURCECLASS_LUXURY") then
        gAvailableLuxuries[resource.ID] = true
        gAvailableLuxuries[resource.Type] = true
      end
    end
  end
end

function GetCivLuxuries()
  -- Any civ specific luxuries
  if (isBNW) then
    for iCiv = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
      local pCiv = Players[iCiv]
      if (pCiv:IsEverAlive()) then
	    local sCivType = GameInfo.Civilizations[pCiv:GetCivilizationType()].Type

	    for resource in GameInfo.Resources() do
          if (resource.ResourceClassType == "RESOURCECLASS_LUXURY" and resource.CivilizationType == sCivType) then
            gAvailableLuxuries[resource.ID] = true
            gAvailableLuxuries[resource.Type] = true
		  end
		end
      end
    end
  end
end

GetAvailableLuxuries()

function OnCityCreated(hexPos, iPlayer)
  if (iPlayer >= GameDefines.MAX_MAJOR_CIVS) then
    -- It's a City State being founded, so we may now have Mercantile luxuries
    GetCsLuxuries()
  end
end
Events.SerialEventCityCreated.Add(OnCityCreated)

-- Certain events should cause the graphs to redraw themselves

function turnStartHandler()
  UpdateStatus();
end
Events.ActivePlayerTurnStart.Add( turnStartHandler );

function teamMetHandler()
  --logger:debug("New leader encountered, redrawing relations");
  UpdateStatus();
end
Events.TeamMet.Add( teamMetHandler );

-- Update view after leaving leader diplo screen
function OnLeavingLeader()
    UpdateStatus();
end
Events.LeavingLeaderViewMode.Add( OnLeavingLeader );
