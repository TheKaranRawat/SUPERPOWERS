include("IconSupport")
include("SupportFunctions")
include("InstanceManager")
include("InfoTooltipInclude")
include("CityStateStatusHelper")


local iGoldGiftLarge  = GameDefines.MINOR_GOLD_GIFT_LARGE
local iGoldGiftMedium = GameDefines.MINOR_GOLD_GIFT_MEDIUM
local iGoldGiftSmall  = GameDefines.MINOR_GOLD_GIFT_SMALL

local gCsIM = InstanceManager:new("CsStatusInstance", "CsBox", Controls.CsStack)

local gSortTable
local sLastSort = "influence"
local bReverseSort = true

local gCsControls

function ShowHideHandler(bIsHide, bIsInit)
  if (not bIsInit and not bIsHide) then
    InitCsList()
  end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)

function InitCsList()
  local iPlayer = Game.GetActivePlayer()
  local pPlayer = Players[iPlayer]
  local iTeam   = pPlayer:GetTeam()
  local pTeam   = Teams[iTeam]

  local iCount = 0

  gCsIM:ResetInstances()
  gCsControls = {}

  gSortTable = {}

  -- Don't include the Barbarians (so -2)
  for iCs = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_PLAYERS-2, 1 do
    local pCs = Players[iCs]
    if (pCs:IsAlive() and pTeam:IsHasMet(pCs:GetTeam())) then
      GetCsControl(gCsIM, iCs, iPlayer)
      iCount = iCount + 1
    end
  end
  
  if (iCount == 0) then
    Controls.CsNoneMetText:SetHide(false)
    Controls.CsScrollPanel:SetHide(true)
  else
    OnSortCs()
    Controls.CsStack:CalculateSize()
    Controls.CsStack:ReprocessAnchoring()
    Controls.CsScrollPanel:CalculateInternalSize()

    Controls.CsNoneMetText:SetHide(true)
    Controls.CsScrollPanel:SetHide(false)
  end
end

function GetCsControl(im, iCs, iPlayer)
  local pPlayer = Players[iPlayer]
  local iTeam = pPlayer:GetTeam()
  local pTeam = Teams[iTeam]

  local pCs = Players[iCs]
  local sCsTrait = GameInfo.MinorCivilizations[pCs:GetMinorCivType()].MinorCivTrait
        
  local controlTable = im:GetInstance()
  gCsControls[iCs] = controlTable

  local sortEntry = {trait=sCsTrait, name=pCs:GetName()}
  gSortTable[tostring(controlTable.CsBox)] = sortEntry

  -- Trait
  controlTable.CsTraitIcon:SetTexture(GameInfo.MinorCivTraits[sCsTrait].TraitIcon)
  local primaryColor, secondaryColor = pCs:GetPlayerColors()
  controlTable.CsTraitIcon:SetColor({x = secondaryColor.x, y = secondaryColor.y, z = secondaryColor.z, w = 1})

  -- Name
  controlTable.CsName:SetText(pCs:GetName() .. getUnitSpawnFlag(pCs, pPlayer))

  -- CS Button
  controlTable.CsButton:SetVoid1(iCs)
  controlTable.CsButton:RegisterCallback(Mouse.eLClick, OnCsSelected)

  -- Spy in city state?
  local bHasSpy, sSpyToolTip = getSpy(pCs, pPlayer)
  controlTable.CsSpy:SetHide(bHasSpy == false)
  controlTable.CsSpy:SetToolTipString(sSpyToolTip)

  -- Influence
  local iInfluence, sInfluenceText, iNeededInfluence, sInfluenceToolTip = getInfluence(pCs, pPlayer)
  controlTable.CsInfluence:SetText(sInfluenceText)
  controlTable.CsInfluence:SetToolTipString(sInfluenceToolTip)
  sortEntry.influence = iInfluence
  sortEntry.neededInfluence = iNeededInfluence

  -- Allied with anyone?
  local sAlly, sAllyText = getAlly(pCs, pPlayer)
  controlTable.CsAlly:SetText(sAllyText)
  controlTable.CsAlly:SetToolTipString(sInfluenceToolTip)
  sortEntry.ally = sAlly
  
  -- Protected by anyone?
  local sProtectingPlayers = getProtectingPlayers(pCs, pPlayer)

  if (sProtectingPlayers ~= "") then
    controlTable.CsProtect:SetText(sProtectingPlayers)
    controlTable.CsProtect:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_PROTECT_TT", pCs:GetName(), sProtectingPlayers))
  else
    controlTable.CsProtect:SetText("")
    controlTable.CsProtect:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_NO_PROTECT_TT", pCs:GetName()))
  end

  -- Quests
  setQuests(controlTable.CsQuest, pCs, pPlayer, false)

  -- At war?
  setWarPeaceIcon(controlTable.CsWarPeace, pCs, pPlayer, false)

  -- Gold gifts
  setGoldGiftIcons(controlTable, pCs, pPlayer, false)

  return controlTable
