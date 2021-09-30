-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, AllowsRangeStrike, Defense, ExtraCityHitPoints, CityWall, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3BUFFALOPOUND', BuildingClass, AllowsRangeStrike, Defense, ExtraCityHitPoints,CityWall,  Cost, 1, 'TECH_TRAPPING', ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3BUFFALOPOUND_HELP', 'TXT_KEY_BUILDING_3BUFFALOPOUND', 'TXT_KEY_BUILDING_3BUFFALOPOUND_TEXT', 'TXT_KEY_BUILDING_3BUFFALOPOUND_STRATEGY', '3BUFFALOPOUND_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_WATERMILL';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3BUFFALOPOUND',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_WATERMILL';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3BUFFALOPOUND',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_WATERMILL';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3BUFFALOPOUND',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_WATERMILL';
------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_3BUFFALOPOUND',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_3BUFFALOPOUND',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3BUFFALOPOUND', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3BUFFALOPOUND', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_WATERMILL';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_3BUFFALOPOUND', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_WATERMILL';

INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
VALUES ('BUILDING_3BUFFALOPOUND', 'RESOURCE_BISON', 'YIELD_FOOD', 1);

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_SHOSHONE',	'BUILDINGCLASS_WATERMILL',	'BUILDING_3BUFFALOPOUND');


