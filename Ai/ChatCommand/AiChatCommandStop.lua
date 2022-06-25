--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandStop
--- @class AiChatCommandStop : AiChatCommandBase
local AiChatCommandStop = {
    cmd = "stop",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandStop:invoke(ai, sender, args)
    if not sender:isAlive() then
        return self.SENDER_IS_DEAD
    end

    ai.states.check:reset()
    ai.states.patrol:reset()
    ai.states.boostTeammate:reset()
    ai.states.follow:reset()
    ai.states.wait:reset()
    ai.states.evacuate:reset()
    ai.states.knife:reset()
end

return Nyx.class("AiChatCommandStop", AiChatCommandStop, AiChatCommandBase)
--}}}
