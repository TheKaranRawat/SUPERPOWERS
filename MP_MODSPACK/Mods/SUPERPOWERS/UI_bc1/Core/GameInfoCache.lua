--==========================================================
-- Written by bc1 using Notepad++
--==========================================================

if not GameInfoCache and MapModData then
	local ptr = ContextPtr:LookUpControl("..")
	if not MapModData.EUI_GameInfoCache and ptr and ptr:GetID():lower()=="ingame" then
		ptr:LoadNewContext( "EUI_context" )
	end
	GameInfoCache = MapModData.EUI_GameInfoCache
end
if not GameInfoCache then
	include "GameInfoActualCache"
end
