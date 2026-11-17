--==========================================================================
-- AutoImprovements.lua  -  simple, multiplayer-safe worker-less improving
-- (Civilization V, BNW / Gods & Kings)
--
-- Every BUILD_INTERVAL turns (staggered per city) each city places
--   BASE_PER_TURN (+1 per researched BONUS_TECH) improvements on tiles the
-- player owns within BUILD_RANGE tiles of the city.
--
-- Priority:  1) strategic resources   2) luxury resources   3) everything else
-- (inside a priority, tiles are taken in a fixed scan order: nearest first).
--
-- Pillaged improvements are repaired slowly (REPAIR_*), clearing fallout.
--
-- MULTIPLAYER SAFETY
--   * Runs only from GameEvents.PlayerDoTurn (fires on every machine).
--   * Deterministic: no randomness, no clocks, no UI, no "active player"
--     queries; only explicit player/team queries on real game state.
--   * Stateless: schedules come from (game turn + city ID), so reloads and
--     late joins cannot put machines out of step.
--   * Fixed iteration order everywhere (engine city order, fixed tile scan).
--==========================================================================

local CONFIG = {
	BASE_PER_TURN = 1,
	BONUS_TECHS = {
		"TECH_INDUSTRIALIZATION",      -- +1 improvement per build turn
	},

	BUILD_INTERVAL = 3,                -- a city builds every N turns (1 = every turn)
	BUILD_RANGE    = 5,                -- tiles from the city

	APPLY_TO_HUMANS      = true,
	APPLY_TO_AI          = true,
	APPLY_TO_CITY_STATES = true,

	SKIP_OCCUPIED_BY_ENEMY = true,     -- don't build/repair under at-war units

	-- Slow repair of pillaged improvements
	REPAIR_PILLAGED  = true,
	REPAIR_INTERVAL  = 4,              -- each city, every N turns
	REPAIRS_PER_CITY = 1,
	REMOVE_FALLOUT   = true,

	-- Which improvement goes on a plain tile when several are possible:
	-- listed ones first (in this order), unlisted next, last-resort ones last.
	PREFERRED_IMPROVEMENTS = {
		"IMPROVEMENT_FARM",
		"IMPROVEMENT_MINE",
		"IMPROVEMENT_LUMBERMILL",
	},
	LAST_RESORT_IMPROVEMENTS = {
		"IMPROVEMENT_TRADING_POST",
	},

	-- Never auto-built (unit-consuming builds are excluded automatically)
	EXCLUDED_IMPROVEMENTS = {
		"IMPROVEMENT_FORT",
		"IMPROVEMENT_CITADEL",
	},

	DEBUG = false,
}

--------------------------------------------------------------------------
-- LOAD-TIME CACHES (same database on every client)
--------------------------------------------------------------------------
local NO_IMPROVEMENT = -1   -- Civ 5 has no NO_* globals for these
local NO_FEATURE     = -1

local function dprint(...)
	if CONFIG.DEBUG then print("[AutoImprovements]", ...) end
end

local BUILD_INTERVAL   = math.max(1, math.floor(CONFIG.BUILD_INTERVAL))
local BUILD_RANGE      = math.max(1, math.floor(CONFIG.BUILD_RANGE))
local REPAIR_INTERVAL  = math.max(1, math.floor(CONFIG.REPAIR_INTERVAL))
local REPAIRS_PER_CITY = math.max(1, math.floor(CONFIG.REPAIRS_PER_CITY))
local SKIP_ENEMY       = CONFIG.SKIP_OCCUPIED_BY_ENEMY
local FALLOUT_ID       = GameInfoTypes["FEATURE_FALLOUT"]

