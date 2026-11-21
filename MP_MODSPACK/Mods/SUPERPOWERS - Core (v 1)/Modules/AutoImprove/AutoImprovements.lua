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
-- Pillaged improvements are repaired slowly (REPAIR_*); fallout is cleared on
-- its own, slower schedule (FALLOUT_*). Strategic/luxury resource tiles inside
-- the player's borders but beyond every city's reach are improved too
-- (OUTSIDE_RANGE_*). When an improvement cannot coexist with a forest or
-- jungle on the tile, that feature is cleared first (CLEAR_FEATURES).
--
-- MULTIPLAYER SAFETY
--   * Runs only from GameEvents.PlayerDoTurn (fires on every machine).
--   * Deterministic: no randomness, no clocks, no UI, no "active player"
--     queries; only explicit player/team queries on real game state.
--   * Stateless: schedules come from (game turn + city ID), so reloads and
--     late joins cannot put machines out of step.
--   * Fixed iteration order everywhere (engine city order, fixed tile scan).
--   * No cached game state: only database tables and plot handles are cached,
--     so a client that loads late computes exactly what the others do.
--   * Every engine call that fails is isolated with pcall (same result on all
--     clients, and it can never break the turn for other scripts).
--
-- PERFORMANCE
--   * A city does work only on its own turns (stagger by city ID); idle turns
--     cost a modulo check per city.
--   * Tile list is gathered once per city per turn and shared by all passes.
--   * Candidate selection stops early once strategic tiles fill the quota;
--     builds are tried best-first so most tiles need one or two CanBuild calls;
--     water/mountain tiles skip the generic search.
--   * The map-wide outside-range pass scans only a slice of the map per run
--     (OUTSIDE_RANGE_SLICES) using cached plot handles.
--==========================================================================

