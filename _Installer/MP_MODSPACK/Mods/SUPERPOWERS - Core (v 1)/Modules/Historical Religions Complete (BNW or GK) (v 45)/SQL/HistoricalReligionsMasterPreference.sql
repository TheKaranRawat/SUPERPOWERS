--==========================================================================================================================
-- Vanilla
--==========================================================================================================================

--America
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_AMERICA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_AMERICA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
		THEN 'RELIGION_PROTESTANT_BAPTIST'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_AMERICA';

CREATE TRIGGER CivilizationTierAmerica
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_AMERICA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
			THEN 'RELIGION_PROTESTANT_BAPTIST'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_AMERICA';
END;

--Arabia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ARABIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_ARABIA'; 

--Aztec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_AZTEC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_AZTEC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_AZTEC';

CREATE TRIGGER CivilizationTierAztec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_AZTEC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_AZTEC';
END;

--China
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CHINA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_TAOISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_CHINA'; 

--Egypt
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_EGYPT';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_EGYPT'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_EGYPT';

CREATE TRIGGER CivilizationTierEgypt
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_EGYPT' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_EGYPT';
END;

--England
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ENGLAND';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ENGLAND'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ENGLAND';

CREATE TRIGGER CivilizationTierEngland
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ENGLAND' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ENGLAND';
END;

--France
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_FRANCE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_FRANCE'; 

--Germany
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GERMANY';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GERMANY'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_GERMANY';

CREATE TRIGGER CivilizationTierGermany
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GERMANY' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_GERMANY';
END;

--Greece
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GREECE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GREECE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_GREECE';

CREATE TRIGGER CivilizationTierGreece
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GREECE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_GREECE';
END;

--India
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_INDIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_INDIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VISHNU' )
		THEN 'RELIGION_VISHNU'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_INDIA';

CREATE TRIGGER CivilizationTierIndia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_INDIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VISHNU' )
			THEN 'RELIGION_VISHNU'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_INDIA';
END;

--Iroquois
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_IROQUOIS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_IROQUOIS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
		THEN 'RELIGION_ORENDA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_IROQUOIS';

CREATE TRIGGER CivilizationTierIroquois
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_IROQUOIS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
			THEN 'RELIGION_ORENDA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_IROQUOIS';
END;

--Japan
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JAPAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_SHINTO')
FROM Civilizations WHERE Type = 'CIVILIZATION_JAPAN'; 

--Ottomans
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_OTTOMAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_OTTOMAN'; 

--Persia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_PERSIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ZOROASTRIANISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_PERSIA'; 

--Rome
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ROME';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ROME'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_IMPERIAL_CULT' )
		THEN 'RELIGION_IMPERIAL_CULT'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NUMENISM' )
		THEN 'RELIGION_NUMENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ROME';

CREATE TRIGGER CivilizationTierRome
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ROME' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_IMPERIAL_CULT' )
			THEN 'RELIGION_IMPERIAL_CULT'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NUMENISM' )
			THEN 'RELIGION_NUMENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ROME';
END;

--Russia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RUSSIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RUSSIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_RUSSIA';

CREATE TRIGGER CivilizationTierRussia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RUSSIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_RUSSIA';
END;

--Siam
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SIAM';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SIAM'; 

--Songhai
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SONGHAI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SONGHAI'; 

--==========================================================================================================================
-- DLC
--==========================================================================================================================

--Mongolia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MONGOL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_TENGRIISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MONGOL'; 

--Babylon
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BABYLON';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_BABYLON'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_BABYLON';

CREATE TRIGGER CivilizationTierBabylon
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_BABYLON' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_BABYLON';
END;

--Spain
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SPAIN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SPAIN'; 

--Inca
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_INCA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_INCA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_INTIISM' )
		THEN 'RELIGION_INTIISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_INCA';

CREATE TRIGGER CivilizationTierInca
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_INCA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_INTIISM' )
			THEN 'RELIGION_INTIISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_INCA';
END;

--Polynesia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_POLYNESIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_POLYNESIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
		THEN 'RELIGION_PUTA_TUPUNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_POLYNESIA';

CREATE TRIGGER CivilizationTierPolynesia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_POLYNESIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
			THEN 'RELIGION_PUTA_TUPUNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_POLYNESIA';
END;

--Denmark
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_DENMARK';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_DENMARK'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_DENMARK';

CREATE TRIGGER CivilizationTierDenmark
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_DENMARK' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_DENMARK';
END;

--Korea
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_KOREA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CONFUCIANISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_KOREA'; 

--==========================================================================================================================
-- Gods & Kings
--==========================================================================================================================

--Austria
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_AUSTRIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_AUSTRIA'; 

--Byzantium
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BYZANTIUM';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_BYZANTIUM';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_BYZANTIUM';

CREATE TRIGGER CivilizationTierByzantium
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_BYZANTIUM' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_BYZANTIUM';
END;

--Carthage
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CARTHAGE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_CARTHAGE';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
		THEN 'RELIGION_CANAANISM'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_CARTHAGE';

CREATE TRIGGER CivilizationTierCarthage
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CARTHAGE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
			THEN 'RELIGION_CANAANISM'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_CARTHAGE';
END;

--Celts
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CELTS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CELTS';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_CELTS';

CREATE TRIGGER CivilizationTierCelts
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CELTS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_CELTS';
END;

--Ethiopia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ETHIOPIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ETHIOPIA';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX' )
		THEN 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_ETHIOPIA';

CREATE TRIGGER CivilizationTierEthiopia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ETHIOPIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX' )
			THEN 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_ETHIOPIA';
END;

--Huns
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_HUNS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_TENGRIISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_HUNS'; 

--Maya
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MAYA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MAYA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
		THEN 'RELIGION_TZOLKIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MAYA';

CREATE TRIGGER CivilizationTierMaya
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MAYA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
			THEN 'RELIGION_TZOLKIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MAYA';
END;

--Netherlands
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NETHERLANDS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NETHERLANDS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_NETHERLANDS';

CREATE TRIGGER CivilizationTierDutch
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NETHERLANDS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_NETHERLANDS';
END;

--Sweden
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SWEDEN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SWEDEN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_SWEDEN';

CREATE TRIGGER CivilizationTierSweden
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SWEDEN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_SWEDEN';
END;

--==========================================================================================================================
-- Brave New World
--==========================================================================================================================

--Zulu
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ZULU';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ZULU'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMATONGO' )
		THEN 'RELIGION_AMATONGO'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ZULU';

CREATE TRIGGER CivilizationTierZulu
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ZULU' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMATONGO' )
			THEN 'RELIGION_AMATONGO'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ZULU';
END;

--Venice
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_VENICE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_VENICE';

--Shoshone
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SHOSHONE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SHOSHONE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
		THEN 'RELIGION_POHAKANTENNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
		THEN 'RELIGION_PROTESTANT_BAPTIST'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SHOSHONE';

CREATE TRIGGER CivilizationTierShoshone
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SHOSHONE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
			THEN 'RELIGION_POHAKANTENNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
			THEN 'RELIGION_PROTESTANT_BAPTIST'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SHOSHONE';
END;

--Portugal
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_PORTUGAL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_PORTUGAL'; 

--Poland
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_POLAND';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_POLAND'; 

--Morocco
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MOROCCO';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MOROCCO'; 

--Indonesia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_INDONESIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_INDONESIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_INDONESIA';

CREATE TRIGGER CivilizationTierIndonesia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_INDONESIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_INDONESIA';
END;

--Brazil
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BRAZIL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_BRAZIL'; 

--Assyria
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ASSYRIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ZOROASTRIANISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_ASSYRIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ASHURISM' )
		THEN 'RELIGION_ASHURISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE 'RELIGION_ZOROASTRIANISM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ASSYRIA';

CREATE TRIGGER CivilizationTierAssyria
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ASSYRIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ASHURISM' )
			THEN 'RELIGION_ASHURISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE 'RELIGION_ZOROASTRIANISM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ASSYRIA';
END;

--==========================================================================================================================
-- Tomatekh
--==========================================================================================================================

--Goths
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_VISIGOTHS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_VISIGOTHS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
		THEN 'RELIGION_CHRISTIAN_ARIANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_VISIGOTHS_MOD';

CREATE TRIGGER CivilizationTierGoths
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_VISIGOTHS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
			THEN 'RELIGION_CHRISTIAN_ARIANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_VISIGOTHS_MOD';
END;

--Sumer
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_AKKADIAN_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_AKKADIAN_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_AKKADIAN_MOD';

CREATE TRIGGER CivilizationTierSumer
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_AKKADIAN_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_AKKADIAN_MOD';
END;

--Benin
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BENIN_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_BENIN_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ITAN' )
		THEN 'RELIGION_ITAN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_BENIN_MOD';

CREATE TRIGGER CivilizationTierBenin
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_BENIN_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ITAN' )
			THEN 'RELIGION_ITAN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_BENIN_MOD';
END;

--Garamantes
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ANCIENT_LIBYA_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_ANCIENT_LIBYA_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMANAIISM' )
		THEN 'RELIGION_AMANAIISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ANCIENT_LIBYA_MOD';

