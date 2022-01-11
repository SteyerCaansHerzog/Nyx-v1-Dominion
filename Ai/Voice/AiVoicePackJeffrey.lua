--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackJeffrey
--- @class AiVoicePackJeffrey : AiVoicePack
local AiVoicePackJeffrey = {
	name = "M / EN-US - Jeffrey",
    packPath = "Jeffrey"
}

--- @param fields AiVoicePackJeffrey
--- @return AiVoicePackJeffrey
function AiVoicePackJeffrey:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackJeffrey", AiVoicePackJeffrey, AiVoicePackGenericBase)
--}}}
