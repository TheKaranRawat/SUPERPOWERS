include("IconSupport")

--------------------------------------------------------------------------------
-- CONFIGURATION  (all times in seconds, distance in pixels)
--------------------------------------------------------------------------------
local CONFIG = {
    AnimationsEnabled    = true,    -- false = instant show/hide, no update loop at all
    SlideDuration        = 0.65,    -- how long the slide takes
    SlideDistance        = 100,      -- how far (px) the panel travels while sliding
    SlideFrom            = "LEFT",  -- "LEFT", "RIGHT", "UP" or "DOWN"
    FadeDuration         = 1.0,    -- how long the fade takes
    CloseSpeedMultiplier = 1.0,     -- closing speed relative to opening (2.0 = twice as fast)
    DebugLog             = false,    -- print events to Lua.log; set false once everything works
}

--------------------------------------------------------------------------------
-- STATE (UI-only: nothing here touches game state, so it can't desync MP)
--------------------------------------------------------------------------------
local g_iPlayer      = -1      -- player currently displayed (-1 = none)
local g_iIconPlayer  = -1      -- player the civ icon/title were last built for
local g_bOpen        = false   -- target state of the animation
local g_bAnimating   = false   -- is our per-frame update registered?
local g_slideP       = 0       -- slide progress, 0 (away) .. 1 (in place)
local g_fadeP        = 0       -- fade progress,  0 (invisible) .. 1 (opaque)
local g_closeSpeed   = 1       -- effective closing speed (set per close, see ClosePanel)
local g_textCache    = {}      -- last text written per control, avoids redundant SetText

-- Resting position comes from the XML so layout stays editable there
local g_baseX, g_baseY = 40, 160
do
    local ok, x, y = pcall(function() return Controls.Panel:GetOffsetVal() end)
    if ok and x and y then g_baseX, g_baseY = x, y end
end

local SLIDE_VECTORS = {
    LEFT  = { -1,  0 },
    RIGHT = {  1,  0 },
    UP    = {  0, -1 },
    DOWN  = {  0,  1 },
}
local g_slideDX, g_slideDY = unpack(SLIDE_VECTORS[string.upper(CONFIG.SlideFrom)] or SLIDE_VECTORS.LEFT)

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
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

local function FormatPopulationTotal(total)
    if total >= 1000000 then
        return string.format("%.2fM", total / 1000000)
    elseif total >= 1000 then
        return string.format("%dK", math.floor(total / 1000))
    else
        return tostring(math.floor(total))
    end
end

local function GetScoreRank(iPlayer)
    local myScore = Players[iPlayer]:GetScore()
    local rank = 1
    for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        if i ~= iPlayer then
            local p = Players[i]
            if p and p:IsAlive() and not p:IsMinorCiv() and not p:IsBarbarian()
               and p:GetScore() > myScore then
                rank = rank + 1
            end
        end
    end
    return rank
end

-- Only write to a control when its text actually changed
local function SetText(control, text)
    text = tostring(text)
    if g_textCache[control] ~= text then
        g_textCache[control] = text
        control:SetText(text)
    end
end

-- Multiplayer / hotseat: never reveal another human's private numbers.
local function IsInfoHidden(iPlayer, pl)
    if not pl:IsHuman() then return false end
    if iPlayer == Game.GetActivePlayer() then return false end
    return Game.IsNetworkMultiPlayer() or Game.IsHotSeat()
end

--------------------------------------------------------------------------------
-- ANIMATION
--------------------------------------------------------------------------------
local function Smooth(t)            -- smoothstep easing
    return t * t * (3 - 2 * t)
end

local function Step(p, dt, duration, dir)
    if duration <= 0 then
        return (dir > 0) and 1 or 0
    end
    p = p + dir * dt / duration
    if p < 0 then return 0 end
    if p > 1 then return 1 end
    return p
end

-- Run a UI call safely: a failing call is logged once (see Lua.log) and can never
-- break the animation state machine.
local g_logged = {}
local function Try(label, fn)
    local ok, err = pcall(fn)
    if not ok and not g_logged[label] then
        g_logged[label] = true
        print("[LeaderStatsPanel] " .. label .. " failed: " .. tostring(err))
    end
    return ok
end

local g_alphaOK = true   -- flips to false if the Panel control doesn't support SetAlpha

local function ApplyVisual()
    local s = 1 - Smooth(g_slideP)
    local dist = CONFIG.SlideDistance
    local x = g_baseX + g_slideDX * s * dist
    local y = g_baseY + g_slideDY * s * dist
    Try("SetOffsetVal", function() Controls.Panel:SetOffsetVal(x, y) end)
    if g_alphaOK then
        local a = Smooth(g_fadeP)
        g_alphaOK = Try("SetAlpha", function() Controls.Panel:SetAlpha(a) end)
    end
end

local function NoOp() end

-- NOTE: this script shares its context with LeaderHeadRoot, and a context has only one
-- update slot, so we never call ClearUpdate(). When idle, OnUpdate returns immediately
-- (one boolean check per frame).
local function StopAnimating()
    g_bAnimating = false
end

local function OnUpdate(fDTime)
    if not g_bAnimating then return end

    local dt = fDTime or 0.016
    if dt > 0.1 then dt = 0.1 end   -- avoid jumps after a hitch / load

    local dir, speed = 1, 1
    if not g_bOpen then
        dir = -1
        speed = g_closeSpeed
    end

    g_slideP = Step(g_slideP, dt * speed, CONFIG.SlideDuration, dir)
    g_fadeP  = Step(g_fadeP,  dt * speed, CONFIG.FadeDuration,  dir)

    -- Decide completion BEFORE touching any control, so state always settles
    local target = g_bOpen and 1 or 0
    local done = (g_slideP == target and g_fadeP == target)

    ApplyVisual()

    if done then
        if CONFIG.DebugLog then print("[LeaderStatsPanel] animation finished, open=" .. tostring(g_bOpen)) end
        StopAnimating()
        if not g_bOpen then
            Try("SetHide", function() Controls.Panel:SetHide(true) end)
        end
    end
end

local function StartAnimating()
    -- Always (re)register: harmless if already registered, and self-heals a stale state
    g_bAnimating = true
    ContextPtr:SetUpdate(OnUpdate)
end

local function OpenPanel()
    g_bOpen = true
    Controls.Panel:SetHide(false)
    if CONFIG.AnimationsEnabled then
        StartAnimating()            -- continues from current progress (handles interrupted close)
    else
        StopAnimating()
        g_slideP, g_fadeP = 1, 1
        ApplyVisual()
    end
end

-- budgetSeconds (optional): the host screen's fade-out length. If our close would take
-- longer than that, speed it up so the slide-out finishes before the screen disappears.
local function ClosePanel(budgetSeconds)
    g_bOpen = false

    local speed   = math.max(CONFIG.CloseSpeedMultiplier, 0.01)
    local longest = math.max(CONFIG.SlideDuration, CONFIG.FadeDuration)
    if budgetSeconds and budgetSeconds > 0 and longest / speed > budgetSeconds then
        speed = longest / budgetSeconds
    end
    g_closeSpeed = speed

    if CONFIG.AnimationsEnabled and not Controls.Panel:IsHidden() then
        StartAnimating()
    else
        StopAnimating()
        g_slideP, g_fadeP = 0, 0
        ApplyVisual()
        Controls.Panel:SetHide(true)
    end
end

--------------------------------------------------------------------------------
-- DATA REFRESH
--------------------------------------------------------------------------------
local function Refresh()
    if g_iPlayer < 0 then return end
    local pl = Players[g_iPlayer]
    if not pl or not pl:IsAlive() then return end

    local hidden = IsInfoHidden(g_iPlayer, pl)
    local function V(s) return hidden and "?" or s end

    -- Header (rebuilt only when the displayed player changes)
    if g_iIconPlayer ~= g_iPlayer then
        g_iIconPlayer = g_iPlayer
        Controls.Title:SetText(Locale.ConvertTextKey(pl:GetCivilizationShortDescriptionKey()))
        CivIconHookup(g_iPlayer, 128, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow)
    end
    SetText(Controls.Rank, "#" .. GetScoreRank(g_iPlayer))

    -- Single pass over cities
    local prod, wonders, popTotal = 0, 0, 0
    for city in pl:Cities() do
        wonders = wonders + city:GetNumWorldWonders()
        if not hidden then
            prod = prod + city:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
            popTotal = popTotal + (city:GetPopulation() ^ 2.8) * 1000
        end
    end

    -- Society (public info)
    SetText(Controls.Wonders, wonders)
    SetText(Controls.Cities, pl:GetNumCities())

    if hidden then
        -- Skip the unit loop and all private lookups entirely
        SetText(Controls.Land,    "?")
        SetText(Controls.Naval,   "?")
        SetText(Controls.Supply,  "?")
        SetText(Controls.Power,   "?")
        SetText(Controls.Gold,    "?")
        SetText(Controls.Sci,     "?")
        SetText(Controls.Prod,    "?")
        SetText(Controls.Pop,     "?")
        SetText(Controls.Culture, "?")
        SetText(Controls.Happy,   "?")
        return
    end

    -- Military
    local land, navy = 0, 0
    for unit in pl:Units() do
        if unit:IsCombatUnit() then
            local d = unit:GetDomainType()
            if d == DomainTypes.DOMAIN_LAND then land = land + 1
            elseif d == DomainTypes.DOMAIN_SEA then navy = navy + 1 end
        end
    end
    local supplied = pl:GetNumUnitsSupplied()
    local over     = pl:GetNumUnits()

    SetText(Controls.Land,   land)
    SetText(Controls.Naval,  navy)
    SetText(Controls.Supply, (supplied - over) .. "/" .. supplied)
    SetText(Controls.Power,  FormatK(pl:GetMilitaryMight()))

    -- Economy
    SetText(Controls.Gold, FormatK(pl:GetGold()) .. " (" .. FormatK(pl:CalculateGoldRate(), true) .. ")")
    SetText(Controls.Sci,  FormatK(pl:GetScience(), true))
    SetText(Controls.Prod, FormatK(prod))
    SetText(Controls.Pop,  FormatPopulationTotal(popTotal))

    -- Culture / happiness
    SetText(Controls.Culture, string.format("%+d", pl:GetTotalJONSCulturePerTurn()))
    SetText(Controls.Happy,   pl:GetExcessHappiness())
end

--[[ tab button 
Controls.TabButton:RegisterCallback(Mouse.eLClick, function()
    local show = Controls.Panel:IsHidden()
    Controls.Panel:SetHide(not show)
    if show then Refresh() end        -- compute only when opened
end)
]]--

--------------------------------------------------------------------------------
-- EVENTS
--------------------------------------------------------------------------------
local function Log(msg)
    if CONFIG.DebugLog then print("[LeaderStatsPanel] " .. msg) end
end

LuaEvents.LeaderStatsSetPlayer.Add(function(iPlayer)
    Log("SetPlayer " .. tostring(iPlayer))
    g_iPlayer = iPlayer
    Refresh()
    -- Always start a fresh open from zero. Updates stop while the leader screen is hidden,
    -- so a previous fade/slide may have been frozen half-way; never trust old progress.
    g_slideP, g_fadeP = 0, 0
    ApplyVisual()
    OpenPanel()
end)

-- Fired by LeaderHeadRoot at the START of its fade-out, while the screen is still visible,
-- so this is where the slide-out can actually be seen.
LuaEvents.LeaderStatsClose.Add(function(fFadeOutSeconds)
    Log("LeaderStatsClose " .. tostring(fFadeOutSeconds))
    g_iPlayer = -1          -- stop refreshing; keep showing the last values while leaving
    ClosePanel(fFadeOutSeconds)
end)

LuaEvents.LeaderStatsHide.Add(function()
    Log("LeaderStatsHide")
    -- Stop refreshing immediately; the panel keeps showing its last values while it fades out
    g_iPlayer = -1
    g_iIconPlayer = -1

    -- If the screen is already hidden, no updates will run: snap closed instead of animating
    local ctxHidden = false
    pcall(function() ctxHidden = ContextPtr:IsHidden() end)
    if ctxHidden then
        StopAnimating()
        g_bOpen = false
        g_slideP, g_fadeP = 0, 0
        ApplyVisual()
        Controls.Panel:SetHide(true)
    else
        ClosePanel()
    end
end)

-- No ContextPtr:SetShowHideHandler here on purpose: this context belongs to LeaderHeadRoot,
-- which has its own handler, and registering ours would replace it.

-- Initial state: invisible and parked at the slide-start position
ApplyVisual()
Controls.Panel:SetHide(true)