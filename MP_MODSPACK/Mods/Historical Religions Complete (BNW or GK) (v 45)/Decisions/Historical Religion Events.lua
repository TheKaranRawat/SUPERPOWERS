print("HR Events")

local isBNW = (GameInfoTypes.UNITCOMBAT_SUBMARINE ~= nil);
local isEEraExt = (GameInfoTypes.UNIT_EE_CUIRASSIER ~= nil);

function JFD_IsUsingPietyPrestige()
        local pietyPrestigeModID = "eea66053-7579-481a-bb8d-2f3959b59974"
        local isUsingPiety = false
       
        for _, mod in pairs(Modding.GetActivatedMods()) do
          if (mod.ID == pietyPrestigeModID) then
            isUsingPiety = true
            break
          end
        end
 
        return isUsingPiety
end

function GetHumanPlayer()
	local hPlayer = 0;
	for oPlayer=0, GameDefines.MAX_MAJOR_CIVS-1 do
		local oPlayer = Players[oPlayer];
		if (oPlayer:IsAlive()) and (oPlayer:IsHuman()) then
			hPlayer = oPlayer;
			break
		end
	end
	return hPlayer;
end

function GetRandomHR(lower, upper)
    return (Game.Rand((upper + 1) - lower, "")) + lower
end

local rCatholic = GameInfoTypes.RELIGION_CHRISTIANITY;

local rOrthodox = GameInfoTypes.RELIGION_ORTHODOXY;

local rIslam1 = GameInfoTypes.RELIGION_ISLAM;
local rIslam2 = GameInfoTypes.RELIGION_ISLAM_SHIA;
local rIslam3 = GameInfoTypes.RELIGION_ISLAM_IBADI;
local rIslam4 = GameInfoTypes.RELIGION_MUTAZILA;
local rIslam5 = GameInfoTypes.RELIGION_DRUZE;
local rIslam6 = GameInfoTypes.RELIGION_AHMADI;

local rJudaism = GameInfoTypes.RELIGION_JUDAISM;

local rGreek1 = GameInfoTypes.RELIGION_HELLENISM;
local rGreek2 = GameInfoTypes.RELIGION_NUMENISM;
local rGreek3 = GameInfoTypes.RELIGION_IMPERIAL_CULT;
local rGreek4 = GameInfoTypes.RELIGION_HEROS_KARABAZMOS;
local rGreek5 = GameInfoTypes.RELIGION_ATANODJUWAJA;

local rTao = GameInfoTypes.RELIGION_TAOISM;

local rWestAfrica1 = GameInfoTypes.RELIGION_ITAN;
local rWestAfrica2 = GameInfoTypes.RELIGION_ODINANI;
local rWestAfrica3 = GameInfoTypes.RELIGION_VODUN;

local rNorse = GameInfoTypes.RELIGION_FORN_SIDR;

local rHindu1 = GameInfoTypes.RELIGION_HINDUISM;
local rHindu2 = GameInfoTypes.RELIGION_SHAKTI;
local rHindu3 = GameInfoTypes.RELIGION_SHIVA;
local rHindu4 = GameInfoTypes.RELIGION_VISHNU;
local rHindu5 = GameInfoTypes.RELIGION_JAIN;
local rHindu6 = GameInfoTypes.RELIGION_VAJRAYANA;

local rNative1 = GameInfoTypes.RELIGION_WAKAN_TANKA;
local rNative2 = GameInfoTypes.RELIGION_POHAKANTENNA;
local rNative3 = GameInfoTypes.RELIGION_ORENDA;
local rNative4 = GameInfoTypes.RELIGION_SOUTHERN_CULT;
local rNative5 = GameInfoTypes.RELIGION_KACHINA;

local rAfrica1 = GameInfoTypes.RELIGION_AMATONGO;
local rAfrica2 = GameInfoTypes.RELIGION_LAIBONI;
local rAfrica3 = GameInfoTypes.RELIGION_NZAMBIISM;
local rAfrica4 = GameInfoTypes.RELIGION_BUMUNTU;
local rAfrica5 = GameInfoTypes.RELIGION_MWARI;

local rConfucian = GameInfoTypes.RELIGION_CONFUCIANISM;

local rProtestant1 = GameInfoTypes.RELIGION_PROTESTANTISM;
local rProtestant2 = GameInfoTypes.RELIGION_PROTESTANT_CALVINISM;
local rProtestant3 = GameInfoTypes.RELIGION_PROTESTANT_METHODISM;
local rProtestant4 = GameInfoTypes.RELIGION_PROTESTANT_BAPTIST;
local rProtestant5 = GameInfoTypes.RELIGION_CHRISTIAN_ANGLICANISM;

local bHREsoteric = GameInfoTypes.BUILDING_HR_ESOTERIC_DUMMY;

local pHREsoteric = GameInfoTypes.POLICY_HR_ESOTERIC_DUMMY;
local pHRSpiritualist = GameInfoTypes.POLICY_HR_SPIRITUALIST_DUMMY;

