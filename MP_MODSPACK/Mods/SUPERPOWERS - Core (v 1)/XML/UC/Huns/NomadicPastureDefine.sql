-- Attila
-- Eki

INSERT INTO ArtDefine_LandmarkTypes(Type, LandmarkType, FriendlyName)
SELECT 'ART_DEF_IMPROVEMENT_3EKI', 'Improvement', 'Nomadic Pasture';

INSERT INTO ArtDefine_Landmarks(Era, State, Scale, ImprovementType, LayoutHandler, ResourceType, Model, TerrainContour)
SELECT 'Any', 'UnderConstruction', 0.75,  'ART_DEF_IMPROVEMENT_3EKI', 'SNAPSHOT', 'ART_DEF_RESOURCE_ALL', 'eki_built.fxsxml', 1 UNION ALL
SELECT 'Any', 'Constructed', 0.75,  'ART_DEF_IMPROVEMENT_3EKI', 'SNAPSHOT', 'ART_DEF_RESOURCE_ALL', 'eki_built.fxsxml', 1 UNION ALL
SELECT 'Any', 'Pillaged', 0.75,  'ART_DEF_IMPROVEMENT_3EKI', 'SNAPSHOT', 'ART_DEF_RESOURCE_ALL', 'pl_ind_polder.fxsxml', 1;
