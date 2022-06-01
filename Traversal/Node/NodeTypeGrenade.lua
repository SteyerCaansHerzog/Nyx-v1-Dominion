--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeGrenade
--- @class NodeTypeGrenade : NodeTypeBase
--- @field isJump boolean
--- @field isRun boolean
local NodeTypeGrenade = {
	type = "Grenade",
	isDirectional = true,
	isActive = true
}

--- @param fields NodeTypeGrenade
--- @return NodeTypeGrenade
function NodeTypeGrenade:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function NodeTypeGrenade:__init()
	NodeTypeBase.__init(self)
end

--- @param menu MenuGroup
--- @return void
function NodeTypeGrenade:setupCustomizers(menu)
	NodeTypeBase.setupCustomizers(self, menu)

	self:addCustomizer("isJump", function()
		return menu.group:addCheckbox("    > Jump")
	end)

	self:addCustomizer("isRun", function()
		return menu.group:addCheckbox("    > Run")
	end)
end

return Nyx.class("NodeTypeGrenade", NodeTypeGrenade, NodeTypeBase)
--}}}
