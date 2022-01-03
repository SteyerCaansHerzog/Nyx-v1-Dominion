--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyRacism
--- @class AiSentenceReplyRacism : AiSentence
local AiSentenceReplyRacism = {}

--- @return AiSentenceReplyRacism
function AiSentenceReplyRacism:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyRacism:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 2

    self.structures = {
        FIRST_TIME_RACIST = {
            "{OH}{RACIST1}{PUNCTUATION}",
            "{OH}{RACIST2}{MORON}{PUNCTUATION}"
        },
        STILL_RACIST = {
            "{STILL} {RACIST3}{MORON}{PUNCTUATION}"
        }
    }

    self.insertions = {
        OH = {
            " ",
            "oh, ",
            "ah, "
        },
        PUNCTUATION = {
            "",
            ".",
            " ...",
            "?"
        },
        RACIST1 = {
            "being racist",
            "you're a racist",
            "ur a racist",
            "you're racist",
            "ur racist",
            "a racist"
        },
        RACIST2 = {
            "a racist",
            "you're a racist",
            "ur a racist"
        },
        RACIST3 = {
            "being racist",
            "a racist"
        },
        MORON = {
            "",
            " retard",
            " moron",
            " dumbass",
            " dickhead",
            " cunt",
            " fuckhead"
        },
        STILL = {
            "still",
            "you're still",
            "ur still",
            "ur actually",
            "really",
            "u really are"
        }
    }

    Callbacks.playerChat(function(e)
        if not self.contains(e.text, {
            "nigger", "negro", "coon", "kaffir", "kaffer", "chink", "ching chong", "spick", "beaner", "wetback", "charlie"
        }) then
            return
        end

        if self.uses > 0 then
            self:speak("STILL_RACIST")
        else
            self:speak("FIRST_TIME_RACIST")
        end
    end)
end

return Nyx.class("AiSentenceReplyRacism", AiSentenceReplyRacism, AiSentence)
--}}}
