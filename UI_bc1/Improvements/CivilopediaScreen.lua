-------------------------------------------------
-- Civilopedia screen
-------------------------------------------------

print"Loading EUI Civilopedia Script"

include "GameInfoCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
local GameInfo = GameInfoCache

include( "StackInstanceManager" )
local StackInstanceManager = StackInstanceManager

include( "IconSupport" )
local IconLookup = IconLookup
local IconHookup = IconHookup
local nullOffset = nullOffset

local ipairs = ipairs
local math = math
local pairs = pairs
--local print = print
local string = string
local table = table
local tostring = tostring
local tonumber = tonumber
local insert = table.insert
local sort = table.sort
local concat = table.concat
--local remove = table.remove

local Game = Game

local IsCiv5BNW = ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY) or nil
local IsCiv5notVanilla = IsCiv5BNW or ContentManager.IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType.GAMEPLAY) or nil
local IsCiv5Vanilla = not IsCiv5notVanilla or nil
local IsReligionActive = IsCiv5notVanilla and not (Game and Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)) or nil

local Controls = Controls
local UIManager = UIManager
local eLClick = Mouse.eLClick
local TagExists = Locale.HasTextKey
local L = Locale.ConvertTextKey
local ToLower = Locale.ToLower
local Compare = Locale.Compare
local DataBaseQuery = DB.Query
local YieldTypes = YieldTypes
local GameDefines = GameDefines
local Players = Players
local Teams = Teams
local Events = Events
local KeyDown = KeyEvents.KeyDown
local VK_ESCAPE = Keys.VK_ESCAPE
--local VK_RETURN = Keys.VK_RETURN
local BulkShowUI = SystemUpdateUIType.BulkShowUI
local BulkHideUI = SystemUpdateUIType.BulkHideUI
local ContextPtr = ContextPtr
local PopupPriority = PopupPriority

local ToolTipControls = {}
TTManager:GetTypeControlTable( "TypeRoundImage", ToolTipControls )

local selectedCategory
-- defines for the various categories of topics
local Categories
local CategoryHomePage = 1
local CategoryGameConcepts = 2
local CategoryTechnologies = 3
local CategoryUnits = 4
local CategoryPromotions = 5
local CategoryBuildings = 6
local CategoryWonders = 7
local CategoryPolicies = 8
local CategoryGreatPeople = 9
local CategoryCivilizations = 10
local CategoryCityStates = 11
local CategoryTerrains = 12
local CategoryResources = 13
local CategoryImprovements = 14
local CategoryReligions = 15
local CategoryLeagueProjects = 16
local CategoryProjects = 17
local CategoryFeatures = 18
local CategoryFakeFeatures = 19
local CategoryRoutes = 20
local CategoryLeaders = 21
local CategorySpecialists = 22
local CategoryBeliefs = 23
local CategoryResolutions = 24
local GroupedCategories = {
	[ CategoryProjects ] = CategoryWonders,
	[ CategoryFeatures ] = CategoryTerrains,
	[ CategoryFakeFeatures ] = CategoryTerrains,
	[ CategoryRoutes ] = CategoryImprovements,
	[ CategoryLeaders ] = CategoryCivilizations,
	[ CategorySpecialists ] = CategoryGreatPeople,
	[ CategoryBeliefs ] = CategoryReligions,
	[ CategoryResolutions ] = CategoryLeagueProjects,
}

local ArticlesHistoryIndex = 0
local ArticlesHistory = {}
local ArticlesByNameKey = {}
local ArticlesByNameLowerCase = {}
local ArticlesBySection = {}

-- These projects were more of an implementation detail and not explicit projects
-- that the user can build.  So to avoid confusion, we shall ignore them from the pedia.
local projectsToIgnore = {
	PROJECT_SS_COCKPIT = true,
	PROJECT_SS_STASIS_CHAMBER = true,
	PROJECT_SS_ENGINE = true,
	PROJECT_SS_BOOSTER = true
}

local TrophyIcons = {
	"[ICON_TROPHY_BRONZE]",
	"[ICON_TROPHY_SILVER]",
	"[ICON_TROPHY_GOLD]",
}

-- the instance managers
local g_SearchResultItemManager = StackInstanceManager( "ListItemInstance", "ListItemButton", Controls.SearchResultsStack )

local g_ListItemManager = StackInstanceManager( "ListItemInstance", "ListItemButton", Controls.ListOfArticles )
local g_ListHeadingManager = StackInstanceManager( "ListHeadingInstance", "ListHeadingButton", Controls.ListOfArticles )
local g_PrereqTechManager = StackInstanceManager( "PrereqTechInstance", "PrereqTechButton", Controls.PrereqTechInnerFrame )
local g_GreatWorksManager = StackInstanceManager( "GreatWorksInstance", "GreatWorksButton", Controls.GreatWorksInnerFrame )
local g_ObsoleteTechManager = StackInstanceManager( "ObsoleteTechInstance", "ObsoleteTechButton", Controls.ObsoleteTechInnerFrame )
local g_UpgradeManager = StackInstanceManager( "UpgradeInstance", "UpgradeButton", Controls.UpgradeInnerFrame )
local g_LeadsToTechManager = StackInstanceManager( "LeadsToTechInstance", "LeadsToTechButton", Controls.LeadsToTechInnerFrame )
local g_UnlockedUnitsManager = StackInstanceManager( "UnlockedUnitInstance", "UnlockedUnitButton", Controls.UnlockedUnitsInnerFrame )
local g_UnlockedBuildingsManager = StackInstanceManager( "UnlockedBuildingInstance", "UnlockedBuildingButton", Controls.UnlockedBuildingsInnerFrame )
local g_RevealedResourcesManager = StackInstanceManager( "RevealedResourceInstance", "RevealedResourceButton", Controls.RevealedResourcesInnerFrame )
local g_RequiredResourcesManager = StackInstanceManager( "RequiredResourceInstance", "RequiredResourceButton", Controls.RequiredResourcesInnerFrame )
local g_WorkerActionsManager = StackInstanceManager( "WorkerActionInstance", "WorkerActionButton", Controls.WorkerActionsInnerFrame )
local g_UnlockedProjectsManager = StackInstanceManager( "UnlockedProjectInstance", "UnlockedProjectButton", Controls.UnlockedProjectsInnerFrame )
local g_PromotionsManager = StackInstanceManager( "PromotionInstance", "PromotionButton", Controls.FreePromotionsInnerFrame )
local g_SpecialistsManager = StackInstanceManager( "SpecialistInstance", "SpecialistButton", Controls.SpecialistsInnerFrame )
local g_RequiredBuildingsManager = StackInstanceManager( "RequiredBuildingInstance", "RequiredBuildingButton", Controls.RequiredBuildingsInnerFrame )
local g_LocalResourcesManager = StackInstanceManager( "LocalResourceInstance", "LocalResourceButton", Controls.LocalResourcesInnerFrame )
local g_RequiredPromotionsManager = StackInstanceManager( "RequiredPromotionInstance", "RequiredPromotionButton", Controls.RequiredPromotionsInnerFrame )
local g_RequiredPoliciesManager = StackInstanceManager( "RequiredPolicyInstance", "RequiredPolicyButton", Controls.RequiredPoliciesInnerFrame )
local g_FreeFormTextManager = StackInstanceManager( "FreeFormTextInstance", "FFTextFrame", Controls.FFTextStack )
local g_BBTextManager = StackInstanceManager( "BBTextInstance", "BBTextFrame", Controls.BBTextStack )
local g_LeadersManager = StackInstanceManager( "LeaderInstance", "LeaderButton", Controls.LeadersInnerFrame )
local g_UniqueUnitsManager = StackInstanceManager( "UniqueUnitInstance", "UniqueUnitButton", Controls.UniqueUnitsInnerFrame )
local g_UniqueBuildingsManager = StackInstanceManager( "UniqueBuildingInstance", "UniqueBuildingButton", Controls.UniqueBuildingsInnerFrame )
local g_UniqueImprovementsManager = StackInstanceManager( "UniqueImprovementInstance", "UniqueImprovementButton", Controls.UniqueImprovementsInnerFrame )
local g_CivilizationsManager = StackInstanceManager( "CivilizationInstance", "CivilizationButton", Controls.CivilizationsInnerFrame )
--local g_TraitsManager = StackInstanceManager( "TraitInstance", "TraitButton", Controls.TraitsInnerFrame )
local g_FeaturesManager = StackInstanceManager( "FeatureInstance", "FeatureButton", Controls.FeaturesInnerFrame )
local g_ResourcesFoundManager = StackInstanceManager( "ResourceFoundInstance", "ResourceFoundButton", Controls.ResourcesFoundInnerFrame )
--local g_TerrainsManager = StackInstanceManager( "TerrainInstance", "TerrainButton", Controls.TerrainsInnerFrame )
local g_ReplacesManager = StackInstanceManager( "ReplaceInstance", "ReplaceButton", Controls.ReplacesInnerFrame )
local g_RevealTechsManager = StackInstanceManager( "RevealTechInstance", "RevealTechButton", Controls.RevealTechsInnerFrame )
local g_ImprovementsManager = StackInstanceManager( "ImprovementInstance", "ImprovementButton", Controls.ImprovementsInnerFrame )

-- adjust the various parts to fit the screen size
local _, screenSizeY = UIManager:GetScreenSizeVal() -- Controls.BackDrop:GetSize()
Controls.ScrollPanel:SetSizeY( screenSizeY - 126 )
Controls.ScrollPanel:GetScrollBar():SetSizeY( screenSizeY - 162 )
Controls.LeftScrollPanel:SetSizeY( screenSizeY - 126 )
Controls.LeftScrollPanel:GetScrollBar():SetSizeY( screenSizeY - 162 )

local function TipHandler( control )
	local category = Categories[ control:GetVoid1() ]
	local info = category and category.Info
	local row = info and info[ control:GetVoid2() ]
	local index = row and (row.PortraitIndex or row.IconIndex)
	if index and row.IconAtlas then
		local offset, texture = IconLookup( index, 256, row.IconAtlas )
		if offset and texture then
			ToolTipControls.ToolTipText:SetText( row._Name )
			ToolTipControls.ToolTipGrid:DoAutoSize()
			ToolTipControls.ToolTipImage:SetTexture( texture )
			ToolTipControls.ToolTipImage:SetTextureOffset( offset )
			return ToolTipControls.ToolTipFrame:SetHide( false )
		end
	end
	ToolTipControls.ToolTipFrame:SetHide( true )
end

--------------------------------------------------------------------------------------------------------
-- a few handy-dandy helper functions
--------------------------------------------------------------------------------------------------------

local function insertIf( t, v )
	if v then
		return insert( t, v )
	end
end

local function insertIfLocalized( t, ... )
	if ... then
		return insert( t, L( ... ) )
	end
end

local function ShowInPedia( row )
	return row and row.ShowInPedia ~= false and row.ShowInPedia ~= 0
end

local function ResizeEtc()
	Controls.ListOfArticles:CalculateSize()
	Controls.WideStack:CalculateSize()
	Controls.FFTextStack:CalculateSize()
	Controls.NarrowStack:CalculateSize()
	Controls.BBTextStack:CalculateSize()
	Controls.SuperWideStack:CalculateSize()

	Controls.BBTextStack:ReprocessAnchoring()
	Controls.WideStack:ReprocessAnchoring()
	Controls.FFTextStack:ReprocessAnchoring()
	Controls.NarrowStack:ReprocessAnchoring()
	Controls.ListOfArticles:ReprocessAnchoring()
	Controls.SuperWideStack:ReprocessAnchoring()

	Controls.ScrollPanel:CalculateInternalSize()
	Controls.LeftScrollPanel:CalculateInternalSize()

	Controls.SearchEditBox:TakeFocus()
	Controls.SearchGrid:SetHide( true )
end

local function SetStringBlock( label, frame, text )
	if text and text~="" then
		label:SetText( text )
		return frame:SetHide( false )
	end
end

local function LocalizeAndSetStringBlock( label, frame, ... )
	if ... and TagExists((...)) then
		return SetStringBlock( label, frame, L(...) )
	end
end

local function SetTextBlock( label, innerFrame, outerFrame, text )
	if text and text~="" then
		label:SetText( text )
		local h = label:GetSizeY() + 34 -- textPaddingFromInnerFrame
		innerFrame:SetSizeY( h )
		outerFrame:SetSizeY( h - 4 ) -- offsetsBetweenFrames
		return outerFrame:SetHide( false )
	end
end

local function LocalizeAndSetTextBlock( label, innerFrame, outerFrame, ... )
	if ... and TagExists((...)) then
		return SetTextBlock( label, innerFrame, outerFrame, L(...) )
	end
end

local function LocalizeAndSetNameAndBlurbsAndPortrait( row )
	LocalizeAndSetTextBlock( Controls.GameInfoLabel, Controls.GameInfoInnerFrame, Controls.GameInfoFrame, row.Help ~= row.Strategy and row.Help )
	LocalizeAndSetTextBlock( Controls.StrategyLabel, Controls.StrategyInnerFrame, Controls.StrategyFrame, row.Strategy )
	LocalizeAndSetTextBlock( Controls.HistoryLabel, Controls.HistoryInnerFrame, Controls.HistoryFrame, row.Civilopedia )
	LocalizeAndSetTextBlock( Controls.SilentQuoteLabel, Controls.SilentQuoteInnerFrame, Controls.SilentQuoteFrame, row.Quote )
	if row._Name then
		Controls.ArticleID:SetText( row._Name )
	end
	local index = row and (row.PortraitIndex or row.IconIndex)
	if index and row.IconAtlas then
		local offset, texture = IconLookup( index, 256, row.IconAtlas )
		if offset and texture then
			Controls.PortraitFrame:SetHide( false )
			Controls.Portrait:SetTexture( texture )
			Controls.Portrait:SetTextureOffset( offset )
		end
	end
end

