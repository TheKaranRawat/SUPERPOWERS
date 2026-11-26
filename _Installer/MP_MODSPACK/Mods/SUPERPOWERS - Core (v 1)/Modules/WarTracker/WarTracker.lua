-------------------------------------------------
-- War Tracker
-- UI-only: reads game state and draws UI. It never changes game state, sends network
-- commands or uses randomness, so it cannot desync a multiplayer game.
-- Event-driven: no per-frame work except a ~0.3s timer while the popup closes.
-- Stats are only computed when the popup opens (and once per turn while it is open).
-------------------------------------------------
include("IconSupport")
include("InstanceManager")

-- Not a global in UI contexts; pull it from GameDefines (nil-safe fallback)
local MAX_CIV_PLAYERS = (GameDefines and GameDefines.MAX_CIV_PLAYERS) or 64

local CFG = {
	MAX_CHIP_ICONS   = 5,    -- enemy icons shown on the bottom chip (overlapped)
	CLOSE_TIME       = 0.30, -- seconds the close animation runs
	CHIP_GAP         = 10,   -- vertical gap (px) between stacked war chips
	SHOW_CITY_STATES = false, -- false = hide city-state icons in the popup (their units/land/production
	                          --         are still counted in the stats, see next option)
	COUNT_CITY_STATES_IN_STATS = true, -- false = stats only count the major civs
}

-- Fixed name pools; the pick is derived from the turn number (never Game.Rand)
local NAMES = {
	attacker  = { "The Iron Offensive", "March of Empires", "Campaign of Conquest", "The Gilded Gauntlet", "Crown & Cannon" },
	defender  = { "Defense of the Realm", "Hearth & Standard", "The Unbroken Line", "Banner Held High", "The Long Vigil" },
	ongoing   = { "Standing Hostilities", "The Uneasy Front", "Smoldering Frontiers" },
	coalition = { "The Grand Coalition", "Concert of Foes", "The Gathering Storm", "Pact of Ruin" },
}
-- Flavor text: one reason per war, picked from a hash of the war's start turn, role and first
-- enemy team. That makes it vary from war to war but identical on every client (no RNG used).
local REASONS = {
	attacker = {   -- "Declared in <year> <reason>."
		"to answer old insults with a single decisive blow",
		"so that our banners may fly over a greater destiny",
		"to break the old order and forge a mightier realm",
		"in the name of glory, which asks no permission",
		"to teach our rivals the price of underestimating us",
		"for honor, for empire, and for the pages of history",
		"to seize destiny before it slips from our grasp",
	},
	defender = {   -- "Declared upon us in <year> <reason>."
		"as envious empires gathered at our gates",
		"when rivals mistook our peace for weakness",
		"by foes who coveted what generations built",
		"in a bid to topple our throne and divide our lands",
		"as old treacheries finally came due",
		"when ambition cast its shadow over our borders",
	},
	ongoing = {    -- "Already raging by <year>, <reason>."
		"its origins lost in the smoke of a thousand campfires",
		"a feud older than the memory of our oldest scribes",
		"its cause forgotten, its fury undimmed",
		"a grudge that history refuses to bury",
	},
}

-- Each conflict: { id, role, turn, enemyTeams = {[teamID]=true}, name, lossesOur, lossesTheir }
local g_Conflicts  = {}
local g_NextID     = 1
local g_OpenID     = nil   -- id of the conflict whose popup is open
local g_CloseTimer = 0

local ClosePopup, TogglePopup   -- defined below

local g_ChipIM  = InstanceManager:new("WarChip",    "ChipRoot",   Controls.ChipStack)
-- Popup geometry (must match WarTracker.xml). Coordinates are from the wrapper's top-left;
-- the visible panel starts MARGIN px in, so icons can float over its left/right edges.
local MARGIN, PANEL_W = 70, 440
local POP = { COL_X = { MARGIN + 10, MARGIN + PANEL_W - 10 }, COL_Y = 12 - 50, COL_H = 300 - 24,  -- civ icons straddle the edges (moved up 50)
              CS_X = { MARGIN + 80, MARGIN + 224 }, CS_W = 136, CS_Y = 254 }                       -- small city-state rows

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function ActiveTeam() return Game.GetActiveTeam() end

