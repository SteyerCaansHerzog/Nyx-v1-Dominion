--{{{ Dependencies
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ Definitions
--- @class PlanarTestListItem
--- @field offset number
--- @field validation fun(origin: Vector3): boolean
--}}}

--- @type PlanarTestListItem[]
local traces = {
	{
		offset = 10,
		validation = function(origin)
			local trace = Trace.getHullAtPosition(
				origin,
				Vector3:newBounds(Vector3.align.BOTTOM, 15, 15, 9),
				AiUtility.traceOptionsPathfinding,
				"Nodegraph.setupNodegraph<FindNodeTraversableArea>"
			)

			return not trace.isIntersectingGeometry
		end
	},
	{
		offset = 15,
		validation = function(origin)
			local trace = Trace.getHullAtPosition(
				origin,
				Vector3:newBounds(Vector3.align.BOTTOM, 30, 30, 9),
				AiUtility.traceOptionsPathfinding,
				"Nodegraph.setupNodegraph<FindNodeTraversableArea>"
			)

			return not trace.isIntersectingGeometry
		end
	},
	{
		offset = 20,
		validation = function(origin)
			local trace = Trace.getHullAtPosition(
				origin,
				Vector3:newBounds(Vector3.align.BOTTOM, 60, 60, 9),
				AiUtility.traceOptionsPathfinding,
				"Nodegraph.setupNodegraph<FindNodeTraversableArea>"
			)

			return not trace.isIntersectingGeometry
		end
	},
	{
		offset = 25,
		validation = function(origin)
			local trace = Trace.getHullAtPosition(
				origin,
				Vector3:newBounds(Vector3.align.BOTTOM, 90, 90, 9),
				AiUtility.traceOptionsPathfinding,
				"Nodegraph.setupNodegraph<FindNodeTraversableArea>"
			)

			return not trace.isIntersectingGeometry
		end
	}
}

return traces
