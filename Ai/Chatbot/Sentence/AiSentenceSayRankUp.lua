--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceSayRankUp
--- @class AiSentenceSayRankUp : AiSentenceBase
--- @field currentRank number
local AiSentenceSayRankUp = {}

--- @return AiSentenceSayRankUp
function AiSentenceSayRankUp:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceSayRankUp:__init()
    self.currentRank = Panorama.MyPersonaAPI.GetCompetitiveRank()

    Callbacks.frameGlobal(function()
        local newRank = Panorama.MyPersonaAPI.GetCompetitiveRank()

        if newRank > self.currentRank then
            self.currentRank = newRank

            self:speak()
        end
    end)

    self.__parent.__init(self)

    self.probability = 1
    self.maxUses = 100

    self.structures = {
        "{OMG} {RANKED_UP} {TO_RANK}{PUNCT}",
        "{OMG} {RANKED_UP}{PUNCT}",
        "{RANKED_UP}{PUNCT}"
    }

    self.insertions = {
        TO_RANK = function()
            local ranks = {"silver 1","silver 2","silver 3","silver 4","silver elite","sem","nova","nova 2","nova 3","nova master","guardian","guardian 2","mge","dmg","le","lem","supreme","global"}
            local rank = string.format("to %s", ranks[Panorama.MyPersonaAPI.GetCompetitiveRank()])

            return rank
        end,
        OMG = {
            "omg", "oh", "lmao", "xd", "cool", "nice", "oh fuck", "fuck yeah", "epic", "shit"
        },
        RANKED_UP = {
            "i ranked up", "i got ranked up", "i've been ranked up",
            "i upranked", "i got an uprank", "i've been upranked"
        },
        PUNCT = {
            "", ".", "...", " ..."
        }
    }
end

return Nyx.class("AiSentenceSayRankUp", AiSentenceSayRankUp, AiSentenceBase)
--}}}
