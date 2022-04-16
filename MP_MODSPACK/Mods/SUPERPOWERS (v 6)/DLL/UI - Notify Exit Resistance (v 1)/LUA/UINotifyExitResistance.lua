print("This is the 'UI - Notify Exit Resistance' mod script.")

local g_NotificationType = NotificationTypes.NOTIFICATION_GENERIC

function OnCityResistanceNotificationId(id)
  print(string.format("Setting city resistance notification id to %i", id))
  g_NotificationType = id
end
LuaEvents.CityResistanceNotificationId.Add(OnCityResistanceNotificationId)


local cityResistanceCache = {}

function cacheCitiesInResistance(iPlayer)
  local pPlayer = Players[iPlayer]
  local cache = {}
  
  for pCity in pPlayer:Cities() do
    if (pCity:IsResistance()) then
	  table.insert(cache, pCity:GetID())
	end
  end
  
  cityResistanceCache[iPlayer] = cache
end

function notifyCitiesExitedResistance(iPlayer)
  local pPlayer = Players[iPlayer]
  local cache = cityResistanceCache[iPlayer] or {}
  
  for _, iCity in ipairs(cache) do
    local pCity = pPlayer:GetCityByID(iCity)
	
	if (pCity and not pCity:IsResistance()) then
	  local sHeading = Locale.ConvertTextKey("TXT_KEY_CITY_NOTIFICATIONS_RESISTANCE_HEADING", pCity:GetName())
	  local sMessage = Locale.ConvertTextKey("TXT_KEY_CITY_NOTIFICATIONS_RESISTANCE_TEXT", pCity:GetName())
	  pPlayer:AddNotification(g_NotificationType, sMessage, sHeading, pCity:GetX(), pCity:GetY(), pCity:GetOwner(), pCity:GetID())
	end
  end
end


function OnPlayerDoTurn(iPlayer)
  local pPlayer = Players[iPlayer]
  
  if (pPlayer:IsAlive() and pPlayer:IsHuman()) then
    notifyCitiesExitedResistance(iPlayer)
    cacheCitiesInResistance(iPlayer)
  end
end
GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)


for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
  local pPlayer = Players[iPlayer]
  
  if (pPlayer:IsAlive() and pPlayer:IsHuman()) then
    cacheCitiesInResistance(iPlayer)
  end
end

LuaEvents.CityResistanceNotificationIdRequest()
