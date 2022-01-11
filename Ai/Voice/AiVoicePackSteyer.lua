--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackSteyer
--- @class AiVoicePackSteyer : AiVoicePack
local AiVoicePackSteyer = {
	name = "M / EN-CY - Steyer",
    packPath = "Steyer"
}

--- @param fields AiVoicePackSteyer
--- @return AiVoicePackSteyer
function AiVoicePackSteyer:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackSteyer", AiVoicePackSteyer, AiVoicePackGenericBase)
--}}}
