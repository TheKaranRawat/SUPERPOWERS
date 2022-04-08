-- Released under GPL v3
--------------------------------------------------------------
NoRotation = 0;
CWRotation = 1;
CCWRotation = -1;

RiverSides = { "E", "SE", "SW", "W", "NW", "NE" };

local sidesToIndices = { E = 0, SE = 1, SW = 2, W = 3, NW = 4, NE = 5 };
local verticesToIndices = { NE = 0, SE = 1, S = 2, SW = 3, NW = 4, N = 5 };

local indicesToFlows = {};
indicesToFlows[0] = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
indicesToFlows[1] = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
indicesToFlows[2] = FlowDirectionTypes.FLOWDIRECTION_SOUTH;
indicesToFlows[3] = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
indicesToFlows[4] = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
indicesToFlows[5] = FlowDirectionTypes.FLOWDIRECTION_NORTH;

local sidesToDirections = {};
sidesToDirections[0] = DirectionTypes.DIRECTION_EAST;
sidesToDirections[1] = DirectionTypes.DIRECTION_SOUTHEAST;
sidesToDirections[2] = DirectionTypes.DIRECTION_SOUTHWEST;
sidesToDirections[3] = DirectionTypes.DIRECTION_WEST;
sidesToDirections[4] = DirectionTypes.DIRECTION_NORTHWEST;
sidesToDirections[5] = DirectionTypes.DIRECTION_NORTHEAST;

local indicesToSides = {};
for symbol, i in pairs(sidesToIndices) do indicesToSides[i] = symbol; end

local indicesToVertices = {};
for symbol, i in pairs(verticesToIndices) do indicesToVertices[i] = symbol; end

local flowsToIndices = {};
for i, symbol in pairs(indicesToFlows) do flowsToIndices[symbol] = i; end

local directionsToSides = {};
for i, symbol in pairs(sidesToDirections) do directionsToSides[symbol] = i; end

-------------------------------------------------------------------------------------------------
function GetSideIndex(side)
	if type(side) == "number" then return side % 6 end
	return sidesToIndices[side];
end

-------------------------------------------------------------------------------------------------
function GetVertexIndex(vertex)
	if type(vertex) == "number" then return vertex % 6 end
	return verticesToIndices[vertex];
end

-------------------------------------------------------------------------------------------------
function GetAdjacentPlot(plot, side)
	side = GetSideIndex(side);
	return Map.PlotDirection(plot:GetX(), plot:GetY(), sidesToDirections[side]);
end

-------------------------------------------------------------------------------------------------
function GetFlowRotation(plot, side)
	side = GetSideIndex(side);

	-- Need to check adjacent side
	if side > 2 then
		local adjacentPlot = GetAdjacentPlot(plot, side);
		if adjacentPlot then
			local rotation = GetFlowRotation(adjacentPlot, (side + 3) % 6); 
			if rotation == NoRotation then return NoRotation end
			return -rotation;
		else
			return NoRotation
		end
	end

	-- Get flow direction
	local symbol = indicesToSides[side];
	local getter = plot["GetRiver"..symbol.."FlowDirection"];
	local flowDirection = getter(plot);
	if flowDirection == FlowDirectionTypes.NO_FLOWDIRECTION then
		return NoRotation
	end

	-- Direction to rotation
	-- On east side (0), flow can either be ccw-north (5) or cw-south (2)
	local ccw = (side - 1) % 6;	
	--print(ccw.." ; "..side.." ; "..flowDirection.." ; "..symbol);
	if ccw == flowsToIndices[flowDirection] then
		return CCWRotation;
	else
		return CWRotation;
	end
end

-------------------------------------------------------------------------------------------------
function SetFlowRotation(plot, side, rotation)
	if plot then
		side = GetSideIndex(side);
		--print(side);

		if side > 2 then
			local adjacentPlot = GetAdjacentPlot(plot, side);
			if rotation == NoRotation then
				SetFlowRotation(adjacentPlot, (side + 3) % 6, NoRotation);
			else
				SetFlowRotation(adjacentPlot, (side + 3) % 6, -rotation);
			end
		else
			local symbol = indicesToSides[(side + 3) % 6];
			local setter = plot["Set"..symbol.."OfRiver"];

			-- On east side (0), flow can either be ccw-north (5) or cw-south (2)
			if rotation == CWRotation then
				local flow = indicesToFlows[(side + 2) % 6];
				--print("cw: "..flow.." ; "..side.." ; "..symbol);
				setter(plot, true, flow);
			elseif rotation == CCWRotation then
				local flow = indicesToFlows[(side - 1) % 6];
				--print("ccw: "..flow.." ; "..side.." ; "..symbol);
				setter(plot, true, flow);
			else
				setter(plot, false, FlowDirectionTypes.NO_FLOWDIRECTION);
				--print("none: "..side.." ; "..symbol);
			end
		end
	end
