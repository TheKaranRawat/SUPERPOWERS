------------------------------
-- Buildings
------------------------------
UPDATE Buildings
SET BuildingClass=(SELECT	BuildingClass FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	XBuiltTriggersIdeologyChoice=(SELECT	XBuiltTriggersIdeologyChoice FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	Cost=(SELECT	Cost FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	GoldMaintenance=(SELECT	GoldMaintenance FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	PrereqTech=(SELECT	PrereqTech FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	ArtDefineTag=(SELECT	ArtDefineTag FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	SpecialistType=(SELECT	SpecialistType FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	SpecialistCount=(SELECT	SpecialistCount FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	MinAreaSize=(SELECT	MinAreaSize FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	ConquestProb=(SELECT	ConquestProb FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	HurryCostModifier=(SELECT	HurryCostModifier FROM Buildings WHERE Type = 'BUILDING_WINDMILL'),
	BuildingProductionModifier=(SELECT	BuildingProductionModifier FROM Buildings WHERE Type = 'BUILDING_WINDMILL')
WHERE Type='BUILDING_3UC_TEXTILE';

------------------------------
-- Building_YieldChanges
------------------------------
UPDATE Building_YieldChanges
SET	Yield=(SELECT	Yield FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_WINDMILL' AND YieldType='YIELD_PRODUCTION')
WHERE BuildingType='BUILDING_3UC_TEXTILE' AND YieldType='YIELD_PRODUCTION';
