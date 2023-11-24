INSERT INTO ArtDefine_UnitInfos(Type, DamageStates, Formation)
  VALUES ('ART_DEF_UNIT_SAS_TDF', 1, 'UnFormed');
INSERT INTO ArtDefine_UnitInfoMemberInfos(UnitInfoType, UnitMemberInfoType, NumMembers)
  VALUES ('ART_DEF_UNIT_SAS_TDF', 'ART_DEF_UNIT_MEMBER_SAS_TDF', 8);
INSERT INTO ArtDefine_UnitMemberInfos(Type, Scale, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
  VALUES ('ART_DEF_UNIT_MEMBER_SAS_TDF', 0.135, 'ModernInfantry.fxsxml', 'CLOTH', 'FLESH');
INSERT INTO ArtDefine_UnitMemberCombats(UnitMemberType, EnableActions, ShortMoveRadius, ShortMoveRate, TargetHeight, HasShortRangedAttack, HasRefaceAfterCombat, ReformBeforeCombat)
  VALUES ('ART_DEF_UNIT_MEMBER_SAS_TDF', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady Walk AttackCharge', 12.0, 0.349999994039536, 8.0, 1, 1, 1);
INSERT INTO ArtDefine_UnitMemberCombatWeapons(UnitMemberType, "Index", SubIndex, WeaponTypeTag, WeaponTypeSoundOverrideTag)
  VALUES ('ART_DEF_UNIT_MEMBER_SAS_TDF', 0, 0, 'BULLET', 'BULLET');
INSERT INTO ArtDefine_StrategicView(StrategicViewType, TileType, Asset)
  VALUES ('ART_DEF_UNIT_SAS_TDF', 'Unit', 'SV_Sas_TDF.dds');

--=======================================================================================================================
-- ICON ATLASES
--=======================================================================================================================	
------------------------------------------------------------------------------------------------------------------------
-- IconTextureAtlases
------------------------------------------------------------------------------------------------------------------------
INSERT INTO IconTextureAtlases 
		(Atlas, 									IconSize, 	Filename, 										IconsPerRow, 	IconsPerColumn)
VALUES	('SAS_ZELENSKYY_ALPHA_ATLAS',			128, 		'SasZelenskyyAlpha_128.dds',			1,				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			80, 		'SasZelenskyyAlpha_80.dds',			1, 				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			64, 		'SasZelenskyyAlpha_64.dds',			1, 				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			48, 		'SasZelenskyyAlpha_48.dds',			1, 				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			45, 		'SasZelenskyyAlpha_45.dds',			1, 				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			32, 		'SasZelenskyyAlpha_32.dds',			1, 				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			24, 		'SasZelenskyyAlpha_24.dds',			1, 				1),
		('SAS_ZELENSKYY_ALPHA_ATLAS',			16, 		'SasZelenskyyAlpha_16.dds',			1, 				1),
		('SAS_ZELENSKYY_ICON_ATLAS', 			256, 		'SasZelenskyyIcons256.dds',			4, 				1),
		('SAS_ZELENSKYY_ICON_ATLAS', 			128, 		'SasZelenskyyIcons128.dds',			4, 				1),
		('SAS_ZELENSKYY_ICON_ATLAS', 			80, 		'SasZelenskyyIcons80.dds',			4, 				1),
		('SAS_ZELENSKYY_ICON_ATLAS', 			64, 		'SasZelenskyyIcons64.dds',			4, 				1),
		('SAS_ZELENSKYY_ICON_ATLAS', 			45, 		'SasZelenskyyIcons45.dds',			4, 				1),
		('SAS_ZELENSKYY_ICON_ATLAS', 			32, 		'SasZelenskyyIcons32.dds',			4, 				1),
		('SAS_TDF_FLAG', 				32, 		'SasTDFFlag.dds',		1, 				1);
--=======================================================================================================================	
--=======================================================================================================================	