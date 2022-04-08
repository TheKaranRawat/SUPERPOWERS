-- Released under GPL v3
--------------------------------------------------------------
local yieldIcons = {}
for row in GameInfo.Yields() do
	yieldIcons[row.Type] = row.IconString
	if not row.IconString then
		print("Yield "..row.Type.." has no yield")
	end
end

function GetYieldIcon(yieldType)
	if yieldType == "YIELD_CULTURE" then return "[ICON_CULTURE]" end
	return yieldIcons[yieldType] or " <error>"
end

--===============================================================================================
-- Tooltip
--===============================================================================================
local function GetYieldAmount(value, suffix, showYieldMod)
	if value and value ~= 0 then
		local sign = (showYieldMod and value > 0) and "+" or "";
		return sign..value..suffix;
	else
		return "";
	end
end

-------------------------------------------------------------------------------------------------
function GetYieldString(item)
	local str = "";

	-- Straight yields : food, prod, gold, science, culture, happiness, defense
	if item.yields then
		for type, value in pairs(item.yields) do
			local yieldIcon = GetYieldIcon(type)
			str = str..GetYieldAmount(value, yieldIcon.." ", item.showYieldMod);
		end
	-- Terrains with multiples yields (coast/lake)
	elseif item.yieldGroups then
		local isFirstGroup = true
		for groupName, group in pairs(item.yieldGroups) do
			if not isFirstGroup then str = str.."[NEWLINE]" end
			isFirstGroup = false

			for type, value in pairs(group) do
				local yieldIcon = GetYieldIcon(type)
				str = str..GetYieldAmount(value, yieldIcon.." ", item.showYieldMod);
			end

			str = str.." ("..groupName..")"
		end
	end
	if item.happiness and item.happiness ~= 0 then
		str = str..GetYieldAmount(item.happiness, "[ICON_HAPPINESS_1] ", item.showYieldMod);
	end
	if item.defenseModifier and item.defenseModifier > 0 then
		str = str..GetYieldAmount(item.defenseModifier, "%[ICON_STRENGTH] ", item.showYieldMod);
	end

	-- No base yield but improving resources bring yield changes
	if str == "" and item.improvedResources and next(item.improvedResources) then
		local lookup = {};
		for _, improvedResource in pairs(item.improvedResources) do
			local key = improvedResource.yield..improvedResource.yieldType;
			if not lookup[key] then lookup[key] = {} end;
			table.insert(lookup[key], improvedResource);
		end

		for _, row in pairs(lookup) do
			local yield = 0;
			local yieldType = 0;
			local suffix = " on ";
			for _, improvedResource in pairs(row) do
				yield = improvedResource.yield;
				yieldType = improvedResource.yieldType;
				suffix = suffix..improvedResource.resource.iconString.." ";
			end

			if str ~= "" then 
				str = str.."[NEWLINE]";
			end
			local yieldIcon = GetYieldIcon(yieldType)
			str = str..GetYieldAmount(yield, yieldIcon..suffix, true);
		end
	end
	return str;
end

-------------------------------------------------------------------------------------------------
local yieldChangeColors = { BUILDING = "[COLOR_BUILDING_TEXT]", TECH = "[COLOR_TECH_TEXT]", IMPROVEMENT = "[COLOR_HIGHLIGHT_TEXT]" }
local yieldChangeTemplate = L("TXT_KEY_IGE_YIELD_CHANGE_TEMPLATE");
local noYieldChangeTemplate = L("TXT_KEY_IGE_NO_YIELD_CHANGE_TEMPLATE");

function GetYieldChangeString(item)
	local str = "";

	if item.yieldChanges then
		for i, v in ipairs(item.yieldChanges) do
			local suffix = nil;
			local value = nil;
			suffix = GetYieldIcon(v.yieldType)

			local sourceName = yieldChangeColors[v.type]..v.name.."[ENDCOLOR]"
			if v.suffix then
				sourceName = sourceName.." ("..v.suffix..")"
			end
			sourceName = sourceName.."[NEWLINE]";

			if suffix then
				local amount = GetYieldAmount(v.yield, suffix, true);
				str = str..L("TXT_KEY_IGE_YIELD_CHANGE_TEMPLATE", amount, sourceName);
			else
				str = str..L("TXT_KEY_IGE_NO_YIELD_CHANGE_TEMPLATE", sourceName);
			end
		end
	end

	return str;
end

--===============================================================================================
-- OTHERS
--===============================================================================================
function GetXPForLevel(level)
	if level == 1 then return 0 end
	if level == 2 then return 16 end

	local xp = 31;
	local offset = 30;
	local currentLevel = 3;
	while currentLevel < level do
		xp = xp + offset;
		offset = offset + 10;
		currentLevel = currentLevel + 1;
	end

	print(xp.." xp required for level "..level);
	return xp;
