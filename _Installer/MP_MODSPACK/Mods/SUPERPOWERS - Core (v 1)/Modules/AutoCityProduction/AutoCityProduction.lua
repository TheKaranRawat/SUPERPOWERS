--------------------------------------------------------------------------------
-- Automate City Production
--
-- UI-only InGameUIAddin. Adds a checkbox to the city screen. When enabled,
-- the city keeps its queue stocked with BUILDINGS (food -> production -> other)
-- and falls back to the Science process when nothing is left to build.
--
-- MULTIPLAYER SAFETY
--   * This script never changes game state directly. Every change goes through
--     Game.CityPushOrder / Game.CityPopOrder, the same networked commands the
--     normal production UI uses, so all clients receive identical orders.
--   * It only acts for the local player's own cities, on that player's turn.
--   * The on/off flag is UI-side data only (never read by gameplay code), so it
--     cannot cause desyncs. It is stored in the save file so it survives reloads.
--
-- PERFORMANCE
--   * Building catalog is built once and cached in sorted priority order.
--   * Each turn automated cities get an O(queue length) check only.
--   * The full building scan runs every CHECK_INTERVAL_TURNS turns per city
--     (staggered by city ID), or immediately if the queue is completely empty.
--------------------------------------------------------------------------------

-------------------------------- CONFIG ----------------------------------------
local CHECK_INTERVAL_TURNS = 8   -- full building scan every N turns per city
local MIN_QUEUE_DEPTH      = 4   -- keep at least this many non-process items queued
                                 -- (2 means the queue never runs dry mid-interval)
local DEBUG                = false

-- Building types the automation must never queue, e.g. "BUILDING_CIRCUS"
local EXCLUDED_BUILDINGS = {
}

-- Always treated as food / production tier even if the data scan misses them
local FOOD_OVERRIDES = {
	"BUILDING_GRANARY", "BUILDING_AQUEDUCT", "BUILDING_HARBOR", "BUILDING_LIGHTHOUSE",
}
local PRODUCTION_OVERRIDES = {
	"BUILDING_WORKSHOP", "BUILDING_FORGE", "BUILDING_FACTORY", "BUILDING_STONE_WORKS",
	"BUILDING_WATERMILL", "BUILDING_HYDRO_PLANT", "BUILDING_SOLAR_PLANT",
}

local TOOLTIP   = "Automate this city's production.[NEWLINE][NEWLINE]Builds only buildings: food first, "
               .. "then production, then everything else. Switches to the Science process when "
               .. "nothing is left to build.[NEWLINE][NEWLINE]Items you queue yourself are never removed "
               .. "and you can reorder the queue freely. Automated items are always added at the end."
--------------------------------------------------------------------------------

local function Log(msg) if DEBUG then print("[AutoCity] " .. tostring(msg)) end end

-- ===== Persistence (UI-side flag only) ======================================
local saveDB = nil
do
	local ok, db = pcall(function() return Modding.OpenSaveData() end)
	if ok then saveDB = db end
end

local flagCache = {}

local function FlagKey(city)
	return "AutoCity_" .. tostring(city:GetOwner()) .. "_" .. tostring(city:GetID())
end

local function IsAutomated(city)
	local key = FlagKey(city)
	local cached = flagCache[key]
	if cached == nil then
		cached = false
		if saveDB then
			local ok, v = pcall(function() return saveDB.GetValue(key) end)
			if ok and v == 1 then cached = true end
		end
		flagCache[key] = cached
	end
	return cached
end

local function SetAutomated(city, enabled)
	local key = FlagKey(city)
	flagCache[key] = enabled
	if saveDB then
		pcall(function() saveDB.SetValue(key, enabled and 1 or 0) end)
	end
end

-- ===== Building catalog (built once) ========================================
local catalog = nil          -- sorted array of { id, tier, cost }
local scienceProcessID = nil
local scienceResolved = false

local function ForEachRow(tableName, fn)
	local ok, t = pcall(function() return GameInfo[tableName] end)
	if ok and t then
		pcall(function() for row in t() do fn(row) end end)
	end
end

local YIELD_TABLES = {
	"Building_YieldChanges", "Building_YieldModifiers", "Building_SeaPlotYieldChanges",
	"Building_SeaResourceYieldChanges", "Building_ResourceYieldChanges",
	"Building_FeatureYieldChanges", "Building_TerrainYieldChanges",
	"Building_RiverPlotYieldChanges", "Building_LakePlotYieldChanges",
	"Building_YieldChangesPerPop",
}

