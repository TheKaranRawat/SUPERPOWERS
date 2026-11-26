--==========================================================
-- Written by bc1 using Notepad++
--==========================================================
local pcall = pcall
local pairs = pairs
local print = print

local UserData = Modding.OpenUserData( "Enhanced User Interface Options", 2 )
local GetUserDataValue = UserData.GetValue
local UserInterfaceSettingsCache = setmetatable( {}, { __index = function( t, k ) local v = GetUserDataValue( k ) or 1 t[k] = v return v end } )
UserInterfaceSettings = setmetatable( {}, { __index = UserInterfaceSettingsCache } )

ContextPtr:SetShutdown( function() pcall( function()
	print( "Saving settings..." )
	local SetUserDataValue = UserData.SetValue
	for k, v in pairs( UserInterfaceSettings ) do
		if v ~= UserInterfaceSettingsCache[k] then
			SetUserDataValue( k, v )
		end
	end
	if MapModData then
		MapModData.EUI_GameInfoCache = nil
		MapModData.EUI_UserInterfaceSettings = nil
	end
	print( "Shutdown complete\n", ("="):rep(100),"\n\n\n" )
end) end)
