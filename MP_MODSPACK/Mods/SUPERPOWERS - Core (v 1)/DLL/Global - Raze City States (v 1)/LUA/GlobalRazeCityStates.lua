print("This is the 'Global - Raze City States' mod script")

--
-- This function is called whenever a city is being considered for being razed.
-- It is called after the standard checks (do we own this city, did we caputure it from another civilization, etc)
-- but before any special rules (can't raze capitals or cities with special resources)
--
function OnPlayerCanRaze(iPlayer, iCity)
  print(string.format("OnPlayerCanRaze(%d, %d)", iPlayer, iCity))
  local pCity = Players[iPlayer]:GetCityByID(iCity)

  -- Permit any city originally built by a city state to be razed (ie original CS capitals)
  return (pCity:GetOriginalOwner() >= GameDefines.MAX_MAJOR_CIVS)
end
GameEvents.PlayerCanRaze.Add(OnPlayerCanRaze)
