--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyBot
--- @class AiSentenceReplyBot : AiSentence
local AiSentenceReplyBot = {}

--- @return AiSentenceReplyBot
function AiSentenceReplyBot:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyBot:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 2

    self.structures = {
        "{NOPE}{COMMA} {NO_BOTS} {HERE}{PUNCT}"
    }

    self.insertions = {
        NOPE = {
            "nope", "no", "nah", "lol", "lol no", "lol nah"
        },
        NO_BOTS = {
            "no bots", "there're no bots", "there are no bots", "there's no bots"
        },
        HERE = {
            "here", "around here", "on this team"
        },
        COMMA = {
            "", ","
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
            "bot"
        }) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceReplyBot", AiSentenceReplyBot, AiSentence)
--}}}
