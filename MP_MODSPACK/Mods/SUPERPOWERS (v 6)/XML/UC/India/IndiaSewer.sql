-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, Happiness, Defense, ExtraCityHitPoints, CityWall, FreshWater, FoodKept, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_5UC_SEWER', BuildingClass, Happiness, Defense, ExtraCityHitPoints, CityWall, 'true', FoodKept, Cost, 0, 'TECH_AGRICULTURE', ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_5UC_SEWER_HELP', 'TXT_KEY_BUILDING_5UC_SEWER', 'TXT_KEY_BUILDING_5UC_SEWER_TEXT', 'TXT_KEY_BUILDING_5UC_SEWER_STRATEGY', '5UC_ICON_ATLAS', 17
FROM Buildings WHERE Type = 'BUILDING_WATERMILL';

------------------------------
-- Building_Flavors
------------------------------
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_5UC_SEWER',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_WATERMILL';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_5UC_SEWER',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_WATERMILL';
------------------------------
-- Building_YieldChanges
------------------------------
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT 'BUILDING_5UC_SEWER', YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_5UC_SEWER',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_5UC_SEWER',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_5UC_SEWER', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
VALUES ('BUILDING_5UC_SEWER', 'YIELD_FOOD', 33);

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_5UC_SEWER', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_FeatureYieldChanges
------------------------------
--INSERT INTO Building_FeatureYieldChanges 	
--			(BuildingType, FeatureType, YieldType, Yield)
--SELECT 'BUILDING_5UC_SEWER', FeatureType, YieldType, Yield
--FROM Building_FeatureYieldChanges WHERE BuildingType = 'BUILDING_WATERMILL';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_INDIA',	'BUILDINGCLASS_WATERMILL',	'BUILDING_5UC_SEWER');

