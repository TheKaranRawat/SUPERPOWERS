--Increases boost of Walls of Sargon, if 3UC is installed.

------------------------------
-- Building_YieldChanges
------------------------------
UPDATE Building_YieldChanges
SET	Yield=2
WHERE BuildingType='BUILDING_SARGON3_FORT' AND YieldType='YIELD_PRODUCTION';