end

-------------------------------------------------------------------------------------------------
local function GetConstrainedRotation(plot, side)
	-- Each side has two vertices and each vertex is connected to two 
	-- other segments, so we have four segments to check. 
	local constrain = 0;
	if plot then
		side = GetSideIndex(side);
		local adjacentPlots = { -1, -1, side, side };
		local adjacentSides = { (side - 1) % 6, (side + 1) % 6, (side - 2) % 6, (side + 2) % 6 };

		for i, plotIndex in ipairs(adjacentPlots) do
			local adjacentPlot = plot;
			if plotIndex >= 0 then
				adjacentPlot = GetAdjacentPlot(plot, plotIndex);
			end

			if adjacentPlot then
				local rotation = GetFlowRotation(adjacentPlot, adjacentSides[i]);
				if rotation ~= NoRotation then
					if plotIndex >= 0 then rotation = -rotation end

					if constrain == NoRotation then
						constrain = rotation;
					elseif constrain ~= rotation then
						return NoRotation;
					end
				end
			end
		end
	end

	return constrain;
end

-------------------------------------------------------------------------------------------------
function ToggleRiverFlow(plot, side)
	if plot then 
		side = GetSideIndex(side);
		local current = GetFlowRotation(plot, side);
		local constrain = GetConstrainedRotation(plot, side);
		--print(current.." ; "..constrain);

		-- Rivers around this side are imposing a flow: we toggle between "on" or "off".
		if constrain ~= NoRotation then
			if current ~= NoRotation then
				SetFlowRotation(plot, side, NoRotation);
			else
				SetFlowRotation(plot, side, constrain);
			end
		-- Beginning of a river: we cycle between "flow1", "flow2" and "off".
		else
			if current == CWRotation then
				SetFlowRotation(plot, side, CCWRotation);
			elseif current == CCWRotation then
				SetFlowRotation(plot, side, NoRotation);
			else
				SetFlowRotation(plot, side, CWRotation);
			end
		end
	end
end

-------------------------------------------------------------------------------------------------
function IsRiverEntryPoint(plot, vertex)
	vertex = GetVertexIndex(vertex);

	-- First we check the radial segment connected to this vertex.
	-- Each vertex is connected to three segments: two within this plot, one radial segment outside this plot.
	-- We check the radial segment. Since it is common to two plots, we check both in case one is nil.
	-- Vertex N (5), check plot NW (4) + side E (0), and plot NE (5) + side W (3)
	local adjacentSide = (vertex - 2) % 6;
	local adjacent = GetAdjacentPlot(plot, vertex);
	if not adjacent then
		adjacent = GetAdjacentPlot(plot, (vertex - 1) % 6);
		adjacentSide = (vertex - 5) % 6;
	end
	if adjacent and GetFlowRotation(adjacent, adjacentSide) ~= NoRotation then 
		return true;
	end

	-- Now we check for a connection to a lake or ocean plot.
	-- Each vertex belong to two segments, each segment is orthogonal 
	-- to an adjacent plot. We check those orthogonal plots.
	-- Vertex N (5) belong to segments NW (4) et NE (5). Those are orthogonals to plots NE (5) and NW (4)
	if GetFlowRotation(plot, vertex) ~= NoRotation then
		adjacent = GetAdjacentPlot(plot, (vertex - 1) % 6);
		if adjacent and adjacent:GetPlotType() == PlotTypes.PLOT_OCEAN  then
			return true;
		end
	end
	if GetFlowRotation(plot, (vertex - 1) % 6) ~= NoRotation then
		adjacent = GetAdjacentPlot(plot, vertex);
		if adjacent and adjacent:GetPlotType() == PlotTypes.PLOT_OCEAN  then
			return true;
		end
	end

	return false;
end
