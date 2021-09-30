
INSERT INTO ArtDefine_UnitInfos (Type,DamageStates,Formation)
	SELECT	('ART_DEF_UNIT_CHARIOTCELT'), DamageStates, Formation
	FROM ArtDefine_UnitInfos WHERE (Type = 'ART_DEF_UNIT_U_HITTITE_WARCHARIOT');

INSERT INTO ArtDefine_UnitInfoMemberInfos VALUES	('ART_DEF_UNIT_CHARIOTCELT', 'ART_DEF_UNIT_MEMBER_CHARIOTCELT_1', 1);	

INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation)
	SELECT	('ART_DEF_UNIT_MEMBER_CHARIOTCELT_1'), EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation
	FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_U_HITTITE_WARCHARIOT');

INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag)
	SELECT ('ART_DEF_UNIT_MEMBER_CHARIOTCELT_1'), "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_U_HITTITE_WARCHARIOT');

INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale, ZOffset, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
	SELECT	('ART_DEF_UNIT_MEMBER_CHARIOTCELT_1'), Scale, ZOffset, Domain, ('Hititte_War_Chariot.fxsxml'), MaterialTypeTag, MaterialTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberInfos WHERE (Type = 'ART_DEF_UNIT_MEMBER_U_HITTITE_WARCHARIOT');

	INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset )
	VALUES	('ART_DEF_UNIT_CHARIOTCELT', 'Unit', '3celtknotSV.dds');

--------------------------------	
-- Units
--------------------------------
INSERT INTO Units 	
		(Type, 						Class,	PrereqTech, RangedCombat, Range, Special, Combat, Cost, ObsoleteTech, GoodyHutUpgradeUnitClass, FaithCost, RequiresFaithPurchaseEnabled, Moves, CombatClass, Domain, DefaultUnitAI, Help, Description, 					  Civilopedia, 								Strategy, 		 									Pillage, MilitarySupport, MilitaryProduction, IgnoreBuildingDefense, Mechanized, AdvancedStartCost, RangedCombatLimit, CombatLimit, XPValueDefense, UnitArtInfo, 						UnitFlagIconOffset,	UnitFlagAtlas,						 PortraitIndex, 	IconAtlas,			 MoveRate)
SELECT	'UNIT_4CARPENTOM',	Class,	 'TECH_THE_WHEEL', RangedCombat, Range, Special, 10, Cost, ObsoleteTech, GoodyHutUpgradeUnitClass, FaithCost, RequiresFaithPurchaseEnabled, Moves, CombatClass, Domain, DefaultUnitAI, 'TXT_KEY_UNIT_4CARPENTOM_HELP','TXT_KEY_UNIT_4CARPENTOM', 'TXT_KEY_UNIT_4CARPENTOM_TEXT',	'TXT_KEY_UNIT_4CARPENTOM_STRATEGY',  	Pillage, MilitarySupport, MilitaryProduction, IgnoreBuildingDefense, Mechanized, AdvancedStartCost, RangedCombatLimit, CombatLimit, XPValueDefense, 'ART_DEF_UNIT_CHARIOTCELT',	0,					'4CARPENTOM_FLAG',					  0, 				'4CARPENTOM_ATLAS',	 MoveRate
FROM Units WHERE Type = 'UNIT_HORSEMAN';
--------------------------------	
-- UnitGameplay2DScripts
--------------------------------		
INSERT INTO UnitGameplay2DScripts 	
		(UnitType, 					SelectionSound, FirstSelectionSound)
SELECT	'UNIT_4CARPENTOM', 	SelectionSound, FirstSelectionSound
FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_HORSEMAN';
--------------------------------		
-- Unit_AITypes
--------------------------------		
INSERT INTO Unit_AITypes 	
		(UnitType, 					UnitAIType)
SELECT	'UNIT_4CARPENTOM', 	UnitAIType
FROM Unit_AITypes WHERE UnitType = 'UNIT_HORSEMAN';

INSERT INTO Unit_AITypes 	
		(UnitType, 					UnitAIType)
VALUES ('UNIT_4CARPENTOM', 'UNITAI_GENERAL');

--------------------------------	
-- Unit_ClassUpgrades
--------------------------------	
INSERT INTO Unit_ClassUpgrades 	
		(UnitType, 					UnitClassType)
SELECT	'UNIT_4CARPENTOM',	UnitClassType
FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_HORSEMAN';	
--------------------------------	
-- Unit_Flavors
--------------------------------		
INSERT INTO Unit_Flavors 	
		(UnitType, 					FlavorType, Flavor)
VALUES	('UNIT_4CARPENTOM',	'FLAVOR_OFFENSE', 3),
		('UNIT_4CARPENTOM',	'FLAVOR_DEFENSE', 5),
		('UNIT_4CARPENTOM',	'FLAVOR_MOBILE', 3);

--------------------------------	
-- Unit_ResourceQuantityRequirements
--------------------------------	
INSERT INTO Unit_ResourceQuantityRequirements 	
		(UnitType, 					ResourceType, Cost)
SELECT	'UNIT_4CARPENTOM', 	ResourceType, Cost
FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_HORSEMAN';
--------------------------------	
-- Unit_FreePromotions
--------------------------------	
INSERT INTO Unit_FreePromotions 	
		(UnitType, 					PromotionType)
SELECT	'UNIT_4CARPENTOM', 	PromotionType
FROM Unit_FreePromotions WHERE UnitType = 'UNIT_HORSEMAN';	

INSERT INTO Unit_FreePromotions
		(UnitType, 					PromotionType)
VALUES	('UNIT_4CARPENTOM',  'PROMOTION_MEDIC'),
		('UNIT_4CARPENTOM',  'PROMOTION_MEDIC_II'),
		('UNIT_4CARPENTOM',  'PROMOTION_ROUGH_TERRAIN_ENDS_TURN'),
		('UNIT_4CARPENTOM',  'PROMOTION_ANTI_MOUNTED_I');

--------------------------------	
-- Civilization_UnitClassOverrides 
--------------------------------		
INSERT INTO Civilization_UnitClassOverrides 
		(CivilizationType, 					UnitClassType, 			UnitType)
VALUES	('CIVILIZATION_CELTS',	'UNITCLASS_HORSEMAN',	'UNIT_4CARPENTOM');