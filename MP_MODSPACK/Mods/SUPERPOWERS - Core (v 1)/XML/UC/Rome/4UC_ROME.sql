-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, GreatPeopleRateModifier, FreshWater, AllowsRangeStrike, Defense, ExtraCityHitPoints, CityWall, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3ROMEGARDEN', BuildingClass, GreatPeopleRateModifier, FreshWater, AllowsRangeStrike, Defense, ExtraCityHitPoints,CityWall,  Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3ROMEGARDEN_HELP', 'TXT_KEY_BUILDING_3ROMEGARDEN', 'TXT_KEY_BUILDING_3ROMEGARDEN_TEXT', 'TXT_KEY_BUILDING_3ROMEGARDEN_STRATEGY', '3ROMEGARDEN_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_GARDEN';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3ROMEGARDEN',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_GARDEN';

INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
VALUES	('BUILDING_3ROMEGARDEN',	'FLAVOR_CULTURE', 10),
		('BUILDING_3ROMEGARDEN',	'FLAVOR_GROWTH', 10),
		('BUILDING_3ROMEGARDEN',	'FLAVOR_SCIENCE', 10);

------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3ROMEGARDEN',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_GARDEN';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3ROMEGARDEN',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_GARDEN';

INSERT INTO Building_YieldChanges 		
			(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3ROMEGARDEN', 'YIELD_CULTURE', 2),
		('BUILDING_3ROMEGARDEN', 'YIELD_FOOD', 2),
		('BUILDING_3ROMEGARDEN', 'YIELD_SCIENCE', 2);
------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_3ROMEGARDEN',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_3ROMEGARDEN',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3ROMEGARDEN', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3ROMEGARDEN', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_3ROMEGARDEN', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_GARDEN';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_ROME',	'BUILDINGCLASS_GARDEN',	'BUILDING_3ROMEGARDEN');


