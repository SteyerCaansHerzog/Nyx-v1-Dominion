--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiSense = require "gamesense/Nyx/v1/Dominion/Ai/AiSense"
--}}}

--{{{ AiChatCommandKnow
--- @class AiChatCommandKnow : AiChatCommandBase
local AiChatCommandKnow = {
    cmd = "know",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandKnow:invoke(ai, sender, args)
    for _, enemy in Player.find(function(p)
        return p:isEnemy() and p:isAlive()
    end) do
        AiSense.sense(enemy, Vector3.MAX_DISTANCE, false, "forced")
    end
end

return Nyx.class("AiChatCommandKnow", AiChatCommandKnow, AiChatCommandBase)
--}}}
