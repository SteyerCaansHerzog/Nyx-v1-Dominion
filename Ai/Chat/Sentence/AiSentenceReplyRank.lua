--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyRank
--- @class AiSentenceReplyRank : AiSentence
local AiSentenceReplyRank = {}

--- @return AiSentenceReplyRank
function AiSentenceReplyRank:new()
    return Nyx.new(self)
end

--- @return nil
function AiSentenceReplyRank:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 1

    self.structures = {
        "{RANK}",
        "i'm {RANK}",
    }

    self.insertions = {
        RANK = function()
            local ranks = {"silver","silver","silver","silver","silver elite","sem","nova","nova","nova","nova master","guardian","guardian","mge","dmg","le","lem","supreme","global"}
            local rank

            if Client.getChance(4) then
                rank = Table.getRandom(ranks) -- Lie about our rank
            else
                rank = ranks[Panorama.MyPersonaAPI.GetCompetitiveRank()]
            end

            return rank
        end
    }

    Callbacks.playerChat(function(e)
        if not self:isValidReplyTarget(e) then
            return
        end

        if not self.contains(e.text, {
            "ranks", "rank", "what rank", "your ranks", "your rank", "ur ranks", "ur rank"
        }) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceReplyRank", AiSentenceReplyRank, AiSentence)
--}}}
