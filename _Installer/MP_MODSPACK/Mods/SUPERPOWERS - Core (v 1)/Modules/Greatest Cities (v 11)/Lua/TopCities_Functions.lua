-- TopCities_Functions
-- Author: FramedArchitecture
-- DateCreated: 8/1/2014
--------------------------------------------------------------------
include("Serializer.lua")
--------------------------------------------------------------------
MapModData.g_Properties	= MapModData.g_Properties or {}
g_Properties			= MapModData.g_Properties;
--------------------------------------------------------------------
bDisablePrint		= false
g_MaxEntries		= 10;	--the number of entries reported in UI
g_MaxScore			= 10;	--the highest score possible in any discretionary category
g_IsGnK				= ContentManager.IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType.GAMEPLAY);
g_IsBNW				= ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY);
g_IsPlagueMod		= GameInfo.Yields["YIELD_HEALTH"] and true or false 
--------------------------------------------------------------------
local insert		= table.insert
local remove		= table.remove
local sort			= table.sort
local smaller		= math.min
local random		= math.random
local maxEntries	= g_MaxEntries
local maxScore		= g_MaxScore
local bExpansion	= g_IsGnK or g_IsBNW
local bScience		= not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE);
local bCulture		= not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES);
local bFaith		= not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION);
local bHappy		= not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS);
local bHealth		= g_IsBNW and g_IsPlagueMod;
local wonderKey		= bExpansion and "HOLYCITY" or "WONDERS"
local saveData		= Modding.OpenSaveData();
local print			= bDisablePrint and function() end or print
--------------------------------------------------------------------
local yieldType;
local GetHolyCityCount = function(x) return (bExpansion and x:IsHolyCityAnyReligion()) and 2 or 0 end
local GetWonderCount = function(x) return x:GetNumWorldWonders() + GetHolyCityCount(x) end
local GetPopulation = function(x) return x:GetRealPopulation() end
local GetYieldRate = function(x) return x:GetYieldRateTimes100(yieldType) end
local GetCulture = function(x) return x:GetJONSCulturePerTurn() end
local GetHappiness = function(x) return not x:IsResistance() and x:GetLocalHappiness() or 0 end
local GetFaith = function(x) return x:GetFaithPerTurn() end
local GetTourism = function(x) return x:GetBaseTourism() end
local GetHealth = function(x) 
	local t = g_Properties.gCityHealthList or {}
	local name = x:GetName()
	local n = #t
	for i = 1, n do
		local v = t[i]
		if (v.city:GetName() == name) then
			return v.health
		end
	end
	return 0
end
--------------------------------------------------------------------
function GetCitiesByScore()
	local sortList = {}
	
	for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
		local player = Players[i]
		if player and player:IsAlive() then
			for city in player:Cities() do
				insert(sortList, { city=city, score=0, details={} });
			end
		end
	end
	
	local n = #sortList
	if n > 0 then 
		local scoreOptions = {
			[wonderKey]	= { func=GetWonderCount, run=true },
			["POP"]		= { func=GetPopulation, run=true },
			["PROD"]	= { func=GetYieldRate, type=YieldTypes.YIELD_PRODUCTION, run=true },
			["GOLD"]	= { func=GetYieldRate, type=YieldTypes.YIELD_GOLD, run=true },
			["SCIENCE"]	= { func=GetYieldRate, type=YieldTypes.YIELD_SCIENCE, run=bScience },
			["CULTURE"]	= { func=GetCulture, run=bCulture },
			["HAPPY"]	= { func=GetHappiness, run=(bExpansion and bHappy) },
			["FAITH"]	= { func=GetFaith, run=(bExpansion and bFaith) },
			["TOURISM"]	= { func=GetTourism, run=(g_IsBNW and bCulture) },
			["HEALTH"]	= { func=GetHealth, run=bHealth },
		}
		local UpdateScore = function(func, key)
			sort(sortList, function(x, y) return func(x.city) > func(y.city) end)
			local score = maxScore
			local p_value = 0
			for i = 1, n do
				if score > 0 then
					local entry = sortList[i]
					local c_value = func(entry.city)
					if c_value > 0 then
						if i > 1 then
							if c_value < p_value then
								score = score - 1
							end
						end
						p_value = c_value
						entry.details[key] = score
						entry.score = entry.score + score
					else
						break;
					end
				else
					break;
				end
			end
		end

		for key,v in pairs(scoreOptions) do
			if v.run then
				if v.type then yieldType=v.type end
				UpdateScore(v.func, key);
			end
		end
		
		sort(sortList, function(x, y) if (x.score == y.score) then return (x.city:GetName() < y.city:GetName()) else return (x.score > y.score) end end)
	end

	return sortList
