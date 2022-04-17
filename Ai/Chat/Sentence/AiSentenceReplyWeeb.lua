--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyWeeb
--- @class AiSentenceReplyWeeb : AiSentence
local AiSentenceReplyWeeb = {}

--- @return AiSentenceReplyWeeb
function AiSentenceReplyWeeb:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyWeeb:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 2

    self.structures = {
        "{SHUT_UP} {YOU} {WEEB}{PUNCT}",
        "{SHUT_UP}{PUNCT}",
        "{SUSSY}"
    }

    self.insertions = {
        SHUT_UP = {
            "shut up", "shut it", "shut the fuck up", "don't talk", "stop talking"
        },
        YOU = {
            "you", "you're a", "ur a", "you are a"
        },
        WEEB = {
            "weeb", "smelly weeb", "dirty weeb", "fucking weeb", "weeaboo"
        },
        SUSSY = {
            "sussy", "sussy baka", "sus"
        },
        PUNCT = {
            "", "."
        }
    }
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceReplyWeeb:replyToPlayerChat(e)
    if not self:isValidReplyTarget(e) then
        return
    end

    if not self.contains(e.text, {
        "uwu", "owo"
    }) then
        return
    end

    self:speak()
end

return Nyx.class("AiSentenceReplyWeeb", AiSentenceReplyWeeb, AiSentence)
--}}}
