--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyGay
--- @class AiSentenceReplyGay : AiSentence
local AiSentenceReplyGay = {}

--- @return AiSentenceReplyGay
function AiSentenceReplyGay:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyGay:__init()
    self.__parent.__init(self)

    self.probability = 3
    self.maxUses = 2

    self.structures = {
        "{SHUSH}{PUNCT}"
    }

    self.insertions = {
        SHUSH = {
            "shush", "hush now", "shut it", "shut up", "quiet down", "pipe down"
        },
        PUNCT = {
            "", "."
        }
    }

    Callbacks.playerChat(function(e)
        if not self:isValidReplyTarget(e) then
            return
        end

        if not self.contains(e.text, {
            "gay", "homo", "cocksucker"
        }) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceReplyGay", AiSentenceReplyGay, AiSentence)
--}}}
