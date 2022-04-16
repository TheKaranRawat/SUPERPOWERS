-- ==================================================================================================================================================================
-- Unit Infos

INSERT INTO ArtDefine_UnitInfos(Type, DamageStates) VALUES ('ART_DEF_UNIT_SMAN_WAR_JUNK', 3);

INSERT INTO ArtDefine_UnitInfoMemberInfos(UnitInfoType, UnitMemberInfoType, NumMembers) VALUES ('ART_DEF_UNIT_SMAN_WAR_JUNK', 'ART_DEF_UNIT_MEMBER_SMAN_WAR_JUNK', 1);

INSERT INTO ArtDefine_StrategicView(StrategicViewType, TileType, Asset) VALUES ('ART_DEF_UNIT_SMAN_WAR_JUNK', 'Unit', 'sv_sea_mercenary.dds');


-- ==================================================================================================================================================================
-- Unit Member Infos

INSERT INTO ArtDefine_UnitMemberInfos(Type, Scale, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_WAR_JUNK', 0.11, 'Sea', 'SMAN_EU_WarJunk.fxsxml', 'WOOD', 'WOODLRG');


INSERT INTO ArtDefine_UnitMemberCombats(UnitMemberType, EnableActions, HasShortRangedAttack, HasLeftRightAttack, HasRefaceAfterCombat, HasIndependentWeaponFacing)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_WAR_JUNK', 'Idle Attack RunCharge AttackCity Bombard Death BombardDefend Run Fortify CombatReady AttackSurfaceToAir', 1, 1, 0, 1);


INSERT INTO ArtDefine_UnitMemberCombatWeapons(UnitMemberType, "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax, HitEffect, WeaponTypeTag, WeaponTypeSoundOverrideTag)
  VALUES ('ART_DEF_UNIT_MEMBER_SMAN_WAR_JUNK', 0, 0, 10.0, 20.0, 'ART_DEF_VEFFECT_CANNON_IMPACT_$(TERRAIN)', 'EXPLOSIVE', 'EXPLOSION6POUND');

  

