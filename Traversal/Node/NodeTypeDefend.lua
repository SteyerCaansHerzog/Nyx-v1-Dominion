--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeDefend
--- @class NodeTypeDefend : NodeTypeBase
--- @field pairedWith NodeTypeDefend
local NodeTypeDefend = {
	type = "Defend",
	isConnectable = true,
	isDirectional = true,
	isLinkedToBombsite = true,
}

--- @param fields NodeTypeDefend
--- @return NodeTypeDefend
function NodeTypeDefend:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeDefend:render(nodegraph, isRenderingMetaData)
	NodeTypeBase.render(self, nodegraph, isRenderingMetaData)

	if self.pairedWith then
		self.origin:drawLine(self.pairedWith.origin, self.renderColorPrimary, 0.5)
	end
end

--- @param nodegraph Nodegraph
--- @return string|nil
function NodeTypeDefend:getError(nodegraph)
	local err = NodeTypeBase.getError(self, nodegraph)

	if err then
		return err
	end

	if not self.pairedWith then
		return "No partner"
	end
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTypeDefend:onCreate(nodegraph)
	NodeTypeBase.onCreate(self, nodegraph)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTypeDefend:onRemove(nodegraph)
	NodeTypeBase.onRemove(self, nodegraph)

	if self.pairedWith then
		self.pairedWith.pairedWith = nil
	end
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTypeDefend:onSetup(nodegraph)
	NodeTypeBase.onSetup(self, nodegraph)

	if self.pairedWith then
		return
	end

	local nodes = nodegraph.get(self)

	if not nodes then
		return
	end

	--- @type NodeTypeDefend
	local closest
	local closestDistance = math.huge

	for _, node in pairs(nodes) do repeat
		if self.id == node.id then
			break
		end

		local distance = self.origin:getDistance(node.origin)

		if distance < 256 and distance < closestDistance and not node.pairedWith then
			closestDistance = distance
			closest = node
		end
	until true end

	if closest then
		self.pairedWith = closest
		closest.pairedWith = self
	end
end

return Nyx.class("NodeTypeDefend", NodeTypeDefend, NodeTypeBase)
--}}}
