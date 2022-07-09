--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandForce
--- @class AiChatCommandForce : AiChatCommandBase
local AiChatCommandForce = {
    cmd = "force",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandForce:invoke(ai, sender, args)
    if ai.reaper.isActive then
        return
    end

    ai.routines.buyGear:force()
end

return Nyx.class("AiChatCommandForce", AiChatCommandForce, AiChatCommandBase)
--}}}
