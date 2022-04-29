-- Conquer.lua
-- Author: Matviyko Rozumiyko
-- DateCreated: 1/5/2013 5:20:57 PM
--------------------------------------------------------------
print( "Loading Conquer.lua" )

-- Traverse all units of the given player to see if they can conquer plots
function PlayerHexConquer( playerID )
	local player = Players[ playerID ]
	if player:IsBarbarian() then return end
	local numUnits = player:GetNumUnits()
	local i = 0
	--print(string.format(">Player %s (ID %d) has %d units", player:GetName(), playerID, numUnits));
	while numUnits > 0 do
		local unit = player:GetUnitByID( i )
		if unit ~= nil then
			UnitConquerPlots( player, unit )
			numUnits = numUnits -1
		end
		i = i + 1
	end
	--print(string.format("Player %d, %s, has passed PlayerHexConquer()", playerID , player:GetName()));
end


function UnitConquerPlots( player, unit )
	--print(string.format("    Unit: %s (ID %d)", unit:GetName(), i));
	if not unit:IsCombatUnit() then return end -- only combat units can conquer
	local plot = unit:GetPlot()
	if plot == nil then return end
	if plot:IsWater() then return end -- in order to conquer, the unit must be on a land plot
	ConquerPlot( player, plot, false )
	ConquerAdjacentPlots( player, plot )
end


--
function ConquerPlot( player, plot, mustBeAdjacentToFriendlyPlot )
	--if player == nil or plot = nil then return end
	if not PlotIsConquerable( player, plot ) then return end
	
	if mustBeAdjacentToFriendlyPlot == true then
		if not PlotIsAdjacentToFriendlyPlot( player, plot ) then return end
	end
	
	local adjPlots = GetAdjacentPlots( plot )	
	if PlotHasEnemyCombatUnit( player, plot ) then return end
	if PlotsHaveEnemyCombatUnits( player, adjPlots ) then return end
	
	if plot:IsCity() then return end
		




	local playerID = player:GetID()
	local cityID = getNearestCity( playerID, plot ):GetID()
	plot:SetOwner( playerID, cityID, true, true )
	print(string.format("%s is a new owner of plot (%d, %d)", player:GetName(), plot:GetX(), plot:GetY() ))
	table.insert( newConqueredPots, plot )
end


-- tells whether the given player can conquer the plot THIS ONE
-- returns true if plot is a valid, not city, and the owner is at war with the player
function PlotIsConquerable( player, plot )
	if( plot == nil ) then return false end -- not a valid plot	

				if not PlotIsAdjacentToFriendlyPlot( player, plot ) then return false end
				if PlotIsAdjacentToEnemyCity( player, plot ) then return false end

	local ownerPlayerID = plot:GetOwner()
	if( ownerPlayerID < 0) then return false end -- cannot conquer a neutral plot
	
	local ownerPlayer = Players[ ownerPlayerID ]
	local invaderTeam = Teams[ player:GetTeam() ]
	if not( invaderTeam:IsAtWar( ownerPlayer:GetTeam() ) ) then return false end -- can conquer enemy's plot only
	
	if( plot:IsCity() ) then return false end -- conquering a city is a different story

	--print(string.format("      plot (%dx, %dy) is conquerable", plot:GetX(), plot:GetY() ));
	return true
end


--
function PlotsHaveEnemyCombatUnits( player, plots )
	--print( "PlotsHaveEnemyCombatUnits" )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil then
			if PlotHasEnemyCombatUnit( player, plot ) then
				return true
			end					
		end
	end	
	return false
end


--
function PlotHasEnemyCombatUnit( player, plot )
	--print( "PlotHasEnemyCombatUnits" )
	if plot == nil then return false end
	local numUnits = plot:GetNumUnits()
	--print(string.format("      plot (%dx, %dy) has %d units", plot:GetX(), plot:GetY(), numUnits ));
	for i=0, numUnits, 1 do
		local unit = plot:GetUnit(i)
		if unit ~= nil then
			local ownerPlayerID = unit:GetOwner()
			local ownerPlayer = Players[ ownerPlayerID ]
			local playerTeam = Teams[ player:GetTeam() ]
			local isEnemy = playerTeam:IsAtWar( ownerPlayer:GetTeam() )
			if isEnemy and unit:IsCombatUnit() then
				--print(string.format("  plot (%dx, %dy) unit[%d] is enemy", plot:GetX(), plot:GetY(), i ));
				return true
			end
		end
	end
	return false
end


function PlotsHaveEnemyCitadel( player, plots )
	--print( "PlotsHaveEnemyCitadel" )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil then
			if PlotHasEnemyCitadel( player, plot ) then
				return true
			end					
		end
	end	
	return false
end


function PlotHasEnemyCitadel( player, plot )
	--print(string.format("      PlotHasEnemyCitadel(%s, %dx %dy)", player:GetName(), plot:GetX(), plot:GetY() ))
	if plot == nil then return false end
	if player == nil then return false end
	
	local ownerPlayerID = plot:GetOwner()
	if( ownerPlayerID < 0) then return false end
	local ownerPlayer = Players[ ownerPlayerID ]
	local playerTeam = Teams[ player:GetTeam() ]
	local isEnemy = playerTeam:IsAtWar( ownerPlayer:GetTeam() )
	if not isEnemy then return false end
	local improvementType = plot:GetImprovementType()
	if improvementType == GameInfo.Improvements.IMPROVEMENT_CITADEL.ID then
		--print(string.format("      plot (%dx, %dy) has enemy citadel", plot:GetX(), plot:GetY() ))
		return true
	else
		return false
	end
end


