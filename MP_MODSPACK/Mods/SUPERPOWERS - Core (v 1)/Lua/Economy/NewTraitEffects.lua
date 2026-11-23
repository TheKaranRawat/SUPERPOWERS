-- New Trait and Policies (multiplayer-safe, cached lookups)
-- Must run in the gameplay (GameEvents) context so it executes identically on all clients.

----------------------------------------------------------------------
-- Cached lookups (once at load)
----------------------------------------------------------------------
local CIV_JAPAN   = GameInfoTypes["CIVILIZATION_JAPAN"]
local CIV_HUNS    = GameInfoTypes["CIVILIZATION_HUNS"]
local CIV_ASSYRIA = GameInfoTypes["CIVILIZATION_ASSYRIA"]
local PROMO_QUICK = GameInfoTypes["PROMOTION_GAME_QUICKSPEED"]
local SPEED_QUICK = GameInfoTypes["GAMESPEED_QUICK"] or 3

local HUN_PER_TURN = 10
local HUN_MAX      = 1000

local function Notify(pPlayer, textKey, heading, x, y, ...)
	if pPlayer == nil or not pPlayer:IsHuman() then return end
	local text = Locale.ConvertTextKey(textKey, ...)
	pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, heading or text, x or -1, y or -1)
end

----------------------------------------------------------------------
-- Quick game speed promotion (only registered when it can matter)
----------------------------------------------------------------------
if PROMO_QUICK ~= nil and Game.GetGameSpeedType() == SPEED_QUICK then
	local function SpecialUnitType(iPlayerID, iUnitID)
		local pPlayer = Players[iPlayerID]
		if pPlayer == nil then return end
		local pUnit = pPlayer:GetUnitByID(iUnitID)
		if pUnit == nil then return end
		pUnit:SetHasPromotion(PROMO_QUICK, true)
	end
	GameEvents.UnitCreated.Add(SpecialUnitType)
end

----------------------------------------------------------------------
-- Japan: culture from building combat units
----------------------------------------------------------------------
local function JapanCultureUnit(iPlayerID, iCityID, iUnitID)
	local pPlayer = Players[iPlayerID]
	if pPlayer == nil or pPlayer:GetCivilizationType() ~= CIV_JAPAN then return end

	local pUnit = pPlayer:GetUnitByID(iUnitID)
	if pUnit == nil or not pUnit:IsCombatUnit() then return end

	local bonusCulture = math.ceil(pUnit:GetBaseCombatStrength())
	if bonusCulture <= 0 then return end

	pPlayer:ChangeJONSCulture(bonusCulture)
	Notify(pPlayer, "TXT_KEY_SP_TRAIT_CULTURE_FROM_UNIT", nil, -1, -1, tostring(bonusCulture), pUnit:GetName())
end
GameEvents.CityTrained.Add(JapanCultureUnit)

----------------------------------------------------------------------
-- Huns: yields for razing cities
-- SerialEventCityDestroyed is UI-only, so instead detect cities the Hun
-- player owns that have started razing, once per city.
----------------------------------------------------------------------
local razeRewarded = {}   -- [playerID] = { [cityID] = true }

local function HunRazeRewards(iPlayerID)
	local pPlayer = Players[iPlayerID]
	if pPlayer == nil or pPlayer:GetCivilizationType() ~= CIV_HUNS or not pPlayer:IsAlive() then return end

	local old  = razeRewarded[iPlayerID] or {}
	local seen = {}
	local newRazes = 0

	for pCity in pPlayer:Cities() do
		if pCity:IsRazing() then
			local id = pCity:GetID()
			seen[id] = true
			if not old[id] then newRazes = newRazes + 1 end
		end
	end
	razeRewarded[iPlayerID] = seen
	if newRazes == 0 then return end

	local output = math.min(HUN_PER_TURN * Game.GetGameTurn(), HUN_MAX) * newRazes

	pPlayer:ChangeJONSCulture(output)
	pPlayer:ChangeGold(output)
	pPlayer:ChangeFaith(output)

	local iTech = pPlayer:GetCurrentResearch()
	if iTech ~= nil and iTech >= 0 then
		local pTeamTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs()
		if pTeamTechs ~= nil then
			pTeamTechs:ChangeResearchProgress(iTech, output, iPlayerID)
		end
	end

	Notify(pPlayer, "TXT_KEY_SP_NOTIFICATION_TRAIT_OUTPUT_FROM_RAZING", nil, -1, -1, tostring(output))
end
GameEvents.PlayerDoTurn.Add(HunRazeRewards)

----------------------------------------------------------------------
-- Assyria: +1 population in capital after capturing a city (pop > 4)
----------------------------------------------------------------------
local function AssyriaCityCapture(iOldPlayer, bCapital, iX, iY, iNewPlayer)
	local pNewPlayer = Players[iNewPlayer]
	if pNewPlayer == nil or pNewPlayer:GetCivilizationType() ~= CIV_ASSYRIA then return end

	local pPlot = Map.GetPlot(iX, iY)
	if pPlot == nil then return end
	local pCity = pPlot:GetPlotCity()
	if pCity == nil or pCity:GetPopulation() <= 4 then return end

	local pCapital = pNewPlayer:GetCapitalCity()
	if pCapital == nil then return end

	pCapital:ChangePopulation(1, true)
	Notify(pNewPlayer, "TXT_KEY_SP_NOTIFICATION_ASSYRIA_POPULATION",
		Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ASSYRIA_POPULATION_SHORT"),
		pCapital:GetX(), pCapital:GetY(), pCapital:GetName())
end
GameEvents.CityCaptureComplete.Add(AssyriaCityCapture)