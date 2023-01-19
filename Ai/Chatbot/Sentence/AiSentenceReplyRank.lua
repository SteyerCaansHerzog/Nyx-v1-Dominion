--{{{ Dependencies
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceReplyRank
--- @class AiSentenceReplyRank : AiSentenceBase
local AiSentenceReplyRank = {}

--- @return AiSentenceReplyRank
function AiSentenceReplyRank:new()
    return Nyx.new(self)
end

--- @return void
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

            if Math.getChance(4) then
                rank = Table.getRandom(ranks) -- Lie about our rank
            else
                rank = ranks[Panorama.MyPersonaAPI.GetCompetitiveRank()]
            end

            return rank
        end
    }
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceReplyRank:replyToPlayerChat(e)
    if not self:isValidReplyTarget(e) then
        return
    end

    if not self.contains(e.text, {
        "ranks", "rank", "what rank", "your ranks", "your rank", "ur ranks", "ur rank"
    }) then
        return
    end

    self:speak()
end

return Nyx.class("AiSentenceReplyRank", AiSentenceReplyRank, AiSentenceBase)
--}}}
