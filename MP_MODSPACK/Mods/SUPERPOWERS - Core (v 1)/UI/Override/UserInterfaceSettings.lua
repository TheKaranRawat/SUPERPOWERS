--==========================================================
-- Written by bc1 using Notepad++
--==========================================================
if not UserInterfaceSettings and MapModData then
	if not MapModData.EUI_UserInterfaceSettings then
		print "Loading EUI context"
		ContextPtr:LookUpControl(".."):LoadNewContext( "EUI_context" )
	end
	UserInterfaceSettings = MapModData.EUI_UserInterfaceSettings
end
if not UserInterfaceSettings then
	include "UserInterfaceSettingCache"
end
