--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiVoicePack = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePack"
--}}}

--{{{ AiVoicePackGeneric
--- @class AiVoicePackGeneric : AiVoicePack
local AiVoicePackGeneric = {
    filepath = "Generic"
}

--- @param fields AiVoicePackGeneric
--- @return AiVoicePackGeneric
function AiVoicePackGeneric:new(fields)
	return Nyx.new(self, fields)
end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePackGeneric:speakEnemyKilledByClient(event)
    local target = self:getTarget()

    self:speakRandomSequence({
        {target, "Trigger/EnemyKilledByClient/1"},
        {target, "Trigger/EnemyKilledByClient/2"},
        {"Trigger/EnemyKilledByClient/3"},
        {"Trigger/EnemyKilledByClient/4"},
        {"Trigger/EnemyKilledByClient/5"}
    })
end

--- @return void
function AiVoicePackGeneric:speakHearNearbyEnemies()
    local expletive = self:getRandomExpletive()
    local callsignName, callsignNumber = self:getCallsign(Player.getClient())

    self:speakRandomSequence({
        {expletive, callsignName, callsignNumber, "Trigger/HearNearbyEnemies/1"},
        {expletive, "Trigger/HearNearbyEnemies/2"},
        {expletive, "Trigger/HearNearbyEnemies/3"},
    })
end

--- @return string
function AiVoicePackGeneric:getRandomExpletive()
    return Table.getRandom({
        "Misc/Utility/Empty",
        "Misc/Expletive/Fuck",
        "Misc/Expletive/OhFuck",
        "Misc/Expletive/Shit",
        "Misc/Expletive/OhShit",
    })
end

--- @param enemy Player
--- @return string
function AiVoicePackGeneric:getTarget(enemy) end

--- @param player Player
--- @return string, string
function AiVoicePackGeneric:getCallsign(player) end

return Nyx.class("AiVoicePackGeneric", AiVoicePackGeneric, AiVoicePack)
--}}}