CREATE TRIGGER CivilizationTierGaramantes
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ANCIENT_LIBYA_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMANAIISM' )
			THEN 'RELIGION_AMANAIISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ANCIENT_LIBYA_MOD';
END;

--Mali
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MALI_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MALI_MOD'; 

CREATE TRIGGER CivilizationTierMali
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MALI_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions 
	SET ReligionType = 'RELIGION_ISLAM'
	WHERE CivilizationType IN ('CIVILIZATION_MALI_MOD');
END;

--Kievan Rus'
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_KIEVAN_RUS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_KIEVAN_RUS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_KIEVAN_RUS_MOD';

CREATE TRIGGER CivilizationTierKievanRus
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_KIEVAN_RUS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_KIEVAN_RUS_MOD';
END;

--Hittites
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_HITTITE_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_HITTITE_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LIIM_DINGERMES' )
		THEN 'RELIGION_LIIM_DINGERMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_HITTITE_MOD';

CREATE TRIGGER CivilizationTierHittites
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_HITTITE_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LIIM_DINGERMES' )
			THEN 'RELIGION_LIIM_DINGERMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_HITTITE_MOD';
END;

--Timurids
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TIMURIDS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_TIMURIDS_MOD'; 

CREATE TRIGGER CivilizationTierTimurids
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TIMURIDS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions 
	SET ReligionType = 'RELIGION_ISLAM'
	WHERE CivilizationType IN ('CIVILIZATION_TIMURIDS_MOD');
END;

--Harappa
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_HARAPPA_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_HARAPPA_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AKATTU' )
		THEN 'RELIGION_AKATTU'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
		THEN 'RELIGION_VEDIC'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_JAIN' )
		THEN 'RELIGION_JAIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END ) END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_HARAPPA_MOD';

CREATE TRIGGER CivilizationTierHarappa
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_HARAPPA_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AKATTU' )
			THEN 'RELIGION_AKATTU'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
			THEN 'RELIGION_VEDIC'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_JAIN' )
			THEN 'RELIGION_JAIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END ) END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_HARAPPA_MOD';
END;

--Kongo
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_KONGO_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_KONGO_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NZAMBIISM' )
		THEN 'RELIGION_NZAMBIISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_KONGO_MOD';

CREATE TRIGGER CivilizationTierKongo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_KONGO_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NZAMBIISM' )
			THEN 'RELIGION_NZAMBIISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_KONGO_MOD';
END;

--Champa
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CHAMPA_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_CHAMPA_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_CHAMPA_MOD';

CREATE TRIGGER CivilizationTierChampa
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CHAMPA_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_CHAMPA_MOD';
END;

--Sioux
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SIOUX_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SIOUX_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
		THEN 'RELIGION_WAKAN_TANKA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
		THEN 'RELIGION_POHAKANTENNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SIOUX_MOD';

CREATE TRIGGER CivilizationTierSioux
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SIOUX_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
			THEN 'RELIGION_WAKAN_TANKA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
			THEN 'RELIGION_POHAKANTENNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SIOUX_MOD';
END;

--Norte Chico
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NORTE_CHICO_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NORTE_CHICO_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_NORTE_CHICO_MOD';

CREATE TRIGGER CivilizationTierNorteChico
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NORTE_CHICO_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_NORTE_CHICO_MOD';
END;

--Xia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ERLITOU_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_TAOISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_ERLITOU_MOD'; 

CREATE TRIGGER CivilizationTierXia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ERLITOU_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions 
	SET ReligionType = 'RELIGION_TAOISM'
	WHERE CivilizationType IN ('CIVILIZATION_ERLITOU_MOD');
END;

--Shang
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SHANG_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_TAOISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SHANG_MOD'; 

CREATE TRIGGER CivilizationTierShang
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SHANG_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions 
	SET ReligionType = 'RELIGION_TAOISM'
	WHERE CivilizationType IN ('CIVILIZATION_SHANG_MOD');
END;

--Mississippi
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MISSISSIPPI_MOD_TOMATEKH';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MISSISSIPPI_MOD_TOMATEKH'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SOUTHERN_CULT' )
		THEN 'RELIGION_SOUTHERN_CULT'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
		THEN 'RELIGION_ORENDA'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MISSISSIPPI_MOD_TOMATEKH';

CREATE TRIGGER CivilizationTierMississippiEdit
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MISSISSIPPI_MOD_TOMATEKH' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SOUTHERN_CULT' )
			THEN 'RELIGION_SOUTHERN_CULT'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
			THEN 'RELIGION_ORENDA'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MISSISSIPPI_MOD_TOMATEKH';
END;

--Olmec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LEUGI_OLMEC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_LEUGI_OLMEC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
		THEN 'RELIGION_TZOLKIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_LEUGI_OLMEC';

CREATE TRIGGER CivilizationTierCradleOlmec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LEUGI_OLMEC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
			THEN 'RELIGION_TZOLKIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_LEUGI_OLMEC';
END;

--Xingu
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_XINGU_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_XINGU_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PAJELANCA' )
		THEN 'RELIGION_PAJELANCA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_XINGU_MOD';

CREATE TRIGGER CivilizationTierXingu
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_XINGU_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PAJELANCA' )
			THEN 'RELIGION_PAJELANCA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_XINGU_MOD';
END;

--Poverty Point
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_POVERTY_POINT_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_POVERTY_POINT_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SOUTHERN_CULT' )
		THEN 'RELIGION_SOUTHERN_CULT'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
		THEN 'RELIGION_ORENDA'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_POVERTY_POINT_MOD';

CREATE TRIGGER CivilizationTierPovertyPoint
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_POVERTY_POINT_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SOUTHERN_CULT' )
			THEN 'RELIGION_SOUTHERN_CULT'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
			THEN 'RELIGION_ORENDA'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_POVERTY_POINT_MOD';
END;

--Vinca
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_VINCA_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_VINCA_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_BIRD_FIGURE' )
		THEN 'RELIGION_BIRD_FIGURE'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_VINCA_MOD';

CREATE TRIGGER CivilizationTierVinca
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_VINCA_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_BIRD_FIGURE' )
			THEN 'RELIGION_BIRD_FIGURE'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_VINCA_MOD';
END;

--==========================================================================================================================
-- More Civs
--==========================================================================================================================

--Kilwa
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_KILWA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_KILWA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_KILWA';

CREATE TRIGGER CivilizationTierKilwa
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_KILWA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_KILWA';
END;

--Oman
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_OMAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_OMAN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_IBADI' )
		THEN 'RELIGION_ISLAM_IBADI'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_OMAN';

CREATE TRIGGER CivilizationTierOman
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_OMAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_IBADI' )
			THEN 'RELIGION_ISLAM_IBADI'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_OMAN';
END;

DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_OMAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_OMAN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_IBADI' )
		THEN 'RELIGION_ISLAM_IBADI'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_OMAN';

CREATE TRIGGER CivilizationTierOmanTwo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_OMAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_IBADI' )
			THEN 'RELIGION_ISLAM_IBADI'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_OMAN';
END;

--Hawai'i
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_HAWAII';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_HAWAII'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
		THEN 'RELIGION_PUTA_TUPUNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_HAWAII';

CREATE TRIGGER CivilizationTierHawaii
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_HAWAII' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
			THEN 'RELIGION_PUTA_TUPUNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_HAWAII';
END;

--Tonga
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_TONGA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_TONGA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_TONGA';

CREATE TRIGGER CivilizationTierTonga
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_TONGA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_TONGA';
END;

--Rapa Nui
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_RAPA_NUI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_RAPA_NUI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TANGATA_MANU' )
		THEN 'RELIGION_TANGATA_MANU'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_RAPA_NUI';

CREATE TRIGGER CivilizationTierRapaNui
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_RAPA_NUI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TANGATA_MANU' )
			THEN 'RELIGION_TANGATA_MANU'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_RAPA_NUI';
END;

--Maori
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_MAORI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_MAORI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
		THEN 'RELIGION_PUTA_TUPUNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_MAORI';

CREATE TRIGGER CivilizationTieMaori
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_MAORI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
			THEN 'RELIGION_PUTA_TUPUNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_MAORI';
END;

--Thrace
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_THRACE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_THRACE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HEROS_KARABAZMOS' )
		THEN 'RELIGION_HEROS_KARABAZMOS'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_THRACE';

CREATE TRIGGER CivilizationTierMCThrace
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_THRACE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HEROS_KARABAZMOS' )
			THEN 'RELIGION_HEROS_KARABAZMOS'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_THRACE';
END;

--Tibet
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_TIBET';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_TIBET'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VAJRAYANA' )
		THEN 'RELIGION_VAJRAYANA'
		ELSE 'RELIGION_BUDDHISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_TIBET';

CREATE TRIGGER CivilizationTierTibet
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_TIBET' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VAJRAYANA' )
			THEN 'RELIGION_VAJRAYANA'
			ELSE 'RELIGION_BUDDHISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_TIBET';
END;

--Nazca
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NAZCA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NAZCA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_NAZCA';

