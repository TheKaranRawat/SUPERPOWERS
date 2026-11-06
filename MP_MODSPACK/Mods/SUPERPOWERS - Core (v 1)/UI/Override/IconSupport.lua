--==========================================================
-- Written by bc1 using Notepad++
-- Hooks into the popup manager from GenericPopup.lua
--==========================================================

if not AddSerialEventGameMessagePopup then
	include "IconHookup"
end

LuaEvents["PopupTypesFor"..ContextPtr:GetID()].Add( function( popupTypes )
--print( "Popups for", ContextPtr:GetID(), unpack( popupTypes ) )
	Events.SerialEventGameMessagePopup.Add = function( handler )
		AddSerialEventGameMessagePopup( handler, unpack( popupTypes ) )
	end
end)

LuaEvents.QuerySerialEventGameMessagePopup( ContextPtr )
