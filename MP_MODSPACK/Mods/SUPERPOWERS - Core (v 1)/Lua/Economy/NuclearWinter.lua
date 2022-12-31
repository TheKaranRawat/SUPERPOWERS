-- Nuclear Winter

--------------------------------------------------------------
function CountFalloutPlots() -------Count the Fallout plots on the map

	local iFallout = 0

	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotLoop);
		local featureType = plot:GetFeatureType();

		if ( featureType == FeatureTypes.FEATURE_FALLOUT ) then
			iFallout = iFallout + 1	
		end	
	end	
	print("Fallout Plots:"..iFallout)
	return iFallout	
end


function NukeExploded()----------When nuke exploded, start the counter
	local MapTotalPlots = Map.GetNumPlots() 
--	local TotallandPlots = Map.GetNumLandAreas()                   -------------get the total number of plots 

	print ("Map Plots:" ..MapTotalPlots)
--	print ("land Area" ..TotallandPlots)
	local FalloutTotal = CountFalloutPlots()
	local FalloutPerCent = FalloutTotal/MapTotalPlots
	print ("Fallout Percent:"..FalloutPerCent)
	
	if FalloutPerCent > 0.005 and FalloutPerCent <= 0.01 then
		PlayerNotice(0)	
	elseif  FalloutPerCent > 0.01 and FalloutPerCent <= 0.05 then	  ------------------------When the fallout plots reaches beyond the thershold, trigger the nuclear winter
		NuclearWinterLV1()
		PlayerNotice(1)	
	elseif FalloutPerCent > 0.05 and FalloutPerCent <= 0.1 then
		NuclearWinterLV2()
		PlayerNotice(2)	
	elseif FalloutPerCent > 0.1 then
		NuclearWinterLV3()	
		PlayerNotice(3)	
	end
	
end
GameEvents.NuclearDetonation.Add(NukeExploded)




function NuclearWinterLV1()
	print ( "Nuclear Winter Strikes: LV1")
	
	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotLoop);
		local FoodYield = plot:GetYield(YieldTypes.YIELD_FOOD) ---------All plots with Food Yield >4 will reduce its food yield to 4

		if ( FoodYield > 3 ) then
			local pPlotX = plot:GetX()
			local pPlotY = plot:GetY()
			Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, -1)
		end	
	end	
end

function NuclearWinterLV2()
	print ( "Nuclear Winter Strikes: LV2")
	
	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotLoop);
		local FoodYield = plot:GetYield(YieldTypes.YIELD_FOOD) ---------All plots with Food Yield >1 will reduce its food yield to 1

		if ( FoodYield > 1 ) then
			local pPlotX = plot:GetX()
			local pPlotY = plot:GetY()
			Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, -1)
		end	
	end	
end

function NuclearWinterLV3()
	print ( "Nuclear Winter Strikes: LV3")
	
	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotLoop);
		local FoodYield = plot:GetYield(YieldTypes.YIELD_FOOD) ---------All plots reduce its food yield to 0!
		local ProductionYield = plot:GetYield(YieldTypes.YIELD_PRODUCTION) ---------All plots reduce its production yield to 0!

		if ( FoodYield > 0 ) then
			local pPlotX = plot:GetX()
			local pPlotY = plot:GetY()
			Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, -1)
		end	
		if ( ProductionYield > 0 ) then
			local pPlotX = plot:GetX()
			local pPlotY = plot:GetY()
			Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, -1)
		end	
		
	end	
end

function PlayerNotice(iCounter)
	local player = Players[Game.GetActivePlayer()]
	if iCounter == 0 then	
		local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER" )
	    local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_SHORT")
		player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, heading, -1, -1); 
	elseif iCounter == 1 then
		local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_LV1" )
	    local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_LV1_SHORT")
		player:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, -1, -1); 
	elseif iCounter == 2 then
		local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_LV2" )
	    local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_LV2_SHORT")
		player:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, -1, -1); 	
	elseif iCounter == 3 then
		local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_LV3" )
	    local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_NUCLEAR_WINTER_LV3_SHORT")
		player:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, -1, -1); 	
	end	
	
end


















print("Nuclear Winter Check Pass!")


