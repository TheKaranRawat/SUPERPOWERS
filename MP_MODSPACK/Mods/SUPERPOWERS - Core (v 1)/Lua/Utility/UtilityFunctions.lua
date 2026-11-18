-- UtilityFunctions (optimized for performance + multiplayer determinism)
-- Original author: linco
--
-- MP RULES THIS FILE FOLLOWS (keep following them in callers):
--   * No Game.GetActivePlayer(), math.random, os.clock/os.time, or UI-only state in gameplay logic.
--   * Iterate players with an explicit numeric loop (fixed order on every client).
--   * Cache only DB-derived data (identical on all clients). Never cache game state
--     (humans, wars, happiness...) across calls: players can drop / be replaced by AI mid-game.

local DEBUG = false -- set true only for local testing; print() is slow (file I/O) and the
                    -- string concatenation in its arguments is evaluated even if you ignore it.

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS

------------------------------------------------------------------------------
-- Cached DB ids (looked up once at load instead of on every call)
------------------------------------------------------------------------------
local RES_CONSUMER        = GameInfoTypes["RESOURCE_CONSUMER"]
local RES_ELECTRICITY     = GameInfoTypes["RESOURCE_ELECTRICITY"]
local ERA_MODERN          = GameInfoTypes["ERA_MODERN"]

local POLICY_IRON_CURTAIN = GameInfoTypes["POLICY_IRON_CURTAIN"]
local POLICY_TREATY_ORG   = GameInfoTypes["POLICY_TREATY_ORGANIZATION"]
local POLICY_DICTATORSHIP = GameInfoTypes["POLICY_DICTATORSHIP_PROLETARIAT"]
local POLICY_REPRESENTATION = GameInfoTypes["POLICY_REPRESENTATION"]
local POLICY_POLICE_STATE = GameInfoTypes["POLICY_POLICE_STATE"]

local CIV_POLYNESIA = GameInfoTypes["CIVILIZATION_POLYNESIA"]
local CIV_ENGLAND   = GameInfoTypes["CIVILIZATION_ENGLAND"]
local CIV_VENICE    = GameInfoTypes["CIVILIZATION_VENICE"]
local CIV_PERSIA    = GameInfoTypes["CIVILIZATION_PERSIA"]

local FEATURE_FOREST = FeatureTypes.FEATURE_FOREST
local FEATURE_MARSH  = FeatureTypes.FEATURE_MARSH
local FEATURE_JUNGLE = FeatureTypes.FEATURE_JUNGLE

local RES_NUTMEG, RES_CLOVES, RES_PEPPER =
	GameInfoTypes.RESOURCE_NUTMEG, GameInfoTypes.RESOURCE_CLOVES, GameInfoTypes.RESOURCE_PEPPER

------------------------------------------------------------------------------
-- Players
------------------------------------------------------------------------------

-- DEPRECATE [COMBAT]
function PlayersAtWar(iPlayer, ePlayer)
	return Teams[iPlayer:GetTeam()]:IsAtWar(ePlayer:GetTeam())
end

-- DEPRECATE [COMBAT]
-- BEHAVIOUR CHANGE: the old version only looked at the FIRST human found and returned
-- immediately. In MP that made the result depend on slot order. Now true if at war with ANY human.
function PlayerAtWarWithHuman(player)
	local team = Teams[player:GetTeam()]
	for i = 0, MAX_MAJOR - 1 do
		local human = Players[i]
		if human ~= nil and human:IsHuman() and human:IsAlive() and team:IsAtWar(human:GetTeam()) then
			return true
		end
	end
	return false
end

function AICanBeBoss(player)
	-- cheapest checks first, and world totals only if we actually need them
	if player:IsHuman() or player:IsBarbarian() or player:IsMinorCiv() then
		return false -- (old code returned nil for minors)
	end

	local cities = player:GetNumCities()
	if cities <= 1 then return false end
	local pop = player:GetTotalPopulation()
	if pop <= 1 then return false end
	local tourism = player:GetTourism()
	if tourism <= 1 then return false end

	if cities >= 16 or tourism > 600 then return true end
	if cities >= Game.GetNumCities() / 10 or pop >= Game.GetTotalPopulation() / 10 then
		return true
	end
	return false
