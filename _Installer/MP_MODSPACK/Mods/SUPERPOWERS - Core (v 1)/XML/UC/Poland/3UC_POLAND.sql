-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass,  EnhancedYieldTech, TechEnhancedTourism, AllowsRangeStrike, Defense, ExtraCityHitPoints,  GreatPeopleRateModifier, GreatWorkSlotType, GreatWorkCount, FreshWater, Cost, FreeStartEra, Happiness, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_BARBICAN', BuildingClass, 'TECH_FLIGHT', 2, AllowsRangeStrike, Defense, ExtraCityHitPoints, GreatPeopleRateModifier, GreatWorkSlotType, GreatWorkCount, FreshWater, Cost, FreeStartEra, Happiness, NeverCapture, GoldMaintenance, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier,  'TXT_KEY_BUILDING_3UC_BARBICAN_HELP','TXT_KEY_BUILDING_3UC_BARBICAN', 'TXT_KEY_BUILDING_3UC_BARBICAN_TEXT', 'TXT_KEY_BUILDING_3UC_BARBICAN_STRATEGY', 'BUILDING_3_BARBICAN_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_CASTLE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_BARBICAN',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_CASTLE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_BARBICAN',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_CASTLE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES	('BUILDING_3UC_BARBICAN',	'YIELD_FOOD',	4);

------------------------------	
-- Building_TechEnhancedYieldChanges
------------------------------		
INSERT INTO Building_TechEnhancedYieldChanges	
		(BuildingType, 				YieldType, Yield)
VALUES	('BUILDING_3UC_BARBICAN',	'YIELD_FOOD',	-4),
		('BUILDING_3UC_BARBICAN',	'YIELD_CULTURE',	4);

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_BARBICAN', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_CASTLE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_BARBICAN', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_CASTLE';


--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_POLAND',	'BUILDINGCLASS_CASTLE',	'BUILDING_3UC_BARBICAN');


