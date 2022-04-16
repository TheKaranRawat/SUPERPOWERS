CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Technologies ORDER BY GridX ASC;
UPDATE Technologies SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Technologies.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM AICityStrategies;
UPDATE AICityStrategies SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE AICityStrategies.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM AIEconomicStrategies;
UPDATE AIEconomicStrategies SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE AIEconomicStrategies.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM AIGrandStrategies;
UPDATE AIGrandStrategies SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE AIGrandStrategies.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM AIMilitaryStrategies;
UPDATE AIMilitaryStrategies SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE AIMilitaryStrategies.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM CitySpecializations;
UPDATE CitySpecializations SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE CitySpecializations.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM TacticalMoves;
UPDATE TacticalMoves SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE TacticalMoves.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Attitudes;
UPDATE Attitudes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Attitudes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Calendars;
UPDATE Calendars SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Calendars.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM CitySizes;
UPDATE CitySizes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE CitySizes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Concepts;
UPDATE Concepts SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Concepts.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Contacts;
UPDATE Contacts SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Contacts.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Domains;
UPDATE Domains SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Domains.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM InvisibleInfos;
UPDATE InvisibleInfos SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE InvisibleInfos.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MajorCivApproachTypes;
UPDATE MajorCivApproachTypes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MajorCivApproachTypes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MinorCivApproachTypes;
UPDATE MinorCivApproachTypes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MinorCivApproachTypes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MinorCivTraits;
UPDATE MinorCivTraits SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MinorCivTraits.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Months;
UPDATE Months SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Months.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Seasons;
UPDATE Seasons SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Seasons.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM UnitAIInfos;
UPDATE UnitAIInfos SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE UnitAIInfos.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM UnitCombatInfos;
UPDATE UnitCombatInfos SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE UnitCombatInfos.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM BuildingClasses;
UPDATE BuildingClasses SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE BuildingClasses.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Buildings;
UPDATE Buildings SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Buildings.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Civilizations;
UPDATE Civilizations SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Civilizations.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MinorCivilizations;
UPDATE MinorCivilizations SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MinorCivilizations.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Regions;
UPDATE Regions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Regions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Traits;
UPDATE Traits SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Traits.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM ArtStyleTypes;
UPDATE ArtStyleTypes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE ArtStyleTypes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Climates;
UPDATE Climates SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Climates.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Cursors;
UPDATE Cursors SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Cursors.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM EmphasizeInfos;
UPDATE EmphasizeInfos SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE EmphasizeInfos.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Eras;
UPDATE Eras SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Eras.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Flavors;
UPDATE Flavors SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Flavors.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM GameOptions;
UPDATE GameOptions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE GameOptions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM GameSpeeds;
UPDATE GameSpeeds SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE GameSpeeds.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM GoodyHuts;
UPDATE GoodyHuts SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE GoodyHuts.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM HandicapInfos;
UPDATE HandicapInfos SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE HandicapInfos.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM HurryInfos;
UPDATE HurryInfos SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE HurryInfos.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MultiplayerOptions;
UPDATE MultiplayerOptions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MultiplayerOptions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM PlayerOptions;
UPDATE PlayerOptions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE PlayerOptions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Policies;
UPDATE Policies SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Policies.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM PolicyBranchTypes;
UPDATE PolicyBranchTypes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE PolicyBranchTypes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Processes;
UPDATE Processes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Processes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM PolicyBranchTypes;
UPDATE PolicyBranchTypes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE PolicyBranchTypes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Projects;
UPDATE Projects SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Projects.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM SeaLevels;
UPDATE SeaLevels SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE SeaLevels.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Specialists;
UPDATE Specialists SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Specialists.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Trades;
UPDATE Trades SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Trades.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM TurnTimers;
UPDATE TurnTimers SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE TurnTimers.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Votes;
UPDATE Votes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Votes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM VoteSources;
UPDATE VoteSources SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE VoteSources.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Worlds;
UPDATE Worlds SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Worlds.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Colors;
UPDATE Colors SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Colors.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM InterfaceModes;
UPDATE InterfaceModes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE InterfaceModes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Leaders;
UPDATE Leaders SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Leaders.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM PlayerColors;
UPDATE PlayerColors SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE PlayerColors.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Routes;
UPDATE Routes SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Routes.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Features;
UPDATE Features SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Features.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM FakeFeatures;
UPDATE FakeFeatures SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE FakeFeatures.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Improvements;
UPDATE Improvements SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Improvements.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM ResourceClasses;
UPDATE ResourceClasses SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE ResourceClasses.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Resources;
UPDATE Resources SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Resources.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Terrains;
UPDATE Terrains SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Terrains.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Yields;
UPDATE Yields SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Yields.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM AnimationCategories;
UPDATE AnimationCategories SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE AnimationCategories.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM AnimationPaths;
UPDATE AnimationPaths SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE AnimationPaths.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Automates;
UPDATE Automates SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Automates.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Builds;
UPDATE Builds SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Builds.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Commands;
UPDATE Commands SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Commands.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Controls;
UPDATE Controls SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Controls.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM EntityEvents;
UPDATE EntityEvents SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE EntityEvents.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Missions;
UPDATE Missions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Missions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MultiUnitFormations;
UPDATE MultiUnitFormations SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MultiUnitFormations.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM MultiUnitPositions;
UPDATE MultiUnitPositions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE MultiUnitPositions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM SpecialUnits;
UPDATE SpecialUnits SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE SpecialUnits.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM UnitClasses;
UPDATE UnitClasses SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE UnitClasses.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM UnitPromotions;
UPDATE UnitPromotions SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE UnitPromotions.Type = IDRemapper.Type);

DROP TABLE IDRemapper;
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Units;
UPDATE Units SET ID =	( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Units.Type = IDRemapper.Type);

DROP TABLE IDRemapper;