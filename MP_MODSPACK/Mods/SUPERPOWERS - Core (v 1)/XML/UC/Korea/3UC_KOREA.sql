-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, FaithCost, Cost, UnlockedByBelief, FreeStartEra, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_SEOWON', BuildingClass, FaithCost, Cost, UnlockedByBelief, FreeStartEra, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_SEOWON_HELP','TXT_KEY_BUILDING_3UC_SEOWON',  'TXT_KEY_BUILDING_3UC_SEOWON_TEXT', 'TXT_KEY_BUILDING_3UC_SEOWON_STRATEGY', 'SEOWON_ICON_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_UNIVERSITY';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_SEOWON',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_UNIVERSITY';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_SEOWON',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_UNIVERSITY';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3UC_SEOWON', 'YIELD_FAITH', 4);

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_SEOWON', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_UNIVERSITY';

------------------------------	
-- Building_FeatureYieldChanges
------------------------------
INSERT INTO Building_FeatureYieldChanges 	
			(BuildingType, FeatureType, YieldType, Yield)
SELECT	'BUILDING_3UC_SEOWON',	FeatureType, YieldType, Yield
FROM Building_FeatureYieldChanges WHERE BuildingType = 'BUILDING_UNIVERSITY';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_SEOWON', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_UNIVERSITY';


--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_KOREA',	'BUILDINGCLASS_UNIVERSITY',	'BUILDING_3UC_SEOWON');