local stuffToHide = {
	Controls.PortraitFrame,
	Controls.CostFrame,
	Controls.MaintenanceFrame,
	Controls.HappinessFrame,
	Controls.UnmoddedHappinessFrame,
	Controls.CultureFrame,
	Controls.FaithFrame,
	Controls.DefenseFrame,
	Controls.FoodFrame,
	Controls.GoldChangeFrame,
	Controls.GoldFrame,
	Controls.ScienceFrame,
	Controls.ProductionFrame,
	Controls.GreatPeopleFrame,
	Controls.CombatFrame,
	Controls.RangedCombatFrame,
	Controls.RangedCombatRangeFrame,
	Controls.MovementFrame,
	Controls.FreePromotionsFrame,
	Controls.PrereqTechFrame,
	Controls.GreatWorksFrame,
	Controls.LeadsToTechFrame,
	Controls.ObsoleteTechFrame,
	Controls.UpgradeFrame,
	Controls.UnlockedUnitsFrame,
	Controls.UnlockedBuildingsFrame,
	Controls.RequiredBuildingsFrame,
	Controls.RevealedResourcesFrame,
	Controls.RequiredResourcesFrame,
	Controls.RequiredPromotionsFrame,
	Controls.LocalResourcesFrame,
	Controls.WorkerActionsFrame,
	Controls.UnlockedProjectsFrame,
	Controls.SpecialistsFrame,
	Controls.RelatedArticlesFrame,
	Controls.GameInfoFrame,
	Controls.QuoteFrame,
	Controls.SilentQuoteFrame,
	Controls.AbilitiesFrame,
	Controls.HistoryFrame,
	Controls.StrategyFrame,
	Controls.RelatedImagesFrame,
	Controls.SummaryFrame,
	Controls.ExtendedFrame,
	Controls.DNotesFrame,
	Controls.RequiredPoliciesFrame,
	Controls.PrereqEraFrame,
	Controls.PolicyBranchFrame,
	Controls.TenetLevelFrame,
	Controls.LeadersFrame,
	Controls.UniqueUnitsFrame,
	Controls.UniqueBuildingsFrame,
	Controls.UniqueImprovementsFrame,
	Controls.CivilizationsFrame,
	Controls.TraitsFrame,
	Controls.LivedFrame,
	Controls.TitlesFrame,
	Controls.SubtitleID,
	Controls.YieldFrame,
	Controls.MountainYieldFrame,
	Controls.MovementCostFrame,
	Controls.CombatModFrame,
	Controls.FeaturesFrame,
	Controls.ResourcesFoundFrame,
	Controls.TerrainsFrame,
	Controls.CombatTypeFrame,
	Controls.ReplacesFrame,
	Controls.RevealTechsFrame,
	Controls.ImprovementsFrame,
	Controls.HomePageBlurbFrame,
	Controls.WideTextBlockFrame,
	Controls.FFTextStack,
	Controls.BBTextStack,

	Controls.SearchGrid,
}

local function ClearArticle()
	for _, control in pairs( stuffToHide ) do
		control:SetHide( true )
	end
	Controls.ScrollPanel:SetScrollValue( 0 )
	Controls.SearchButton:SetHide( false )
	Controls.Portrait:UnloadTexture()
end

local function addListItem( label, callback, void1, void2 )
	local instance = g_ListItemManager:GetInstance()
	if instance then
		instance.ListItemLabel:SetText( label )
		instance.ListItemButton:SetVoids( void1, void2 )
		instance.ListItemButton:RegisterCallback( eLClick, callback )
		instance.ListItemButton:SetToolTipCallback( TipHandler )
	end
end

local SelectArticleHistorized

local function SelectCategoryHeading( categoryID, headingID )
	g_ListHeadingManager:ResetInstances()
	g_ListItemManager:ResetInstances()
	-- put in a home page item
	local sections = ArticlesBySection[ categoryID ]
	if sections then
		if sections.HomePage then
			addListItem( sections.HomePage, SelectArticleHistorized, categoryID, -1 )
		end
		for sectionID, section in ipairs( sections ) do
			local isOpen = true
			-- show section header
			if section.HeadingName then
				isOpen = not section.HeadingClosed
				if sectionID == headingID then
					section.HeadingClosed = isOpen
					isOpen = not isOpen
				end
				local instance = g_ListHeadingManager:GetInstance()
				if instance then
					instance.ListHeadingLabel:SetText( ( isOpen and "[ICON_MINUS] " or "[ICON_PLUS] " ) .. section.HeadingName )
					instance.ListHeadingButton:SetVoids( categoryID, sectionID )
					instance.ListHeadingButton:RegisterCallback( eLClick, SelectCategoryHeading )
				end
			end
			-- show names of articles in section
			if isOpen then
				for _, v in ipairs(section) do
					addListItem( v.entryName, SelectArticleHistorized, v.CategoryID, v.entryID )
				end
			end
		end
	end
	return ResizeEtc()
end

local function SelectArticle( categoryID, rowID, shouldHistorize )
	local category = Categories[ categoryID ]
	if category then
		categoryID = GroupedCategories[ categoryID ] or categoryID
		if selectedCategory ~= categoryID then
			selectedCategory = categoryID
			-- set up tab & label
			Controls.SelectedCategoryTab:SetOffsetX( 47 * (categoryID - 1) )
			Controls.SelectedCategoryTab:SetTexture( Categories[ categoryID ].Texture )
			Controls.CategoryLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_CATEGORY_"..categoryID.."_LABEL" )
			-- populate the list of entries
			SelectCategoryHeading( categoryID )
		end
		if shouldHistorize then
			local article = category[ rowID or -1 ]
			if article then
				if ArticlesHistoryIndex == 0 or article ~= ArticlesHistory[ ArticlesHistoryIndex ] then
					ArticlesHistoryIndex = ArticlesHistoryIndex + 1
					ArticlesHistory[ArticlesHistoryIndex] = article
					for i = ArticlesHistoryIndex + 1, #ArticlesHistory do
						ArticlesHistory[i] = nil
					end
				end
			end
		end
		ClearArticle()
		local row = category.Info and category.Info[ rowID ]
		if row then
			LocalizeAndSetNameAndBlurbsAndPortrait( row )
			if category.DisplayArticle then
				category.DisplayArticle( row, rowID )
			end
		else
			category = Categories[ categoryID ] or category
			if category.DisplayHomePage then
				category.DisplayHomePage()
			end
		end
	end
	return ResizeEtc()
end

function SelectArticleHistorized( categoryID, rowID )
	return SelectArticle( categoryID, rowID, true )
end

-- numberOfButtonsPerRow = 3
-- buttonPadding = 8
local SmallButtonCount = 0
local SmallButtonSize = 64

local function AddSmallButton( image, button, categoryID, tipKey, rowID, textureOffset, textureSheet )
	image:SetTexture( textureSheet or "blank.dds" )
	image:SetTextureOffset( textureOffset or nullOffset )
	button:SetOffsetVal( ( SmallButtonCount % 3 ) * SmallButtonSize + 8, math.floor( SmallButtonCount / 3 ) * SmallButtonSize + 8 )
	if categoryID and rowID then
		button:SetVoids( categoryID, rowID )
		button:RegisterCallback( eLClick, SelectArticleHistorized )
		button:SetToolTipCallback( TipHandler )
		button:SetToolTipType( "TypeRoundImage" )
	elseif button.ClearCallback then
		button:ClearCallback( eLClick )
		button:SetToolTipType()
		button:LocalizeAndSetToolTip( tipKey or "" )
	end
	SmallButtonCount = SmallButtonCount + 1
end

local function AddSmallItemButton( image, button, categoryID, row, rowID )
	return AddSmallButton( image, button, categoryID, row._Name, rowID or row.ID, IconLookup( row.PortraitIndex or row.IconIndex, SmallButtonSize, row.IconAtlas ) )
end

local function AddSmallBuildingButton( image, button, row )
	local class = GameInfo.BuildingClasses[ row.BuildingClass ]
	return AddSmallItemButton( image, button, class and ( class.MaxGlobalInstances > 0 or (class.MaxPlayerInstances == 1 and row.SpecialistCount == 0) or class.MaxTeamInstances > 0 ) and CategoryWonders or CategoryBuildings, row )
end

local function UpdateSmallButtonFrame( innerFrame, outerFrame )
	if SmallButtonCount > 0 then
		local h = math.ceil( SmallButtonCount / 3 ) * SmallButtonSize + 16
		innerFrame:SetSizeY( h )
		outerFrame:SetSizeY( h - 4 ) -- offsetsBetweenFrames
		outerFrame:SetHide( false )
	end
	SmallButtonCount = 0
end

local function LocalizeAndAddBBtext( pageLabel, helpText )
	local thisBBTextInstance = helpText and TagExists(helpText) and g_BBTextManager:GetInstance()
	if thisBBTextInstance then
		thisBBTextInstance.BBTextHeader:LocalizeAndSetText( pageLabel )
		return LocalizeAndSetTextBlock( thisBBTextInstance.BBTextLabel, thisBBTextInstance.BBTextInnerFrame, thisBBTextInstance.BBTextFrame, helpText )
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function addWorkerActions( rows )
	g_WorkerActionsManager:ResetInstances()
	for row in rows do
		row = GameInfo.Builds[ row.BuildType ]
		local instance = ShowInPedia( row ) and g_WorkerActionsManager:GetInstance()
		if instance then
			local rowID, categoryID
			if row.ImprovementType then
				categoryID = CategoryImprovements
				rowID = GameInfo.Improvements[row.ImprovementType].ID
			elseif row.RouteType then
				categoryID = CategoryRoutes
				rowID = GameInfo.Routes[row.RouteType].ID
			else
				local row = GameInfo.BuildFeatures{ BuildType = row.Type }()
				row = row and GameInfo.Features[ row.FeatureType ]
				rowID = row and row.ID
				categoryID = rowID and CategoryFeatures
			end
			AddSmallItemButton( instance.WorkerActionImage, instance.WorkerActionButton, categoryID, row, rowID )
		end
	end
	UpdateSmallButtonFrame( Controls.WorkerActionsInnerFrame, Controls.WorkerActionsFrame )
end

local function addResources( rows, label )
	Controls.RequiredResourcesLabel:LocalizeAndSetText( label )
	g_RequiredResourcesManager:ResetInstances()
	for row in rows do
		row = GameInfo.Resources[ row.ResourceType ]
		local instance = row and g_RequiredResourcesManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.RequiredResourceImage, instance.RequiredResourceButton, CategoryResources, row )
		end
	end
	UpdateSmallButtonFrame( Controls.RequiredResourcesInnerFrame, Controls.RequiredResourcesFrame )
end

local function addPrereqTechs( rows )
	g_PrereqTechManager:ResetInstances()
	for row in rows do
		row = GameInfo.Technologies[row.PrereqTech]
		local instance = row and g_PrereqTechManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.PrereqTechImage, instance.PrereqTechButton, CategoryTechnologies, row )
		end
	end
	UpdateSmallButtonFrame( Controls.PrereqTechInnerFrame, Controls.PrereqTechFrame )
end

local function addPrereqTech( tag )
	local row = tag and GameInfo.Technologies[ tag ]
	if row then
		g_PrereqTechManager:ResetInstances()
		local instance = g_PrereqTechManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.PrereqTechImage, instance.PrereqTechButton, CategoryTechnologies, row )
			UpdateSmallButtonFrame( Controls.PrereqTechInnerFrame, Controls.PrereqTechFrame )
		end
	end
end

local function addObsoleteTech( tag )
	local row = tag and GameInfo.Technologies[ tag ]
	if row then
		g_ObsoleteTechManager:ResetInstances()
		local instance = g_ObsoleteTechManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.ObsoleteTechImage, instance.ObsoleteTechButton, CategoryTechnologies, row )
			UpdateSmallButtonFrame( Controls.ObsoleteTechInnerFrame, Controls.ObsoleteTechFrame )
		end
	end
end

local function addRequiredBuildings( rows )
	g_RequiredBuildingsManager:ResetInstances()
	for row in rows do
		local buildingClass = GameInfo.BuildingClasses[row.BuildingClassType]
		local building = buildingClass and GameInfo.Buildings[ buildingClass.DefaultBuilding ]
		local instance = ShowInPedia(building) and g_RequiredBuildingsManager:GetInstance()
		if instance then
			AddSmallBuildingButton( instance.RequiredBuildingImage, instance.RequiredBuildingButton, building )
		end
	end
	UpdateSmallButtonFrame( Controls.RequiredBuildingsInnerFrame, Controls.RequiredBuildingsFrame )
end

local function addCivilizations( rows )
	g_CivilizationsManager:ResetInstances()
	for row in rows do
		row = GameInfo.Civilizations[ row.CivilizationType ]
		local instance = row and g_CivilizationsManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.CivilizationImage, instance.CivilizationButton, CategoryCivilizations, row )
		end
	end
	UpdateSmallButtonFrame( Controls.CivilizationsInnerFrame, Controls.CivilizationsFrame )
end

local function addUnlockedUnits( rows )
	g_UnlockedUnitsManager:ResetInstances()
	for row in rows do
		local instance = ShowInPedia(row) and g_UnlockedUnitsManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.UnlockedUnitImage, instance.UnlockedUnitButton, CategoryUnits, row )
		end
	end
	UpdateSmallButtonFrame( Controls.UnlockedUnitsInnerFrame, Controls.UnlockedUnitsFrame )
end

local function addUnlockedBuildings( rows )
	g_UnlockedBuildingsManager:ResetInstances()
	for row in rows do
		local instance = ShowInPedia(row) and g_UnlockedBuildingsManager:GetInstance()
		if instance then
			AddSmallBuildingButton( instance.UnlockedBuildingImage, instance.UnlockedBuildingButton, row )
		end
	end
	UpdateSmallButtonFrame( Controls.UnlockedBuildingsInnerFrame, Controls.UnlockedBuildingsFrame )
end

