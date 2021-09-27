-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, AllowsRangeStrike, Happiness, Defense, ExtraCityHitPoints, CityWall, Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_GUMBOOT_GUILD', BuildingClass, AllowsRangeStrike, Happiness, Defense, ExtraCityHitPoints,CityWall,  Cost, GoldMaintenance, 'TECH_MINING', ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_GUMBOOT_GUILD_HELP', 'TXT_KEY_BUILDING_GUMBOOT_GUILD', 'TXT_KEY_BUILDING_GUMBOOT_GUILD_TEXT', 'TXT_KEY_BUILDING_GUMBOOT_GUILD_STRATEGY', 'GUMBOOT_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_CIRCUS';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_GUMBOOT_GUILD',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_CIRCUS';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_GUMBOOT_GUILD',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_CIRCUS';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_GUMBOOT_GUILD',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_CIRCUS';
------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_GUMBOOT_GUILD',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_CIRCUS';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_GUMBOOT_GUILD',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_CIRCUS';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_GUMBOOT_GUILD', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_CIRCUS';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_GUMBOOT_GUILD', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_CIRCUS';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_GUMBOOT_GUILD', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges  WHERE BuildingType = 'BUILDING_CIRCUS';

INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
VALUES ('BUILDING_GUMBOOT_GUILD', 'RESOURCE_GOLD', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_SILVER', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_GEMS', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_COPPER', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_IRON', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_COAL', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_ALUMINUM', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_URANIUM', 'YIELD_PRODUCTION', 1),
		('BUILDING_GUMBOOT_GUILD', 'RESOURCE_SALT', 'YIELD_PRODUCTION', 1);

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_ZULU',	'BUILDINGCLASS_CIRCUS',	'BUILDING_GUMBOOT_GUILD');


