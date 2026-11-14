--------------------------------------------------------------
-- SettlerFoundDelay.lua
-- Blocks founding cities until a set game turn is reached.
--
-- Multiplayer safety:
--   * Only reads Game.GetGameTurn(), which is identical on every
--     client, so the result is deterministic (no desync).
--   * No state is stored, no random numbers, no UI-dependent logic.
-- Performance:
--   * One tiny GameEvents handler: a single integer comparison.
--   * No per-turn or per-unit loops.
--   * Handler is not registered at all when loading a save that is
--     already past the delay.
--
-- Entry point type: InGameUIAddin (same as your other scripts)
--------------------------------------------------------------

--[[ DISABLED FOR NOW 
local FOUND_DELAY_TURNS = 10   -- cities may be founded on this turn or later

local GetGameTurn = Game.GetGameTurn

-- Returning false disables the "Found City" action (button greyed
-- out in the UI, and the AI also cannot found). Returning true
-- leaves the normal rules untouched.
function SettlerFoundDelay_CanFound(iPlayer, iPlotX, iPlotY)
	if GetGameTurn() < FOUND_DELAY_TURNS then
		return false
	end
	return true
end

-- Skip registering when the delay has already passed (e.g. loading a late save)
if GetGameTurn() < FOUND_DELAY_TURNS then
	GameEvents.PlayerCanFound.Add(SettlerFoundDelay_CanFound)
end
print("Settler Delay Loaded ")
]]--