--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyInsult
--- @class AiSentenceReplyInsult : AiSentence
local AiSentenceReplyInsult = {}

--- @return AiSentenceReplyInsult
function AiSentenceReplyInsult:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyInsult:__init()
    self.__parent.__init(self)

    self.probability = 4
    self.maxUses = 30

    self.structures = {
        "didn't ask{PUNCTUATION}",
        "who asked?",
        "did someone ask you?",
        "i don't think anyone asked{PUNCTUATION}",
        "nobody {ASKED}{PUNCTUATION}"
    }

    self.insertions = {
        ASKED = {
            "asked",
            "was speaking to you",
        },
        PUNCTUATION = {
            "", "."
        }
    }

    Callbacks.playerChat(function(e)
        if not self:isValidReplyTarget(e) then
            return
        end
        if not self.contains(e.text, {
            "ur shit", "you're shit",
            "suck",
            "fuck you", "fuck u", "fuck off", "bitch",
            "ur mom", "your mom", "ur sister", "your sister",
            "ez", "easy", "rekt", "nn ", " nn", "sit", "sit dog", "hdf",
            "kys", "go die",
            "cunt", "bastard", "fag", "faggot", "retard", "fucker",
            "loser"
        }) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceReplyInsult", AiSentenceReplyInsult, AiSentence)
--}}}
