--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ AiRoutineBase
--- @class AiRoutineBase : Class
--- @field ai AiController
--- @field isBlocked boolean
--- @field think fun(self: AiRoutineBase, cmd: SetupCommandEvent): void
local AiRoutineBase = {}

--- @param fields AiRoutineBase
--- @return AiRoutineBase
function AiRoutineBase:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineBase:block()
	self.isBlocked = true
end

--- @return void
function AiRoutineBase:whileBlocked() end

return Nyx.class("AiRoutineBase", AiRoutineBase)
--}}}
