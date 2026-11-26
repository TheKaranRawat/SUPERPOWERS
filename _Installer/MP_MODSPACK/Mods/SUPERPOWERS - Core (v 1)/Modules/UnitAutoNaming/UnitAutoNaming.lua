--==========================================================================
-- UnitAutoNaming.lua
-- Names every newly TRAINED military land unit: "3rd Tokyo Riflemen"
--   * counts per city AND per unit type (3rd Tokyo Riflemen is separate from 3rd Tokyo Cannon)
--   * military units only (workers, settlers, missionaries, great people ignored)
--   * event driven: no per-turn loops, runs only when a city finishes a unit
--   * multiplayer safe: gameplay-only (no UI calls, no randomness, no
--     dependence on the local player), every client runs identical logic
--==========================================================================

----------------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------------
local INCLUDE_AI        = true   -- false = only human players get named units
local INCLUDE_BARBARIAN = false  -- barbarians never train in cities anyway
local PERSIST_COUNTS    = true   -- keep counters across save/load (see note below)

----------------------------------------------------------------------------
-- Cache globals (cheaper lookups)
----------------------------------------------------------------------------
local Players       = Players
local ConvertTextKey = Locale.ConvertTextKey
local tostring      = tostring
local pcall         = pcall

----------------------------------------------------------------------------
-- Counter storage
-- In-memory cache, optionally backed by the game's save data so counters
-- survive save/load. Every client performs the same writes in the same order,
-- so the data stays identical across machines.
----------------------------------------------------------------------------
local counts = {}
local saveDB = nil

if PERSIST_COUNTS and Modding and Modding.OpenSaveData then
	local ok, db = pcall(Modding.OpenSaveData)
	if ok and db then saveDB = db end
end

local function GetCount(key)
	local n = counts[key]
	if n == nil then
		n = 0
		if saveDB then
			local ok, v = pcall(saveDB.GetValue, key)
			if ok and v then n = v end
		end
		counts[key] = n
	end
	return n
end

local function SetCount(key, n)
	counts[key] = n
	if saveDB then
		pcall(saveDB.SetValue, key, n)
	end
end

----------------------------------------------------------------------------
-- English ordinal: 1st 2nd 3rd 4th ... 11th 12th 13th ... 21st 22nd 101st 111th
----------------------------------------------------------------------------
local function Ordinal(n)
	local m100 = n % 100
	local suffix = "th"
	if m100 < 11 or m100 > 13 then
		local m10 = n % 10
		if     m10 == 1 then suffix = "st"
		elseif m10 == 2 then suffix = "nd"
		elseif m10 == 3 then suffix = "rd"
		end
	end
	return tostring(n) .. suffix
end

----------------------------------------------------------------------------
-- Main handler
----------------------------------------------------------------------------
function UnitAutoNaming_OnCityTrained(playerID, cityID, unitID, bGold, bFaith)
	local player = Players[playerID]
	if player == nil then return end
	if not INCLUDE_BARBARIAN and player:IsBarbarian() then return end
	if not INCLUDE_AI and not player:IsHuman() then return end

	local unit = player:GetUnitByID(unitID)
	if unit == nil then return end

	-- Military land units only (skips naval and air)
	if not unit:IsCombatUnit() then return end
	if unit:GetDomainType() ~= DomainTypes.DOMAIN_LAND then return end

	local city = player:GetCityByID(cityID)
	if city == nil then return end

	local unitType = unit:GetUnitType()
	local key = "UAN_" .. playerID .. "_" .. cityID .. "_" .. unitType

	local n = GetCount(key) + 1
	SetCount(key, n)

	local unitName = ConvertTextKey(unit:GetNameKey())
	local cityName = city:GetName()
	if cityName == nil or cityName == "" then cityName = "?" end

	unit:SetName(Ordinal(n) .. " " .. ConvertTextKey(cityName) .. " " .. unitName)
end

GameEvents.CityTrained.Add(UnitAutoNaming_OnCityTrained)