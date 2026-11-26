-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, Cost, FreeStartEra, Happiness, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_PLAYHOUSE', BuildingClass, Cost, FreeStartEra, Happiness, NeverCapture, 0, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_PLAYHOUSE_HELP', 'TXT_KEY_BUILDING_3UC_PLAYHOUSE', 'TXT_KEY_BUILDING_3UC_PLAYHOUSE_TEXT', 'TXT_KEY_BUILDING_3UC_PLAYHOUSE_STRATEGY', 'ATLAS_3UC_PLAYHOUSE', 0
FROM Buildings WHERE Type = 'BUILDING_THEATRE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_PLAYHOUSE',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_THEATRE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_PLAYHOUSE',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_THEATRE';	


------------------------------	
-- Building_YieldChangesPerPop
------------------------------		
INSERT INTO Building_YieldChangesPerPop 	
		(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3UC_PLAYHOUSE', 'YIELD_GOLD', 10);

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_PLAYHOUSE', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_THEATRE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_PLAYHOUSE', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_THEATRE';


--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_ENGLAND',	'BUILDINGCLASS_THEATRE',	'BUILDING_3UC_PLAYHOUSE');


