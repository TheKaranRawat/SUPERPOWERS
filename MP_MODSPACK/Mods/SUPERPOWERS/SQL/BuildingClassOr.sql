CREATE TABLE IF NOT EXISTS
        Building_ClassesNeededInCityOR (
        BuildingType                                                    text    REFERENCES Buildings(TYPE)                      DEFAULT NULL,
        BuildingClassType                                               text    REFERENCES BuildingClasses(TYPE)                DEFAULT NULL);