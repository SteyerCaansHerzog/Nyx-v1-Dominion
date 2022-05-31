--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandKnife
--- @class AiChatCommandKnife : AiChatCommandBase
local AiChatCommandKnife = {
    cmd = "knife",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandKnife:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if ai.reaper.isActive then
        return
    end

    local emotion = args[1]

    if emotion == "commit" then
        ai.states.knife.isActive = true
        ai.states.knife.isScared = false
    elseif emotion == "scared" then
        ai.states.knife.isActive = true
        ai.states.knife.isScared = true
    elseif emotion == "off" then
        ai.states.knife.isActive = false
        ai.states.knife.isScared = false
    end
end

return Nyx.class("AiChatCommandKnife", AiChatCommandKnife, AiChatCommandBase)
--}}}
