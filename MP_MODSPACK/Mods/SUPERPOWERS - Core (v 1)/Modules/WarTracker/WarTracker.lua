-------------------------------------------------
-- War Tracker (UI-only, no gameplay changes => no multiplayer desync)
-- Event-driven: no per-frame update except ~0.3s while the popup closes.
-------------------------------------------------
include("IconSupport")
include("InstanceManager")

-- Not a global in UI contexts; pull it from GameDefines (nil-safe fallback)
local MAX_CIV_PLAYERS = (GameDefines and GameDefines.MAX_CIV_PLAYERS) or 64

local CFG = {
	RESPECT_FOG      = true,  -- enemy stats only count what the active player can see/has revealed
	-- In multiplayer, stats that have no legitimate per-civ source are shown as "?" instead of
	-- risking an information leak (enemy production, enemy unit losses). Set false to show them anyway.
	MP_STRICT        = true,
	MAX_CHIP_ICONS   = 3,
	MAX_MEMBER_ICONS = 10,
	CLOSE_TIME       = 0.30,
}

-- Deterministic name pools (never use Game.Rand in UI code - it would desync)
local NAMES = {
	attacker  = { "The Iron Offensive", "March of Empires", "Campaign of Conquest", "The Gilded Gauntlet", "Crown & Cannon" },
	defender  = { "Defense of the Realm", "Hearth & Standard", "The Unbroken Line", "Banner Held High", "The Long Vigil" },
	ongoing   = { "Standing Hostilities", "The Uneasy Front", "Smoldering Frontiers" },
	coalition = { "The Grand Coalition", "Concert of Foes", "The Gathering Storm", "Pact of Ruin" },
}

local g_Conflicts   = {}   -- { id, role, turn, enemyTeams = {[teamID]=true}, name, lossesOur, lossesTheir }
local g_NextID      = 1
local g_OpenID      = nil  -- conflict id whose popup is open
local g_Closing     = false
local g_CloseTimer  = 0

local g_ChipIM   = InstanceManager:new("WarChip",    "ChipRoot",   Controls.ChipStack)
local g_OurIM    = InstanceManager:new("MemberIcon", "MemberRoot", Controls.OurMembers)
local g_TheirIM  = InstanceManager:new("MemberIcon", "MemberRoot", Controls.TheirMembers)

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function ActiveTeam() return Game.GetActiveTeam() end

local function IsMultiplayer()
	return (Game.IsGameMultiPlayer ~= nil and Game.IsGameMultiPlayer())
	    or (Game.IsNetworkMultiPlayer ~= nil and Game.IsNetworkMultiPlayer())
	    or false
end

-- True once a valid active player/team exists (guards early load, observers, reconnects)
local function Ready()
	local ap = Game.GetActivePlayer()
	local at = Game.GetActiveTeam()
	return ap ~= nil and ap >= 0 and Players[ap] ~= nil and at ~= nil and at >= 0 and Teams[at] ~= nil
end

local function IsRealPlayer(p)
	return p ~= nil and p:IsAlive() and not p:IsBarbarian()
end

local function SetCivIcon(ctrl, pid, size)
	local p = Players[pid]
	if not p then return end
	local civ = GameInfo.Civilizations[p:GetCivilizationType()]
	if civ then
		IconHookup(civ.PortraitIndex, size, civ.IconAtlas, ctrl)
	end
end

