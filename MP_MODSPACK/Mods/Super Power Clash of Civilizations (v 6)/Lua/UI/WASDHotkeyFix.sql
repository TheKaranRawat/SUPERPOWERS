UPDATE Automates SET HotKey = 'KB_P' WHERE Type = 'AUTOMATE_BUILD';					--A => Z
UPDATE Builds SET HotKey = '' WHERE Type = 'BUILD_ACADEMY';							--A => NULL
--UPDATE Builds SET HotKey = 'KB_A' WHERE Type = 'BUILD_ARCHAEOLOGY_DIG';			--Ctrl+A
--UPDATE Builds SET CtrlDown = 1 WHERE Type = 'BUILD_ARCHAEOLOGY_DIG';
UPDATE Builds SET HotKey = 'KB_X' WHERE Type = 'BUILD_SCRUB_FALLOUT';				--S => X
UPDATE Builds SET HotKey = '' WHERE Type = 'BUILD_FEITORIA';						--Z => NULL
UPDATE Builds SET HotKey = '' WHERE Type = 'BUILD_CHATEAU';							--Z => NULL
--UPDATE Controls SET HotKey = 'KB_A' WHERE Type = 'CONTROL_AUTOMOVES';				--Ctrl+A
--UPDATE Controls SET CtrlDown = 1 WHERE Type = 'CONTROL_AUTOMOVES';
UPDATE Controls SET HotKey = '' WHERE Type = 'CONTROL_CYCLEUNIT';					--W => NULL
--UPDATE Controls SET HotKey = 'KB_S' WHERE Type = 'CONTROL_SAVE_GROUP';			--Ctrl+Alt+S
--UPDATE Controls SET AltDown = 1 WHERE Type = 'CONTROL_SAVE_GROUP';
--UPDATE Controls SET CtrlDown = 1 WHERE Type = 'CONTROL_SAVE_GROUP';
--UPDATE Controls SET HotKey = 'KB_S' WHERE Type = 'CONTROL_SAVE_NORMAL';			--Ctrl+S
--UPDATE Controls SET CtrlDown = 1 WHERE Type = 'CONTROL_SAVE_NORMAL';
UPDATE InterfaceModes SET HotKey = '' WHERE Type = 'INTERFACEMODE_AIRLIFT';			--Shift+A => NULL
--UPDATE InterfaceModes SET ShiftDown = 1 WHERE Type = 'INTERFACEMODE_AIRLIFT';
UPDATE InterfaceModes SET HotKey = 'KB_X' WHERE Type = 'INTERFACEMODE_AIRSTRIKE';	--S => X
UPDATE InterfaceModes SET HotKey = 'KB_X' WHERE Type = 'INTERFACEMODE_AIR_SWEEP';	--Alt+S => Alt+X
--UPDATE InterfaceModes SET AltDown = 1 WHERE Type = 'INTERFACEMODE_AIR_SWEEP';
--UPDATE InterfaceModes SET HotKey = 'KB_A' WHERE Type = 'INTERFACEMODE_ATTACK';	--Ctrl+A
--UPDATE InterfaceModes SET CtrlDown = 1 WHERE Type = 'INTERFACEMODE_ATTACK';
UPDATE Missions SET HotKey = '' WHERE Type = 'MISSION_AIR_SWEEP';					--S? => NULL
UPDATE Missions SET HotKey = 'KB_Z' WHERE Type = 'MISSION_ALERT';					--A => Z
--UPDATE Missions SET HotKey = 'KB_D' WHERE Type = 'MISSION_DISEMBARK';				--D => Ctrl+D
UPDATE Missions SET CtrlDown = 1 WHERE Type = 'MISSION_DISEMBARK';
UPDATE Missions SET HotKey = 'KB_X' WHERE Type = 'MISSION_SET_UP_FOR_RANGED_ATTACK';--S => X