-- True once a valid active player/team exists (guards early load, observers, reconnects)
local function Ready()
	local ap, at = Game.GetActivePlayer(), Game.GetActiveTeam()
	return ap ~= nil and ap >= 0 and Players[ap] ~= nil and at ~= nil and at >= 0 and Teams[at] ~= nil
end

local function IsRealPlayer(p)
	return p ~= nil and p:IsAlive() and not p:IsBarbarian()
end

local ICON_SIZES = { 256, 128, 80, 64, 48, 45, 32, 24 }
local g_IconWarned = false

-- Sets a civ icon at `size`; if the atlas has no such size, falls back to the nearest smaller
-- one, then a larger one. Returns the size actually used (nil if nothing worked).
local function SetCivIcon(ctrl, pid, size)
	local p = Players[pid]
	if not p then return nil end
	local civ = GameInfo.Civilizations[p:GetCivilizationType()]
	if not civ then return nil end

	local cands = {}
	for _, s in ipairs(ICON_SIZES) do if s <= size then cands[#cands + 1] = s end end
	for i = #ICON_SIZES, 1, -1 do if ICON_SIZES[i] > size then cands[#cands + 1] = ICON_SIZES[i] end end

	for _, sz in ipairs(cands) do
		local exists = true
		if IconLookup ~= nil then
			local ok, offset = pcall(IconLookup, civ.PortraitIndex, sz, civ.IconAtlas)
			exists = ok and offset ~= nil
		end
		if exists and IconHookup(civ.PortraitIndex, sz, civ.IconAtlas, ctrl) ~= false then
			return sz
		end
	end
	if not g_IconWarned then
		g_IconWarned = true
		print("WarTracker: no icon size found in atlas " .. tostring(civ.IconAtlas))
	end
	return nil
end

local function CountSet(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

local function PickName(c)
	local pool = NAMES[c.role]
	if CountSet(c.enemyTeams) >= 3 then pool = NAMES.coalition end
	return pool[(c.turn % #pool) + 1]
end
-- In-game calendar year of a turn, e.g. "1250 AD" / "3000 BC" (nil if the API is unavailable)
local function YearString(turn)
	local ok, year = pcall(function()
		if Game.GetTurnYear ~= nil then return Game.GetTurnYear(turn) end
		if Game.GetGameTurnYear ~= nil then return Game.GetGameTurnYear() end
		return nil
	end)
	if not ok or type(year) ~= "number" then return nil end
	local n   = math.abs(year)
	local key = (year < 0) and "TXT_KEY_TIME_BC" or "TXT_KEY_TIME_AD"
	local str = Locale.ConvertTextKey(key, n)
	if string.find(str, "TXT_KEY", 1, true) then str = n .. ((year < 0) and " BC" or " AD") end
	return str
end

local function FlavorText(c)
	local pool = REASONS[c.role]
	-- two rounds of a Park-Miller step, then the middle bits: integer math that stays exact in
	-- Lua doubles and gives every client the same pick (no RNG is used)
	local r = (c.seed * 48271) % 2147483647
	r = (r * 48271) % 2147483647
	local reason = pool[math.floor(r / 4096) % #pool + 1]
	local when = c.year or ("turn " .. c.turn)
	if c.role == "attacker" then return string.format("Declared in %s %s.", when, reason) end
	if c.role == "defender" then return string.format("Declared upon us in %s %s.", when, reason) end
	return string.format("Already raging by %s, %s.", when, reason)
end

-- Word-wraps into at most two centered lines (anything longer is folded into line two)
local function WrapTwoLines(text, maxChars)
	local lines, cur = {}, ""
	for word in string.gmatch(text, "%S+") do
		if cur == "" then cur = word
		elseif #cur + 1 + #word <= maxChars then cur = cur .. " " .. word
		else lines[#lines + 1] = cur; cur = word end
	end
	lines[#lines + 1] = cur
	if #lines > 2 then
		lines[2] = table.concat(lines, " ", 2)
		for i = #lines, 3, -1 do lines[i] = nil end
	end
	return lines[1] or "", lines[2] or ""
end

local function CivName(p)
	return Locale.ConvertTextKey(p:GetCivilizationShortDescriptionKey())
end

-- A side = every living player on the given teams + city-states allied to any of them
local function CollectSide(teamSet)
	local list, seen = {}, {}
	for pid = 0, MAX_CIV_PLAYERS - 1 do
		local p = Players[pid]
		if IsRealPlayer(p) and teamSet[p:GetTeam()] then
			list[#list + 1] = pid
			seen[pid] = true
		end
	end
	for pid = 0, MAX_CIV_PLAYERS - 1 do
		local p = Players[pid]
		if IsRealPlayer(p) and p:IsMinorCiv() and not seen[pid] then
			local ally = p:GetAlly()
			if ally ~= nil and ally >= 0 then
				local ap = Players[ally]
				if ap and teamSet[ap:GetTeam()] then
					list[#list + 1] = pid
					seen[pid] = true
				end
			end
		end
	end
	return list
end

-- Which side of conflict c does this player belong to? ("our" / "their" / nil)
local function SideOfPlayer(c, pid)
	local p = Players[pid]
	if not p then return nil end
	local function sideFor(q)
		local t = q:GetTeam()
		if t == ActiveTeam() then return "our" end
		if c.enemyTeams[t] then return "their" end
	end
	local s = sideFor(p)
	if s then return s end
	if p:IsMinorCiv() then
		local ally = p:GetAlly()
		if ally ~= nil and ally >= 0 and Players[ally] then return sideFor(Players[ally]) end
	end
	return nil
end

local function TeamHasRealPlayers(team)
	for pid = 0, MAX_CIV_PLAYERS - 1 do
		local p = Players[pid]
		if IsRealPlayer(p) and p:GetTeam() == team then return true end
	end
	return false
end

-- True only for teams that contain a living major civ (not a city-state, not barbarians)
local function TeamHasMajorCiv(team)
	for pid = 0, MAX_CIV_PLAYERS - 1 do
		local p = Players[pid]
		if IsRealPlayer(p) and not p:IsMinorCiv() and p:GetTeam() == team then return true end
	end
	return false
end

-------------------------------------------------
-- Bottom chips
-------------------------------------------------
local function RebuildChips()
	g_ChipIM:ResetInstances()
	if not Ready() then return end
	local ICON, STEP, PAD, CHIP_H = 64, 32, 16, 96     -- STEP = ICON / 2 -> icons overlap by half
	local ROOT_H = ICON + CFG.CHIP_GAP                 -- layout height per chip: icon + the gap below it

	for _, c in ipairs(g_Conflicts) do
		local chip  = g_ChipIM:GetInstance()
		local slots = { chip.E1, chip.E2, chip.E3, chip.E4, chip.E5 }
		local glows = { chip.G1, chip.G2, chip.G3, chip.G4, chip.G5 }
		local shown, total = 0, 0
		local tooltip = c.name .. " (turn " .. c.turn .. ")"

		for team in pairs(c.enemyTeams) do
			total = total + 1
			for pid = 0, MAX_CIV_PLAYERS - 1 do   -- representative = first living player on that team
				local p = Players[pid]
				if IsRealPlayer(p) and p:GetTeam() == team then
					if shown < CFG.MAX_CHIP_ICONS then
						shown = shown + 1
						SetCivIcon(slots[shown], pid, ICON)
					end
					tooltip = tooltip .. "[NEWLINE]- " .. CivName(p)
					break
				end
			end
		end

		for i = 1, #slots do
			slots[i]:SetHide(i > shown)
			glows[i]:SetHide(i > shown)
		end

		-- single war icon on the lower-right corner of the last (top-most) icon
		local lastX = PAD + (math.max(shown, 1) - 1) * STEP
		chip.WarIcon:SetHide(shown == 0)
		chip.WarIcon:SetText("[ICON_WAR]")
		chip.WarIcon:SetOffsetVal(lastX + 40, 54)

		local more = total > shown
		chip.MoreLabel:SetText(more and ("+" .. (total - shown)) or "")
		chip.MoreLabel:SetOffsetVal(lastX + ICON + 4, 36)

		local w = lastX + ICON + PAD + (more and 36 or 0)
		chip.ChipRoot:SetSizeVal(w, ROOT_H)
		chip.ChipAlpha:SetSizeVal(w, CHIP_H)
		chip.ChipButton:SetSizeVal(w, CHIP_H)

		chip.ChipButton:SetToolTipString(tooltip)
		local id = c.id
		chip.ChipButton:RegisterCallback(Mouse.eLClick, function() TogglePopup(id) end)

		chip.ChipAlpha:SetToBeginning()
		chip.ChipAlpha:Play()
	end

	Controls.ChipStack:CalculateSize()
	Controls.ChipStack:ReprocessAnchoring()
end

-------------------------------------------------
-- Conflict bookkeeping
-------------------------------------------------
local function FindConflictFor(team)
	for _, c in ipairs(g_Conflicts) do
		if c.enemyTeams[team] then return c end
	end
end

local function AddWar(otherTeam, role)
	if FindConflictFor(otherTeam) then return end
	local turn = Game.GetGameTurn()
	local target

	if role == "ongoing" then
		-- wars that were already running (load / reconnect) all share a single group
		for _, c in ipairs(g_Conflicts) do
			if c.role == "ongoing" then target = c break end
		end
	else
		-- same role, same turn => same group
		for _, c in ipairs(g_Conflicts) do
			if c.turn == turn and c.role == role then target = c break end
		end
		-- an enemy's ally joining our same-turn offensive belongs to that group
		if not target and role == "defender" then
			for _, c in ipairs(g_Conflicts) do
				if c.turn == turn and c.role == "attacker" then target = c break end
			end
		end
	end

	if not target then
		target = { id = g_NextID, role = role, turn = turn, enemyTeams = {}, lossesOur = 0, lossesTheir = 0 }
		target.year   = YearString(turn)
		target.seed   = turn * 7919 + (role == "attacker" and 11 or (role == "defender" and 23 or 37)) + otherTeam * 104729
		target.flavor = FlavorText(target)
		g_NextID = g_NextID + 1
		g_Conflicts[#g_Conflicts + 1] = target
	end
	target.enemyTeams[otherTeam] = true
	target.name = PickName(target)
end

local function RemoveWar(otherTeam)
	for i = #g_Conflicts, 1, -1 do
		local c = g_Conflicts[i]
		if c.enemyTeams[otherTeam] then
			c.enemyTeams[otherTeam] = nil
			if next(c.enemyTeams) == nil then
				if g_OpenID == c.id then ClosePopup(true) end
				table.remove(g_Conflicts, i)
			else
				c.name = PickName(c)
			end
		end
	end
end

-- Wars that already exist (game start, load, reconnect, hotseat switch) show as "ongoing"
local function ScanExistingWars()
	g_Conflicts = {}
	if Ready() then
		local me, pTeam, done = ActiveTeam(), Teams[ActiveTeam()], {}
		for pid = 0, MAX_CIV_PLAYERS - 1 do
			local p = Players[pid]
			if IsRealPlayer(p) then
				local t = p:GetTeam()
				if t ~= me and not done[t] then
					done[t] = true
					if pTeam:IsHasMet(t) and pTeam:IsAtWar(t) and TeamHasMajorCiv(t) then AddWar(t, "ongoing") end
				end
			end
		end
	end
	RebuildChips()
end

-------------------------------------------------
-- Stats (exact values)
-------------------------------------------------
local function SideStats(pids)
	local s = { armies = 0, navies = 0, prod = 0, land = 0 }
	for _, pid in ipairs(pids) do
		local p = Players[pid]
		for u in p:Units() do
			if u:IsCombatUnit() then
				local d = u:GetDomainType()
				if d == DomainTypes.DOMAIN_LAND then s.armies = s.armies + 1
				elseif d == DomainTypes.DOMAIN_SEA then s.navies = s.navies + 1 end
			end
		end
		for city in p:Cities() do
			s.prod = s.prod + city:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
		end
		s.land = s.land + p:GetTotalLand()
	end
	return s
end

local function Fmt(n) return tostring(math.floor(n + 0.5)) end

-- Civ icons float over the left/right edge of the panel as a vertical stack of 80px icons that
-- overlap by 40% (48px step; later icons draw on top). If more civs are present than fit
-- at that step, the step shrinks (more overlap) so all of them stay visible (max 7).
-- City-states are a small (24px) row near the bottom of each half.
local CIV_ICON, CIV_STEP = 80, 48
local MAJOR_SLOTS, ALLY_SLOTS = 7, 5

local function PlaceSlot(btn, img, pid, cell, x, y)
	local used = SetCivIcon(img, pid, cell)
	btn:SetSizeVal(cell, cell)
	btn:SetOffsetVal(math.floor(x + 0.5), math.floor(y + 0.5))
	img:SetSizeVal(used or cell, used or cell)
	local p = Players[pid]
	local tip = CivName(p)
	if p:IsMinorCiv() then tip = tip .. " (City-State)" end
	btn:SetToolTipString(tip)
	btn:SetHide(false)
end

local function FillSide(side, pids, moreLabel)
	local prefix = (side == 1) and "Our" or "Their"
	local majors, allies = {}, {}
	for _, pid in ipairs(pids) do
		if Players[pid]:IsMinorCiv() then allies[#allies + 1] = pid else majors[#majors + 1] = pid end
	end

	-- civ column
	local n    = math.min(#majors, MAJOR_SLOTS)
	local size = CIV_ICON
	local step = CIV_STEP
	if n > 1 then step = math.min(step, (POP.COL_H - size) / (n - 1)) end
	local total = size + math.max(n - 1, 0) * step
	local top   = POP.COL_Y + (POP.COL_H - total) / 2
	for i = 1, MAJOR_SLOTS do
		local btn, img = Controls[prefix .. i], Controls[prefix .. i .. "I"]
		if i <= n then
			PlaceSlot(btn, img, majors[i], size, POP.COL_X[side] - size / 2, top + (i - 1) * step)
		else
			btn:SetHide(true)
		end
	end

	-- city-state row
	local m = math.min(#allies, ALLY_SLOTS)
	local rowW = m * 24 + math.max(m - 1, 0) * 4
	local startX = POP.CS_X[side] + (POP.CS_W - rowW) / 2
	for i = 1, ALLY_SLOTS do
		local btn, img = Controls[prefix .. "CS" .. i], Controls[prefix .. "CS" .. i .. "I"]
		if i <= m then
			PlaceSlot(btn, img, allies[i], 24, startX + (i - 1) * 28, POP.CS_Y)
		else
			btn:SetHide(true)
		end
	end

	local extra = math.max(0, #majors - MAJOR_SLOTS) + math.max(0, #allies - ALLY_SLOTS)
	moreLabel:SetText(extra > 0 and ("+" .. extra .. " more") or "")
end

local function MajorsOnly(pids)
	local out = {}
	for _, pid in ipairs(pids) do
		if not Players[pid]:IsMinorCiv() then out[#out + 1] = pid end
	end
	return out
end

local function PopulatePopup(c)
	local ourPids   = CollectSide({ [ActiveTeam()] = true })
	local theirPids = CollectSide(c.enemyTeams)

	Controls.PopupTitle:SetText(c.name)
	local line1, line2 = WrapTwoLines(c.flavor or "", 46)
	Controls.PopupSub:SetText(line1)
	Controls.PopupSub2:SetText(line2)

	-- icons: city-states hidden unless CFG.SHOW_CITY_STATES
	if CFG.SHOW_CITY_STATES then
		FillSide(1, ourPids,   Controls.OurMore)
		FillSide(2, theirPids, Controls.TheirMore)
	else
		FillSide(1, MajorsOnly(ourPids),   Controls.OurMore)
		FillSide(2, MajorsOnly(theirPids), Controls.TheirMore)
	end

	-- stats: city-state allies counted unless CFG.COUNT_CITY_STATES_IN_STATS = false
	if not CFG.COUNT_CITY_STATES_IN_STATS then
		ourPids, theirPids = MajorsOnly(ourPids), MajorsOnly(theirPids)
	end
	local us, them = SideStats(ourPids), SideStats(theirPids)
	Controls.OurArmies:SetText(Fmt(us.armies));      Controls.TheirArmies:SetText(Fmt(them.armies))
	Controls.OurNavies:SetText(Fmt(us.navies));      Controls.TheirNavies:SetText(Fmt(them.navies))
	Controls.OurProduction:SetText(Fmt(us.prod));    Controls.TheirProduction:SetText(Fmt(them.prod))
	Controls.OurLand:SetText(Fmt(us.land));          Controls.TheirLand:SetText(Fmt(them.land))
	Controls.OurLosses:SetText(Fmt(c.lossesOur));    Controls.TheirLosses:SetText(Fmt(c.lossesTheir))
end

-------------------------------------------------
-- Popup open / close
-------------------------------------------------
local function FindByID(id)
	for _, c in ipairs(g_Conflicts) do if c.id == id then return c end end
end

local function StopCloseTimer()
	ContextPtr:ClearUpdate()
end

function ClosePopup(instant)
	if g_OpenID == nil then return end
	g_OpenID = nil
	if instant then
		StopCloseTimer()
		Controls.PopupWrap:SetHide(true)
		Controls.BackdropWrap:SetHide(true)
		return
	end
	Controls.BackdropWrap:SetHide(true)
	Controls.PopupAlpha:Reverse()
	Controls.PopupSlide:Reverse()
	g_CloseTimer = 0
	ContextPtr:SetUpdate(function(dt)
		g_CloseTimer = g_CloseTimer + dt
		if g_CloseTimer >= CFG.CLOSE_TIME then
			StopCloseTimer()
			Controls.PopupWrap:SetHide(true)
		end
	end)
end

function TogglePopup(id)
	if not Ready() then return end
	if g_OpenID == id then ClosePopup(false) return end
	local c = FindByID(id)
	if not c then return end
	StopCloseTimer()
	g_OpenID = id
	PopulatePopup(c)
	Controls.BackdropWrap:SetHide(false)
	Controls.PopupWrap:SetHide(false)
	Controls.PopupAlpha:SetToBeginning()
	Controls.PopupSlide:SetToBeginning()
	Controls.PopupAlpha:Play()
	Controls.PopupSlide:Play()
end

Controls.CloseButton:RegisterCallback(Mouse.eLClick, function() ClosePopup(false) end)
Controls.Backdrop:RegisterCallback(Mouse.eLClick,    function() ClosePopup(false) end)

ContextPtr:SetInputHandler(function(uiMsg, wParam)
	if g_OpenID ~= nil and uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE then
		ClosePopup(false)
		return true
	end
	return false
end)

-------------------------------------------------
-- Events
-------------------------------------------------
-- Assumes team1 = the declaring team (how the engine raises it). If a build ever reports
-- it the other way round, flip `weAttacked` below.
Events.WarStateChanged.Add(function(team1, team2, isAtWar)
	if not Ready() then return end
	local me = ActiveTeam()
	if team1 ~= me and team2 ~= me then return end
	local other = (team1 == me) and team2 or team1

	if isAtWar then
		if not TeamHasMajorCiv(other) then return end   -- ignore city-states, barbarians and dead teams
		local weAttacked = (team1 == me)
		AddWar(other, weAttacked and "attacker" or "defender")
	else
		RemoveWar(other)
	end
	RebuildChips()
end)

-- Unit losses since the war group was created: any destroyed unit owned by either side
-- (approximate: includes disbands and civilians). Counters only, no UI work per death.
Events.SerialEventUnitDestroyed.Add(function(playerID, unitID)
	if #g_Conflicts == 0 then return end
	for _, c in ipairs(g_Conflicts) do
		local side = SideOfPlayer(c, playerID)
		if side == "our" then c.lossesOur = c.lossesOur + 1
		elseif side == "their" then c.lossesTheir = c.lossesTheir + 1 end
	end
end)

-- Once per turn: prune ended wars / dead teams, refresh the popup if it is open
Events.ActivePlayerTurnStart.Add(function()
	if not Ready() then return end
	local me = Teams[ActiveTeam()]
	local changed = false
	for i = #g_Conflicts, 1, -1 do
		local c = g_Conflicts[i]
		for t in pairs(c.enemyTeams) do
			if not TeamHasRealPlayers(t) or not me:IsAtWar(t) then
				c.enemyTeams[t] = nil
				changed = true
			end
		end
		if next(c.enemyTeams) == nil then
			if g_OpenID == c.id then ClosePopup(true) end
			table.remove(g_Conflicts, i)
		end
	end
	if changed then RebuildChips() end
	if g_OpenID then
		local c = FindByID(g_OpenID)
		if c then PopulatePopup(c) end
	end
end)

-- Hotseat / active player swap
Events.GameplaySetActivePlayer.Add(function()
	ClosePopup(true)
	ScanExistingWars()
end)

Events.SequenceGameInitComplete.Add(ScanExistingWars)
ScanExistingWars()