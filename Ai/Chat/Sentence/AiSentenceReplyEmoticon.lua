--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceReplyEmoticon
--- @class AiSentenceReplyEmoticon : AiSentence
local AiSentenceReplyEmoticon = {}

--- @return AiSentenceReplyEmoticon
function AiSentenceReplyEmoticon:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyEmoticon:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 2

    self.structures = {
        "{EMOTICON}"
    }

    self.insertions = {
        EMOTICON = {
            ":)", ":(", ":|", "c:"
        }
    }
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceReplyEmoticon:replyToPlayerChat(e)
    if not self:isValidReplyTarget(e) then
        return
    end

    if not self.contains(e.text, {
        "%:%)", "xd", "%:%("
    }) then
        return
    end

    self:speak()
end

return Nyx.class("AiSentenceReplyEmoticon", AiSentenceReplyEmoticon, AiSentence)
--}}}
