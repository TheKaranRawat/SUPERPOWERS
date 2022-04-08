-- Released under GPL v3
--------------------------------------------------------------
local debug = true;

function plot_to_str(plot)
	if plot then
		return "("..plot:GetX().." ; "..plot:GetY()..")";
	else
		return "nil";
	end
end

--===============================================================================================
-- INIT-SHOW-UPDATE
--===============================================================================================
function OnUpdate()
	print("IGE_Update");
end
LuaEvents.IGE_Update.Add(OnUpdate);

function OnPingAllVersions(data)
	print("IGE_PingAllVersions, data="..getstr(data));
end
LuaEvents.IGE_PingAllVersions.Add(OnPingAllVersions);

function OnInitialize()
	print("IGE_Initialize");
	print("IGE:Gods and kings="..getstr(IGE_HasGodsAndKings));
	print("IGE:Brave new world="..getstr(IGE_HasBraveNewWorld));
end
LuaEvents.IGE_Initialize.Add(OnInitialize);

function OnShareGlobalAndOptions()
	print("IGE_ShareGlobalAndOptions");
end
LuaEvents.IGE_ShareGlobalAndOptions.Add(OnShareGlobalAndOptions);

function OnSharingGlobalAndOptions(IGE)
	print("IGE_SharingGlobalAndOptions"..", IGE="..getstr(IGE));
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(OnSharingGlobalAndOptions);

function OnShowing()
	print("IGE_Showing");
end
LuaEvents.IGE_Showing.Add(OnShowing);

function OnShowingFailure()
	print("IGE_Showing_Failure");
end
LuaEvents.IGE_Showing_Failure.Add(OnShowingFailure);

function OnClosing(takingSeat)
	print("IGE_Closing"..", takingSeat="..getstr(takingSeat));
end
LuaEvents.IGE_Closing.Add(OnClosing);

function OnClosingPreview(takingSeat)
	print("IGE_Closing_Preview"..", takingSeat="..getstr(takingSeat));
end
LuaEvents.IGE_Closing_Preview.Add(OnClosingPreview);

function OnForceQuit(takingSeat)
	print("IGE_ForceQuit"..", takingSeat="..getstr(takingSeat));
end
LuaEvents.IGE_ForceQuit.Add(OnForceQuit);

--===============================================================================================
-- INPUTS
--===============================================================================================
function OnBroadcastingMouseState(mouseOver, gridX, gridY, plot, shift)
	--print("IGE_BroadcastingMouseState"..", mouseOver="..getstr(mouseOver)..", x="..getstr(gridX)..", y="..getstr(gridY)..", shift="..getstr(shift));
end
LuaEvents.IGE_BroadcastingMouseState.Add(OnBroadcastingMouseState);

function OnSelectedPlot(plot)
	--print("IGE_SelectedPlot"..", plot="..plot_to_str(plot));
end
LuaEvents.IGE_SelectedPlot.Add(OnSelectedPlot);

function IGE_BeginPaint()
	print("IGE_BeginPaint");
end
LuaEvents.IGE_BeginPaint.Add(OnBeginPaint);

function OnPaintPlot(button, plot, shift)
	--print("IGE_PaintPlot"..", button="..getstr(button)..", plot="..plot_to_str(plot)..", shift="..getstr(shift));
end
LuaEvents.IGE_PaintPlot.Add(OnPaintPlot);

function OnPlop(button, plot, shift)
	--print("IGE_Plop"..", button="..getstr(button)..", plot="..plot_to_str(plot)..", shift="..getstr(shift));
end
LuaEvents.IGE_Plop.Add(OnPlop);

function OnSetMouseMode(mode)
	print("IGE_SetMouseMode"..", mode="..getstr(mode));
end
LuaEvents.IGE_SetMouseMode.Add(OnSetMouseMode);

function OnPushUndoStack(set)
	print("IGE_PushUndoStack"..", set="..getstr(set));
end
LuaEvents.IGE_PushUndoStack.Add(OnPushUndoStack);

function OnRedo()
	print("IGE_Redo");
end
LuaEvents.IGE_Redo.Add(OnRedo);

function OnUndo()
	print("IGE_Undo");
end
LuaEvents.IGE_Undo.Add(OnUndo);

