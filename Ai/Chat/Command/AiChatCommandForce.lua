--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandForce
--- @class AiChatCommandForce : AiChatCommand
local AiChatCommandForce = {
    cmd = "force",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return nil
function AiChatCommandForce:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai:forceBuy()
end

return Nyx.class("AiChatCommandForce", AiChatCommandForce, AiChatCommand)
--}}}
