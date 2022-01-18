-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass,PlotCultureCostModifier,  Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_RANCH', BuildingClass, -25,  Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_RANCH_HELP', 'TXT_KEY_BUILDING_3UC_RANCH', 'TXT_KEY_BUILDING_3UC_RANCH_TEXT', 'TXT_KEY_BUILDING_3UC_RANCH_STRATEGY', '3UC_RANCH_ICON_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_STABLE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_RANCH',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_STABLE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_RANCH',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_STABLE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3UC_RANCH',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT 'BUILDING_3UC_RANCH', UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_RANCH', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_3UC_RANCH', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges WHERE BuildingType = 'BUILDING_STABLE';

INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
VALUES ('BUILDING_3UC_RANCH', 'RESOURCE_DEER', 'YIELD_PRODUCTION', 1),
	   ('BUILDING_3UC_RANCH', 'RESOURCE_BISON', 'YIELD_PRODUCTION', 1);

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_AMERICA',	'BUILDINGCLASS_STABLE',	'BUILDING_3UC_RANCH');


