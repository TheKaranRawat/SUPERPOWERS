-----------------------
-- Author: Gaia
-- Special Thanks: WHoward; SMAN
-----------------------

print("UI - Notify Nuclear Attack Script Loaded")

local g_NotificationType = NotificationTypes.NOTIFICATION_GENERIC

function OnNuclearAttackNotificationId(id)
  print(string.format("Setting nuclear attack notification id to %i", id))
  g_NotificationType = id
end
LuaEvents.NuclearAttackNotificationId.Add(OnNuclearAttackNotificationId)

function NuclearAttackFunction(ePlayer, iPlotX, iPlotY, bWar, bBystander)					-- Game event: fires each time a nuke is exploded
	local pPlayer = Players[ePlayer]														-- Set up the attacker pointer	
	if not pPlayer then																		-- If the player pointer isn't valid, then...  (exit early
		print("NuclearAttackFunction.  ERROR!  pPlayer is nil.  Exiting early...")
		return
	end
		
	print("NuclearAttackFunction.   Nuker: " .. pPlayer:GetCivilizationShortDescription() .. "    ePlayer: " .. ePlayer .. "    X/Y: " .. iPlotX .. " / " .. iPlotY .. "    War?: " .. tostring(bWar) .. "    Bystander?: " .. tostring(bBystander))
	
	local pTargetPlot = Map.GetPlot(iPlotX, iPlotY)										-- Get the plot pointer for the sticken X/Y
	if pTargetPlot then																	-- If the plot pointer is valid, then...
		NuclearReportFunction(ePlayer, iPlotX, iPlotY, bWar, bBystander)				-- If we have a valid target plot, then call the general "nuclear report" function (simply sends a notification of the attack; diplo responses come afterwards/below)
	end
end
GameEvents.NuclearDetonation.Add(NuclearAttackFunction) 

function NuclearReportFunction(ePlayer, iPlotX, iPlotY, bWar, bBystander)					-- Displays a notification letting human players know a nuke was dropped at X/Y
	local pPlayer = Players[ePlayer]
	if pPlayer then																			-- If the player pointer is valid, then...		
		local sLocation = GetTargetLocationDescription(iPlotX, iPlotY)						-- Get a string describing the target location
		local sText = pPlayer:GetCivilizationShortDescription() .. " has launched a devastating nuclear attack " .. sLocation	.. "!"
		local sHeading = "A Nuclear Strike has Occurred"
		SendNotificationToHumanPlayers(sHeading, sText, iPlotX, iPlotY, -1, -1, -1)			-- Issue the notification
	end
end

function GetTargetLocationDescription(iPlotX, iPlotY)										-- Builds a "target location" string, describing what was attacked at the incoming X/Y
	local sLocation = ""																	-- Set up the default return string as nil 

	if (not iPlotX) or (not iPlotY) then													-- If the incoming X or Y is nil, then...
		sLocation = "at an unknown location"												-- Return "UNK"
	else																					-- If the locations aren't nil, then...
		sLocation = "at location " .. iPlotX .. " / " .. iPlotY								-- Set up the target location string to the "X / Y" location	
	end

	local pTargetPlot = Map.GetPlot(iPlotX, iPlotY)											-- Get a plot pointer for the incoming coordinates of the attack
	if pTargetPlot then																		-- If the plot pointer is valid, then...		
		if (pTargetPlot:IsCity()) then														-- If the target plot is a city, then...
			local pCity = pTargetPlot:GetPlotCity()											-- Get the city pointer for the target plot
			if pCity then																	-- If the city pointer is valid, then...
				sLocation = "against " .. pCity:GetName()									-- Change the location string to the city's name
			end
		end
	end

	return sLocation
end

function SendNotificationToHumanPlayers(sNotificationTitle, sNotificationMessage, iX, iY, iDisplayUnitType, iPlayerAttacker, iPlayerDefender)
	for iDX = 0, GameDefines.MAX_MAJOR_CIVS-1 do											-- Cycle through all all major players...		
		if (Players[iDX]:IsAlive()) and (Players[iDX]:IsHuman()) then						-- If the loop civ is alive AND human, then...
			Players[iDX]:AddNotification(g_NotificationType, sNotificationMessage, sNotificationTitle, iX, iY, false, false, false)
			--NotificationStatus.SetValue("NukeMessageSent", "Sent")
		end
	end
end

LuaEvents.NuclearAttackNotificationIdRequest()