local eAncient = GameInfoTypes.ERA_ANCIENT;
local eClassic = GameInfoTypes.ERA_CLASSICAL;
local eIndustrial = GameInfoTypes.ERA_INDUSTRIAL;
local eModern = GameInfoTypes.ERA_MODERN;
local eInformation = GameInfoTypes.ERA_FUTURE;

--=========================================================
--Esotericism
--=========================================================
local Event_TomatekhHREsotericism = {}
	Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM"
	Event_TomatekhHREsotericism.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_DESC"
	Event_TomatekhHREsotericism.EventImage = "HREsoteric.dds"
	Event_TomatekhHREsotericism.Weight = 1
	Event_TomatekhHREsotericism.CanFunc = (
		function(pPlayer)		
		
			if load(pPlayer, "Event_TomatekhHREsotericism") == true then return false end
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
                religionID = JFD_GetStateReligion(pPlayer:GetID())
            end
			if religionID <= 0 then return false end
			
			if not isBNW then return false end

			if (GetNumReligionsinEmpire(pPlayer) < 2) then return false end

			local pTeam = pPlayer:GetTeam();
			if (Teams[pTeam]:GetCurrentEra() == eAncient) then return false end
			if (Teams[pTeam]:GetCurrentEra() == eClassic) then return false end
			if (Teams[pTeam]:GetCurrentEra() == eIndustrial) then return false end
			if (Teams[pTeam]:GetCurrentEra() == eInformation) then return false end

			Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM"
			Event_TomatekhHREsotericism.EventImage = "HREsoteric.dds"
			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then
				if (religionID == rCatholic) then 
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_CHRISTIAN" 
					Event_TomatekhHREsotericism.EventImage = "HREsotericChristian.dds"
				end
				if (religionID == rOrthodox) then 
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_EASTERN" 
					Event_TomatekhHREsotericism.EventImage = "HREsotericOrthodox.dds"
				end
				if (religionID == rIslam1) or (religionID == rIslam2) or (religionID == rIslam3) or (religionID == rIslam4) or (religionID == rIslam5) or (religionID == rIslam6) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_ISLAM"
					Event_TomatekhHREsotericism.EventImage = "HREsotericIslam.dds"
				end
				if (religionID == rJudaism) then 
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_JUDAISM" 
					Event_TomatekhHREsotericism.EventImage = "HREsotericJudaism.dds"
				end
				if (religionID == rGreek1) or (religionID == rGreek2) or (religionID == rGreek3) or (religionID == rGreek4) or (religionID == rGreek5) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_GREEK"
					Event_TomatekhHREsotericism.EventImage = "HREsotericGreek.dds"
				end
				if (religionID == rTao) then 
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_TAOISM" 
					Event_TomatekhHREsotericism.EventImage = "HREsotericTao.dds"
				end
				if (religionID == rWestAfrica1) or (religionID == rWestAfrica2) or (religionID == rWestAfrica3) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_ITAN"
					Event_TomatekhHREsotericism.EventImage = "HREsotericIfa.dds"
				end
				if (religionID == rNorse) then 
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NORSE"
					 Event_TomatekhHREsotericism.EventImage = "HREsotericNorse.dds"
				end
				if (religionID == rHindu1) or (religionID == rHindu2) or (religionID == rHindu3) or (religionID == rHindu4) or (religionID == rHindu5) or (religionID == rHindu6) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_HINDU"
					Event_TomatekhHREsotericism.EventImage = "HREsotericYoga.dds"
				end
				if (religionID == rNative1) or (religionID == rNative2) or (religionID == rNative3) or (religionID == rNative4) or (religionID == rNative5) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_SIOUX"
					Event_TomatekhHREsotericism.EventImage = "HREsotericIndian.dds"
				end
				if (religionID == rAfrica1) or (religionID == rAfrica2) or (religionID == rAfrica3) or (religionID == rAfrica4) or (religionID == rAfrica5) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_AFRICA"
					Event_TomatekhHREsotericism.EventImage = "HREsotericMuti.dds"
				end
				if (religionID == rConfucian) then 
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_CONFUCIAN" 
					Event_TomatekhHREsotericism.EventImage = "HREsotericConfuci.dds"
				end
				if (religionID == rProtestant1) or (religionID == rProtestant2) or (religionID == rProtestant3) or (religionID == rProtestant4) or (religionID == rProtestant5) then
					Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_PROTESTANT"
					Event_TomatekhHREsotericism.EventImage = "HREsotericProtest.dds"
				end
			elseif (Teams[pTeam]:GetCurrentEra() > eIndustrial) then
				Event_TomatekhHREsotericism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NEW_AGE"
				Event_TomatekhHREsotericism.EventImage = "HREsotericNewAge.dds"
			end

			Event_TomatekhHREsotericism.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_DESC"
			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then
				if (religionID == rProtestant1) or (religionID == rProtestant2) or (religionID == rProtestant3) or (religionID == rProtestant4) or (religionID == rProtestant5) then
					Event_TomatekhHREsotericism.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_PROTESTANT_DESC"
				end
			elseif (Teams[pTeam]:GetCurrentEra() > eIndustrial) then
				Event_TomatekhHREsotericism.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NEW_AGE_DESC"
			end

			return true

		end
		)

	Event_TomatekhHREsotericism.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHREsotericism.Outcomes[1] = {}
	Event_TomatekhHREsotericism.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_1"
	Event_TomatekhHREsotericism.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_1_DESC"
	Event_TomatekhHREsotericism.Outcomes[1].Weight = 1
	Event_TomatekhHREsotericism.Outcomes[1].CanFunc = (
		function(pPlayer)			

            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
                religionID = JFD_GetStateReligion(pPlayer:GetID())
            end

			local pTeam = pPlayer:GetTeam();

			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then
				if (religionID == rProtestant1) or (religionID == rProtestant2) or (religionID == rProtestant3) or (religionID == rProtestant4) or (religionID == rProtestant5) then
					Event_TomatekhHREsotericism.Outcomes[1].Name = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_PROTESTANT_OUTCOME_1")
				else
					Event_TomatekhHREsotericism.Outcomes[1].Name = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_1")
				end
			elseif (Teams[pTeam]:GetCurrentEra() > eIndustrial) then
				Event_TomatekhHREsotericism.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NEW_AGE_OUTCOME_1"
			end

			Event_TomatekhHREsotericism.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_1_DESC")

			return true
		end
		)
	Event_TomatekhHREsotericism.Outcomes[1].DoFunc = (
		function(pPlayer) 

            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
                religionID = JFD_GetStateReligion(pPlayer:GetID())
            end

			save(pPlayer, "Event_TomatekhHREsotericism", true)
			save(pPlayer, "Event_TomatekhHREsotericism_One", true)

			local pTeam = pPlayer:GetTeam();

			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then
				if (religionID == rProtestant1) or (religionID == rProtestant2) or (religionID == rProtestant3) or (religionID == rProtestant4) or (religionID == rProtestant5) then
					JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_PROTESTANT_OUTCOME_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHREsotericism.Name))			
					local hPlayer = GetHumanPlayer();
					if hPlayer ~= 0 then
						if hPlayer ~= pPlayer then
							local pTeam = pPlayer:GetTeam();
							local hTeam = hPlayer:GetTeam();
							if Teams[pTeam]:IsHasMet(hTeam) then	
								Events.GameplayAlertMessage("A religious renewal movement has spread through " .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. "!")
							end
						end			
					end					
				else
					JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHREsotericism.Name))				
					local hPlayer = GetHumanPlayer();
					if hPlayer ~= 0 then
						if hPlayer ~= pPlayer then
							local pTeam = pPlayer:GetTeam();
							local hTeam = hPlayer:GetTeam();
							if Teams[pTeam]:IsHasMet(hTeam) then	
								Events.GameplayAlertMessage("" .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. " has developed a new mystic tradition.")
							end
						end	
					end
				end
			elseif (Teams[pTeam]:GetCurrentEra() > eIndustrial) then						
				JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NEW_AGE_OUTCOME_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHREsotericism.Name))				
				local hPlayer = GetHumanPlayer();
				if hPlayer ~= 0 then
					if hPlayer ~= pPlayer then
						local pTeam = pPlayer:GetTeam();
						local hTeam = hPlayer:GetTeam();
						if Teams[pTeam]:IsHasMet(hTeam) then	
							Events.GameplayAlertMessage("A New Age religious movement has started in " .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. ".")
						end
					end		
				end					
			end

			for pCity in pPlayer:Cities() do
				if not (pCity:IsHasBuilding(bHREsoteric)) then
					pCity:SetNumRealBuilding(bHREsoteric, 1);
				end
			end

		end
		)

	-- Outcome 2
	Event_TomatekhHREsotericism.Outcomes[2] = {}
	Event_TomatekhHREsotericism.Outcomes[2].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_2"
	Event_TomatekhHREsotericism.Outcomes[2].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_2_DESC"
	Event_TomatekhHREsotericism.Outcomes[2].Weight = 10
	Event_TomatekhHREsotericism.Outcomes[2].CanFunc = (
		function(pPlayer)			

            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
                religionID = JFD_GetStateReligion(pPlayer:GetID())
            end

			local pTeam = pPlayer:GetTeam();

			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then
				if (religionID == rProtestant1) or (religionID == rProtestant2) or (religionID == rProtestant3) or (religionID == rProtestant4) or (religionID == rProtestant5) then
					Event_TomatekhHREsotericism.Outcomes[2].Name = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_PROTESTANT_OUTCOME_2")
				else
					Event_TomatekhHREsotericism.Outcomes[2].Name = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_2")
				end
			elseif (Teams[pTeam]:GetCurrentEra() > eIndustrial) then
				Event_TomatekhHREsotericism.Outcomes[2].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NEW_AGE_OUTCOME_2"
			end

			Event_TomatekhHREsotericism.Outcomes[2].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_2_DESC")

			return true
		end
		)

	Event_TomatekhHREsotericism.Outcomes[2].DoFunc = (
		function(pPlayer) 
			
            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
                religionID = JFD_GetStateReligion(pPlayer:GetID())
            end

			save(pPlayer, "Event_TomatekhHREsotericism", true)

			local pTeam = pPlayer:GetTeam();

			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then
				if (religionID == rProtestant1) or (religionID == rProtestant2) or (religionID == rProtestant3) or (religionID == rProtestant4) or (religionID == rProtestant5) then
					JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_PROTESTANT_OUTCOME_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHREsotericism.Name))			
					local hPlayer = GetHumanPlayer();
					if hPlayer ~= pPlayer then
						local pTeam = pPlayer:GetTeam();
						local hTeam = hPlayer:GetTeam();
						if Teams[pTeam]:IsHasMet(hTeam) then	
							Events.GameplayAlertMessage("A religious renewal movement has spread through " .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. ".")
						end
					end											
				else
					JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_OUTCOME_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHREsotericism.Name))				
					local hPlayer = GetHumanPlayer();
					if hPlayer ~= pPlayer then
						local pTeam = pPlayer:GetTeam();
						local hTeam = hPlayer:GetTeam();
						if Teams[pTeam]:IsHasMet(hTeam) then	
							Events.GameplayAlertMessage("" .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. " has developed a new mystic tradition!")
						end
					end	
				end
			elseif (Teams[pTeam]:GetCurrentEra() > eIndustrial) then						
				JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ESOTERICISM_NEW_AGE_OUTCOME_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHREsotericism.Name))				
				local hPlayer = GetHumanPlayer();
				if hPlayer ~= 0 then
					if hPlayer ~= pPlayer then
						local pTeam = pPlayer:GetTeam();
						local hTeam = hPlayer:GetTeam();
						if Teams[pTeam]:IsHasMet(hTeam) then	
							Events.GameplayAlertMessage("A New Age religious movement has started in " .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. ".")
						end
					end		
				end					
			end								
								
			if not pPlayer:HasPolicy(pHREsoteric) then
				pPlayer:SetNumFreePolicies(1)
				pPlayer:SetNumFreePolicies(0)
				pPlayer:SetHasPolicy(pHREsoteric, true);
			end

		end
		)

