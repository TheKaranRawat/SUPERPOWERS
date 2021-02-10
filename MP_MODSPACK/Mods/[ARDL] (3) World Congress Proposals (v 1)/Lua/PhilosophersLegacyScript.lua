-- PhilosophersLegacyScript
-- Author: Vicevirtuoso
-- DateCreated: 2/11/2014 11:23:54 PM
--------------------------------------------------------------

local iMaxCivs = GameDefines.MAX_MAJOR_CIVS
local iBaseGold = 100 --Modified by Game Speed

local iBronzeB = GameInfoTypes.BUILDING_PL_BRONZE_DUMMY
local iSilverB = GameInfoTypes.BUILDING_PL_SILVER_DUMMY
local iGoldB = GameInfoTypes.BUILDING_PL_GOLD_DUMMY
local iAlreadyGold = GameInfoTypes.BUILDING_PL_GOLD_DUMMY_POST_COMPLETION

local iBronzeP = GameInfoTypes.POLICY_PHILOSOPHERS_LEGACY_BRONZE_DUMMY
local iSilverP = GameInfoTypes.POLICY_PHILOSOPHERS_LEGACY_SILVER_DUMMY

function PhilosophersLegacy(iPlayer)
	if iPlayer < iMaxCivs then
		local pPlayer = Players[iPlayer]
		local pCapital = pPlayer:GetCapitalCity()
		if pCapital then
			if pCapital:IsHasBuilding(iBronzeB) and not pPlayer:HasPolicy(iBronzeP) then
				pPlayer:SetNumFreePolicies(1)
				pPlayer:SetNumFreePolicies(0)
				pPlayer:SetHasPolicy(iBronzeP, true)
			end
			if pCapital:IsHasBuilding(iSilverB) and not pPlayer:HasPolicy(iSilverP) then
				pPlayer:SetNumFreePolicies(1)
				pPlayer:SetNumFreePolicies(0)
				pPlayer:SetHasPolicy(iSilverP, true)
			end
			if pCapital:IsHasBuilding(iGoldB) and not pCapital:IsHasBuilding(iAlreadyGold) then
				local iGoldMod = GameInfo.GameSpeeds[PreGame.GetGameSpeed()].GoldPercent / 100
				local iTotalGold = math.ceil((pPlayer:GetNumMilitaryUnits() * iBaseGold) * iGoldMod)
				pPlayer:ChangeGold(iTotalGold)
				local sText = Locale.ConvertTextKey("TXT_KEY_PHILEG_NOTIFICATION_TEXT", iTotalGold)
				local sTitle = Locale.ConvertTextKey("TXT_KEY_PHILEG_NOTIFICATION_TITLE")
				pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, -1, -1)
				pCapital:SetNumRealBuilding(iAlreadyGold, 1)
			end
		end
	end
end


GameEvents.PlayerDoTurn.Add(PhilosophersLegacy)