--===============================================================================================
-- PANELS & TABS MANAGEMENT
--===============================================================================================
function OnSelectedPanel(ID)
	print("IGE_SelectedPanel"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectedPanel.Add(OnSelectedPanel);

function OnRegisterTab(ID, name, icon, group, toolTip, topData)
	print("IGE_RegisterTab"..", ID="..getstr(ID)..", name="..getstr(name)..", icon="..getstr(icon)..", group="..getstr(group));
end
LuaEvents.IGE_RegisterTab.Add(OnRegisterTab);

function OnSetTabData(data)
	print("IGE_SetTabData"..", data="..getstr(data));
end
LuaEvents.IGE_SetTabData.Add(OnSetTabData);

function OnClosePlayerSelection()
	print("IGE_ClosePlayerSelection");
end
LuaEvents.IGE_ClosePlayerSelection.Add(OnClosePlayerSelection);

function OnSetTab(tab)
	print("IGE_SetTab"..", tab="..getstr(tab));
end
LuaEvents.IGE_SetTab.Add(OnSetTab);

--===============================================================================================
-- OPTIONS
--===============================================================================================
function OnUpdateOptions(options)
	print("IGE_UpdateOptions"..", options="..getstr(options));
end
LuaEvents.IGE_UpdateOptions.Add(OnUpdateOptions);

function OnUpdatedOptions(IGE)
	print("IGE_UpdatedOptions"..", IGE="..getstr(IGE));
end
LuaEvents.IGE_UpdatedOptions.Add(OnUpdatedOptions);


--===============================================================================================
-- OTHERS
--===============================================================================================
function OnSelectPlayer(ID)
	print("IGE_SelectPlayer"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectPlayer.Add(OnSelectPlayer);

function OnSelectingPlayer(ID)
	print("IGE_SelectingPlayer"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectingPlayer.Add(OnSelectingPlayer);

function OnSelectedPlayer(ID)
	print("IGE_SelectedPlayer"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectedPlayer.Add(OnSelectedPlayer);

function OnToggleRevealMap(revealMap)
	print("IGE_ToggleRevealMap"..", revealMap="..getstr(revealMap));
end
LuaEvents.IGE_ToggleRevealMap.Add(OnToggleRevealMap);

function OnModifiedPlot(plot)
	print("IGE_ModifiedPlot"..", plot="..plot_to_str(plot));
end
LuaEvents.IGE_ModifiedPlot.Add(OnModifiedPlot);

function OnFlashPlot(plot)
	print("IGE_FlashPlot"..", plot="..plot_to_str(plot));
end
LuaEvents.IGE_FlashPlot.Add(OnFlashPlot);

function OnSchedule(frames, timeSpan, callback)
	print("IGE_Schedule"..", frames="..getstr(frames)..", timeSpan="..getstr(timeSpan)..", callback="..getstr(callback));
end
LuaEvents.IGE_Schedule.Add(OnSchedule);

function OnForceRevealMap(reveal, removeFoW)
	print("IGE_ForceRevealMap"..", reveal="..getstr(reveal)..", removeFoW="..getstr(removeFoW));
end
LuaEvents.IGE_ForceRevealMap.Add(OnForceRevealMap);

function OnConfirmPopup(text, yesCallback)
	print("IGE_ConfirmPopup"..", text="..getstr(text)..", yesCallback="..getstr(yesCallback));
end
LuaEvents.IGE_ConfirmPopup.Add(OnConfirmPopup);

function OnWonderPopup(buildingID)
	print("IGE_WonderPopup"..", buildingID="..getstr(buildingID));
end
LuaEvents.IGE_WonderPopup.Add(OnWonderPopup);

function OnChooseReligionPopup(player, city)
	print("IGE_ChooseReligionPopup"..", player="..getstr(player)..", city="..getstr(city));
end
LuaEvents.IGE_ChooseReligionPopup.Add(OnChooseReligionPopup);

function OnChoosePantheonPopup(player)
	print("IGE_ChoosePantheonPopup"..", player="..getstr(player));
end
LuaEvents.IGE_ChoosePantheonPopup.Add(OnChoosePantheonPopup);

function OnFloatingError(text)
	print("IGE_FloatingMessage"..", text="..getstr(text));
end
LuaEvents.IGE_FloatingMessage.Add(OnFloatingError)

function OnResizedReseedElement(w, h)
	print("IGE_ResizedReseedElement"..", w="..getstr(w)..", h="..getstr(h));
end
LuaEvents.IGE_ResizedReseedElement.Add(OnResizedReseedElement);