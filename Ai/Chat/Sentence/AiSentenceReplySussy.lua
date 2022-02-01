--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplySussy
--- @class AiSentenceReplySussy : AiSentence
local AiSentenceReplySussy = {}

--- @return AiSentenceReplySussy
function AiSentenceReplySussy:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplySussy:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 2

    self.structures = {
        "{GO_AWAY} {FAN}{PUNCT}",
        "{AMOGUS}"
    }

    self.insertions = {
        GO_AWAY = {
            "go away", "fuck off", "piss off", "shut up", "shut it", "stop talking", "don't talk"
        },
        FAN = {
            "amongus fan", "amongus retard", "retard", "fat fuck", "spick"
        },
        AMOGUS = {
            "amogus"
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
            "sussy", "baka"
        }) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceReplySussy", AiSentenceReplySussy, AiSentence)
--}}}
