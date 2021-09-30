INSERT INTO ArtDefine_UnitInfos (Type,DamageStates,Formation)
	SELECT	('ART_DEF_UNIT_3CENTAUR'), DamageStates, Formation
	FROM ArtDefine_UnitInfos WHERE (Type = 'ART_DEF_UNIT_U_MONGOLIAN_KESHIK');

INSERT INTO ArtDefine_UnitInfoMemberInfos (UnitInfoType,UnitMemberInfoType,NumMembers)
	SELECT	('ART_DEF_UNIT_3CENTAUR'), ('ART_DEF_UNIT_MEMBER_3CENTAUR'), NumMembers
	FROM ArtDefine_UnitInfoMemberInfos WHERE (UnitInfoType = 'ART_DEF_UNIT_U_MONGOLIAN_KESHIK');

INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation)
	SELECT	('ART_DEF_UNIT_MEMBER_3CENTAUR'), EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation
	FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_U_MONGOLIAN_KESHIK');

INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag)
	SELECT ('ART_DEF_UNIT_MEMBER_3CENTAUR'), "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_U_MONGOLIAN_KESHIK');

INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale, ZOffset, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
	SELECT	('ART_DEF_UNIT_MEMBER_3CENTAUR'), Scale, ZOffset, Domain, ('HorseArcher_Mongol.fxsxml'), MaterialTypeTag, MaterialTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberInfos WHERE (Type = 'ART_DEF_UNIT_MEMBER_U_MONGOLIAN_KESHIK');

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset )
	VALUES	('ART_DEF_UNIT_3CENTAUR', 'Unit', 'IconCentaurSV.dds');


--------------------------------	
-- Units
--------------------------------
INSERT INTO Units 	
		(Type, 						Class,	 PrereqTech, RangedCombat, Range, Special, Combat, Cost, ObsoleteTech, GoodyHutUpgradeUnitClass, FaithCost, RequiresFaithPurchaseEnabled, Moves, CombatClass, Domain, DefaultUnitAI, Help, Description, 					  Civilopedia, 								Strategy, 		 									Pillage, MilitarySupport, MilitaryProduction, IgnoreBuildingDefense, Mechanized, AdvancedStartCost, RangedCombatLimit, CombatLimit, XPValueDefense, UnitArtInfo, 						UnitFlagIconOffset,	UnitFlagAtlas,						 PortraitIndex, 	IconAtlas,			 MoveRate)
SELECT	'UNIT_3CENTAUR',	Class,	  PrereqTech, 17, 2, Special, Combat, Cost, ObsoleteTech, GoodyHutUpgradeUnitClass, FaithCost, RequiresFaithPurchaseEnabled, Moves, 'UNITCOMBAT_ARCHER', Domain, 'UNITAI_RANGED', 'TXT_KEY_UNIT_3CENTAUR_HELP','TXT_KEY_UNIT_3CENTAUR', 'TXT_KEY_UNIT_3CENTAUR_TEXT',	'TXT_KEY_UNIT_3CENTAUR_STRATEGY',  	Pillage, MilitarySupport, MilitaryProduction, IgnoreBuildingDefense, Mechanized, AdvancedStartCost, RangedCombatLimit, CombatLimit, XPValueDefense, 'ART_DEF_UNIT_3CENTAUR',	0,					'3CENTAUR_FLAG',					  0, 				'3CENTAUR_ATLAS',	 MoveRate
FROM Units WHERE Type = 'UNIT_KNIGHT';
--------------------------------	
-- UnitGameplay2DScripts
--------------------------------		
INSERT INTO UnitGameplay2DScripts 	
		(UnitType, 					SelectionSound, FirstSelectionSound)
SELECT	'UNIT_3CENTAUR', 	SelectionSound, FirstSelectionSound
FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_KNIGHT';
--------------------------------		
-- Unit_AITypes
--------------------------------		
INSERT INTO Unit_AITypes 	
		(UnitType, 					UnitAIType)
VALUES	('UNIT_3CENTAUR', 	'UNITAI_RANGED'),
		('UNIT_3CENTAUR', 	'UNITAI_DEFENSE'),
		('UNIT_3CENTAUR', 	'UNITAI_FAST_ATTACK');

--------------------------------	
-- Unit_ClassUpgrades
--------------------------------	
INSERT INTO Unit_ClassUpgrades 	
		(UnitType, 					UnitClassType)
SELECT	'UNIT_3CENTAUR',	UnitClassType
FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_KNIGHT';	
--------------------------------	
-- Unit_Flavors
--------------------------------		
INSERT INTO Unit_Flavors 	
		(UnitType, 					FlavorType, Flavor)
SELECT	'UNIT_3CENTAUR',	FlavorType, Flavor
FROM Unit_Flavors  WHERE UnitType = 'UNIT_KNIGHT';	

INSERT INTO Unit_Flavors 	
		(UnitType, 					FlavorType, Flavor)
VALUES	('UNIT_3CENTAUR', 	'FLAVOR_RANGED',10);
--------------------------------	
-- Unit_ResourceQuantityRequirements
--------------------------------	
INSERT INTO Unit_ResourceQuantityRequirements 	
		(UnitType, 					ResourceType, Cost)
SELECT	'UNIT_3CENTAUR', 	ResourceType, Cost
FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_KNIGHT';
--------------------------------	
-- Unit_FreePromotions
--------------------------------	
INSERT INTO Unit_FreePromotions 	
		(UnitType, 					PromotionType)
SELECT	'UNIT_3CENTAUR', 	PromotionType
FROM Unit_FreePromotions WHERE UnitType = 'UNIT_KNIGHT';	

INSERT INTO Unit_FreePromotions
		(UnitType, 					PromotionType)
VALUES	('UNIT_3CENTAUR',  'PROMOTION_ONLY_DEFENSIVE'),
		('UNIT_3CENTAUR',  'PROMOTION_4HUNS');

--------------------------------	
-- Civilization_UnitClassOverrides 
--------------------------------		
INSERT INTO Civilization_UnitClassOverrides 
		(CivilizationType, 					UnitClassType, 			UnitType)
VALUES	('CIVILIZATION_HUNS',	'UNITCLASS_KNIGHT',	'UNIT_3CENTAUR');