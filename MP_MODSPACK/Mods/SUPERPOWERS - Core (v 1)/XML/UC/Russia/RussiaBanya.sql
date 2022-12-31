-- Buildings
------------------------------
INSERT INTO Buildings
	(Type, BuildingClass, Happiness, Defense, ExtraCityHitPoints, CityWall, FoodKept, Cost, GoldMaintenance, PlotCultureCostModifier, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_BANYA', BuildingClass, Happiness, Defense, ExtraCityHitPoints, CityWall, FoodKept, Cost, 0, -25, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_BANYA_HELP', 'TXT_KEY_BUILDING_BANYA', 'TXT_KEY_BUILDING_BANYA_TEXT', 'TXT_KEY_BUILDING_BANYA_STRATEGY', '5UC_ICON_ATLAS', 40
FROM Buildings WHERE Type = 'BUILDING_GARDEN';

------------------------------
-- Building_Flavors
------------------------------
INSERT INTO Building_Flavors 
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_BANYA',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_ClassesNeededInCity
------------------------------
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_BANYA',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_YieldChanges
------------------------------
INSERT INTO Building_YieldChanges	
			(BuildingType, 	YieldType, Yield)
SELECT	'BUILDING_BANYA',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_DomainProductionModifiers
------------------------------
INSERT INTO Building_DomainProductionModifiers 	
			(BuildingType, DomainType, Modifier)
SELECT	'BUILDING_BANYA',	DomainType, Modifier
FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT	'BUILDING_BANYA',	 UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_BANYA', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_BANYA', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_BANYA', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges WHERE BuildingType = 'BUILDING_GARDEN';

------------------------------
-- Building_TerrainYieldChanges
------------------------------
INSERT INTO Building_TerrainYieldChanges	
			(BuildingType, TerrainType, YieldType, Yield)
VALUES ('BUILDING_BANYA', 'TERRAIN_TUNDRA', 'YIELD_FOOD', 1),
	('BUILDING_BANYA', 'TERRAIN_SNOW', 'YIELD_FOOD', 1);

--------------------------------
-- Civilization_BuildingClassOverrides
--------------------------------
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_RUSSIA',	'BUILDINGCLASS_GARDEN',	'BUILDING_BANYA');
