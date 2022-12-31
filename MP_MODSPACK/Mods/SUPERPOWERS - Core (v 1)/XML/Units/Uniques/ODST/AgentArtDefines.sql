
-- Unit Infos - Original info based on unit: Euro Settler #35 from the original game

INSERT INTO ArtDefine_UnitInfos (Type, DamageStates, Formation) VALUES ('ART_DEF_UNIT_CO_AGENT',	1, "");
INSERT INTO ArtDefine_UnitInfoMemberInfos VALUES ('ART_DEF_UNIT_CO_AGENT', 'ART_DEF_UNIT_MEMBER_CO_AGENT', "1");
INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset) VALUES	('ART_DEF_UNIT_CO_AGENT', "Unit", 'sv_covert_operative.dds');


--  Member Infos

INSERT INTO ArtDefine_UnitMemberInfos (Type,	Scale,		ZOffset,		Domain,		Model,					MaterialTypeTag,	 MaterialTypeSoundOverrideTag)
	SELECT	('ART_DEF_UNIT_MEMBER_CO_AGENT'),'0.15',		ZOffset,		Domain,		('CO_Agent.fxsxml'),	MaterialTypeTag,	 MaterialTypeSoundOverrideTag
	FROM ArtDefine_UnitMemberInfos WHERE Type = 'ART_DEF_UNIT_MEMBER_XCOM_SQUAD';