CREATE TRIGGER CivilizationTierNazca
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NAZCA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_NAZCA';
END;

DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_NAZCA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_NAZCA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_NAZCA';

CREATE TRIGGER CivilizationTierNazcaTwo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_NAZCA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_NAZCA';
END;

--Gauls
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_GAUL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_GAUL'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_GAUL';

CREATE TRIGGER CivilizationTierMCGauls
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_GAUL' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_GAUL';
END;

--Sami
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SAMI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SAMI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NOAIDEVUOHTA' )
		THEN 'RELIGION_NOAIDEVUOHTA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SAMI';

CREATE TRIGGER CivilizationTierSami
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SAMI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NOAIDEVUOHTA' )
			THEN 'RELIGION_NOAIDEVUOHTA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SAMI';
END;

DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_SAMI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_SAMI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NOAIDEVUOHTA' )
		THEN 'RELIGION_NOAIDEVUOHTA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_SAMI';

CREATE TRIGGER CivilizationTierSamiTwo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_SAMI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NOAIDEVUOHTA' )
			THEN 'RELIGION_NOAIDEVUOHTA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_SAMI';
END;

--Phoenicia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_PHOENICIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_JUDAISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_PHOENICIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
		THEN 'RELIGION_CANAANISM'
		ELSE 'RELIGION_JUDAISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_PHOENICIA';

CREATE TRIGGER CivilizationTierMCPhoenicia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_PHOENICIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
			THEN 'RELIGION_CANAANISM'
			ELSE 'RELIGION_JUDAISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_PHOENICIA';
END;

--Bucanners
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BUCCANEER';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_BUCCANEER'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
		THEN 'RELIGION_VODUN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_BUCCANEER';

CREATE TRIGGER CivilizationTierBucanners
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_BUCCANEER' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
			THEN 'RELIGION_VODUN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_BUCCANEER';
END;

DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_BUCCANEER';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_BUCCANEER'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
		THEN 'RELIGION_VODUN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_BUCCANEER';

CREATE TRIGGER CivilizationTierBucannersTwo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_BUCCANEER' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
			THEN 'RELIGION_VODUN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_BUCCANEER';
END;

--Ashanti
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_ASHANTI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_ASHANTI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
		THEN 'RELIGION_ONYAMESOM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_ASHANTI';

CREATE TRIGGER CivilizationTierMCAshanti
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_ASHANTI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
			THEN 'RELIGION_ONYAMESOM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_ASHANTI';
END;

--Chola
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CHOLA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_CHOLA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_CHOLA';

CREATE TRIGGER CivilizationTierChola
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CHOLA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_CHOLA';
END;

DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_CHOLA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_CHOLA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_CHOLA';

CREATE TRIGGER CivilizationTierCholaTwo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_CHOLA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_CHOLA';
END;

--Maratha
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MARATHA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MARATHA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VISHNU' )
		THEN 'RELIGION_VISHNU'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MARATHA';

CREATE TRIGGER CivilizationTierMaratha
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MARATHA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VISHNU' )
			THEN 'RELIGION_VISHNU'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MARATHA';
END;

DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_MARATHA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_MARATHA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VISHNU' )
		THEN 'RELIGION_VISHNU'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_MARATHA';

CREATE TRIGGER CivilizationTierMarathaTwo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_MARATHA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VISHNU' )
			THEN 'RELIGION_VISHNU'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_MARATHA';
END;

--Chinook
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_CHINOOK';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_CHINOOK'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
		THEN 'RELIGION_SGAANAANG'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_CHINOOK';

CREATE TRIGGER CivilizationTierMCChinook
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_CHINOOK' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
			THEN 'RELIGION_SGAANAANG'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_CHINOOK';
END;

--Minoans
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_MINOA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_MINOA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ATANODJUWAJA' )
		THEN 'RELIGION_ATANODJUWAJA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_MINOA';

CREATE TRIGGER CivilizationTierMCMinoans
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_MINOA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ATANODJUWAJA' )
			THEN 'RELIGION_ATANODJUWAJA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_MINOA';
END;

--Athens
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_ATHENS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_ATHENS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_ATHENS';

CREATE TRIGGER CivilizationTierMCAthens
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_ATHENS ' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_ATHENS';
END;

--Sparta
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_SPARTA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_SPARTA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_SPARTA';

CREATE TRIGGER CivilizationTierMCSparta
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_SPARTA ' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_SPARTA';
END;

--Pergamon
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_PERGAMON';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_PERGAMON'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_PERGAMON';

CREATE TRIGGER CivilizationTierMCPergamon
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_PERGAMON ' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_PERGAMON';
END;

--Nubia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_LITE_NUBIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_LITE_NUBIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_LITE_NUBIA';

CREATE TRIGGER CivilizationTierMCNubia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_LITE_NUBIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_LITE_NUBIA';
END;

--Narmer
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_NARMER';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_NARMER'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_MC_NARMER';

CREATE TRIGGER CivilizationTierMCNarmer
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_NARMER' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_MC_NARMER';
END;

--Maasai
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_MAASAI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_MAASAI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LAIBONI' )
		THEN 'RELIGION_LAIBONI'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_MAASAI';

CREATE TRIGGER CivilizationTierMCMaasai
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_MAASAI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LAIBONI' )
			THEN 'RELIGION_LAIBONI'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_MAASAI';
END;

--Zimbabwe
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_ZIMBABWE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_ZIMBABWE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MWARI' )
		THEN 'RELIGION_MWARI'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_ZIMBABWE';

CREATE TRIGGER CivilizationTierZimbabweMC
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_ZIMBABWE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MWARI' )
			THEN 'RELIGION_MWARI'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_ZIMBABWE';
END;

--MC Macedon
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MC_MACEDON';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MC_MACEDON'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MC_MACEDON';

CREATE TRIGGER CivilizationTierMCGreekSplitEdit
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MC_MACEDON ' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MC_MACEDON';
END;

--==========================================================================================================================
-- Leugi
--==========================================================================================================================

--Mapuche
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MAPUCHE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MAPUCHE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WILTRAN_MAPU' )
		THEN 'RELIGION_WILTRAN_MAPU'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_MAPUCHE';

CREATE TRIGGER CivilizationTierMapuche
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MAPUCHE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WILTRAN_MAPU' )
			THEN 'RELIGION_WILTRAN_MAPU'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_MAPUCHE';
END;

--Qullana
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_QULLANA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_QULLANA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SUMA_QAMANA' )
		THEN 'RELIGION_SUMA_QAMANA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_QULLANA';

CREATE TRIGGER CivilizationTierQullana
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_QULLANA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SUMA_QAMANA' )
			THEN 'RELIGION_SUMA_QAMANA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_QULLANA';
END;

--Haiti
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LEUGI_HAITI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_LEUGI_HAITI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
		THEN 'RELIGION_VODUN'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_LEUGI_HAITI';

CREATE TRIGGER CivilizationTierHaitiVoodoo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LEUGI_HAITI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
			THEN 'RELIGION_VODUN'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_LEUGI_HAITI';
END;

--Cuba
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LEUGI_CUBA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_LEUGI_CUBA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SANTERIA' )
		THEN 'RELIGION_SANTERIA'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_LEUGI_CUBA';

CREATE TRIGGER CivilizationTierCubaSanteria
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LEUGI_CUBA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SANTERIA' )
			THEN 'RELIGION_SANTERIA'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_LEUGI_CUBA';
END;

--Tiwanaku
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TIWANAKU';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TIWANAKU'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TIWANAKU';

CREATE TRIGGER CivilizationTierTiwanaku
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TIWANAKU' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TIWANAKU';
END;

--Tupi
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TUPI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TUPI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PAJELANCA' )
		THEN 'RELIGION_PAJELANCA'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TUPI';

CREATE TRIGGER CivilizationTierTupi
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TUPI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PAJELANCA' )
			THEN 'RELIGION_PAJELANCA'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TUPI';
END;

--Muisca
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MUISCA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MUISCA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHIMINAGUA' )
		THEN 'RELIGION_CHIMINAGUA'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_MUISCA';

CREATE TRIGGER CivilizationTierMuisca
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MUISCA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHIMINAGUA' )
			THEN 'RELIGION_CHIMINAGUA'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_MUISCA';
END;

--==========================================================================================================================
-- Trystero49
--==========================================================================================================================

--Inuit
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_INUIT';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_INUIT'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ANGAKKUQISM' )
		THEN 'RELIGION_ANGAKKUQISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_INUIT';

CREATE TRIGGER CivilizationTierTrystInuit
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_INUIT' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ANGAKKUQISM' )
			THEN 'RELIGION_ANGAKKUQISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_INUIT';
END;

--Norway
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NORWAY';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NORWAY'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_NORWAY';

CREATE TRIGGER CivilizationTierTrystNorway
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NORWAY' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_NORWAY';
END;

--==========================================================================================================================
-- Engarde
--==========================================================================================================================

--Desert
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_DESERET';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_DESERET'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_MORMONISM' )
		THEN 'RELIGION_CHRISTIAN_MORMONISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_DESERET';

