--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeObjective
--- @class NodeTypeObjective : NodeTypeBase
local NodeTypeObjective = {
	type = "Objective",
	isConnectable = false
}

--- @param fields NodeTypeObjective
--- @return NodeTypeObjective
function NodeTypeObjective:new(fields)
	return Nyx.new(self, fields)
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

return Nyx.class("NodeTypeObjective", NodeTypeObjective, NodeTypeBase)
--}}}
