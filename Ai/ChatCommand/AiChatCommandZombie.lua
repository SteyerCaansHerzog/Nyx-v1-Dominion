--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandZombie
--- @class AiChatCommandZombie : AiChatCommandBase
local AiChatCommandZombie = {
    cmd = "zombie",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandZombie:invoke(ai, sender, args)
    local toggle = args[1]

    if toggle == "on" then
        ai.states.zombie.isActive = true

        return
    elseif toggle == "off" then
        ai.states.zombie.isActive = false

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandZombie", AiChatCommandZombie, AiChatCommandBase)
--}}}