tEvents.Event_TomatekhHREsotericism = Event_TomatekhHREsotericism

GameEvents.PlayerDoTurn.Add(
function(iPlayer)
	local pPlayer = Players[iPlayer];
	if (pPlayer:IsAlive()) then
		if load(pPlayer, "Event_TomatekhHREsotericism_One") == true then

			local EsotericFaith = 0;
			for pCity in pPlayer:Cities() do
				if not (pCity:IsHasBuilding(bHREsoteric)) then
					pCity:SetNumRealBuilding(bHREsoteric, 1);
				end
				local fPop = pCity:GetPopulation();
				if fPop >= 5 then
					local bFaith = math.floor(fPop / 5)
					EsotericFaith = EsotericFaith + bFaith;
				end
			end
			--Building_YieldChangesPerPop doesn't work with faith?
			pPlayer:ChangeFaith(EsotericFaith);

		end
	end
end)

--=========================================================
--Spiritualism
--=========================================================
local Event_TomatekhHRSpiritualism = {}
	Event_TomatekhHRSpiritualism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM"
	Event_TomatekhHRSpiritualism.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM_DESC"
	Event_TomatekhHRSpiritualism.EventImage = "HRSpiritualism.dds"
	Event_TomatekhHRSpiritualism.Weight = 2
	Event_TomatekhHRSpiritualism.CanFunc = (

		function(pPlayer)		
		
			if load(pPlayer, "Event_TomatekhHRSpiritualism") == true then return false end
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
                religionID = JFD_GetStateReligion(pPlayer:GetID())
            end
			if religionID <= 0 then return false end

			if (GetNumReligionsinEmpire(pPlayer) < 2) then return false end
			
			if not isBNW then return false end

			local pTeam = pPlayer:GetTeam();
			if not (Teams[pTeam]:GetCurrentEra() == eIndustrial) then return false end

			Event_TomatekhHRSpiritualism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM"

			return true

		end
		)

	Event_TomatekhHRSpiritualism.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHRSpiritualism.Outcomes[1] = {}
	Event_TomatekhHRSpiritualism.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM_OUTCOME_1"
	Event_TomatekhHRSpiritualism.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM_OUTCOME_1_DESC"
	Event_TomatekhHRSpiritualism.Outcomes[1].Weight = 10
	Event_TomatekhHRSpiritualism.Outcomes[1].CanFunc = (

		function(pPlayer)

			Event_TomatekhHRSpiritualism.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM_OUTCOME_1_DESC")

			return true
		end
		)
	Event_TomatekhHRSpiritualism.Outcomes[1].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRSpiritualism", true)

			if not pPlayer:HasPolicy(pHRSpiritualist) then
				pPlayer:SetNumFreePolicies(1)
				pPlayer:SetNumFreePolicies(0)
				pPlayer:SetHasPolicy(pHRSpiritualist, true);
			end

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_SPIRITUALISM_OUTCOME_1_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRSpiritualism.Name))

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("The " .. Locale.ConvertTextKey(pPlayer:GetCivilizationAdjective()) .. " are attempting to contact the spirit world!")
					end
				end	
			end

		end
		)

