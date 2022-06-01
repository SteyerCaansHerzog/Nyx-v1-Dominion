--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeObjective
--- @class NodeTypeObjective : NodeTypeBase
--- @field size number
local NodeTypeObjective = {
	type = "Objective",
	isConnectable = false,
	size = 200
}

--- @param fields NodeTypeObjective
--- @return NodeTypeObjective
function NodeTypeObjective:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeObjective:render(nodegraph, isRenderingMetaData)
	NodeTypeBase.render(self, nodegraph, isRenderingMetaData)

	if not self:isRenderable() then
		return
	end

	local plane = self.origin:clone():offset(0, 0, -18):getPlane(Vector3.align.CENTER, self.size)
	local lastVertex = #plane

	for k, vertex in pairs(plane) do
		--- @type Vector3
		local nextVertex

		if k == lastVertex then
			nextVertex = plane[1]
		else
			nextVertex = plane[k + 1]
		end

		vertex:drawLine(nextVertex, self.renderColorFovPrimary)
	end
end

--- @param  nodegraph Nodegraph
--- @return string
function NodeTypeObjective:getError(nodegraph)
	local nodesOfType = nodegraph.get(self)

	if not nodesOfType then
		return
	end

	local iNodes = 0

	for _, _ in pairs(nodesOfType) do
		iNodes = iNodes + 1

		if iNodes > 1 then
			return "Duplicate node"
		end
	end

	return NodeTypeBase.getError(self, nodegraph)
end

--- @param menu MenuGroup
--- @return void
function NodeTypeObjective:setupCustomizers(menu)
	NodeTypeBase.setupCustomizers(self, menu)

	self:addCustomizer("size", function()
		return menu.group:addSlider("    > Size", 1, 10, {
			default = 2,
			scale = 100
		}):onGet(function(value)
			return value * 100
		end)
	end)
end

return Nyx.class("NodeTypeObjective", NodeTypeObjective, NodeTypeBase)
--}}}
