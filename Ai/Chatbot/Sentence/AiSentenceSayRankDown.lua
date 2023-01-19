--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceSayRankDown
--- @class AiSentenceSayRankDown : AiSentenceBase
--- @field currentRank number
local AiSentenceSayRankDown = {}

--- @return AiSentenceSayRankDown
function AiSentenceSayRankDown:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceSayRankDown:__init()
    self.currentRank = Panorama.MyPersonaAPI.GetCompetitiveRank()

    Callbacks.frameGlobal(function()
        local newRank = Panorama.MyPersonaAPI.GetCompetitiveRank()

        if newRank < self.currentRank then
            self.currentRank = newRank

            self:speak()
        end
    end)

    self.__parent.__init(self)

    self.probability = 1
    self.maxUses = 100

    self.structures = {
        "{OMG} {RANKED_DOWN} {TO_RANK}{PUNCT}",
        "{OMG} {RANKED_DOWN}{PUNCT}",
        "{RANKED_DOWN}{PUNCT}"
    }

    self.insertions = {
        TO_RANK = function()
            local ranks = {"silver 1","silver 2","silver 3","silver 4","silver elite","sem","nova","nova 2","nova 3","nova master","guardian","guardian 2","mge","dmg","le","lem","supreme","global"}
            local rank = string.format("to %s", ranks[Panorama.MyPersonaAPI.GetCompetitiveRank()])

            return rank
        end,
        OMG = {
            "omg", "oh", "lmao", "xd", "fuck", "oh fuck", "shit", "aww"
        },
        RANKED_DOWN = {
            "i ranked down", "i got ranked down", "i've been ranked down",
            "i down ranked", "i got a down rank", "i've been down ranked"
        },
        PUNCT = {
            "", ".", "...", " ..."
        }
    }
end

return Nyx.class("AiSentenceSayRankDown", AiSentenceSayRankDown, AiSentenceBase)
--}}}
