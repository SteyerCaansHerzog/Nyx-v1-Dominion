--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiStateDrop = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDrop"
--}}}

--{{{ AiChatCommandBomb
--- @class AiChatCommandBomb : AiChatCommand
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

    local player = Player.getClient()

    if not player:isAlive() then
        return
    end

    if player:getOrigin():getDistance(sender:getOrigin()) > 512 then
        return
    end

    if not Client.hasBomb() then
        return
    end

    local drop = ai:getState(AiStateDrop)

    drop:dropGear(sender, "bomb")
end

return Nyx.class("AiChatCommandBomb", AiChatCommandBomb, AiChatCommand)
--}}}
