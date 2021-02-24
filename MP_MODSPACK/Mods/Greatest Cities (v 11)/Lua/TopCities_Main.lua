-- Top_Cities_Main
-- Author: FramedArchitecture
-- DateCreated: 8/1/2014
--------------------------------------------------------------------
include("TopCities_Functions.lua")
--------------------------------------------------------------------
MapModData.g_Properties	= MapModData.g_Properties or {}
local g_Properties		= MapModData.g_Properties;
local archID			= GameInfo.Buildings["BUILDING_TC_TRIUMPHARCH"].ID
--------------------------------------------------------------------


--------------------------------------------------------------------
function OnCityCanConstruct(playerID, cityID, buildingID)
	if (buildingID == archID) then
		local city = Players[playerID]:GetCityByID(cityID)
		return IsEverGreatestCity(city)
	end
	return true;
end
GameEvents.CityCanConstruct.Add( OnCityCanConstruct )
--------------------------------------------------------------------
local eraID = 0
for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
	local player = Players[i]
	 if player and (player:GetCurrentEra() > eraID) then
		eraID = player:GetCurrentEra()
	 end
end
SetCurrentEra(GameInfo.Eras[eraID].Type)
--------------------------------------------------------------------
print("Top Cities Initialized...")