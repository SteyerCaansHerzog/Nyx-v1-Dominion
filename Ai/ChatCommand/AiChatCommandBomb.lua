--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandBomb
--- @class AiChatCommandBomb : AiChatCommandBase
local AiChatCommandBomb = {
    cmd = "bomb",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandBomb:invoke(ai, sender, args)
    if not sender:isAlive() then
        return self.SENDER_IS_DEAD
    end

    if not LocalPlayer:isAlive() then
        return self.CLIENT_IS_DEAD
    end

    if LocalPlayer:getOrigin():getDistance(sender:getOrigin()) > 800 then
        return self.SENDER_IS_OUT_OF_RANGE
    end

    if not LocalPlayer.hasBomb() then
        return "the client does not have the bomb"
    end

    ai.states.drop:dropGear(sender, "bomb")
end

return Nyx.class("AiChatCommandBomb", AiChatCommandBomb, AiChatCommandBase)
--}}}
