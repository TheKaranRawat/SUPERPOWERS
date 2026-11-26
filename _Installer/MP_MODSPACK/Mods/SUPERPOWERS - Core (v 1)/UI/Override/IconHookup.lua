--==========================================================
-- Re-written by bc1 using Notepad++
-- Caches stuff and defines AddSerialEventGameMessagePopup
--==========================================================

--print( "Lua memory in use: ", Locale.ToNumber( collectgarbage("count") * 1024, "#,###,###,###" ), "ContextID", ContextPtr:GetID(), "isHotLoad", ContextPtr:IsHotLoad() )
local GameInfo = GameInfoCache or GameInfo

include "FLuaVector"
local Color = Color
local ColorWhite = Color( 1, 1, 1, 1 )

--==========================================================
-- Minor lua optimizations
--==========================================================

local floor = math.floor
local print = print

local IsCiv5 = InStrategicView ~= nil
local GameInfoIconTextureAtlases = GameInfo.IconTextureAtlases
local GameInfoCivilizations = GameInfo.Civilizations
local GameInfoPlayerColors = GameInfo.PlayerColors
local GameInfoColors = GameInfo.Colors
local GetCivilization = PreGame.GetCivilization
local GetCivilizationColor = PreGame.GetCivilizationColor

local IconTextureAtlasCache = setmetatable( {}, { __index = function( IconTextureAtlasCache, name )
	local atlas = {}
	if name then
		for row in GameInfoIconTextureAtlases{ Atlas=name } do
			atlas[ row.IconSize ] = { row.Filename, row.IconsPerRow, row.IconsPerColumn }
		end
		IconTextureAtlasCache[ name ] = atlas
	end
	return atlas
end})

-- cache only ingame, pregame player slots can change
local Cache = Game and function( value, table, key )
	table[ key ] = value
	return value
end or function( value )
	return value
end

local PlayerCivilizationInfo = setmetatable( {}, { __index = function( table, playerID )
	return Cache( GameInfoCivilizations[ GetCivilization( playerID ) ], table, playerID )
end})

local function GetPlayerColor( playerID, RGB )
	local playerCivilizationInfo = PlayerCivilizationInfo[ playerID ]
	local color = playerCivilizationInfo and ( GameInfoPlayerColors[ GetCivilizationColor( playerID ) ] or GameInfoPlayerColors[ playerCivilizationInfo.DefaultPlayerColor ] )
	color = color and GameInfoColors[ color[ (playerCivilizationInfo.Type ~= "CIVILIZATION_MINOR")==(RGB==1) and "PrimaryColor" or "SecondaryColor" ] ]
	return color and Color( color.Red, color.Green, color.Blue, color.Alpha ) or Color( RGB, RGB, RGB, 1 )
end

local IsPlayerUsingCustomColor = setmetatable( {}, { __index = function( table, playerID )
	local playerCivilizationInfo = PlayerCivilizationInfo[ playerID ]
	local defaultColorSet = playerCivilizationInfo and GameInfoPlayerColors[ playerCivilizationInfo.DefaultPlayerColor ]
	return Cache( not defaultColorSet or playerCivilizationInfo.Type == "CIVILIZATION_MINOR" or defaultColorSet.ID ~= GetCivilizationColor( playerID ), table, playerID )
end})

PrimaryColors = setmetatable( {}, { __index = function( table, playerID )
	return Cache( GetPlayerColor( playerID, 1 ), table, playerID )
end}) local PrimaryColors = PrimaryColors

BackgroundColors = setmetatable( {}, { __index = function( table, playerID )
	return Cache( GetPlayerColor( playerID, 0 ), table, playerID )
end}) local BackgroundColors = BackgroundColors

--==========================================================
-- AddSerialEventGameMessagePopup is a more efficient EUI
-- substitute for Events.SerialEventGameMessagePopup.Add
--==========================================================
function AddSerialEventGameMessagePopup( handler, ... )
	for _, popupType in pairs{...} do
		LuaEvents[popupType].Add( handler )
	end
	LuaEvents.AddSerialEventGameMessagePopup( ... )
end

--==========================================================
function IconLookup( index, size, atlas )
	local entry = (index or -1) >= 0 and IconTextureAtlasCache[ atlas ][ size ]
	if entry then
		local filename = entry[1]
		local numRows = entry[3]
		local numCols = entry[2]
		if filename and index < numRows * numCols then
			return { x=(index % numCols) * size, y = floor(index / numCols) * size }, filename
		end
	end