local function IsPlainBuilding(b)
	if not b.Cost or b.Cost <= 0 then return false end
	local class = GameInfo.BuildingClasses[b.BuildingClass]
	if class then
		-- World / team / national wonders have instance limits; normal buildings do not.
		if (class.MaxGlobalInstances or -1) > 0 then return false end
		if (class.MaxTeamInstances or -1) > 0 then return false end
		if (class.MaxPlayerInstances or -1) > 0 then return false end
	end
	return true
end

local function BuildCatalog()
	local foodSet, prodSet, excluded = {}, {}, {}

	for _, name in ipairs(YIELD_TABLES) do
		ForEachRow(name, function(row)
			if row.Yield and row.Yield > 0 and row.BuildingType then
				if row.YieldType == "YIELD_FOOD" then foodSet[row.BuildingType] = true
				elseif row.YieldType == "YIELD_PRODUCTION" then prodSet[row.BuildingType] = true end
			end
		end)
	end
	for _, t in ipairs(FOOD_OVERRIDES) do foodSet[t] = true end
	for _, t in ipairs(PRODUCTION_OVERRIDES) do prodSet[t] = true end
	for _, t in ipairs(EXCLUDED_BUILDINGS) do excluded[t] = true end

	local list = {}
	for b in GameInfo.Buildings() do
		if not excluded[b.Type] and IsPlainBuilding(b) then
			local tier = 3
			if foodSet[b.Type] or (b.FoodKept and b.FoodKept > 0) then tier = 1
			elseif prodSet[b.Type] then tier = 2 end
			list[#list + 1] = { id = b.ID, tier = tier, cost = b.Cost }
		end
	end

	table.sort(list, function(a, b)
		if a.tier ~= b.tier then return a.tier < b.tier end
		if a.cost ~= b.cost then return a.cost < b.cost end
		return a.id < b.id
	end)
	Log("Catalog built with " .. #list .. " buildings")
	return list
end

local function GetScienceProcessID()
	if scienceResolved then return scienceProcessID end
	scienceResolved = true
	local p = GameInfo.Processes["PROCESS_RESEARCH"]
	if p then
		scienceProcessID = p.ID
	else
		ForEachRow("Process_ProductionYields", function(row)
			if not scienceProcessID and row.YieldType == "YIELD_SCIENCE" then
				local proc = GameInfo.Processes[row.ProcessType]
				if proc then scienceProcessID = proc.ID end
			end
		end)
	end
	return scienceProcessID
end

-- ===== Queue helpers =========================================================
local function ReadQueue(city)
	local info = {
		length = city:GetOrderQueueLength(),
		real = 0,             -- non-process entries (buildings, units, wonders, projects)
		lastRealIndex = -1,
		processIndices = {},  -- ascending
		buildingSet = {},     -- building IDs already queued
	}
	for i = 0, info.length - 1 do
		local orderType, data1 = city:GetOrderFromQueue(i)
		if orderType == OrderTypes.ORDER_MAINTAIN then
			info.processIndices[#info.processIndices + 1] = i
		else
			info.real = info.real + 1
			info.lastRealIndex = i
			if orderType == OrderTypes.ORDER_CONSTRUCT then
				info.buildingSet[data1] = true
			end
		end
	end
	return info
end

-- Networked command wrappers (same calls the stock production UI makes).
-- Args: city, order, data, bAlt=false, bReplace=false, bAppend=true
-- The 5th arg is "replace the whole queue" (true on a normal click, false on a
-- shift-click). It MUST stay false here or the player's queue gets wiped.
local function PushBuilding(city, id)
	Game.CityPushOrder(city, OrderTypes.ORDER_CONSTRUCT, id, false, false, true)
end
local function PushProcess(city, id)
	Game.CityPushOrder(city, OrderTypes.ORDER_MAINTAIN, id, false, false, true)
end
-- Pop only works on the currently selected city (same call the stock UI uses).
-- Returns true if the order was sent.
local function PopOrder(city, index)
	local sel = UI.GetHeadSelectedCity()
	if sel and sel:GetOwner() == city:GetOwner() and sel:GetID() == city:GetID() then
		Game.SelectedCitiesGameNetMessage(GameMessageTypes.GAMEMESSAGE_POP_ORDER, index)
		return true
	end
	return false
end

local function FindBuildings(city, queuedSet, needed)
	if not catalog then catalog = BuildCatalog() end
	local found = {}
	for i = 1, #catalog do
		local id = catalog[i].id
		if not queuedSet[id] and city:CanConstruct(id) then
			found[#found + 1] = id
			if #found >= needed then break end
		end
	end
	return found
end

local function CityIsManageable(city)
	if not city then return false end
	if city.IsPuppet and city:IsPuppet() then return false end
	if city.IsRazing and city:IsRazing() then return false end
	return true
end

-- ===== Core logic ============================================================
local function ProcessCity(city, fullScan)
	local q = ReadQueue(city)

	-- A process sitting in front of real items would block them forever.
	local blocked = false
	for _, idx in ipairs(q.processIndices) do
		if idx < q.lastRealIndex then blocked = true break end
	end

	local needed = MIN_QUEUE_DEPTH - q.real
	local isEmpty = (q.length == 0)

	if not (isEmpty or fullScan or blocked) then return end

	local pushed = {}
	if needed > 0 then
		pushed = FindBuildings(city, q.buildingSet, needed)
		for _, id in ipairs(pushed) do PushBuilding(city, id) end
	end

	local lastReal = q.lastRealIndex
	if #pushed > 0 then lastReal = q.length + #pushed - 1 end

	-- Nothing (more) to build: park the city on Science (appended at the end)
	if needed > 0 and #pushed < needed and #q.processIndices == 0 then
		local pid = GetScienceProcessID()
		if pid and city:CanMaintain(pid) then
			PushProcess(city, pid)
			Log("City " .. city:GetName() .. " -> science process")
		end
	end

	-- Remove processes that sit ahead of real items (highest index first so
	-- earlier indices stay valid). Player-added real items are never touched.
	for n = #q.processIndices, 1, -1 do
		local idx = q.processIndices[n]
		if idx < lastReal then PopOrder(city, idx) end
	end
end

local function OnActivePlayerTurnStart()
	local playerID = Game.GetActivePlayer()
	local player = Players[playerID]
	if not player or not player:IsAlive() or not player:IsHuman() then return end

	local turn = Game.GetGameTurn()
	for city in player:Cities() do
		if IsAutomated(city) and CityIsManageable(city) then
			local fullScan = ((turn + city:GetID()) % CHECK_INTERVAL_TURNS) == 0
			ProcessCity(city, fullScan)
		end
	end
end

-- ===== Checkbox / UI =========================================================
local cityScreenOpen = false
local isRefreshing = false  -- guards against SetCheck re-triggering the handler

local function RefreshButton()
	local city = UI.GetHeadSelectedCity()
	if cityScreenOpen and city and city:GetOwner() == Game.GetActivePlayer() and CityIsManageable(city) then
		isRefreshing = true
		Controls.AutoCityCheckbox:SetCheck(IsAutomated(city))
		isRefreshing = false
		ContextPtr:SetHide(false)
	else
		ContextPtr:SetHide(true)
	end
end

local function OnCheckChanged(bIsChecked)
	if isRefreshing then return end

	local city = UI.GetHeadSelectedCity()
	if not city or city:GetOwner() ~= Game.GetActivePlayer() or not CityIsManageable(city) then return end

	SetAutomated(city, bIsChecked)

	if bIsChecked then
		local name = Locale.ConvertTextKey(city:GetNameKey())
		Events.GameplayAlertMessage("Production automation enabled for " .. name)
		-- Act right away (only on our own turn) so the city isn't left idle
		local player = Players[Game.GetActivePlayer()]
		if player and player:IsTurnActive() then ProcessCity(city, true) end
	end
end

local function SafeAdd(eventName, fn)
	local ok, ev = pcall(function() return Events[eventName] end)
	if ok and ev then ev.Add(fn) else Log("Event missing: " .. eventName) end
end

local function OnEnterCityScreen()
	cityScreenOpen = true
	RefreshButton()
	local city = UI.GetHeadSelectedCity()
	local player = Players[Game.GetActivePlayer()]
	if city and IsAutomated(city) and CityIsManageable(city)
	   and city:GetOwner() == Game.GetActivePlayer()
	   and player and player:IsTurnActive() then
		ProcessCity(city, false)
	end
end

local function OnExitCityScreen()  cityScreenOpen = false RefreshButton() end

ContextPtr:SetHide(true)
-- Label comes from the XML String attribute (CheckBox has no SetText).
-- Tooltip is guarded so a missing method can never break script loading.
pcall(function() Controls.AutoCityCheckbox:SetToolTipString(TOOLTIP) end)
Controls.AutoCityCheckbox:RegisterCheckHandler(OnCheckChanged)

SafeAdd("SerialEventEnterCityScreen", OnEnterCityScreen)
SafeAdd("SerialEventExitCityScreen", OnExitCityScreen)
SafeAdd("SerialEventCityScreenDirty", RefreshButton)
SafeAdd("ActivePlayerTurnStart", OnActivePlayerTurnStart)