end

function getUnitSpawnFlag(pCs, pPlayer)
  local sFlag = ""
  local iPlayer = pPlayer:GetID()

  if (pCs:GetMinorCivTrait() == MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC) then
    if (pCs:IsFriends(iPlayer)) then
      if (pCs:IsMinorCivUnitSpawningDisabled(iPlayer)) then
        -- Unit spawning is off
        sFlag = " [ICON_TEAM_2]"
      else
        -- Unit spawning is on
        sFlag = " [ICON_TEAM_4]"
      end
    end
  end

  return sFlag
end

function getSpy(pCS, pPlayer)
  local pCity = pCS:GetCapitalCity()
  local iX = pCity:GetX()
  local iY = pCity:GetY()
		
  for _, spy in ipairs(pPlayer:GetEspionageSpies()) do
    if (spy.CityX == iX and spy.CityY == iY) then
      local sName = Locale.Lookup(spy.Name)
      local sRank = Locale.Lookup(spy.Rank)

      return true, Locale.ConvertTextKey("TXT_KEY_CITY_SPY_CITY_STATE_TT", sRank, sName, pCity:GetName(), sRank, sName)
  	end
  end

  return false, ""
end

function getAlly(pCs, pPlayer)
  local iPlayer = pPlayer:GetID()
  local sAlly, sAllyText

  if (pCs:IsAllies(iPlayer)) then
    sAlly = Locale.ConvertTextKey("TXT_KEY_YOU")
    sAllyText = "[COLOR_POSITIVE_TEXT]" .. sAlly .. "[ENDCOLOR]"
  else
    local iAlly = pCs:GetAlly() or -1

    if (iAlly ~= -1) then
      sAlly = Locale.ConvertTextKey(Players[iAlly]:GetCivilizationShortDescriptionKey())
      sAllyText = sAlly
    else
      sAlly = ""
      sAllyText = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_NOBODY")
    end
  end

  return sAlly, sAllyText
end

function getProtectingPlayers(pCs, pPlayer)
  local sProtecting = ""
  local iCs = pCs:GetID()
  local iPlayer = pPlayer:GetID()
  
  for iCivPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
    pCivPlayer = Players[iCivPlayer]

    if (pCivPlayer:IsAlive()) then
      if (pCivPlayer:IsProtectingMinor(iCs)) then

        if (sProtecting ~= "") then
          sProtecting = sProtecting .. ", "
        end

        if (iCivPlayer == iPlayer) then
          sProtecting = sProtecting .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_YOU") .. "[ENDCOLOR]"
        else
          sProtecting = sProtecting .. Locale.ConvertTextKey(Players[iCivPlayer]:GetCivilizationShortDescriptionKey())
        end
      end
    end
  end

  return sProtecting
end

function getQuests(pCs, pPlayer, bForcePeace)
  local iMajor = pPlayer:GetID()
  local iMinor = pCs:GetID()

  return GetActiveQuestText(iMajor, iMinor), GetActiveQuestToolTip(iMajor, iMinor)
end

function setQuests(pText, pCs, pPlayer, bForcePeace)
  local sCsQuests, sCsQuestsDesc = getQuests(pCs, pPlayer, bForcePeace)

  if (sCsQuests ~= "") then
    pText:SetText(sCsQuests)
    pText:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_QUEST_TT", pCs:GetName(), sCsQuestsDesc))
  else
    pText:SetText("")
    pText:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_NO_QUEST_TT", pCs:GetName()))
  end
end

