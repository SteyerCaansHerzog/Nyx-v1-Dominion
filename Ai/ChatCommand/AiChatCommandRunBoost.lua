--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandRunBoost
--- @class AiChatCommandRunBoost : AiChatCommandBase
--- @field isTaken boolean
local AiChatCommandRunBoost = {
    cmd = "rboost",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandRunBoost:invoke(ai, sender, args)
    self.isTaken = false

    local senderOrigin = sender:getOrigin()

    if LocalPlayer:getOrigin():getDistance(senderOrigin) > 1400 then
        return self.SENDER_IS_OUT_OF_RANGE
    end

    local senderCameraAngles = sender:getCameraAngles()
    local traceAim = Trace.getHullAtAngle(sender:getEyeOrigin(), senderCameraAngles, Vector3:newBounds(Vector3.align.CENTER, 16, 16, 18), AiUtility.traceOptionsPathfinding)
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

        if k == LocalPlayer.eid then
            orderInQueue = i

            break
        end
    end

    Client.fireAfter(orderInQueue * 1, function()
        if not self.isTaken then
            ai.states.boostTeammate:boost(sender, traceAim.endPosition, true)
            ai.states.useBoost:reset()

            Messenger.send(true, " ok")

            ai.voice.pack:speakNoProblem()
        end

        self.isTaken = false
    end)
end

return Nyx.class("AiChatCommandRunBoost", AiChatCommandRunBoost, AiChatCommandBase)
--}}}
