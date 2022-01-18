--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiStatePatrol = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePatrol"
--}}}

--{{{ AiChatCommandAssist
--- @class AiChatCommandAssist : AiChatCommand
local AiChatCommandAssist = {
    cmd = "assist",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return nil
function AiChatCommandAssist:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if not sender:isAlive() then
        return
    end

    local eyeOrigin = sender:getEyeOrigin()
    local cameraAngles = sender:getCameraAngles()
    local forward = cameraAngles:getForward()
    local origin = eyeOrigin:getTraceLine(eyeOrigin + forward * Vector3.MAX_DISTANCE, sender.eid)

    origin = origin - forward * 18
    origin = origin:getTraceLine(origin + Vector3:new(0, 0, -Vector3.MAX_DISTANCE), sender.eid)

    Client.fireAfter(Client.getRandomFloat(1, 2), function()
        ai.states.patrol:beginPatrol(origin, sender)
    end)
end

return Nyx.class("AiChatCommandAssist", AiChatCommandAssist, AiChatCommand)
--}}}