function getInfluence(pCs, pPlayer)
  local iPlayer = pPlayer:GetID()
  local iTeam = pPlayer:GetTeam()
  local bWar = Teams[iTeam]:IsAtWar(pCs:GetTeam())
  local iInfluence = pCs:GetMinorCivFriendshipWithMajor(iPlayer)

  local sColour = ""
  local sEndColour = "[ENDCOLOR]"
  if (pCs:IsAllies(iPlayer)) then
    sColour = "[COLOR_CYAN]"
  elseif (pCs:IsFriends(iPlayer)) then
    sColour = "[COLOR_GREEN]"
  elseif (pCs:IsMinorPermanentWar(iTeam) or pCs:IsPeaceBlocked(iTeam) or bWar or (iInfluence < 0)) then
    sColour = "[COLOR_RED]"
  else
    sEndColour = ""
  end

  local iNeededInf, sNeededInf = getNeededInf(pCs, pPlayer)

  local sInfluence = sColour .. iInfluence
  if (iNeededInf > 0) then
    sInfluence = sInfluence .. " (" ..iNeededInf .. ")"
  end
  sInfluence = sInfluence .. sEndColour

  return iInfluence, sInfluence, iNeededInf, sNeededInf
end

function getNeededInf(pCs, pPlayer)
  local iNeededInf = 0
  local sNeededInf = nil

  local iPlayerInf = pCs:GetMinorCivFriendshipWithMajor(pPlayer:GetID())
  local iAlly = pCs:GetAlly()

  if (iAlly ~= nil and iAlly ~= -1) then
    if (iAlly ~= pPlayer:GetID()) then
      iNeededInf = pCs:GetMinorCivFriendshipWithMajor(iAlly) - iPlayerInf + 1
      sNeededInf = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_ALLY_TT", Players[iAlly]:GetCivilizationShortDescriptionKey(), iNeededInf);
    end
  else
    iNeededInf = GameDefines["FRIENDSHIP_THRESHOLD_ALLIES"] - iPlayerInf
    sNeededInf = Locale.ConvertTextKey("TXT_KEY_CITY_STATE_ALLY_NOBODY_TT", iNeededInf)
  end

  if (sNeededInf ~= nil) then
    sNeededInf, _ = string.gsub(sNeededInf, "%[NEWLINE].*", "")
  end

  return iNeededInf, sNeededInf
end

function setWarPeaceIcon(pIcon, pCs, pPlayer, bForcePeace)
  local iCs = pCs:GetID()
  local iTeam = pPlayer:GetTeam()
  local pTeam = Teams[iTeam]

  local bWar = not bForcePeace and pTeam:IsAtWar(pCs:GetTeam())
  local bCanMakePeace = (bWar and not pCs:IsPeaceBlocked(iTeam))

  if (bCanMakePeace) then
    pIcon:SetHide(false)
    pIcon:SetText("[ICON_PEACE]")
    pIcon:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_PEACE_TT"))

    pIcon:SetVoid1(iCs)
    pIcon:RegisterCallback(Mouse.eLClick, OnMakePeaceSelected)
  elseif (bWar) then
    pIcon:SetHide(false)
    pIcon:SetText("[ICON_WAR]")
    pIcon:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_WAR_TT"))

    pIcon:RegisterCallback(Mouse.eLClick, OnIgnore)
  else
    pIcon:SetHide(true)
  end
end

function setGoldGiftIcons(controlTable, pCs, pPlayer, bForcePeace)
  local iCs = pCs:GetID()
  local iPlayer = pPlayer:GetID()
  local pTeam = Teams[pPlayer:GetTeam()]
  local iPlayerGold = pPlayer:GetGold()
  local bWar = (bForcePeace == false and pTeam:IsAtWar(pCs:GetTeam()))

  -- Small Gold
  if (not bWar and iPlayerGold >= iGoldGiftSmall) then
    controlTable.CsGiftSmall:SetHide(false)
    controlTable.CsGiftSmall:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_GIFT_INFLUENCE_TT", iGoldGiftSmall, pCs:GetFriendshipFromGoldGift(iPlayer, iGoldGiftSmall)))

    controlTable.CsGiftSmall:SetVoid1(iCs)
    controlTable.CsGiftSmall:SetVoid2(iGoldGiftSmall)
    controlTable.CsGiftSmall:RegisterCallback(Mouse.eLClick, OnGiftSelected)
  else
    controlTable.CsGiftSmall:SetHide(true)
  end

  -- Medium Gold
  if (not bWar and iPlayerGold >= iGoldGiftMedium) then
    controlTable.CsGiftMedium:SetHide(false)
    controlTable.CsGiftMedium:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_GIFT_INFLUENCE_TT", iGoldGiftMedium, pCs:GetFriendshipFromGoldGift(iPlayer, iGoldGiftMedium)))

    controlTable.CsGiftMedium:SetVoid1(iCs)
    controlTable.CsGiftMedium:SetVoid2(iGoldGiftMedium)
    controlTable.CsGiftMedium:RegisterCallback(Mouse.eLClick, OnGiftSelected)
  else
    controlTable.CsGiftMedium:SetHide(true)
  end

  -- Large Gold
  if (not bWar and iPlayerGold >= iGoldGiftLarge) then
    controlTable.CsGiftLarge:SetHide(false)
    controlTable.CsGiftLarge:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_DO_CS_STATUS_GIFT_INFLUENCE_TT", iGoldGiftLarge, pCs:GetFriendshipFromGoldGift(iPlayer, iGoldGiftLarge)))

    controlTable.CsGiftLarge:SetVoid1(iCs)
    controlTable.CsGiftLarge:SetVoid2(iGoldGiftLarge)
    controlTable.CsGiftLarge:RegisterCallback(Mouse.eLClick, OnGiftSelected)
  else
    controlTable.CsGiftLarge:SetHide(true)
  end
