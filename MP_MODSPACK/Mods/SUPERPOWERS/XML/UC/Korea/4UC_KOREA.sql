-- Buildings
------------------------------	
INSERT INTO Buildings 	
	(Type, BuildingClass, NeverCapture, GreatWorkSlotType, GreatWorkCount, Capital, Happiness, Defense, ArtInfoCulturalVariation, NukeImmune,   Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, Help, Description, Civilopedia, Strategy, IconAtlas, PortraitIndex)
SELECT	'BUILDING_3_GRANDPALACE', BuildingClass, NeverCapture, GreatWorkSlotType, GreatWorkCount, Capital, 4,  Defense, ArtInfoCulturalVariation, NukeImmune,  Cost, GoldMaintenance, PrereqTech, ArtDefineTag, XBuiltTriggersIdeologyChoice, SpecialistType, SpecialistCount, MinAreaSize, ConquestProb, HurryCostModifier, 'TXT_KEY_BUILDING_3_GRANDPALACE_HELP', 'TXT_KEY_BUILDING_3_GRANDPALACE', 'TXT_KEY_BUILDING_3_GRANDPALACE_TEXT', 'TXT_KEY_BUILDING_3_GRANDPALACE_STRATEGY', 'BUILDING_3_GRANDPALACE', 0
FROM Buildings WHERE Type = 'BUILDING_PALACE';	
------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_3_GRANDPALACE',	FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_PALACE';
------------------------------	
-- Building_ClassesNeededInCity
------------------------------		
INSERT INTO Building_ClassesNeededInCity 	
		(BuildingType, 				BuildingClassType)
SELECT	'BUILDING_3_GRANDPALACE',	BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_PALACE';
------------------------------	
-- Building_YieldChanges
------------------------------		
INSERT INTO Building_YieldChanges 	
		(BuildingType, 				YieldType, Yield)
SELECT	'BUILDING_3_GRANDPALACE',	YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_PALACE';

------------------------------	
-- Building_UnitCombatProductionModifiers
------------------------------
INSERT INTO Building_UnitCombatProductionModifiers 	
			(BuildingType, UnitCombatType, Modifier)
SELECT 'BUILDING_3_GRANDPALACE', UnitCombatType, Modifier
FROM Building_UnitCombatProductionModifiers WHERE BuildingType = 'BUILDING_PALACE';

------------------------------	
-- Building_YieldModifiers
------------------------------
INSERT INTO Building_YieldModifiers 	
			(BuildingType, YieldType, Yield)
SELECT 'BUILDING_3_GRANDPALACE', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_PALACE';

------------------------------	
-- Building_ResourceYieldChanges
------------------------------
INSERT INTO Building_ResourceYieldChanges 	
			(BuildingType, ResourceType, YieldType, Yield)
SELECT 'BUILDING_3_GRANDPALACE', ResourceType, YieldType, Yield
FROM Building_ResourceYieldChanges WHERE BuildingType = 'BUILDING_PALACE';

--------------------------------	
-- Civilization_BuildingClassOverrides 
--------------------------------		
INSERT INTO Civilization_BuildingClassOverrides 
		(CivilizationType, 					BuildingClassType, 			BuildingType)
VALUES	('CIVILIZATION_KOREA',	'BUILDINGCLASS_PALACE',	'BUILDING_3_GRANDPALACE');


