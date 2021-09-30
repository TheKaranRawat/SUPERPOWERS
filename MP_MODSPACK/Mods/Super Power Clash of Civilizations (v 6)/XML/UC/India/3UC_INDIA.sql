INSERT INTO ArtDefine_UnitInfos (Type,DamageStates,Formation)
    SELECT    ('ART_DEF_UNIT_3SEPOY'), DamageStates, Formation
    FROM ArtDefine_UnitInfos WHERE (Type = 'ART_DEF_UNIT_U_OTTOMAN_JANISSARY');

INSERT INTO ArtDefine_UnitInfoMemberInfos (UnitInfoType,UnitMemberInfoType,NumMembers)
	SELECT	('ART_DEF_UNIT_3SEPOY'), ('ART_DEF_UNIT_MEMBER_3SEPOY'), NumMembers
	FROM ArtDefine_UnitInfoMemberInfos WHERE (UnitInfoType = 'ART_DEF_UNIT_U_OTTOMAN_JANISSARY');    

INSERT INTO ArtDefine_UnitMemberCombats (UnitMemberType, EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation)
    SELECT    ('ART_DEF_UNIT_MEMBER_3SEPOY'), EnableActions, DisableActions, MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, MoveRate, ShortMoveRate, TurnRateMin, TurnRateMax, TurnFacingRateMin, TurnFacingRateMax, RollRateMin, RollRateMax, PitchRateMin, PitchRateMax, LOSRadiusScale, TargetRadius, TargetHeight, HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasStationaryMelee, HasStationaryRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat, HasIndependentWeaponFacing, HasOpponentTracking, HasCollisionAttack, AttackAltitude, AltitudeDecelerationDistance, OnlyTurnInMovementActions, RushAttackFormation
    FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType = 'ART_DEF_UNIT_MEMBER_U_OTTOMAN_JANISSARY');

INSERT INTO ArtDefine_UnitMemberCombatWeapons (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag)
    SELECT ('ART_DEF_UNIT_MEMBER_3SEPOY'), "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, ProjectileTurnRateMin, ProjectileTurnRateMax, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale, AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped, WeaponTypeTag, WeaponTypeSoundOverrideTag
    FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType = 'ART_DEF_UNIT_U_OTTOMAN_JANISSARY');

INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale, ZOffset, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
    SELECT    ('ART_DEF_UNIT_MEMBER_3SEPOY'), Scale, ZOffset, Domain, ('sepoy.fxsxml'), MaterialTypeTag, MaterialTypeSoundOverrideTag
    FROM ArtDefine_UnitMemberInfos WHERE (Type = 'ART_DEF_UNIT_MEMBER_U_OTTOMAN_JANISSARY');

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset )
	VALUES	('ART_DEF_UNIT_3SEPOY', 'Unit', 'sv_sepoy.dds');


INSERT OR REPLACE INTO UnitPromotions 
			(Type, 						Description, 					Help, 									Sound, 				ExperiencePercent, 	LostWithUpgrade, CannotBeChosen, PortraitIndex, 	IconAtlas, 			PediaType, 			PediaEntry)
VALUES		('PROMOTION_3SEPOY',	'TXT_KEY_PROMOTION_3SEPOY',	'TXT_KEY_PROMOTION_3SEPOY_HELP',	'AS2D_IF_LEVELUP', 				50,					'false',			 1, 				59, 			'ABILITY_ATLAS', 	'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_3SEPOY');

--------------------------------	
-- Units
--------------------------------
INSERT INTO Units 	
		(Type, 						Class,	PrereqTech, RangedCombat, Range, Special, Combat, Cost, ObsoleteTech, GoodyHutUpgradeUnitClass, FaithCost, RequiresFaithPurchaseEnabled, Moves, CombatClass, Domain, DefaultUnitAI, Help, Description, 					  Civilopedia, 								Strategy, 		 									Pillage, MilitarySupport, MilitaryProduction, IgnoreBuildingDefense, Mechanized, AdvancedStartCost, RangedCombatLimit, CombatLimit, XPValueDefense, UnitArtInfo, 						UnitFlagIconOffset,	UnitFlagAtlas,						 PortraitIndex, 	IconAtlas,			 MoveRate)
SELECT	'UNIT_3SEPOY',	Class,	PrereqTech, RangedCombat, Range, Special, Combat, Cost, ObsoleteTech, GoodyHutUpgradeUnitClass, FaithCost, RequiresFaithPurchaseEnabled, Moves, CombatClass, Domain,  DefaultUnitAI, 'TXT_KEY_UNIT_3SEPOY_HELP', 'TXT_KEY_UNIT_3SEPOY',  'TXT_KEY_UNIT_3SEPOY_TEXT',	'TXT_KEY_UNIT_3SEPOY_STRATEGY',  	Pillage, MilitarySupport, MilitaryProduction, IgnoreBuildingDefense, Mechanized, AdvancedStartCost, RangedCombatLimit, CombatLimit, XPValueDefense, 'ART_DEF_UNIT_3SEPOY',	0,					'3SEPOY_FLAG',					  0, 				'3SEPOY_ATLAS',	 MoveRate
FROM Units WHERE Type = 'UNIT_MUSKETMAN';
--------------------------------	
-- UnitGameplay2DScripts
--------------------------------		
INSERT INTO UnitGameplay2DScripts 	
		(UnitType, 					SelectionSound, FirstSelectionSound)
SELECT	'UNIT_3SEPOY', 	SelectionSound, FirstSelectionSound
FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_MUSKETMAN';
--------------------------------		
-- Unit_AITypes
--------------------------------		
INSERT INTO Unit_AITypes 	
		(UnitType, 					UnitAIType)
SELECT	'UNIT_3SEPOY', 	UnitAIType
FROM Unit_AITypes WHERE UnitType = 'UNIT_MUSKETMAN';
--------------------------------	
-- Unit_ClassUpgrades
--------------------------------	
INSERT INTO Unit_ClassUpgrades 	
		(UnitType, 					UnitClassType)
SELECT	'UNIT_3SEPOY',	UnitClassType
FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_MUSKETMAN';	
--------------------------------	
-- Unit_Flavors
--------------------------------		
INSERT INTO Unit_Flavors 	
		(UnitType, 					FlavorType, Flavor)
SELECT	'UNIT_3SEPOY', 	FlavorType, Flavor
FROM Unit_Flavors WHERE UnitType = 'UNIT_MUSKETMAN';
--------------------------------	
-- Unit_ResourceQuantityRequirements
--------------------------------	
INSERT INTO Unit_ResourceQuantityRequirements 	
		(UnitType, 					ResourceType, Cost)
SELECT	'UNIT_3SEPOY', 	ResourceType, Cost
FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_MUSKETMAN';
--------------------------------	
-- Unit_FreePromotions
--------------------------------	
INSERT INTO Unit_FreePromotions 	
		(UnitType, 					PromotionType)
SELECT	'UNIT_3SEPOY', 	PromotionType
FROM Unit_FreePromotions WHERE UnitType = 'UNIT_MUSKETMAN';	

INSERT INTO Unit_FreePromotions
		(UnitType, 					PromotionType)
VALUES	('UNIT_3SEPOY',  'PROMOTION_SIEGE'),
		('UNIT_3SEPOY',  'PROMOTION_3SEPOY');


--------------------------------	
-- Civilization_UnitClassOverrides 
--------------------------------		
INSERT INTO Civilization_UnitClassOverrides 
		(CivilizationType, 					UnitClassType, 			UnitType)
VALUES	('CIVILIZATION_INDIA',	'UNITCLASS_MUSKETMAN',	'UNIT_3SEPOY');