end


-- If we spend money with the CS, the list is updated in OnGameDataDirty, 
-- If we make peace/war with the CS, the list is updated in OnWarStateChanged
function OnCsSelected(iCs)
  Events.SerialEventGameMessagePopup({Type=ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO, Data1=iCs})
end

function OnMakePeaceSelected(iCs)
  Network.SendChangeWar(Players[iCs]:GetTeam(), false)
end

function OnGiftSelected(iCs, iGold)
  Game.DoMinorGoldGift(iCs, iGold)
end


function OnIgnore()
end


function OnSortCs(sSort)
  if (sSort) then
    if (sLastSort == sSort) then
      bReverseSort = not bReverseSort
    else
      bReverseSort = (sSort == "influence")
    end 

    sLastSort = sSort
  end

  Controls.CsStack:SortChildren(ByMethod)
end


function ByMethod(a, b)
  local entryA = gSortTable[tostring(a)]
  local entryB = gSortTable[tostring(b)]

  local bReverse = bReverseSort

  if ((entryA == nil) or (entryB == nil)) then 
    if ((entryA ~= nil) and (entryB == nil)) then
      if (bReverse) then
        return false
      else
        return true
      end
    elseif ((entryA == nil) and (entryB ~= nil)) then
      if (bReverse) then
        return true
      else
        return false
      end
    else
      -- gotta do something!
      if (bReverse) then
        return (tostring(a) >= tostring(b))
      else
        return (tostring(a) < tostring(b))
      end
    end
  end

  local valueA = entryA[sLastSort]
  local valueB = entryB[sLastSort]

  if (valueA == valueB and sLastSort == "influence") then
    valueA = entryA.neededInfluence
    valueB = entryB.neededInfluence
  end

  if (valueA == valueB) then
    valueA = entryA.name
    valueB = entryB.name

    bReverse = false
  end

  if (bReverse) then
    return (valueA >= valueB)
  else
    return (valueA < valueB)
  end
end

function OnSortCsTrait()
  OnSortCs("trait")
end
Controls.SortCsTrait:RegisterCallback(Mouse.eLClick, OnSortCsTrait)

function OnSortCsName()
  OnSortCs("name")
end
Controls.SortCsName:RegisterCallback(Mouse.eLClick, OnSortCsName)

function OnSortCsAlly()
  OnSortCs("ally")
end
Controls.SortCsAlly:RegisterCallback(Mouse.eLClick, OnSortCsAlly)

function OnSortCsInfluence()
  OnSortCs("influence")
end
Controls.SortCsInfluence:RegisterCallback(Mouse.eLClick, OnSortCsInfluence)

-- Catch changes in cash that will affect the "Gold Gift" buttons
function OnGameDataDirty()
	if (not ContextPtr:IsHidden()) then
    InitCsList()
  end
end
Events.SerialEventGameDataDirty.Add(OnGameDataDirty)

-- Catch changes in war/peace that will affect Quests, Influence, Status, Gifts et al
function OnWarStateChanged(iTeam1, iTeam2, bWar)
	if (not ContextPtr:IsHidden()) then
    InitCsList()
  end
end
Events.WarStateChanged.Add(OnWarStateChanged)
