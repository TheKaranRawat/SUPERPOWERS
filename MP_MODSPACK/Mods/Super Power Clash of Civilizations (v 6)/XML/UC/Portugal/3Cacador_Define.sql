INSERT OR REPLACE INTO ArtDefine_StrategicView 
			(StrategicViewType, 				TileType,	Asset)
VALUES		('ART_DEF_UNIT_4UC_CACADOR', 	'Unit', 	'sv_3UC_CACADOR.dds');
--==========================================================================================================================
-- ArtDefine_UnitInfos
--==========================================================================================================================	
INSERT OR REPLACE INTO ArtDefine_UnitInfos 
			(Type,							DamageStates, Formation)
SELECT		('ART_DEF_UNIT_4UC_CACADOR'),	DamageStates, Formation
FROM "ArtDefine_UnitInfos" WHERE (Type = 'ART_DEF_UNIT_RIFLEMAN');
--==========================================================================================================================
-- ArtDefine_UnitInfos
--==========================================================================================================================	
INSERT OR REPLACE INTO ArtDefine_UnitInfoMemberInfos 
			(UnitInfoType,					UnitMemberInfoType,					NumMembers)
SELECT		('ART_DEF_UNIT_4UC_CACADOR'),	('ART_DEF_UNIT_MEMBER_4UC_CACADOR'),	NumMembers
FROM ArtDefine_UnitInfoMemberInfos WHERE (UnitInfoType = 'ART_DEF_UNIT_RIFLEMAN');
--==========================================================================================================================
-- ArtDefine_UnitMemberCombats
--==========================================================================================================================	
INSERT OR REPLACE INTO ArtDefine_UnitMemberCombats 
			(UnitMemberType,					EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation)