local function addSameClass( rows, categoryID, rowID )
	g_ReplacesManager:ResetInstances()
	for row in rows do
		local instance = ShowInPedia(row) and rowID ~= row.ID and g_ReplacesManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.ReplaceImage, instance.ReplaceButton, categoryID, row )
		end
	end
	UpdateSmallButtonFrame( Controls.ReplacesInnerFrame, Controls.ReplacesFrame )
end

local function DoDisplayHomePage( pageLabel, blurbText, helpText, portraitAtlas, portraitIndex, iconQuery )
	ClearArticle()
	Controls.ArticleID:LocalizeAndSetText( pageLabel )

	-- Update some circle logo
	local row = iconQuery and DataBaseQuery( iconQuery )()
	if row then
		portraitIndex = row.PortraitIndex
		portraitAtlas = row.IconAtlas
	end
	if portraitAtlas then
		if portraitIndex then
			Controls.PortraitFrame:SetHide( not IconHookup( portraitIndex, 256, portraitAtlas, Controls.Portrait ) )
		else
			Controls.Portrait:SetTexture( portraitAtlas )
			Controls.Portrait:SetTextureOffsetVal( 0,0 )
			Controls.PortraitFrame:SetHide( false )
		end
	end

	--Welcome and insert 1st manual paragraph
	LocalizeAndSetTextBlock( Controls.HomePageBlurbLabel, Controls.HomePageBlurbInnerFrame, Controls.HomePageBlurbFrame, blurbText )

	--How to use the Pedia
	g_BBTextManager:ResetInstances()
	Controls.BBTextStack:SetHide( false )
	if helpText then
		LocalizeAndAddBBtext( pageLabel, helpText )
		return ResizeEtc()
	end
end

local function DisplayBuildingOrWonderArticle( thisBuilding, buildingID )
	-- update the cost
	local cost = Game and Players[Game.GetActivePlayer()]:GetBuildingProductionNeeded( buildingID ) or tonumber(thisBuilding.Cost) or 0
	local faithCost = IsReligionActive and tonumber(thisBuilding.FaithCost) or 0
	local costPerPlayer = 0
	if IsCiv5BNW then
		for tLeagueProject in GameInfo.LeagueProjects() do
			for iTier = 1, 3, 1 do
				local tLeagueTier = tLeagueProject["RewardTier" .. iTier]
				local tReward = tLeagueTier  and GameInfo.LeagueProjectRewards[ tLeagueTier ]
				local rewardBuildingInfo = tReward and tReward.Building and GameInfo.Buildings[tReward.Building]
				if rewardBuildingInfo and rewardBuildingInfo.ID == buildingID then
					local league = Game and Game.GetNumActiveLeagues() > 0 and Game.GetActiveLeague()
					costPerPlayer = league and league:GetProjectCostPerPlayer(tLeagueProject.ID) / 100 or tLeagueProject.CostPerPlayer or 0
				end
			end
		end
	end
	if costPerPlayer > 0 then
		LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, "TXT_KEY_LEAGUE_PROJECT_COST_PER_PLAYER", costPerPlayer )
	elseif cost > 1 and faithCost > 0 then
		LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, "TXT_KEY_PEDIA_A_OR_B", cost .. " [ICON_PRODUCTION]", faithCost .. " [ICON_PEACE]" )
	elseif cost > 0 then
		SetStringBlock( Controls.CostLabel, Controls.CostFrame, cost .. " [ICON_PRODUCTION]" )
	elseif faithCost > 0 then
		SetStringBlock( Controls.CostLabel, Controls.CostFrame, faithCost .. " [ICON_PEACE]" )
	else
		LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, "TXT_KEY_FREE" )
	end

	-- update the maintenance
	local v = tonumber(thisBuilding.GoldMaintenance) or 0
	SetStringBlock( Controls.MaintenanceLabel, Controls.MaintenanceFrame, v > 0 and v.." [ICON_GOLD]" )

	-- update the Happiness
	v = tonumber(thisBuilding.Happiness) or 0
	SetStringBlock( Controls.HappinessLabel, Controls.HappinessFrame, v > 0 and v.." [ICON_HAPPINESS_1]" )

	-- Unmodded Happiness
	v = tonumber(thisBuilding.UnmoddedHappiness) or 0
	SetStringBlock( Controls.UnmoddedHappinessLabel, Controls.UnmoddedHappinessFrame, v > 0 and v.." [ICON_HAPPINESS_1]" )

	-- Use Game to calculate Yield Changes and modifiers.
	local GetBuildingYieldChange = Game
	and function( yieldType )
		return Game.GetBuildingYieldChange( buildingID, YieldTypes[ yieldType ] )
	end
	or function( yieldType )
		local yieldModifier = 0
		for row in GameInfo.Building_YieldChanges{ BuildingType = thisBuilding.Type, YieldType = yieldType } do
			yieldModifier = yieldModifier + row.Yield
		end
		return yieldModifier
	end

	local GetBuildingYieldModifier = Game
	and function( yieldType )
		return Game.GetBuildingYieldModifier( buildingID, YieldTypes[ yieldType ] )
	end
	or function( yieldType )
		local yieldModifier = 0
		for row in GameInfo.Building_YieldModifiers{ BuildingType = thisBuilding.Type, YieldType = yieldType } do
			yieldModifier = yieldModifier + row.Yield
		end
		return yieldModifier
	end

	-- update the Culture
	v = IsCiv5notVanilla and GetBuildingYieldChange( "YIELD_CULTURE" ) or tonumber(thisBuilding.Culture) or 0
	SetStringBlock( Controls.CultureLabel, Controls.CultureFrame, v > 0 and v.." [ICON_CULTURE]" )

	-- update the Faith
	v = IsReligionActive and GetBuildingYieldChange( "YIELD_FAITH" ) or 0
	SetStringBlock( Controls.FaithLabel, Controls.FaithFrame, v > 0 and v.." [ICON_PEACE]" )

	-- update the Defense
	local t = {}
	v = tonumber(thisBuilding.Defense) or 0
	insertIf( t, v > 0 and (v / 100).." [ICON_STRENGTH]" )
	v = IsCiv5notVanilla and tonumber(thisBuilding.ExtraCityHitPoints) or 0
	insertIfLocalized( t, v > 0 and "TXT_KEY_PEDIA_DEFENSE_HITPOINTS", v )
	SetStringBlock( Controls.DefenseLabel, Controls.DefenseFrame, concat( t, "  " ) )

--		v = tonumber(thisBuilding.) or 0
--		SetStringBlock( Controls., Controls., v > 0 and v.." []" )

	-- update the Food
	t = {}
	v = GetBuildingYieldChange( "YIELD_FOOD" )
	insertIf( t, v > 0 and "+"..v.." [ICON_FOOD]" )
	v = GetBuildingYieldModifier( "YIELD_FOOD" )
	insertIf( t, v > 0 and "+"..v.."% [ICON_FOOD]" )
	SetStringBlock( Controls.FoodLabel, Controls.FoodFrame, concat( t, "  " ) )

	-- update the Gold
	t = {}
	v = GetBuildingYieldChange( "YIELD_GOLD" )
	insertIf( t, v > 0 and "+"..v.." [ICON_GOLD]" )
	v = GetBuildingYieldModifier( "YIELD_GOLD" )
	insertIf( t, v > 0 and "+"..v.."% [ICON_GOLD]" )
	SetStringBlock( Controls.GoldLabel, Controls.GoldFrame, concat( t, "  " ) )

	-- update the Science
	t = {}
	v = GetBuildingYieldChange( "YIELD_SCIENCE" )
	insertIf( t, v > 0 and "+"..v.." [ICON_RESEARCH]" )
	v = GetBuildingYieldModifier( "YIELD_SCIENCE" )
	insertIf( t, v > 0 and "+"..v.."% [ICON_RESEARCH]" )
	SetStringBlock( Controls.ScienceLabel, Controls.ScienceFrame, concat( t, "  " ) )

	-- update the Production
	t = {}
	v = GetBuildingYieldChange( "YIELD_PRODUCTION" )
	insertIf( t, v > 0 and "+"..v.." [ICON_PRODUCTION]" )
	v = GetBuildingYieldModifier( "YIELD_PRODUCTION" )
	insertIf( t, v > 0 and "+"..v.."% [ICON_PRODUCTION]" )
	SetStringBlock( Controls.ProductionLabel, Controls.ProductionFrame, concat( t, "  " ) )

	-- Great People
	local iGPType = thisBuilding.SpecialistType
	v = iGPType and tonumber( thisBuilding.GreatPeopleRateChange ) or 0
	if v > 0 then
		Controls.GPTitle:LocalizeAndSetText( GameInfo.Specialists[iGPType].GreatPeopleTitle )
		Controls.GreatPeopleLabel:SetText( v.." [ICON_GREAT_PEOPLE]" )
		Controls.GreatPeopleFrame:SetHide( false )
	end

	local condition = { BuildingType = thisBuilding.Type }

	-- specialists
	g_SpecialistsManager:ResetInstances()
	if (thisBuilding.SpecialistCount > 0 and thisBuilding.SpecialistType) then
		local thisSpec = GameInfo.Specialists[thisBuilding.SpecialistType]
		if(thisSpec)  then
			for _ = 1, thisBuilding.SpecialistCount do
				local instance = g_SpecialistsManager:GetInstance()
				if instance then
					AddSmallItemButton( instance.SpecialistImage, instance.SpecialistButton, CategorySpecialists, thisSpec )
				end
			end
		end
	end
	UpdateSmallButtonFrame( Controls.SpecialistsInnerFrame, Controls.SpecialistsFrame )

	-- techs
	addPrereqTech( thisBuilding.PrereqTech )
	addObsoleteTech( thisBuilding.ObsoleteTech )

	-- needed local resources
	g_LocalResourcesManager:ResetInstances()
	for row in GameInfo.Building_LocalResourceAnds( condition ) do
		row = GameInfo.Resources[row.ResourceType]
		local instance = row and g_LocalResourcesManager:GetInstance()
		if instance then
			AddSmallItemButton( instance.LocalResourceImage, instance.LocalResourceButton, CategoryResources, row )
		end
	end
	UpdateSmallButtonFrame( Controls.LocalResourcesInnerFrame, Controls.LocalResourcesFrame )

	-- required buildings
	addRequiredBuildings( GameInfo.Building_ClassesNeededInCity( condition ) )

	-- required resources
	addResources( GameInfo.Building_ResourceQuantityRequirements( condition ), "TXT_KEY_PEDIA_REQ_RESRC_LABEL" )

	-- similar buildings
	addSameClass( GameInfo.Buildings{ BuildingClass = thisBuilding.BuildingClass }, CategoryBuildings, thisBuilding.ID )

	-- civilization unique
	addCivilizations( GameInfo.Civilization_BuildingClassOverrides( condition ) )

	-- what buildings does this building enable ?
	g_UnlockedBuildingsManager:ResetInstances()
	for row in GameInfo.Building_ClassesNeededInCity{ BuildingClassType = thisBuilding.BuildingClass } do
		row = GameInfo.Buildings[ row.BuildingType ]
		local instance = ShowInPedia(row) and g_UnlockedBuildingsManager:GetInstance()
		if instance then
			AddSmallBuildingButton( instance.UnlockedBuildingImage, instance.UnlockedBuildingButton, row )
		end
	end
	UpdateSmallButtonFrame( Controls.UnlockedBuildingsInnerFrame, Controls.UnlockedBuildingsFrame )

	-- great works
	if IsCiv5BNW then
		g_GreatWorksManager:ResetInstances()
		local greatWorkSlot = GameInfo.GreatWorkSlots[thisBuilding.GreatWorkSlotType]
		for _ = 1, greatWorkSlot and thisBuilding.GreatWorkCount or 0 do
			local instance = g_GreatWorksManager:GetInstance()
			AddSmallButton( instance.GreatWorksImage, instance.GreatWorksButton, nil, greatWorkSlot.EmptyToolTipText, 0, nullOffset, greatWorkSlot.EmptyIcon )
		end
		UpdateSmallButtonFrame( Controls.GreatWorksInnerFrame, Controls.GreatWorksFrame )
	end
end

