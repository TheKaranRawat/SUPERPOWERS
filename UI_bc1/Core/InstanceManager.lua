-- Written by bc1 using Notepad++

include "StackInstanceManager"
local StackInstanceManager = StackInstanceManager

-- CustomMod, ScenariosMenu, SaveMapMenu, SaveMenu, but not LoadTutorial !
local lb = { LoadButton = "InstanceRoot" }
local kludges = ({ ModsCustom = lb, ScenariosScreen = lb, LoadMenu = lb, SaveMapMenu=lb, SaveMenu = lb })[ ContextPtr:GetID() ] or {}

InstanceManager = { new = function( o, instanceName, rootControlName, parentControl )
	if kludges[instanceName] then
		rootControlName = kludges[instanceName]
	end
	o = StackInstanceManager( instanceName, rootControlName, parentControl )
	-- Compatibility
	o.m_InstanceName     = instanceName
	o.m_RootControlName  = rootControlName
	o.m_ParentControl    = parentControl
	o.BuildInstance = function() end
	return o
end }
GenerationalInstanceManager = InstanceManager
