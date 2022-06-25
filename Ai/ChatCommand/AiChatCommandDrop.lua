--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandDrop
--- @class AiChatCommandDrop : AiChatCommandBase
local AiChatCommandDrop = {
    cmd = "drop",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandDrop:invoke(ai, sender, args)
    if not sender:isAlive() then
        return self.SENDER_IS_DEAD
    end

    if not LocalPlayer:isAlive() then
        return self.CLIENT_IS_DEAD
    end

    if LocalPlayer:getOrigin():getDistance(sender:getOrigin()) > 800 then
        return self.SENDER_IS_OUT_OF_RANGE
    end

    if not sender:isTeammateOf(LocalPlayer) then
        return self.SENDER_IS_NOT_TEAMMATE
    end

    local eid = args[1]

    -- Handle being asked directly by entity-index to drop a weapon.
    -- This is used by the Manage Economy routine to handle AI-to-AI economy management.
    if eid then
        eid = tonumber(eid)

        if eid == LocalPlayer.eid then
            ai.states.drop:dropGear(sender, "weapon")

            return
        else
            ai.states.pickupItems:temporarilyBlacklistDroppedItemsFrom(Player:new(eid))

            return "the invoker was not asking us"
        end
    end

    local senderEyeOrigin = sender:getEyeOrigin()
    local senderCameraAngles = sender:getCameraAngles()
    --- @type Player
    local closestTeammate
    local closestFov = math.huge

    for _, teammate in Player.find(function(p)
        return p:isAlive() and p:isTeammate() and p.eid ~= sender.eid
    end) do
        local fov = senderCameraAngles:getFov(senderEyeOrigin, teammate:getEyeOrigin())

        if fov < 55 and fov < closestFov then
            closestFov = fov
            closestTeammate = teammate
        end
    end

    if closestTeammate and closestTeammate.eid ~= LocalPlayer.eid then
        ai.states.pickupItems:temporarilyBlacklistDroppedItemsFrom(closestTeammate)

        return "the invoker was not asking us"
    end

    ai.states.drop:dropGear(sender, "weapon")
end

return Nyx.class("AiChatCommandDrop", AiChatCommandDrop, AiChatCommandBase)
--}}}
