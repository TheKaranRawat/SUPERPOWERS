--
-- Resistance Notification - custom notification for a city exiting resistance
--

local NuclearAttack = {
  label = "TXT_KEY_NUCLEAR_ATTACK_NOTIFICATION", 
  key   = "NUCLEAR_ATTACK_NOTIFICATION", 
  item = "NuclearAttack",
  show  = true, 
  ui    = true, 
}

function OnLookAt(pPlot)
  if (pPlot ~= nil) then
    UI.LookAt(pPlot)
  end
end

function OnNuclearAttackNotification(cbData)
  print(string.format("OnNuclearAttack(%i, %i, %s, %s)", cbData.iExtra1, cbData.iExtra2, cbData.sHeading, cbData.sText))
  local instance = {}
  ContextPtr:BuildInstanceForControl("NuclearAttackItem", instance, cbData.parent)
  cbData.instance = instance

  local pPlayer = Players[cbData.iExtra1]
  if (pPlayer ~= nil) then
    local pCity = pPlayer:GetCityByID(cbData.iExtra2)
    if (pCity ~= nil) then
      instance.CityResistanceButton:RegisterCallback(Mouse.eLClick, function() OnLookAt(pCity:Plot()) end)
    end
  end    
end
NuclearAttack.callback = OnNuclearAttackNotification

function OnNuclearAttackNotificationIdRequest()
  if (NuclearAttack.id ~= nil) then
    LuaEvents.CityResistanceNotificationId(NuclearAttack.id)
  end
end
LuaEvents.NuclearAttackNotificationIdRequest.Add(OnNuclearAttackNotificationIdRequest)

function Register()
  LuaEvents.CustomNotificationAddin(NuclearAttack)
  OnNuclearAttackNotificationIdRequest()
end

Register()
