-- ==================================================================================================================================================================
-- Unit Infos

INSERT INTO ArtDefine_UnitInfos (Type, DamageStates, Formation) VALUES ('ART_DEF_UNIT_SMAN_EU_ARMORED_FRIGATE', 3, '');

INSERT INTO ArtDefine_UnitInfoMemberInfos (UnitInfoType, UnitMemberInfoType, NumMembers) VALUES ('ART_DEF_UNIT_SMAN_EU_ARMORED_FRIGATE', 'ART_DEF_UNIT_MEMBER_SMAN_EU_ARMORED_FRIGATE', 1);

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset) VALUES ('ART_DEF_UNIT_SMAN_EU_ARMORED_FRIGATE', 'Unit', 'sv_sea_mercenary.dds');


-- ==================================================================================================================================================================
-- Unit Member Infos

INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale , Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
VALUES ('ART_DEF_UNIT_MEMBER_SMAN_EU_ARMORED_FRIGATE', 0.11, 'Sea', 'SMAN_EU_AF_Ironclad.fxsxml', 'METAL', 'METALLRG');


INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions, DisableActions,	HasShortRangedAttack, HasLeftRightAttack, HasRefaceAfterCombat, HasIndependentWeaponFacing, RushAttackFormation)
VALUES ('ART_DEF_UNIT_MEMBER_SMAN_EU_ARMORED_FRIGATE', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady AttackSurfaceToAir', '', 1, 1, 0, 1, '');


INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, HitEffect, WeaponTypeTag, WeaponTypeSoundOverrideTag)
VALUES 
	('ART_DEF_UNIT_MEMBER_SMAN_EU_ARMORED_FRIGATE', 0, 0, '', 25, 50, NULL, 'ART_DEF_VEFFECT_ARTILLERY_IMPACT_$(TERRAIN)', 'EXPLOSIVE', 'EXPLOSION1TON'),
	('ART_DEF_UNIT_MEMBER_SMAN_EU_ARMORED_FRIGATE', 1, 0, '', 25, 50, NULL, 'ART_DEF_VEFFECT_ARTILLERY_IMPACT_$(TERRAIN)', 'BULLETHC', 'BULLETHC');

