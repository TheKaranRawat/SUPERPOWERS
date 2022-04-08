-- Released under GPL v3
--------------------------------------------------------------
function OnShareGlobalAndOptions()
	LuaEvents.IGE_SharingGlobalAndOptions(IGE);
end
LuaEvents.IGE_ShareGlobalAndOptions.Add(OnShareGlobalAndOptions);

--------------------------------------------------------------
function OnPingAllVersions(data)
	data.count = data.count + 1;
end
LuaEvents.IGE_PingAllVersions.Add(OnPingAllVersions);

--------------------------------------------------------------
function OnInitialize()
	StorePlayer();
	Game.SetName("Schmurtz")
end
LuaEvents.IGE_Initialize.Add(OnInitialize);

-------------------------------------------------------------------------------------------------
function OnShowing()
	StorePlayer();
end
LuaEvents.IGE_Showing.Add(OnShowing);

-------------------------------------------------------------------------------------------------
function StorePlayer()
	local ID = Game.GetActivePlayer();
	local player = Players[ID];

	if player:IsHuman() then
		IGE.humanPlayerID = ID;
		IGE.humanPlayer = player;
	end
	IGE.initialPlayerID = ID;
	IGE.initialPlayer = player;

	IGE.currentPlayerID = ID;
	IGE.currentPlayer = player;
	IGE.currentTeamID = Players[ID]:GetTeam()
	IGE.currentTeam = Teams[IGE.currentTeamID]
end

-------------------------------------------------------------------------------------------------
function OnSelectPlayer(ID, isShowing)
	local newPlayer = Players[ID]
	local safeMode = newPlayer:IsBarbarian() or newPlayer:IsMinorCiv() or IGE.safeMode

	LuaEvents.IGE_SelectingPlayer(ID, not safeMode);
	IGE.currentPlayerID = ID;
	IGE.currentPlayer = newPlayer;
	IGE.currentTeamID = newPlayer:GetTeam()
	IGE.currentTeam = Teams[IGE.currentTeamID]

	-- Barbarian fix
	if not safeMode then
		Game.SetActivePlayer(ID);
	end

	LuaEvents.IGE_SelectedPlayer(ID, not safeMode);
	LuaEvents.IGE_ClosePlayerSelection();
end
LuaEvents.IGE_SelectPlayer.Add(OnSelectPlayer);



--===============================================================================================
-- OPTIONS
--===============================================================================================
local db = Modding.OpenUserData("Ingame Editor", 2);

function OnUpdateOptions(options, suppressNotification)
	-- Write updated values to the DB
	if options then
		if options.showYields ~= nil then
			db.SetValue("ShowYields",				options.showYields and "true" or "false");
		end
		if options.showResources ~= nil then
			db.SetValue("ShowResources",			options.showResources and "true" or "false");
		end
		if options.safeMode ~= nil then
			db.SetValue("SafeMode",					options.safeMode and "true" or "false");
		end
		if options.autoSave ~= nil then
			db.SetValue("AutoSave",					options.autoSave and "true" or "false");
		end
		if options.disableStrategicView ~= nil then
			db.SetValue("DisableStrategicView",		options.disableStrategicView and "true" or "false");
		end
		if options.showUnknownResources ~= nil then
			db.SetValue("ShowUnknownResources",		options.showUnknownResources and "true" or "false");
		end
		if options.cleanUpFiles ~= nil then
			db.SetValue("CleanUpFiles",				options.cleanUpFiles and "true" or "false");
		end
	end

	-- Fetch options from the DB and broadcast them
	IGE.showYields = db.GetValue("ShowYields") ~= "false";
	IGE.showResources = db.GetValue("ShowResources") ~= "false";
	IGE.showUnknownResources = db.GetValue("ShowUnknownResources") ~= "false";
	IGE.disableStrategicView = db.GetValue("DisableStrategicView") == "true";
	IGE.cleanUpFiles = db.GetValue("CleanUpFiles") == "true";
	IGE.autoSave = db.GetValue("AutoSave") ~= "false";
	IGE.safeMode = db.GetValue("SafeMode") == "true";

	if not suppressNotification then
		LuaEvents.IGE_UpdatedOptions(IGE);
	end
end
LuaEvents.IGE_UpdateOptions.Add(OnUpdateOptions);



--===============================================================================================
-- SCHEDULING
--===============================================================================================
local hooks = {};
local ticks = 0;
function OnSchedule(frames, timeSpan, callback)
	local item = { func = callback };
	if frames then 
		item.frames = frames;
	elseif timeSpan then
		item.timeSpan = timeSpan;
	else
		item.frames = -1;
	end

	table.insert(hooks, item);
	if #hooks == 1 then
		ContextPtr:SetUpdate(OnFrame);
	end
end
LuaEvents.IGE_Schedule.Add(OnSchedule);

-------------------------------------------------------------------------------------------------
function OnFrame(deltaTime)
	ticks = ticks + 1;
	--print("OnFrame "..ticks);

	local i = 1;
	while i <= #hooks do
		local trigger = false;
		local hook = hooks[i];
		if hook.frames then
			hook.frames = hook.frames - 1;
			trigger = hook.frames == 0;
		else
			hook.timeSpan = hook.timeSpan - deltaTime;
			trigger = hook.timeSpan < 0;
		end
			
		if trigger then
			print("start scheduled action");
			hook.func();
			table.remove(hooks, i);
		else
			i = i + 1;
		end
	end

	if #hooks == 0 then
		--print("clear");
		ContextPtr:ClearUpdate();
	end
end

-------------------------------------------------------------------------------------------------
OnUpdateOptions(nil, true);