end

------------------------------------------------------------------------------
-- Plots
------------------------------------------------------------------------------

-- DEPRECATE [COMBAT]
-- BEHAVIOUR CHANGE: true if ANY human's team can see the plot (old code: first human only).
function PlotIsVisibleToHuman(plot)
	for i = 0, MAX_MAJOR - 1 do
		local human = Players[i]
		if human ~= nil and human:IsHuman() and human:IsAlive() and plot:IsVisible(human:GetTeam()) then
			return true
		end
	end
	return false
end

-- DEPRECATE [NO USE DETECTED]
function isFriendlyCity(pUnit, pCity)
	return pCity:GetTeam() == pUnit:GetTeam()
		and not pCity:IsResistance()
		and not pCity:IsRazing()
		and not (pCity:IsOccupied() and not pCity:IsNoOccupiedUnhappiness())
end

------------------------------------------------------------------------------
-- Units (results come from the static DB, so they are safe to memoize)
------------------------------------------------------------------------------
local civUnitCache = {} -- [civType][unitClass] = unitType or false

function GetCivSpecificUnit(player, sUnitClass)
	local civID = player:GetCivilizationType()
	local byClass = civUnitCache[civID]
	if byClass == nil then
		byClass = {}
		civUnitCache[civID] = byClass
	end

	local cached = byClass[sUnitClass]
	if cached ~= nil then
		return cached or nil
	end

	local sCivType = GameInfo.Civilizations[civID].Type
	local sUnitType = nil
	for row in GameInfo.Civilization_UnitClassOverrides{ CivilizationType = sCivType, UnitClassType = sUnitClass } do
		sUnitType = row.UnitType
		break
	end
	if sUnitType == nil then
		local class = GameInfo.UnitClasses[sUnitClass]
		sUnitType = class and class.DefaultUnit or nil
	end

	byClass[sUnitClass] = sUnitType or false
	return sUnitType
end

function GetUpgradeUnit(player, sUnitType)
	local info = GameInfo.Units[sUnitType]
	if info == nil or info.GoodyHutUpgradeUnitClass == nil then return nil end

	local sUpgrade = GetCivSpecificUnit(player, info.GoodyHutUpgradeUnitClass)
	if sUpgrade == nil then return nil end

	local prereq = GameInfo.Units[sUpgrade].PrereqTech
	if prereq == nil or Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[prereq]) then
		return sUpgrade
	end
	return nil
end

