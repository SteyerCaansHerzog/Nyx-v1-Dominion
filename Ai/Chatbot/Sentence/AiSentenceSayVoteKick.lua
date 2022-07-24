--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceSayVoteKick
--- @class AiSentenceSayVoteKick : AiSentenceBase
local AiSentenceSayVoteKick = {}

--- @return AiSentenceSayVoteKick
function AiSentenceSayVoteKick:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceSayVoteKick:__init()
    self.__parent.__init(self)

    self.probability = 1
    self.maxUses = 100

    self.structures = {
        "{PLEASE} {KICK}{PUNCT}",
        "{PLEASE} {KICK} {HE_SUCKS}{PUNCT}",
        "{KICK}{PUNCT}",
        "{KICK} {HE_SUCKS}{PUNCT}",
    }

    self.insertions = {
        PLEASE = {
            "pls", "please", "omg", "oml", "omw", "omfg", "fucking", "fkn", "fucken"
        },
        KICK = {
            "kick this guy", "kick him", "kick him out", "get rid of him"
        },
        HE_SUCKS = {
            "he sucks", "he's so bad", "he's terrible", "he's shit", "he's awful", "he is so bad"
        },
        PUNCT = {
            "", ".", "...", " ...", " lmao", " lmfao", " xd", " XD", " xD", " XDDD"
        }
    }
end

return Nyx.class("AiSentenceSayVoteKick", AiSentenceSayVoteKick, AiSentenceBase)
--}}}