local function DisplayFeatureArticle( thisFeature )

	local condition = { FeatureType = thisFeature.Type }

	-- City Yield
	Controls.YieldFrame:SetHide( false )
	local numYields = 0
	local yieldString = ""
	for row in GameInfo.Feature_YieldChanges( condition ) do
		numYields = numYields + 1
		yieldString = yieldString..tostring(row.Yield).." "
		yieldString = yieldString..GameInfo.Yields[row.YieldType].IconString.." "
	end

	-- culture hack for vanilla
	if IsCiv5Vanilla and thisFeature.Culture ~= 0 then
		numYields = numYields + 1
		yieldString = yieldString.."+"..tostring(thisFeature.Culture).."[ICON_CULTURE]"
	end

	-- add happiness since it is a quasi-yield
	if (thisFeature.InBorderHappiness or 0) ~= 0 then
		numYields = numYields + 1
		yieldString = yieldString.." "
		yieldString = yieldString..tostring(thisFeature.InBorderHappiness).."[ICON_HAPPINESS_1]".." "
	end

	if numYields == 0 then
		Controls.YieldLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_NO_YIELD" )
	else
		Controls.YieldLabel:SetText( yieldString )
	end

	-- Movement
	Controls.MovementCostFrame:SetHide( false )
	local moveCost = thisFeature.Movement or 0
	if thisFeature.Impassable then
		Controls.MovementCostLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_IMPASSABLE" )
	elseif tonumber( moveCost ) then
		Controls.MovementCostLabel:SetText( moveCost.."[ICON_MOVES]" )
	else
		Controls.MovementCostLabel:LocalizeAndSetText( moveCost )
	end

	-- Combat Modifier
	Controls.CombatModFrame:SetHide( false )
	local combatModifier = thisFeature.Defense
	local combatModString = ""
	if combatModifier > 0 then
		combatModString = "+"
	end
	combatModString = combatModString..tostring(combatModifier).."%"
	Controls.CombatModLabel:SetText( combatModString )

	-- Features that can exist on this terrain
	g_FeaturesManager:ResetInstances()
	for feature in GameInfo.Feature_TerrainBooleans( condition ) do
		feature = GameInfo.Features[ feature.TerrainType ]
		if feature then
			local thisTerrainInstance = g_FeaturesManager:GetInstance()
			if thisTerrainInstance then
				AddSmallItemButton( thisTerrainInstance.FeatureImage, thisTerrainInstance.FeatureButton, CategoryFeatures, feature )
			end
		end
	end
	UpdateSmallButtonFrame( Controls.TerrainsInnerFrame, Controls.TerrainsFrame )

	-- Resources that can exist on this feature
	Controls.ResourcesFoundLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_RESOURCESFOUND_LABEL" )
	g_ResourcesFoundManager:ResetInstances()
	for resource in GameInfo.Resource_FeatureBooleans( condition ) do
		resource = GameInfo.Resources[ resource.ResourceType ]
		if resource then
			local thisResourceInstance = g_ResourcesFoundManager:GetInstance()
			if thisResourceInstance then
				AddSmallItemButton( thisResourceInstance.ResourceFoundImage, thisResourceInstance.ResourceFoundButton, CategoryResources, resource )
			end
		end
	end
	UpdateSmallButtonFrame( Controls.ResourcesFoundInnerFrame, Controls.ResourcesFoundFrame )
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Categories = {
[ CategoryHomePage ] = {
	Texture = "CivilopediaTopButtonsHome.dds",
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_HOME_PAGE_LABEL", "TXT_KEY_PEDIA_HOME_PAGE_BLURB_TEXT", "TXT_KEY_PEDIA_HOME_PAGE_HELP_TEXT", "TERRAIN_ATLAS", 20 )
	end,
},
[ CategoryGameConcepts ] = {
	Texture = "CivilopediaTopButtonsGameplay.dds",
	Info = GameInfo.Concepts,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_GAME_CONCEPT_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_GCONCEPTS", "TXT_KEY_PEDIA_GAME_CONCEPT_HELP_TEXT", "TECH_ATLAS_1", 47 )
	end,
	DisplayArticle = function( thisConcept )
		Controls.ArticleID:LocalizeAndSetText( thisConcept.Description )
		LocalizeAndSetTextBlock( Controls.SummaryLabel, Controls.SummaryInnerFrame, Controls.SummaryFrame, thisConcept.Summary )
		LocalizeAndSetTextBlock( Controls.ExtendedLabel, Controls.ExtendedInnerFrame, Controls.ExtendedFrame, thisConcept.Extended )
		LocalizeAndSetTextBlock( Controls.DNotesLabel, Controls.DNotesInnerFrame, Controls.DNotesFrame, thisConcept.DesignNotes )
	end,
},
[ CategoryTechnologies ] = {
	Texture = "CivilopediaTopButtonsTechnology.dds",
	Info = GameInfo.Technologies,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_TECH_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_TECHS", "TXT_KEY_PEDIA_TECHNOLOGIES_HELP_TEXT", "TECH_ATLAS_1", 48, "SELECT PortraitIndex, IconAtlas from Technologies ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( thisTech, techID )
		-- update the cost
		local cost = Game and Teams[Players[Game.GetActivePlayer()]:GetTeam()]:GetTeamTechs():GetResearchCost(techID) or thisTech.Cost or 0
		SetStringBlock( Controls.CostLabel, Controls.CostFrame, cost > 0 and cost.." [ICON_RESEARCH]" or L"TXT_KEY_FREE" )

		local techType = thisTech.Type
		local condition = { TechType = techType }
		local prereqCondition = { PrereqTech = techType }
		local otherPrereqCondition = { TechPrereq = techType }
		local revealCondition = { TechReveal = techType }

		-- update the prereq techs
		addPrereqTechs( GameInfo.Technology_PrereqTechs( condition ) )

		-- update the leads to techs
		g_LeadsToTechManager:ResetInstances()
		for row in GameInfo.Technology_PrereqTechs( prereqCondition ) do
			row = GameInfo.Technologies[row.TechType]
			local instance = row and g_LeadsToTechManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.LeadsToTechImage, instance.LeadsToTechButton, CategoryTechnologies, row )
			end
		end
		UpdateSmallButtonFrame( Controls.LeadsToTechInnerFrame, Controls.LeadsToTechFrame )

		-- unlocked units
		addUnlockedUnits( GameInfo.Units( prereqCondition ) )

		-- unlocked buildings
		addUnlockedBuildings( GameInfo.Buildings( prereqCondition ) )

		-- update the projects unlocked
		g_UnlockedProjectsManager:ResetInstances()
		for thisProjectInfo in GameInfo.Projects( otherPrereqCondition ) do
			local instance = not projectsToIgnore[thisProjectInfo.Type] and g_UnlockedProjectsManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.UnlockedProjectImage, instance.UnlockedProjectButton, CategoryWonders, thisProjectInfo )
			end
		end
		UpdateSmallButtonFrame( Controls.UnlockedProjectsInnerFrame, Controls.UnlockedProjectsFrame )

		-- update the resources revealed
		g_RevealedResourcesManager:ResetInstances()
		for revealedResource in GameInfo.Resources( revealCondition ) do
			local instance = g_RevealedResourcesManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.RevealedResourceImage, instance.RevealedResourceButton, CategoryResources, revealedResource )
			end
		end
		UpdateSmallButtonFrame( Controls.RevealedResourcesInnerFrame, Controls.RevealedResourcesFrame )

		-- update the build actions unlocked
		addWorkerActions( GameInfo.Builds( prereqCondition ) )

		-- update the special abilites
		local abilities = {}
		for row in GameInfo.Route_TechMovementChanges( condition ) do
			insert( abilities, L( "TXT_KEY_CIVILOPEDIA_SPECIALABILITIES_MOVEMENT", GameInfo.Routes[row.RouteType].Description) )
		end
		for row in GameInfo.Improvement_TechYieldChanges( condition ) do
			insert( abilities, L("TXT_KEY_CIVILOPEDIA_SPECIALABILITIES_YIELDCHANGES", GameInfo.Improvements[row.ImprovementType].Description, GameInfo.Yields[row.YieldType].Description, row.Yield) )
		end
		for row in GameInfo.Improvement_TechNoFreshWaterYieldChanges( condition ) do
			insert( abilities, L("TXT_KEY_CIVILOPEDIA_SPECIALABILITIES_NOFRESHWATERYIELDCHANGES", GameInfo.Improvements[row.ImprovementType].Description, GameInfo.Yields[row.YieldType].Description, row.Yield ) )
		end
		for row in GameInfo.Improvement_TechFreshWaterYieldChanges( condition ) do
			insert( abilities, L("TXT_KEY_CIVILOPEDIA_SPECIALABILITIES_FRESHWATERYIELDCHANGES", GameInfo.Improvements[row.ImprovementType].Description, GameInfo.Yields[row.YieldType].Description, row.Yield ) )
		end
		insertIfLocalized( abilities, thisTech.EmbarkedMoveChange > 0 and "TXT_KEY_ABLTY_FAST_EMBARK_STRING" )
		insertIfLocalized( abilities, thisTech.AllowsEmbarking and "TXT_KEY_ALLOWS_EMBARKING" )
		insertIfLocalized( abilities, thisTech.AllowsDefensiveEmbarking and "TXT_KEY_ABLTY_DEFENSIVE_EMBARK_STRING" )
		insertIfLocalized( abilities, thisTech.EmbarkedAllWaterPassage and "TXT_KEY_ABLTY_OCEAN_EMBARK_STRING" )
		insertIfLocalized( abilities, thisTech.AllowEmbassyTradingAllowed and "TXT_KEY_ABLTY_ALLOW_EMBASSY_STRING" )
		insertIfLocalized( abilities, thisTech.OpenBordersTradingAllowed and "TXT_KEY_ABLTY_OPEN_BORDER_STRING" )
		insertIfLocalized( abilities, thisTech.DefensivePactTradingAllowed and "TXT_KEY_ABLTY_D_PACT_STRING" )
		insertIfLocalized( abilities, thisTech.ResearchAgreementTradingAllowed and "TXT_KEY_ABLTY_R_PACT_STRING" )
		insertIfLocalized( abilities, thisTech.TradeAgreementTradingAllowed and "TXT_KEY_ABLTY_T_PACT_STRING" )
		insertIfLocalized( abilities, thisTech.BridgeBuilding and "TXT_KEY_ABLTY_BRIDGE_STRING" )
		SetTextBlock( Controls.AbilitiesLabel, Controls.AbilitiesInnerFrame, Controls.AbilitiesFrame, concat( abilities, "[NEWLINE]" ) )
	end,
},
[ CategoryUnits ] = {
	Texture = "CivilopediaTopButtonsUnit.dds",
	Info = GameInfo.Units,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_UNITS_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_UNITS", "TXT_KEY_PEDIA_UNITS_HELP_TEXT", "UNIT_ATLAS_1", 26, "SELECT PortraitIndex, IconAtlas from Units WHERE Special IS NULL OR PrereqTech IS NOT NULL ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( thisUnit, unitID )
		-- update the cost
		local cost = Game and Players[Game.GetActivePlayer()]:GetUnitProductionNeeded( unitID ) or tonumber(thisUnit.Cost) or 0
		local faithCost = IsReligionActive and Game and Game.GetFaithCost(unitID) or tonumber(thisUnit.FaithCost) or 0
		if cost > 1 and faithCost > 0 then
			LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, "TXT_KEY_PEDIA_A_OR_B", tostring(cost) .. " [ICON_PRODUCTION]", faithCost.." [ICON_PEACE]" )
		elseif faithCost > 0 then
			SetStringBlock( Controls.CostLabel, Controls.CostFrame, faithCost.." [ICON_PEACE]" )
		elseif cost > 0 then
			SetStringBlock( Controls.CostLabel, Controls.CostFrame, cost .. " [ICON_PRODUCTION]" )
		elseif thisUnit.Type ~= "UNIT_SETTLER" then
			LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, "TXT_KEY_FREE" )
		end

		-- update the Combat value
		local v = tonumber(thisUnit.Combat) or 0
		SetStringBlock( Controls.CombatLabel, Controls.CombatFrame, v > 0 and v.." [ICON_STRENGTH]" )

		-- update the Ranged Combat value
		v = tonumber(thisUnit.RangedCombat) or 0
		SetStringBlock( Controls.RangedCombatLabel, Controls.RangedCombatFrame, v > 0 and v.." [ICON_RANGE_STRENGTH]" )

		-- update the Ranged Combat range
		v = tonumber(thisUnit.Range) or 0
		SetStringBlock( Controls.RangedCombatRangeLabel, Controls.RangedCombatRangeFrame, v > 0 and v )

		-- update the Combat Type value
		v = GameInfo.UnitCombatInfos[thisUnit.CombatClass]
		LocalizeAndSetStringBlock( Controls.CombatTypeLabel, Controls.CombatTypeFrame, v and v.Description )

		-- update the Movement value
		v = thisUnit.Domain ~= "DOMAIN_AIR" and tonumber(thisUnit.Moves) or 0
		SetStringBlock( Controls.MovementLabel, Controls.MovementFrame, v > 0 and v.." [ICON_MOVES]" )

		local condition = { UnitType = thisUnit.Type }

		-- what units can be upgraded to this unit ?
		g_UpgradeManager:ResetInstances()
		for row in GameInfo.Unit_ClassUpgrades{ UnitClassType = thisUnit.Class } do
			for row in GameInfo.Units{ Type = row.UnitType } do
				local instance = ShowInPedia(row) and g_UpgradeManager:GetInstance()
				if instance then
					AddSmallItemButton( instance.UpgradeImage, instance.UpgradeButton, CategoryUnits, row )
				end
			end
		end
		UpdateSmallButtonFrame( Controls.UpgradeInnerFrame, Controls.UpgradeFrame )

		-- what units can this unit upgrade to ?
		g_UnlockedUnitsManager:ResetInstances()
		if Game then
			local row = GameInfo.Units[ Game.GetUnitUpgradesTo( unitID ) ]
			local instance = ShowInPedia(row) and g_UnlockedUnitsManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.UnlockedUnitImage, instance.UnlockedUnitButton, CategoryUnits, row )
			end
		else
			for row in GameInfo.Unit_ClassUpgrades( condition ) do
				for row in GameInfo.Units{ Class = row.UnitClassType } do
					local instance = ShowInPedia(row) and g_UnlockedUnitsManager:GetInstance()
					if instance then
						AddSmallItemButton( instance.UnlockedUnitImage, instance.UnlockedUnitButton, CategoryUnits, row )
					end
				end
			end
		end
		UpdateSmallButtonFrame( Controls.UnlockedUnitsInnerFrame, Controls.UnlockedUnitsFrame )

		-- worker commands
		addWorkerActions( GameInfo.Unit_Builds( condition ) )

		-- required resources
		addResources( GameInfo.Unit_ResourceQuantityRequirements( condition ), "TXT_KEY_PEDIA_REQ_RESRC_LABEL" )

		-- techs
		addPrereqTech( thisUnit.PrereqTech )
		addObsoleteTech( thisUnit.ObsoleteTech )

		-- similar units
		addSameClass( GameInfo.Units{ Class = thisUnit.Class }, CategoryUnits, thisUnit.ID )

		-- civilization unique
		addCivilizations( GameInfo.Civilization_UnitClassOverrides( condition ) )

		-- what promotions can this unit have ?
		local promotions = {}
		if thisUnit.CombatClass then
			for row in GameInfo.UnitPromotions_UnitCombats{ UnitCombatType = thisUnit.CombatClass } do
				promotions[ row.PromotionType ] = true
			end
		end
		-- update the the free promotions
		local abilities = {}
		for row in GameInfo.Unit_FreePromotions( condition ) do
			promotions[ row.PromotionType ] = nil
			row = GameInfo.UnitPromotions[ row.PromotionType ]
			if row then
				insert( abilities, L(row.Help or row.Description) )
			end
		end
		SetTextBlock( Controls.AbilitiesLabel, Controls.AbilitiesInnerFrame, Controls.AbilitiesFrame, concat( abilities, "[NEWLINE]" ) )

		-- update available promotions
		g_PromotionsManager:ResetInstances()
		for promotionType in pairs(promotions) do
			local row = GameInfo.UnitPromotions[ promotionType ]
			local instance = row and (row.CannotBeChosen or 0)==0 and g_PromotionsManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.PromotionImage, instance.PromotionButton, CategoryPromotions, row )
			end
		end
		UpdateSmallButtonFrame( Controls.FreePromotionsInnerFrame, Controls.FreePromotionsFrame )
	end,
},
[ CategoryPromotions ] = {
	Texture = "CivilopediaTopButtonsPromotions.dds",
	Info = GameInfo.UnitPromotions,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_PROMOTIONS_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_PROMOTIONS", "TXT_KEY_PEDIA_PROMOTIONS_HELP_TEXT", "PROMOTION_ATLAS", 16, "SELECT PortraitIndex, IconAtlas from UnitPromotions ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( thisPromotion )
		-- required promotions
		g_RequiredPromotionsManager:ResetInstances()
		for i = 1, 6 do
			local tag = thisPromotion[ "PromotionPrereqOr"..i ]
			local row = tag and GameInfo.UnitPromotions[ tag ]
			local instance = row and g_RequiredPromotionsManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.RequiredPromotionImage, instance.RequiredPromotionButton, CategoryPromotions, row )
			end
		end
		UpdateSmallButtonFrame( Controls.RequiredPromotionsInnerFrame, Controls.RequiredPromotionsFrame )

		-- update the leads to other promotions
		g_LeadsToTechManager:ResetInstances()
		local promotionType = thisPromotion.Type
		for row in GameInfo.UnitPromotions() do
			for i = 1, 6 do
				local instance = row[ "PromotionPrereqOr"..i ]==promotionType and g_LeadsToTechManager:GetInstance()
				if instance then
					AddSmallItemButton( instance.LeadsToTechImage, instance.LeadsToTechButton, CategoryPromotions, row )
					break
				end
			end
		end
		UpdateSmallButtonFrame( Controls.LeadsToTechInnerFrame, Controls.LeadsToTechFrame )

		-- what units can be promoted ?
		g_UpgradeManager:ResetInstances()
		for row in GameInfo.UnitPromotions_UnitCombats{ PromotionType = promotionType } do
			for row in GameInfo.Units{ CombatClass = row.UnitCombatType } do
				local instance = ShowInPedia(row) and g_UpgradeManager:GetInstance()
				if instance then
					if SmallButtonCount > 21 then
						SmallButtonCount = 0
						return g_UpgradeManager:ResetInstances()
					end
					AddSmallItemButton( instance.UpgradeImage, instance.UpgradeButton, CategoryUnits, row )
				end
			end
		end
		UpdateSmallButtonFrame( Controls.UpgradeInnerFrame, Controls.UpgradeFrame )

	end,
},
[ CategoryBuildings ] = {
	Texture = "CivilopediaTopButtonsBuildings.dds",
	Info = GameInfo.Buildings,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_BUILDINGS_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_BUILDINGS", "TXT_KEY_PEDIA_BUILDINGS_HELP_TEXT", "BW_ATLAS_1", 24, "SELECT PortraitIndex, IconAtlas from Buildings WHERE WonderSplashImage IS NULL ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = DisplayBuildingOrWonderArticle,
},
[ CategoryWonders ] = {
	Texture = "CivilopediaTopButtonsWonders.dds",
	Info = GameInfo.Buildings,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_WONDERS_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_WONDERS", "TXT_KEY_PEDIA_WONDERS_HELP_TEXT", "BW_ATLAS_2", 2, "SELECT PortraitIndex, IconAtlas from Buildings WHERE WonderSplashImage IS NOT NULL ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = DisplayBuildingOrWonderArticle,
},
[ CategoryPolicies ] = {
	Texture = "CivilopediaTopButtonsSocialPolicy.dds",
	Info = GameInfo.Policies,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_POLICIES_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_POLICIES", "TXT_KEY_PEDIA_SOCIAL_POL_HELP_TEXT", "POLICY_ATLAS", 25, "SELECT PortraitIndex, IconAtlas from Policies WHERE IconAtlas IS NOT NULL ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( thisPolicy )
		-- update the policy branch
		if thisPolicy.PolicyBranchType then
			local branch = GameInfo.PolicyBranchTypes[thisPolicy.PolicyBranchType]
			if branch then
				Controls.PolicyBranchLabel:LocalizeAndSetText( branch.Description )
				Controls.PolicyBranchFrame:SetHide( false )
				-- update the prereq era
				local era = GameInfo.Eras[branch.EraPrereq]
				if era then
					Controls.PrereqEraLabel:LocalizeAndSetText( era.Description )
					Controls.PrereqEraFrame:SetHide( false )
				end
			end
		end

		-- update the prereq policies
		g_RequiredPoliciesManager:ResetInstances()
		for row in GameInfo.Policy_PrereqPolicies{ PolicyType = thisPolicy.Type } do
			local requiredPolicy = GameInfo.Policies[row.PrereqPolicy]
			if requiredPolicy then
				local instance = g_RequiredPoliciesManager:GetInstance()
				AddSmallItemButton( instance.RequiredPolicyImage, instance.RequiredPolicyButton, CategoryPolicies, requiredPolicy )
			end
		end
		UpdateSmallButtonFrame( Controls.RequiredPoliciesInnerFrame, Controls.RequiredPoliciesFrame )

		if (tonumber(thisPolicy.Level)or 0)~=0 then
			Controls.TenetLevelLabel:LocalizeAndSetText( "TXT_KEY_POLICYSCREEN_L"..thisPolicy.Level.."_TENET" )
			Controls.TenetLevelFrame:SetHide( false )
		end

	end,
},
[ CategoryGreatPeople ] = {
	Texture = "CivilopediaTopButtonsGreatPersons.dds",
	Info = GameInfo.Units,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_PEOPLE_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_PEOPLE", "TXT_KEY_PEDIA_SPEC_HELP_TEXT", "UNIT_ATLAS_2", 47, "SELECT PortraitIndex, IconAtlas from Units WHERE Special IS NOT NULL AND PrereqTech IS NULL ORDER By Random() LIMIT 1" )
	end,
},
[ CategoryCivilizations ] = {
	Texture = "CivilopediaTopButtonsCivsCityStates.dds",
	Info = GameInfo.Civilizations,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_CIVILIZATIONS_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_CIVS", "TXT_KEY_PEDIA_CIVS_HELP_TEXT", "LEADER_ATLAS", 7, "SELECT l.PortraitIndex, l.IconAtlas from Leaders l INNER JOIN Civilization_Leaders cl ON cl.LeaderheadType = l.Type INNER JOIN Civilizations c ON cl.CivilizationType = c.Type WHERE l.Type <> 'LEADER_BARBARIAN' ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( thisCiv )
		local condition = { CivilizationType = thisCiv.Type }
		-- add a list of leaders
		g_LeadersManager:ResetInstances()
		for leader in GameInfo.Civilization_Leaders( condition ) do
			leader = GameInfo.Leaders[ leader.LeaderheadType ]
			if leader then
				local instance = g_LeadersManager:GetInstance()
				AddSmallItemButton( instance.LeaderImage, instance.LeaderButton, CategoryLeaders, leader )
			end
		end
		UpdateSmallButtonFrame( Controls.LeadersInnerFrame, Controls.LeadersFrame )

		-- list of UUs
		g_UniqueUnitsManager:ResetInstances()
		for unit in GameInfo.Civilization_UnitClassOverrides( condition ) do
			unit = GameInfo.Units[ unit.UnitType ]
			if ShowInPedia(unit) then
				local instance = g_UniqueUnitsManager:GetInstance()
				AddSmallItemButton( instance.UniqueUnitImage, instance.UniqueUnitButton, CategoryUnits, unit )
			end
		end
		UpdateSmallButtonFrame( Controls.UniqueUnitsInnerFrame, Controls.UniqueUnitsFrame )

		-- list of UBs
		g_UniqueBuildingsManager:ResetInstances()
		for building in GameInfo.Civilization_BuildingClassOverrides( condition ) do
			building = GameInfo.Buildings[ building.BuildingType ]
			if ShowInPedia(building) then
				local instance = g_UniqueBuildingsManager:GetInstance()
				if instance then
					AddSmallBuildingButton( instance.UniqueBuildingImage, instance.UniqueBuildingButton, building )
				end
			end
		end
		UpdateSmallButtonFrame( Controls.UniqueBuildingsInnerFrame, Controls.UniqueBuildingsFrame )

		-- list of unique improvements
		g_UniqueImprovementsManager:ResetInstances()
		for thisImprovement in GameInfo.Improvements( condition ) do
			local instance = g_UniqueImprovementsManager:GetInstance()
			AddSmallItemButton( instance.UniqueImprovementImage, instance.UniqueImprovementButton, CategoryImprovements, thisImprovement )
		end
		UpdateSmallButtonFrame( Controls.UniqueImprovementsInnerFrame, Controls.UniqueImprovementsFrame )

		-- list of special abilities
		-- add the free form text
		g_FreeFormTextManager:ResetInstances()
		local tagString = thisCiv.CivilopediaTag
		if tagString then
			local headerString = tagString .. "_HEADING_"
			local bodyString = tagString .. "_TEXT_"
			for i=1, 9 do
				local headerTag = headerString .. i
				local bodyTag = bodyString .. i
				if TagExists( headerTag ) and TagExists( bodyTag ) then
					local instance = g_FreeFormTextManager:GetInstance()
					if instance then
						instance.FFTextHeader:LocalizeAndSetText( headerTag )
						LocalizeAndSetTextBlock( instance.FFTextLabel, instance.FFTextInnerFrame, instance.FFTextFrame, bodyTag )
					end
				else
					break
				end
			end

			local factoidHeaderString = tagString .. "_FACTOID_HEADING"
			local factoidBodyString = tagString .. "_FACTOID_TEXT"
			if TagExists( factoidHeaderString ) and TagExists( factoidBodyString ) then
				local instance = g_FreeFormTextManager:GetInstance()
				if instance then
					instance.FFTextHeader:LocalizeAndSetText( factoidHeaderString )
					LocalizeAndSetTextBlock( instance.FFTextLabel, instance.FFTextInnerFrame, instance.FFTextFrame, factoidBodyString )
				end
			end
			Controls.FFTextStack:SetHide( false )
		end
	end,
},
[ CategoryCityStates ] = {
	Texture = "CivilopediaTopButtonsCities.dds",
	Info = GameInfo.MinorCivilizations,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_CITY_STATES_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_CITYSTATES", "TXT_KEY_PEDIA_CSTATES_HELP_TEXT", "UNIT_ATLAS_2", 44 )
	end,
},
[ CategoryTerrains ] = {
	Texture = "CivilopediaTopButtonsTerrian.dds",
	Info = GameInfo.Terrains,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_TERRAIN_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_TERRAIN", nil, "TERRAIN_ATLAS", 9, "SELECT PortraitIndex, IconAtlas from Terrains ORDER By Random() LIMIT 1" )
		LocalizeAndAddBBtext( "TXT_KEY_PEDIA_TERRAIN_LABEL", "TXT_KEY_PEDIA_TERRAIN_HELP_TEXT" )
		LocalizeAndAddBBtext( "TXT_KEY_PEDIA_TERRAIN_FEATURES_LABEL", "TXT_KEY_PEDIA_TERRAIN_FEATURES_HELP_TEXT" )
		return ResizeEtc()
	end,
	DisplayArticle = function( thisTerrain )

		local condition = { TerrainType = thisTerrain.Type }

		-- City Yield
		Controls.YieldFrame:SetHide( false )
		local numYields = 0
		local yieldString = ""
		for row in GameInfo.Terrain_Yields( condition ) do
			numYields = numYields + 1
			yieldString = yieldString..tostring(row.Yield).." "
			yieldString = yieldString..GameInfo.Yields[row.YieldType].IconString.." "
		end
		-- special case hackery for hills
		if thisTerrain.Type == "TERRAIN_HILL" then
			--for row in GameInfo.Yields() do
				--if row.HillsChange ~= 0 then
					--numYields = numYields + 1
					--if row.HillsChange > 0 then
						--yieldString = yieldString.."+"
					--end
					--yieldString = yieldString..tostring(row.HillsChange).." "
					--yieldString = yieldString..row.IconString.." "
				--end
			--end
			numYields = 1
			yieldString = "2 [ICON_PRODUCTION]"
		end

		if numYields == 0 then
			Controls.YieldLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_NO_YIELD" )
		else
			Controls.YieldLabel:LocalizeAndSetText( yieldString )
		end

		-- Movement
		Controls.MovementCostFrame:SetHide( false )
		local moveCost = thisTerrain.Movement or 0
		-- special case hackery for hills
		if thisTerrain.Type == "TERRAIN_MOUNTAIN" then
			Controls.MovementCostLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_IMPASSABLE" )
		elseif tonumber( moveCost ) then
			if thisTerrain.Type == "TERRAIN_HILL" then
				moveCost = moveCost + GameDefines.HILLS_EXTRA_MOVEMENT
			end
			Controls.MovementCostLabel:SetText( moveCost.."[ICON_MOVES]" )
		else
			Controls.MovementCostLabel:LocalizeAndSetText( moveCost )
		end

		-- Combat Modifier
		Controls.CombatModFrame:SetHide( false )
		local combatModifier = 0
		local combatModString = ""
		if thisTerrain.Type == "TERRAIN_HILL" or thisTerrain.Type == "TERRAIN_MOUNTAIN" then
			combatModifier = GameDefines.HILLS_EXTRA_DEFENSE
		elseif thisTerrain.Water then
			combatModifier = 0
		else
			combatModifier = GameDefines.FLAT_LAND_EXTRA_DEFENSE
		end
		if combatModifier > 0 then
			combatModString = "+"
		end
		combatModString = combatModString..tostring(combatModifier).."%"
		Controls.CombatModLabel:SetText( combatModString )

		-- Features that can exist on this terrain
		g_FeaturesManager:ResetInstances()
		for row in GameInfo.Feature_TerrainBooleans( condition ) do
			local thisFeature = GameInfo.Features[row.FeatureType]
			if thisFeature then
				local thisFeatureInstance = g_FeaturesManager:GetInstance()
				if thisFeatureInstance then
					AddSmallItemButton( thisFeatureInstance.FeatureImage, thisFeatureInstance.FeatureButton, CategoryFeatures, thisFeature )
				end
			end
		end
		UpdateSmallButtonFrame( Controls.FeaturesInnerFrame, Controls.FeaturesFrame )

		-- Resources that can exist on this terrain
		Controls.ResourcesFoundLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_RESOURCESFOUND_LABEL" )
		g_ResourcesFoundManager:ResetInstances()
		for resource in GameInfo.Resource_TerrainBooleans( condition ) do
			resource = GameInfo.Resources[ resource.ResourceType ]
			if resource then
				local thisResourceInstance = g_ResourcesFoundManager:GetInstance()
				if thisResourceInstance then
					AddSmallItemButton( thisResourceInstance.ResourceFoundImage, thisResourceInstance.ResourceFoundButton, CategoryResources, resource )
				end
			end
		end
		-- special case hackery for hills
		if thisTerrain.Type == "TERRAIN_HILL" then
			for resource in GameInfo.Resources() do
				if resource and resource.Hills then
					local thisResourceInstance = g_ResourcesFoundManager:GetInstance()
					if thisResourceInstance then
						AddSmallItemButton( thisResourceInstance.ResourceFoundImage, thisResourceInstance.ResourceFoundButton, CategoryResources, resource )
					end
				end
			end
		end
		UpdateSmallButtonFrame( Controls.ResourcesFoundInnerFrame, Controls.ResourcesFoundFrame )
	end,
},
[ CategoryResources ] = {
	HomePage = L"TXT_KEY_PEDIA_IMPROVEMENTS_PAGE_LABEL",
	Texture = "CivilopediaTopButtonsResourcesImprovements.dds",
	Info = GameInfo.Resources,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_RESOURCES_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_RESOURCES", "TXT_KEY_PEDIA_RESOURCES_HELP_TEXT", "RESOURCE_ATLAS", 6, "SELECT PortraitIndex, IconAtlas from Resources ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( resource )

		local condition = { ResourceType = resource.Type }

		-- tech visibility
		g_RevealTechsManager:ResetInstances()
		if resource.TechReveal then
			local prereq = GameInfo.Technologies[ resource.TechReveal ]
			local instance = g_RevealTechsManager:GetInstance()
			if instance then
				AddSmallItemButton( instance.RevealTechImage, instance.RevealTechButton, CategoryTechnologies, prereq )
			end
			UpdateSmallButtonFrame( Controls.RevealTechsInnerFrame, Controls.RevealTechsFrame )
		end

		-- City Yield
		Controls.YieldFrame:SetHide( false )
		local numYields = 0
		local yieldString = ""
		for row in GameInfo.Resource_YieldChanges( condition ) do
			numYields = numYields + 1
			if row.Yield > 0 then
				yieldString = yieldString.."+"
			end
			yieldString = yieldString..tostring(row.Yield)..GameInfo.Yields[row.YieldType].IconString.." "
		end

		if numYields == 0 then
			Controls.YieldLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_NO_YIELD" )
		else
			Controls.YieldLabel:SetText( yieldString )
		end

		-- found on
			Controls.ResourcesFoundLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_TERRAINS_LABEL" )
		g_ResourcesFoundManager:ResetInstances() -- okay, this is supposed to be a resource, but for now a round button is a round button
		for row in GameInfo.Resource_FeatureBooleans( condition ) do
			local thisFeature = GameInfo.Features[row.FeatureType]
			if thisFeature then
				local thisFeatureInstance = g_ResourcesFoundManager:GetInstance()
				if thisFeatureInstance then
					AddSmallItemButton( thisFeatureInstance.ResourceFoundImage, thisFeatureInstance.ResourceFoundButton, CategoryFeatures, thisFeature )
				end
			end
		end

		local bAlreadyShowingHills = false
		for row in GameInfo.Resource_TerrainBooleans( condition ) do
			local thisTerrain = GameInfo.Terrains[row.TerrainType]
			if thisTerrain then
				local thisTerrainInstance = g_ResourcesFoundManager:GetInstance()
				if thisTerrainInstance then
					if row.TerrainType == "TERRAIN_HILL" then
						bAlreadyShowingHills = true
					end

					AddSmallItemButton( thisTerrainInstance.ResourceFoundImage, thisTerrainInstance.ResourceFoundButton, CategoryTerrains, thisTerrain )
				end
			end
		end
		-- hackery for hills
		if resource and resource.Hills and not bAlreadyShowingHills then
			local thisTerrain = GameInfo.Terrains.TERRAIN_HILL
			local thisTerrainInstance = g_ResourcesFoundManager:GetInstance()
			if thisTerrainInstance then
				AddSmallItemButton( thisTerrainInstance.ResourceFoundImage, thisTerrainInstance.ResourceFoundButton, CategoryTerrains, thisTerrain )
			end
		end
		UpdateSmallButtonFrame( Controls.ResourcesFoundInnerFrame, Controls.ResourcesFoundFrame )

		-- improvement
		g_ImprovementsManager:ResetInstances()
		for row in GameInfo.Improvement_ResourceTypes( condition ) do
			local thisImprovement = GameInfo.Improvements[row.ImprovementType]
			if thisImprovement then
				local instance = g_ImprovementsManager:GetInstance()
				if instance then
					AddSmallItemButton( instance.ImprovementImage, instance.ImprovementButton, CategoryImprovements, thisImprovement )
				end
			end
		end
		UpdateSmallButtonFrame( Controls.ImprovementsInnerFrame, Controls.ImprovementsFrame )
	end,
},
[ CategoryImprovements ] = {
	HomePage = L"TXT_KEY_PEDIA_IMPROVEMENTS_PAGE_LABEL",
	Texture = "CivilopediaTopButtonsImprovements.dds",
	Info = GameInfo.Improvements,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_IMPROVEMENTS_PAGE_LABEL", "TXT_KEY_PEDIA_QUOTE_BLOCK_IMPROVEMENTS", "TXT_KEY_PEDIA_IMPROVEMENT_HELP_TEXT", "BW_ATLAS_1", 1, "SELECT PortraitIndex, IconAtlas from Improvements ORDER By Random() LIMIT 1" )
	end,
	DisplayArticle = function( thisImprovement )

		LocalizeAndSetNameAndBlurbsAndPortrait( thisImprovement )

		local condition = { ImprovementType = thisImprovement.Type }

		-- tech visibility
		addPrereqTechs( GameInfo.Builds( condition ) )

		-- City Yield
		local numYields = 0
		local yieldString = ""
		for row in GameInfo.Improvement_Yields( condition ) do
			numYields = numYields + 1
			if row.Yield > 0 then
				yieldString = yieldString.."+"
			end
			yieldString = yieldString..tostring(row.Yield)..GameInfo.Yields[row.YieldType].IconString.." "
		end

		-- culture hack for vanilla
		if IsCiv5Vanilla and thisImprovement.Culture ~= 0 then
			numYields = numYields + 1
			yieldString = yieldString.."+"..tostring(thisImprovement.Culture).."[ICON_CULTURE]"
		end

		if numYields == 0 then
			Controls.YieldLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_NO_YIELD" )
		else
			Controls.YieldLabel:SetText( yieldString )
			Controls.YieldFrame:SetHide( false )
		end

		-- add in mountain adjacency yield
		numYields = 0
		yieldString = ""
		for row in GameInfo.Improvement_AdjacentMountainYieldChanges( condition ) do
			numYields = numYields + 1
			if row.Yield > 0 then
				yieldString = yieldString.."+"
			end
			yieldString = yieldString..tostring(row.Yield)..GameInfo.Yields[row.YieldType].IconString.." "
		end
		if numYields == 0 then
			Controls.MountainYieldFrame:SetHide( true )
		else
			Controls.MountainYieldLabel:SetText( yieldString )
			Controls.MountainYieldFrame:SetHide( false )
		end

		if thisImprovement.CivilizationType then
			local thisCiv = GameInfo.Civilizations[thisImprovement.CivilizationType]
			if thisCiv then
				g_CivilizationsManager:ResetInstances()
				local instance = g_CivilizationsManager:GetInstance()
				if instance then
					AddSmallItemButton( instance.CivilizationImage, instance.CivilizationButton, CategoryCivilizations, thisCiv )
				end
			end
		end
		UpdateSmallButtonFrame( Controls.CivilizationsInnerFrame, Controls.CivilizationsFrame )

		-- found on
		Controls.ResourcesFoundLabel:LocalizeAndSetText( "TXT_KEY_PEDIA_FOUNDON_LABEL" )
		g_ResourcesFoundManager:ResetInstances() -- okay, this is supposed to be a resource, but for now a round button is a round button
		for row in GameInfo.Improvement_ValidFeatures( condition ) do
			local thisFeature = GameInfo.Features[row.FeatureType]
			if thisFeature then
				local thisFeatureInstance = g_ResourcesFoundManager:GetInstance()
				if thisFeatureInstance then
					AddSmallItemButton( thisFeatureInstance.ResourceFoundImage, thisFeatureInstance.ResourceFoundButton, CategoryFeatures, thisFeature )
				end
			end
		end
		for row in GameInfo.Improvement_ValidTerrains( condition ) do
			local thisTerrain = GameInfo.Terrains[row.TerrainType]
			if thisTerrain then
				local thisTerrainInstance = g_ResourcesFoundManager:GetInstance()
				if thisTerrainInstance then
					AddSmallItemButton( thisTerrainInstance.ResourceFoundImage, thisTerrainInstance.ResourceFoundButton, CategoryTerrains, thisTerrain )
				end
			end
		end
		-- hackery for hills
		--if thisImprovement and thisImprovement.HillsMakesValid then
			--local thisTerrain = GameInfo.Terrains.TERRAIN_HILL
			--local thisTerrainInstance = g_ResourcesFoundManager:GetInstance()
			--if thisTerrainInstance then
				--local textureSheet
				--local textureOffset
				--textureSheet = "blank.dds"
				--textureOffset = nullOffset
				--AddSmallItemButton( thisTerrainInstance.ResourceFoundImage, thisTerrainInstance.ResourceFoundButton, CategoryTerrains, thisTerrain )
			--end
		--end
		UpdateSmallButtonFrame( Controls.ResourcesFoundInnerFrame, Controls.ResourcesFoundFrame )

		addResources( GameInfo.Improvement_ResourceTypes( condition ), "TXT_KEY_PEDIA_IMPROVES_RESRC_LABEL" )
	end,
},
[ CategoryReligions ] = IsCiv5notVanilla and {
	Texture = "CivilopediaTopButtonsReligion.dds",
	Info = GameInfo.Religions,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_BELIEFS_PAGE_LABEL", "TXT_KEY_PEDIA_BELIEFS_HOMEPAGE_BLURB", nil, "Religion256.dds" )
		LocalizeAndAddBBtext( "TXT_KEY_PEDIA_BELIEFS_HOMEPAGE_LABEL1", "TXT_KEY_PEDIA_BELIEFS_HOMEPAGE_TEXT1" )
		return ResizeEtc()
	end,
},
[ CategoryLeagueProjects ] = IsCiv5BNW and {
	Texture = "CivilopediaTopButtonsWorldCongress.dds",
	Info = GameInfo.LeagueProjects,
	DisplayHomePage = function()
		DoDisplayHomePage( "TXT_KEY_PEDIA_WORLD_CONGRESS_PAGE_LABEL", "TXT_KEY_PEDIA_WORLD_CONGRESS_HOMEPAGE_BLURB", nil, "WorldCongressPortrait256_EXP2.dds" )
		LocalizeAndAddBBtext( "TXT_KEY_PEDIA_WORLD_CONGRESS_HOMEPAGE_LABEL1", "TXT_KEY_PEDIA_WORLD_CONGRESS_HOMEPAGE_TEXT1" )
		return ResizeEtc()
	end,
	DisplayArticle = function( thisLeagueProject, rowID )
		local s = ""
		for i = 3, 1, -1 do
			local reward = thisLeagueProject["RewardTier" .. i]
			reward = reward and GameInfo.LeagueProjectRewards[ reward ]
			if reward then
				s = s .. L( "TXT_KEY_PEDIA_LEAGUE_PROJECT_REWARD", TrophyIcons[i], reward.Description or "", reward.Help or "" )
			end
			if i > 1 then
				s = s .. "[NEWLINE][NEWLINE]"
			end
		end
		SetTextBlock( Controls.SummaryLabel, Controls.SummaryInnerFrame, Controls.SummaryFrame, s )

		-- update the cost
		local league = Game and Game.GetNumActiveLeagues() > 0 and Game.GetActiveLeague()
		local cost = league and league:GetProjectCostPerPlayer( rowID ) / 100 or tonumber(thisLeagueProject.CostPerPlayer) or 0
		LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, cost>0 and "TXT_KEY_LEAGUE_PROJECT_COST_PER_PLAYER", cost )
	end,
},
[ CategoryProjects ] = {
	Info = GameInfo.Projects,
	DisplayArticle = function( thisProject )
		-- update the cost
		local cost = Game and Players[Game.GetActivePlayer()]:GetProjectProductionNeeded( thisProject.ID ) or tonumber(thisProject.Cost) or 0
		if cost > 0 then
			SetStringBlock( Controls.CostLabel, Controls.CostFrame, cost.." [ICON_PRODUCTION]" )
		elseif cost == 0 then
			LocalizeAndSetStringBlock( Controls.CostLabel, Controls.CostFrame, "TXT_KEY_FREE" )
		end
		-- update the prereq techs
		addPrereqTech( thisProject.PrereqTech )
		-- required buildings
		addRequiredBuildings( GameInfo.Building_ClassesNeededInCity{ BuildingType = thisProject.Type } )
	end,
},
[ CategoryFeatures ] = {
	Info = GameInfo.Features,
	DisplayArticle = DisplayFeatureArticle,
},
[ CategoryFakeFeatures ] = {
	Info = GameInfo.FakeFeatures,
	DisplayArticle = DisplayFeatureArticle,
},
[ CategoryRoutes ] = {
	Info = GameInfo.Routes,
	DisplayArticle = function( row )
		addPrereqTechs( GameInfo.Builds{ RouteType = row.Type } )
	end,
},
[ CategoryLeaders ] = {
	Info = GameInfo.Leaders,
	DisplayArticle = function( leader )
		local tagString = leader.CivilopediaTag
		if tagString then
			Controls.ArticleID:LocalizeAndSetText( tagString.."_NAME" )
			Controls.SubtitleLabel:LocalizeAndSetText( tagString.."_SUBTITLE" )
			Controls.SubtitleID:SetHide( false )
			-- add titles etc.
			Controls.LivedLabel:LocalizeAndSetText( tagString.."_LIVED" )
			Controls.LivedFrame:SetHide( false )

			local titlesString = tagString .. "_TITLES_"
			local notFound = false
			local i = 1
			local titles = ""
			local numTitles = 0
			repeat
				local titlesTag = titlesString .. tostring( i )
				if TagExists( titlesTag ) then
					if numTitles > 0 then
						titles = titles .. "[NEWLINE][NEWLINE]"
					end
					numTitles = numTitles + 1
					titles = titles .. L( titlesTag )
				else
					notFound = true
				end
				i = i + 1
			until notFound
			if numTitles > 0 then
				SetTextBlock( Controls.TitlesLabel, Controls.TitlesInnerFrame, Controls.TitlesFrame, titles )
			end
		end

		g_FreeFormTextManager:ResetInstances()
		-- list of traits
		--g_TraitsManager:ResetInstances()
		for trait in GameInfo.Leader_Traits{ LeaderType = leader.Type } do
			trait = GameInfo.Traits[ trait.TraitType ]
			if trait then
				local instance = g_FreeFormTextManager:GetInstance()
				--local instance = g_TraitsManager:GetInstance()
				--AddSmallItemButton( instance.TraitImage, instance.TraitButton, CategoryGameConcepts, trait )
				instance.FFTextHeader:LocalizeAndSetText( trait.ShortDescription )
				LocalizeAndSetTextBlock( instance.FFTextLabel, instance.FFTextInnerFrame, instance.FFTextFrame, trait.Description )
			end
		end
		--UpdateSmallButtonFrame( Controls.TraitsInnerFrame, Controls.TraitsFrame )

		-- add the civ icons
		g_CivilizationsManager:ResetInstances()
		for civ in GameInfo.Civilization_Leaders{ LeaderheadType = leader.Type } do
			civ = GameInfo.Civilizations[ civ.CivilizationType ]
			if civ then
				local instance = g_CivilizationsManager:GetInstance()
				AddSmallItemButton( instance.CivilizationImage, instance.CivilizationButton, CategoryCivilizations, civ )
			end
		end
		UpdateSmallButtonFrame( Controls.CivilizationsInnerFrame, Controls.CivilizationsFrame )

		-- add the free form text
		if tagString then
			local headerString = tagString .. "_HEADING_"
			local bodyString = tagString .. "_TEXT_"
			for i=1, 9 do
				local headerTag = headerString .. i
				local bodyTag = bodyString .. i
				if TagExists( headerTag ) and TagExists( bodyTag ) then
					local instance = g_FreeFormTextManager:GetInstance()
					instance.FFTextHeader:LocalizeAndSetText( headerTag )
					LocalizeAndSetTextBlock( instance.FFTextLabel, instance.FFTextInnerFrame, instance.FFTextFrame, bodyTag )
				else
					break
				end
			end
			bodyString = tagString .. "_FACT_"
			for i=1, 9 do
				local bodyTag = bodyString .. i
				if TagExists( bodyTag ) then
					local instance = g_FreeFormTextManager:GetInstance()
					if instance then
						instance.FFTextHeader:LocalizeAndSetText( "TXT_KEY_PEDIA_FACTOID" )
						LocalizeAndSetTextBlock( instance.FFTextLabel, instance.FFTextInnerFrame, instance.FFTextFrame, bodyTag )
					end
				else
					break
				end
			end
			Controls.FFTextStack:SetHide( false )
		end
	end,
},
[ CategorySpecialists ] = {
	Info = GameInfo.Specialists,
},
[ CategoryBeliefs ] = IsCiv5notVanilla and {
	Info = GameInfo.Beliefs,
	DisplayArticle = function( row )
		LocalizeAndSetTextBlock( Controls.SummaryLabel, Controls.SummaryInnerFrame, Controls.SummaryFrame, row.Description )
	end,
},
[ CategoryResolutions ] = IsCiv5BNW and {
	Info = GameInfo.Resolutions,
	DisplayArticle = function()
		Controls.Portrait:SetTexture( "WorldCongressPortrait256_EXP2.dds" )
		Controls.Portrait:SetTextureOffsetVal( 0,0 )
		Controls.PortraitFrame:SetHide( false )
	end,
},
}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local section, sections

