--{{{ Dependencies
local Math = require "gamesense/Nyx/v1/Api/Math"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandSkill
--- @class AiChatCommandSkill : AiChatCommandBase
local AiChatCommandSkill = {
    cmd = "skill",
    requiredArgs = 0,
    isAdminOnly = true,
    isValidIfSelfInvoked = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandSkill:invoke(ai, sender, args)
    local min = args[1]
    local max = args[2]

    if not min then
        Messenger.send(string.format("My skill is level %i", ai.states.engage.skill), true)
    end

    min = Math.getClamped(tonumber(min), ai.states.engage.skillLevelMin, ai.states.engage.skillLevelMax)

    local skill = min

    if max then
        max = Math.getClamped(tonumber(max), ai.states.engage.skillLevelMin, ai.states.engage.skillLevelMax)
        skill = Math.getRandomInt(min, max)
    end

    ai.states.engage:setAimSkill(skill)

    ai.nodegraph:log("Updated skill level to %sx", skill)
end

return Nyx.class("AiChatCommandSkill", AiChatCommandSkill, AiChatCommandBase)
--}}}