CREATE TRIGGER CivilizationTierEngarde
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_DESERET' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_MORMONISM' )
			THEN 'RELIGION_CHRISTIAN_MORMONISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_DESERET';
END;

--==========================================================================================================================
-- LastSword
--==========================================================================================================================

--Sumer
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SUMER_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SUMER_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SUMER_LS_MOD';

CREATE TRIGGER CivilizationTierLSSumer
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SUMER_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SUMER_LS_MOD';
END;

--Swiss
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SWISS_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SWISS_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SWISS_LS_MOD';

CREATE TRIGGER CivilizationTierLSSwiss
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SWISS_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SWISS_LS_MOD';
END;

--Goths
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GOTHS_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GOTHS_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
		THEN 'RELIGION_CHRISTIAN_ARIANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_GOTHS_LS_MOD';

CREATE TRIGGER CivilizationTierLSGoths
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GOTHS_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
			THEN 'RELIGION_CHRISTIAN_ARIANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_GOTHS_LS_MOD';
END;

--Australia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_AUSTRALIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_AUSTRALIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TJUKURPA' )
		THEN 'RELIGION_TJUKURPA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_AUSTRALIA_LS_MOD';

CREATE TRIGGER CivilizationTierLSAborigine
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_AUSTRALIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TJUKURPA' )
			THEN 'RELIGION_TJUKURPA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_AUSTRALIA_LS_MOD';
END;

--Scotland
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SCOTLAND_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SCOTLAND_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SCOTLAND_LS_MOD';

CREATE TRIGGER CivilizationTierLastScotland
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SCOTLAND_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SCOTLAND_LS_MOD';
END;

--Nepal
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NEPAL_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_NEPAL_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_NEPAL_LS_MOD';

CREATE TRIGGER CivilizationTierLastNepal
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NEPAL_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_NEPAL_LS_MOD';
END;

--Tibet
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TIBET_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_TIBET_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VAJRAYANA' )
		THEN 'RELIGION_VAJRAYANA'
		ELSE 'RELIGION_BUDDHISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_TIBET';

CREATE TRIGGER CivilizationTierLastTibet
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TIBET' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VAJRAYANA' )
			THEN 'RELIGION_VAJRAYANA'
			ELSE 'RELIGION_BUDDHISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_TIBET';
END;

--Imbangala
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_IMBANGALA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_IMBANGALA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_BUMUNTU' )
		THEN 'RELIGION_BUMUNTU'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMATONGO' )
		THEN 'RELIGION_AMATONGO'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_IMBANGALA_LS_MOD';

CREATE TRIGGER CivilizationTierLastImbangala
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_IMBANGALA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_BUMUNTU' )
			THEN 'RELIGION_BUMUNTU'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMATONGO' )
			THEN 'RELIGION_AMATONGO'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_IMBANGALA_LS_MOD';
END;

--Haida
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_HAIDA_MOD_LS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_HAIDA_MOD_LS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
		THEN 'RELIGION_SGAANAANG'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_HAIDA_MOD_LS';

CREATE TRIGGER CivilizationTierLastHaida
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_HAIDA_MOD_LS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
			THEN 'RELIGION_SGAANAANG'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_HAIDA_MOD_LS';
END;

--Hetaman
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_UKRAINE_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_UKRAINE_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_UKRAINE_LS_MOD';

CREATE TRIGGER CivilizationTierLastHetaman
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_UKRAINE_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_UKRAINE_LS_MOD';
END;

--Sioux
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SIOUX_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SIOUX_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
		THEN 'RELIGION_WAKAN_TANKA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
		THEN 'RELIGION_POHAKANTENNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SIOUX_LS_MOD';

CREATE TRIGGER CivilizationTierLastSioux
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SIOUX_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
			THEN 'RELIGION_WAKAN_TANKA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
			THEN 'RELIGION_POHAKANTENNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SIOUX_LS_MOD';
END;

--Phoenicia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_PHOENICIA_MOD_LS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_JUDAISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_PHOENICIA_MOD_LS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
		THEN 'RELIGION_CANAANISM'
		ELSE 'RELIGION_JUDAISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_PHOENICIA_MOD_LS';

CREATE TRIGGER CivilizationTierLastPhoenicia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_PHOENICIA_MOD_LS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
			THEN 'RELIGION_CANAANISM'
			ELSE 'RELIGION_JUDAISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_PHOENICIA_MOD_LS';
END;

--Ashanti
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ASHANTI_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ASHANTI_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
		THEN 'RELIGION_ONYAMESOM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ASHANTI_LS_MOD';

CREATE TRIGGER CivilizationTierLastAshanti
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ASHANTI_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
			THEN 'RELIGION_ONYAMESOM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ASHANTI_LS_MOD';
END;

--Gauls
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GALLIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GALLIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_GALLIA_LS_MOD';

CREATE TRIGGER CivilizationTierLastGauls
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GALLIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_GALLIA_LS_MOD';
END;

--Tahiti
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TAHITI_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TAHITI_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
		THEN 'RELIGION_PUTA_TUPUNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TAHITI_LS_MOD';

CREATE TRIGGER CivilizationTierLastTahiti
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TAHITI_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PUTA_TUPUNA' )
			THEN 'RELIGION_PUTA_TUPUNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TAHITI_LS_MOD';
END;

--Zimbabwe
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ZIMBABWE_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ZIMBABWE_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MWARI' )
		THEN 'RELIGION_MWARI'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ZIMBABWE_LS_MOD';

CREATE TRIGGER CivilizationTierLastZimbabwe
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ZIMBABWE_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MWARI' )
			THEN 'RELIGION_MWARI'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ZIMBABWE_LS_MOD';
END;

--Olmec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_OLMEC_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_OLMEC_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
		THEN 'RELIGION_TZOLKIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_OLMEC_LS_MOD';

CREATE TRIGGER CivilizationTierLastOlmec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_OLMEC_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
			THEN 'RELIGION_TZOLKIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_OLMEC_LS_MOD';
END;

--Lithuania
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LITHUANIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_LITHUANIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ROMUVA' )
		THEN 'RELIGION_ROMUVA'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_LITHUANIA_LS_MOD';

CREATE TRIGGER CivilizationTierLastLithuania
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LITHUANIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ROMUVA' )
			THEN 'RELIGION_ROMUVA'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_LITHUANIA_LS_MOD';
END;

--Bulgaria
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BULGARIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_BULGARIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_BULGARIA_LS_MOD';

CREATE TRIGGER CivilizationTierLastBulgaria
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_BULGARIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_BULGARIA_LS_MOD';
END;

--Numidia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NUMIDIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_NUMIDIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMANAIISM' )
		THEN 'RELIGION_AMANAIISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_NUMIDIA_LS_MOD';

CREATE TRIGGER TierLastNumida
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NUMIDIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMANAIISM' )
			THEN 'RELIGION_AMANAIISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_NUMIDIA_LS_MOD';
END;

--Hittite
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_HITTITE_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_HITTITE_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LIIM_DINGERMES' )
		THEN 'RELIGION_LIIM_DINGERMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_HITTITE_LS_MOD';

CREATE TRIGGER CivilizationTierLastHittites
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_HITTITE_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LIIM_DINGERMES' )
			THEN 'RELIGION_LIIM_DINGERMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_HITTITE_LS_MOD';
END;

--Cherokee
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CHEROKEE_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CHEROKEE_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
		THEN 'RELIGION_ORENDA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
		THEN 'RELIGION_PROTESTANT_BAPTIST'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CHEROKEE_LS_MOD';

CREATE TRIGGER CivilizationTierLastCherokee
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CHEROKEE_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
			THEN 'RELIGION_ORENDA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
			THEN 'RELIGION_PROTESTANT_BAPTIST'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CHEROKEE_LS_MOD';
END;

--Romania
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ROMANIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ROMANIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_ROMANIA_LS_MOD';

CREATE TRIGGER CivilizationTierLastRomania
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ROMANIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_ROMANIA_LS_MOD';
END;

--Scythia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SCYTHIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ZOROASTRIANISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SCYTHIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SAIRIMAISM' )
		THEN 'RELIGION_SAIRIMAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
		THEN 'RELIGION_VEDIC'
		ELSE 'RELIGION_ZOROASTRIANISM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SCYTHIA_LS_MOD';

CREATE TRIGGER CivilizationTierLastScythia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SCYTHIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SAIRIMAISM' )
			THEN 'RELIGION_SAIRIMAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
			THEN 'RELIGION_VEDIC'
			ELSE 'RELIGION_ZOROASTRIANISM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SCYTHIA_LS_MOD';
END;

--Sparta
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SPARTA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SPARTA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SPARTA_LS_MOD';

CREATE TRIGGER CivilizationTierLastSparta
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SPARTA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SPARTA_LS_MOD';
END;

--Viking
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_VIKING_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_VIKING_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_VIKING_LS_MOD';

CREATE TRIGGER CivilizationTierLastViking
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_VIKING_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_VIKING_LS_MOD';
END;

--Minoans
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MINOAN_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MINOAN_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ATANODJUWAJA' )
		THEN 'RELIGION_ATANODJUWAJA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MINOAN_LS_MOD';

