-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, ArtInfoEraVariation, NeverCapture, TradeRouteSeaGoldBonus, TradeRouteSeaDistanceModifier, Water, AllowsWaterRoutes, Cost, Defense, GoldMaintenance, ConquestProb, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_COTHON', BuildingClass, ArtInfoEraVariation, NeverCapture, 200, TradeRouteSeaDistanceModifier, Water, AllowsWaterRoutes, Cost, 500, GoldMaintenance, ConquestProb, PrereqTech, ArtDefineTag, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_COTHON_HELP', 'TXT_KEY_BUILDING_3UC_COTHON', 'TXT_KEY_BUILDING_3UC_COTHON_TEXT', 'TXT_KEY_BUILDING_3UC_COTHON_STRATEGY', 'ICON_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_SEAPORT';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_COTHON',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_SEAPORT';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_COTHON',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_SEAPORT';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3UC_COTHON',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_SEAPORT';
------------------------------	
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
VALUES ('BUILDING_3UC_COTHON', 'DOMAIN_SEA', 25);

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_COTHON', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_SEAPORT';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_COTHON', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_SEAPORT';


--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_CARTHAGE',	'BUILDINGCLASS_SEAPORT',	'BUILDING_3UC_COTHON');