------------------------------------------------------------------------------
-- International immigration
-- Returns a number (0 where the old code returned nil on bad input).
------------------------------------------------------------------------------
--[[ DISABLE IMMIGRATION
function CheckMoveOutCounter(MoveOutPlayerID, MoveInPlayerID)
	local outP, inP = Players[MoveOutPlayerID], Players[MoveInPlayerID]
	if outP == nil or inP == nil then return 0 end

	-- Early exits before doing any of the expensive modifier work
	local base = inP:GetInfluenceLevel(MoveOutPlayerID)
	if base <= 0 then return 0 end

	local inHappy = inP:GetExcessHappiness()
	if inHappy <= 0 or inP:GetNumResourceAvailable(RES_CONSUMER, true) <= 0 then return 0 end
	if inP:GetCurrentEra() >= ERA_MODERN and inP:GetNumResourceAvailable(RES_ELECTRICITY, true) <= 0 then return 0 end
	if PlayersAtWar(outP, inP) then return 0 end

	local mod = 1

	-- Diplomacy
	if Teams[inP:GetTeam()]:IsAllowsOpenBordersToTeam(outP:GetTeam()) then mod = mod + 1 end
	if outP:IsDenouncedPlayer(MoveInPlayerID) or inP:IsDenouncedPlayer(MoveOutPlayerID) then mod = mod - 0.5 end
	if outP:IsDoF(MoveInPlayerID) then mod = mod + 0.5 end

	-- Religion
	local inReligion = inP:GetReligionCreatedByPlayer()
	if inReligion ~= nil and inReligion > 0 and outP:HasReligionInMostCities(inReligion) then
		mod = mod + 1
	end

	-- Happiness (human only)
	if inP:IsHuman() then
		if inHappy > 150 then mod = mod + 0.5
		elseif inHappy > 100 then mod = mod + 0.25
		elseif inHappy <= 20 then mod = mod - 0.5
		elseif inHappy <= 50 then mod = mod - 0.25
		end
	end

	if outP:IsHuman() then
		local outHappy = outP:GetExcessHappiness()
		-- FIX (please verify intent): the old code tested MoveInPlayer's happiness in the
		-- middle branches of this move-OUT block (copy/paste slip). Now uses outP throughout.
		if outHappy >= 150 then mod = mod - 0.5
		elseif outHappy > 100 then mod = mod - 0.25
		elseif outHappy <= 0 then mod = mod + 0.5
		elseif outHappy <= 20 then mod = mod + 0.25
		end
	end

	-- Ideology
	if outP:HasPolicy(POLICY_IRON_CURTAIN) then mod = mod - 0.5 end
	if inP:HasPolicy(POLICY_TREATY_ORG) then mod = mod + 0.5 end

	if mod < 0 then mod = 0 end
	local result = mod * base
	if DEBUG then print("MoveoutCounterFinal: " .. result) end
	return result
end
]]--
------------------------------------------------------------------------------
-- City level by distance from capital
------------------------------------------------------------------------------
------------Set City Level by Distance (used in city founding or else)

