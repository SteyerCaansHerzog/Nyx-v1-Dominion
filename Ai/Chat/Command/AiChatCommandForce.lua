--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandForce
--- @class AiChatCommandForce : AiChatCommandBase
local AiChatCommandForce = {
    cmd = "force",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandForce:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if ai.reaper.isActive then
        return
    end

    ai:forceBuy()
end

return Nyx.class("AiChatCommandForce", AiChatCommandForce, AiChatCommandBase)
--}}}
