-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, BuildingProductionModifier, GreatWorkSlotType, GreatWorkCount, Cost, FreeStartEra, Happiness, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_SALON', BuildingClass, BuildingProductionModifier, GreatWorkSlotType, GreatWorkCount, Cost, FreeStartEra, Happiness, NeverCapture, GoldMaintenance, 'TECH_PRINTING_PRESS', ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_SALON_HELP', 'TXT_KEY_BUILDING_3UC_SALON', 'TXT_KEY_BUILDING_3UC_SALON_TEXT', 'TXT_KEY_BUILDING_3UC_SALON_STRATEGY', 'SALON_ICON_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_THEATRE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_SALON',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_THEATRE';

INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
VALUES( 'BUILDING_3UC_SALON',	'FLAVOR_SCIENCE', 10),
		( 'BUILDING_3UC_SALON',	'FLAVOR_CULTURE', 10);
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_SALON',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_THEATRE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
		SELECT	'BUILDING_3UC_SALON',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_THEATRE';

INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3UC_SALON', 'YIELD_CULTURE', 4),
	('BUILDING_3UC_SALON', 'YIELD_SCIENCE', 2);

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_SALON', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_THEATRE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_SALON', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_THEATRE';



--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_FRANCE',	'BUILDINGCLASS_THEATRE',	'BUILDING_3UC_SALON');