local CONFIG = {
	BASE_PER_TURN = 1,
	BONUS_TECHS = {
		"TECH_CIVIL_SERVICE",      -- +1 improvement per build turn
		"TECH_INDUSTRIALIZATION",      -- +1 improvement per build turn
	},

	BUILD_INTERVAL = 3,                -- a city builds every N turns (1 = every turn)
	BUILD_RANGE    = 5,                -- tiles from the city

	APPLY_TO_HUMANS      = true,
	APPLY_TO_AI          = true,
	APPLY_TO_CITY_STATES = true,

	SKIP_OCCUPIED_BY_ENEMY = true,     -- don't build/repair under at-war units

	-- Plain (non-resource) tiles on water or mountains never get a generic
	-- improvement, so skip searching them. Resource tiles are still handled.
	SKIP_GENERIC_ON_WATER_AND_MOUNTAINS = true,

	-- Slow repair of pillaged improvements
	REPAIR_PILLAGED  = true,
	REPAIR_INTERVAL  = 4,              -- each city, every N turns
	REPAIRS_PER_CITY = 2,

	-- Fallout cleanup (separate from repairs)
	REMOVE_FALLOUT    = true,
	FALLOUT_INTERVAL  = 6,             -- each city, every N turns
	FALLOUTS_PER_CITY = 1,

	-- Strategic/luxury resource tiles that are inside our borders but not
	-- covered by any city's range. Scans the map for the player's own tiles
	-- in slices; raise INTERVAL or SLICES to lower the cost on huge maps.
	OUTSIDE_RANGE_ENABLED  = true,
	OUTSIDE_RANGE_INTERVAL = 4,        -- each player scans every N turns...
	OUTSIDE_RANGE_SLICES   = 3,        -- ...1/N of the map each time (whole map
	                                   -- covered every INTERVAL x SLICES turns)

	-- Features removed before placing an improvement on the tile, but only
	-- when that improvement cannot exist alongside the feature (a Lumber Mill
	-- keeps its forest; a Mine or Farm clears it).
	CLEAR_FEATURES = {
		"FEATURE_FOREST",
		"FEATURE_JUNGLE",
	},

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

local DEBUG = CONFIG.DEBUG
local function dprint(...)
	if DEBUG then print("[AutoImprovements]", ...) end
end

local BUILD_INTERVAL   = math.max(1, math.floor(CONFIG.BUILD_INTERVAL))
local BUILD_RANGE      = math.max(1, math.floor(CONFIG.BUILD_RANGE))
local REPAIR_INTERVAL  = math.max(1, math.floor(CONFIG.REPAIR_INTERVAL))
local REPAIRS_PER_CITY = math.max(1, math.floor(CONFIG.REPAIRS_PER_CITY))
local SKIP_ENEMY       = CONFIG.SKIP_OCCUPIED_BY_ENEMY
local FALLOUT_ID       = GameInfoTypes["FEATURE_FALLOUT"]
local FALLOUT_ENABLED  = CONFIG.REMOVE_FALLOUT and FALLOUT_ID ~= nil
local FALLOUT_INTERVAL  = math.max(1, math.floor(CONFIG.FALLOUT_INTERVAL))
local FALLOUTS_PER_CITY = math.max(1, math.floor(CONFIG.FALLOUTS_PER_CITY))
local OUTSIDE_ENABLED   = CONFIG.OUTSIDE_RANGE_ENABLED
local OUTSIDE_INTERVAL  = math.max(1, math.floor(CONFIG.OUTSIDE_RANGE_INTERVAL))
local OUTSIDE_SLICES    = math.max(1, math.floor(CONFIG.OUTSIDE_RANGE_SLICES))

-- Plot types for the water/mountain shortcut (disabled if the globals are absent)
local PLOT_OCEAN    = PlotTypes and PlotTypes.PLOT_OCEAN
local PLOT_MOUNTAIN = PlotTypes and PlotTypes.PLOT_MOUNTAIN
local SKIP_GENERIC_WM = CONFIG.SKIP_GENERIC_ON_WATER_AND_MOUNTAINS
	and PLOT_OCEAN ~= nil and PLOT_MOUNTAIN ~= nil

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

-- Features each improvement may coexist with, and features we may clear
local validFeature = {}   -- [improvementID][featureID] = true
for row in GameInfo.Improvement_ValidFeatures() do
	local impID, feaID = GameInfoTypes[row.ImprovementType], GameInfoTypes[row.FeatureType]
	if impID and feaID then
		validFeature[impID] = validFeature[impID] or {}
		validFeature[impID][feaID] = true
	end
end
local clearFeature = {}
for _, id in ipairs(ToIDList(CONFIG.CLEAR_FEATURES)) do clearFeature[id] = true end

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

-- First available build that connects the tile's resource and is legal here
local function ConnectBuild(pPlot, iPlayer, resID, available)
	local list = connectBuilds[resID]
	if list then
		for i = 1, #list do
			local b = list[i]
			if available[b.build] and pPlot:CanBuild(b.build, iPlayer) then return b end
		end
	end
	return nil
end

-- Unimproved tile: connect its resource if possible, otherwise the best
-- ranked plain improvement (also acts as a stand-in until the resource's
-- own improvement is unlocked; ChooseUpgrade replaces it later).
local function ChooseForEmpty(pPlot, iPlayer, iTeam, builds, nBuilds, available)
	local resID = pPlot:GetResourceType(iTeam)
	if resID ~= nil and resID >= 0 then
		local b = ConnectBuild(pPlot, iPlayer, resID, available)
		if b then return b, resourceTier[resID] or 3 end
	end
	if SKIP_GENERIC_WM then
		local plotType = pPlot:GetPlotType()
		if plotType == PLOT_OCEAN or plotType == PLOT_MOUNTAIN then return nil end
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
	local current = improvementConnects[imp]
	if current and current[resID] then return nil end   -- already proper

	local b = ConnectBuild(pPlot, iPlayer, resID, available)
	if b then return b, resourceTier[resID] or 3 end
	return nil
end

--------------------------------------------------------------------------
-- PLACING IMPROVEMENTS
--------------------------------------------------------------------------

-- Places the improvement. A forest/jungle is cleared first, but only when the
-- improvement cannot exist on that feature (a Lumber Mill keeps its forest).
local function PlaceImprovement(pPlot, build, iPlayer)
	local imp = build.improvement
	local feature = pPlot:GetFeatureType()
	if feature ~= nil and clearFeature[feature] then
		local vf = validFeature[imp]
		if not (vf and vf[feature]) then
			pPlot:SetFeatureType(NO_FEATURE)
		end
	end
	pPlot:SetImprovementType(imp, iPlayer)
	pPlot:SetImprovementPillaged(false)
end

-- tiers[1] = strategic, [2] = luxury, [3] = other; each a list of
-- { plot, build }. Applies up to perTurn, best tier first.
local function ApplyTiers(tiers, perTurn, iPlayer)
	local applied = 0
	for t = 1, #tiers do
		local list = tiers[t]
		for i = 1, #list do
			if applied >= perTurn then return end
			local c = list[i]
			PlaceImprovement(c.plot, c.build, iPlayer)
			applied = applied + 1
			if DEBUG then dprint("Player", iPlayer, "tier", t, "built at", c.plot:GetX(), c.plot:GetY()) end
		end
	end
end

--------------------------------------------------------------------------
-- BUILD PASS (one city)
-- Tiles are gathered per tier in scan order, then applied tier 1 -> 3.
--------------------------------------------------------------------------
local function BuildForCity(iPlayer, iTeam, builds, nBuilds, available, perTurn, nPlots)
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

	ApplyTiers(tiers, perTurn, iPlayer)
end

--------------------------------------------------------------------------
-- OUTSIDE-RANGE PASS (one player)
-- Strategic / luxury resource tiles anywhere inside the player's borders.
-- City passes run first, so this mostly finds tiles beyond every city's reach.
-- Only connecting improvements are placed here (no stand-ins).
--------------------------------------------------------------------------

-- Plot handles (not game state) are cached on first use, so a scan costs one
-- ownership check per tile instead of two engine calls.
local allPlots, numAllPlots = nil, 0
local function GetAllPlots()
	if allPlots == nil then
		local list = {}
		local total = Map.GetNumPlots()
		for i = 0, total - 1 do list[i + 1] = Map.GetPlotByIndex(i) end
		allPlots, numAllPlots = list, total
	end
	return allPlots, numAllPlots
end

local function ImproveOutsideRange(iPlayer, iTeam, available, perTurn)
	local tiers = { {}, {} }

	-- This run covers one slice of the map; the slice advances every run
	local plots, total = GetAllPlots()
	local sliceSize = math.ceil(total / OUTSIDE_SLICES)
	local slice = math.floor(Game.GetGameTurn() / OUTSIDE_INTERVAL) % OUTSIDE_SLICES
	local first = slice * sliceSize + 1
	local last = math.min(total, first + sliceSize - 1)

	for i = first, last do
		local pPlot = plots[i]
		if pPlot and pPlot:GetOwner() == iPlayer then
			local resID = pPlot:GetResourceType(iTeam)
			if resID ~= nil and resID >= 0 then
				local tier = resourceTier[resID] or 3
				if tier <= 2 and not pPlot:IsCity() then
					local imp = pPlot:GetImprovementType()
					local b = nil
					if imp == NO_IMPROVEMENT then
						b = ConnectBuild(pPlot, iPlayer, resID, available)
					elseif buildable[imp] then
						local current = improvementConnects[imp]
						if not (current and current[resID]) then
							b = ConnectBuild(pPlot, iPlayer, resID, available)
						end
					end

					if b and not (SKIP_ENEMY and BlockedByEnemy(pPlot, iTeam)) then
						local list = tiers[tier]
						if #list < perTurn then
							list[#list + 1] = { plot = pPlot, build = b }
							if tier == 1 and #list >= perTurn then break end
						end
					end
				end
			end
		end
	end

	ApplyTiers(tiers, perTurn, iPlayer)
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
			pPlot:SetImprovementPillaged(false)
			if DEBUG then dprint("Player", iPlayer, "repaired", pPlot:GetX(), pPlot:GetY()) end
			repaired = repaired + 1
			if repaired >= REPAIRS_PER_CITY then return end
		end
	end
end

--------------------------------------------------------------------------
-- FALLOUT PASS (one city): first tile with fallout in scan order, not blocked
--------------------------------------------------------------------------
local function ClearFalloutCity(iPlayer, iTeam, nPlots)
	local cleared = 0
	for i = 1, nPlots do
		local pPlot = scratchPlots[i]
		if pPlot:GetFeatureType() == FALLOUT_ID and not BlockedByEnemy(pPlot, iTeam) then
			pPlot:SetFeatureType(NO_FEATURE)
			if DEBUG then dprint("Player", iPlayer, "cleared fallout", pPlot:GetX(), pPlot:GetY()) end
			cleared = cleared + 1
			if cleared >= FALLOUTS_PER_CITY then return end
		end
	end
end

--------------------------------------------------------------------------
-- MAIN
-- A city acts when (turn + cityID) % interval == 0; the outside-range pass
-- runs when (turn + playerID) % interval == 0 (no stored state).
--------------------------------------------------------------------------
local outsideWarned = false

local function DoTurn(iPlayer)
	local pPlayer = Players[iPlayer]
	if not PlayerQualifies(pPlayer) then return end
	if pPlayer:GetNumCities() == 0 then return end

	local iTeam = pPlayer:GetTeam()
	local turn = Game.GetGameTurn()
	local builds, nBuilds, available, perTurn

	local outsideDue = OUTSIDE_ENABLED and (turn + iPlayer) % OUTSIDE_INTERVAL == 0
	if outsideDue then
		perTurn = GetActionsPerTurn(iTeam)
		builds, nBuilds, available = GetAvailableBuilds(iTeam, pPlayer:GetCivilizationType())
	end

	for pCity in pPlayer:Cities() do
		local key = turn + pCity:GetID()
		local doFallout = FALLOUT_ENABLED and key % FALLOUT_INTERVAL == 0
		local doRepair  = CONFIG.REPAIR_PILLAGED and key % REPAIR_INTERVAL == 0
		local doBuild   = key % BUILD_INTERVAL == 0

		if doFallout or doRepair or doBuild then
			local nPlots = CollectCityPlots(pCity, iPlayer)   -- once per city

			if doFallout then ClearFalloutCity(iPlayer, iTeam, nPlots) end
			if doRepair then RepairCity(iPlayer, iTeam, nPlots) end

			if doBuild then
				if builds == nil then   -- once per player, only when needed
					perTurn = GetActionsPerTurn(iTeam)
					builds, nBuilds, available = GetAvailableBuilds(iTeam, pPlayer:GetCivilizationType())
				end
				if nBuilds > 0 then
					BuildForCity(iPlayer, iTeam, builds, nBuilds, available, perTurn, nPlots)
				end
			end
		end
	end

	-- Guarded separately: a failure here must not affect the city passes
	if outsideDue and nBuilds > 0 then
		local ok, err = pcall(ImproveOutsideRange, iPlayer, iTeam, available, perTurn)
		if not ok and not outsideWarned then
			outsideWarned = true
			print("[AutoImprovements] Outside-range pass failed: " .. tostring(err))
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