function PlotHasEnemyFort( player, plot )
	--print(string.format("      PlotHasEnemyCitadel(%s, %dx %dy)", player:GetName(), plot:GetX(), plot:GetY() ))
	if plot == nil then return false end
	if player == nil then return false end
	
	local ownerPlayerID = plot:GetOwner()
	if( ownerPlayerID < 0) then return false end
	local ownerPlayer = Players[ ownerPlayerID ]
	local playerTeam = Teams[ player:GetTeam() ]
	local isEnemy = playerTeam:IsAtWar( ownerPlayer:GetTeam() )
	if not isEnemy then return false end
	local improvementType = plot:GetImprovementType()
	if improvementType == GameInfo.Improvements.IMPROVEMENT_FORT.ID then
		--print(string.format("      plot (%dx, %dy) has enemy citadel", plot:GetX(), plot:GetY() ))
		return true
	else
		return false
	end
end






-- this function hasn't been completely tested by the author
function ConquerCitadel( player, plot )
	--print( "ConquerCitadelAndAdjacentPlots" )
	if plot == nil then return end
	if not PlotHasEnemyCitadel( player, plot ) then return end
	
	-- conquer the citadel plot
	local city = getNearestCity( player:GetID(), plot )
	if city == nil then return end
	plot:SetOwner( player:GetID(), city:GetID(), true, true )
	table.insert( newConqueredPots, plot )
	print( string.format( "Citadel on plot (%dx, %dy) was captured by %s", plot:GetX(), plot:GetY(), player:GetName() ))	
	
	
end







--
function ConquerAdjacentPlots( player, centralPlot )
	local plots = GetAdjacentPlots( centralPlot )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil then
			ConquerPlot( player, plot, true )
		end
	end	
	return false	
end

-------------------------------------------------------------------------------------------------
------------------------------------- Encircled Plots -------------------------------------------
-------------------------------------------------------------------------------------------------

--
function EliminateEncircledPlots( playerID )
	--local deltaTime = os.clock()
	FindEncirclments( playerID )
	--local player = Players[ playerID ]
	--print( string.format( "  Player %s, time %f", player:GetName(), os.clock() - deltaTime ) )	
end


--
function FindEncirclments( playerID )
	local w, h = Map.GetGridSize()
	w = w - 1
	h = h - 1
	for x=0, w, 1 do
		for y=0, h, 1 do
			local plot = Map.GetPlot( x, y )
			CheckIfPlotIsEncircled( playerID, plot )
		end
	end
end


--
function CheckIfPlotsAreEncircled( playerID, plots )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		CheckIfPlotIsEncircled( playerID, plot )
	end	
end


--
function CheckIfPlotIsEncircled( playerID, plot )
	if plot == nil then return end
	if playerID ~= plot:GetOwner() then return end
	local adjPlots = GetAdjacentPlots( plot )
	if not PlotIsAtBorder( playerID, adjPlots ) then return end
	if not PlotMightBeEncircled( playerID, plot, adjPlots ) then return end
	--print( string.format( "Is plot (%d, %d) Encircled???", plot:GetX(), plot:GetY() ) )	
	
	if PlotHasUnit( playerID, plot ) then return end
	if PlotsHaveUnit( playerID, adjPlots ) then return end
	if PlotHasCityOrCitadel( playerID, plot ) then return end
	if PlotsHaveCityOrCitadel( playerID, adjPlots ) then return end

	local city, distance = getNearestCityWithException( playerID, plot, -1 )
	local city2, distance2 = getAnyNearestCity( plot )
	if city == nil or distance == nil or city2 == nil or distance2 == nil then return end
	if distance <= distance2 then return end

	if distance2 <= 3 then 
		plot:SetOwner( city2:GetOwner(), city2:GetID(), true, true )
		table.insert( newConqueredPots, plot )
		print( string.format( "Encircled plot (%d, %d) was reassigned to %s", plot:GetX(), plot:GetY(), city2:GetName()))	
		CheckIfPlotsAreEncircled( playerID, adjPlots )
	end
	
	--IF the closest city is an enemy city, then use adjacent tiles to decide. ???
	--reevaluate the plots adjacent to the plot which changed the ownership
end


--
function PlotIsAtBorder( playerID, adjPlots )
	if adjPlots == nil then return false end
	for i, plot in pairs( adjPlots ) do
		if plot ~= nil then
			if plot:GetOwner() ~= playerID then return true end
		end
	end	
	return false
end


--
function PlotsHaveCityOrCitadel( playerID, plots )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if PlotHasCityOrCitadel( playerID, plot ) then return true end
	end	
	return false
end


--
function PlotHasCityOrCitadel( playerID, plot )
	if plot == nil then return false end
	if plot:IsCity() then return true end
	if plot:GetImprovementType() == GameInfo.Improvements.IMPROVEMENT_CITADEL.ID then return true end
end


--
function PlotsHaveUnit( playerID, plots )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if PlotHasUnit( playerID, plot ) then
			return true
		end
	end	
	return false
end


--
function PlotHasUnit( playerID, plot )
	if plot == nil then return false end
	local numUnits = plot:GetNumUnits()
	for i=0, numUnits, 1 do
		local unit = plot:GetUnit(i)
		if unit ~= nil then
			if playerID == unit:GetOwner() and unit:IsCombatUnit() then 
				return true
			end
		end
	end
	return false
end


function PlotMightBeEncircled( playerID, plot, adjPlots )
	if plot == nil then return false end
	if adjPlots == nil then return false end
	local city, distance = getNearestCityWithException( playerID, plot, -1 )
	for i, adjPlot in pairs( adjPlots ) do
		if adjPlot ~= nil and playerID == adjPlot:GetOwner() then
			local cityAdj, distanceAdj = getNearestCityWithException( playerID, adjPlot, -1 )
			if distanceAdj < distance then return false end
		end
	end	
	return true
end