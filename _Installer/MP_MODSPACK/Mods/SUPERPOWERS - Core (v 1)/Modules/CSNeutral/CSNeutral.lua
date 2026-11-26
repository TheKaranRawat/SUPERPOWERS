-- CityStateWarRules.lua  (sim-side, GameEvents only)
-- 1) War declared directly on a city-state: pledged protectors may join in,
--    and the city-state keeps fighting.
-- 2) City-state dragged into a war because its ally is at war: peace is made.

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS
local MAX_CIV   = GameDefines.MAX_CIV_PLAYERS
local MAX_TEAMS = GameDefines.MAX_CIV_TEAMS

-- Settings
local PROTECTORS_JOIN_AI    = true   -- AI civs pledged to protect a CS join its war
local PROTECTORS_JOIN_HUMAN = false  -- human players are never auto-declared into wars

local prevWar  = {}   -- [pairKey] = true, wars as of the last sweep
local prevAlly = {}   -- [minorID] = allyID as of the last sweep
local direct   = {}   -- [pairKey] = {minorTeam, majorTeam}, wars treated as "direct"
local initialised = false
local iLastTurn = -1

local function Key(a, b)
    if a < b then return a .. ":" .. b end
    return b .. ":" .. a
end

local function Snapshot()
    local s = {}
    for a = 0, MAX_TEAMS - 1 do
        if Teams[a]:IsAlive() then
            for b = a + 1, MAX_TEAMS - 1 do
                if Teams[b]:IsAlive() and Teams[a]:IsAtWar(b) then
                    s[Key(a, b)] = true
                end
            end
        end
    end
    return s
end

local function SnapshotAllies()
    local t = {}
    for i = MAX_MAJOR, MAX_CIV - 1 do
        local p = Players[i]
        if p and p:IsAlive() and p:IsMinorCiv() then t[i] = p:GetAlly() end
    end
    return t
end

-- Majors pledged to protect this minor join the war against the aggressor
local function JoinProtectors(pMinor, iAggressorTeam)
    for iP = 0, MAX_MAJOR - 1 do
        local pP = Players[iP]
        if pP and pP:IsAlive() and pMinor:IsProtectedByMajor(iP) then
            local bAllowed
            if pP:IsHuman() then
                bAllowed = PROTECTORS_JOIN_HUMAN
            else
                bAllowed = PROTECTORS_JOIN_AI
            end

            local iPT = pP:GetTeam()
            if bAllowed
               and iPT ~= iAggressorTeam
               and not Teams[iPT]:IsAtWar(iAggressorTeam)
               and Teams[iPT]:CanDeclareWar(iAggressorTeam) then
                Teams[iPT]:DeclareWar(iAggressorTeam)
            end
        end
    end
end

local function Sweep()
    local handled = {}

    -- up to 3 passes so wars created by protectors joining (and any
    -- city-states dragged in by that) are classified too
    for pass = 1, 3 do
        local changed = false

        for iMinor = MAX_MAJOR, MAX_CIV - 1 do
            local pM = Players[iMinor]
            if pM and pM:IsAlive() and pM:IsMinorCiv() then
                local mt = pM:GetTeam()
                local iAlly = pM:GetAlly()
                local at = nil
                if iAlly and iAlly >= 0 and Players[iAlly] then
                    at = Players[iAlly]:GetTeam()
                end

                for iMajor = 0, MAX_MAJOR - 1 do
                    local pX = Players[iMajor]
                    if pX and pX:IsAlive() then
                        local xt = pX:GetTeam()
                        local k = Key(mt, xt)

                        if Teams[mt]:IsAtWar(xt) and not prevWar[k]
                           and not handled[k] and not direct[k] then
                            handled[k] = true
                            changed = true

                            -- Dragged in: ally is at war with them AND either that war
                            -- is new too, or this CS only just became that ally's ally.
                            local dragged = false
                            if at and at ~= xt and Teams[at]:IsAtWar(xt) then
                                if not prevWar[Key(at, xt)] or prevAlly[iMinor] ~= iAlly then
                                    dragged = true
                                end
                            end

                            if dragged then
                                Teams[mt]:MakePeace(xt)
                            else
                                direct[k] = { mt, xt }
                                JoinProtectors(pM, xt)
                            end
                        end
                    end
                end
            end
        end

        if not changed then break end
    end

    -- forget direct wars that have ended
    for k, v in pairs(direct) do
        if not Teams[v[1]]:IsAtWar(v[2]) then direct[k] = nil end
    end

    prevWar  = Snapshot()
    prevAlly = SnapshotAllies()
end

local function Init()
    prevWar  = Snapshot()
    prevAlly = SnapshotAllies()
    -- Wars that already exist when the script starts are left alone (treated as direct)
    for iMinor = MAX_MAJOR, MAX_CIV - 1 do
        local pM = Players[iMinor]
        if pM and pM:IsAlive() and pM:IsMinorCiv() then
            for iMajor = 0, MAX_MAJOR - 1 do
                local pX = Players[iMajor]
                if pX and pX:IsAlive() then
                    local mt, xt = pM:GetTeam(), pX:GetTeam()
                    if Teams[mt]:IsAtWar(xt) then direct[Key(mt, xt)] = { mt, xt } end
                end
            end
        end
    end
    initialised = true
end

function OnPlayerDoTurn(iPlayer)
    if iPlayer >= MAX_MAJOR then return end
    local iTurn = Game.GetGameTurn()
    if iTurn == iLastTurn then return end
    iLastTurn = iTurn

    if not initialised then Init() return end
    Sweep()
end
GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)