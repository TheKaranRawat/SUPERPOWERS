--==========================================================================
-- AutoImprovements.lua
-- Worker-less terrain improvement for Civilization V (BNW / Gods & Kings).
--
-- Every turn, each qualifying player automatically gets N new improvements
-- placed on tiles inside their borders. Pillaged improvements are repaired
-- by a separate, slower pass (see REPAIR_* in CONFIG).
--   N = BASE_PER_TURN + number of bonus techs the player's team has researched.
--
-- MULTIPLAYER SAFETY
--   * Runs only inside GameEvents.PlayerDoTurn, which fires identically on
--     every machine.
--   * Fully deterministic: no math.random, no os.time/os.clock, no pairs()
--     over hash tables, no Game.GetActivePlayer(), no UI calls, no
--     persistent state that can differ between clients (a reload or a late
--     join cannot desync it).
--   * Ties are broken by plot coordinates, never by chance.
--
-- PERFORMANCE
--   * All database lookups (builds, improvements, resources, techs, yields)
--     are cached once at load time.
--   * Per turn, work is limited to the owner's city tiles; improved tiles
--     are rejected with a single cheap call before anything else is done.
--   * Top-N selection is a tiny partial selection pass, no sorting.
--==========================================================================

--------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------
local CONFIG = {
	-- "PLAYER": N improvements per turn for the whole empire (literal reading)
	-- "CITY"  : N improvements per turn for EACH city
	MODE = "PLAYER",

	BASE_PER_TURN = 1,

	-- Improvements are only placed every BUILD_INTERVAL turns (1 = every turn).
	-- The count above is placed on each build turn. Stateless stagger: in
	-- "PLAYER" mode players are offset by player ID, in "CITY" mode cities
	-- are offset by city ID, so the work is spread over different turns.
	BUILD_INTERVAL = 3,

	-- Each tech the team owns adds +1 to the per-turn count.
	-- Techs missing from your database are skipped silently.
	BONUS_TECHS = {
		"TECH_INDUSTRIALIZATION",   -- 2 per turn
		-- "TECH_ELECTRICITY",      -- uncomment for 3 per turn
		-- "TECH_ROBOTICS",         -- uncomment for 4 per turn
	},

	HARD_CAP_PER_TURN = 6,          -- safety ceiling

	APPLY_TO_HUMANS      = true,
	APPLY_TO_AI          = true,    -- set false if the AI keeps using workers
	APPLY_TO_CITY_STATES = true,

	-- Slow repair of pillaged improvements, independent of the build count.
	-- Each city repairs REPAIRS_PER_CITY tile(s) every REPAIR_INTERVAL turns.
	-- Cities are staggered by city ID so the work spreads across turns.
	REPAIR_PILLAGED  = true,
	REPAIR_INTERVAL  = 3,
	REPAIRS_PER_CITY = 2,

	-- Skip tiles that currently hold an enemy-owned unit at war.
	SKIP_OCCUPIED_BY_ENEMY = true,

	-- Improvements never auto-built (great person / unit-consuming ones are
	-- excluded automatically via Build.Kill).
	EXCLUDED_IMPROVEMENTS = {
		"IMPROVEMENT_FORT",
		"IMPROVEMENT_CITADEL",
	},

	-- Tile scoring weights (used with the engine's yield-with-build query)
	YIELD_WEIGHTS = {
		YIELD_FOOD       = 12,
		YIELD_PRODUCTION = 10,
		YIELD_GOLD       = 6,
		YIELD_SCIENCE    = 8,
		YIELD_CULTURE    = 8,
		YIELD_FAITH      = 6,
	},
	RESOURCE_CONNECT_BONUS = 100,   -- connecting a resource beats most yield gains
	WORKED_TILE_BONUS      = 20,    -- prefer tiles a citizen is actually working
	UPGRADE_BONUS          = 300,   -- replacing a stand-in with the proper resource improvement

	DEBUG = false,
}

--------------------------------------------------------------------------
-- LOAD-TIME CACHES (identical on every client: built from the same DB)
--------------------------------------------------------------------------
-- Civ 5 has no ImprovementTypes / ResourceTypes globals; "none" is always -1.
local NO_IMPROVEMENT = -1
local NO_RESOURCE    = -1

local function dprint(...)
	if CONFIG.DEBUG then print("[AutoImprovements]", ...) end
end

-- Excluded improvement IDs
local excludedImprovement = {}
for _, typeName in ipairs(CONFIG.EXCLUDED_IMPROVEMENTS) do
	local id = GameInfoTypes[typeName]
	if id then excludedImprovement[id] = true end
end

-- Bonus tech IDs
local bonusTechIDs = {}
for _, typeName in ipairs(CONFIG.BONUS_TECHS) do
	local id = GameInfoTypes[typeName]
	if id then bonusTechIDs[#bonusTechIDs + 1] = id end
end

-- Which improvements connect which resource
local improvementConnects = {}   -- [improvementID][resourceID] = true
local resourceHasImprovement = {} -- [resourceID] = true
for row in GameInfo.Improvement_ResourceTypes() do
	local impID = GameInfoTypes[row.ImprovementType]
	local resID = GameInfoTypes[row.ResourceType]
	if impID and resID then
		improvementConnects[impID] = improvementConnects[impID] or {}
		improvementConnects[impID][resID] = true
		resourceHasImprovement[resID] = true
	end
end

-- Unique improvements: [improvementID] = civilizationID that owns it
local improvementCiv = {}
for row in GameInfo.Improvements() do
	if row.CivilizationType then
		local civID = GameInfoTypes[row.CivilizationType]
		if civID then improvementCiv[row.ID] = civID end
	end
end

-- Candidate improvement builds (ordered by Build ID -> deterministic)
local improvementBuilds = {}   -- { {build=, improvement=, tech=}, ... }
for row in GameInfo.Builds() do
	local impID = row.ImprovementType and GameInfoTypes[row.ImprovementType]
	if impID and not row.Kill and not excludedImprovement[impID] then
		improvementBuilds[#improvementBuilds + 1] = {
			build       = row.ID,
			improvement = impID,
			tech        = row.PrereqTech and GameInfoTypes[row.PrereqTech] or nil,
		}
	end
end

-- Improvements this script could have placed (only these may be replaced)
local buildableImprovement = {}
for i = 1, #improvementBuilds do
	buildableImprovement[improvementBuilds[i].improvement] = true
end

-- Yield list for scoring
local yieldList = {}
for typeName, weight in pairs(CONFIG.YIELD_WEIGHTS) do
	local id = GameInfoTypes[typeName]
	if id then yieldList[#yieldList + 1] = { id = id, weight = weight } end
end
table.sort(yieldList, function(a, b) return a.id < b.id end) -- fixed order

-- Engine query support check (older/modded DLLs may lack it)
local HAS_YIELD_QUERY = false
do
	local testPlot = Map.GetPlotByIndex(0)
	HAS_YIELD_QUERY = testPlot ~= nil
		and testPlot.GetYieldWithBuild ~= nil
		and testPlot.CalculateYield ~= nil
end

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function GetActionsPerTurn(iTeam)
	local team = Teams[iTeam]
	local count = CONFIG.BASE_PER_TURN
	for i = 1, #bonusTechIDs do
		if team:IsHasTech(bonusTechIDs[i]) then count = count + 1 end
	end
	if count > CONFIG.HARD_CAP_PER_TURN then count = CONFIG.HARD_CAP_PER_TURN end
	return count
end

local function PlayerQualifies(pPlayer)
	if not pPlayer or not pPlayer:IsAlive() then return false end
	if pPlayer:IsBarbarian() then return false end
	if pPlayer:IsMinorCiv() then return CONFIG.APPLY_TO_CITY_STATES end
	if pPlayer:IsHuman() then return CONFIG.APPLY_TO_HUMANS end
	return CONFIG.APPLY_TO_AI
end

-- Builds the player can use right now (once per player per turn)
local function GetAvailableBuilds(iTeam, iCiv)
	local team = Teams[iTeam]
	local list, n = {}, 0
	for i = 1, #improvementBuilds do
		local b = improvementBuilds[i]
		local owner = improvementCiv[b.improvement]
		-- Unique improvements are only available to the civ that owns them
		if (owner == nil or owner == iCiv)
			and (b.tech == nil or team:IsHasTech(b.tech)) then
			n = n + 1
			list[n] = b
		end
	end
	return list, n
end

local function TileHasEnemy(pPlot, iTeam)
	local team = Teams[iTeam]
	local numUnits = pPlot:GetNumUnits()
	for i = 0, numUnits - 1 do
		local pUnit = pPlot:GetUnit(i)
		if pUnit and team:IsAtWar(pUnit:GetTeam()) then return true end
	end
	return false
end

local function ScoreBuild(pPlot, b, iPlayer, connects, bWorked)
	local score = 0
	if connects then score = score + CONFIG.RESOURCE_CONNECT_BONUS end
	if HAS_YIELD_QUERY then
		for j = 1, #yieldList do
			local y = yieldList[j]
			local after  = pPlot:GetYieldWithBuild(b.build, y.id, true, iPlayer)
			local before = pPlot:CalculateYield(y.id, true)
			score = score + y.weight * (after - before)
		end
	end
	if bWorked then score = score + CONFIG.WORKED_TILE_BONUS end
	return score
end

-- Unimproved tile: returns bestBuild, bestScore (nil if nothing suitable).
-- Resource tiles whose proper improvement is not unlocked yet receive a
-- stand-in improvement; it is replaced later by the upgrade pass.
local function EvaluatePlot(pPlot, iPlayer, iTeam, builds, nBuilds, bWorked)
	local resID = pPlot:GetResourceType(iTeam)
	local hasResource = (resID ~= nil and resID ~= NO_RESOURCE)

	local legal, nLegal = nil, 0
	local anyConnects = false
	for i = 1, nBuilds do
		local b = builds[i]
		if pPlot:CanBuild(b.build, iPlayer) then
			legal = legal or {}
			nLegal = nLegal + 1
			legal[nLegal] = b
			if hasResource and improvementConnects[b.improvement]
				and improvementConnects[b.improvement][resID] then
				anyConnects = true
			end
		end
	end
	if nLegal == 0 then return nil end

	local bestBuild, bestScore
	for i = 1, nLegal do
		local b = legal[i]
		local connects = hasResource and improvementConnects[b.improvement]
			and improvementConnects[b.improvement][resID] or false

		-- If the proper improvement is available, only consider those.
		if (not anyConnects) or connects then
			local score = ScoreBuild(pPlot, b, iPlayer, connects, bWorked)
			if bestScore == nil or score > bestScore then
				bestBuild, bestScore = b, score
			end
		end
	end
	return bestBuild, bestScore
end

-- Improved tile: if it holds a non-connecting improvement we placed (or
-- could have placed) and a connecting improvement is now unlocked, return
-- that build and its score.
local function EvaluateUpgrade(pPlot, iPlayer, iTeam, builds, nBuilds, imp, bWorked)
	if not buildableImprovement[imp] or excludedImprovement[imp] then return nil end

	local resID = pPlot:GetResourceType(iTeam)
	if resID == nil or resID == NO_RESOURCE or not resourceHasImprovement[resID] then
		return nil
	end
	-- Already the proper improvement
	if improvementConnects[imp] and improvementConnects[imp][resID] then return nil end

	local bestBuild, bestScore
	for i = 1, nBuilds do
		local b = builds[i]
		if improvementConnects[b.improvement] and improvementConnects[b.improvement][resID]
			and pPlot:CanBuild(b.build, iPlayer) then
			local score = ScoreBuild(pPlot, b, iPlayer, true, bWorked) + CONFIG.UPGRADE_BONUS
			if bestScore == nil or score > bestScore then
				bestBuild, bestScore = b, score
			end
		end
	end
	return bestBuild, bestScore
end

-- Candidate ordering: higher score first, then lower y, then lower x
local function Better(score, x, y, other)
	if other == nil then return true end
	if score ~= other.score then return score > other.score end
	if y ~= other.y then return y < other.y end
	return x < other.x
end

-- Collect candidates for one city into 'out' (shared 'seen' avoids duplicates)
local function CollectCityCandidates(pCity, iPlayer, iTeam, builds, nBuilds, seen, out)
	local numPlots = pCity:GetNumCityPlots()
	for i = 0, numPlots - 1 do
		local pPlot = pCity:GetCityIndexPlot(i)
		if pPlot and pPlot:GetOwner() == iPlayer and not pPlot:IsCity() then
			local x, y = pPlot:GetX(), pPlot:GetY()
			local key = y * 4096 + x
			if not seen[key] then
				seen[key] = true

				local imp = pPlot:GetImprovementType()
				local candidate = nil

				if imp == NO_IMPROVEMENT then
					local bWorked = pCity:IsWorkingPlot(pPlot)
					local b, score = EvaluatePlot(pPlot, iPlayer, iTeam, builds, nBuilds, bWorked)
					if b then
						candidate = { plot = pPlot, build = b, score = score, x = x, y = y }
					end
				else
					local bWorked = pCity:IsWorkingPlot(pPlot)
					local b, score = EvaluateUpgrade(pPlot, iPlayer, iTeam, builds, nBuilds, imp, bWorked)
					if b then
						candidate = { plot = pPlot, build = b, score = score, x = x, y = y }
					end
				end

				if candidate and CONFIG.SKIP_OCCUPIED_BY_ENEMY
					and TileHasEnemy(pPlot, iTeam) then
					candidate = nil
				end

				if candidate then out[#out + 1] = candidate end
			end
		end
	end
end

-- Pull the best 'count' candidates out of the list (partial selection)
local function ApplyBest(out, count, iPlayer)
	local applied = 0
	local total = #out
	while applied < count and total > 0 do
		local bestIdx
		for i = 1, total do
			local c = out[i]
			local bestC = bestIdx and out[bestIdx] or nil
			if Better(c.score, c.x, c.y, bestC) then bestIdx = i end
		end
		local c = out[bestIdx]
		out[bestIdx] = out[total]
		out[total] = nil
		total = total - 1

		c.plot:SetImprovementType(c.build.improvement, iPlayer)
		c.plot:SetImprovementPillaged(false)
		applied = applied + 1
		dprint("Player", iPlayer, "built", c.x, c.y)
	end
	return applied
end

--------------------------------------------------------------------------
-- REPAIR PASS
-- Stateless and deterministic: a city is "due" when
-- (game turn + city ID) % REPAIR_INTERVAL == 0, so every client agrees
-- without storing anything. Pillaged tiles with an enemy unit on them are
-- skipped.
--------------------------------------------------------------------------
local function RepairPillaged(pPlayer, iPlayer, iTeam)
	local interval = CONFIG.REPAIR_INTERVAL
	if interval < 1 then interval = 1 end
	local turn = Game.GetGameTurn()
	local seen = {}

	for pCity in pPlayer:Cities() do
		if (turn + pCity:GetID()) % interval == 0 then
			local repaired = 0
			local numPlots = pCity:GetNumCityPlots()

			-- Repeat the (cheap) scan once per repair so ordering stays
			-- deterministic: worked tiles first, then lowest y, then lowest x.
			while repaired < CONFIG.REPAIRS_PER_CITY do
				local best, bestWorked, bestX, bestY
				for i = 0, numPlots - 1 do
					local pPlot = pCity:GetCityIndexPlot(i)
					if pPlot and pPlot:GetOwner() == iPlayer
						and pPlot:GetImprovementType() ~= NO_IMPROVEMENT
						and pPlot:IsImprovementPillaged() then
						local x, y = pPlot:GetX(), pPlot:GetY()
						if not seen[y * 4096 + x] and not TileHasEnemy(pPlot, iTeam) then
							local worked = pCity:IsWorkingPlot(pPlot)
							local better = false
							if best == nil then
								better = true
							elseif worked ~= bestWorked then
								better = worked
							elseif y ~= bestY then
								better = y < bestY
							else
								better = x < bestX
							end
							if better then
								best, bestWorked, bestX, bestY = pPlot, worked, x, y
							end
						end
					end
				end

				if not best then break end
				best:SetImprovementPillaged(false)
				seen[bestY * 4096 + bestX] = true
				repaired = repaired + 1
				dprint("Player", iPlayer, "repaired", bestX, bestY)
			end
		end
	end
end

--------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------
function AutoImprovements_PlayerDoTurn(iPlayer)
	local pPlayer = Players[iPlayer]
	if not PlayerQualifies(pPlayer) then return end
	if pPlayer:GetNumCities() == 0 then return end

	local iTeam = pPlayer:GetTeam()

	if CONFIG.REPAIR_PILLAGED then
		RepairPillaged(pPlayer, iPlayer, iTeam)
	end

	local interval = CONFIG.BUILD_INTERVAL
	if interval < 1 then interval = 1 end
	local turn = Game.GetGameTurn()

	-- Off-turn for this player in PLAYER mode: skip all scanning.
	if CONFIG.MODE ~= "CITY" and (turn + iPlayer) % interval ~= 0 then return end

	local perTurn = GetActionsPerTurn(iTeam)
	local builds, nBuilds = GetAvailableBuilds(iTeam, pPlayer:GetCivilizationType())
	if nBuilds == 0 then return end

	local seen = {}

	if CONFIG.MODE == "CITY" then
		for pCity in pPlayer:Cities() do
			if (turn + pCity:GetID()) % interval == 0 then
				local out = {}
				CollectCityCandidates(pCity, iPlayer, iTeam, builds, nBuilds, seen, out)
				if #out > 0 then ApplyBest(out, perTurn, iPlayer) end
			end
		end
	else
		local out = {}
		for pCity in pPlayer:Cities() do
			CollectCityCandidates(pCity, iPlayer, iTeam, builds, nBuilds, seen, out)
		end
		if #out > 0 then ApplyBest(out, perTurn, iPlayer) end
	end
end

GameEvents.PlayerDoTurn.Add(AutoImprovements_PlayerDoTurn)
print("AutoImprovements loaded. Yield query available: " .. tostring(HAS_YIELD_QUERY))