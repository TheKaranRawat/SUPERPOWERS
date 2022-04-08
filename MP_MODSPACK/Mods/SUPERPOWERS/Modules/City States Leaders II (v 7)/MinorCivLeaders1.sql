UPDATE MinorCivTraits SET BackgroundImage = 'CityStateBackgroundDefault.dds';

CREATE TABLE IF NOT EXISTS MinorCivLeaders (
	'ID' INTEGER PRIMARY KEY AUTOINCREMENT,
	'Type' TEXT NOT NULL UNIQUE,
	'LeaderIcon' TEXT NOT NULL,
	'ModernCountry' TEXT DEFAULT NULL,
	'ShortModernCountry' TEXT DEFAULT NULL,
	'LeaderPlace' TEXT DEFAULT NULL,
	'LeaderName' TEXT DEFAULT NULL,
	'LeaderTitle' TEXT DEFAULT NULL,
	'LeaderSuffix' TEXT DEFAULT NULL,
	'LeaderArtistName' TEXT DEFAULT NULL,
	FOREIGN KEY (Type) REFERENCES MinorCivilizations(Type));

INSERT INTO MinorCivLeaders(
		Type,						LeaderIcon,						ModernCountry,							ShortModernCountry,		LeaderPlace,			LeaderName,				LeaderTitle,		LeaderSuffix,	LeaderArtistName)