CREATE TRIGGER CivilizationTierLastMinoans
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MINOAN_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ATANODJUWAJA' )
			THEN 'RELIGION_ATANODJUWAJA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MINOAN_LS_MOD';
END;

--Pirates
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CARIBBEAN_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CARIBBEAN_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
		THEN 'RELIGION_VODUN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CARIBBEAN_LS_MOD';

CREATE TRIGGER CivilizationTierLastPirates
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CARIBBEAN_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VODUN' )
			THEN 'RELIGION_VODUN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CARIBBEAN_LS_MOD';
END;

--Mapuche
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MAPUCHE_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MAPUCHE_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WILTRAN_MAPU' )
		THEN 'RELIGION_WILTRAN_MAPU'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_MAPUCHE_LS_MOD';

CREATE TRIGGER CivilizationTierLastMapuche
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MAPUCHE_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WILTRAN_MAPU' )
			THEN 'RELIGION_WILTRAN_MAPU'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_MAPUCHE_LS_MOD';
END;

--Kongo
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NDONGO_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NDONGO_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NZAMBIISM' )
		THEN 'RELIGION_NZAMBIISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_NDONGO_LS_MOD';

CREATE TRIGGER CivilizationTierLastNdongo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NDONGO_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NZAMBIISM' )
			THEN 'RELIGION_NZAMBIISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_NDONGO_LS_MOD';
END;

--Blackfoot
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NIIT_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NIIT_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
		THEN 'RELIGION_WAKAN_TANKA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
		THEN 'RELIGION_POHAKANTENNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_NIIT_LS_MOD';

CREATE TRIGGER CivilizationTierLastNiitsitapi
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NIIT_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
			THEN 'RELIGION_WAKAN_TANKA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
			THEN 'RELIGION_POHAKANTENNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_NIIT_LS_MOD';
END;

--==========================================================================================================================
-- Hiram
--==========================================================================================================================

--Ryuku
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RYUKYU';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_RYUKYU'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
		THEN 'RELIGION_MAHAYANA'
		ELSE 'RELIGION_BUDDHISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_RYUKYU';

CREATE TRIGGER CivilizationTierHiramRyuku
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RYUKYU' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
			THEN 'RELIGION_MAHAYANA'
			ELSE 'RELIGION_BUDDHISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_RYUKYU';
END;

--Wales
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_WALES';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_WALES'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_WALES';

CREATE TRIGGER CivilizationTierHiramWales
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_WALES' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_WALES';
END;

--Kulin
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_KULINNATION';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_KULINNATION'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TJUKURPA' )
		THEN 'RELIGION_TJUKURPA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_KULINNATION';

CREATE TRIGGER CivilizationTierHiramKulin
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_KULINNATION' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TJUKURPA' )
			THEN 'RELIGION_TJUKURPA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_KULINNATION';
END;

--Chimu
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CHIMU_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CHIMU_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_CHIMU_MOD';

CREATE TRIGGER CivilizationTierHiramChimu
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CHIMU_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_CHIMU_MOD';
END;

--Lithuania
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_KDMLITHUANIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_KDMLITHUANIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ROMUVA' )
		THEN 'RELIGION_ROMUVA'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_KDMLITHUANIA';

CREATE TRIGGER CivilizationTierHiramLithuania
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_KDMLITHUANIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ROMUVA' )
			THEN 'RELIGION_ROMUVA'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_KDMLITHUANIA';
END;

--Uyghur
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_UYGHUR';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_TENGRIISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_UYGHUR'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANICHAEISM' )
		THEN 'RELIGION_MANICHAEISM'
		ELSE 'RELIGION_TENGRIISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_UYGHUR';

CREATE TRIGGER CivilizationTierHiramUyghur
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_UYGHUR' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANICHAEISM' )
			THEN 'RELIGION_MANICHAEISM'
			ELSE 'RELIGION_TENGRIISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_UYGHUR';
END;

--Mitanni
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MITANNI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_MITANNI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LIIM_DINGERMES' )
		THEN 'RELIGION_LIIM_DINGERMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MITANNI';

CREATE TRIGGER CivilizationTierHiramMitanni
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MITANNI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_LIIM_DINGERMES' )
			THEN 'RELIGION_LIIM_DINGERMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MITANNI';
END;

--Iceni
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ICENI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ICENI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_ICENI';

CREATE TRIGGER CivilizationTierHiramIceni
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ICENI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_ICENI';
END;

--Cornwall
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CORNWALL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CORNWALL'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CORNWALL';

CREATE TRIGGER CivilizationTierHiramCornwall
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CORNWALL' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CORNWALL';
END;

--Picts
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_PICTS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_PICTS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_PICTS';

CREATE TRIGGER CivilizationTierHiramPicts
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_PICTS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_PICTS';
END;

--Seleucid
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SELEUCID';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SELEUCID'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SELEUCID';

CREATE TRIGGER CivilizationTierHiramSeleucid
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SELEUCID' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SELEUCID';
END;

--Saba
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SABA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SABA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AL_ASNAM' )
		THEN 'RELIGION_AL_ASNAM'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_SABA';

CREATE TRIGGER CivilizationTierHiramSaba
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SABA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AL_ASNAM' )
			THEN 'RELIGION_AL_ASNAM'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_SABA';
END;

--Nabatae
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NABATAEA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_NABATAEA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AL_ASNAM' )
		THEN 'RELIGION_AL_ASNAM'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_NABATAEA';

CREATE TRIGGER CivilizationTierHiramNabatae
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NABATAEA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AL_ASNAM' )
			THEN 'RELIGION_AL_ASNAM'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_NABATAEA';
END;

--==========================================================================================================================
-- Colonial Legacies
--==========================================================================================================================

--Blackfoot
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_BLACKFOOTFIRSTNATION';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_BLACKFOOTFIRSTNATION'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
		THEN 'RELIGION_WAKAN_TANKA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
		THEN 'RELIGION_POHAKANTENNA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_BLACKFOOTFIRSTNATION';

CREATE TRIGGER CivilizationTierColBlackfoot
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_BLACKFOOTFIRSTNATION' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_WAKAN_TANKA' )
			THEN 'RELIGION_WAKAN_TANKA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_POHAKANTENNA' )
			THEN 'RELIGION_POHAKANTENNA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_BLACKFOOTFIRSTNATION';
END;

--Cree
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_THECREEFIRSTNATION';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_THECREEFIRSTNATION'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
		THEN 'RELIGION_ORENDA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_THECREEFIRSTNATION';

CREATE TRIGGER CivilizationTierColLegCree
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_THECREEFIRSTNATION' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
			THEN 'RELIGION_ORENDA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_THECREEFIRSTNATION';
END;

--Dene
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_DENEFIRSTNATION';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_DENEFIRSTNATION'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
		THEN 'RELIGION_SGAANAANG'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_DENEFIRSTNATION';

CREATE TRIGGER CivilizationTierColDene
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_DENEFIRSTNATION' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
			THEN 'RELIGION_SGAANAANG'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_DENEFIRSTNATION';
END;

--Inuit
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CLINUIT';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CLINUIT'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ANGAKKUQISM' )
		THEN 'RELIGION_ANGAKKUQISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CLINUIT';

CREATE TRIGGER CivilizationTierColInuit
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CLINUIT' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ANGAKKUQISM' )
			THEN 'RELIGION_ANGAKKUQISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CLINUIT';
END;

--Afhganistan
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CL_AFGHANISTAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_CL_AFGHANISTAN'; 

CREATE TRIGGER CivilizationTierCLAfghanistan
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CL_AFGHANISTAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions 
	SET ReligionType = 'RELIGION_ISLAM'
	WHERE CivilizationType IN ('CIVILIZATION_CL_AFGHANISTAN');
END;

--Zapotec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CLZAPOTEC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CLZAPOTEC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_CLZAPOTEC';

CREATE TRIGGER CivilizationTierCLZapotec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CLZAPOTEC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_CLZAPOTEC';
END;

--==========================================================================================================================
-- AggresiveWimp
--==========================================================================================================================

--Georgia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GEORGIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GEORGIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_GEORGIA';

CREATE TRIGGER CivilizationTierAWGeorgia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GEORGIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_GEORGIA';
END;

--Switzerland
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SWITZERLAND';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SWITZERLAND'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SWITZERLAND';

CREATE TRIGGER CivilizationTierAWSwiss
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SWITZERLAND' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SWITZERLAND';
END;

--Harappa
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_HARAPPAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_HARAPPAN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AKATTU' )
		THEN 'RELIGION_AKATTU'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
		THEN 'RELIGION_VEDIC'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_JAIN' )
		THEN 'RELIGION_JAIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END ) END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_HARAPPAN';

CREATE TRIGGER CivilizationTierAWHarappa
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_HARAPPAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AKATTU' )
			THEN 'RELIGION_AKATTU'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
			THEN 'RELIGION_VEDIC'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_JAIN' )
			THEN 'RELIGION_JAIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END ) END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_HARAPPAN';
END;

