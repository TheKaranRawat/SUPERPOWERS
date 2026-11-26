if not IconHookup then
	include "IconHookup"
end
local IconHookup = IconHookup
local GetMousePos = UIManager.GetMousePos
--local ScreenWidth = UIManager.GetScreenSizeVal()

local pi = math.pi
local cos = math.cos
local sin = math.sin
local min = math.min

local function SetMark( line, size, percent, label, text )
	local r1 = size * 0.43
	local r2 = size * 0.47
	local angle = percent * pi * 2
	local x = sin( angle )
	local y = -cos( angle )
	line:SetEndVal( r1 * x, r1 * y )
	label:SetOffsetVal( r2 * x, r2 * y )
	label:SetText( text )
end
function ShowProgress( size, LossMeter, ProgressMeter, Line1, Label1, Line2, Label2, turnsRemaining, cost, progress, change, loss )
	local showLine1, showLine2, showLossMeter, showProgressMeter
	if turnsRemaining then
		local progressNext = progress + change
		if turnsRemaining > 0 then
			showProgressMeter = true
			if change ~= 0 then
				local overflow = change * turnsRemaining + progress - cost
				if change > 0 then
					SetMark( Line2, size, overflow / cost, Label2, turnsRemaining )
					showLine2 = true
					if turnsRemaining > 1 and change/cost > .03 then
						SetMark( Line1, size, ( overflow - change ) / cost, Label1, turnsRemaining - 1 )
						showLine1 = true
					end
				else
					SetMark( Line1, size, overflow / cost, Label1, turnsRemaining )
					showLine1 = true
					if turnsRemaining > 1 and change/cost < -.03 then
						SetMark( Line2, size, ( overflow - change ) / cost, Label2, turnsRemaining - 1 )
						showLine2 = true
					end
					loss = change
					progress = progressNext
				end
			end
			ProgressMeter:SetPercents( min(1, progress / cost), progressNext / cost )
		end
		if loss and loss < 0 then
			showLossMeter = true
			LossMeter:SetPercent( min(1, ( progressNext - loss ) / cost ) )
		end
	end
	LossMeter:SetHide( not showLossMeter )
	ProgressMeter:SetHide( not showProgressMeter )
	Line1:SetHide( not showLine1 )
	Label1:SetHide( not showLine1 )
	Line2:SetHide( not showLine2 )
	Label2:SetHide( not showLine2 )
end
local ShowProgress = ShowProgress

function ShowProgressToolTip( controls, size, portraitOffset, portraitAtlas, text, ... )
	controls.ItemPortrait:SetHide( not ( portraitAtlas and IconHookup( portraitOffset, size, portraitAtlas, controls.ItemPortrait ) ) )
	if controls.Text then
		controls.Text:SetText( text )
		if controls.Box then
			controls.Box:DoAutoSize()
		end
	end
	if controls.Meters then
		controls.Meters:SetAnchor( GetMousePos() > 300 and "L,T" or "R,T" )
	end
	return ShowProgress( size, controls.LossMeter, controls.ProgressMeter, controls.Line1, controls.Label1, controls.Line2, controls.Label2, ... )
end
