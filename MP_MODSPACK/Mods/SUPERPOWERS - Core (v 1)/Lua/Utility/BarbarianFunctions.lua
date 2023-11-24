-- Include other lua stuff:
--WARN_NOT_SHARED = false; include( "SaveUtils" ); MY_MOD_NAME = "Leugi_Barbarian_Era_Scripts";


-- BARBARIAN NAME CHANGE FUNCTION
--------------------------------------------------------------------------------------------------------------------

print ("Barb Function Start - BFS")

function Leugi_GetAvrgEra()
	local pEras = {}
	for _, pPlayer in pairs(Players) do
		if (pPlayer:IsAlive()) then
			local currentEra = pPlayer:GetCurrentEra()
			table.insert(pEras, currentEra)
		end
	end
	n = 0
	a = 0
	for _, i in pairs (pEras) do
		n = n + 1
		a = a + i
	end
	if a == 0 then
		eraID = 0
	else
		eraID = math.floor(a/n)
	end
	print ("Current Average Era:" .. eraID)
	return eraID
end

-------------------------------------------------------

function Leugi_BarbNameChange(eraID)
	print("Checking Barbarian Era")
	adj = nil
	camp = nil
	if eraID == 2 then
		oldname = "Barbarians"
		adj = "Brigand";
		camp = "Encampment";
		print ("Brigand days!")
	elseif eraID == 3 then
		oldname = "Brigands"
		adj = "Pirate";
		camp = "Encampment";
		print ("Pirate days!")
	elseif eraID == 4 or eraID == 5 then
		oldname = "Pirates"
		adj = "Rebel";
		camp = "Base";
		print ("Rebel days!")
	elseif eraID >= 6 then
		oldname = "Rebels"
		adj = "Terrorist";
		camp = "Base";
		print ("Terrorist days!")
	end
	print ("Barbarian precheck")
	if adj ~= nil then
		print ("MUST change barbarian names")
	   --if settings_BarbarianChangeAll == 1 then
			print ("Must change ALL barbarian names")
			Leugi_BarbChangeStrings(adj, camp)
		--else
			--Leugi_BarbChangeStringsLow(adj, camp)
		--end
	end
end

--------------------------------------------------------------------