-- Type names -> ordered list of IDs (unknown names are skipped)
local function ToIDList(names)
	local list = {}
	for _, name in ipairs(names) do
		local id = GameInfoTypes[name]
		if id then list[#list + 1] = id end
	end
	return list
end

local bonusTechIDs = ToIDList(CONFIG.BONUS_TECHS)

local excluded = {}
for _, id in ipairs(ToIDList(CONFIG.EXCLUDED_IMPROVEMENTS)) do excluded[id] = true end

-- Improvement sort rank: lower = chosen first on a plain tile
local DEFAULT_RANK, LAST_RANK = 500, 1000
local rank = {}
for i, id in ipairs(ToIDList(CONFIG.PREFERRED_IMPROVEMENTS)) do rank[id] = i end
for _, id in ipairs(ToIDList(CONFIG.LAST_RESORT_IMPROVEMENTS)) do rank[id] = LAST_RANK end

-- Resource -> improvements that connect it
local improvementConnects = {}   -- [improvementID][resourceID] = true
for row in GameInfo.Improvement_ResourceTypes() do
	local impID, resID = GameInfoTypes[row.ImprovementType], GameInfoTypes[row.ResourceType]
	if impID and resID then
		improvementConnects[impID] = improvementConnects[impID] or {}
		improvementConnects[impID][resID] = true
	end
end

-- Unique improvements: [improvementID] = owning civilizationID
local improvementCiv = {}
for row in GameInfo.Improvements() do
	if row.CivilizationType then
		local civID = GameInfoTypes[row.CivilizationType]
		if civID then improvementCiv[row.ID] = civID end
	end
end

-- All improvement builds, best-ranked first (deterministic order)
local improvementBuilds = {}
for row in GameInfo.Builds() do
	local impID = row.ImprovementType and GameInfoTypes[row.ImprovementType]
	if impID and not row.Kill and not excluded[impID] then
		improvementBuilds[#improvementBuilds + 1] = {
			build       = row.ID,
			improvement = impID,
			tech        = row.PrereqTech and GameInfoTypes[row.PrereqTech] or nil,
			rank        = rank[impID] or DEFAULT_RANK,
		}
	end
end
table.sort(improvementBuilds, function(a, b)
	if a.rank ~= b.rank then return a.rank < b.rank end
	return a.build < b.build
end)

-- Improvements this script could have placed (only these may be replaced)
local buildable = {}
for i = 1, #improvementBuilds do buildable[improvementBuilds[i].improvement] = true end

-- Builds that connect each resource: [resourceID] = ordered build list
local connectBuilds = {}
for i = 1, #improvementBuilds do
	local b = improvementBuilds[i]
	local ic = improvementConnects[b.improvement]
	if ic then
		for resID in pairs(ic) do   -- order irrelevant: each list is filled in build order
			connectBuilds[resID] = connectBuilds[resID] or {}
			local list = connectBuilds[resID]
			list[#list + 1] = b
		end
	end
end

-- Resource priority tier: 1 = strategic, 2 = luxury, 3 = everything else
local resourceTier = {}
for row in GameInfo.Resources() do
	local class, usage = row.ResourceClassType, row.ResourceUsage
	if usage == 1 or class == "RESOURCECLASS_RUSH" or class == "RESOURCECLASS_MODERN" then
		resourceTier[row.ID] = 1
	elseif usage == 2 or class == "RESOURCECLASS_LUXURY" then
		resourceTier[row.ID] = 2
	else
		resourceTier[row.ID] = 3
	end
end

local scratchPlots = {}   -- owned tiles within range of the city being processed

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function GetActionsPerTurn(iTeam)
	local team = Teams[iTeam]
	local count = CONFIG.BASE_PER_TURN
	for i = 1, #bonusTechIDs do
		if team:IsHasTech(bonusTechIDs[i]) then count = count + 1 end
	end
	return count
end

local function PlayerQualifies(pPlayer)
	if not pPlayer or not pPlayer:IsAlive() then return false end
	if pPlayer:IsBarbarian() then return false end
	if pPlayer:IsMinorCiv() then return CONFIG.APPLY_TO_CITY_STATES end
	if pPlayer:IsHuman() then return CONFIG.APPLY_TO_HUMANS end
	return CONFIG.APPLY_TO_AI
end

-- Builds this player can use right now: ordered list, count, and a set
local function GetAvailableBuilds(iTeam, iCiv)
	local team = Teams[iTeam]
	local list, n, set = {}, 0, {}
	for i = 1, #improvementBuilds do
		local b = improvementBuilds[i]
		local owner = improvementCiv[b.improvement]
		if (owner == nil or owner == iCiv)                 -- unique improvements: owner only
			and (b.tech == nil or team:IsHasTech(b.tech)) then
			n = n + 1
			list[n] = b
			set[b.build] = true
		end
	end
	return list, n, set
end

local function BlockedByEnemy(pPlot, iTeam)
	local numUnits = pPlot:GetNumUnits()
	if numUnits == 0 then return false end
	local team = Teams[iTeam]
	for i = 0, numUnits - 1 do
		local pUnit = pPlot:GetUnit(i)
		if pUnit and team:IsAtWar(pUnit:GetTeam()) then return true end
	end
	return false
end

-- Outer ring (beyond the engine's city tile list). Called through pcall so a
-- missing engine function can only disable the extra range, not the script.
local function CollectOuterPlots(pCity, iPlayer, inner, n)
	local cx, cy = pCity:GetX(), pCity:GetY()
	for dx = -BUILD_RANGE, BUILD_RANGE do
		for dy = -BUILD_RANGE, BUILD_RANGE do
			local pPlot = Map.PlotXYWithRangeCheck(cx, cy, dx, dy, BUILD_RANGE)
			if pPlot and pPlot:GetOwner() == iPlayer and not pPlot:IsCity()
				and not inner[pPlot:GetY() * 4096 + pPlot:GetX()] then
				n = n + 1
				scratchPlots[n] = pPlot
			end
		end
	end
	return n
end

local rangeWarned = false

-- Fills scratchPlots with the player's owned, non-city tiles near the city,
-- nearest first, and returns the count.
local function CollectCityPlots(pCity, iPlayer)
	local n = 0
	local inner = {}
	local numPlots = pCity:GetNumCityPlots()
	for i = 0, numPlots - 1 do
		local pPlot = pCity:GetCityIndexPlot(i)
		if pPlot then
			inner[pPlot:GetY() * 4096 + pPlot:GetX()] = true
			if pPlot:GetOwner() == iPlayer and not pPlot:IsCity() then
				n = n + 1
				scratchPlots[n] = pPlot
			end
		end
	end

	-- Only scan further out if the engine's list does not already cover the range
	if numPlots < 1 + 3 * BUILD_RANGE * (BUILD_RANGE + 1) then
		local ok, result = pcall(CollectOuterPlots, pCity, iPlayer, inner, n)
		if ok then
			n = result
		elseif not rangeWarned then
			rangeWarned = true
			print("[AutoImprovements] Extended range disabled: " .. tostring(result))
		end
	end
	return n
end

--------------------------------------------------------------------------
-- CHOOSING A BUILD FOR A TILE
-- Returns build, tier (1 strategic, 2 luxury, 3 other) or nil.
--------------------------------------------------------------------------

-- Unimproved tile: connect its resource if possible, otherwise the best
-- ranked plain improvement (also acts as a stand-in until the resource's
-- own improvement is unlocked; ChooseUpgrade replaces it later).
local function ChooseForEmpty(pPlot, iPlayer, iTeam, builds, nBuilds, available)
	local resID = pPlot:GetResourceType(iTeam)
	if resID ~= nil and resID >= 0 then
		local list = connectBuilds[resID]
		if list then
			for i = 1, #list do
				local b = list[i]
				if available[b.build] and pPlot:CanBuild(b.build, iPlayer) then
					return b, resourceTier[resID] or 3
				end
			end
		end
	end
	for i = 1, nBuilds do
		local b = builds[i]
		if pPlot:CanBuild(b.build, iPlayer) then return b, 3 end
	end
	return nil
end

-- Improved tile: replace a non-connecting improvement of ours once the
-- resource's proper improvement is available.
local function ChooseUpgrade(pPlot, iPlayer, iTeam, imp, available)
	if not buildable[imp] then return nil end
	local resID = pPlot:GetResourceType(iTeam)
	if resID == nil or resID < 0 then return nil end
	local list = connectBuilds[resID]
	if not list then return nil end
	local current = improvementConnects[imp]
	if current and current[resID] then return nil end   -- already proper

	for i = 1, #list do
		local b = list[i]
		if available[b.build] and pPlot:CanBuild(b.build, iPlayer) then
			return b, resourceTier[resID] or 3
		end
	end
	return nil
end

--------------------------------------------------------------------------
-- BUILD PASS (one city)
-- Tiles are gathered per tier in scan order, then applied tier 1 -> 3.
--------------------------------------------------------------------------
local function BuildForCity(pCity, iPlayer, iTeam, builds, nBuilds, available, perTurn, nPlots)
	local tiers = { {}, {}, {} }

	for i = 1, nPlots do
		local pPlot = scratchPlots[i]
		local imp = pPlot:GetImprovementType()
		local b, tier
		if imp == NO_IMPROVEMENT then
			if not (SKIP_ENEMY and BlockedByEnemy(pPlot, iTeam)) then
				b, tier = ChooseForEmpty(pPlot, iPlayer, iTeam, builds, nBuilds, available)
			end
		else
			b, tier = ChooseUpgrade(pPlot, iPlayer, iTeam, imp, available)
			if b and SKIP_ENEMY and BlockedByEnemy(pPlot, iTeam) then b = nil end
		end

		if b then
			local list = tiers[tier]
			if #list < perTurn then
				list[#list + 1] = { plot = pPlot, build = b }
				-- Strategic list full: nothing can beat it, stop scanning
				if tier == 1 and #list >= perTurn then break end
			end
		end
	end

	local applied = 0
	for t = 1, 3 do
		local list = tiers[t]
		for i = 1, #list do
			if applied >= perTurn then break end
			local c = list[i]
			c.plot:SetImprovementType(c.build.improvement, iPlayer)
			c.plot:SetImprovementPillaged(false)
			applied = applied + 1
			dprint("Player", iPlayer, "city", pCity:GetID(), "tier", t,
				"built at", c.plot:GetX(), c.plot:GetY())
		end
	end
end

--------------------------------------------------------------------------
-- REPAIR PASS (one city): first pillaged tile in scan order, not blocked
--------------------------------------------------------------------------
local function RepairCity(iPlayer, iTeam, nPlots)
	local repaired = 0
	for i = 1, nPlots do
		local pPlot = scratchPlots[i]
		if pPlot:GetImprovementType() ~= NO_IMPROVEMENT
			and pPlot:IsImprovementPillaged()
			and not BlockedByEnemy(pPlot, iTeam) then
			if CONFIG.REMOVE_FALLOUT and FALLOUT_ID
				and pPlot:GetFeatureType() == FALLOUT_ID then
				pPlot:SetFeatureType(NO_FEATURE)
			end
			pPlot:SetImprovementPillaged(false)
			dprint("Player", iPlayer, "repaired", pPlot:GetX(), pPlot:GetY())
			repaired = repaired + 1
			if repaired >= REPAIRS_PER_CITY then return end
		end
	end
end

--------------------------------------------------------------------------
-- MAIN
-- A city acts when (turn + cityID) % interval == 0  (no stored state).
--------------------------------------------------------------------------
local function DoTurn(iPlayer)
	local pPlayer = Players[iPlayer]
	if not PlayerQualifies(pPlayer) then return end
	if pPlayer:GetNumCities() == 0 then return end

	local iTeam = pPlayer:GetTeam()
	local turn = Game.GetGameTurn()
	local builds, nBuilds, available, perTurn

	for pCity in pPlayer:Cities() do
		local key = turn + pCity:GetID()
		local doRepair = CONFIG.REPAIR_PILLAGED and key % REPAIR_INTERVAL == 0
		local doBuild  = key % BUILD_INTERVAL == 0

		if doRepair or doBuild then
			local nPlots = CollectCityPlots(pCity, iPlayer)   -- once per city

			if doRepair then RepairCity(iPlayer, iTeam, nPlots) end

			if doBuild then
				if builds == nil then   -- once per player, only when needed
					perTurn = GetActionsPerTurn(iTeam)
					builds, nBuilds, available = GetAvailableBuilds(iTeam, pPlayer:GetCivilizationType())
				end
				if nBuilds > 0 then
					BuildForCity(pCity, iPlayer, iTeam, builds, nBuilds, available, perTurn, nPlots)
				end
			end
		end
	end
end

-- Errors are logged instead of breaking the turn for other scripts
local function SafeDoTurn(iPlayer)
	local ok, err = pcall(DoTurn, iPlayer)
	if not ok then
		print("[AutoImprovements] ERROR for player " .. tostring(iPlayer) .. ": " .. tostring(err))
	end
end

-- A reload replaces the old handler instead of doubling it
if AutoImprovements_Handler then
	pcall(GameEvents.PlayerDoTurn.Remove, AutoImprovements_Handler)
end
AutoImprovements_Handler = SafeDoTurn
GameEvents.PlayerDoTurn.Add(SafeDoTurn)

print("AutoImprovements loaded. Range " .. tostring(BUILD_RANGE) .. ", every "
	.. tostring(BUILD_INTERVAL) .. " turns.")