--Minoans
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_MINOAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_MINOAN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_MINOAN';

CREATE TRIGGER CivilizationTierAWMinoans
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_MINOAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_MINOAN';
END;

--Zapotec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ZAPOTEC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ZAPOTEC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_ZAPOTEC';

CREATE TRIGGER CivilizationTierAWZapotec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ZAPOTEC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_ZAPOTEC';
END;

--==========================================================================================================================
-- TarcisioTM
--==========================================================================================================================

--Iberia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_THE_IBERIANS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_THE_IBERIANS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TCM_THE_IBERIANS';

CREATE TRIGGER CivilizationTierTarcioIberia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_THE_IBERIANS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TCM_THE_IBERIANS';
END;

--Rome
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_AURELIAN_ROME';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_AURELIAN_ROME'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_IMPERIAL_CULT' )
		THEN 'RELIGION_IMPERIAL_CULT'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NUMENISM' )
		THEN 'RELIGION_NUMENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TCM_AURELIAN_ROME';

CREATE TRIGGER CivilizationTierTarcioRome
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_AURELIAN_ROME' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_IMPERIAL_CULT' )
			THEN 'RELIGION_IMPERIAL_CULT'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NUMENISM' )
			THEN 'RELIGION_NUMENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TCM_AURELIAN_ROME';
END;

--Alans
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_ALAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ZOROASTRIANISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_ALAN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SAIRIMAISM' )
		THEN 'RELIGION_SAIRIMAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
		THEN 'RELIGION_VEDIC'
		ELSE 'RELIGION_ZOROASTRIANISM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TCM_ALAN';

CREATE TRIGGER CivilizationTierTCMAlan
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_ALAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SAIRIMAISM' )
			THEN 'RELIGION_SAIRIMAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_VEDIC' )
			THEN 'RELIGION_VEDIC'
			ELSE 'RELIGION_ZOROASTRIANISM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TCM_ALAN';
END;

--Ptolemaic
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_PTOLEMAIC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_PTOLEMAIC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TCM_PTOLEMAIC';

CREATE TRIGGER CivilizationTierTCMPtolemaic
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_PTOLEMAIC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TCM_PTOLEMAIC';
END;

--Holy Roman Empire
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_HRE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_HRE'; 

CREATE TRIGGER CivilizationTierTCMHolyRoman
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_HRE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions 
	SET ReligionType = 'RELIGION_CHRISTIANITY'
	WHERE CivilizationType IN ('CIVILIZATION_TCM_HRE');
END;

--Etruscan
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_ETRUSCAN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_ETRUSCAN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NUMENISM' )
		THEN 'RELIGION_NUMENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TCM_ETRUSCAN';

CREATE TRIGGER CivilizationTierTCMEtruscan
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_ETRUSCAN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_NUMENISM' )
			THEN 'RELIGION_NUMENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TCM_ETRUSCAN';
END;

--Suebi
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_SUEBI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_SUEBI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TCM_SUEBI';

CREATE TRIGGER CivilizationTierTCMSuebi
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_SUEBI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TCM_SUEBI';
END;

--Germany
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GREATEREUROPE_GERMANY';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GREATEREUROPE_GERMANY'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_GREATEREUROPE_GERMANY';

CREATE TRIGGER CivilizationTierTCMGermany
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GREATEREUROPE_GERMANY' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_GREATEREUROPE_GERMANY';
END;

--Hyksos
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_HYKSOS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_JUDAISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_HYKSOS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
		THEN 'RELIGION_CANAANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_JUDAISM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_TCM_HYKSOS';

CREATE TRIGGER CivilizationTierTCMHyksos
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_HYKSOS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
			THEN 'RELIGION_CANAANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_JUDAISM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_TCM_HYKSOS';
END;

--==========================================================================================================================
-- Han
--==========================================================================================================================

--Akkad
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_AKKADIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_AKKADIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_AKKADIA';

CREATE TRIGGER CivilizationTierHanAkkad
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_AKKADIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_AKKADIA';
END;

--Chimu
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CHIMOR';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CHIMOR'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
		THEN 'RELIGION_PACHISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_CHIMOR';

CREATE TRIGGER CivilizationTierHanChimu
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CHIMOR' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PACHISM' )
			THEN 'RELIGION_PACHISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_CHIMOR';
END;

--==========================================================================================================================
-- Viregel
--==========================================================================================================================

--Picts
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GE_PICTS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GE_PICTS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
		THEN 'RELIGION_DRUIDISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_GE_PICTS';

CREATE TRIGGER CivilizationTierViregelPicts
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GE_PICTS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_DRUIDISM' )
			THEN 'RELIGION_DRUIDISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_GE_PICTS';
END;

--UK
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_UNITED_KINGDOM';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_UNITED_KINGDOM'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_UNITED_KINGDOM';

CREATE TRIGGER CivilizationTierViregelUK
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_UNITED_KINGDOM' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_UNITED_KINGDOM';
END;

--Sealand
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SEALAND';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SEALAND'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SEALAND';

CREATE TRIGGER CivilizationTierViregelSealand
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SEALAND' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SEALAND';
END;

--Slavs
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_GE_SLAVS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_GE_SLAVS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SLAVIANISM' )
		THEN 'RELIGION_SLAVIANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_GE_SLAVS';

CREATE TRIGGER CivilizationTierViregelSlavs
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_GE_SLAVS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SLAVIANISM' )
			THEN 'RELIGION_SLAVIANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_GE_SLAVS';
END;

--==========================================================================================================================
-- DJSHenniger
--==========================================================================================================================

--Armenia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ARMENIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ARMENIA';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX' )
		THEN 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_ARMENIA';

CREATE TRIGGER CivilizationTierDJSHennigerArmenia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ARMENIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX' )
			THEN 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_ARMENIA';
END;

--Nepal
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NEPAL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_HINDUISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_NEPAL'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
		THEN 'RELIGION_SHIVA'
		ELSE 'RELIGION_HINDUISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_NEPAL';

CREATE TRIGGER CivilizationTierDJSHennigerNepal
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NEPAL' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SHIVA' )
			THEN 'RELIGION_SHIVA'
			ELSE 'RELIGION_HINDUISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_NEPAL';
END;

--==========================================================================================================================
-- JFD
--==========================================================================================================================

--Vandals
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_THE_VANDALS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_THE_VANDALS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
		THEN 'RELIGION_CHRISTIAN_ARIANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_THE_VANDALS';

CREATE TRIGGER CivilizationTierJFDVandals
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_THE_VANDALS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
			THEN 'RELIGION_CHRISTIAN_ARIANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_THE_VANDALS';
END;

--Armenia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_ARMENIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_ARMENIA';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX' )
		THEN 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_ARMENIA';

CREATE TRIGGER CivilizationTierJFDArmenia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_ARMENIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX' )
			THEN 'RELIGION_CHRISTIAN_ORIENTAL_ORTHODOX'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_ARMENIA';
END;

--Lithuania
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_LITHUANIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_LITHUANIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ROMUVA' )
		THEN 'RELIGION_ROMUVA'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_LITHUANIA';

CREATE TRIGGER CivilizationTierJFDLithuania
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_LITHUANIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ROMUVA' )
			THEN 'RELIGION_ROMUVA'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_LITHUANIA';
END;

--Switzerland
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_SWITZERLAND';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_SWITZERLAND'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
		THEN 'RELIGION_PROTESTANT_CALVINISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_SWITZERLAND';

CREATE TRIGGER CivilizationTierJFDSwiss
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_SWITZERLAND' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_CALVINISM' )
			THEN 'RELIGION_PROTESTANT_CALVINISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_SWITZERLAND';
END;

--Russia: Nicholas
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_NICHOLAS_RUSSIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_NICHOLAS_RUSSIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_NICHOLAS_RUSSIA';

CREATE TRIGGER CivilizationTierJFDNick
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_NICHOLAS_RUSSIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_NICHOLAS_RUSSIA';
END;

--Russia: Lenin
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_USSR_LENIN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_USSR_LENIN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_USSR_LENIN';

CREATE TRIGGER CivilizationTierJFDLenin
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_USSR_LENIN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_USSR_LENIN';
END;

--Russia: Peter
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_PETRINE_RUSSIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_PETRINE_RUSSIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_PETRINE_RUSSIA';

CREATE TRIGGER CivilizationTierJFDPeter
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_PETRINE_RUSSIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_PETRINE_RUSSIA';
END;

--Russia: Stalin
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_USSR_STALIN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_USSR_STALIN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_USSR_STALIN';

CREATE TRIGGER CivilizationTierJFDStalin
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_USSR_STALIN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_USSR_STALIN';
END;

--England: Churchill
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_UNITED_KINGDOM';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_UNITED_KINGDOM'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_UNITED_KINGDOM';

CREATE TRIGGER CivilizationTierJFDChurchill
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_UNITED_KINGDOM' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_UNITED_KINGDOM';
END;

--England: Victoria
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_GREAT_BRITAIN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_GREAT_BRITAIN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_GREAT_BRITAIN';

