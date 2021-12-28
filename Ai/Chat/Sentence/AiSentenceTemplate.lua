--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceTemplate
--- @class AiSentenceTemplate : AiSentence
local AiSentenceTemplate = {}

--- @return AiSentenceTemplate
function AiSentenceTemplate:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceTemplate:__init()
    self.__parent.__init(self)

    self.probability = 1
    self.maxUses = 1
    self.structures = {}
    self.insertions = {}

    Callbacks.playerChat(function(e)
        if not self.contains(e.text, {}) then
            return
        end

        self:speak()
    end)
end

return Nyx.class("AiSentenceTemplate", AiSentenceTemplate, AiSentence)
--}}}