local function newCategory( categoryID, label )
	sections = { HomePage = label }
	ArticlesBySection[ categoryID ] = sections
end

local function newSection( label, isClosed )
	section = { HeadingName = label, HeadingClosed = isClosed }
end

local function insertSection( func )
	if #section > 0 then
		if func then
			sort( section, func )
		end
		insert( sections, section )
	end
end

-- sort method for sorting alphabetically.
local function Alphabetically( a, b )
	return Compare(a and a.entryName or"", b and b.entryName or"") == -1
end

local function createArticle( categoryID, entryID, name )
	local article={
		entryName = name,
		entryID = entryID,
		CategoryID = categoryID,
	}
	Categories[ categoryID ][ entryID ] = article
	ArticlesByNameLowerCase[ ToLower(name) ] = article
	return article
end


local function insertArticle( categoryID, row )
	local article = createArticle( categoryID, row.ID, row._Name )
	ArticlesByNameKey[ row.ShortDescription or row.Description or "" ] = article
	insert( section, article )
	return article
end

-------------------------------------------------------------------------------
newCategory( CategoryHomePage ) -- no home page
newSection() -- no header
createArticle( CategoryHomePage, -1, L"TXT_KEY_PEDIA_HOME_PAGE_LABEL" )

for categoryID =1, 99 do
	local button = Controls[ "CategoryButton"..categoryID ]
	if button then
		if Categories[ categoryID ] then
			button:RegisterCallback( eLClick, SelectArticleHistorized )
			button:SetVoids( categoryID, -1 )
			insert( section, createArticle( categoryID, -1, L("TXT_KEY_PEDIA_CATEGORY_" .. categoryID .. "_LABEL") ) )
		else
			button:SetHide( true )
		end
	else
		break
	end
