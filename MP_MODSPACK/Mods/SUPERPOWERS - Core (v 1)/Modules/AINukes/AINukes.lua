--------------------------------------------------------------------------------
-- AINukeGift.lua
-- Gives AI civs nuclear units once they have completed the Manhattan Project.
--   * Unit type depends on techs (best available wins)
--   * Only gifted while the AI is below a city-based nuke threshold
--   * Requires the AI to own Uranium
--   * Runs once every 20 turns per AI (staggered by player ID to spread load)
-- Multiplayer safe: gameplay events only, no UI calls, no math.random,
-- only synced Game.Rand, deterministic player iteration, no persistent state.
--------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------
local TURN_INTERVAL      = 15   -- run once every N turns per AI
local STAGGER_BY_PLAYER  = true -- spread AIs across different turns (perf)
local CITIES_PER_NUKE    = 4    -- threshold = floor(cities / CITIES_PER_NUKE)
local MIN_THRESHOLD      = 1    -- an AI with at least 1 city can hold 1 nuke
local MAX_THRESHOLD      = 8    -- hard cap on nukes held at once
local MAX_GIFT_PER_RUN   = 2    -- never give more than this in a single run

-- ---------------------------------------------------------------------------
-- Cached lookups (done once at load, not every turn)
-- ---------------------------------------------------------------------------
local PROJECT_MANHATTAN = GameInfoTypes.PROJECT_MANHATTAN_PROJECT
local RESOURCE_URANIUM  = GameInfoTypes.RESOURCE_URANIUM

-- Ordered best -> worst. First entry whose tech the AI has is the one given.
-- Entries whose unit or tech doesn't exist in this ruleset are skipped.
local NUKE_TIERS = {}
local function AddTier(unitType, techType)
	local unitID = GameInfoTypes[unitType]
	local techID = GameInfoTypes[techType]
	if unitID ~= nil and techID ~= nil then
		table.insert(NUKE_TIERS, { unit = unitID, tech = techID })
	end
end
AddTier("UNIT_ICBM_MISSILE",    "TECH_INTEGRATED_DEFENSE")
AddTier("UNIT_NUCLEAR_MISSILE", "TECH_ADVANCED_BALLISTICS")
AddTier("UNIT_ATOMIC_BOMB",     "TECH_NUCLEAR_FISSION")

-- Set of every nuke unit ID, used when counting what an AI already owns.
local NUKE_UNIT_SET = {}
for _, tier in ipairs(NUKE_TIERS) do
	NUKE_UNIT_SET[tier.unit] = true
end

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS

-- Bail out entirely if the ruleset is missing what we need.
if PROJECT_MANHATTAN == nil or RESOURCE_URANIUM == nil or #NUKE_TIERS == 0 then
	print("AINukeGift: required project/resource/units not found, script disabled.")
	return
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function GetBestNukeUnit(pTeamTechs)
	for i = 1, #NUKE_TIERS do
		local tier = NUKE_TIERS[i]
		if pTeamTechs:HasTech(tier.tech) then
			return tier.unit
		end
	end
	return nil
end

local function CountNukes(pPlayer)
	local count = 0
	for pUnit in pPlayer:Units() do
		if NUKE_UNIT_SET[pUnit:GetUnitType()] then
			count = count + 1
		end
	end
	return count
end

local function GetThreshold(pPlayer)
	local threshold = math.floor(pPlayer:GetNumCities() / CITIES_PER_NUKE)
	if threshold < MIN_THRESHOLD then threshold = MIN_THRESHOLD end
	if threshold > MAX_THRESHOLD then threshold = MAX_THRESHOLD end
	return threshold
end

-- Deterministic list of the player's cities (needed for a synced random pick).
local function GetCityList(pPlayer)
	local cities = {}
	for pCity in pPlayer:Cities() do
		cities[#cities + 1] = pCity
	end
	return cities
end

-- ---------------------------------------------------------------------------
-- Main
-- ---------------------------------------------------------------------------
local function OnPlayerDoTurn(iPlayer)
	-- Cheapest checks first.
	if iPlayer >= MAX_MAJOR then return end

	local iTurn = Game.GetGameTurn()
	local offset = STAGGER_BY_PLAYER and iPlayer or 0
	if (iTurn + offset) % TURN_INTERVAL ~= 0 then return end

	local pPlayer = Players[iPlayer]
	if pPlayer == nil or not pPlayer:IsAlive() or pPlayer:IsHuman() then return end
	if pPlayer:GetNumCities() <= 0 then return end

	-- 1. Manhattan Project completed by this AI's team
	local pTeam = Teams[pPlayer:GetTeam()]
	if pTeam:GetProjectCount(PROJECT_MANHATTAN) <= 0 then return end

	-- 2. Which nuke (if any) does their tech allow?
	local unitID = GetBestNukeUnit(pTeam:GetTeamTechs())
	if unitID == nil then return end

	-- 3. Must have Uranium (owned or imported)
	if pPlayer:GetNumResourceTotal(RESOURCE_URANIUM, true) <= 0 then return end

	-- 4. Below the city-based threshold?
	local deficit = GetThreshold(pPlayer) - CountNukes(pPlayer)
	if deficit <= 0 then return end
	if deficit > MAX_GIFT_PER_RUN then deficit = MAX_GIFT_PER_RUN end

	-- 5. Spawn in cities (synced RNG picks the city so all clients agree)
	local cities = GetCityList(pPlayer)
	if #cities == 0 then return end

	for _ = 1, deficit do
		local pCity = cities[Game.Rand(#cities, "AINukeGift city pick") + 1]
		pPlayer:InitUnit(unitID, pCity:GetX(), pCity:GetY())
	end
end

GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)
print("AINukeGift: loaded.")