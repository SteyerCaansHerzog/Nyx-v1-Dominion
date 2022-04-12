--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackCoen
--- @class AiVoicePackCoen : AiVoicePackGenericBase
local AiVoicePackCoen = {
	name = "M / EN-NL - Coen",
	packPath = "Coen"
}

--- @param fields AiVoicePackCoen
--- @return AiVoicePackCoen
function AiVoicePackCoen:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackCoen", AiVoicePackCoen, AiVoicePackGenericBase)
--}}}