end
insertSection() -- no sort

-------------------------------------------------------------------------------
newCategory( CategoryGameConcepts, L"TXT_KEY_PEDIA_GAME_CONCEPT_PAGE_LABEL" )

for i, k in ipairs{ "HEADER_CITIES", "HEADER_COMBAT", "HEADER_TERRAIN", "HEADER_RESOURCES", "HEADER_IMPROVEMENTS", "HEADER_CITYGROWTH", "HEADER_TECHNOLOGY", "HEADER_CULTURE", "HEADER_DIPLOMACY", "HEADER_HAPPINESS", "HEADER_FOW", "HEADER_POLICIES", "HEADER_GOLD", "HEADER_ADVISORS", "HEADER_PEOPLE", "HEADER_CITYSTATE", "HEADER_MOVEMENT", "HEADER_AIRCOMBAT", "HEADER_RUBARB", "HEADER_UNITS", "HEADER_VICTORY", "HEADER_ESPIONAGE", "HEADER_RELIGION", "HEADER_TRADE", "HEADER_WORLDCONGRESS" } do
	newSection( L("TXT_KEY_GAME_CONCEPT_SECTION_"..i), true )
	for thisConcept in GameInfo.Concepts{ CivilopediaHeaderType = k } do
		local article = insertArticle( CategoryGameConcepts, thisConcept )
		article.InsertBefore = thisConcept.InsertBefore
		article.InsertAfter = thisConcept.InsertAfter
		article.Type = thisConcept.Type
	end
	insertSection() -- no sort
