--
-- Resistance Notification - custom notification for a city exiting resistance
--

local CityResistance = {
  label = "TXT_KEY_CITY_NOTIFICATIONS_RESISTANCE", 
  key   = "CITY_NOTIFICATIONS_RESISTANCE", 
  item = "CityResistance",
  show  = true, 
  ui    = true, 
}

function OnLookAt(pPlot)
  if (pPlot ~= nil) then
    UI.LookAt(pPlot)
  end
end

function OnCityResistanceNotification(cbData)
  print(string.format("OnCityResistance(%i, %i, %s, %s)", cbData.iExtra1, cbData.iExtra2, cbData.sHeading, cbData.sText))
  local instance = {}
  ContextPtr:BuildInstanceForControl("CityResistanceItem", instance, cbData.parent)
  cbData.instance = instance

  local pPlayer = Players[cbData.iExtra1]
  if (pPlayer ~= nil) then
    local pCity = pPlayer:GetCityByID(cbData.iExtra2)
    if (pCity ~= nil) then
      instance.CityResistanceButton:RegisterCallback(Mouse.eLClick, function() OnLookAt(pCity:Plot()) end)
    end
  end    
end
CityResistance.callback = OnCityResistanceNotification

function OnCityResistanceNotificationIdRequest()
  if (CityResistance.id ~= nil) then
    LuaEvents.CityResistanceNotificationId(CityResistance.id)
  end
end
LuaEvents.CityResistanceNotificationIdRequest.Add(OnCityResistanceNotificationIdRequest)

function Register()
  LuaEvents.CustomNotificationAddin(CityResistance)
  OnCityResistanceNotificationIdRequest()
end

Register()
