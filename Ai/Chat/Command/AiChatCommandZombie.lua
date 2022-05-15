--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandZombie
--- @class AiChatCommandZombie : AiChatCommand
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
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        ai.states.zombie.isActive = true
    elseif toggle == "off" then
        ai.states.zombie.isActive = false
    end
end

return Nyx.class("AiChatCommandZombie", AiChatCommandZombie, AiChatCommand)
--}}}
