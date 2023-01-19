local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local MenuGroup = require "Nyx/v1/Dominion/Utility/MenuGroup"
local VKey = require "gamesense/Nyx/v1/Api/VKey"

local key = VKey:new(VKey.TAB)

Callbacks.frame(function()
	if not key:wasPressed() then
		return
	end

	MenuGroup.enableAi:set(not MenuGroup.enableAi:get())
end)