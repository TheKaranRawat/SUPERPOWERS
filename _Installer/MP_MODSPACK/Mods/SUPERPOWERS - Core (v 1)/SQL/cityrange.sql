--CREATE TABLE IF NOT EXISTS Sapiens_DBUpdates (Name TEXT PRIMARY KEY, Value INTEGER DEFAULT 0);
--INSERT OR IGNORE INTO Sapiens_DBUpdates (Name) VALUES ('GAIA_PublicTransport');
    --====================================================================================================================
    -- CITY WORK RANGE CAP
    --====================================================================================================================
--UPDATE Defines SET Value = 5 WHERE Name = 'GD_CITY_WORK_RANGE_MAX' AND Value < 5;



    --====================================================================================================================
    -- CITY WORK RANGE
    --====================================================================================================================
--INSERT OR IGNORE INTO _Building_CityModifiers (BuildingType)
--SELECT Type FROM Buildings WHERE Type IN ('BUILDING_CITY_SIZE_LARGE','BUILDING_CITY_SIZE_XL');
--UPDATE _Building_CityModifiers SET iCityExtraWorkRange = 1
--WHERE BuildingType IN ('BUILDING_CITY_SIZE_LARGE','BUILDING_CITY_SIZE_XL');

--UPDATE _Building_CityModifiers SET iCityExtraWorkRange = 1 WHERE BuildingType IN (SELECT Type FROM Buildings WHERE BuildingClass = 'BUILDINGCLASS_PALACE');

--UPDATE Sapiens_DBUpdates SET Value = 1 WHERE Name = 'GAIA_PublicTransport';