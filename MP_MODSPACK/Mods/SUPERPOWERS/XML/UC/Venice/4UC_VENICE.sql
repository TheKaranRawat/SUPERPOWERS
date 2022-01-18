-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, NeverCapture, GreatWorkSlotType, GreatWorkCount, Capital, Defense, ArtInfoCulturalVariation, NukeImmune,   Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3DOGEPALACE', BuildingClass, NeverCapture, GreatWorkSlotType, GreatWorkCount, Capital, 500, ArtInfoCulturalVariation, NukeImmune,  Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3DOGEPALACE_HELP', 'TXT_KEY_BUILDING_3DOGEPALACE', 'TXT_KEY_BUILDING_3DOGEPALACE_TEXT', 'TXT_KEY_BUILDING_3DOGEPALACE_STRATEGY', '3DOGEPALACE_ATLAS', 0
FROM Buildings WHERE Type = 'BUILDING_PALACE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3DOGEPALACE',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_PALACE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3DOGEPALACE',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_PALACE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
VALUES ('BUILDING_3DOGEPALACE',	'YIELD_CULTURE', 3),
		('BUILDING_3DOGEPALACE','YIELD_SCIENCE', 3),
		('BUILDING_3DOGEPALACE','YIELD_PRODUCTION', 3),
		('BUILDING_3DOGEPALACE','YIELD_GOLD', 3);

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT 'BUILDING_3DOGEPALACE', UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_PALACE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3DOGEPALACE', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_PALACE';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_3DOGEPALACE', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges WHERE BuildingType = 'BUILDING_PALACE';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_VENICE',	'BUILDINGCLASS_PALACE',	'BUILDING_3DOGEPALACE');


