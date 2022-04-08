-- Main.lua
-- Author: Matviyko Rozumiyko
-- DateCreated: 1/5/2013 5:20:30 PM
--------------------------------------------------------------

print( "Loading Main.lua" )

include( "Conquer3.lua" )


local errorFlag = false -- tracks whether the lua script error occured

------------------------------------ GameEvents.PlayerDoTurn ------------------------------------

-- wrapper function that detects whether a lua script in the mod encounered an error
function PlotModWrapper( playerID )
	if errorFlag == true then PrintLuaErrorMessage() end
	errorFlag = true
	-------------------------------
	newConqueredPots = nil -- plots conquered by cureent player at this turn start 
	newConqueredPots = {} 
	
	PlotMod( playerID )
	-------------------------------
	errorFlag = false
end
GameEvents.PlayerDoTurn.Add( PlotModWrapper )


-- the actual mod entry function
function PlotMod( playerID )
	if playerID < 0 then return end

	EliminateEncircledPlots( playerID )

	local player = Players[ playerID ]
	if player == nil then return end
	local team = Teams[ player:GetTeam() ]
	local numEnemies = team:GetAtWarCount( false )
	-- print(string.format("%s has %d enemies)", player:GetName(), numEnemies));
	if numEnemies == 0 then return end -- no enemies --> no plots to conquer
	
	PlayerHexConquer( playerID )
	UpdateOwnerShipDuration()
end


--------------------------------- GameEvents.CityCaptureComplete --------------------------------

function CityModWrapper( oldPlayerID, isCapital, x, y, newPlayerID, int1, bool1 )
	if errorFlag == true then PrintLuaErrorMessage() end
	errorFlag = true
	-------------------------------
	CityMod( oldPlayerID, isCapital, x, y, newPlayerID, int1, bool1 )
	-------------------------------
	errorFlag = false
end
GameEvents.CityCaptureComplete.Add( CityModWrapper )


------------------------------------- Events.WarStateChanged ------------------------------------
function PeaceSigned( team1, team2, war )
	if errorFlag == true then PrintLuaErrorMessage() end
	errorFlag = true
	-------------------------------
	if war then --peace event expected
		errorFlag = false
		return
	end 
	
	--print(string.format( "%d signed peace with %d)", team1, team2));
	ReturnPlotsTeamToTeam( team1, team2 )
	-------------------------------
	errorFlag = false
	
end
Events.WarStateChanged.Add( PeaceSigned )


------------------------------------------- Debugging -------------------------------------------

--
function PrintLuaErrorMessage( )
	print( "ERROR  Script in Main.lua didn't terminate properly." )
	print( "       Please e-mail two most recent saves/autosaves to Matviyko.Rozumiyko@gmail.com" )
end

-------------------------------------------------------------------------------------------------
--------------------------------------- Utility Functions ---------------------------------------
-------------------------------------------------------------------------------------------------

--[[ buggy? don't use it
function PlayerHasEnemies( playerID )
	if playerID < 0 then return end
	for i = 0, 1000, 1 do
		local player2 = Players[ i ]
		if player2 ~= nil then
			--print( i, player2:GetName() )
		end
	end
	return false
end ]]


function PlayersAreAtWarByID( player1ID, player2ID )
	if player1ID == player2ID then return false end
	if player1ID < 0 or player2ID < 0 then return false end
	
	local player1 = Players[ player1ID ]
	local player2 = Players[ player2ID ]
	if player1 == nil or player2 == nil then return false end
	
	local team1 = Teams[ player1:GetTeam() ]	
	if team1:IsAtWar( player2:GetTeam() ) then return true end
	
	return false
end


--
function PlotsHaveACity( plots )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil then
			if plot:IsCity() then
				--print(string.format("  plot (%dx, %dy) is a city", plot:GetX(), plot:GetY()));
				return true
			end					
		end
	end	
	return false
end

function PlotIsAdjacentToCity( player, centralPlot )
	--print( "----------------" )
	local plots = GetAdjacentPlots( centralPlot )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil then
			if plot:IsCity() then
				--print(string.format("  plot (%dx, %dy) is a city", plot:GetX(), plot:GetY()));
				return true
			end
		end
	end	
end



function PlotIsAdjacentToEnemyCity( player, centralPlot )
	--print( "----------------" )
	local plots = GetAdjacentPlots( centralPlot )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil then
	local ownerPlayerID = plot:GetOwner()
	if( ownerPlayerID < 0) then return false end
	local ownerPlayer = Players[ ownerPlayerID ]
	local playerTeam = Teams[ player:GetTeam() ]
	local isEnemy = playerTeam:IsAtWar( ownerPlayer:GetTeam() )
			if plot:IsCity() and isEnemy then
				--print(string.format("  plot (%dx, %dy) is a city", plot:GetX(), plot:GetY()));
				return true
			end
		end
	end	
