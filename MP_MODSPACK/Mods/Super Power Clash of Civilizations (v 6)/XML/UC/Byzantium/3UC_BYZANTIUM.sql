-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, Cost, Happiness, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_HIPPODROME', BuildingClass, Cost, Happiness, GoldMaintenance, 'TECH_THE_WHEEL', ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_HIPPODROME_HELP', 'TXT_KEY_BUILDING_3UC_HIPPODROME', 'TXT_KEY_BUILDING_3UC_HIPPODROME_TEXT', 'TXT_KEY_BUILDING_3UC_HIPPODROME_STRATEGY', 'ICON_ATLAS', 6
FROM Buildings WHERE Type = 'BUILDING_CIRCUS';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_HIPPODROME',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_CIRCUS';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_HIPPODROME',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_CIRCUS';

------------------------------	
-- Building_Building_LocalResourceOrs
------------------------------		
INSERT INTO Building_LocalResourceOrs	
		(BuildingType, 				ResourceType)
SELECT	'BUILDING_3UC_HIPPODROME',	ResourceType
FROM Building_LocalResourceOrs WHERE BuildingType = 'BUILDING_CIRCUS';

------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES	('BUILDING_3UC_HIPPODROME',	'YIELD_CULTURE', 2),
		('BUILDING_3UC_HIPPODROME',	'YIELD_FAITH', 1);

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_HIPPODROME', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_CIRCUS';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_BYZANTIUM',	'BUILDINGCLASS_CIRCUS',	'BUILDING_3UC_HIPPODROME');


