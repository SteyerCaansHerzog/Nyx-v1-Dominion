--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
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
    if not self:isValid(ai, sender, args) then
        return
    end

    if not sender:isAlive() then
        return
    end

    local player = AiUtility.client

    if not player:isAlive() then
        return
    end

    if player:getOrigin():getDistance(sender:getOrigin()) > 800 then
        return
    end

    if not Client.hasBomb() then
        return
    end

    ai.states.drop:dropGear(sender, "bomb")
end

return Nyx.class("AiChatCommandBomb", AiChatCommandBomb, AiChatCommandBase)
--}}}
