--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ AiChat
--- @class AiChat : Class
--- @field sentences AiSentence[]
local AiChat = {}

--- @param fields AiChat
--- @return AiChat
function AiChat:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiChat:__init()
    local sentences = {}

    for _, sentence in pairs(self.sentences) do
        table.insert(sentences, sentence:new())
    end

    self.sentences = sentences
end

return Nyx.class("AiChat", AiChat)
--}}}