end

-------------------------------------------------------------------------------------------------
function GetLevelFromXP(xp)
	print("current xp = "..xp);
	if xp < 16 then return 1 end

	local offset = 30;
	local nextLevelXP = 31;
	local currentLevel = 2;
	while xp >= nextLevelXP do
		nextLevelXP = nextLevelXP + offset;
		currentLevel = currentLevel + 1;
		offset = offset + 10;
	end

	print("current level = "..currentLevel);
	return currentLevel;
end

-------------------------------------------------------------------------------------------------
function Neighbors(plot)
	local i = 0
	local x = plot:GetX()
	local y = plot:GetY()
	return function()
		while true do
			if i > 5 then return nil end
			local neighbor = Map.PlotDirection(x, y, i)
			i = i + 1
			if neighbor then return neighbor end
		end
	end
end

-------------------------------------------------------------------------------------------------
function GetSelection(items)
	for k, v in ipairs(items) do
		if v.selected then return v end
	end
end

-------------------------------------------------------------------------------------------------
function SelectAll(items)
	for k, v in ipairs(items) do
		v.selected = true;
	end
end

-------------------------------------------------------------------------------------------------
function UnselectAll(items)
	for k, v in ipairs(items) do
		v.selected = false;
	end
end

-------------------------------------------------------------------------------------------------
function GetTeamID(playerID)
	local pPlayer = Players[playerID];
	return pPlayer:GetTeam();
end

-------------------------------------------------------------------------------------------------
function GetTeam(playerID)
	local pPlayer = Players[playerID];
	local teamID = pPlayer:GetTeam();
	return Teams[teamID];
end

--===============================================================================================
-- SAVES
--===============================================================================================
local builtInFiles = { "IGE1", "IGE2", "IGE3" };

function LoadFile(fileName)
	print("Loading");
	local files = {};
	UI.SaveFileList(files, GameTypes.GAME_SINGLE_PLAYER, false, true);

	for _, path in ipairs(files) do
		local thisFileName = Path.GetFileNameWithoutExtension(path);
		if thisFileName == fileName then
			print("Loading "..path);
			Events.PlayerChoseToLoadGame(path);
			return path;
		end
	end
end

-------------------------------------------------------------------------------------------------
function DeleteFiles(fileName)
	if IGE then assert(IGE.cleanUpFiles) end

	print("Deleting");
	local files = {};
	UI.SaveFileList(files, GameTypes.GAME_SINGLE_PLAYER, false, true);

	for _, path in ipairs(files) do
		local otherName = Path.GetFileNameWithoutExtension(path);
		if Locale.ToUpper(otherName) == Locale.ToUpper(fileName) then
			print("Deleting "..otherName);
			print(path);
			UI.DeleteSavedGame(path);
		end
	end
end

-------------------------------------------------------------------------------------------------
function SaveFile(canCleanUpFile)
	if not UI.CompareFileTime then return end

	print("Get files list");
	local files = {};
	UI.SaveFileList(files, GameTypes.GAME_SINGLE_PLAYER, false, true);

	-- Get first free "n" for "IGEn"
	print("Get first free index");
	local fileIndex = 1;
	for _, path in ipairs(files) do
		local fileName = Path.GetFileNameWithoutExtension(path);
		for i, builtInName in ipairs(builtInFiles) do
			if Locale.ToUpper(builtInName) == Locale.ToUpper(fileName) then
				fileIndex = math.max(fileIndex, i + 1);
			end
		end
	end

	-- Get oldest "n" for "IGEn" if no free index
	print("Get oldest index");
	if fileIndex > 3 then
		local oldestDateLow = nil;
		local oldestDateHigh = nil;
		for _, path in ipairs(files) do
			local fileName = Path.GetFileNameWithoutExtension(path);
			for i, builtInName in ipairs(builtInFiles) do
				if Locale.ToUpper(builtInName) == Locale.ToUpper(fileName) then
					local high, low = UI.GetSavedGameModificationTimeRaw(path);
					if (oldestDateHigh == nil) or (1 == UI.CompareFileTime(oldestDateHigh, oldestDateLow, high, low)) then
						oldestDateHigh = high;
						oldestDateLow = low;
						fileIndex = i;
					end
				end
			end
		end
	end

	-- Pick the "IGEn" name to use
	local fileName = builtInFiles[fileIndex];
	if canCleanUpFile then
		DeleteFiles(fileName);
	end

	-- Save
	print("Saving");
	UI.SaveGame(fileName, true);
	LuaEvents.IGE_FloatingMessage(L("TXT_KEY_IGE_SAVED_AS", fileName));
	return fileName;
end