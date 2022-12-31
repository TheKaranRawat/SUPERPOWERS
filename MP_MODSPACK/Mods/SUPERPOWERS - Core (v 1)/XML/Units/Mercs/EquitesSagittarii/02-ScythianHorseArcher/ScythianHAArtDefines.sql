-- Insert SQL Rules Here 

INSERT INTO ArtDefine_UnitInfos (Type,DamageStates,Formation) VALUES ('ART_DEF_UNIT_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', 1, "DefaultCavalry");

INSERT INTO ArtDefine_UnitInfoMemberInfos VALUES ('ART_DEF_UNIT_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', 'ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', "5");

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset ) VALUES ('ART_DEF_UNIT_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', 'Unit', 'sv_auxilia.dds');

-- ==================================================================================================================================================================
-- Member Infos

INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale, ZOffset, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
	VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', .11, '', '', 'SMAN_EU_Scythian_Horse_Archer.fxsxml', "CLOTH", "FLESH");


INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions,	DisableActions,	MoveRadius,	ShortMoveRadius,	ChargeRadius,	AttackRadius,	RangedAttackRadius,	MoveRate,	ShortMoveRate,	TurnRateMin,	TurnRateMax,	TurnFacingRateMin,	TurnFacingRateMax,	RollRateMin,	RollRateMax,	PitchRateMin,	PitchRateMax,	LOSRadiusScale,	TargetRadius,	TargetHeight,	HasShortRangedAttack,	HasLongRangedAttack,	HasLeftRightAttack,	HasStationaryMelee,	HasStationaryRangedAttack,	HasRefaceAfterCombat,	ReformBeforeCombat,	HasIndependentWeaponFacing,	HasOpponentTracking,	HasCollisionAttack,	AttackAltitude,	AltitudeDecelerationDistance,	OnlyTurnInMovementActions,	RushAttackFormation)
	SELECT	('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER'), EnableActions,	DisableActions,	MoveRadius,	ShortMoveRadius,	ChargeRadius,	AttackRadius,	RangedAttackRadius,	MoveRate,	ShortMoveRate,	TurnRateMin,	TurnRateMax,	TurnFacingRateMin,	TurnFacingRateMax,	RollRateMin,	RollRateMax,	PitchRateMin,	PitchRateMax,	LOSRadiusScale,	TargetRadius,	TargetHeight,	HasShortRangedAttack,	HasLongRangedAttack,	HasLeftRightAttack,	HasStationaryMelee,	HasStationaryRangedAttack,	HasRefaceAfterCombat,	ReformBeforeCombat,	HasIndependentWeaponFacing,	HasOpponentTracking,	HasCollisionAttack,	AttackAltitude,	AltitudeDecelerationDistance,	OnlyTurnInMovementActions,	RushAttackFormation
	FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_U_MONGOLIAN_KESHIK');


INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, WeaponTypeTag, WeaponTypeSoundOverrideTag)
	VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', 0, 0, 'ARROW', 'ARROW');

INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax, WeaponTypeTag)
	VALUES ('ART_DEF_UNIT_MEMBER_EXOTIC_UNIT_SCYTHIAN_HORSE_ARCHER', 1, 0, 10, 20, 'FLAMING_ARROW');

