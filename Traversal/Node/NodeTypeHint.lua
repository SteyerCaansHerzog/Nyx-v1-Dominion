--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeHint
--- @class NodeTypeHint : NodeTypeBase
--- @field radius number
local NodeTypeHint = {
	type = "Hint",
	isConnectable = false
}

--- @param fields NodeTypeHint
--- @return NodeTypeHint
function NodeTypeHint:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeHint:render(nodegraph, isRenderingMetaData)
	NodeTypeBase.render(self, nodegraph, isRenderingMetaData)

	if not self:isRenderable() then
		return
	end

	if self.radius then
		self.origin:clone():offset(0, 0, -18):drawCircle3D(self.radius, self.renderColorInfo)
	end
end

--- @param menu MenuGroup
--- @return void
function NodeTypeHint:setCustomizers(menu)
	NodeTypeBase.setCustomizers(self, menu)

	self:addCustomizer("radius", function()
		return menu.group:addSlider("    > Hint Radius", 1, 10, {
			default = 2,
			scale = 100
		}):onGet(function(value)
			return value * 100
		end)
	end)
end

return Nyx.class("NodeTypeHint", NodeTypeHint, NodeTypeBase)
--}}}
