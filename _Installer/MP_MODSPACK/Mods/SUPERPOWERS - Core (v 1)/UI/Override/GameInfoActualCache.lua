
--==========================================================
-- Written by bc1 using Notepad++
--==========================================================

local collectgarbage = collectgarbage
local pairs = pairs
local next = next
local print = print
local setmetatable = setmetatable
--local tonumber = tonumber
local type = type
local insert = table.insert
local sort = table.sort

local ContentManager_IsActive = ContentManager.IsActive
local ContentType_GAMEPLAY = ContentType.GAMEPLAY
local DataBaseQuery = DB.Query
local CreateQuery = DB.CreateQuery
local GameInfo = GameInfo
local Game = Game
local L = Locale.ConvertTextKey

print( "Loading EUI cache manager; IsPregame:", not Game, "Context:", ContextPtr:LookUpControl(".."):GetID(), ContextPtr:GetID() )

local function sortByName(a,b) return a._Name < b._Name end
local sortFunctions = {
	Buildings = sortByName,
	Projects = sortByName,
	Processes = sortByName,
	Units = sortByName,
	UnitClasses = false,
	UnitPromotions = sortByName,
	Promotions = sortByName,
	Domains = false,
	UnitCombatInfos = false,
	HurryInfos = false,
	UnitUpgrades = false, -- CivBE
	Affinity_Types = false, -- CivBE
	Specialists = sortByName,
	Civilizations = sortByName,
	Beliefs = sortByName,
	Technologies = false,
	Eras = false,
	Policies = false,
	PolicyBranchTypes = false,
	Yields = false,
	Terrains = false,
	Features = sortByName,
	Resources = sortByName,
	Improvements = sortByName,
	Builds = sortByName,
	Routes = false,
	GreatWorks = false,
	Victories = false,
}
local g_MissingTextures = { RESOURCE_JEWELRY = "SV_Jewelry.dds", RESOURCE_PORCELAIN = "SV_Porcelain.dds" }
--local recordTypes = { null=type(nil), integer=type(0),  int=type(0), float=type(0.1), boolean=type(true), text=type"" }

local function doNothing() end
local emptyInfoCache = setmetatable( {}, { __call = function() return doNothing end,  __newindex = doNothing } )

