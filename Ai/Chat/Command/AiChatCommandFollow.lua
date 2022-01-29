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

--{{{ AiChatCommandFollow
--- @class AiChatCommandFollow : AiChatCommand
--- @field isTaken boolean
local AiChatCommandFollow = {
    cmd = "follow",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandFollow:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai.voice.pack:speakAgreement()

    Client.fireAfter(Client.getRandomFloat(0.5, 1.5), function()
        if sender:isAlive() then
            ai.states.follow:follow(sender)
        end
    end)
end

return Nyx.class("AiChatCommandFollow", AiChatCommandFollow, AiChatCommand)
--}}}
