--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandBoost
--- @class AiChatCommandBoost : AiChatCommand
--- @field isTaken boolean
local AiChatCommandBoost = {
    cmd = "boost",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandBoost:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    self.isTaken = false

    local player = AiUtility.client
    local senderOrigin = sender:getOrigin()

    if player:getOrigin():getDistance(senderOrigin) > 1400 then
        return
    end

    if sender:isClient() then
        return
    end

    local senderCameraAngles = sender:getCameraAngles()
    local senderCameraBackward = senderCameraAngles:getBackward()
    local bounds = Vector3:newBounds(Vector3.align.CENTER, 8)
    local traceAim = Trace.getLineAtAngle(sender:getEyeOrigin(), senderCameraAngles, AiUtility.traceOptionsPathfinding)

    traceAim.endPosition = traceAim.endPosition + senderCameraBackward * 16

    local traceFloor = Trace.getHullInDirection(traceAim.endPosition, Vector3:new(0, 0, -1), bounds, AiUtility.traceOptionsPathfinding)

    local distances = {}

    for _, teammate in Player.find(function(p)
        return p:isTeammate() and p:isAlive() and not p:is(sender)
    end) do
        distances[teammate.eid] = senderOrigin:getDistance(teammate:getOrigin())
    end

    local orderInQueue = 0
    local i = 0

    for k, _ in Table.sortedPairs(distances, function(a, b)
        return a < b
    end) do
        i = i + 1

        if k == player.eid then
            orderInQueue = i

            break
        end
    end

    Client.fireAfter(orderInQueue, function()
        if not self.isTaken then
            ai.states.boost:boost(sender, traceFloor.endPosition)

            Messenger.send(" ok", true)

            ai.voice.pack:speakNoProblem()
        end

        self.isTaken = false
    end)
end

return Nyx.class("AiChatCommandBoost", AiChatCommandBoost, AiChatCommand)
--}}}
