-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, TrainedFreePromotion, BuildingClass, Cost, FreeStartEra, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_VIKING_LONGHOUSE', 'PROMOTION_VIKING_LEGACY', BuildingClass, Cost, FreeStartEra, NeverCapture, 0, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_VIKING_LONGHOUSE_HELP', 'TXT_KEY_BUILDING_3UC_VIKING_LONGHOUSE', 'TXT_KEY_BUILDING_3UC_VIKING_LONGHOUSE_TEXT', 'TXT_KEY_BUILDING_3UC_VIKING_LONGHOUSE_STRATEGY', 'ICON_ATLAS', 10
FROM Buildings WHERE Type = 'BUILDING_BARRACKS';	

INSERT OR REPLACE INTO UnitPromotions 
			(Type, 						Description, 					Help, 									Sound, 		OpenAttack, 	RoughAttack,	 	LostWithUpgrade, CannotBeChosen, PortraitIndex, 	IconAtlas, 			PediaType, 			PediaEntry)
VALUES		('PROMOTION_VIKING_LEGACY',	'TXT_KEY_PROMOTION_VIKING_LEGACY',	'TXT_KEY_PROMOTION_VIKING_LEGACY_HELP',	'AS2D_IF_LEVELUP', 		15, 15, 						'false',			 1, 				59, 			'ABILITY_ATLAS', 	'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_VIKING_LEGACY');

INSERT INTO UnitPromotions_UnitCombats
	(PromotionType, UnitCombatType)
VALUES ('PROMOTION_VIKING_LEGACY', 'UNITCOMBAT_MOUNTED'),
		('PROMOTION_VIKING_LEGACY', 'UNITCOMBAT_MELEE'),
		('PROMOTION_VIKING_LEGACY', 'UNITCOMBAT_NAVALMELEE'),
		('PROMOTION_VIKING_LEGACY', 'UNITCOMBAT_GUN');
		


------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_VIKING_LONGHOUSE',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_BARRACKS';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_VIKING_LONGHOUSE',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_BARRACKS';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3UC_VIKING_LONGHOUSE', 'YIELD_CULTURE', 2);
------------------------------	
-- Building_DomainFreeExperiences
------------------------------
INSERT INTO Building_DomainFreeExperiences 	
		(BuildingType, 				DomainType, Experience)
SELECT	'BUILDING_3UC_VIKING_LONGHOUSE',	DomainType, Experience
FROM Building_DomainFreeExperiences WHERE BuildingType = 'BUILDING_BARRACKS';


------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_VIKING_LONGHOUSE', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_BARRACKS';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_VIKING_LONGHOUSE', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_BARRACKS';


--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_DENMARK',	'BUILDINGCLASS_BARRACKS',	'BUILDING_3UC_VIKING_LONGHOUSE');


