-- ==================================================================================================================================================================
-- Unit Infos

INSERT INTO ArtDefine_UnitInfos (Type, DamageStates) VALUES ('ART_DEF_UNIT_SMAN_EU_FIRESHIP', 3);
	
INSERT INTO ArtDefine_UnitInfoMemberInfos VALUES ('ART_DEF_UNIT_SMAN_EU_FIRESHIP', 'ART_DEF_UNIT_MEMBER_SMAN_EU_FIRESHIP', "1");
	
INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset) VALUES ('ART_DEF_UNIT_SMAN_EU_FIRESHIP', 'Unit', 'sv_sea_mercenary.dds');


-- ==================================================================================================================================================================
-- Unit Member Infos

INSERT INTO ArtDefine_UnitMemberInfos (Type,			Scale,		ZOffset,		Domain,		Model,							MaterialTypeTag,	 MaterialTypeSoundOverrideTag)	
	SELECT	('ART_DEF_UNIT_MEMBER_SMAN_EU_FIRESHIP'),	'0.15',		ZOffset,		Domain,		('SMAN_EU_Fireship.fxsxml'),	MaterialTypeTag,	 MaterialTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberInfos WHERE Type = 'ART_DEF_UNIT_MEMBER_CARAVEL';


INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType,	EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation)
	SELECT	('ART_DEF_UNIT_MEMBER_SMAN_EU_FIRESHIP'),		EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, '1',				'10',			AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation
	FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_CARAVEL');


INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType,	"Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag)
	SELECT ('ART_DEF_UNIT_MEMBER_SMAN_EU_FIRESHIP'),			"Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_CARAVEL');