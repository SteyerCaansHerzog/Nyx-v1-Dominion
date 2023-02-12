--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceReplyChickenKilled
--- @class AiSentenceReplyChickenKilled : AiSentenceBase
local AiSentenceReplyChickenKilled = {}

--- @return AiSentenceReplyChickenKilled
function AiSentenceReplyChickenKilled:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyChickenKilled:__init()
    self.__parent.__init(self)

    self.probability = 1
    self.maxUses = 2

    self.structures = {
        "{INSULT}, {CHICKEN_KILLED}{PUNCT_EMOJI}",
        "{CHICKEN_KILLED}{PUNCT_EMOJI}",
        "{BRO} {CHICKEN_KILLED}"
    }

    self.insertions = {
        INSULT = {
            "fuck you", "omfg", "omg", "my guy", "you cunt"
        },
        CHICKEN_KILLED = {
            "my chicken",
            "my fucking chicken",
            "the chicken",
            "the fucking chicken"
        },
        BRO = {
            "dude", "bro", "bruh", "brah"
        },
        PUNCT_EMOJI = {
            "", ".", "!", " :(", " :*("
        }
    }
end

return Nyx.class("AiSentenceReplyChickenKilled", AiSentenceReplyChickenKilled, AiSentenceBase)
--}}}
