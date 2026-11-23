-- PuppetBuilder.lua (gameplay script)

local CONFIG = {
    CHECK_INTERVAL           = 4,     -- run every N turns (1 = every turn)
    QUEUE_DEPTH              = 5,     -- buildings queued per puppet, so it stays busy between checks
    HUMANS_ONLY              = false, -- true = ignore AI players' puppets
    INCLUDE_NATIONAL_WONDERS = false,
    INCLUDE_WORLD_WONDERS    = false,
    EXCLUDED_BUILDINGS       = {      -- building types the puppet should never build
        -- "BUILDING_CASTLE",
    },
}

local INTERVAL = math.max(1, math.floor(CONFIG.CHECK_INTERVAL))
local DEPTH    = math.max(1, math.floor(CONFIG.QUEUE_DEPTH))

local PROCESS_WEALTH = GameInfo.Processes["PROCESS_WEALTH"]
local FOCUS_PROD     = CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION
local FOCUS_GOLD     = CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD

local excluded = {}
for _, t in ipairs(CONFIG.EXCLUDED_BUILDINGS) do excluded[t] = true end

-- Eligible buildings are worked out once, then reused every check.
local buildingCache

local function IsAllowed(building)
    if excluded[building.Type] then return false end
    local class = GameInfo.BuildingClasses[building.BuildingClass]
    if class then
        if not CONFIG.INCLUDE_WORLD_WONDERS and class.MaxGlobalInstances and class.MaxGlobalInstances > 0 then
            return false
        end
        if not CONFIG.INCLUDE_NATIONAL_WONDERS and class.MaxPlayerInstances and class.MaxPlayerInstances == 1 then
            return false
        end
    end
    return true
end

local function GetBuildingCache()
    if buildingCache then return buildingCache end
    local list = {}
    for building in GameInfo.Buildings() do
        if IsAllowed(building) then
            local cost = (building.Cost and building.Cost >= 0) and building.Cost or math.huge
            list[#list + 1] = { id = building.ID, cost = cost }
        end
    end
    -- cheapest first; ID tiebreak keeps the order identical on every client
    table.sort(list, function(a, b)
        if a.cost ~= b.cost then return a.cost < b.cost end
        return a.id < b.id
    end)
    buildingCache = list
    return list
end

local function FindNextBuilding(city, queued)
    local list = GetBuildingCache()
    for i = 1, #list do
        local id = list[i].id
        if not queued[id] and city:CanConstruct(id) then
            return id
        end
    end
    return nil
end

local function SetFocus(city, focus)
    if city:GetFocusType() ~= focus then
        city:SetFocusType(focus)
    end
end

local function HandlePuppet(city)
    local queueLen  = city:GetOrderQueueLength()
    local onProcess = queueLen > 0 and city:IsProductionProcess()
    local queued    = {}

    -- already busy with a full queue of real orders: nothing to do
    if queueLen >= DEPTH and not onProcess then
        SetFocus(city, FOCUS_PROD)
        return
    end

    local nextBuilding = FindNextBuilding(city, queued)

    if not nextBuilding then
        if queueLen == 0 or onProcess then
            SetFocus(city, FOCUS_GOLD)
            if queueLen == 0 and PROCESS_WEALTH then
                city:PushOrder(OrderTypes.ORDER_MAINTAIN, PROCESS_WEALTH.ID, -1, false, false, true)
            end
        else
            SetFocus(city, FOCUS_PROD) -- still finishing what's already queued
        end
        return
    end

    SetFocus(city, FOCUS_PROD)
    if onProcess then
        city:ClearOrderQueue()
        queueLen = 0
    end

    while nextBuilding and queueLen < DEPTH do
        city:PushOrder(OrderTypes.ORDER_CONSTRUCT, nextBuilding, -1, false, false, true)
        queued[nextBuilding] = true
        queueLen = queueLen + 1
        nextBuilding = (queueLen < DEPTH) and FindNextBuilding(city, queued) or nil
    end
end

function PuppetBuilder_DoTurn(playerID)
    -- the player ID offset spreads players across different turns
    if (Game.GetGameTurn() + playerID) % INTERVAL ~= 0 then return end

    local player = Players[playerID]
    if not player or not player:IsAlive() or player:IsMinorCiv() or player:IsBarbarian() then return end
    if CONFIG.HUMANS_ONLY and not player:IsHuman() then return end

    for city in player:Cities() do
        if city:IsPuppet() then
            local ok, err = pcall(HandlePuppet, city)
            if not ok then print("PuppetBuilder error: " .. tostring(err)) end
        end
    end
end

GameEvents.PlayerDoTurn.Add(PuppetBuilder_DoTurn)