-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, Cost, TradeRouteRecipientBonus, TradeRouteTargetBonus,  MaxStartEra, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3UC_STAVE_CHURCH', BuildingClass,  Cost, 1, 1, MaxStartEra, 0, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3UC_STAVE_CHURCH_HELP', 'TXT_KEY_BUILDING_3UC_STAVE_CHURCH', 'TXT_KEY_BUILDING_3UC_STAVE_CHURCH_TEXT', 'TXT_KEY_BUILDING_3UC_STAVE_CHURCH_STRATEGY', 'EXPANSION_SCEN_BUILDING_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_TEMPLE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3UC_STAVE_CHURCH',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_TEMPLE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3UC_STAVE_CHURCH',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_TEMPLE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3UC_STAVE_CHURCH',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_TEMPLE';

------------------------------	
-- Building_ResourceQuantityRequirements
------------------------------
INSERT INTO Building_ResourceQuantityRequirements 	
			(BuildingType, ResourceType, Cost)
SELECT 'BUILDING_3UC_STAVE_CHURCH', ResourceType, Cost
FROM Building_ResourceQuantityRequirements WHERE BuildingType = 'BUILDING_TEMPLE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3UC_STAVE_CHURCH', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_TEMPLE';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_SWEDEN',	'BUILDINGCLASS_TEMPLE',	'BUILDING_3UC_STAVE_CHURCH');


