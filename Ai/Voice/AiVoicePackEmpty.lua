--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiVoicePack = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePack"
--}}}

--{{{ AiVoicePackEmpty
--- @class AiVoicePackEmpty : AiVoicePack
local AiVoicePackEmpty = {
    packPath = "Generic"
}

--- @param fields AiVoicePackEmpty
--- @return AiVoicePackEmpty
function AiVoicePackEmpty:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackEmpty", AiVoicePackEmpty, AiVoicePack)
--}}}
