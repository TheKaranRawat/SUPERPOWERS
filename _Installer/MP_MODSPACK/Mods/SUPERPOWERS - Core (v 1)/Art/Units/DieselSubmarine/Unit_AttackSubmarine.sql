----------------------------------------------------
-- Enhanced Modern Warfare
-- New unit: Attack Submarine
-- Author: Infixo
-- Feb 16, 2017: Created
----------------------------------------------------

----------------------------------------------------
-- ArtDef
----------------------------------------------------

INSERT INTO ArtDefine_UnitInfos (Type, DamageStates, Formation)
VALUES ('ART_DEF_UNIT_ATTACK_SUBMARINE', 3, '');

INSERT INTO ArtDefine_UnitMemberInfos (Type, Scale , Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
VALUES ('ART_DEF_UNIT_MEMBER_ATTACK_SUBMARINE', 0.09, 'Sea', 'akula.fxsxml', 'METAL', 'METALLRG');

INSERT INTO ArtDefine_UnitInfoMemberInfos (UnitInfoType, UnitMemberInfoType, NumMembers)
VALUES ('ART_DEF_UNIT_ATTACK_SUBMARINE', 'ART_DEF_UNIT_MEMBER_ATTACK_SUBMARINE', 1);

INSERT INTO ArtDefine_UnitMemberCombats
	(UnitMemberType, EnableActions, DisableActions,
	HasShortRangedAttack, HasLongRangedAttack, HasLeftRightAttack, HasRefaceAfterCombat, HasIndependentWeaponFacing, RushAttackFormation)
VALUES
	('ART_DEF_UNIT_MEMBER_ATTACK_SUBMARINE', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady AttackSurfaceToAir', '',
	1, 1, NULL, 0, NULL, '');

INSERT INTO ArtDefine_UnitMemberCombatWeapons
	(UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax, ProjectileSpeed, HitEffect, WeaponTypeTag, WeaponTypeSoundOverrideTag)
VALUES
	('ART_DEF_UNIT_MEMBER_ATTACK_SUBMARINE', 0, 0, '', NULL, NULL, NULL, '', 'EXPLOSIVE', 'EXPLOSION200POUND');
	-- subs have only 1 entry
	--('ART_DEF_UNIT_MEMBER_ATTACK_SUBMARINE', 1, 0, 'ART_DEF_VEFFECT_MECH_ROCKET_PROJECTILE', 25, 50, 5.3, 'ART_DEF_VEFFECT_GUIDED_MISSILE_IMPACT_$(TERRAIN)', 'BULLETHC', 'BULLETHC');

-- uses vanilla's Missile Cruiser SV icon
INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset)
VALUES ('ART_DEF_UNIT_ATTACK_SUBMARINE', 'Unit', 'SV_AttackSubmarine.dds');

----------------------------------------------------
-- Icons
-- Shared atlas: ICON_ATLAS_ENW
----------------------------------------------------
/*
INSERT INTO IconTextureAtlases (Atlas, IconSize, Filename, IconsPerRow, IconsPerColumn)
VALUES ('UNIT_ATTACK_SUBMARINE_FLAG_ATLAS', 32, 'UnitFlag_AttackSubmarine.dds', '1', '1');
*/
----------------------------------------------------
-- Unit
----------------------------------------------------

INSERT INTO UnitClasses (Type, Description, MaxPlayerInstances, DefaultUnit)
VALUES ('UNITCLASS_ATTACK_SUBMARINE', 'TXT_KEY_UNIT_ATTACK_SUBMARINE', -1, 'UNIT_ATTACK_SUBMARINE');

INSERT INTO Units
	(Type, Class, Domain, CombatClass, PrereqTech, ObsoleteTech, DefaultUnitAI,
	Description, Civilopedia, Strategy, Help,
	Cost, FaithCost, ExtraMaintenanceCost, Combat, Moves, RangedCombat, Range, AirInterceptRange, BaseSightRange, RangeAttackOnlyInDomain,
	MilitarySupport, MilitaryProduction, Pillage, IgnoreBuildingDefense, Mechanized,
	AdvancedStartCost, MinAreaSize, XPValueAttack, XPValueDefense, MoveRate,
	BaseLandAirDefense, SpecialCargo, DomainCargo, PurchaseCooldown,
	UnitArtInfo, UnitFlagAtlas, UnitFlagIconOffset, IconAtlas, PortraitIndex)
VALUES
	('UNIT_ATTACK_SUBMARINE', 'UNITCLASS_ATTACK_SUBMARINE', 'DOMAIN_SEA', 'UNITCOMBAT_SUBMARINE', 'TECH_PENICILIN', NULL, 'UNITAI_ASSAULT_SEA',
	'TXT_KEY_UNIT_ATTACK_SUBMARINE', 'TXT_KEY_UNIT_ATTACK_SUBMARINE_PEDIA', 'TXT_KEY_UNIT_ATTACK_SUBMARINE_STRATEGY', 'TXT_KEY_UNIT_ATTACK_SUBMARINE_HELP',
	1600, 1000, 0, 35, 5, 50, 1, 0, 2, 1,
	1, 1, 1, 1, 1,
	60, 10, 3, 3, 'SUB',
	5, 'SPECIALUNIT_MISSILE', 'DOMAIN_AIR', 1,
	'ART_DEF_UNIT_ATTACK_SUBMARINE', 'FLAG_ATLAS_ENW', 0, 'ICON_ATLAS_ENW', 0);
	
