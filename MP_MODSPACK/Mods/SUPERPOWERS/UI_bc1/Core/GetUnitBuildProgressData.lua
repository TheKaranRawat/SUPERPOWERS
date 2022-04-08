-- Written by bc1 using Notepad++

local ceil = math.ceil

function GetUnitBuildProgressData( plot, buildID, unit )
	local unitOwner = unit:GetOwner()
	local buildProgress = plot:GetBuildProgress( buildID )
	local nominalWorkRate = unit:WorkRate( true )
	-- take into account unit.cpp "wipe out all build progress also" game bug
	local buildTime = plot:GetBuildTime( buildID, unitOwner ) - nominalWorkRate
	local buildTurnsLeft
	if buildProgress == 0 then
		buildTurnsLeft = plot:GetBuildTurnsLeft( buildID, unitOwner, nominalWorkRate - unit:WorkRate() )
	else
		buildProgress = buildProgress - nominalWorkRate
		buildTurnsLeft = plot:GetBuildTurnsLeft( buildID, unitOwner, -unit:WorkRate() )
	end
	if buildTurnsLeft > 99999 then
		return ceil( ( buildTime - buildProgress ) / nominalWorkRate ), buildProgress, buildTime
	else
		return buildTurnsLeft, buildProgress, buildTime
	end
end