end
local IconLookup = IconLookup

--==========================================================
function IconHookup( index, size, atlas, control )
	local entry = control and (index or -1) >= 0 and IconTextureAtlasCache[ atlas ][ size ]
	if entry then
		local filename = entry[1]
		local numRows = entry[3]
		local numCols = entry[2]
		if filename and index < numRows * numCols then
			control:SetTextureOffsetVal( (index % numCols) * size, floor(index / numCols) * size )
			control:SetTexture( filename )
			return true
		end
		print( "Could not hookup icon index:", index, "from atlas:", filename, "numRows:", numRows, "numCols:", numCols, "to control:", control, control:GetID() )
	end
	print( "Could not hookup icon index:", index, "size:", size, "atlas:", atlas, "to control:", control, control and control:GetID() )
end
local IconHookup = IconHookup

--==========================================================
-- This is a special case hookup for civilization icons
-- that will take into account the fact that player colors
-- are dynamically handed out
--==========================================================
local downSizes = { [80] = 64, [64] = 48, [57] = 45, [45] = 32, [32] = 24 }
local textureOffsets = IsCiv5 and { [64] = 141, [48] = 77, [32] = 32, [24] = 0 } or { [64] = 200, [48] = 137, [45] = 80, [32] = 32, [24] = 0 }
local unmetCiv = { PortraitIndex = IsCiv5 and 23 or 24, IconAtlas = "CIV_COLOR_ATLAS", AlphaIconAtlas = IsCiv5 and "CIV_COLOR_ATLAS" or "CIV_ALPHA_ATLAS" }
function CivIconHookup( playerID, size, iconControl, backgroundControl, shadowIconControl, alwaysUseComposite, shadowedWhoCares, highlightControl )
-- eg backgroundControl 32, shadowIconControl 24, iconControl 24, highlightControl 32
	local playerCivilizationInfo = PlayerCivilizationInfo[ playerID ]
	if playerCivilizationInfo then
		if alwaysUseComposite or IsPlayerUsingCustomColor[ playerID ] or not playerCivilizationInfo.IconAtlas then
			-- use the ugly composite version
			size = downSizes[ size ] or size

			if backgroundControl then
				backgroundControl:SetTexture( "CivIconBGSizes.dds" )
				backgroundControl:SetTextureOffsetVal( textureOffsets[ size ] or 0, 0 )
				backgroundControl:SetColor( BackgroundColors[ playerID ] )
			end

			if highlightControl then
				highlightControl:SetTexture( "CivIconBGSizes_Highlight.dds" )
				highlightControl:SetTextureOffsetVal( textureOffsets[ size ] or 0, 0 )
				highlightControl:SetColor( PrimaryColors[ playerID ] )
				highlightControl:SetHide( false )
			end

			local textureOffset, textureAtlas = IconLookup( playerCivilizationInfo.PortraitIndex, size, playerCivilizationInfo.AlphaIconAtlas )

			if iconControl then
				if textureAtlas then
					iconControl:SetTexture( textureAtlas )
					iconControl:SetTextureOffset( textureOffset )
					iconControl:SetColor( PrimaryColors[ playerID ] )
					iconControl:SetHide( false )
				else
					iconControl:SetHide( true )
				end
			end

			if shadowIconControl then
				if textureAtlas then
					shadowIconControl:SetTexture( textureAtlas )
					shadowIconControl:SetTextureOffset( textureOffset )
					return shadowIconControl:SetHide( false )
				else
					return shadowIconControl:SetHide( true )
				end
			end
			return
		end
	else
		playerCivilizationInfo = unmetCiv
	end
	-- use the one-piece pretty color version
	if iconControl then
		iconControl:SetHide( true )
	end
	if shadowIconControl then
		shadowIconControl:SetHide( true )
	end
	if highlightControl then
		highlightControl:SetHide( true )
	end
	if backgroundControl then
		backgroundControl:SetColor( ColorWhite )
		return IconHookup( playerCivilizationInfo.PortraitIndex, size, playerCivilizationInfo.IconAtlas, backgroundControl )
	end
end

--==========================================================
-- This is a special case hookup for civilization icons
-- that always uses the one-piece pretty color version
--==========================================================
function SimpleCivIconHookup( playerID, size, control )
	local playerCivilizationInfo = PlayerCivilizationInfo[ playerID ] or unmetCiv
	return IconHookup( playerCivilizationInfo.PortraitIndex, size, playerCivilizationInfo.IconAtlas, control )
end
