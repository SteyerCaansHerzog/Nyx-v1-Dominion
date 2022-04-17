--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatbot = require "gamesense/Nyx/v1/Dominion/Ai/Chat/AiChatbot"
local AiSentenceReplyBot = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyBot"
local AiSentenceReplyCheater = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyCheater"
local AiSentenceReplyCommend = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyCommend"
local AiSentenceReplyEmoticon = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyEmoticon"
local AiSentenceReplyGay = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyGay"
local AiSentenceReplyInsult = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyInsult"
local AiSentenceReplyRacism = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyRacism"
local AiSentenceReplyRank = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyRank"
local AiSentenceReplySussy = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplySussy"
local AiSentenceReplyWeeb = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyWeeb"
local AiSentenceSayAce = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayAce"
local AiSentenceSayGg = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayGg"
local AiSentenceSayKills = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayKills"
local AiSentenceSayRandom = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayRandom"
--}}}

--{{{ AiChatbotNormal
--- @class AiChatbotNormal : AiChatbot
--- @field sentences AiSentence[]
local AiChatbotNormal = {
    sentences = {
        AiSentenceReplyBot,
        AiSentenceReplyCheater,
        AiSentenceReplyCommend,
        AiSentenceReplyEmoticon,
        AiSentenceReplyGay,
        AiSentenceReplyInsult,
        AiSentenceReplyRacism,
        AiSentenceReplyRank,
        AiSentenceReplySussy,
        AiSentenceReplyWeeb,
        AiSentenceSayAce,
        AiSentenceSayGg,
        AiSentenceSayKills,
        AiSentenceSayRandom,
    }
}

--- @param fields AiChatbotNormal
--- @return AiChatbotNormal
function AiChatbotNormal:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiChatbotNormal:__init()
    local sentences = {}

    for _, sentence in pairs(self.sentences) do
        table.insert(sentences, sentence:new())
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

return Nyx.class("AiChatbotNormal", AiChatbotNormal, AiChatbot)
--}}}
