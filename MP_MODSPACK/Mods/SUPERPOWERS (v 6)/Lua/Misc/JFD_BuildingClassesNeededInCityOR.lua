local tBuildingClassInCityORS = {}
for row in GameInfo.Building_ClassesNeededInCityOR() do
	if not tBuildingClassInCityORS[GameInfoTypes[row.BuildingType]] then
		tBuildingClassInCityORS[GameInfoTypes[row.BuildingType]] = { [GameInfoTypes[row.BuildingClassType]] = row.BuildingClassType }
	else
		tBuildingClassInCityORS[GameInfoTypes[row.BuildingType]][GameInfoTypes[row.BuildingClassType]] = row.BuildingClassType
	end
end
function JFD_Building_ClassesNeededInCityOR(playerID, cityID, buildingID)
	if tBuildingClassInCityORS[buildingID] then
		local pCity = Players[playerID]:GetCityByID(cityID)
		for k,v in pairs(tBuildingClassInCityORS[buildingID]) do
			if HasBuildingClass(pCity, v) then
				return true
			end
		end
		return false
	end
	return true
end
GameEvents.CityCanConstruct.Add(JFD_Building_ClassesNeededInCityOR)
------------------------------------------------------------
---- Whoward69' BuildingClass in a city check
------------------------------------------------------------

function HasBuildingClass(pCity, sBuildingClass)
  for building in GameInfo.Buildings("BuildingClass='" .. sBuildingClass .. "'") do
    if (pCity:IsHasBuilding(building.ID)) then
      return true
    end
  end
  
  return false
end