-- NewBuildingEffects.lua
-- GAMEPLAY context only (GameEvents). No UI calls in this file.

local DEBUG = false
local function dprint(...)
	if DEBUG then print(...) end
end

--------------------------------------------------------------
-- Helpers: resolve IDs once at load time (not on every event)
--------------------------------------------------------------
local function ResolveList(names)
	local ids = {}
	for _, name in ipairs(names) do
		local id = GameInfoTypes[name]
		if id ~= nil then
			ids[#ids + 1] = id
		else
			print("[NewBuildingEffects] WARNING: unknown type " .. name)
		end
	end
	return ids
end

local function ClearBuildings(city, ids)
	for i = 1, #ids do
		city:SetNumRealBuilding(ids[i], 0)
	end
end

-- Game speed order in the DB: 0 = Marathon, 1 = Epic, 2 = Standard, 3 = Quick
local function GiveSpeedScaledGold(player, amounts)
	local gold = amounts[Game.GetGameSpeedType()] or amounts.default
	player:ChangeGold(gold)
	dprint("Gold granted: " .. gold)
end

--------------------------------------------------------------
-- Cached IDs
--------------------------------------------------------------
local PALACE_ID           = GameInfoTypes["BUILDING_PALACE"]
local NEW_PALACE_ID       = GameInfoTypes["BUILDING_NEW_PALACE"]
local MILITARY_ACADEMY_ID = GameInfoTypes["BUILDING_MILITARY_ACADEMY"]

-- Removed from the OLD capital when the palace moves
local OLD_CAPITAL_CLEAR = ResolveList({
	"BUILDING_ELECTRICITY_BONUS",
	"BUILDING_ELECTRICITY_PENALTY",
	"BUILDING_MANPOWER_BONUS",
	"BUILDING_CONSUMER_BONUS",
	"BUILDING_CONSUMER_PENALTY_WARNING",
	"BUILDING_CONSUMER_PENALTY",
	"BUILDING_TB_ART_OF_WAR",
	"BUILDING_HAPPINESS_TOURISMBOOST",
	"BUILDING_TRADE_TO_SCIENCE",
	"BUILDING_RATIONALISM_HAPPINESS",
	"BUILDING_CAPITAL_LOCATOR",
})

-- Removed from the NEW capital (replaced by the palace)
local NEW_CAPITAL_CLEAR = ResolveList({
	"BUILDING_CITY_HALL_LV1",
	"BUILDING_CITY_HALL_LV2",
	"BUILDING_CITY_HALL_LV3",
	"BUILDING_CITY_HALL_LV4",
	"BUILDING_CITY_HALL_LV5",
	"BUILDING_PUPPET_GOVERNEMENT",
	"BUILDING_PUPPET_GOVERNEMENT_FULL",
	"BUILDING_CONSTABLE",
	"BUILDING_SHERIFF_OFFICE",
	"BUILDING_POLICE_STATION",
	"BUILDING_PROCURATORATE",
	"BUILDING_NEW_PALACE", -- the trigger building itself
})

local CAPITAL_LOCATOR_ID = GameInfoTypes["BUILDING_CAPITAL_LOCATOR"]

--------------------------------------------------------------
-- Handlers: handler(player, city)
--------------------------------------------------------------
local Handlers = {}

local function Register(typeName, fn)
	local id = GameInfoTypes[typeName]
	if id == nil then
		print("[NewBuildingEffects] WARNING: cannot register, unknown type " .. typeName)
		return
	end
	Handlers[id] = fn
end

-- AI bonus: free Military Academy with Market / Bazaar
local function AIBonus(player, city)
	if player:IsHuman() or MILITARY_ACADEMY_ID == nil then return end
	if not city:IsHasBuilding(MILITARY_ACADEMY_ID) then
		city:SetNumRealBuilding(MILITARY_ACADEMY_ID, 1)
		dprint("AI Free Military Academy!")
	end
end
Register("BUILDING_MARKET", AIBonus)
Register("BUILDING_BAZAAR", AIBonus)

-- One-time gold
Register("BUILDING_BURJ_TOWER", function(player)
	GiveSpeedScaledGold(player, { [0] = 99999, [1] = 66666, [2] = 44444, [3] = 22222, default = 44444 })
end)

Register("BUILDING_AUSTRIA_MUSIC_SCHOOL", function(player)
	GiveSpeedScaledGold(player, { [0] = 1000, [1] = 750, [2] = 500, [3] = 300, default = 500 })
end)

-- One-time population
Register("BUILDING_MEGACITY_PYRAMID", function(player, city)
	city:ChangePopulation(30, true)
end)

-- Move capital (human players only)
Register("BUILDING_NEW_PALACE", function(player, newCity)
	if not player:IsHuman() or PALACE_ID == nil then return end

	local newCityID = newCity:GetID()

	-- Already the capital: just consume the trigger building
	if newCity:IsHasBuilding(PALACE_ID) then
		newCity:SetNumRealBuilding(NEW_PALACE_ID, 0)
		return
	end

	for city in player:Cities() do
		if city:GetID() ~= newCityID and city:IsHasBuilding(PALACE_ID) then
			dprint("Old Capital Found!")
			city:SetNumRealBuilding(PALACE_ID, 0)
			ClearBuildings(city, OLD_CAPITAL_CLEAR)
			break -- only one capital
		end
	end

	if CAPITAL_LOCATOR_ID ~= nil then
		newCity:SetNumRealBuilding(CAPITAL_LOCATOR_ID, 1)
	end
	newCity:SetNumRealBuilding(PALACE_ID, 1)
	ClearBuildings(newCity, NEW_CAPITAL_CLEAR)
	dprint("Capital Moved!")
end)

--------------------------------------------------------------
-- Event entry point
--------------------------------------------------------------
function NewBuildingEffects(iPlayer, iCity, iBuilding, bGold, bFaith)
	local handler = Handlers[iBuilding]
	if handler == nil then return end -- fast exit for the 99% of buildings we don't care about

	local player = Players[iPlayer]
	if player == nil or player:IsBarbarian() or player:IsMinorCiv() then return end
	if player:GetNumCities() <= 0 then return end

	local city = player:GetCityByID(iCity)
	if city == nil then return end

	handler(player, city)
end

GameEvents.CityConstructed.Add(NewBuildingEffects)

-- UI context only (e.g. attach via an InGameUIAddin / UI include).
-- Purely local: removes a notification for this client, never touches game state.

local FILTER_KEYWORD = "OVER_RESOURCE"

function OnNotificationAdded(notificationId, notificationType, toolTip, summary, gameValue, extraGameData, playerID)
	if summary == nil then return end

	-- Only touch notifications for the local player
	if playerID ~= nil and playerID ~= Game.GetActivePlayer() then return end

	-- plain find (4th arg true) = no Lua pattern surprises
	if string.find(summary, FILTER_KEYWORD, 1, true) ~= nil then
		UI.RemoveNotification(notificationId)
	end
end

Events.NotificationAdded.Add(OnNotificationAdded)

print("New Building Effects Check Pass!")

