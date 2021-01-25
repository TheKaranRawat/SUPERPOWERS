--==========================================================
-- EUI context hosts interface settings and tooltip server
-- Written by bc1 using Notepad++
--==========================================================

local pairs = pairs
local print = print
local insert = table.insert
local format = string.format
local concat = table.concat

local ContentManager = ContentManager
local ContentTypeGAMEPLAY = ContentType.GAMEPLAY
local Locale = Locale
local Modding = Modding

-- Print game DLC and MOD configuration for debug
local t= { "DLC/MOD configuration" }
for _, v in pairs( ContentManager.GetAllPackageIDs() ) do
	insert( t, format( "%s DLC: %s %s", ContentManager.IsActive(v, ContentTypeGAMEPLAY) and "Active" or "Disabled", v, Locale.Lookup(ContentManager.GetPackageDescription(v)) ) )
end
for _, v in pairs( Modding.GetActivatedMods() ) do
	insert( t, format( "Active MOD: %s %s v%s", v.ID, Modding.GetModProperty(v.ID, v.Version, "Name"), v.Version ) )
	if v.ID == "34fb6c19-10dd-4b65-b143-fd00b2c0826f" then
		IsNewWorldDeluxeScenario = true
	end
end
print( table.concat( t,"\n\t" ) )

if Game then
	local slotStatus = {}
	for k, v in pairs( SlotStatus ) do slotStatus[ v ] = k end
	local t = {}
	for playerID = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		local player = Players[ playerID ]
		if player:IsEverAlive() then
			insert( t, format( "\n\tplayer %-4iteam %-4i%-22s%-14sciv %-4i%s",
						playerID, PreGame.GetTeam( playerID ), GameInfo.HandicapInfos[ PreGame.GetHandicap( playerID ) ].Type, slotStatus[ PreGame.GetSlotStatus( playerID ) ], PreGame.GetCivilization( playerID ), player:GetCivilizationShortDescription() ) )
		end
	end
	print( format( "there are %i major civs and %i minor civs in the game", #t, PreGame.GetNumMinorCivs() ), concat(t) )

	include "GameInfoActualCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
	MapModData.EUI_GameInfoCache = GameInfoCache
	print "Loaded EUI game info cache"
	include "UserInterfaceSettingCache"
	MapModData.EUI_UserInterfaceSettings = UserInterfaceSettings
	print "Loaded EUI settings cache"
	include "EUI_tooltip_server"
end
