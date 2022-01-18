print("This is the 'Global - City State Airbases' mod script.")

local iMaxAircraftPerCS = 3

--
-- CanRebaseInCity() is only called for cities we do not own
-- It should be used to ascertain if the city can take our aircraft anyway
--
-- The non-city plot equivalent is CanRebaseTo()
--
function OnCanRebaseInCity(iPlayer, iUnit, iPlotX, iPlotY)
  local pPlot = Map.GetPlot(iPlotX, iPlotY)
  local pCity = pPlot:GetPlotCity()
  local pUnit = Players[iPlayer]:GetUnitByID(iUnit)
  local unit = GameInfo.Units[pUnit:GetUnitType()]
  -- print(string.format("Can %s rebase to %s (%i, %i)", pUnit:GetName(), (pCity and pCity:GetName() or ""), iPlotX, iPlotY))

  -- No suicide units (missiles, nukes etc) in non-domestic cities
  if (unit.Suicide or unit.NukeDamageLevel ~= -1) then
    return false
  end

  -- Is this an allied City State?
  local pCityOwner = Players[pCity:GetOwner()]
  if (pCityOwner:IsMinorCiv() and pCityOwner:GetAlly() == iPlayer) then
	-- print("  found an allied city state here")
	return (CountAircraft(pPlot, pUnit) < iMaxAircraftPerCS)
  end

  return false
end
GameEvents.CanRebaseInCity.Add(OnCanRebaseInCity)

--
-- RebaseTo() is called after one of our aircraft is rebased
--
function OnRebaseTo(iPlayer, iUnit, iPlotX, iPlotY)
  local pCity = Map.GetPlot(iPlotX, iPlotY):GetPlotCity()
  local pUnit = Players[iPlayer]:GetUnitByID(iUnit)
  print(string.format("%s rebased to %s (%i, %i)", pUnit:GetName(), (pCity and pCity:GetName() or ""), iPlotX, iPlotY))
end
-- GameEvents.RebaseTo.Add(OnRebaseTo)


--
-- MinorAlliesChanged() is called when our status with a CS changes
--
function OnMinorAlliesChanged(iMinor, iMajor, bIsAlly, iOldFriendship, iNewFriendship)
  local pPlayer = Players[iMajor]

  if not bIsAlly then
	for pCity in Players[iMinor]:Cities() do
	  local pPlot = pCity:Plot()

	  for i = 0, pPlot:GetNumUnits()-1, 1 do
	    local pUnit = pPlot:GetUnit(i)

		if (pUnit:GetOwner() == iMajor) then
		  local pBestPlot = FindBestPlot(pUnit)

          if pBestPlot then
            -- pUnit:SetXY(pBestPlot:GetX(), pBestPlot:GetY())
            pUnit:RebaseAt(pBestPlot:GetX(), pBestPlot:GetY())
		  else
		    if pPlayer:IsHuman() then
              local sHeading = Locale.ConvertTextKey("TXT_KEY_CS_AIRBASE_UNABLE_TO_REBASE")
              local sText = Locale.ConvertTextKey("TXT_KEY_CS_AIRBASE_UNABLE_TO_REBASE_TEXT", pUnit:GetName())
              pPlayer:AddNotification(NotificationTypes.NOTIFICATION_UNIT_DIED, sText, sHeading, pUnit:GetX(), pUnit:GetY(), pUnit:GetUnitType(), iMajor)
			end

		    pUnit:Kill(false)
          end
		end
	  end
	end
  end
end
GameEvents.MinorAlliesChanged.Add(OnMinorAlliesChanged)


function FindBestPlot(pUnit)
  local iRange= (pUnit:Range() * GameDefines.AIR_UNIT_REBASE_RANGE_MULTIPLIER) / 100
  local pUnitPlot = pUnit:GetPlot()
  local iUnitX = pUnit:GetX()
  local iUnitY = pUnit:GetY()
  
  local pBestPlot = nil
  local iBestDistance = 9999
  local iBestAircraft = 0
	
  for iDX = -iRange, iRange, 1 do
    for iDY = -iRange, iRange, 1 do
      local pPlot = Map.GetPlotXY(iUnitX, iUnitY, iDX, iDY)
	  
      if pPlot then
        local iPlotX = pPlot:GetX()
        local iPlotY = pPlot:GetY()
        local iDistance = Map.PlotDistance(iUnitX, iUnitY, iPlotX, iPlotY)
        if (iDistance <= iRange and iDistance <= iBestDistance) then
          if pUnit:CanRebaseAt(pUnitPlot, iPlotX, iPlotY) then
            local iAircraft = CountAircraft(pPlot, pUnit)

            -- Find the nearest plot with the most aircraft, as this is probably where the war is!			
		    if (iDistance < iBestDistance or iAircraft > iBestAircraft) then
			  pBestPlot = pPlot
			  iBestDistance = iDistance
			  iBestAircraft = iAircraft
			end
          end
        end
      end
    end
  end

  return pBestPlot  
end

function CountAircraft(pPlot, pUnit)
  local iAircraft = 0
  local iPlayer = pUnit:GetOwner()
  
  for i = 0, pPlot:GetNumUnits()-1, 1 do
    local pPlotUnit = pPlot:GetUnit(i)
	
	if (pPlotUnit:GetOwner() == iPlayer and pPlotUnit:GetDomainType() == DomainTypes.DOMAIN_AIR) then
	  iAircraft = iAircraft + 1
	end
  end
  
  return iAircraft
end
