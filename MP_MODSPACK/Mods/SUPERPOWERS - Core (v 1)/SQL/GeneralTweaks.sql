-- Insert SQL Rules Here 

--Faster Aircraft Animation
UPDATE ArtDefine_UnitMemberCombats SET MoveRate = 2*MoveRate;
UPDATE ArtDefine_UnitMemberCombats SET TurnRateMin = 2*TurnRateMin WHERE MoveRate > 0;
UPDATE ArtDefine_UnitMemberCombats SET TurnRateMax = 2*TurnRateMax WHERE MoveRate > 0;










UPDATE Units SET Moves=3 WHERE Type='UNIT_CARAVAN';
UPDATE Units SET Moves=6 WHERE Type='UNIT_CARGO_SHIP';



--UPDATE ArtDefine_UnitMemberInfos SET Granny = '' WHERE Type = 'ART_DEF_UNIT_MEMBER_U_DANISH_LONGBOAT';

