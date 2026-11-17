function NoMinorCivUnits(playerID, unitType)
    local player = Players[playerID]
    if player and player:IsMinorCiv() then
        return false
    end
    return true
end
GameEvents.PlayerCanTrain.Add(NoMinorCivUnits)