SELECT		('ART_DEF_UNIT_MEMBER_4UC_CACADOR'),	EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation
FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_RIFLEMAN');
--==========================================================================================================================
-- ArtDefine_UnitMemberCombatWeapons
--==========================================================================================================================	
INSERT OR REPLACE INTO ArtDefine_UnitMemberCombatWeapons	
			(UnitMemberType,					"Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag)
SELECT		('ART_DEF_UNIT_MEMBER_4UC_CACADOR'),	"Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag
FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_RIFLEMAN');
--==========================================================================================================================
-- ArtDefine_UnitMemberInfos
--==========================================================================================================================	
INSERT OR REPLACE INTO ArtDefine_UnitMemberInfos 	
			(Type, 								Scale, ZOffset, Domain, Model, 				MaterialTypeTag, MaterialTypeSoundOverrideTag)
SELECT		('ART_DEF_UNIT_MEMBER_4UC_CACADOR'),	Scale, ZOffset, Domain, ('ausgw1.fxsxml'),	MaterialTypeTag, MaterialTypeSoundOverrideTag
FROM ArtDefine_UnitMemberInfos WHERE (Type = 'ART_DEF_UNIT_MEMBER_RIFLEMAN');
--==========================================================================================================================	
-- IconTextureAtlases
--==========================================================================================================================	
INSERT OR REPLACE INTO IconTextureAtlases 
			(Atlas, 									IconSize, 	Filename, 								IconsPerRow, 	IconsPerColumn)
VALUES		('4UC_CACADOR_ATLAS', 						256, 		'4CACADOR256.dds',					1, 				1),
			('4UC_CACADOR_ATLAS', 						128, 		'4CACADOR128.dds',					1, 				1),
			('4UC_CACADOR_ATLAS', 						80, 		'4CACADOR80.dds',					1, 				1),
			('4UC_CACADOR_ATLAS', 						45, 		'4CACADOR45.dds',					1, 				1),
			('4UC_CACADOR_ATLAS', 						64, 		'4CACADOR64.dds',					1, 				1),
			('UNITS_4UC_CACADOR_FLAG_ATLAS', 		32, 		'Unit_CACADOR_Flag_4UC_32.dds',				1, 				1);
--==========================================================================================================================	
--==========================================================================================================================	
INSERT OR REPLACE INTO Civilization_UnitClassOverrides 
			(CivilizationType, 			UnitClassType, 			UnitType)
VALUES		('CIVILIZATION_PORTUGAL', 	'UNITCLASS_RIFLEMAN', 	'UNIT_4UC_CACADOR');
			--==========================================================================================================================
-- Units
--==========================================================================================================================
INSERT OR REPLACE INTO Units 	
			(Class, Type, 					PrereqTech, Combat, Cost, 	FaithCost, 	RequiresFaithPurchaseEnabled, Moves, HurryCostModifier,	CombatClass, Domain, DefaultUnitAI, Description, 					Civilopedia, 					Strategy, 							Help, 							MilitarySupport, MilitaryProduction, Pillage, ObsoleteTech, AdvancedStartCost, GoodyHutUpgradeUnitClass, CombatLimit, XPValueAttack, XPValueDefense, Conscription, UnitArtInfo, 				UnitFlagAtlas, 						UnitFlagIconOffset, PortraitIndex, 	IconAtlas, 				MoveRate)
SELECT		Class, 	('UNIT_4UC_CACADOR'),	PrereqTech, Combat, Cost, 	FaithCost, 	RequiresFaithPurchaseEnabled, Moves, HurryCostModifier,	CombatClass, Domain, DefaultUnitAI, ('TXT_KEY_4UC_CACADOR'),	('TXT_KEY_4UC_CACADOR_TEXT'),	('TXT_KEY_4UC_CACADOR_STRATEGY'),	('TXT_KEY_4UC_CACADOR_HELP'),	MilitarySupport, MilitaryProduction, Pillage, ObsoleteTech, AdvancedStartCost, GoodyHutUpgradeUnitClass, CombatLimit, XPValueAttack, XPValueDefense, Conscription, ('ART_DEF_UNIT_4UC_CACADOR'),	('UNITS_4UC_CACADOR_FLAG_ATLAS'), 	0,					0, 				('4UC_CACADOR_ATLAS'), 	MoveRate
FROM Units WHERE (Type = 'UNIT_RIFLEMAN');
--==========================================================================================================================
-- UnitGameplay2DScripts
--==========================================================================================================================	
INSERT OR REPLACE INTO UnitGameplay2DScripts 	
			(UnitType, 					SelectionSound, FirstSelectionSound)
SELECT		('UNIT_4UC_CACADOR'), 		SelectionSound, FirstSelectionSound
FROM UnitGameplay2DScripts WHERE (UnitType = 'UNIT_RIFLEMAN');	
--==========================================================================================================================
-- Unit_AITypes
--==========================================================================================================================	
INSERT OR REPLACE INTO Unit_AITypes 	
			(UnitType, 				UnitAIType)
SELECT		('UNIT_4UC_CACADOR'),	UnitAIType
FROM Unit_AITypes WHERE (UnitType = 'UNIT_RIFLEMAN');
--==========================================================================================================================
-- Unit_Flavors
--==========================================================================================================================	
INSERT OR REPLACE INTO Unit_Flavors 	
			(UnitType, 				FlavorType,	Flavor)
SELECT		('UNIT_4UC_CACADOR'),	FlavorType,	Flavor
FROM Unit_Flavors WHERE (UnitType = 'UNIT_RIFLEMAN');	
--==========================================================================================================================
-- Unit_FreePromotions
--==========================================================================================================================	
INSERT OR REPLACE INTO Unit_FreePromotions 
			(UnitType, 				PromotionType)
VALUES		('UNIT_4UC_CACADOR', 	'PROMOTION_4UC_CACADOR');

INSERT OR REPLACE INTO UnitPromotions 
			(Type, 						Description, 					Help, 									Sound, 			 	LostWithUpgrade, CannotBeChosen, PortraitIndex, 	IconAtlas, 			PediaType, 			PediaEntry)
VALUES		('PROMOTION_4UC_CACADOR',	'TXT_KEY_PROMOTION_4UC_CACADOR',	'TXT_KEY_PROMOTION_4UC_CACADOR_HELP',	'AS2D_IF_LEVELUP', 			0,				1, 				59, 			'ABILITY_ATLAS', 	'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_4UC_CACADOR');

INSERT OR REPLACE INTO UnitPromotions_Terrains
		(PromotionType,		TerrainType,	Attack,		Defense)
VALUES	('PROMOTION_4UC_CACADOR', 'TERRAIN_DESERT', 20, 20),
		('PROMOTION_4UC_CACADOR', 'TERRAIN_PLAINS', 20, 20);

--==========================================================================================================================
-- Unit_ClassUpgrades
--==========================================================================================================================	
INSERT OR REPLACE INTO Unit_ClassUpgrades 	
			(UnitType, 				UnitClassType)
SELECT		('UNIT_4UC_CACADOR'),	UnitClassType
FROM Unit_ClassUpgrades WHERE (UnitType = 'UNIT_RIFLEMAN');	
--==========================================================================================================================	
--==========================================================================================================================	