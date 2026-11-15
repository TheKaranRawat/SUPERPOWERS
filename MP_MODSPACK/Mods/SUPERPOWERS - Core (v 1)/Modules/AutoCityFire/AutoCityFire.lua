-- Auto City Strike: cities fire at the best enemy target at turn start.
-- UI-context script (InGameUIAddin). Commands go through the network layer,
-- so it behaves exactly like a manual click and is multiplayer safe.

local CONFIG = {
    TARGET_CITIES = true,   -- fall back to enemy cities if no units are in range
    FRAME_DELAY   = 2,      -- frames to wait after turn start (lets visibility settle)
    SKIP_PUPPETS  = true,
    DEBUG         = true,   -- log errors/actions to Lua.log
}

local pendingFrames = 0

local function Log(msg)
    if CONFIG.DEBUG then print("[AutoCityStrike] " .. tostring(msg)) end
end

---------------------------------------------------------------
-- Plot lookup by offset (replaces the nonexistent Map.PlotXY)
---------------------------------------------------------------
local GetPlotOffset
if Map.PlotXYWithRangeCheck then
    GetPlotOffset = function(cx, cy, dx, dy, range)
        return Map.PlotXYWithRangeCheck(cx, cy, dx, dy, range)
    end
else
    local w, h = Map.GetGridSize()
    local wrapX = Map.IsWrapX()
    GetPlotOffset = function(cx, cy, dx, dy)
        local x, y = cx + dx, cy + dy
        if wrapX then x = x % w end
        if y < 0 or y >= h or x < 0 or x >= w then return nil end
        return Map.GetPlot(x, y)
    end
end

---------------------------------------------------------------
-- Estimated damage of this city's shot on a defender unit
---------------------------------------------------------------
local function EstimateDamage(pCity, pUnit)
    local ok, dmg = pcall(pCity.RangeCombatDamage, pCity, pUnit, nil, false)
    if ok and dmg then return dmg end
    return 0
end

---------------------------------------------------------------
-- Pick the best target for one city. Returns x, y, key, dmg or nil.
-- expected: table of [targetKey] = damage already assigned this volley
---------------------------------------------------------------
local function FindBestTarget(pCity, teamID, expected)
    local cx, cy = pCity:GetX(), pCity:GetY()
    local range  = (GameDefines and GameDefines.CITY_ATTACK_RANGE) or 2
    local bestScore, bx, by, bkey, bdmg = -1, nil, nil, nil, 0

    for dx = -range, range do
        for dy = -range, range do
            local plot = GetPlotOffset(cx, cy, dx, dy, range)
            if plot then
                local px, py = plot:GetX(), plot:GetY()

                if Map.PlotDistance(cx, cy, px, py) <= range
                   and plot:IsVisible(teamID, false) then

                    local numUnits    = plot:GetNumUnits()
                    local isEnemyCity = CONFIG.TARGET_CITIES and plot:IsCity()

                    -- Only run the legality check if something is on the plot
                    if (numUnits > 0 or isEnemyCity)
                       and pCity:CanRangeStrikeAt(px, py, true, true) then

                        if numUnits > 0 then
                            for i = 0, numUnits - 1 do
                                local u = plot:GetUnit(i)
                                if u and not u:IsDead()
                                   and not u:IsInvisible(teamID, false) then
                                    local key = px .. ":" .. py .. ":" .. u:GetID() .. ":" .. u:GetOwner()
                                    local hp  = u:GetCurrHitPoints() - (expected[key] or 0)
                                    if hp > 0 then
                                        local dmg   = EstimateDamage(pCity, u)
                                        local score = (dmg >= hp)
                                            and (1000 + u:GetBaseCombatStrength())
                                            or  (100 * dmg / math.max(hp, 1))
                                        if score > bestScore then
                                            bestScore, bx, by, bkey, bdmg = score, px, py, key, dmg
                                        end
                                    end
                                end
                            end
                        elseif isEnemyCity then
                            local key = px .. ":" .. py .. ":city"
                            if 1 > bestScore and not expected[key] then
                                bestScore, bx, by, bkey, bdmg = 1, px, py, key, 0
                            end
                        end
                    end
                end
            end
        end
    end

    return bx, by, bkey, bdmg
end

---------------------------------------------------------------
-- Main routine
---------------------------------------------------------------
local function AutoFire()
    local playerID = Game.GetActivePlayer()
    local pPlayer  = Players[playerID]
    if not pPlayer or not pPlayer:IsAlive() or not pPlayer:IsHuman() then return end
    if not pPlayer:IsTurnActive() then return end

    local teamID   = pPlayer:GetTeam()
    local expected = {}
    local fired    = false

    for pCity in pPlayer:Cities() do
        if not (CONFIG.SKIP_PUPPETS and pCity:IsPuppet())
           and pCity:CanRangeStrikeNow() then

            local x, y, key, dmg = FindBestTarget(pCity, teamID, expected)
            if x then
                local ok, err = pcall(function()
                    UI.SelectCity(pCity)
                    Game.SelectedCitiesGameNetMessage(
                        GameMessageTypes.GAMEMESSAGE_DO_TASK,
                        TaskTypes.TASK_RANGED_ATTACK, x, y)
                end)
                if ok then
                    expected[key] = (expected[key] or 0) + dmg
                    fired = true
                    Log(pCity:GetName() .. " fires at " .. x .. "," .. y)
                else
                    Log("fire failed for " .. pCity:GetName() .. ": " .. tostring(err))
                end
            end
        end
    end

    if fired then UI.ClearSelectedCities() end
end

---------------------------------------------------------------
-- Scheduling: wait a couple of frames after turn start, run once
---------------------------------------------------------------
local function OnUpdate()
    if pendingFrames > 0 then
        pendingFrames = pendingFrames - 1
        if pendingFrames == 0 then
            ContextPtr:ClearUpdate()
            local ok, err = pcall(AutoFire)
            if not ok then Log("AutoFire error: " .. tostring(err)) end
        end
    end
end

local function OnActivePlayerTurnStart()
    pendingFrames = CONFIG.FRAME_DELAY
    ContextPtr:SetUpdate(OnUpdate)
end

Events.ActivePlayerTurnStart.Add(OnActivePlayerTurnStart)