tEvents.Event_TomatekhHRSpiritualism = Event_TomatekhHRSpiritualism

--=========================================================
--Rosicrucian Enlightenment
--=========================================================

local Event_TomatekhHRRosyCross = {}
	Event_TomatekhHRRosyCross.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS"
	Event_TomatekhHRRosyCross.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_DESC"
	Event_TomatekhHRRosyCross.EventImage = "HRRosyCross.dds"
	Event_TomatekhHRRosyCross.Weight = 1
	Event_TomatekhHRRosyCross.CanFunc = (

		function(pPlayer)		
		
			if load(pPlayer, "Event_TomatekhHRRosyCross") == true then return false end
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

            local religionID = pPlayer:GetReligionCreatedByPlayer()
            if religionID <= 0 then 
				if (pPlayer:GetNumCities() >= 1) then
					religionID = pPlayer:GetCapitalCity():GetReligiousMajority() 
				end
			end
            if isUsingPietyPrestige then   
				religionID = JFD_GetStateReligion(pPlayer:GetID())
            end
			if religionID <= 0 then return false end

			if (GetNumReligionsinEmpire(pPlayer) < 2) then return false end
			
			if not isBNW then return false end

			local eRenID = GameInfoTypes.ERA_RENAISSANCE;
			local eIndID = GameInfoTypes.ERA_INDUSTRIAL;
			if isEEraExt then
				eIndID = GameInfoTypes.ERA_ENLIGHTENMENT;
			end

			local pTeam = pPlayer:GetTeam();
			if (Teams[pTeam]:GetCurrentEra() < eRenID) or (Teams[pTeam]:GetCurrentEra() > eIndID) then return false end

			Event_TomatekhHRRosyCross.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS"

			return true

		end
		)

	Event_TomatekhHRRosyCross.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHRRosyCross.Outcomes[1] = {}
	Event_TomatekhHRRosyCross.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_1"
	Event_TomatekhHRRosyCross.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_1_DESC"
	Event_TomatekhHRRosyCross.Outcomes[1].Weight = 1
	Event_TomatekhHRRosyCross.Outcomes[1].CanFunc = (

		function(pPlayer)

			local Award = 0;
			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			if Faith >= Proph then
				Award = Proph;
			elseif Faith < Proph then
				Award = (Proph - Faith);
			end
			Award = math.ceil(Award);

			Event_TomatekhHRRosyCross.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_1_DESC", Award)

			return true
		end
		)
	Event_TomatekhHRRosyCross.Outcomes[1].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRRosyCross", true)

			local Award = 0;
			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			if Faith >= Proph then
				Award = Proph;
			elseif Faith < Proph then
				Award = (Proph - Faith);
			end
			Award = math.ceil(Award);

			pPlayer:ChangeFaith(Award);

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_1_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRRosyCross.Name))

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("Rosicrucianism has provided " .. Locale.ConvertTextKey(pPlayer:GetCivilizationAdjective()) .. " citizens with new insights into their faith.")
					end
				end	
			end

		end
		)

	-- Outcome 2
	Event_TomatekhHRRosyCross.Outcomes[2] = {}
	Event_TomatekhHRRosyCross.Outcomes[2].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_2"
	Event_TomatekhHRRosyCross.Outcomes[2].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_2_DESC"
	Event_TomatekhHRRosyCross.Outcomes[2].Weight = 10
	Event_TomatekhHRRosyCross.Outcomes[2].CanFunc = (

		function(pPlayer)

			local Award = 0;
			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			if Faith >= Proph then
				Award = Proph;
			elseif Faith < Proph then
				Award = (Proph - Faith);
			end
			Award = math.ceil(Award / 2);

			Event_TomatekhHRRosyCross.Outcomes[2].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_2_DESC", Award)

			return true
		end
		)
	Event_TomatekhHRRosyCross.Outcomes[2].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRRosyCross", true)

			local Award = 0;
			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			if Faith >= Proph then
				Award = Proph;
			elseif Faith < Proph then
				Award = (Proph - Faith);
			end
			Award = math.ceil(Award / 2);

			local pTeamTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs()
			pTeamTechs:ChangeResearchProgress(pPlayer:GetCurrentResearch(), Award, pPlayer:GetID())

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ROSY_CROSS_OUTCOME_2_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRRosyCross.Name))

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("Rosicrucianism has inspired " .. Locale.ConvertTextKey(pPlayer:GetCivilizationAdjective()) .. " citizens to form an Invisible College.")
					end
				end	
			end

		end
		)