CREATE TRIGGER CivilizationTierJFDVictoria
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_GREAT_BRITAIN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_GREAT_BRITAIN';
END;

--Carthage: Hannibal
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_CARTHAGE_HANNIBAL';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_CARTHAGE_HANNIBAL';

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
		THEN 'RELIGION_CANAANISM'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_CARTHAGE_HANNIBAL';

CREATE TRIGGER CivilizationTierJFDHannibal
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_CARTHAGE_HANNIBAL' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
			THEN 'RELIGION_CANAANISM'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_CARTHAGE_HANNIBAL';
END;

--Prussia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_PRUSSIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_PRUSSIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_PRUSSIA';

CREATE TRIGGER CivilizationTierJFDPrussia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_PRUSSIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_PRUSSIA';
END;

--Germany: Hitler
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_NAZI_GERMANY';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_NAZI_GERMANY'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_NAZI_GERMANY';

CREATE TRIGGER CivilizationTierJFDHitler
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_NAZI_GERMANY' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_NAZI_GERMANY';
END;

--America: Lincoln
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_AMERICA_LINCOLN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_AMERICA_LINCOLN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_AMERICA_LINCOLN';

CREATE TRIGGER CivilizationTierJFDLincoln
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_AMERICA_LINCOLN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_AMERICA_LINCOLN';
END;

--America: Roosevelt
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_AMERICA_ROOSEVELT';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_AMERICA_ROOSEVELT'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_AMERICA_ROOSEVELT';

CREATE TRIGGER CivilizationTierJFDRoosevelt
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_AMERICA_ROOSEVELT' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_AMERICA_ROOSEVELT';
END;

--JFD Germans
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_GERMANS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_GERMANS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_GERMANS';

CREATE TRIGGER CivilizationTierJFDClassicGermans
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_GERMANS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_GERMANS';
END;

--JFD Iceland
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_ICELAND';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_ICELAND'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_JFD_ICELAND';

CREATE TRIGGER CivilizationTierJFDIceland
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_ICELAND' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_JFD_ICELAND';
END;

--JFD Igbo
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_NRI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_NRI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ODINANI' )
		THEN 'RELIGION_ODINANI'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ITAN' )
		THEN 'RELIGION_ITAN'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_NRI';

CREATE TRIGGER CivilizationTierJFDIgbo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_NRI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ODINANI' )
			THEN 'RELIGION_ODINANI'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ITAN' )
			THEN 'RELIGION_ITAN'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_NRI';
END;

--JFD Aten
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_EGYPT_AKHENATEN';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_EGYPT_AKHENATEN'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ATENISM' )
		THEN 'RELIGION_ATENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_EGYPT_AKHENATEN';

CREATE TRIGGER CivilizationTierJFDAten
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_EGYPT_AKHENATEN' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ATENISM' )
			THEN 'RELIGION_ATENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_EGYPT_AKHENATEN';
END;

--JFD Bohemia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_JFD_BOHEMIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_JFD_BOHEMIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HUSSITISM' )
		THEN 'RELIGION_HUSSITISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_JFD_BOHEMIA';

CREATE TRIGGER CivilizationTierJFDBohemia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_JFD_BOHEMIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HUSSITISM' )
			THEN 'RELIGION_HUSSITISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_JFD_BOHEMIA';
END;

--==========================================================================================================================
-- Light in the East
--==========================================================================================================================

--Safavids
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SAFAVIDS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_SAFAVIDS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_SAFAVIDS';

CREATE TRIGGER CivilizationTierRegalmanSafavids
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SAFAVIDS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_SAFAVIDS';
END;

--Srivijaya
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LITE_SRIVIJAYA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_LITE_SRIVIJAYA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
		THEN 'RELIGION_MAHAYANA'
		ELSE 'RELIGION_BUDDHISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_LITE_SRIVIJAYA';

CREATE TRIGGER CivilizationTierRegalmanSrivijaya
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LITE_SRIVIJAYA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
			THEN 'RELIGION_MAHAYANA'
			ELSE 'RELIGION_BUDDHISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_LITE_SRIVIJAYA';
END;

--Indo-Greek
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LITE_INDO_GREEK';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_LITE_INDO_GREEK'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
		THEN 'RELIGION_MAHAYANA'
		ELSE 'RELIGION_BUDDHISM' END 
	) WHERE CivilizationType = 'CIVILIZATION_LITE_INDO_GREEK';

CREATE TRIGGER CivilizationTierRegalmanIndoGreek
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LITE_INDO_GREEK' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
			THEN 'RELIGION_MAHAYANA'
			ELSE 'RELIGION_BUDDHISM' END 
		) WHERE CivilizationType = 'CIVILIZATION_LITE_INDO_GREEK';
END;

--North Korea
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LITE_NORTH_KOREA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_BUDDHISM')
FROM Civilizations WHERE Type = 'CIVILIZATION_LITE_NORTH_KOREA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_JUCHE' )
		THEN 'RELIGION_JUCHE'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MUISM' )
		THEN 'RELIGION_MUISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
		THEN 'RELIGION_MAHAYANA'
		ELSE 'RELIGION_BUDDHISM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_LITE_NORTH_KOREA';

CREATE TRIGGER CivilizationTierRegalmanNorthKorea
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LITE_NORTH_KOREA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_JUCHE' )
			THEN 'RELIGION_JUCHE'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MUISM' )
			THEN 'RELIGION_MUISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MAHAYANA' )
			THEN 'RELIGION_MAHAYANA'
			ELSE 'RELIGION_BUDDHISM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_LITE_NORTH_KOREA';
END;

--Ainu
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LITE_AINU';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_SHINTO')
FROM Civilizations WHERE Type = 'CIVILIZATION_LITE_AINU'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SAMAN' )
		THEN 'RELIGION_SAMAN'
		ELSE 'RELIGION_SHINTO' END 
	) WHERE CivilizationType = 'CIVILIZATION_LITE_AINU';

CREATE TRIGGER CivilizationTierRegalmanAinu
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LITE_AINU' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SAMAN' )
			THEN 'RELIGION_SAMAN'
			ELSE 'RELIGION_SHINTO' END 
		) WHERE CivilizationType = 'CIVILIZATION_LITE_AINU';
END;

--Akkad
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_LITE_AKKAD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_LITE_AKKAD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_LITE_AKKAD';

CREATE TRIGGER CivilizationTierLIEAkkad
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_LITE_AKKAD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_LITE_AKKAD';
END;

--==========================================================================================================================
-- Moriboe
--==========================================================================================================================

--Igbo
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NRI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_NRI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ODINANI' )
		THEN 'RELIGION_ODINANI'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ITAN' )
		THEN 'RELIGION_ITAN'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_NRI';

CREATE TRIGGER CivilizationTierMoriboeIgbo
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NRI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ODINANI' )
			THEN 'RELIGION_ODINANI'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ITAN' )
			THEN 'RELIGION_ITAN'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_NRI';
END;

--==========================================================================================================================
-- DMS
--==========================================================================================================================

--Nuraghians
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_DMS_NURAGIC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_DMS_NURAGIC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MYSTERIES' )
		THEN 'RELIGION_MYSTERIES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_DMS_NURAGIC';

CREATE TRIGGER CivilizationTierDMSNuragic
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_DMS_NURAGIC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MYSTERIES' )
			THEN 'RELIGION_MYSTERIES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_DMS_NURAGIC';
END;

--==========================================================================================================================
-- RyanJames
--==========================================================================================================================

--Olmec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ROLMEC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ROLMEC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
		THEN 'RELIGION_TZOLKIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ROLMEC';

CREATE TRIGGER CivilizationTierRyanJamesOlmec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ROLMEC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
			THEN 'RELIGION_TZOLKIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ROLMEC';
END;

--Trypillian
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RTRYPILLIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ORTHODOXY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RTRYPILLIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_BIRD_FIGURE' )
		THEN 'RELIGION_BIRD_FIGURE'
		ELSE 'RELIGION_ORTHODOXY' END 
	) WHERE CivilizationType = 'CIVILIZATION_RTRYPILLIA';

CREATE TRIGGER CivilizationTierRyanJamesTrypillian
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RTRYPILLIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_BIRD_FIGURE' )
			THEN 'RELIGION_BIRD_FIGURE'
			ELSE 'RELIGION_ORTHODOXY' END 
		) WHERE CivilizationType = 'CIVILIZATION_RTRYPILLIA';
END;

--Manx
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CALC_MANX';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CALC_MANX'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CALC_MANX';

CREATE TRIGGER CivilizationTierRyanJamesManx
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CALC_MANX' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CALC_MANX';
END;

--Cromwell
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_PROTECTORATE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_PROTECTORATE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_PROTECTORATE';

CREATE TRIGGER CivilizationTierRyanJamesCromwell
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_PROTECTORATE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_PROTECTORATE';
END;

--Akkad
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RAKKAD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_RAKKAD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
		THEN 'RELIGION_SISKURMES'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
		THEN 'RELIGION_ISLAM_SHIA'
		ELSE 'RELIGION_ISLAM' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_RAKKAD';

