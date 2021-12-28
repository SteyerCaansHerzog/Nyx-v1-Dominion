--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyCheater
--- @class AiSentenceReplyCheater : AiSentence
local AiSentenceReplyCheater = {}

--- @return AiSentenceReplyCheater
function AiSentenceReplyCheater:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyCheater:__init()
    self.__parent.__init(self)

    self.probability = 4
    self.maxUses = 1

    self.structures = {
        "{PRONOUN} {CHEATING}{PUNCTUATION}",
        "{PRONOUN} {CHEATING}, {PUNCHLINE}{PUNCTUATION}",
        "{NO}, {PUNCHLINE}{PUNCTUATION}"
    }

    self.insertions = {
        PRONOUN = {
            "we're not",
            "nobody is",
            "not"
        },
        CHEATING = {
            "cheating",
            "hacking"
        },
        PUNCTUATION = { "", ".", " ..." },
        NO = {
            "no",
            "lol no",
            "bro",
            "dude",
            "my guy",
            "bruh"
        },
        PUNCHLINE = {
            "you just suck",
            "you're just shit",
            "you're just bad",
            "you're bad",
            "you suck",
            "ur just bad"
        }
    }

    Callbacks.playerChat(function(e)
        if not self:isValidReplyTarget(e) then
            return
        end

        if not self.contains(e.text, {
            "report id",
            "cheater", "hacker",
            "you're cheating", "your cheating", "ur cheating", "you cheating",
            "you're hacking", "your hacking", "ur hacking", "you hacking",
            "you cheat", "u cheat", "you hack", "u hack",
            "stop cheating", "stop hacking",
            "fucking cheating", "fucking cheater", "fucking hacker",
            "nice cheats", "ez cheats", "nice cheat", "ez cheat", "aimbot", "aimlock", "nice soft",
            "nice hack", "ez hack", "ez hack",
            "vac", "-acc", "enjoy ban", "nice ow", "ow ban", "bb acc",
            "why cheat", "why hack",
            "so obvious", "ur obvious", "you're obvious"
        }) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceReplyCheater", AiSentenceReplyCheater, AiSentence)
--}}}
