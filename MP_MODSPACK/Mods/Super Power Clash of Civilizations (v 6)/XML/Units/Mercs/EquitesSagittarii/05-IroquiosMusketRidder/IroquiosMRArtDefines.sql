-- Insert SQL Rules Here 

INSERT INTO ArtDefine_UnitInfos(Type, DamageStates, Formation) VALUES ('ART_DEF_UNIT_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 1, 'DefaultCavalry');

INSERT INTO ArtDefine_UnitInfoMemberInfos(UnitInfoType, UnitMemberInfoType, NumMembers) VALUES ('ART_DEF_UNIT_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 'ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 5);

INSERT INTO ArtDefine_StrategicView(StrategicViewType, TileType, Asset) VALUES ('ART_DEF_UNIT_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 'Unit', 'sv_auxilia.dds');


-- ==================================================================================================================================================================
-- Member Infos

INSERT INTO ArtDefine_UnitMemberInfos(Type, Scale, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag) 
	VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 0.119999997317791, 'SMAN_EU_IMR.fxsxml', 'CLOTH', 'FLESH');


INSERT INTO ArtDefine_UnitMemberCombats(UnitMemberType, EnableActions, ShortMoveRadius, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, TargetHeight, HasShortRangedAttack, HasStationaryMelee, HasRefaceAfterCombat, ReformBeforeCombat, OnlyTurnInMovementActions)
  VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady Walk', 24.0, 0.349999994039536, 0.5, 0.75, 15.0, 20.0, 12.0, 1, 1, 1, 1, 1);


INSERT INTO ArtDefine_UnitMemberCombatWeapons(UnitMemberType, "Index", SubIndex, WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius)
  VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 0, 0, 'ARROW', 'ARROW', 10.0);
--INSERT INTO ArtDefine_UnitMemberCombatWeapons(UnitMemberType, "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax, WeaponTypeTag, MissTargetSlopRadius)
--  VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_IROQUIOS_MUSKET_RIDER', 1, 0, 10.0, 20.0, 'FLAMING_ARROW', 10.0);