--SELECT	'ARTPACK',					'NONE',							'',										'',						'',						'',						'',					'',				''						UNION ALL
SELECT	'MINOR_CIV_ALMATY',			'almaty_leadericon.dds',		'The Republic of Kazakhstan',			'Kazakhstan',			'the Kazakh Khanate',	'Janybek Khan',			'',					'the Wise',		'knightmare13'			UNION ALL
SELECT	'MINOR_CIV_ANTANANARIVO',	'antananarivo_leadericon.dds',	'The Republic of Madagascar',			'Madagascar',			'the Kingdom of Madagascar', 'Ranavalona I',	'Queen',			'',				'Nutty'					UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_ANTANANARIVO',	'antananarivo_leadericon2.dds',	'The Republic of Madagascar',	'Madagascar',	'the Kingdom of Imerina',	'Andrianampoinimerina',	'King',	'',	'TPangolin'	UNION ALL
SELECT	'MINOR_CIV_ANTWERP',		'antwerp_leadericon.dds',		'Flanders, Kingdom of Belgium',			'Flanders',				'Flanders',				'Robert III',			'Count',			'the Lion',		'janboruta'				UNION ALL
SELECT	'MINOR_CIV_BELGRADE',		'belgrade_leadericon.dds',		'The Republic of Serbia',				'Serbia',				'Serbia',				'Karadorde Petrovic',	'Grand Leader',		'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_BOGOTA',			'bogota_leadericon.dds',		'The Republic of Colombia',				'Colombia',				'Gran Colombia',		'Simon Bolivar',		'President',		'',				'Leugi'					UNION ALL
SELECT	'MINOR_CIV_BRATISLAVA',		'bratislava_leadericon.dds',	'The Slovak Republic',					'Slovakia',				'Great Moravia',		'Svatopluk I',			'King',				'the Great',	'J. Kohler/Nutty'		UNION ALL
SELECT	'MINOR_CIV_BRUSSELS',		'brussels_leadericon.dds',		'The Kingdom of Belgium',				'Belgium',				'the Belgians',			'Leopold II',			'King',				'',	'janboruta'	UNION ALL
SELECT	'MINOR_CIV_BUCHAREST',		'bucharest_leadericon.dds',		'Romania',								'Romania',				'Wallachia',			'Vlad III',				'Prince',			'the Impaler',	'janboruta'				UNION ALL
SELECT	'MINOR_CIV_BUDAPEST',		'budapest_leadericon.dds',		'Hungary',								'Hungary',				'the Hungarians',		'Stephen I',			'King',				'the Saint',	'janboruta'				UNION ALL
SELECT	'MINOR_CIV_BUENOS_AIRES',	'buenos_aires_leadericon.dds',	'The Argentine Republic',				'Argentina',			'Argentina',			'Eva Peron',			'',					'',				'Leugi'					UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_BUENOS_AIRES',	'buenos_aires_leadericon2.dds',	'The Argentine Republic',	'Argentina',	'Cuyo, United Provinces', 'Jose de San Martin',	'General Don',	'',	'Leugi'	UNION ALL
SELECT	'MINOR_CIV_BYBLOS',			'byblos_leadericon.dds',		'Mount Lebanon, Lebanese Republic',		'Mount Lebanon',		'Byblos',				'Ahiram',				'King',				'',				'LastSword'				UNION ALL
SELECT	'MINOR_CIV_CAHOKIA',		'cahokia_leadericon.dds',		'The Peoria Tribe',						'the Peoria',			'the Mississippians',	'Birdman',				'King',				'',				'H. Roe/Nutty'			UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_CAHOKIA',	'cahokia_leadericon2.dds',	'The Peoria Tribe',	'the Peoria',	'the Mississippians',	'Birdman',	'King',	'',	'H. Roe/TPangolin'	UNION ALL
SELECT	'MINOR_CIV_CAPE_TOWN',		'cape_town_leadericon.dds',		'The Republic of South Africa',			'South Africa',			'Cape Town',			'Jan van Riebeeck',		'Commander',		'',				'janboruta'				UNION ALL
--[pre-BNW name:]
--SELECT	'MINOR_CAPE_TOWN',			'cape_town_leadericon.dds',		'The Republic of South Africa',			'South Africa',			'Cape Town',			'Jan van Riebeeck',		'Commander',		'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_COLOMBO',		'colombo_leadericon.dds',		'The Democratic Socialist Republic of Sri Lanka', 'Sri Lanka',	'Ceylon',				'D.S. Senanayake',		'Prime Minister',	'',				'knightmare13'			UNION ALL
SELECT	'MINOR_CIV_FLORENCE',		'florence_leadericon.dds',		'Tuscany, Italian Republic',			'Tuscany',				'Florence',				 "Lorenzo de'Medici",	 '',				'the Magnificent', 'sukritact'			UNION ALL
SELECT	'MINOR_CIV_GENEVA',			'geneva_leadericon.dds',		'Geneva, Swiss Confederation',			'Geneva',				'Geneva',				'John Calvin',			'Pastor',			'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_GENOA',			'genoa_leadericon.dds',			'Liguria, Italian Republic',			'Liguria',				'Genoa',				'Andrea Doria',			'Condottiero',		'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_HANOI',			'hanoi_leadericon.dds',			'The Socialist Republic of Vietnam',	'Vietnam',				'Dai Viet',				'Ly Thai To',			'Emperor',			'the Revered',	'davey_henninger'		UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_HANOI',	'hanoi_leadericon2.dds',	'The Socialist Republic of Vietnam',	'Vietnam',	'Vietnam',	'Ho Chi Minh',	'President',	'',	'knightmare13'	UNION ALL
SELECT	'MINOR_CIV_HONG_KONG',		'hong_kong_leadericon.dds',		"Hong Kong, People's Republic of China", 'Hong Kong',			'Hong Kong',			'Kai Ho',				'Sir',				'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_IFE',			'ife_leadericon.dds',			'The Federal Republic of Nigeria',		'Nigeria',				'Ife',					'Akinmoyero',			'Ooni',				'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_JERUSALEM',		'jerusalem_leadericon.dds',		'The State of Israel',					'Israel',				'Israel',				'Solomon',				'King',				'the Wise',		'Leugi'					UNION ALL
SELECT	'MINOR_CIV_KABUL',			'kabul_leadericon.dds',			'The Islamic Republic of Afghanistan',	'Afghanistan',			'Afghanistan',			'Ahmad Shah Durrani',	'Emir',				'',				'LastSword'				UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_KABUL',	'kabul_leadericon2.dds',	'The Islamic Republic of Afghanistan',	'Afghanistan',	'Afghanistan',	'Ahmad Shah Durrani',	'Emir',	'',	'TPangolin'	UNION ALL
SELECT	'MINOR_CIV_KATHMANDU',		'kathmandu_leadericon.dds',		'The Federal Democratic Republic of Nepal', 'Nepal',			'Nepal',				'Tribhuvan',			'King',				'',				'Leugi'					UNION ALL
--[pre-BNW name:]
--SELECT	'MINOR_CIV_SEOUL',			'kathmandu_leadericon.dds',		'The Federal Democratic Republic of Nepal', 'Nepal',			'Nepal',				'Tribhuvan',			'King',				'',				'Leugi'					UNION ALL
SELECT	'MINOR_CIV_KIEV',			'kiev_leadericon.dds',			'Ukraine',								'Ukraine',				'Kiev',					'Yaroslav',				'Grand Prince',		'the Wise',		'janboruta'				UNION ALL
SELECT	'MINOR_CIV_KUALA_LUMPUR',	'kuala_lumpur_leadericon.dds',	'Malaysia',								'Malaysia',				'Kuala Lumpur',			'Yap Ah Loy',			'Kapitan',			'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_KYZYL',			'kyzyl_leadericon.dds',			'The Tuva Republic, Russian Federation', 'Tuva',				'the Little Khural',	'Khertek Anchimaa-Toka', 'Chairperson',		'',				'Nutty'					UNION ALL
SELECT	'MINOR_CIV_LA_VENTA',		'la_venta_leadericon.dds',		'Tabasco, The United Mexican States',	'Tabasco',				'the Olmec',			'Po Ngbe',				'Ku',				'',				'LastSword'				UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_LA_VENTA',	'la_venta_leadericon2.dds',	'Tabasco, The United Mexican States',	'Tabasco',	'the Olmec',	'Po Ngbe',	'Ku',	'',	'Leugi'	UNION ALL
SELECT	'MINOR_CIV_LHASA',			'lhasa_leadericon.dds',			'Free Tibet',							'Tibet',				'Tibet',				'Thubten Gyatso',		'Dalai Lama',		'',				'sukritact'				UNION ALL
SELECT	'MINOR_CIV_MALACCA',		'malacca_leadericon.dds',		'Malacca, Malaysia',					'Malacca',				'Kedah',				'Abdul Halim',			'Sultan',			'',				'Nutty'					UNION ALL
SELECT	'MINOR_CIV_MANILA',			'manila_leadericon.dds',		'The Republic of the Philippines',		'the Philippines',		'the Philippines',		'Jose Rizal',			'',					'',				'knightmare13'			UNION ALL
SELECT	'MINOR_CIV_MBANZA_KONGO',	'mbanza_kongo_leadericon.dds',	'The Republic of Angola',				'Angola',				'Andongo',				'Njinga Mbande',		'Queen',			'',				'Leugi'					UNION ALL
SELECT	'MINOR_CIV_MELBOURNE',		'melbourne_leadericon.dds',		'Victoria, Commonwealth of Australia',	'Victoria',				'Melbourne',			'John Batman',			'',					'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_MILAN',			'milan_leadericon.dds',			'Lombardy, Italian Republic',			'Lombardy',				'Milan',				'Gian Galeazzo Visconti', 'Duke',			'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_MOGADISHU',		'mogadishu_leadericon.dds',		'The Federal Republic of Somalia',		'Somalia',				'Somalia',				'Aden Adde',			'President',		'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_MOMBASA',		'mombasa_leadericon.dds',		'The Republic of Kenya',				'Kenya',				'Kenya',				'Jomo Kenyatta',		'President',		'',				'knightmare13'			UNION ALL
SELECT	'MINOR_CIV_MONACO',			'monaco_leadericon.dds',		'The Principality of Monaco',			'Monaco',				'Monaco',				'Rainier III',			'Prince',			'',				'knightmare13'			UNION ALL
SELECT	'MINOR_CIV_ORMUS',			'ormus_leadericon.dds',			'The Sultanate of Oman',				'Oman',					'Ormus',				'Qaboos bin Said',		'Sultan',			'',				'knightmare13'			UNION ALL
SELECT	'MINOR_CIV_PANAMA_CITY',	'panama_city_leadericon.dds',	'The Republic of Panama',				'Panama',				'Panama',				'Victoriano Lorenzo',	'General',			'',				'Leugi'					UNION ALL
SELECT	'MINOR_CIV_PRAGUE',			'prague_leadericon.dds',		'The Czech Republic',					'Czech Republic',		'Bohemia',				'Wenceslaus II',		'King',				'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_QUEBEC_CITY',	'quebec_city_leadericon.dds',	'Canada',								'Canada',				'Canada',				'John A. MacDonald',	'Prime Minister',	'',				'davey_henninger'		UNION ALL
--[pre-BNW name:]
--SELECT	'MINOR_CIV_OSLO',			'quebec_city_leadericon.dds',	'Canada',								'Canada',				'Canada',				'John A. MacDonald',	'Prime Minister',	'',				'davey_henninger'		UNION ALL
SELECT	'MINOR_CIV_RAGUSA',			'ragusa_leadericon.dds',		'The Republic of Croatia',				'Croatia',				'Ragusa',				'Auguste de Marmont',	'Duke',				'the Betrayer',	'Nutty'					UNION ALL
SELECT	'MINOR_CIV_RIGA',			'riga_leadericon.dds',			'The Republic of Latvia',				'Latvia',				'Latvia',				'Janis Cakste',			'President',		'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_SAMARKAND',		'samarkand_leadericon.dds',		'The Republic of Uzbekistan',			'Uzbekistan',			'the Timurid Empire',	'Timur',				'Emir',				'the Lame',		'M. Gerasimov/LastSword' UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_SAMARKAND',	'samarkand_leadericon2.dds',	'The Republic of Uzbekistan',	'Uzbekistan',	'the Timurid Empire',	'Timur',	'Emir',	'the Lame',	'Tomatekh'	UNION ALL
SELECT	'MINOR_CIV_SIDON',			'sidon_leadericon.dds',			'Saida, Lebanese Republic',				'Saida',				'Sidon',				'Eshmunazar II',		'King',				'',				'Leugi'					UNION ALL
--[pre-BNW name:]
--SELECT	'MINOR_SIDON',				'sidon_leadericon.dds',			'Saida, Lebanese Republic',				'Saida',				'Sidon',				'Eshmunazar II',		'King',				'',				'Leugi'					UNION ALL
SELECT	'MINOR_CIV_SINGAPORE',		'singapore_leadericon.dds',		'The Republic of Singapore',			'Singapore',			'Singapore',			'Lee Kuan Yew',			'Prime Minister',	'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_SOFIA',			'sofia_leadericon.dds',			'The Republic of Bulgaria',				'Bulgaria',				'the Bulgarians',		'Simeon I',				'Tsar',				'the Great',	'D. Giudjenov/Nutty'	UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_SOFIA',	'sofia_leadericon2.dds',	'The Republic of Bulgaria',	'Bulgaria',	'the Bulgarians',	'Simeon I',	'Tsar',	'the Great',	'D. Giudjenov/TPangolin'	UNION ALL
SELECT	'MINOR_CIV_SYDNEY',			'sydney_leadericon.dds',		'New South Wales, Commonwealth of Australia', 'New South Wales', 'New South Wales',		'Arthur Phillip',		'Governor',			'',				'TPangolin'				UNION ALL
--[pre-BNW name:]
--SELECT	'MINOR_CIV_COPENHAGEN',		'sydney_leadericon.dds',		'New South Wales, Commonwealth of Australia', 'New South Wales', 'New South Wales',		'Arthur Phillip',		'Governor',			'',				'TPangolin'				UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_SYDNEY',	'sydney_leadericon2.dds',	'The Commonwealth of Australia',	'Australia',	'New South Wales',	'Sir Henry Parkes',	'Premier',	'',	'TPangolin'	UNION ALL
SELECT	'MINOR_CIV_TYRE',			'tyre_leadericon.dds',			'The Lebanese Republic',				'Lebanon',				'Tyre',					'Hiram I',				'King',				'',				'LastSword'				UNION ALL
--[pre-BNW name:]
--SELECT	'MINOR_TYRE',				'tyre_leadericon.dds',			'The Lebanese Republic',				'Lebanon',				'Tyre',					'Hiram I',				'King',				'',				'LastSword'				UNION ALL
SELECT	'MINOR_CIV_UR',				'ur_leadericon.dds',			'The State of Kuwait',					'Kuwait',				'Sumer',				'Eannatum',				'King',				'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_VALLETTA',		'valletta_leadericon.dds',		'The Republic of Malta',				'Malta',				'the Knights of Malta',	'Giovanni Paolo Lascaris', 'Grand Master',	'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_VANCOUVER',		'vancouver_leadericon.dds',		'British Columbia, Canada',				'British Columbia',		'Canada',				'Mackenzie King',		'Prime Minister',	'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_VATICAN_CITY',	'vatican_city_leadericon.dds',	'The Vatican City State',				'the Vatican',			'the Vatican',			'Pius IX',				'Pope',	'the Blessed',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_VILNIUS',		'vilnius_leadericon.dds',		'The Republic of Lithuania',			'Lithuania',			'Lithuania',			'Gediminas',			'Grand Duke',		'',				'LastSword'				UNION ALL
SELECT	'MINOR_CIV_WELLINGTON',		'wellington_leadericon.dds',	'New Zealand',							'New Zealand',			'New Zealand',			'Richard Seddon',		'Prime Minister',	'the King',		'TPangolin'				UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_WELLINGTON',		'wellington_leadericon2.dds',	'New Zealand',							'New Zealand',			'New Zealand',			'Henry Sewell',			'Premier',			'',				'TPangolin'				UNION ALL
SELECT	'MINOR_CIV_WITTENBERG',		'wittenberg_leadericon.dds',	'Saxony-Anhalt, Federal Republic of Germany', 'Saxony-Anhalt',	'Saxony',				'Frederick III',		'Prince Elector',	'',				'janboruta'				UNION ALL
SELECT	'MINOR_CIV_YEREVAN',		'yerevan_leadericon.dds',		'The Republic of Armenia',				'Armenia',				'Armenia',				'Tigranes II',			'Emperor',			'the Great',	'Leugi'					UNION ALL
SELECT	'MINOR_CIV_ZANZIBAR',		'zanzibar_leadericon.dds',		'The United Republic of Tanzania',		'Tanzania',				'Zanzibar',				'Majid bin Said',		'Sultan',			'',				'sukritact'				UNION ALL
SELECT	'MINOR_CIV_ZURICH',			'zurich_leadericon.dds',		'The Swiss Confederation',				'Switzerland',			'the Swiss Confederacy', 'Guillaume-Henri Dufour', 'General',		'',				'JFD'					;
--[ALTERNATE]SELECT	'MINOR_CIV_ZURICH', 'zurich_leadericon2.dds', 'The Swiss Confederation', 'Switzerland', 'the Swiss Confederacy', 'Matthaus Schiner', 'Cardinal', '', 'Krateng' UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_ZURICH',	'zurich_leadericon3.dds',	'The Swiss Confederation',	'Switzerland',	'Zurich',	'Rudolf Brun',	'Mayor',	'',	'G. Closs/TPangolin' UNION ALL