function Leugi_BarbChangeStrings(adj, camp)
	print ("Changing Barbarian Strings:" .. adj .. "; " .. camp)
	-- Civname (Simply plural version of adjetive)
	plural = adj .. "s"
	name = "The " .. plural
	-- Plunder stuff
	plunder0 = "Filthy " .. plural .. "plundered the trade route you established between {1_CityName} and {2_CityName}.";
	plunder1 = plural .. " plundered the trade route {1_PlayerName} established between {2_CityName} and {3_CityName}";
	-- CS Quest stuff
	csquest0 = "We want you to defeat " .. plural .. " that are invading our territory."
	csquest1 = "They want you to defeat " .. adj .. " units that are invading their territory."
	csquest2 = "They will reward the player that destroys a nearby" .. camp
	csquest3 = "You have successfully destroyed the " .. camp .. " as requested by {1_MinorCivName:textkey}! Your [ICON_INFLUENCE] Influence over them has increased by [COLOR_POSITIVE_TEXT]{2_InfluenceReward}[ENDCOLOR]."
	csquest4 = "There is still that " .. camp .. " nearby that we would like someone to take care of."
	csquest5 = "They want a nearby " .. camp .. " destroyed.";
	csquest6 = "{1_CivName:textkey} requests your assistance against invading " .. plural .. "! Each " .. adj .. " you kill will earn you [ICON_INFLUENCE] Influence over the City-State.";
	csquest7 = "{1_CivName:textkey} no longer needs your assistance against" .. plural
	-- Killed near CS
	kill0 = "You have killed a group of " .. plural .. " near {1_CivName:textkey}! They are grateful, and your [ICON_INFLUENCE] Influence with them has increased by 12!";
	kill1 = adj .. " killed near {1_CivName:textkey}!";
	-- Raided
	raid0 = "Your City of {@1_CityName} was raided by " .. plural .. ", and {2_Num} Gold was stolen from the national treasury!";
	raid1 = name .. " have killed your {@1_UnitName} because you refused to pay heed to their demands!";
	-- Encampment cleared
	clear0 = "You have dispersed a villainous " .. camp .. " and recovered {1_NumGold} [ICON_GOLD] Gold from it!";
	-- Civilian captured
	capture0 = "A civilian was captured by " .. plural
	capture1 = "{TXT_KEY_GRAMMAR_UPPER_A_AN &lt;&lt; {@1_UnitName}} was captured by " .. plural .. "! They will take it to their nearest " .. camp .. ". If you wish to recover your unit you will have to track it down!";
	-- Discovered
	discover = "A " .. camp .. " has been discovered! It will create " .. adj .. " units until dispersed!"
	discover2 = camp .. " discovered";
	-----------------
	-- Update Table
	-----------------
	local tquery = {"UPDATE Language_en_US SET Text = '".. adj .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_ADJECTIVE'",
			"UPDATE Language_en_US SET Text = '".. name .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_SHORT_DESC'",
			"UPDATE Language_en_US SET Text = '".. camp .."' WHERE Tag = 'TXT_KEY_IMPROVEMENT_ENCAMPMENT'",
			"UPDATE Language_en_US SET Text = '".. plunder0 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_TRADE_UNIT_PLUNDERED_TRADER_BARBARIAN'",
			"UPDATE Language_en_US SET Text = '".. plunder1 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_TRADE_UNIT_PLUNDERED_TRADEE_BARBARIANS'",
			"UPDATE Language_en_US SET Text = '".. csquest0 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_INVADING_BARBS'",
			"UPDATE Language_en_US SET Text = '".. csquest1 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_INVADING_BARBS_FORMAL'",
			"UPDATE Language_en_US SET Text = '".. csquest2 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_KILL_CAMP_FORMAL'",
			"UPDATE Language_en_US SET Text = '".. csquest3 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_QUEST_COMPLETE_KILL_CAMP'",
			"UPDATE Language_en_US SET Text = '".. csquest4 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_KILL_CAMP'",
			"UPDATE Language_en_US SET Text = '".. csquest5 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_KILL_CAMP_FORMAL'",
			"UPDATE Language_en_US SET Text = '".. csquest6 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_MINOR_BARBS_QUEST'",
			"UPDATE Language_en_US SET Text = '".. csquest7 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_MINOR_BARBS_QUEST_LOST_CHANCE'",
			"UPDATE Language_en_US SET Text = '".. discover .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_FOUND_BARB_CAMP'",
			"UPDATE Language_en_US SET Text = '".. kill0 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_MINOR_BARB_KILLED'",
			"UPDATE Language_en_US SET Text = '".. kill1 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_SM_MINOR_BARB_KILLED'" ,
			"UPDATE Language_en_US SET Text = '".. raid0 .."' WHERE Tag = 'TXT_KEY_MISC_YOU_CITY_RANSOMED_BY_BARBARIANS'",
			"UPDATE Language_en_US SET Text = '".. clear0 .."' WHERE Tag = 'TXT_KEY_MISC_DESTROYED_BARBARIAN_CAMP'" ,
			"UPDATE Language_en_US SET Text = '".. capture0 .."' WHERE Tag = 'TXT_KEY_UNIT_CAPTURED_BARBS'",
			"UPDATE Language_en_US SET Text = '".. capture1 .."' WHERE Tag = 'TXT_KEY_UNIT_CAPTURED_BARBS_DETAILED'",
			"UPDATE Language_en_US SET Text = '".. discover2 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_SUMMARY_FOUND_BARB_CAMP'"
			}
	for i, iQuery in pairs(tquery) do
		print ("Changing Barbarian Texts: " .. i .. "/" .. #tquery );
		for result in DB.Query(iQuery) do
		end
	end
	-- Hope
	--UpdateBarbs()
	--
	Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
	print ("Barbarian Name Change Succesful")

end

-- Check on load

function CheckStuffOnLoad (arg0, currPlayer)
	print ("Barbarian Load Function - BLF")
	aPlayer = Players[0]
	eraID = Leugi_GetAvrgEra()
	--if settings_BarbarianNames == 1 then
		Leugi_BarbNameChange(eraID)
	--end
	--if settings_BarbarianPromos == 1 then
	--	Leugi_BarbPromoChange(eraID)
	--end
	--save(aPlayer, "Last Era Changed", eraID)
end

--if settings_BarbarianNames == 1 or settings_BarbarianPromos == 1 then
Events.LoadScreenClose.Add(CheckStuffOnLoad)
--end

print ("Barbarian Inmersion Era Changes Active")
Events.SerialEventEraChanged.Add(CheckStuffOnLoad)