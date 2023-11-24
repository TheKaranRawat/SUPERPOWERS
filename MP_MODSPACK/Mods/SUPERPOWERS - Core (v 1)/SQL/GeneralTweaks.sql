-- Insert SQL Rules Here 

--Faster Aircraft Animation
UPDATE ArtDefine_UnitMemberCombats SET MoveRate = 2*MoveRate;
UPDATE ArtDefine_UnitMemberCombats SET TurnRateMin = 2*TurnRateMin WHERE MoveRate > 0;
UPDATE ArtDefine_UnitMemberCombats SET TurnRateMax = 2*TurnRateMax WHERE MoveRate > 0;







--Trade Route Scale


UPDATE Worlds SET TradeRouteDistanceMod=150 WHERE Type='WORLDSIZE_DUEL';
UPDATE Worlds SET TradeRouteDistanceMod=150 WHERE Type='WORLDSIZE_TINY';
UPDATE Worlds SET TradeRouteDistanceMod=150 WHERE Type='WORLDSIZE_SMALL';
UPDATE Worlds SET TradeRouteDistanceMod=250 WHERE Type='WORLDSIZE_STANDARD';
UPDATE Worlds SET TradeRouteDistanceMod=250 WHERE Type='WORLDSIZE_LARGE';
UPDATE Worlds SET TradeRouteDistanceMod=300 WHERE Type='WORLDSIZE_HUGE';




UPDATE GameSpeeds SET TradeRouteSpeedMod=3000 WHERE Type='GAMESPEED_QUICK';
UPDATE GameSpeeds SET TradeRouteSpeedMod=3000 WHERE Type='GAMESPEED_STANDARD';
UPDATE GameSpeeds SET TradeRouteSpeedMod=3000 WHERE Type='GAMESPEED_EPIC';
UPDATE GameSpeeds SET TradeRouteSpeedMod=3000 WHERE Type='GAMESPEED_MARATHON';


UPDATE Units SET Moves=3 WHERE Type='UNIT_CARAVAN';
UPDATE Units SET Moves=6 WHERE Type='UNIT_CARGO_SHIP';



--UPDATE ArtDefine_UnitMemberInfos SET Granny = '' WHERE Type = 'ART_DEF_UNIT_MEMBER_U_DANISH_LONGBOAT';