GameInfoCache = setmetatable( {}, { __index = function( GameInfoCache, tableName )
	local GameInfoData, cache
-- [[ pre-game:
	local keys = {}
--print( "Caching GameInfo table", tableName )
	for row in DataBaseQuery( "PRAGMA table_info("..tableName..")" ) do
		-- cid	name	type	notnull	dflt_value	pk
		-- EUI assumes keys are strings, so only handle those (integer keys will break havok)
		keys[ row.name ] = type(row.name)=="string" and row.name or nil
--print( row.cid, row.name, row.type, row.notnull, row.dflt_value, row.pk )
	end
	if next( keys ) then
		if Game then
--print( "Accessing GameInfo."..tableName )
			GameInfoData = GameInfo[ tableName ]
		else
--print( "Accessing data base table", tableName )
			local QueryAll = CreateQuery( "SELECT * from "..tableName )
			local QueryID = keys.ID and CreateQuery( "SELECT * from "..tableName.." WHERE ID = ?" )
			local QueryType = keys.Type and CreateQuery( "SELECT * from "..tableName.." WHERE Type = ?" )
			GameInfoData = setmetatable( {}, {	__call = function()
														return QueryAll()
												end,
												__index = function( t, key )
													if QueryID and tonumber(key) then
														return QueryID( key )()
													elseif QueryType and key then
														return QueryType( key )()
													end
												end, } )
		end
-- ID = key or Type = key...
--]]
--[[
Each cache table is created by GameInfoCache metatable __index function:
- master set row array is populated from game info, and with setMT metatable to populate master set akeys
When a master set akey is queried, setMT( set, key ) handles creation of akey structure:
- an index of all possible akey values found in row array, with each value having a sub-set structure
- each subset row array is populated, and with setMT metatable to populate subset akeys

{ [#]row-{ [akey]-valu }
{ [akey]-{ [valu]-{ [#]row-{ [akey]-valu }
                  { [akey]-{ [valu] ...
^set     ^index   ^set     ^index   ...
--]]
		local setMT
		setMT = { __index = function( set, key )
			if keys[ key ] then -- verify key name exists and is a string
--print( "Creating index for key", key )
				local index = {}
				local subset, r, v
				for i = 1, #set do -- iterate over set row array
					r = set[ i ]
					v = r[ key ]
					if v ~= nil then -- does row have a defined value for this akey ?
						subset = index[ v ] -- get subset corresponding to this akey value
						if not subset then -- create subset if none already exists
							subset = setmetatable( {}, setMT ) -- setMT will populate subset akeys
							index[ v ] = subset -- assign subset to index akey value
						end
						insert( subset, r ) -- add row to subset row array
					end
				end
				if subset then -- have we created at least one subset ?
					set[ key ] = index -- assign index to set akey
					return index
				else
					set[ key ] = false -- prevent setMT from being called again
				end
			end
		end }
		local masterset = setmetatable( {}, setMT )
		local function cacheCall( cache, condition )
			local set = masterset
			if condition then
				-- Warning: EUI's GameInfoCache iterator only supports table conditions
				for key, value in pairs( condition ) do
					set = (set[ key ] or emptyInfoCache)[ value ] -- can trigger setMT.__index for set and/or for set[ key ][ value ]
					if not set then
						return doNothing -- no iterations
					end
				end
			end
			local i = 0
			return function() -- iterator
				i = i+1
				return set[ i ]
			end
		end
		local r
		local primaryKey = keys.ID or keys.Type
		local uniqueKey = keys.Type or keys.ID
		if primaryKey then
			local name = keys.ShortDescription or keys.Description
			local _Name = name and "_Name" or keys -- anything that's impossible to equate
			local _Texture = keys.ArtDefineTag and "_Texture" or keys -- anything that's impossible to equate
			local rowMT = { __index = function( r, key )
				local v
				if keys[key] then
					v = GameInfoData[r[primaryKey]][key]
				elseif key==_Name then
					v = L( r[name] or "???" )
				elseif key==_Texture then
					-- cache texture name
					v = g_MissingTextures[r.Type]
					if not v and r.ArtDefineTag then
						v = GameInfo.ArtDefine_StrategicView{ StrategicViewType = r.ArtDefineTag }()
						v = v and v.Asset
					end
				end
				r[key] = v
				return v
			end }
			cache = setmetatable( {}, {
				__index = function( cache, key )
					if key then
						local row = GameInfoData[ key ]
						if row then
							r = setmetatable( { [primaryKey] = row[primaryKey], [uniqueKey] = row[uniqueKey] }, rowMT )
							cache[ r[primaryKey] ] = r
							cache[ r[uniqueKey] ] = r
							return r
						else
							cache[ key ] = false
						end
					end
				end,
				__call = function(...)
					for row in GameInfoData() do
						r = cache[ row[primaryKey] ]
						-- populate master set
						insert( masterset, r )
					end
					setmetatable( cache, { __call = cacheCall } )
					local sortFunction = sortFunctions[tableName]
					if name and sortFunction then
--print( "sorting master set for", tableName )
						sort( masterset, sortFunction )
					end
					return cacheCall(...)
				end } )
		else
			for row in GameInfoData() do
				-- make local row copy
				r = {}
				for k, v in pairs( row ) do
					r[ k ] = v
				end
				-- populate master set
				insert( masterset, r )
			end
			cache = setmetatable( {}, { __call = cacheCall } )
		end
--cache.__ = masterset
--print( "master set includes", #masterset, "items" )
	else
		print( tableName, "GameInfo table is undefined for this game version and/or mods" )
		cache = emptyInfoCache
	end
	GameInfoCache[ tableName ] = cache
	if tableName == "UnitPromotions" then
		-- Patch promotion icons
		local isBlandPromotion = { [57]="ABILITY_ATLAS", [58]="ABILITY_ATLAS", [59]="ABILITY_ATLAS" } -- specifies "generic" icons
		for promotion, promotionInfo in pairs{
			PROMOTION_IGNORE_TERRAIN_COST = cache.PROMOTION_MOBILITY,
			PROMOTION_FASTER_HEAL = cache.PROMOTION_INSTA_HEAL,
			PROMOTION_SECOND_ATTACK = cache.PROMOTION_LOGISTICS,
			PROMOTION_MORALE = cache.PROMOTION_GOLDEN_AGE_POINTS,
			PROMOTION_EXTRA_SIGHT_I = cache.PROMOTION_SCOUTING_1,
			PROMOTION_EXTRA_SIGHT_II = cache.PROMOTION_SCOUTING_2,
			PROMOTION_EXTRA_SIGHT_III = cache.PROMOTION_SCOUTING_3,
			PROMOTION_EXTRA_SIGHT_IV = cache.PROMOTION_SENTRY,
			PROMOTION_INVISIBLE_SUBMARINE = cache.PROMOTION_SENTRY,
			PROMOTION_SENTRY = cache.PROMOTION_SCOUTING_1,
			PROMOTION_ADJACENT_BONUS = cache.PROMOTION_HOMELAND_GUARDIAN,
			PROMOTION_HIMEJI_CASTLE = cache.PROMOTION_HOMELAND_GUARDIAN,
			PROMOTION_SIEGE = cache.PROMOTION_VOLLEY,
			PROMOTION_STATUE_ZEUS = cache.PROMOTION_AIR_SIEGE_1,
			PROMOTION_GREAT_GENERAL = cache.PROMOTION_HEROISM,
			PROMOTION_SPAWN_GENERALS_I = cache.PROMOTION_HEROISM,
			PROMOTION_SPAWN_GENERALS_II = cache.PROMOTION_HEROISM,
			PROMOTION_GREAT_ADMIRAL = cache.PROMOTION_HEROISM,
			PROMOTION_FAST_GENERAL = cache.PROMOTION_MOBILITY,
			PROMOTION_FAST_ADMIRAL = cache.PROMOTION_MOBILITY,
			PROMOTION_EXTRA_MOVES_I = cache.PROMOTION_MOBILITY,
			PROMOTION_AIR_RECON = cache.PROMOTION_SORTIE,
			PROMOTION_AIR_SWEEP = cache.PROMOTION_SORTIE,
			PROMOTION_ANTI_AIR = cache.PROMOTION_SORTIE,
			PROMOTION_ANTI_AIR_II = cache.PROMOTION_SORTIE,
			PROMOTION_ANTI_HELICOPTER = cache.PROMOTION_SORTIE,
			PROMOTION_ANTI_FIGHTER = cache.PROMOTION_SORTIE,
			PROMOTION_ANTI_SUBMARINE_I = cache.PROMOTION_WOLFPACK_1,
			PROMOTION_ANTI_SUBMARINE_II = cache.PROMOTION_WOLFPACK_2,
			PROMOTION_ANTI_TANK = cache.PROMOTION_AMBUSH_1,
			PROMOTION_ANTI_MOUNTED_I = cache.PROMOTION_FORMATION_1,
			PROMOTION_ANTI_MOUNTED_II = cache.PROMOTION_FORMATION_2,
		} do
			promotion = cache[ promotion ]
			if promotionInfo and promotion and isBlandPromotion[ promotion.PortraitIndex ] == promotion.IconAtlas then
				promotion.PortraitIndex = promotionInfo.PortraitIndex
				promotion.IconAtlas = promotionInfo.IconAtlas
			end
		end
	elseif tableName == "Yields" then
		-- Patch yield icons
		local i
		for y in cache() do
			i = y.ID
			if not y.IconString then y.IconString = "?" end
		end
		if InStrategicView and not( ContentManager_IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType_GAMEPLAY) or ContentManager_IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType_GAMEPLAY) ) then
			local y = { ID=i+1, Type="YIELD_CULTURE", Description="TXT_KEY_TRADE_CULTURE", _Name=L"TXT_KEY_TRADE_CULTURE", IconString="[ICON_CULTURE]", ImageTexture="YieldAtlas_128_Culture.dds", ImageOffset=0,
						HillsChange=0, MountainChange=0, LakeChange=0, CityChange=0, PopulationChangeOffset=0, PopulationChangeDivisor=0, MinCity=0, GoldenAgeYield=0, GoldenAgeYieldThreshold=0, GoldenAgeYieldMod=0, AIWeightPercent=0 }
			GameInfoCache.Yields[y.Type] = y
			GameInfoCache.Yields[y.ID] = y
		end
	end
	return cache
end } )
