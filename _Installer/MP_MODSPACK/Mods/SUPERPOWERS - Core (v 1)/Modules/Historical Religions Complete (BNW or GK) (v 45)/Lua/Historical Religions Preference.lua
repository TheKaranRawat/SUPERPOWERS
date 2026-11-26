print("HR Scripts")

local isBNW = (GameInfoTypes.UNITCOMBAT_SUBMARINE ~= nil);

--Multiple Preferences

-- Multiple preferences work; however, too many people seem to use mods with outdated DLLs 
-- that don't include OnGetReligionToFound. Not worth the hassle on my part having people 
-- constantly complain preferences are broken because of this.

--[[
function IsReligionAvailable(iReligion)
	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do	
		local pPlayer = Players[iPlayer]
		if (pPlayer:IsEverAlive() and pPlayer:HasCreatedReligion() and pPlayer:GetReligionCreatedByPlayer() == iReligion) then
			return false
		end
	end
	return true
end

function OnGetReligionToFound(ePlayer, eCivDefaultReligion, bCivDefaultReligionFounded)
	local sPlayerCivType = GameInfo.Civilizations[Players[ePlayer]:GetCivilizationType()].Type
	for civReligion in GameInfo.Civilization_Religions("CivilizationType='" .. sPlayerCivType .. "'") do
		local iReligion = GameInfoTypes[civReligion.ReligionType]
		if (IsReligionAvailable(iReligion)) then
			return iReligion
		end
	end
	return eCivDefaultReligion
end
GameEvents.GetReligionToFound.Add(OnGetReligionToFound)
--]]

--Rename Religion on Founding

local rAtanodjuwaja = GameInfoTypes.RELIGION_MYSTERIES;

for pPlayer=0, GameDefines.MAX_MAJOR_CIVS-1 do
	local pPlayer = Players[pPlayer];
	if pPlayer:IsEverAlive() then

		if isBNW then

			local religionID = pPlayer:GetReligionCreatedByPlayer()

			if (pPlayer:GetCivilizationType() == GameInfoTypes.CIVILIZATION_DMS_NURAGIC) then
				if religionID == rAtanodjuwaja then
					local tquery = {"UPDATE Language_en_US SET Text = 'Cult of Waters' WHERE Tag = 'TXT_KEY_RELIGION_HELLENISM_4_MYSTERIES'"}
					for i,iQuery in pairs(tquery) do
						for result in DB.Query(iQuery) do
						end
					end
					Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
				end
			end

		end

	end
end

function HRMiscNames(ePlayer, holyCityId, eReligion, eBelief1, eBelief2, eBelief3, eBelief4, eBelief5)
	local pPlayer = Players[ePlayer]

	if isBNW then

		if (pPlayer:GetCivilizationType() == GameInfoTypes.CIVILIZATION_DMS_NURAGIC) then
			if eReligion == rAtanodjuwaja then
				local tquery = {"UPDATE Language_en_US SET Text = 'Cult of Waters' WHERE Tag = 'TXT_KEY_RELIGION_HELLENISM_4_MYSTERIES'"}
				for i,iQuery in pairs(tquery) do
					for result in DB.Query(iQuery) do
					end
				end
				Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
			end
		end

	end

end
GameEvents.ReligionFounded.Add(HRMiscNames)

