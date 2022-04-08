-------------------------------------------------
-- Great People
-- Written by bc1 using Notepad++
-------------------------------------------------
local ceil = math.ceil
local GameInfo = GameInfoCache -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GetNumActiveLeagues = Game.GetNumActiveLeagues
local GetActiveLeague = Game.GetActiveLeague

-- TODO: optimize loop, add capability for several simultaneous gp's
function ScanGP( player )
	local gp = nil
	for city in player:Cities() do

		for specialist in GameInfo.Specialists() do

			local gpuClass = specialist.GreatPeopleUnitClass	-- nil / UNITCLASS_ARTIST / UNITCLASS_SCIENTIST / UNITCLASS_MERCHANT / UNITCLASS_ENGINEER ...
			local unitClass = gpuClass and GameInfo.UnitClasses[gpuClass]
			if unitClass then
				local gpThreshold = city:GetSpecialistUpgradeThreshold(unitClass.ID)
				local gpProgress = city:GetSpecialistGreatPersonProgressTimes100(specialist.ID) / 100
				local gpChange = specialist.GreatPeopleRateChange * city:GetSpecialistCount( specialist.ID )
				for building in GameInfo.Buildings{ SpecialistType = specialist.Type } do
					if city:IsHasBuilding(building.ID) then
						gpChange = gpChange + building.GreatPeopleRateChange
					end
				end

				local gpChangePlayerMod = player:GetGreatPeopleRateModifier()
				local gpChangeCityMod = city:GetGreatPeopleRateModifier()
				local gpChangePolicyMod = 0
				local gpChangeWorldCongressMod = 0
				local gpChangeGoldenAgeMod = 0
				local isGoldenAge = player:GetGoldenAgeTurns() > 0

				if GetNumActiveLeagues then
					-- Generic GP mods

					gpChangePolicyMod = player:GetPolicyGreatPeopleRateModifier()

					local worldCongress = (GetNumActiveLeagues() > 0) and GetActiveLeague()

					-- GP mods by type
					if specialist.GreatPeopleUnitClass == "UNITCLASS_WRITER" then
						gpChangePlayerMod = gpChangePlayerMod + player:GetGreatWriterRateModifier()
						gpChangePolicyMod = gpChangePolicyMod + player:GetPolicyGreatWriterRateModifier()
						if worldCongress then
							gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetArtsyGreatPersonRateModifier()
						end
						if isGoldenAge and player:GetGoldenAgeGreatWriterRateModifier() > 0 then
							gpChangeGoldenAgeMod = gpChangeGoldenAgeMod + player:GetGoldenAgeGreatWriterRateModifier()
						end
					elseif specialist.GreatPeopleUnitClass == "UNITCLASS_ARTIST" then
						gpChangePlayerMod = gpChangePlayerMod + player:GetGreatArtistRateModifier()
						gpChangePolicyMod = gpChangePolicyMod + player:GetPolicyGreatArtistRateModifier()
						if worldCongress then
							gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetArtsyGreatPersonRateModifier()
						end
						if isGoldenAge and player:GetGoldenAgeGreatArtistRateModifier() > 0 then
							gpChangeGoldenAgeMod = gpChangeGoldenAgeMod + player:GetGoldenAgeGreatArtistRateModifier()
						end
					elseif specialist.GreatPeopleUnitClass == "UNITCLASS_MUSICIAN" then
						gpChangePlayerMod = gpChangePlayerMod + player:GetGreatMusicianRateModifier()
						gpChangePolicyMod = gpChangePolicyMod + player:GetPolicyGreatMusicianRateModifier()
						if worldCongress then
							gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetArtsyGreatPersonRateModifier()
						end
						if isGoldenAge and player:GetGoldenAgeGreatMusicianRateModifier() > 0 then
							gpChangeGoldenAgeMod = gpChangeGoldenAgeMod + player:GetGoldenAgeGreatMusicianRateModifier()
						end
					elseif specialist.GreatPeopleUnitClass == "UNITCLASS_SCIENTIST" then
						gpChangePlayerMod = gpChangePlayerMod + player:GetGreatScientistRateModifier()
						gpChangePolicyMod = gpChangePolicyMod + player:GetPolicyGreatScientistRateModifier()
						if worldCongress then
							gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetScienceyGreatPersonRateModifier()
						end
					elseif specialist.GreatPeopleUnitClass == "UNITCLASS_MERCHANT" then
						gpChangePlayerMod = gpChangePlayerMod + player:GetGreatMerchantRateModifier()
						gpChangePolicyMod = gpChangePolicyMod + player:GetPolicyGreatMerchantRateModifier()
						if worldCongress then
							gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetScienceyGreatPersonRateModifier()
						end
					elseif specialist.GreatPeopleUnitClass == "UNITCLASS_ENGINEER" then
						gpChangePlayerMod = gpChangePlayerMod + player:GetGreatEngineerRateModifier()
						gpChangePolicyMod = gpChangePolicyMod + player:GetPolicyGreatEngineerRateModifier()
						if worldCongress then
							gpChangeWorldCongressMod = gpChangeWorldCongressMod + worldCongress:GetScienceyGreatPersonRateModifier()
						end
					end

					-- Player mod actually includes policy mod and World Congress mod, so separate them for tooltip

					gpChangePlayerMod = gpChangePlayerMod - gpChangePolicyMod - gpChangeWorldCongressMod

				elseif gpuClass == "UNITCLASS_SCIENTIST" then

					gpChangePlayerMod = gpChangePlayerMod + player:GetTraitGreatScientistRateModifier()

				end

				gpChange = gpChange * (1 + (gpChangePlayerMod + gpChangePolicyMod + gpChangeWorldCongressMod + gpChangeCityMod + gpChangeGoldenAgeMod) / 100)

				if gpChange > 0 then
					local gpTurns = ceil( (gpThreshold - gpProgress) / gpChange )
					if not gp or gpTurns < gp.Turns then
						gp = {
							Turns = gpTurns,
							City = city,
							Class = unitClass,
							Progress = gpProgress,
							Threshold = gpThreshold,
							Change = gpChange,
						}
					end
				end

			end -- unitClass
		end -- specialist
	end -- city
	return gp
end
