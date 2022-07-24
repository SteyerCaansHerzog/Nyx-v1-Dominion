--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentence"
local AiChatbotBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbotBase"
--}}}

--{{{ AiChatbotNormal
--- @class AiChatbotNormal : AiChatbotBase
--- @field sentences AiSentence
local AiChatbotNormal = {}

--- @param fields AiChatbotNormal
--- @return AiChatbotNormal
function AiChatbotNormal:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiChatbotNormal:__init()
    local sentences = {}

    --- @param sentence AiSentenceBase
    for id, sentence in pairs(AiSentence) do
        sentences[id] = sentence:new()
    end

    self.sentences = sentences

    Callbacks.playerChat(function(e)
        if not self.isEnabled then
            return
        end

        for _, sentence in pairs(self.sentences) do
            sentence:replyToPlayerChat(e)
        end
    end)

    Callbacks.playerDeath(function(e)
        if not self.isEnabled then
            return
        end

        for _, sentence in pairs(self.sentences) do
            sentence:replyToPlayerDeath(e)
        end
    end)

    Callbacks.roundStart(function()
    	if not self.isEnabled then
            return
        end

        for _, sentence in pairs(self.sentences) do
            sentence:replyOnRoundStart()
        end
    end)

    Callbacks.roundEnd(function()
    	if not self.isEnabled then
            return
        end

        for _, sentence in pairs(self.sentences) do
            sentence:replyOnRoundEnd()
        end
    end)

    Callbacks.netUpdateEnd(function()
        if not self.isEnabled then
            return
        end

        for _, sentence in pairs(self.sentences) do
            sentence:replyOnTick()
        end
    end)
end

return Nyx.class("AiChatbotNormal", AiChatbotNormal, AiChatbotBase)
--}}}
