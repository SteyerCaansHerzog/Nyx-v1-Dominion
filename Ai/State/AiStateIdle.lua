--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
--}}}

--{{{ AiStateIdle
--- @class AiStateIdle : AiStateBase
local AiStateIdle = {
    name = "Idle"
}

--- @param fields AiStateIdle
--- @return AiStateIdle
function AiStateIdle:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateIdle:__init() end

--- @return void
function AiStateIdle:assess()
    return AiPriority.IDLE
end

--- @return void
function AiStateIdle:activate() end

--- @return void
function AiStateIdle:reset() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateIdle:think(cmd)
    self.activity = "Idling"
end

return Nyx.class("AiStateIdle", AiStateIdle, AiStateBase)
--}}}
