--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandWait
--- @class AiChatCommandWait : AiChatCommandBase
--- @field isTaken boolean
local AiChatCommandWait = {
    cmd = "wait",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandWait:invoke(ai, sender, args)
    if not sender:isAlive() then
        return self.SENDER_IS_DEAD
    end

    if not LocalPlayer:isAlive() then
        return self.CLIENT_IS_DEAD
    end

    ai.voice.pack:speakAgreement()

    local eyeOrigin = sender:getEyeOrigin()
    local cameraAngles = sender:getCameraAngles()
    local forward = cameraAngles:getForward()
    local origin = eyeOrigin:getTraceLine(eyeOrigin + forward * Vector3.MAX_DISTANCE, sender.eid)

    origin = origin - forward * 18
    origin = origin:getTraceLine(origin + Vector3:new(0, 0, -Vector3.MAX_DISTANCE), sender.eid)

    Client.fireAfterRandom(0.5, 1.5, function()
        if sender:isAlive() then
            ai.states.wait:reset()
            ai.states.wait:wait(sender, origin)
        end
    end)
end

return Nyx.class("AiChatCommandWait", AiChatCommandWait, AiChatCommandBase)
--}}}
