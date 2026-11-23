-- Insert SQL Rules Here 

--Faster Aircraft Animation
UPDATE ArtDefine_UnitMemberCombats SET MoveRate = 2*MoveRate;
UPDATE ArtDefine_UnitMemberCombats SET TurnRateMin = 2*TurnRateMin WHERE MoveRate > 0;
UPDATE ArtDefine_UnitMemberCombats SET TurnRateMax = 2*TurnRateMax WHERE MoveRate > 0;

-- Scales the trade route turns between choosing a new destination based on game speed
-- On Standard speed the trade route target turns is 30 (rounded based on actual route length)
-- On Quick speed the target turns will be 20, and on Marathon speed 90
-- The number of turns the AI remembers a plundered trade route is also scaled using this value
ALTER TABLE GameSpeeds
  ADD TradeRouteSpeedMod INTEGER DEFAULT 100;

UPDATE GameSpeeds SET TradeRouteSpeedMod=100  WHERE Type='GAMESPEED_QUICK';
UPDATE GameSpeeds SET TradeRouteSpeedMod=150 WHERE Type='GAMESPEED_STANDARD';
UPDATE GameSpeeds SET TradeRouteSpeedMod=200 WHERE Type='GAMESPEED_EPIC';
UPDATE GameSpeeds SET TradeRouteSpeedMod=250 WHERE Type='GAMESPEED_MARATHON';



UPDATE Units SET Moves=3 WHERE Type='UNIT_CARAVAN';
UPDATE Units SET Moves=6 WHERE Type='UNIT_CARGO_SHIP';



--UPDATE ArtDefine_UnitMemberInfos SET Granny = '' WHERE Type = 'ART_DEF_UNIT_MEMBER_U_DANISH_LONGBOAT';

