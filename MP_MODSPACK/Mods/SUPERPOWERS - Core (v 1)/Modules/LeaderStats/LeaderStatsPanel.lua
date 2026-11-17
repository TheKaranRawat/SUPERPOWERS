include("IconSupport")
local g_iPlayer = -1

local function FormatK(n, signed)
    local sign = ""
    if n < 0 then
        sign = "-"
        n = -n
    elseif signed then
        sign = "+"
    end
    n = math.floor(n + 0.5)

    local s
    if n >= 1000000 then
        s = string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        s = string.format("%.1fK", n / 1000)
    else
        s = tostring(n)
    end
    s = s:gsub("%.0([KM])", "%1")   -- 2.0K -> 2K
    return sign .. s
end

local function GetScoreRank(iPlayer)
    local myScore = Players[iPlayer]:GetScore()
    local rank, total = 1, 0
    for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local p = Players[i]
        if p and p:IsAlive() and not p:IsMinorCiv() and not p:IsBarbarian() then
            total = total + 1
            if i ~= iPlayer and p:GetScore() > myScore then
                rank = rank + 1
            end
        end
    end
    return rank, total
end

local function FormatPopulation(pl)
    local total = 0
    for city in pl:Cities() do
        total = total + (city:GetPopulation() ^ 2.8) * 1000
    end

    if total >= 1000000 then
        return string.format("%.2fM", total / 1000000)
    elseif total >= 1000 then
        return string.format("%dK", math.floor(total / 1000))
    else
        return tostring(math.floor(total))
    end
end

local function Refresh()
    if g_iPlayer < 0 then return end
    local pl = Players[g_iPlayer]
    if not pl or not pl:IsAlive() then return end

    local hidden = pl:IsHuman() and Game.IsNetworkMultiPlayer()
    local function V(s) return hidden and "?" or s end

    -- Units
    local land, navy = 0, 0
    for unit in pl:Units() do
        if unit:IsCombatUnit() then
            local d = unit:GetDomainType()
            if d == DomainTypes.DOMAIN_LAND then land = land + 1
            elseif d == DomainTypes.DOMAIN_SEA then navy = navy + 1 end
        end
    end

    -- Cities: one pass for population, production, wonders
    local prod, wonders = 0, 0
    for city in pl:Cities() do
        prod = prod + city:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
        wonders = wonders + city:GetNumWorldWonders()
    end

    local supplied = pl:GetNumUnitsSupplied()
    local over     = pl:GetNumUnits()

    Controls.Title:SetText(Locale.ConvertTextKey(pl:GetCivilizationShortDescriptionKey()))
    local rank, total = GetScoreRank(g_iPlayer)
    Controls.Rank:SetText("#" .. rank)

    CivIconHookup(g_iPlayer, 128, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow)

    -- Military
    Controls.Land:SetText(land)
    Controls.Naval:SetText(navy)
    Controls.Supply:SetText(V((supplied - over) .. "/" .. supplied))
    Controls.Power:SetText(FormatK(pl:GetMilitaryMight()))

    -- Economy
    --[[
    Controls.Gold:SetText(V(math.floor(pl:GetGold()) .. " (" .. string.format("%+d", pl:CalculateGoldRate()) .. ")"))
    Controls.Sci:SetText(V(string.format("%+d", pl:GetScience())))
    Controls.Prod:SetText(V(math.floor(prod)))
    ]]--
    Controls.Gold:SetText(V(FormatK(pl:GetGold()) .. " (" .. FormatK(pl:CalculateGoldRate(), true) .. ")"))
    Controls.Sci:SetText(V(FormatK(pl:GetScience(), true)))
    Controls.Prod:SetText(V(FormatK(prod)))
    Controls.Pop:SetText(FormatPopulation(pl))

    -- Culture
    Controls.Wonders:SetText(wonders)
    Controls.Culture:SetText(V(string.format("%+d", pl:GetTotalJONSCulturePerTurn())))
    Controls.Cities:SetText(pl:GetNumCities())
    Controls.Happy:SetText(V(pl:GetExcessHappiness()))
end

--[[ tab button 
Controls.TabButton:RegisterCallback(Mouse.eLClick, function()
    local show = Controls.Panel:IsHidden()
    Controls.Panel:SetHide(not show)
    if show then Refresh() end        -- compute only when opened
end)
]]--

LuaEvents.LeaderStatsSetPlayer.Add(function(iPlayer)
    g_iPlayer = iPlayer
    Refresh()
end)

LuaEvents.LeaderStatsHide.Add(function()
    g_iPlayer = -1
end)

ContextPtr:SetShowHideHandler(function(bIsHide)
    if not bIsHide then Refresh() end
end)