CREATE TRIGGER CivilizationTierRyanJamesAkkad
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RAKKAD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SISKURMES' )
			THEN 'RELIGION_SISKURMES'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ISLAM_SHIA' )
			THEN 'RELIGION_ISLAM_SHIA'
			ELSE 'RELIGION_ISLAM' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_RAKKAD';
END;

--Mossi
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RMOSSI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RMOSSI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
		THEN 'RELIGION_ONYAMESOM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_RMOSSI';

CREATE TRIGGER CivilizationTierRyanJamesMossi
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RMOSSI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
			THEN 'RELIGION_ONYAMESOM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_RMOSSI';
END;

--Lydia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RLYDIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RLYDIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
		THEN 'RELIGION_HELLENISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
		THEN 'RELIGION_ORTHODOXY'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_RLYDIA';

CREATE TRIGGER CivilizationTierRyanJamesLydia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RLYDIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_HELLENISM' )
			THEN 'RELIGION_HELLENISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORTHODOXY' )
			THEN 'RELIGION_ORTHODOXY'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_RLYDIA';
END;

--Cherokee
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RCHEROKEE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RCHEROKEE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
		THEN 'RELIGION_ORENDA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
		THEN 'RELIGION_PROTESTANT_BAPTIST'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_RCHEROKEE';

CREATE TRIGGER CivilizationTierRyanJamesCherokee
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RCHEROKEE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ORENDA' )
			THEN 'RELIGION_ORENDA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_BAPTIST' )
			THEN 'RELIGION_PROTESTANT_BAPTIST'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_RCHEROKEE';
END;

--Last Edit

--Murri
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CL_MURRI';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CL_MURRI'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TJUKURPA' )
		THEN 'RELIGION_TJUKURPA'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CL_MURRI';

CREATE TRIGGER CivilizationTierLastCLMurri
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CL_MURRI' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TJUKURPA' )
			THEN 'RELIGION_TJUKURPA'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CL_MURRI';
END;

--Palmyra
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_FB_PALMYRA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ORTHODOXY')
FROM Civilizations WHERE Type = 'CIVILIZATION_FB_PALMYRA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
		THEN 'RELIGION_CANAANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
		THEN 'RELIGION_CHALDEANISM'
		ELSE 'RELIGION_ORTHODOXY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_FB_PALMYRA';

CREATE TRIGGER CivilizationTierLastFBPalmyra
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_FB_PALMYRA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CANAANISM' )
			THEN 'RELIGION_CANAANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHALDEANISM' )
			THEN 'RELIGION_CHALDEANISM'
			ELSE 'RELIGION_ORTHODOXY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_FB_PALMYRA';
END;

--Dahomey
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_DAHOMEY_TS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_DAHOMEY_TS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
		THEN 'RELIGION_ONYAMESOM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_DAHOMEY_TS';

CREATE TRIGGER CivilizationTierLastSPDahomey
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_DAHOMEY_TS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_ONYAMESOM' )
			THEN 'RELIGION_ONYAMESOM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_DAHOMEY_TS';
END;

--Ostrogoths
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_OSTROGOTH';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_OSTROGOTH'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
		THEN 'RELIGION_CHRISTIAN_ARIANISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TCM_OSTROGOTH';

CREATE TRIGGER CivilizationTierLastTCOstrgoths
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_OSTROGOTH' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
			THEN 'RELIGION_CHRISTIAN_ARIANISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TCM_OSTROGOTH';
END;

--Visigoths
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_VISIGOTH';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_VISIGOTH'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
		THEN 'RELIGION_CHRISTIAN_ARIANISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TCM_VISIGOTH';

CREATE TRIGGER CivilizationTierLastTCVisigoths
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_VISIGOTH' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ARIANISM' )
			THEN 'RELIGION_CHRISTIAN_ARIANISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TCM_VISIGOTH';
END;

--Moravia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TCM_GREAT_MORAVIA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TCM_GREAT_MORAVIA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SLAVIANISM' )
		THEN 'RELIGION_SLAVIANISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TCM_GREAT_MORAVIA';

CREATE TRIGGER CivilizationTierLastTCMoravia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TCM_GREAT_MORAVIA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SLAVIANISM' )
			THEN 'RELIGION_SLAVIANISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TCM_GREAT_MORAVIA';
END;

--Samoa
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CL_SAMOA';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CL_SAMOA'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
		THEN 'RELIGION_MANAISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CL_SAMOA';

CREATE TRIGGER CivilizationTierLastCLSamoa
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CL_SAMOA' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_MANAISM' )
			THEN 'RELIGION_MANAISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CL_SAMOA';
END;

--Tlingit
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_CL_TLINGIT';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_CL_TLINGIT'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
		THEN 'RELIGION_SGAANAANG'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_CL_TLINGIT';

CREATE TRIGGER CivilizationTierLastCLTlingit
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_CL_TLINGIT' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_SGAANAANG' )
			THEN 'RELIGION_SGAANAANG'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_CL_TLINGIT';
END;

--Serer
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_SERER_TS';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_SERER_TS'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FAT_ROOG' )
		THEN 'RELIGION_FAT_ROOG'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
		THEN 'RELIGION_PROTESTANT_METHODISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_SERER_TS';

CREATE TRIGGER CivilizationTierLastTSSerer
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_SERER_TS' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FAT_ROOG' )
			THEN 'RELIGION_FAT_ROOG'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANT_METHODISM' )
			THEN 'RELIGION_PROTESTANT_METHODISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_SERER_TS';
END;

--Gaunches
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RGUANCHE';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RGUANCHE'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMANAIISM' )
		THEN 'RELIGION_AMANAIISM'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_RGUANCHE';

CREATE TRIGGER CivilizationTierLastRJGaunches
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RGUANCHE' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_AMANAIISM' )
			THEN 'RELIGION_AMANAIISM'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_RGUANCHE';
END;

--Toltec
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_RTOLTEC';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_RTOLTEC'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
		THEN 'RELIGION_TZOLKIN'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END ) END
	) WHERE CivilizationType = 'CIVILIZATION_RTOLTEC';

CREATE TRIGGER CivilizationTierLastRJToltec
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_RTOLTEC' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TZOLKIN' )
			THEN 'RELIGION_TZOLKIN'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END ) END
		) WHERE CivilizationType = 'CIVILIZATION_RTOLTEC';
END;

--Manx
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ORRY_MANX';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_ORRY_MANX'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
		THEN 'RELIGION_FORN_SIDR'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
		THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
		ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
		THEN 'RELIGION_PROTESTANTISM'
		ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
	) WHERE CivilizationType = 'CIVILIZATION_ORRY_MANX';

CREATE TRIGGER CivilizationTierLastRJManx
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_ORRY_MANX' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_FORN_SIDR' )
			THEN 'RELIGION_FORN_SIDR'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_CHRISTIAN_ANGLICANISM' )
			THEN 'RELIGION_CHRISTIAN_ANGLICANISM'
			ELSE ( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PROTESTANTISM' )
			THEN 'RELIGION_PROTESTANTISM'
			ELSE 'RELIGION_CHRISTIANITY' END ) END ) END
		) WHERE CivilizationType = 'CIVILIZATION_ORRY_MANX';
END;

--Nubia
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_NUBIA_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_ISLAM')
FROM Civilizations WHERE Type = 'CIVILIZATION_NUBIA_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
		THEN 'RELIGION_PESEDJET'
		ELSE 'RELIGION_ISLAM' END 
	) WHERE CivilizationType = 'CIVILIZATION_NUBIA_LS_MOD';

CREATE TRIGGER CivilizationTierLastLastNubia
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_NUBIA_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_PESEDJET' )
			THEN 'RELIGION_PESEDJET'
			ELSE 'RELIGION_ISLAM' END 
		) WHERE CivilizationType = 'CIVILIZATION_NUBIA_LS_MOD';
END;

--Teotichuan
DELETE FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_TEO_LS_MOD';
INSERT INTO Civilization_Religions 
		        (CivilizationType,	ReligionType)
SELECT		Type,			('RELIGION_CHRISTIANITY')
FROM Civilizations WHERE Type = 'CIVILIZATION_TEO_LS_MOD'; 

UPDATE Civilization_Religions SET ReligionType = 
	( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
		THEN 'RELIGION_TLATEOMATILIZTLI'
		ELSE 'RELIGION_CHRISTIANITY' END 
	) WHERE CivilizationType = 'CIVILIZATION_TEO_LS_MOD';

CREATE TRIGGER CivilizationTierLastLastTeotichuan
AFTER INSERT ON Civilization_Religions WHEN 'CIVILIZATION_TEO_LS_MOD' = NEW.CivilizationType
BEGIN
	UPDATE Civilization_Religions SET ReligionType = 
		( CASE WHEN EXISTS(SELECT Type FROM Religions WHERE Type = 'RELIGION_TLATEOMATILIZTLI' )
			THEN 'RELIGION_TLATEOMATILIZTLI'
			ELSE 'RELIGION_CHRISTIANITY' END 
		) WHERE CivilizationType = 'CIVILIZATION_TEO_LS_MOD';
END;