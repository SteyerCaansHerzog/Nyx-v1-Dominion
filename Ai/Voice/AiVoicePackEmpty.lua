--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackBase"
--}}}

--{{{ AiVoicePackEmpty
--- @class AiVoicePackEmpty : AiVoicePackBase
local AiVoicePackEmpty = {
	name = "None",
    packPath = "Empty"
}

--- @param fields AiVoicePackEmpty
--- @return AiVoicePackEmpty
function AiVoicePackEmpty:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackEmpty", AiVoicePackEmpty, AiVoicePackBase)
--}}}
