-----------------------------------------------------------------------------------------------------
--Font Mapping
----------------------------------------------------------------------------------------------------- 
INSERT INTO IconFontTextures (IconFontTexture,	IconFontTextureFile)
SELECT 'ICON_FONT_TEXTURE_TOPCITIES',			'TopCities-FontIcons';

INSERT INTO IconFontMapping (IconName,	IconFontTexture,				IconMapping)
SELECT 'ICON_TOPCITY',					'ICON_FONT_TEXTURE_TOPCITIES',	1;

--------------------------------------------------------------------------------------------------
--Icon Atlas 
--------------------------------------------------------------------------------------------------
INSERT INTO IconTextureAtlases (Atlas,	IconSize,	IconsPerRow,	IconsPerColumn,	Filename)
SELECT 'TOPCITIES_ATLAS',				256,		1,				1,				'TopCities_Icon256.dds' UNION ALL
SELECT 'TOPCITIES_ATLAS',				128,		1,				1,				'TopCities_Icon128.dds' UNION ALL
SELECT 'TOPCITIES_ATLAS',				80,			1,				1,				'TopCities_Icon80.dds' UNION ALL
SELECT 'TOPCITIES_ATLAS',				64,			1,				1,				'TopCities_Icon64.dds' UNION ALL
SELECT 'TOPCITIES_ATLAS',				45,			1,				1,				'TopCities_Icon45.dds';

--------------------------------------------------------------------------------------------------
--Building Classes
--------------------------------------------------------------------------------------------------
INSERT INTO BuildingClasses (Type,			DefaultBuilding,				MaxPlayerInstances,	Description)
SELECT 'BUILDINGCLASS_TC_TRIUMPHARCH',		'BUILDING_TC_TRIUMPHARCH',		1,					'TXT_KEY_BUILDING_TC_TRIUMPHARCH';

--------------------------------------------------------------------------------------------------
--Buildings
--------------------------------------------------------------------------------------------------
INSERT INTO Buildings (Type,		BuildingClass,					NeverCapture,	Cost,	NumCityCostMod,	HurryCostModifier,	GoldenAge,	UnmoddedHappiness,	NukeImmune,	IconAtlas,			PortraitIndex,	Description,						Help,									Strategy,									Civilopedia,									ArtDefineTag,	MinAreaSize) 
SELECT 'BUILDING_TC_TRIUMPHARCH',	'BUILDINGCLASS_TC_TRIUMPHARCH',	1,				110,	30,				-1,					1,			1,					1,			'TOPCITIES_ATLAS',	0,				'TXT_KEY_BUILDING_TC_TRIUMPHARCH',	'TXT_KEY_BUILDING_TC_TRIUMPHARCH_HELP',	'TXT_KEY_BUILDING_TC_TRIUMPHARCH_STRATEGY',	'TXT_KEY_CIV5_BUILDINGS_TC_TRIUMPHARCH_TEXT',	'COURTHOUSE',	-1;

--------------------------------------------------------------------------------------------------
--Building Flavors
--------------------------------------------------------------------------------------------------
INSERT INTO Building_Flavors (BuildingType,		FlavorType,							Flavor)
SELECT 'BUILDING_TC_TRIUMPHARCH',				'FLAVOR_HAPPINESS',					80 UNION ALL
SELECT 'BUILDING_TC_TRIUMPHARCH',				'FLAVOR_WONDER',					25 UNION ALL
SELECT 'BUILDING_TC_TRIUMPHARCH',				'FLAVOR_PRODUCTION',				50 UNION ALL
SELECT 'BUILDING_TC_TRIUMPHARCH',				'FLAVOR_GOLD',						50;

-----------------------------------------------------------------------------------------------------
--Pedia Entries
----------------------------------------------------------------------------------------------------- 
INSERT INTO Concepts (Type,			Topic,					Description,								Summary,									AdvisorQuestion,			Advisor,	CivilopediaHeaderType)
SELECT 'CONCEPT_GREATEST_CITY',		'TXT_KEY_TOPIC_CITIES',	'TXT_KEY_CITIES_GREATEST_HEADING3_TITLE',	'TXT_KEY_CITIES_GREATEST_HEADING3_BODY',	'TXT_KEY_CITIES_ADV_QUEST',	'ECONOMIC',	'HEADER_SUPERPOWERS';
