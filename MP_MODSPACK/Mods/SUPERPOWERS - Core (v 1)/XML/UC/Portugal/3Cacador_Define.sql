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
SELECT		Class, 	('UNIT_4UC_CACADOR'),	PrereqTech, 55, Cost, 	FaithCost, 	RequiresFaithPurchaseEnabled, 3, 50,	CombatClass, Domain, DefaultUnitAI, ('TXT_KEY_UNIT_CACADOR'),	('The Caçadores (Portuguese word meaning "hunters") were the elite light infantry troops of the Portuguese Army, in the late 18th and early 19th centuries.[NEWLINE][NEWLINE]In 1808, following the pitiful showing of the Portuguese Army against the French, the Portuguese government realised the necessity of appointing a commander-in-chief capable of training, equipping and disciplining the demoralised Portuguese Army.  Portuguese War secretary Miguel Pereira Forjaz proposed the creation of independent battalions of Caçadores and six would be created. Later in the Peninsular War, additional battalions and other units of Caçadores were formed due to the success of the original six battalions. Each battalion came to include a special Atiradores (sharpshooters) company armed with rifles. In the Anglo-Portuguese Army, some Caçadores units were integrated into the elite Light Division, brigaded with the British units of the 95th Rifles.[NEWLINE][NEWLINE]One of the most distinctive features of the Caçadores was their famous brown uniform. The brown uniform was chosen as a form of camouflage, considered more appropriate to the dry lands of the Iberian Peninsula than the traditional green uniforms used by the light infantry of most other countries in Europe. During the Peninsular War, Caçadores became especially notable in the performance of marksmanship at long distances. Arthur Wellesley referred the Portuguese Caçadores as the "fighting cocks" of his Anglo-Portuguese Army.[NEWLINE][NEWLINE]The battalions and later regiments of Caçadores continued to constitute the light infantry of the Portuguese Army during the rest of the 19th century. However, with the advent of new firearms technologies and new infantry tactics, the differences between the Caçadores and the line infantry steadily decreased. Because of that, in the reorganization of the Portuguese Army of 1911, the decision was taken to extinguish the Caçadores units and to transform them into line infantry regiments.'),	('TXT_KEY_4UC_CACADOR_STRATEGY'),	('TXT_KEY_4UC_CACADOR_HELP'),	MilitarySupport, MilitaryProduction, Pillage, ObsoleteTech, AdvancedStartCost, GoodyHutUpgradeUnitClass, CombatLimit, XPValueAttack, XPValueDefense, Conscription, ('ART_DEF_UNIT_4UC_CACADOR'),	('UNITS_4UC_CACADOR_FLAG_ATLAS'), 	0,					0, 				('4UC_CACADOR_ATLAS'), 	MoveRate
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