end





--
function PlotIsAdjacentToFriendlyPlot( player, centralPlot )
	--print( "----------------" )
	local plots = GetAdjacentPlots( centralPlot )
	if plots == nil then return false end
	for i, plot in pairs( plots ) do
		if plot ~= nil and plot:GetOwnershipDuration() > 0 then
			local ownerPlayer = Players[ plot:GetOwner() ];
			if( player == ownerPlayer ) then
				--print(string.format("  plot (%dx, %dy) is adjacent to friendly plot (%dx, %dy)", centralPlot:GetX(), centralPlot:GetY(), plot:GetX(), plot:GetY()));
				return true
			end
		end
	end	
end


-- written by Gedemon, edited by Matviyko Rozumiyko
function GetAdjacentPlots( plot )
	local plotList = {}
	local direction_types = {
		DirectionTypes.DIRECTION_NORTHEAST,
		DirectionTypes.DIRECTION_SOUTHEAST,
		DirectionTypes.DIRECTION_WEST,
		DirectionTypes.DIRECTION_EAST,
		DirectionTypes.DIRECTION_SOUTHWEST,
		DirectionTypes.DIRECTION_NORTHWEST
	}
	for loop, direction in ipairs(direction_types) do
		local adjPlot = Map.PlotDirection( plot:GetX(), plot:GetY(), direction )
		if ( adjPlot ~= nil ) then table.insert(plotList, adjPlot) end
	end
	return plotList
end


--
function getNearestCity( playerID, plot )
	local player = Players[ playerID ]
	local distance = 10000
	local nearestCity = nil
	for city in player:Cities() do
		distanceToCity = Map.PlotDistance( city:GetX(), city:GetY(), plot:GetX(), plot:GetY() )
		if( distanceToCity < distance) then
			distance = distanceToCity
			nearestCity = city
		end
	end
	return nearestCity
end


function getNearestCityWithException( playerID, plot, exceptCity)
	local player = Players[ playerID ]
	local nearestDistance = 10000
	local nearestCity = nil
	for city in player:Cities() do
		if city ~= exceptCity then
			distance = Map.PlotDistance( city:GetX(), city:GetY(), plot:GetX(), plot:GetY() )
			if( distance < nearestDistance) then
				nearestDistance = distance
				nearestCity = city
			end		
		end
	end
	if nearestCity == nil then nearestDistance = -1 end
	return nearestCity, nearestDistance
end


function getAnyNearestCity( plot )
	local closestCity = nil
	local closestDistance = 10000
	local num = GameDefines.MAX_PLAYERS - 1
	for id = 0, num, 1 do
		local player = Players[ id ]
		if player ~= nil and player:IsAlive() and not player:IsBarbarian() then
			local city, distance = getNearestCityWithException( id, plot, -1 )
			if distance < closestDistance then
				closestDistance = distance
				closestCity = city
			end	
		end	
	end
	return closestCity, closestDistance
end


-- For debugging
function showAdjacentPlotsInfo( plotList )
	for i, plot in pairs( plotList ) do	
		--print( i, plot:GetX(), plot:GetY() )
		if( plot:GetOwner() >= 0 ) then
			print( string.format( "adjacent[%d]: ownerID %d;", i, plot:GetOwner() ) )
		else
			print( string.format( "adjacent[%d]", i ) )
		end
	end
end


-- returns true if plot owner has a city within 3 plots to the plot
function PlotIsWithinCityRadius( player, plot )
	if player == nil then return false end
	if plot == nil then return false end
	for city in player:Cities() do
		if city ~= nil then
			distanceToCity = Map.PlotDistance( city:GetX(), city:GetY(), plot:GetX(), plot:GetY() )
			if distanceToCity <= 2 then
				return true
			end
		end
	end
	return false
end


function UpdateOwnerShipDuration()
	if newConqueredPots == nil then return end
	if # newConqueredPots == 0 then return end
	for i, plot in pairs( newConqueredPots ) do
		if plot ~= nil then
			plot:SetOwnershipDuration( 1 )
		end
	end
end

--[[
function ListNewConqueredPlots()
	if newConqueredPots == nil then return end
	if # newConqueredPots == 0 then return end
	print( "Conquered Plots:" )
	for i, plot in pairs( newConqueredPots ) do
		if plot ~= nil then
			print( "  ", i, plot:GetX(), plot:GetY() )
		end
	end
end


function IsANewConqueredPlot( plot )
	if plot == nil then return false end
	if newConqueredPots == nil then return false end
	if # newConqueredPots == 0 then return false end

	for i, newPlot in pairs( newConqueredPots ) do
		if newPlot  ~= nil and newPlot == plot then
			print(string.format("plot (%dx %dy) was conquered earlier.", plot:GetX(), plot:GetY() ))
			return true
		end
	end
	return false
end
]]