function SetCityLevelbyDistance (player,city)

	
	local WorldSizeLength = Map.GetGridSize()
	local policyID = GameInfo.Policies["POLICY_DICTATORSHIP_PROLETARIAT"].ID
		
	local DistanceLV1 = 7
	print ("DistanceLV1:"..DistanceLV1)
	
	local DistanceLV2 = WorldSizeLength / 8	
	if DistanceLV2 > 18 then
		DistanceLV2 = 18
	elseif DistanceLV2 < 14 then
	   DistanceLV2 = 14
	end
	print ("DistanceLV2:"..DistanceLV2)
	
	
	local DistanceLV3 = WorldSizeLength / 5 	
	if DistanceLV3 > 30 then
	   DistanceLV3 = 30
	elseif DistanceLV3 < 26 then
	   DistanceLV3 = 26
	end
	print ("DistanceLV3:"..DistanceLV3)	 
	       
	local DistanceLV4 = WorldSizeLength / 3 	
	if DistanceLV4 > 44 then
	   DistanceLV4 = 44
	elseif DistanceLV4 < 36 then
	   DistanceLV4 = 36
	end
	print ("DistanceLV4:"..DistanceLV4)


	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_POLYNESIA"] then	
		print ("No Lv 4-5 cities!")
		DistanceLV3 = 999
		DistanceLV4 = 999
	elseif player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ENGLAND"] then
		print ("Lv1 up for all cities!")
		DistanceLV1 = DistanceLV2
		DistanceLV2 = DistanceLV3
		DistanceLV3 = DistanceLV4
		DistanceLV4 = 999
	elseif player:HasPolicy(policyID) then
		print ("Lv1 up for all cities! - Policy Effect!")
		DistanceLV1 = DistanceLV2
		DistanceLV2 = DistanceLV3
		DistanceLV3 = DistanceLV4
		DistanceLV4 = 999
	end
	

	
	
	if player:GetNumCities() > 0 then
		local pCity = player:GetCapitalCity()    
		local CapitalPlot = pCity:Plot() 
		local CapX = CapitalPlot:GetX()
		local CapY = CapitalPlot:GetY()
		
		local policyID = GameInfo.Policies["POLICY_REPRESENTATION"].ID
		local policyBonusID = GameInfo.Policies["POLICY_POLICE_STATE"].ID
		
		
		if city:IsCapital() then
			print ("Capital City!")
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)	
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 	
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 

	
		
		elseif city:IsPuppet() then
		
			if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_VENICE"] then
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],1)	--puppet city has a local government with no Penalties (Venice)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
--					city:SetFocusType(3)
				print("Special Puppet City with no Penalties!")
			else
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],1)	--puppet city has a local government
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			end
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 	
			
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
		
			if not city:IsResistance() then
				if city:GetOrderQueueLength() <= 0 or city:GetProduction()== 0 then
					city:PushOrder (OrderTypes.ORDER_MAINTAIN, 0, -1, 0, false, false)
					print("Puppet City doing nothing! Let it produce Gold!")
				end
			end
			
			print("Puppet City!")
			
		else
			print("Annexed City, City Hall is built!")			
			local plot = city:Plot() 
			local Distance = Map.PlotDistance (plot:GetX(),plot:GetY(),CapX,CapY)
			
			print ("City's Distance from Capital:"..Distance)
			
			if player:HasPolicy(policyID) then
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"],1)	
			    	print ("Player has the Representation policy!")
			else
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_REPRESENTATION_CULTURE"],0)	  
			end
	
			
			
			if Distance <= DistanceLV1 and Distance > 1 then
		
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],1)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
				    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
					
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
					
					if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_PERSIA"] then
				   		city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
				   		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATRAPS_COURT"],1)					
						print ("Persia! Achaemenid Legacy!")
					end	
					print("City lv1")
					
					
			
			elseif Distance > DistanceLV1 and Distance <= DistanceLV2  then	
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],1)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],1) 
					print ("Police State!")
				end
				
				print("City lv2")
				
				
				
			elseif Distance > DistanceLV2 and Distance <= DistanceLV3 then	

				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],1)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],1) 
					print ("Police State!")
				end
				
				print("City lv3")
				
				
				
			elseif Distance > DistanceLV3 and Distance <= DistanceLV4 then	
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],1)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 
				
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],1) 
					print ("Police State!")
				end
				print("City lv4")	
				
				
				
			elseif Distance > DistanceLV4 then	
			
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
			    city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],1)					
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
				
				
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
				city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0) 
				
				if player:HasPolicy(policyBonusID) then
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],1) 
					print ("Police State!")
				end
				print("City lv5")	
					
			end
			
			
			if plot:GetResourceType() == GameInfoTypes.RESOURCE_NUTMEG or plot:GetResourceType() == GameInfoTypes.RESOURCE_CLOVES or plot:GetResourceType() == GameInfoTypes.RESOURCE_PEPPER then
   				 	if player == Players[city:GetOriginalOwner()]  then

			    	print ("Indonesian first 3 cities free from corruption!")
			    	
			    	city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV1"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV2"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV3"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV4"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CITY_HALL_LV5"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT"],0)	
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PUPPET_GOVERNEMENT_FULL"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_CONSTABLE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_ROMAN_SENATE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_SHERIFF_OFFICE"],0)
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATION"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_PROCURATORATE"],0) 	
					
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV2"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV3"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV4"],0) 
					city:SetNumRealBuilding(GameInfoTypes["BUILDING_POLICE_STATE_LV5"],0)
				end
			end
				
				
				
		
			
		end

	end


	
	
	
end-------------Function End

------------------------------------------------------------------------------
-- Misc
------------------------------------------------------------------------------
function RemoveConflictFeatures(plot)
	if plot == nil then return end
	local feature = plot:GetFeatureType()
	if feature == FEATURE_FOREST or feature == FEATURE_MARSH or feature == FEATURE_JUNGLE then
		plot:SetFeatureType(-1)
	end
end

print("UtilityFunctions Check Pass!")