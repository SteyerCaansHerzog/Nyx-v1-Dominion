--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceReplyInsult
--- @class AiSentenceReplyInsult : AiSentenceBase
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
        "{WHO_ASKED}{IPUNCT}",
        "{SHUSH}{PUNCT}"
    }

    self.insertions = {
        WHO_ASKED = {
            "who asked", "nobody asked", "didn't ask", "did i ask", "did we ask", "did someone ask you",
            "did anyone speak to you", "was anyone speaking to you", "i don't think anyone asked"
        },
        SHUSH = {
            "shush", "hush now", "shut it", "shut up", "quiet down", "pipe down"
        },
        PUNCT = {
            "", "."
        },
        IPUNCT = {
            "", ".", "?"
        }
    }
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceReplyInsult:replyToPlayerChat(e)
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
end

return Nyx.class("AiSentenceReplyInsult", AiSentenceReplyInsult, AiSentenceBase)
--}}}