local function CountSet(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

local function PickName(c)
	local pool = NAMES[c.role]
	if CountSet(c.enemyTeams) >= 3 then pool = NAMES.coalition end
	return pool[(c.turn % #pool) + 1]
end

-- Our side = our team + minors allied to it. Their side = enemy teams + minors allied to them.
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

local function OurTeamSet()   return { [ActiveTeam()] = true } end

local function SideOfPlayer(c, pid)
	-- returns "our", "their" or nil (cheap; used by the unit-loss counter)
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

-------------------------------------------------
-- Conflict bookkeeping
-------------------------------------------------
local function FindConflictFor(team)
	for _, c in ipairs(g_Conflicts) do
		if c.enemyTeams[team] then return c end
	end
end

local function TeamHasRealPlayers(team)
	for pid = 0, MAX_CIV_PLAYERS - 1 do
		local p = Players[pid]
		if IsRealPlayer(p) and p:GetTeam() == team then return true end
	end
	return false
end

local function RebuildChips()
	g_ChipIM:ResetInstances()
	if not Ready() then return end
	local WAR_ICON = "[ICON_WAR]"
	local ICON, PITCH, PAD, CHIP_H = 64, 76, 16, 96
	for _, c in ipairs(g_Conflicts) do
		local chip = g_ChipIM:GetInstance()

		local slots  = { chip.E1, chip.E2, chip.E3 }
		local swords = { chip.W1, chip.W2, chip.W3 }
		local glows  = { chip.G1, chip.G2, chip.G3 }
		local shown, total = 0, 0
		local tooltip = c.name .. " (turn " .. c.turn .. ")"
		for team in pairs(c.enemyTeams) do
			total = total + 1
			-- representative icon = first living player on that team
			for pid = 0, MAX_CIV_PLAYERS - 1 do
				local p = Players[pid]
				if IsRealPlayer(p) and p:GetTeam() == team then
					if shown < CFG.MAX_CHIP_ICONS then
						shown = shown + 1
						SetCivIcon(slots[shown], pid, ICON)
					end
					tooltip = tooltip .. "[NEWLINE]- " .. Locale.ConvertTextKey(p:GetCivilizationShortDescriptionKey())
					break
				end
			end
		end
		for i = 1, 3 do
			slots[i]:SetHide(i > shown)
			swords[i]:SetHide(i > shown)
			glows[i]:SetHide(i > shown)
			if i <= shown then swords[i]:SetText(WAR_ICON) end
		end

		-- size the chip to what is actually shown
		local more = total > shown
		chip.MoreLabel:SetText(more and ("+" .. (total - shown)) or "")
		chip.MoreLabel:SetOffsetVal(PAD + shown * PITCH - 6, 36)
		local w = shown * PITCH + PAD + (more and 36 or 0)
		chip.ChipRoot:SetSizeVal(w, CHIP_H)
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

local function AddWar(otherTeam, role)
	if FindConflictFor(otherTeam) then return end
	local turn = Game.GetGameTurn()
	local target

	if role ~= "ongoing" then
		for _, c in ipairs(g_Conflicts) do
			if c.turn == turn and c.role == role then target = c break end
		end
		-- Their ally joining our same-turn offensive belongs to that group
		if not target and role == "defender" then
			for _, c in ipairs(g_Conflicts) do
				if c.turn == turn and c.role == "attacker" then target = c break end
			end
		end
	end

	if not target then
		target = { id = g_NextID, role = role, turn = turn, enemyTeams = {}, lossesOur = 0, lossesTheir = 0 }
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

local function ScanExistingWars()
	g_Conflicts = {}
	if not Ready() then RebuildChips() return end
	local me = ActiveTeam()
	local pTeam = Teams[me]
	local done = {}
	for pid = 0, MAX_CIV_PLAYERS - 1 do
		local p = Players[pid]
		if IsRealPlayer(p) then
			local t = p:GetTeam()
			if t ~= me and not done[t] then
				done[t] = true
				if pTeam:IsHasMet(t) and pTeam:IsAtWar(t) then AddWar(t, "ongoing") end
			end
		end
	end
	RebuildChips()
end

-------------------------------------------------
-- Stats
-------------------------------------------------
-- Revealed-only land count (what the active player could work out from the map)
local function CountRevealedLand(pids, team)
	local set = {}
	for _, pid in ipairs(pids) do set[pid] = true end
	local n = 0
	for i = 0, Map.GetNumPlots() - 1 do
		local plot = Map.GetPlotByIndex(i)
		if plot ~= nil then
			local owner = plot:GetOwner()
			if owner >= 0 and set[owner] and plot:IsRevealed(team, false) then n = n + 1 end
		end
	end
	return n
end

local function SideStats(pids, isEnemy)
	local fog  = CFG.RESPECT_FOG and isEnemy
	local team = ActiveTeam()
	local s = { armies = 0, navies = 0, prod = 0, land = 0 }
	for _, pid in ipairs(pids) do
		local p = Players[pid]
		for u in p:Units() do
			if u:IsCombatUnit() then
				local ok = true
				if fog then
					local plot = u:GetPlot()
					ok = plot ~= nil and plot:IsVisible(team, false)
					-- stealth/hidden units on a visible tile must not be counted
					if ok and u.IsInvisible ~= nil and u:IsInvisible(team, false) then ok = false end
				end
				if ok then
					local d = u:GetDomainType()
					if d == DomainTypes.DOMAIN_LAND then s.armies = s.armies + 1
					elseif d == DomainTypes.DOMAIN_SEA then s.navies = s.navies + 1 end
				end
			end
		end
		if not isEnemy then
			for city in p:Cities() do
				s.prod = s.prod + city:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
			end
		elseif not (CFG.MP_STRICT and IsMultiplayer()) then
			for city in p:Cities() do
				if city:Plot():IsRevealed(team, false) then
					s.prod = s.prod + city:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
				end
			end
		end
		if not fog then s.land = s.land + p:GetTotalLand() end
	end
	if fog then s.land = CountRevealedLand(pids, team) end
	return s
end

local function Fmt(n, approx)
	if n == nil then return "?" end
	return (approx and "~" or "") .. tostring(math.floor(n + 0.5))
end

local function FillMembers(im, pids, isEnemy)
	im:ResetInstances()
	local team = Teams[ActiveTeam()]
	local shown, hiddenUnmet = 0, 0
	for _, pid in ipairs(pids) do
		local p = Players[pid]
		if isEnemy and not team:IsHasMet(p:GetTeam()) then
			hiddenUnmet = hiddenUnmet + 1
		elseif shown < CFG.MAX_MEMBER_ICONS then
			shown = shown + 1
			local inst = im:GetInstance()
			SetCivIcon(inst.MemberImg, pid, 32)
			local tip = Locale.ConvertTextKey(p:GetCivilizationShortDescriptionKey())
			if p:IsMinorCiv() then tip = tip .. " (City-State)" end
			inst.MemberRoot:SetToolTipString(tip)
		end
	end
end

local function PopulatePopup(c)
	local ourPids   = CollectSide(OurTeamSet())
	local theirPids = {}
	do
		-- never count civs/city-states the active player has not met
		local me = Teams[ActiveTeam()]
		for _, pid in ipairs(CollectSide(c.enemyTeams)) do
			if me:IsHasMet(Players[pid]:GetTeam()) then theirPids[#theirPids + 1] = pid end
		end
	end

	Controls.PopupTitle:SetText(c.name)
	local roleText = (c.role == "attacker" and "War declared by you") or (c.role == "defender" and "War declared upon you") or "Ongoing hostilities"
	Controls.PopupSub:SetText(roleText .. "  -  Turn " .. c.turn)

	FillMembers(g_OurIM,   ourPids,   false)
	FillMembers(g_TheirIM, theirPids, true)

	local us, them = SideStats(ourPids, false), SideStats(theirPids, true)
	local approx = CFG.RESPECT_FOG
	local strict = CFG.MP_STRICT and IsMultiplayer()
	if strict then them.prod = nil end
	local theirLosses = c.lossesTheir
	if strict then theirLosses = nil end
	Controls.OurArmies:SetText(Fmt(us.armies));        Controls.TheirArmies:SetText(Fmt(them.armies, approx))
	Controls.OurNavies:SetText(Fmt(us.navies));        Controls.TheirNavies:SetText(Fmt(them.navies, approx))
	Controls.OurProduction:SetText(Fmt(us.prod));      Controls.TheirProduction:SetText(Fmt(them.prod, approx))
	Controls.OurLand:SetText(Fmt(us.land));            Controls.TheirLand:SetText(Fmt(them.land, approx))
	Controls.OurLosses:SetText(Fmt(c.lossesOur));      Controls.TheirLosses:SetText(Fmt(theirLosses, approx))
	Controls.FogNote:SetText(approx and "~ based on our intelligence reports" or "")
end

-------------------------------------------------
-- Popup open / close
-------------------------------------------------
local function FindByID(id)
	for _, c in ipairs(g_Conflicts) do if c.id == id then return c end end
end

local function StopCloseTimer()
	g_Closing = false
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
	g_Closing, g_CloseTimer = true, 0
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
-- Assumes team1 = the declaring team (how the engine raises it). If a build
-- ever reports it the other way round, flip `weAttacked` below.
Events.WarStateChanged.Add(function(team1, team2, isAtWar)
	if not Ready() then return end
	local me = ActiveTeam()
	if team1 ~= me and team2 ~= me then return end
	local other = (team1 == me) and team2 or team1

	if isAtWar then
		if not TeamHasRealPlayers(other) then return end   -- ignore barbarians / dead teams
		local weAttacked = (team1 == me)
		AddWar(other, weAttacked and "attacker" or "defender")
	else
		RemoveWar(other)
	end
	RebuildChips()
end)

-- Unit losses: counts destroyed units belonging to either side while the war group exists.
-- Approximate (includes disbands/civilians). For exact kill tracking use a gameplay-side
-- GameEvents.UnitKilledInCombat hook and persist via Game.SetProperty.
Events.SerialEventUnitDestroyed.Add(function(playerID, unitID)
	if #g_Conflicts == 0 then return end
	for _, c in ipairs(g_Conflicts) do
		local side = SideOfPlayer(c, playerID)
		if side == "our" then c.lossesOur = c.lossesOur + 1
		elseif side == "their" then c.lossesTheir = c.lossesTheir + 1 end
	end
end)

-- Refresh once per turn (prune ended wars / dead teams, update open popup)
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