end
--------------------------------------------------------------------
function DoGreatestCityWinner(eraID)
	local cities = GetCitiesByScore();
	local bestScore = cities[1].score
	if bestScore > 0 then
		local winners = 0
		for _,v in ipairs(cities) do
			if v.score == bestScore then
			    winners = winners + 1
			else
				break;
			end
        end

		local city = cities[random(winners)].city
		local x, y = city:GetX(), city:GetY()
		local t = GetHallOfFameCities()
		
		if city:IsHasBuilding(GameInfoTypes.BUILDING_TC_TRIUMPHARCH) then
			local bonus = 0
			for _,v in ipairs(t) do
				if (v.x == x) and (v.y == y) then
					bonus = bonus + 2
				end
			end
			print("DoGreatestCityWinner bonus", bonus)
			city:SetBuildingYieldChange(GameInfoTypes.BUILDINGCLASS_TC_TRIUMPHARCH, GameInfoTypes.YIELD_GOLD, bonus)
		end

		insert(t, {era=eraID, civ=city:GetCivilizationType(), name=city:GetNameKey(), pop=city:GetRealPopulation(), score=bestScore, x=x, y=y})
		sort(t, function(x, y) return x.era > y.era end)
		SaveHallOfFameCities(t)

		--Notification
		local strEra = GameInfo.Eras[eraID].Description
		local popupInfo = {Data1 = 500,Type = ButtonPopupTypes.BUTTONPOPUP_TEXT}
		if city:GetOwner() == Game.GetActivePlayer() then
			popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_TC_HOF_POPUP_WINNER", city:GetName(), strEra)
		else
			local civName = GameInfo.Civilizations[city:GetCivilizationType()].Adjective
			popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_TC_HOF_POPUP_LOSER", civName, city:GetName(), strEra)
		end
		UI.AddPopup(popupInfo)
	end
end
--------------------------------------------------------------------
function IsCurrentGreatestCity(city)
	local t = GetHallOfFameCities()
	if #t > 0 then
		local x, y = city:GetX(), city:GetY()
		return (t[1].x == x) and (t[1].y == y)
	end
	return false;
end
--------------------------------------------------------------------
function IsEverGreatestCity(city)
	local t = GetHallOfFameCities()
	if #t > 0 then
		local x, y = city:GetX(), city:GetY()
		for _,v in ipairs(t) do
			if (v.x == x) and (v.y == y) then
				return true;
			end
		end
	end
	return false;
end
--------------------------------------------------------------------
function TableReduce(t, n)
	local r = {}
	for i = 1, n do
		insert(r,t[i])
	end
	return r
end
--------------------------------------------------------------------
function CommaFormat(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end
--------------------------------------------------------------------
function SaveHallOfFameCities(t)
	SetPersistentTable("g_HoFCities", t);
end
--------------------------------------------------------------------
function GetHallOfFameCities()
	return GetPersistentTable("g_HoFCities");
end
--------------------------------------------------------------------
function SetCurrentEra(eraType)
	SetPersistentProperty("CurrentTopCitiesEra", eraType);
end
--------------------------------------------------------------------
function GetCurrentEra()
	return GetPersistentProperty("CurrentTopCitiesEra")
end
--------------------------------------------------------------------
function GetPersistentTable(name)
	if (g_Properties[name] == nil) then
		local code = saveData.GetValue(name);
		if code then
			g_Properties[name] = loadstring(code)();
		else
			g_Properties[name] = {}
		end
	end
	return g_Properties[name];
end
--------------------------------------------------------------------
function SetPersistentTable(name, t)
    saveData.SetValue(name, serialize(t))
	g_Properties[name] = t;
end
--------------------------------------------------------------------
function GetPersistentProperty(name)
	if (g_Properties[name] == nil) then
		g_Properties[name] = saveData.GetValue(name);
	end
	return g_Properties[name];
end
--------------------------------------------------------------------
function SetPersistentProperty(name, value)
	saveData.SetValue(name, value);
	g_Properties[name] = value;
end
--------------------------------------------------------------------