end
--[[

-- In order to maintain the original order as best as possible,
-- we assign "InsertBefore" values to all items that lack any insert.
for _, conceptList in ipairs(sections) do
	for i = #conceptList, 1, -1 do
		local concept = conceptList[i]
		if(concept.InsertBefore == nil and concept.InsertAfter == nil) then
			for ii = i - 1, 1, -1 do
				local previousConcept = conceptList[ii]
				if(previousConcept.InsertBefore == nil and previousConcept.InsertAfter == nil) then
					concept.InsertAfter = previousConcept.Type
					break
				end
			end
		end
	end
end

-- sort the articles by their dependencies.
function DependencySort(articles)

	-- index articles by Topic
	local articlesByType= {}
	local dependencies = {}

	for i,v in ipairs(articles) do
		articlesByType[v.Type] = v
		dependencies[v] = {}
	end

	for i,v in ipairs(articles) do

		local insertBefore = v.InsertBefore
		if(insertBefore ~= nil) then
			local article = articlesByType[insertBefore]
			dependencies[article][v] = true
		end

		local insertAfter = v.InsertAfter
		if(insertAfter ~= nil) then
			local article = articlesByType[insertAfter]
			dependencies[v][article] = true
		end
	end

	local ArticlesBySection = {}

	local articleCount = #articles
	while(#ArticlesBySection < articleCount) do

		-- Attempt to find a node with 0 dependencies
		local article
		for i,a in ipairs(articles) do
			if(dependencies[a] ~= nil and table.count(dependencies[a]) == 0) then
				article = a
				break
			end
		end

		if(article == nil) then
			print("Failed to sort articles topologically!! There are dependency cycles.")
			return nil
		else

			-- Insert Node
			insert( ArticlesBySection, article )

			-- Remove node
			dependencies[article] = nil
			for a,d in pairs(dependencies) do
				d[article] = nil
			end
		end
	end

	return ArticlesBySection
end

for i,v in ipairs(sections) do
	local oldList = v
	local newList = DependencySort(v)

	if(newList == nil) then
		newList = oldList
	else
		newList.headingOpen = false
	end

	sections[i] = newList
end

--]]

-------------------------------------------------------------------------------
newCategory( CategoryTechnologies, L"TXT_KEY_PEDIA_TECH_PAGE_LABEL" )

for era in GameInfo.Eras() do
	newSection( era._Name )
	for tech in GameInfo.Technologies{ Era = era.Type } do
		insertArticle( CategoryTechnologies, tech )
	end
	insertSection( Alphabetically )
end

-------------------------------------------------------------------------------
newCategory( CategoryUnits, L"TXT_KEY_PEDIA_UNITS_PAGE_LABEL" )

-- Add units which cost faith to a "Faith" section first.
if IsReligionActive then
	newSection( L"TXT_KEY_PEDIA_RELIGIOUS" )
	for unit in GameInfo.Units{ Cost = -1 } do
		if ShowInPedia( unit ) and not unit.RequiresFaithPurchaseEnabled and (tonumber(unit.FaithCost) or 0) > 0 then
			insertArticle( CategoryUnits, unit )
		end
	end
	insertSection( Alphabetically )
end

-- Categorize units by era, placing those without tech requirements in the Ancient Era for lack of a better place
local isFirstEra = true
for era in GameInfo.Eras() do
	newSection( era._Name )
	for unit in GameInfo.Units() do
		if ShowInPedia( unit ) and ( unit.RequiresFaithPurchaseEnabled or (tonumber(unit.FaithCost) or 0) == 0 or unit.Cost >= 0 ) then
			local tech = GameInfo.Technologies[ unit.PrereqTech ]
			if tech and tech.Era == era.Type or isFirstEra and not unit.PrereqTech and not unit.Special then
				insertArticle( CategoryUnits, unit )
			end
		end
	end
	insertSection( Alphabetically )
	isFirstEra = false
end

-------------------------------------------------------------------------------
newCategory( CategoryPromotions, L"TXT_KEY_PEDIA_PROMOTIONS_PAGE_LABEL" )

for i, pediaType in ipairs{ "PEDIA_MELEE", "PEDIA_RANGED", "PEDIA_NAVAL", "PEDIA_HEAL", "PEDIA_SCOUTING", "PEDIA_AIR", "PEDIA_SHARED", "PEDIA_ATTRIBUTES" } do
	newSection( L("TXT_KEY_PROMOTIONS_SECTION_"..i) )
	for thisPromotion in GameInfo.UnitPromotions{ PediaType = pediaType } do
		insertArticle( CategoryPromotions, thisPromotion )
	end
	insertSection( Alphabetically )
end

-------------------------------------------------------------------------------
newCategory( CategoryBuildings, L"TXT_KEY_PEDIA_BUILDINGS_PAGE_LABEL" )

--Add Faith Buildings first
if IsReligionActive then
	newSection( L"TXT_KEY_PEDIA_RELIGIOUS" )
	for building in GameInfo.Buildings{ Cost = -1 } do
		local class = GameInfo.BuildingClasses[ building.BuildingClass ]
		if class and ShowInPedia(building) and (building.FaithCost or 0) > 0 and class.MaxGlobalInstances < 0 and (class.MaxPlayerInstances ~= 1 or building.SpecialistCount > 0) and class.MaxTeamInstances < 0 then
			insertArticle( CategoryBuildings, building )
		end
	end
	insertSection( Alphabetically )
end

-- Categorize buildings by era, placing those without tech requirements in the Ancient Era for lack of a better place
isFirstEra = true
for era in GameInfo.Eras() do
	newSection( era._Name )
	for building in GameInfo.Buildings() do
		local tech = GameInfo.Technologies[ building.PrereqTech ]
		if tech and tech.Era == era.Type or isFirstEra and not tech then
			local class = GameInfo.BuildingClasses[ building.BuildingClass ]
			if class and ShowInPedia(building) and ((building.FaithCost or 0) == 0 or building.Cost >= 0) and class.MaxGlobalInstances < 0 and (class.MaxPlayerInstances ~= 1 or building.SpecialistCount > 0) and class.MaxTeamInstances < 0 then
				insertArticle( CategoryBuildings, building )
			end
		end
	end
	insertSection( Alphabetically )
	isFirstEra = false
end

-------------------------------------------------------------------------------
newCategory( CategoryWonders, L"TXT_KEY_PEDIA_WONDERS_PAGE_LABEL" )

-- first Wonders
newSection( L"TXT_KEY_WONDER_SECTION_1" )
for building in GameInfo.Buildings() do
	-- exclude wonders etc.
	local class = GameInfo.BuildingClasses[building.BuildingClass]
	if class and ShowInPedia(building) and class.MaxGlobalInstances > 0  then
		insertArticle( CategoryWonders, building )
	end
end
insertSection( Alphabetically )

-- next National Wonders
newSection( L"TXT_KEY_WONDER_SECTION_2" )
for building in GameInfo.Buildings() do
	local class = GameInfo.BuildingClasses[building.BuildingClass]
	if class and ShowInPedia(building) and class.MaxPlayerInstances == 1 and building.SpecialistCount == 0 then
		insertArticle( CategoryWonders, building )
	end
end
insertSection( Alphabetically )

-- finally Projects
newSection( L"TXT_KEY_WONDER_SECTION_3" )
for row in GameInfo.Projects() do
	if ShowInPedia(row) and not projectsToIgnore[row.Type] then
		insertArticle( CategoryProjects, row )
	end
end
insertSection( Alphabetically )

-------------------------------------------------------------------------------
newCategory( CategoryPolicies, L"TXT_KEY_PEDIA_POLICIES_PAGE_LABEL" )

for branch in GameInfo.PolicyBranchTypes() do

	newSection( branch._Name )
	-- for each policy in this branch
	for policy in GameInfo.Policies{ PolicyBranchType = branch.Type } do
		insertArticle( CategoryPolicies, policy )
	end

	-- put in free policies that belong to this branch on top
	local freePolicy = branch.FreePolicy and GameInfo.Policies[branch.FreePolicy]
	if freePolicy then
		insertArticle( CategoryPolicies, freePolicy )
	end
	insertSection( Alphabetically )
end

-------------------------------------------------------------------------------
newCategory( CategoryGreatPeople, L"TXT_KEY_PEDIA_PEOPLE_PAGE_LABEL" )

-- first Specialists
newSection( L"TXT_KEY_PEOPLE_SECTION_1" )
for person in GameInfo.Specialists() do
	insertArticle( CategorySpecialists, person )
end
insertSection( Alphabetically )

-- next Great People
newSection( L"TXT_KEY_PEOPLE_SECTION_2" )
for unit in GameInfo.Units() do
	if ShowInPedia(unit) and not unit.PrereqTech and unit.Special then
		insertArticle( CategoryGreatPeople, unit )
	end
end
insertSection( Alphabetically )

-------------------------------------------------------------------------------
newCategory( CategoryCivilizations, L"TXT_KEY_PEDIA_CIVILIZATIONS_PAGE_LABEL" )

-- first Civilizations
newSection( L"TXT_KEY_CIVILIZATIONS_SECTION_1" )
for row in GameInfo.Civilizations() do
	if row.Type ~= "CIVILIZATION_MINOR" and row.Type ~= "CIVILIZATION_BARBARIAN" then
		insertArticle( CategoryCivilizations, row )
	end
end
insertSection( Alphabetically )

-- next Leaders
newSection( L"TXT_KEY_CIVILIZATIONS_SECTION_2" )
for row in GameInfo.Civilizations() do
	if row.Type ~= "CIVILIZATION_MINOR" and row.Type ~= "CIVILIZATION_BARBARIAN" then
		row = GameInfo.Civilization_Leaders{ CivilizationType = row.Type }()
		row = row and GameInfo.Leaders[ row.LeaderheadType ]
		if row then
			insertArticle( CategoryLeaders, row )
		end
	end
end
insertSection( Alphabetically )

-------------------------------------------------------------------------------
newCategory( CategoryCityStates, L"TXT_KEY_PEDIA_CITY_STATES_PAGE_LABEL" )

for trait in GameInfo.MinorCivTraits() do
	newSection( trait._Name )
	-- for each city state that has this trait
	for cityState in GameInfo.MinorCivilizations{ MinorCivTrait = trait.Type } do
		insertArticle( CategoryCityStates, cityState )
	end
	insertSection( Alphabetically )
end

-------------------------------------------------------------------------------
newCategory( CategoryTerrains, L"TXT_KEY_PEDIA_TERRAIN_PAGE_LABEL" )

newSection( L"TXT_KEY_TERRAIN_SECTION_1" )
for row in GameInfo.Terrains() do
	insertArticle( CategoryTerrains, row )
end
insertSection( Alphabetically )

newSection( L"TXT_KEY_TERRAIN_SECTION_2" )
for row in GameInfo.Features() do
	insertArticle( CategoryFeatures, row )
end
for row in GameInfo.FakeFeatures() do
	insertArticle( CategoryFakeFeatures, row )
end
insertSection( Alphabetically )

-------------------------------------------------------------------------------
newCategory( CategoryResources, L"TXT_KEY_PEDIA_RESOURCES_PAGE_LABEL" )

for i = 0, 2 do
	-- for each type of resource
	newSection( L("TXT_KEY_RESOURCES_SECTION_"..i) )
	for resource in GameInfo.Resources{ ResourceUsage = i } do
		insertArticle( CategoryResources, resource )
	end
	insertSection( Alphabetically )
end

-------------------------------------------------------------------------------
newCategory( CategoryImprovements, L"TXT_KEY_PEDIA_IMPROVEMENTS_PAGE_LABEL" )
newSection() -- no header
for row in GameInfo.Improvements() do
	if not row.GraphicalOnly then
		insertArticle( CategoryImprovements, row )
	end
end
for row in GameInfo.Routes() do
	insertArticle( CategoryRoutes, row )
end
insertSection( Alphabetically )

-------------------------------------------------------------------------------
if IsCiv5notVanilla then
	newCategory( CategoryReligions, L"TXT_KEY_PEDIA_BELIEFS_PAGE_LABEL" )

	newSection( L"TXT_KEY_PEDIA_BELIEFS_CATEGORY_1" )
	for religion in GameInfo.Religions() do
		if religion.Type ~= "RELIGION_PANTHEON" then
			insertArticle( CategoryReligions, religion )
		end
	end
	insertSection( Alphabetically )

	for i, tag in ipairs{ "Pantheon", "Founder", "Follower", "Enhancer", IsCiv5BNW and "Reformation" } do
		newSection( L("TXT_KEY_PEDIA_BELIEFS_CATEGORY_"..i+1) )
		for belief in GameInfo.Beliefs() do
			if (belief[tag] or 0)~=0 then
				insertArticle( CategoryBeliefs, belief )
			end
		end
		insertSection( Alphabetically )
	end
end

-------------------------------------------------------------------------------
if IsCiv5BNW then
	newCategory( CategoryLeagueProjects, L"TXT_KEY_PEDIA_WORLD_CONGRESS_PAGE_LABEL" )

	newSection( L"TXT_KEY_PEDIA_WORLD_CONGRESS_CATEGORY_1" )
	for resolution in GameInfo.Resolutions() do
		insertArticle( CategoryResolutions, resolution )
	end
	insertSection( Alphabetically )

	newSection( L"TXT_KEY_PEDIA_WORLD_CONGRESS_CATEGORY_2" )
	for leagueProject in GameInfo.LeagueProjects() do
		insertArticle( CategoryLeagueProjects, leagueProject )
	end
	insertSection( Alphabetically )
end

SelectArticleHistorized( CategoryHomePage )

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function GotoArticle( article, shouldHistorize )
	if article then
		SelectArticle( article.CategoryID, article.entryID, shouldHistorize )
	end
end

function OnClose()
	Controls.Portrait:UnloadTexture()
	UIManager:DequeuePopup( ContextPtr )
end
Controls.CloseButton:RegisterCallback( eLClick, OnClose )

Controls.BackButton:RegisterCallback( eLClick, function()
	if ArticlesHistoryIndex > 1 then
		ArticlesHistoryIndex = ArticlesHistoryIndex - 1
		GotoArticle( ArticlesHistory[ ArticlesHistoryIndex ] )
	end
end)

Controls.ForwardButton:RegisterCallback( eLClick, function()
	if ArticlesHistoryIndex < #ArticlesHistory then
		ArticlesHistoryIndex = ArticlesHistoryIndex + 1
		GotoArticle( ArticlesHistory[ ArticlesHistoryIndex ] )
	end
end)

local function OnSearchButtonClicked()
	local searchString = Controls.SearchEditBox:GetText()
	local y=0
	if searchString and searchString:match"[]%c\"<>|/\\*?[]" == nil and searchString:gsub("%s", ""):len() > 2 then
		UIManager:SetUICursor( 1 )
		local lowerCaseSearchString = ToLower(searchString)
		local instance, new
		local articles = {}
		for k, v in pairs(ArticlesByNameLowerCase) do
			if string.find( k, lowerCaseSearchString ) then
				insert( articles, v )
			end
		end
		sort( articles, Alphabetically )
		g_SearchResultItemManager:ResetInstances()
		for _, v in ipairs(articles) do
			instance, new = g_SearchResultItemManager:GetInstance()
			if new then
				instance.ListItemButton:RegisterCallback( eLClick, SelectArticleHistorized )
				instance.ListItemButton:SetToolTipCallback( TipHandler )
			end
			instance.ListItemButton:SetText( v.entryName )
			instance.ListItemButton:SetVoids( v.CategoryID, v.entryID )
		end
		Controls.SearchResultsStack:CalculateSize()
		y = Controls.SearchResultsStack:GetSizeY()
		if y>0 then
			Controls.SearchScrollPanel:SetSizeY( math.min( y, screenSizeY-400 ) )
			Controls.SearchScrollPanel:CalculateInternalSize()
			Controls.SearchGrid:DoAutoSize()
		end
		UIManager:SetUICursor( 0 )
	end
	Controls.SearchGrid:SetHide( y<=0 )
end
Controls.SearchEditBox:RegisterCallback( OnSearchButtonClicked )
Controls.SearchButton:RegisterCallback( eLClick, OnSearchButtonClicked )

Events.SearchForPediaEntry.Add( function( searchString )
	UIManager:SetUICursor( 1 )
	if ContextPtr:IsHidden() then
		UIManager:QueuePopup( ContextPtr, PopupPriority.eUtmost )
	end
	local article = ArticlesByNameKey[ searchString ]
	searchString = ToLower( ( tostring(searchString or ""):gsub("[]%c\"<>|/\\*?[]", "") ) )
	article = article or ArticlesByNameLowerCase[ searchString ]
	if article then
		GotoArticle( article, true )
	else
		Controls.SearchEditBox:SetText( searchString )
		SelectArticleHistorized( CategoryHomePage )
		OnSearchButtonClicked()
	end
	UIManager:SetUICursor( 0 )
end)

Events.GoToPediaHomePage.Add( function( iHomePage )
	UIManager:SetUICursor( 1 )
	UIManager:QueuePopup( ContextPtr, PopupPriority.Civilopedia )
	SelectArticleHistorized( iHomePage )
	UIManager:SetUICursor( 0 )
end)

ContextPtr:SetInputHandler( function( uiMsg, wParam )
	if uiMsg == KeyDown then
		if wParam == VK_ESCAPE then
			if Controls.SearchGrid:IsHidden() then
				OnClose()
			else
--				Controls.SearchEditBox:TakeFocus()
				Controls.SearchGrid:SetHide( true )
			end
			return true
		end
	end
end)

ContextPtr:SetShowHideHandler( function( isHide )
	if isHide then
		Controls.Portrait:UnloadTexture()
		Events.SystemUpdateUI.CallImmediate( BulkShowUI )
		Events.GameplaySetActivePlayer.Remove( OnClose )
		Events.MultiplayerGameLobbyInvite.Remove( OnClose )
		Events.MultiplayerGameServerInvite.Remove( OnClose )
	else
		Events.SystemUpdateUI.CallImmediate( BulkHideUI )
		if Categories then
			local article = ArticlesHistory[ ArticlesHistoryIndex ]
			if article then
				GotoArticle( article )
			else
				selectedCategory = nil
				SelectArticleHistorized( CategoryHomePage )
			end
		else
			local cursor = UIManager:SetUICursor( 1 )
			print"Reload"
			ContextPtr:Reload()
			UIManager:SetUICursor( cursor )
		end
		Events.GameplaySetActivePlayer.Add( OnClose )
		Events.MultiplayerGameLobbyInvite.Add( OnClose )
		Events.MultiplayerGameServerInvite.Add( OnClose )
	end
end)

if not Game then
	local function RequireRefresh()
		-- assumes ContextPtr is hidden while this happens
		print"RequireRefresh"
		Categories = nil
	end
	Events.AfterModsDeactivate.Add( RequireRefresh )
	Events.AfterModsActivate.Add( RequireRefresh )
end