INSERT INTO UnitGameplay2DScripts (UnitType, SelectionSound, FirstSelectionSound)
VALUES ('UNIT_ATTACK_SUBMARINE', 'AS2D_SELECT_SUBMARINE', 'AS2D_BIRTH_SUBMARINE');

DELETE FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_SUBMARINE';
INSERT INTO Unit_ClassUpgrades (UnitType, UnitClassType)
VALUES ('UNIT_SUBMARINE', 'UNITCLASS_ATTACK_SUBMARINE');

INSERT INTO Unit_ClassUpgrades (UnitType, UnitClassType)
VALUES ('UNIT_ATTACK_SUBMARINE', 'UNITCLASS_NUCLEAR_SUBMARINE');

----------------------------------------------------
-- Promotions
-- No special promos
----------------------------------------------------

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
VALUES
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_ONLY_DEFENSIVE'),
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_CAN_MOVE_AFTER_ATTACKING'),
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_INVISIBLE_SUBMARINE'),
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_CARGO_I'),
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_SILENT_HUNTER'), -- +75%
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_BIG_CITY_PENALTY'), -- -75%
	('UNIT_ATTACK_SUBMARINE', 'PROMOTION_CAN_MOVE_IMPASSABLE'); -- ice tiles

----------------------------------------------------
-- Other features
----------------------------------------------------

INSERT INTO Unit_ResourceQuantityRequirements (UnitType, ResourceType, Cost)
VALUES ('UNIT_ATTACK_SUBMARINE', 'RESOURCE_ALUMINUM', 1);

INSERT INTO Unit_BuildingClassPurchaseRequireds (UnitType, BuildingClassType)
VALUES ('UNIT_ATTACK_SUBMARINE','BUILDINGCLASS_SEAPORT');

----------------------------------------------------
-- AI
----------------------------------------------------

INSERT INTO Technology_Flavors (TechType, FlavorType, Flavor)
VALUES ('TECH_PENICILIN', 'FLAVOR_NAVAL', 10);
	
INSERT INTO Unit_AITypes (UnitType, UnitAIType)
VALUES
	('UNIT_ATTACK_SUBMARINE', 'UNITAI_ASSAULT_SEA'),
	('UNIT_ATTACK_SUBMARINE', 'UNITAI_RESERVE_SEA'),
	('UNIT_ATTACK_SUBMARINE', 'UNITAI_EXPLORE_SEA'),
	('UNIT_ATTACK_SUBMARINE', 'UNITAI_MISSILE_CARRIER_SEA');

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
VALUES
	('UNIT_ATTACK_SUBMARINE', 'FLAVOR_NAVAL', 30),
	('UNIT_ATTACK_SUBMARINE', 'FLAVOR_NUKE', 5),
	('UNIT_ATTACK_SUBMARINE', 'FLAVOR_NAVAL_RECON', 30);

----------------------------------------------------
-- Text (en_US)
----------------------------------------------------

INSERT INTO Language_en_US (Tag, Text)
VALUES ('TXT_KEY_UNIT_ATTACK_SUBMARINE', 'Attack Submarine');

-- Pedia: Historical Info (bottom)
INSERT INTO Language_en_US (Tag, Text)
VALUES ('TXT_KEY_UNIT_ATTACK_SUBMARINE_PEDIA', 'An attack submarine or hunter-killer submarine is a sub specifically designed for the purpose of attacking and sinking other submarines and naval vessels. Some attack subs are also armed with cruise missiles mounted in vertical launch tubes, increasing the scope of their potential missions to include land targets.[NEWLINE]The basis for most non-nuclear submarine designs worldwide through the 1950s was Type XXI U-boat, an advanced German submarine from WWII, equipped with a Walter hydrogen peroxide-fueled gas turbine and a high battery capacity allowing high sustained underwater speed.[NEWLINE]In 1960s, the first ballistic missile submarines were put into service by both the United States (George Washington class) and the Soviet Union (Golf class) as part of the Cold War nuclear deterrent strategy.');

-- Pedia: Strategy (middle)
INSERT INTO Language_en_US (Tag, Text)
VALUES ('TXT_KEY_UNIT_ATTACK_SUBMARINE_STRATEGY', 'Attack Submarine is a naval offensive unit, stronger and faster than the predecessor. It can also carry a missile.');

-- Pedia: Game Info (top)
INSERT INTO Language_en_US (Tag, Text)
VALUES ('TXT_KEY_UNIT_ATTACK_SUBMARINE_HELP', 'Attack Submarine can carry 1 Missile and it requires [ICON_RES_ALUMINUM] Aluminum to be built.');