tEvents.Event_TomatekhHRRosyCross = Event_TomatekhHRRosyCross

--=========================================================
--Revelation
--=========================================================
local Event_TomatekhHRDivineRevelation = {}
	Event_TomatekhHRDivineRevelation.Name = "TXT_KEY_EVENT_TOMATEKH_HR_REVELATION"
	Event_TomatekhHRDivineRevelation.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_REVELATION_DESC"
	Event_TomatekhHRDivineRevelation.EventImage = "HRDivineInsp.dds"
	Event_TomatekhHRDivineRevelation.Weight = 1
	Event_TomatekhHRDivineRevelation.CanFunc = (

		function(pPlayer)		
		
			if load(pPlayer, "Event_TomatekhHRDivineRevelation") == true then return false end
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

            if pPlayer:HasCreatedReligion() then return false end 
			if (Game.GetNumReligionsStillToFound() <= 0) then return false end 

			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			if Faith >= Proph then return false end 

			if not isBNW then return false end

			Event_TomatekhHRDivineRevelation.Name = "TXT_KEY_EVENT_TOMATEKH_HR_REVELATION"

			return true

		end
		)

	Event_TomatekhHRDivineRevelation.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHRDivineRevelation.Outcomes[1] = {}
	Event_TomatekhHRDivineRevelation.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_REVELATION_OUTCOME_1"
	Event_TomatekhHRDivineRevelation.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_REVELATION_OUTCOME_1_DESC"
	Event_TomatekhHRDivineRevelation.Outcomes[1].Weight = 10
	Event_TomatekhHRDivineRevelation.Outcomes[1].CanFunc = (

		function(pPlayer)

			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			local Award = (Proph - Faith);
			Award = math.ceil(Award / 3);
			if Award <= 1 then
				Award = 1;
			end

			Event_TomatekhHRDivineRevelation.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_REVELATION_OUTCOME_1_DESC", Award)

			return true
		end
		)
	Event_TomatekhHRDivineRevelation.Outcomes[1].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRDivineRevelation", true)

			local Proph = pPlayer:GetMinimumFaithNextGreatProphet();
			local Faith = pPlayer:GetFaith();
			local Award = (Proph - Faith);
			Award = math.ceil(Award / 3);
			if Award <= 1 then
				Award = 1;
			end

			pPlayer:ChangeFaith(Award);

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_REVELATION_OUTCOME_1_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRDivineRevelation.Name))

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("Rumors of divine revelation are circulating " .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. "!")
					end
				end	
			end

		end
		)

