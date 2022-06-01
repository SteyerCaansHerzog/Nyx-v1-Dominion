--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandWait
--- @class AiChatCommandWait : AiChatCommandBase
--- @field isTaken boolean
local AiChatCommandWait = {
    cmd = "wait",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandWait:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai.voice.pack:speakAgreement()

    local eyeOrigin = sender:getEyeOrigin()
    local cameraAngles = sender:getCameraAngles()
    local forward = cameraAngles:getForward()
    local origin = eyeOrigin:getTraceLine(eyeOrigin + forward * Vector3.MAX_DISTANCE, sender.eid)

    origin = origin - forward * 18
    origin = origin:getTraceLine(origin + Vector3:new(0, 0, -Vector3.MAX_DISTANCE), sender.eid)

    Client.fireAfter(Math.getRandomFloat(0.5, 1.5), function()
        if sender:isAlive() then
            ai.states.wait:reset()
            ai.states.wait:wait(sender, origin, ai.nodegraph)
        end
    end)
end

return Nyx.class("AiChatCommandWait", AiChatCommandWait, AiChatCommandBase)
--}}}
