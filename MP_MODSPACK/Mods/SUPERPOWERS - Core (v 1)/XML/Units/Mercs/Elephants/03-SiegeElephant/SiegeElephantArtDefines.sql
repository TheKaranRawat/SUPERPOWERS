-- Insert SQL Rules Here 

INSERT INTO ArtDefine_UnitInfos(Type, DamageStates, Formation)
  VALUES ('ART_DEF_UNIT_SMAN_EU_SIEGE_ELEPHANT', 1, 'ChariotElephant');

INSERT INTO ArtDefine_UnitInfoMemberInfos(UnitInfoType, UnitMemberInfoType, NumMembers)
  VALUES ('ART_DEF_UNIT_SMAN_EU_SIEGE_ELEPHANT', 'ART_DEF_UNIT_MEMBER_SMAN_EU_SIEGE_ELEPHANT', 2);

INSERT INTO ArtDefine_UnitMemberInfos(Type, Scale, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_EU_SIEGE_ELEPHANT', 0.119999997317791, 'SMAN_EU_Siege_Elephant.fxsxml', 'CLOTH', 'FLESH');

INSERT INTO ArtDefine_UnitMemberCombats(UnitMemberType, EnableActions, MoveRadius, ShortMoveRadius, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasStationaryMelee, HasRefaceAfterCombat, OnlyTurnInMovementActions)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_EU_SIEGE_ELEPHANT', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady Walk', 7.0, 24.0, 0.349999994039536, 0.5, 0.75, 15.0, 20.0, 12.0, 1, 1, 1, 1, 1);

INSERT INTO ArtDefine_UnitMemberCombatWeapons(UnitMemberType, "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax, WeaponTypeTag, WeaponTypeSoundOverrideTag)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_EU_SIEGE_ELEPHANT', 0, 0, 10.0, 20.0, 'METAL', 'ARROW');

INSERT INTO ArtDefine_UnitMemberCombatWeapons(UnitMemberType, "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax, WeaponTypeTag, MissTargetSlopRadius)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_EU_SIEGE_ELEPHANT', 1, 0, 10.0, 20.0, 'FLAMING_ARROW', 10.0);


  

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset) VALUES ('ART_DEF_UNIT_SMAN_EU_SIEGE_ELEPHANT', "Unit", 'sv_sman_elephant.dds');