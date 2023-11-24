--==========================================================================================================================	
-- BUILDINGS
--==========================================================================================================================	
-- Buildings
------------------------------
INSERT INTO Buildings 	
		(Type, 						BuildingClass, Cost, GoldMaintenance, PrereqTech,		Water, TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, Description, 					Civilopedia, 						Help, 									Strategy,									PlotBuyCostModifier, ArtDefineTag, 	ArtInfoEraVariation, DisplayPosition, AllowsWaterRoutes, MinAreaSize, ConquestProb, GreatPeopleRateModifier, FreshWater, HurryCostModifier, SpecialistType, SpecialistCount, PortraitIndex, 	IconAtlas)
SELECT	'BUILDING_CL_FALE_TELE',	BuildingClass, 90, 0, 'TECH_THEOLOGY',	Water, TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, 'TXT_KEY_BUILDING_CL_FALE_TELE', 	'TXT_KEY_CIV5_CL_FALE_TELE_TEXT', 	'TXT_KEY_BUILDING_CL_FALE_TELE_HELP', 	'TXT_KEY_BUILDING_CL_FALE_TELE_STRATEGY',		-15,				 ArtDefineTag,	ArtInfoEraVariation, DisplayPosition, AllowsWaterRoutes, MinAreaSize, ConquestProb, GreatPeopleRateModifier, FreshWater, HurryCostModifier, SpecialistType, SpecialistCount, 18, 				'5UC_ICON_ATLAS'
FROM Buildings WHERE Type = 'BUILDING_HARBOR';	

------------------------------	
-- Building_Flavors
------------------------------		
INSERT INTO Building_Flavors 	
		(BuildingType, 				FlavorType, Flavor)
SELECT	'BUILDING_CL_FALE_TELE',		FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_HARBOR';	

INSERT INTO Building_Flavors
		(BuildingType,				FlavorType,				Flavor)
VALUES	('BUILDING_CL_FALE_TELE',		'FLAVOR_GROWTH',		25);

--==========================================================================================================================	
-- Civilization_BuildingClassOverrides 
--==========================================================================================================================		
INSERT INTO Civilization_BuildingClassOverrides 
			(CivilizationType, 			BuildingClassType, 			 BuildingType)
VALUES		('CIVILIZATION_POLYNESIA', 	'BUILDINGCLASS_HARBOR',		'BUILDING_CL_FALE_TELE');

------------------------------	
-- Building_SeaResourceYieldChanges
------------------------------		
INSERT INTO Building_SeaResourceYieldChanges 	
		(BuildingType, 		YieldType, Yield)
VALUES	('BUILDING_CL_FALE_TELE',	'YIELD_CULTURE',	2);

------------------------------	
-- Building_FeatureYieldChanges
------------------------------		
INSERT INTO Building_FeatureYieldChanges 	
		(BuildingType,		 FeatureType,		YieldType, Yield)
VALUES	('BUILDING_CL_FALE_TELE',	'FEATURE_ATOLL',	'YIELD_CULTURE',	1);
