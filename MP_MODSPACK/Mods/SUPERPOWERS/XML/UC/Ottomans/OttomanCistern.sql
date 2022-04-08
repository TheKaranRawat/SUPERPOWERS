-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, Happiness, Defense, ExtraCityHitPoints, CityWall, FoodKept, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_5UC_CISTERN', BuildingClass, 2, Defense, ExtraCityHitPoints, CityWall, 20, Cost, 0, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_5UC_CISTERN_HELP', 'TXT_KEY_BUILDING_5UC_CISTERN', 'TXT_KEY_BUILDING_5UC_CISTERN_TEXT', 'TXT_KEY_BUILDING_5UC_CISTERN_STRATEGY', '5UC_ICON_ATLAS', 8
FROM Buildings WHERE Type = 'BUILDING_AQUEDUCT';

------------------------------
-- Building_Flavors
------------------------------
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_5UC_CISTERN',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_AQUEDUCT';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_5UC_CISTERN',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_AQUEDUCT';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_5UC_CISTERN',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_AQUEDUCT';

------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_5UC_CISTERN',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_AQUEDUCT';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_5UC_CISTERN',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_AQUEDUCT';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_5UC_CISTERN', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_AQUEDUCT';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
VALUES ('BUILDING_5UC_CISTERN', 'YIELD_FOOD', 25);

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_5UC_CISTERN', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_AQUEDUCT';

------------------------------	
-- Building_FeatureYieldChanges
------------------------------
--INSERT INTO Building_FeatureYieldChanges 	
--			(BuildingType, FeatureType, YieldType, Yield)
--SELECT 'BUILDING_5UC_CISTERN', FeatureType, YieldType, Yield
--FROM Building_FeatureYieldChanges WHERE BuildingType = 'BUILDING_AQUEDUCT';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_OTTOMAN',	'BUILDINGCLASS_AQUEDUCT',	'BUILDING_5UC_CISTERN');

