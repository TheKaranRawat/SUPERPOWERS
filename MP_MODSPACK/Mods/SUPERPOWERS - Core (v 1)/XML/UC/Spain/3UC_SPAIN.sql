-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, Cost, FreeStartEra, Happiness, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_BULLRING', BuildingClass, Cost, FreeStartEra, Happiness, NeverCapture, 0, 'TECH_CHIVALRY', ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_BULLRING_HELP', 'TXT_KEY_BUILDING_3UC_BULLRING', 'TXT_KEY_BUILDING_3UC_BULLRING_TEXT', 'TXT_KEY_BUILDING_3UC_BULLRING_STRATEGY', 'ICON_ATLAS', 36
FROM Buildings WHERE Type = 'BUILDING_THEATRE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_BULLRING',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_THEATRE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_BULLRING',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_THEATRE';
------------------------------	
-- Building_ResourceYieldChanges
------------------------------		
INSERT INTO Building_ResourceYieldChanges	
		(BuildingType, 		ResourceType, 		YieldType, Yield)
VALUES ('BUILDING_3UC_BULLRING', 'RESOURCE_COW','YIELD_CULTURE', 3);

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_BULLRING', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_THEATRE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_BULLRING', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_THEATRE';


--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_SPAIN',	'BUILDINGCLASS_THEATRE',	'BUILDING_3UC_BULLRING');


