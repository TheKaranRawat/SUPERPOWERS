
-- Unit Art Defines
INSERT INTO ArtDefine_UnitInfos (Type, DamageStates, Formation) VALUES ('ART_DEF_UNIT_SMAN_PATROL_BOAT', 1, "TwoBigGuns");

INSERT INTO ArtDefine_UnitInfoMemberInfos VALUES ('ART_DEF_UNIT_SMAN_PATROL_BOAT', 'ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT', 1);

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset) VALUES ('ART_DEF_UNIT_SMAN_PATROL_BOAT', 'Unit', 'sv_sea_mercenary.dds');


-- Unit Member Art Defines
INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale , Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
	VALUES ('ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT', 0.08999, 'Sea', 'Assets/Units/Transport/Transport.fxsxml', 'METAL', 'METALLRG');


--INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions, DisableActions,	HasShortRangedAttack, HasLeftRightAttack, HasRefaceAfterCombat, HasIndependentWeaponFacing, RushAttackFormation)
--VALUES ('ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady AttackSurfaceToAir', '', 1, 1, 0, 1, '');

INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation)
	SELECT	('ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT'), EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation
	FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_TRANSPORT');


--INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, HitEffect, WeaponTypeTag, WeaponTypeSoundOverrideTag)
--VALUES 
--	('ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT', 0, 0, '', 25, 50, NULL, 'ART_DEF_VEFFECT_ARTILLERY_IMPACT_$(TERRAIN)', 'EXPLOSIVE', 'EXPLOSION1TON'),
--	('ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT', 1, 0, '', 25, 50, NULL, 'ART_DEF_VEFFECT_ARTILLERY_IMPACT_$(TERRAIN)', 'BULLETHC', 'BULLETHC');

INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag)
	SELECT ('ART_DEF_UNIT_MEMBER_SMAN_PATROL_BOAT'), "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_TRANSPORT');