--[G+K]
--SELECT	'MINOR_CIV_JAKARTA',		'jakarta_leadericon.dds',		'The Republic of Indonesia',			'Indonesia',			'the Majapahit Empire',	'Gajah Mada',			'Prime Minister',	'',				'Firaxis'				UNION ALL
--SELECT	'MINOR_CIV_LISBON',			'lisbon_leadericon.dds',		'The Portuguese Republic',				'Portugal',				'Portugal'			,	'Maria I',				'Queen',			'',				'Firaxis'				UNION ALL
--[ALTERNATE]SELECT	'MINOR_CIV_LISBON',	'lisbon_leadericon2.dds',	'The Portuguese Republic',	'Portugal',	'Portugal',	'Joao II',	'King',	'the Perfect Prince',	'janboruta'	UNION ALL
--SELECT	'MINOR_CIV_MARRAKECH',		'marrakech_leadericon.dds',		'The Kingdom of Morocco',				'Morocco',				'Morocco',				'Ahmad al-Mansur',		'Sultan',			'the Golden',	'Firaxis'				UNION ALL

--[vanilla/G+K]
--SELECT	'MINOR_CIV_RIO_DE_JANEIRO',	'rio_de_janeiro_leadericon.dds', 'The Federative Republic of Brazil',	'Brazil',				'Brazil',				'Pedro II',				'Emperor',			'the Magnanimous', 'Firaxis'			UNION ALL
--SELECT	'MINOR_CIV_VENICE',			'venice_leadericon.dds',		'Veneto, Italian Republic',				'Veneto',				'Venice',				'Enrico Dandolo',		'Doge',				'',				'Firaxis'				UNION ALL
--SELECT	'MINOR_CIV_WARSAW',			'warsaw_leadericon.dds',		'The Republic of Poland',				'Poland',				'Poland',				'Casimir III',			'King',				'the Great',	'Firaxis'				UNION ALL

