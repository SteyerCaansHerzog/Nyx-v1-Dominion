--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceReplyVoteKick
--- @class AiSentenceReplyVoteKick : AiSentenceBase
local AiSentenceReplyVoteKick = {}

--- @return AiSentenceReplyVoteKick
function AiSentenceReplyVoteKick:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyVoteKick:__init()
    self.__parent.__init(self)

    self.probability = 3
    self.maxUses = 5

    self.structures = {
        "{PLEASE} {NO}{PUNCT}",
        "{PLEASE} {NO} {KICK}{PUNCT}",
    }

    self.insertions = {
        PLEASE = {
            "pls", "please", ""
        },
        NO = {
            "no", "nooo", "don't", "dont"
        },
        KICK = {
            "kick"
        },
        PUNCT = {
            "", ".", "...", " ...", "!"
        }
    }
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceReplyVoteKick:replyToPlayerChat(e)
    if not e.sender:isOtherTeammate() then
        return
    end

    if not self.contains(e.text, {
        "kick"
    }) then
        return
    end

    self:speak()
end

return Nyx.class("AiSentenceReplyVoteKick", AiSentenceReplyVoteKick, AiSentenceBase)
--}}}
