-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus, ExtraCityHitPoints, CityWall, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3YAM', BuildingClass, 25, TradeRouteLandGoldBonus, ExtraCityHitPoints, CityWall,  Cost, 0, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3YAM_HELP', 'TXT_KEY_BUILDING_3YAM', 'TXT_KEY_BUILDING_3YAM_TEXT', 'TXT_KEY_BUILDING_3YAM_STRATEGY', '3UC_YAM_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_STABLE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3YAM',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_STABLE';

INSERT INTO Building_Flavors 		
			(BuildingType, 				FlavorType, Flavor)
VALUES ('BUILDING_3YAM', 'FLAVOR_GOLD', 6);
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3YAM',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_STABLE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3YAM',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_STABLE';

INSERT INTO Building_YieldChanges 		
			(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3YAM', 'YIELD_GOLD', 2);
------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_3YAM',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_STABLE';
------------------------------	
-- Building_LocalResourcesOrs
------------------------------
INSERT INTO Building_LocalResourceOrs 	
			(BuildingType, ResourceType)
SELECT	'BUILDING_3YAM',	ResourceType
FROM Building_LocalResourceOrs WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_3YAM',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3YAM', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_ResourceQuantity
------------------------------
INSERT INTO Building_ResourceQuantity 	
			(BuildingType, ResourceType, Quantity)
VALUES ('BUILDING_3YAM', 'RESOURCE_HORSE', 1);

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3YAM', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_STABLE';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_3YAM', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_STABLE';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_MONGOL',	'BUILDINGCLASS_STABLE',	'BUILDING_3YAM');