--[vanilla]
--SELECT	'MINOR_CIV_DUBLIN',			'dublin_leadericon.dds',		'The Republic of Ireland',				'Ireland',				'Dublin',				 "Daniel O'Connell",	'Lord Mayor',		'the Liberator', 'B. Mulrenin/Nutty'	UNION ALL
--SELECT	'MINOR_CIV_EDINBURGH',		'edinburgh_leadericon.dds',		'Scotland',								'Scotland',				'the Scots',			'James VI',				'King',				'',				'LastSword'				UNION ALL
--SELECT	'MINOR_CIV_HELSINKI',		'helsinki_leadericon.dds',		'The Republic of Finland',				'Finland',				'Finland',				'Gustaf Mannerheim',	'President',		'',				'Hypereon'				UNION ALL
--SELECT	'MINOR_CIV_STOCKHOLM',		'stockholm_leadericon.dds',		'The Kingdom of Sweden',				'Sweden',				'Sweden',				'Gustavus Adolphus',	'King',				'the Great',	'Firaxis'				UNION ALL
--SELECT	'MINOR_CIV_VIENNA',			'vienna_leadericon.dds',		'The Republic of Austria',				'Austria',				'the Holy Roman Empire', 'Maria Theresa',		'Empress',			'',				'Firaxis'				;