tEvents.Event_TomatekhHRDivineRevelation = Event_TomatekhHRDivineRevelation

--=========================================================
--Atheism
--=========================================================

local Event_TomatekhHRAtheism = {}
	Event_TomatekhHRAtheism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM"
	Event_TomatekhHRAtheism.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM_DESC"
	Event_TomatekhHRAtheism.EventImage = "HRAtheism.dds"
	Event_TomatekhHRAtheism.Weight = 2
	Event_TomatekhHRAtheism.CanFunc = (

		function(pPlayer)		
		
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

			local pTeam = pPlayer:GetTeam();
			if (Teams[pTeam]:GetCurrentEra() <= eIndustrial) then return false end

			if (GetNumReligionsinEmpire(pPlayer) < 1) then return false end

			if not isBNW then return false end

			Event_TomatekhHRAtheism.Name = "TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM"

			return true

		end
		)

	Event_TomatekhHRAtheism.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHRAtheism.Outcomes[1] = {}
	Event_TomatekhHRAtheism.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM_OUTCOME_1"
	Event_TomatekhHRAtheism.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM_OUTCOME_1_DESC"
	Event_TomatekhHRAtheism.Outcomes[1].Weight = 10
	Event_TomatekhHRAtheism.Outcomes[1].CanFunc = (

		function(pPlayer)

			Event_TomatekhHRAtheism.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM_OUTCOME_1_DESC")

			return true
		end
		)
	Event_TomatekhHRAtheism.Outcomes[1].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRAtheism", true)

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_ATHEISM_OUTCOME_1_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRAtheism.Name))

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("The " .. Locale.ConvertTextKey(pPlayer:GetCivilizationAdjective()) .. " have begun to question the existence of God.")
					end
				end	
			end

		end
		)

tEvents.Event_TomatekhHRAtheism = Event_TomatekhHRAtheism

--=========================================================
--Rapture
--=========================================================

