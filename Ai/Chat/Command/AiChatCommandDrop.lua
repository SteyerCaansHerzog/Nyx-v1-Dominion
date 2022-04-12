--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandDrop
--- @class AiChatCommandDrop : AiChatCommand
local AiChatCommandDrop = {
    cmd = "drop",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandDrop:invoke(ai, sender, args)
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

    if player:m_iAccount() < 1500 and not player:hasWeapons(AiUtility.mainWeapons) then
        --return
    end

    if player:getOrigin():getDistance(sender:getOrigin()) > 800 then
        return
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

    if closestTeammate and closestTeammate.eid ~= player.eid then
        return
    end

    ai.states.drop:dropGear(sender, "weapon")
end

return Nyx.class("AiChatCommandDrop", AiChatCommandDrop, AiChatCommand)
--}}}
