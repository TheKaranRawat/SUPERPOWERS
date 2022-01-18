-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, FaithCost, UnlockedByBelief, AllowsRangeStrike, Defense, ExtraCityHitPoints, CityWall, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_4UC_RUSSIANRESEARCH', BuildingClass, FaithCost, UnlockedByBelief, AllowsRangeStrike, Defense, ExtraCityHitPoints,CityWall,  Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_4UC_RUSSIANRESEARCH_HELP', 'TXT_KEY_BUILDING_4UC_RUSSIANRESEARCH', 'TXT_KEY_BUILDING_4UC_RUSSIANRESEARCH_TEXT', 'TXT_KEY_BUILDING_4UC_RUSSIANRESEARCH_STRATEGY', 'ATLAS_4UC_RUSSIANRESEARCH', 0
FROM Buildings WHERE Type = 'BUILDING_LABORATORY';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_4UC_RUSSIANRESEARCH',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_LABORATORY';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_4UC_RUSSIANRESEARCH',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_LABORATORY';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES	('BUILDING_4UC_RUSSIANRESEARCH',	'YIELD_SCIENCE', 8);

------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_4UC_RUSSIANRESEARCH',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_LABORATORY';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_4UC_RUSSIANRESEARCH',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_LABORATORY';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_4UC_RUSSIANRESEARCH', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_LABORATORY';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_4UC_RUSSIANRESEARCH', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_LABORATORY';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_4UC_RUSSIANRESEARCH', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_LABORATORY';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_RUSSIA',	'BUILDINGCLASS_LABORATORY',	'BUILDING_4UC_RUSSIANRESEARCH');