local Event_TomatekhHRRapture = {}
	Event_TomatekhHRRapture.Name = "TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE"
	Event_TomatekhHRRapture.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE_DESC"
	Event_TomatekhHRRapture.EventImage = "HRRapture.dds"
	Event_TomatekhHRRapture.Weight = 1
	Event_TomatekhHRRapture.CanFunc = (

		function(pPlayer)		
		
			if load(pPlayer, "Event_TomatekhHRRapture") == true then return false end
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

			local pTeam = pPlayer:GetTeam();
			if (Teams[pTeam]:GetCurrentEra() <= eModern) then return false end

			if (GetNumReligionsinEmpire(pPlayer) < 1) then return false end

			if pPlayer:GetNumCities() <= 0 then return false end

			if pPlayer:GetNumCities() >= 1 then
				local pcCity = pPlayer:GetCapitalCity();
				local pcPop = pcCity:GetPopulation();
				if pcPop <= 3 then return false end
			end

			if not isBNW then return false end

			Event_TomatekhHRRapture.Name = "TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE"

			return true

		end
		)

	Event_TomatekhHRRapture.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHRRapture.Outcomes[1] = {}
	Event_TomatekhHRRapture.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE_OUTCOME_1"
	Event_TomatekhHRRapture.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE_OUTCOME_1_DESC"
	Event_TomatekhHRRapture.Outcomes[1].Weight = 10
	Event_TomatekhHRRapture.Outcomes[1].CanFunc = (

		function(pPlayer)

			Event_TomatekhHRRapture.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE_OUTCOME_1_DESC")

			return true
		end
		)
	Event_TomatekhHRRapture.Outcomes[1].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRRapture", true)

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_RAPTURE_OUTCOME_1_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRRapture.Name))

			for pCity in pPlayer:Cities() do
				local RandomHR = GetRandomHR(1, 3)
				if pCity:GetPopulation() > RandomHR then
					pCity:ChangePopulation(-RandomHR, true);
				end
			end

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("" .. Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescription()) .. " was left behind...")
					end
				end	
			end

		end
		)

tEvents.Event_TomatekhHRRapture = Event_TomatekhHRRapture

--=========================================================
--Millenarianism
--=========================================================

local Event_TomatekhHRDoomCult = {}
	Event_TomatekhHRDoomCult.Name = "TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT"
	Event_TomatekhHRDoomCult.Desc = "TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT_DESC"
	Event_TomatekhHRDoomCult.EventImage = "HRDoomCult.dds"
	Event_TomatekhHRDoomCult.Weight = 3
	Event_TomatekhHRDoomCult.CanFunc = (

		function(pPlayer)		
		
			Event_TomatekhHRDoomCult.Name = "TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT"

			if load(pPlayer, "Event_TomatekhHRDoomCult") == true then return false end
			if load(pPlayer, "Event_TomatekhHRAtheism") == true then return false end

			if (pPlayer:GetCivilizationType() == GameInfoTypes.CIVILIZATION_MAYA) then return false end

			local Turn = 0
			if (Game.GetGameTurnYear() >= 250) and (Game.GetGameTurnYear() < 1000) then
				Turn = 1;
			end
			if (Game.GetGameTurnYear() >= 1250) and (Game.GetGameTurnYear() < 2000) then
				Turn = 1;
				Event_TomatekhHRDoomCult.EventImage = "HRDoomCult2.dds"
			end
			if (Turn == 0) then return false end
			
			if not isBNW then return false end

			return true

		end
		)

	Event_TomatekhHRDoomCult.Outcomes = {}

	-- Outcome 1
	Event_TomatekhHRDoomCult.Outcomes[1] = {}
	Event_TomatekhHRDoomCult.Outcomes[1].Name = "TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT_OUTCOME_1"
	Event_TomatekhHRDoomCult.Outcomes[1].Desc = "TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT_OUTCOME_1_DESC"
	Event_TomatekhHRDoomCult.Outcomes[1].Weight = 10
	Event_TomatekhHRDoomCult.Outcomes[1].CanFunc = (

		function(pPlayer)

			local Date = 2000
			if (Game.GetGameTurnYear() >= 250) and (Game.GetGameTurnYear() < 1000) then
				Date = 1000;
			end
			if (Game.GetGameTurnYear() >= 1250) and (Game.GetGameTurnYear() < 2000) then
				Date = 2000;
			end

			Event_TomatekhHRDoomCult.Outcomes[1].Desc = Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT_OUTCOME_1_DESC", Date)

			return true
		end
		)
	Event_TomatekhHRDoomCult.Outcomes[1].DoFunc = (
		function(pPlayer)

			save(pPlayer, "Event_TomatekhHRDoomCult", true)

			JFD_SendNotification(pPlayer:GetID(), "NOTIFICATION_GENERIC", Locale.ConvertTextKey("TXT_KEY_EVENT_TOMATEKH_HR_DOOM_CULT_OUTCOME_1_NOTIFICATION"), Locale.ConvertTextKey(Event_TomatekhHRDoomCult.Name))

			if (Game.GetGameTurnYear() >= 250) and (Game.GetGameTurnYear() < 1000) then
				save(pPlayer, "HR Millenarianism 1000", true)
			end
			if (Game.GetGameTurnYear() >= 1250) and (Game.GetGameTurnYear() < 2000) then
				save(pPlayer, "HR Millenarianism 2000", true)
			end

			local RandomHR = GetRandomHR(1, 2)
			if RandomHR == 1 then
				save(pPlayer, "HR Millenarianism Bad", true)
			elseif RandomHR == 2 then
				save(pPlayer, "HR Millenarianism Good", true)
			end

			local hPlayer = GetHumanPlayer();
			if hPlayer ~= 0 then
				if hPlayer ~= pPlayer then
					local pTeam = pPlayer:GetTeam();
					local hTeam = hPlayer:GetTeam();
					if Teams[pTeam]:IsHasMet(hTeam) then	
						Events.GameplayAlertMessage("" .. Locale.ConvertTextKey(pPlayer:GetCivilizationAdjective()) .. " citizens are convinced the world is going to end!")
					end
				end	
			end

		end
		)

tEvents.Event_TomatekhHRDoomCult = Event_TomatekhHRDoomCult

local speed = Game.GetGameSpeedType();
local MinorAnarchy = 0;
local MinorGA = 0;
if speed == GameInfo.GameSpeeds['GAMESPEED_QUICK'].ID then
	MinorAnarchy = 1;
	MinorGA = 3;
elseif speed == GameInfo.GameSpeeds['GAMESPEED_STANDARD'].ID then
	MinorAnarchy = 1;
	MinorGA = 4;
elseif speed == GameInfo.GameSpeeds['GAMESPEED_EPIC'].ID then
	MinorAnarchy = 1;
	MinorGA = 5;
elseif speed == GameInfo.GameSpeeds['GAMESPEED_MARATHON'].ID then
	MinorAnarchy = 2;
	MinorGA = 8;
else
	MinorAnarchy = 2;
	MinorGA = 8;
end

function HREndofWorld(playerID)
	local pPlayer = Players[playerID]
	if (load(pPlayer, "HR Millenarianism 1000") == true) then
		if (Game.GetGameTurnYear() >= 1000) then
			save(pPlayer, "HR Millenarianism 1000", false)
			if (load(pPlayer, "HR Millenarianism Bad") == true) then
				save(pPlayer, "HR Millenarianism Bad", false)
				if pPlayer:IsAnarchy() then
					pPlayer:ChangeAnarchyNumTurns(MinorAnarchy);
				else
					pPlayer:SetAnarchyNumTurns(MinorAnarchy);
				end
				if (pPlayer:IsHuman()) and (playerID == Game.GetActivePlayer()) then
					Events.GameplayAlertMessage("[COLOR_NEGATIVE_TEXT]An unprecedented solar eclipse has incited your citizens to riot in the streets![ENDCOLOR]");
				end
			end
			if (load(pPlayer, "HR Millenarianism Good") == true) then
				save(pPlayer, "HR Millenarianism Good", false)
				local gAge = pPlayer:GetNumGoldenAges()
				pPlayer:ChangeGoldenAgeTurns(MinorGA)
				pPlayer:SetNumGoldenAges(gAge)
				if (pPlayer:IsHuman()) and (playerID == Game.GetActivePlayer()) then
					Events.GameplayAlertMessage("[COLOR_POSITIVE_TEXT]Looks like the world didn't end after all...[ENDCOLOR]");
				end
			end
		end
	end
	if (load(pPlayer, "HR Millenarianism 2000") == true) then
		if (Game.GetGameTurnYear() >= 2000) then
			save(pPlayer, "HR Millenarianism 1000", false)
			if (load(pPlayer, "HR Millenarianism Bad") == true) then
				save(pPlayer, "HR Millenarianism Bad", false)
				if pPlayer:IsAnarchy() then
					pPlayer:ChangeAnarchyNumTurns(MinorAnarchy);
				else
					pPlayer:SetAnarchyNumTurns(MinorAnarchy);
				end
				if (pPlayer:IsHuman()) and (playerID == Game.GetActivePlayer()) then
					Events.GameplayAlertMessage("[COLOR_NEGATIVE_TEXT]Y2K will kill us all![ENDCOLOR]");
				end
			end
			if (load(pPlayer, "HR Millenarianism Good") == true) then
				save(pPlayer, "HR Millenarianism Good", false)
				local gAge = pPlayer:GetNumGoldenAges()
				pPlayer:ChangeGoldenAgeTurns(MinorGA)
				pPlayer:SetNumGoldenAges(gAge)
				if (pPlayer:IsHuman()) and (playerID == Game.GetActivePlayer()) then
					Events.GameplayAlertMessage("[COLOR_POSITIVE_TEXT]Looks like the world didn't end after all...[ENDCOLOR]");
				end
			end
		end
	end
end

GameEvents.PlayerDoTurn.Add(HREndofWorld)
