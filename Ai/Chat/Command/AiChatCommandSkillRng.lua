--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandSkillRng
--- @class AiChatCommandSkillRng : AiChatCommand
local AiChatCommandSkillRng = {
    cmd = "skillrng",
    requiredArgs = 2,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandSkillRng:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local skillMin = Math.getClamped(tonumber(args[1]), 0, 10)
    local skillMax = Math.getClamped(tonumber(args[2]), 0, 10)
    local skill = Client.getRandomInt(skillMin, skillMax)

    ai.states.engage:setAimSkill(skill)
    ai.nodegraph:log("Updated skill level to %sx", skill)
end

return Nyx.class("AiChatCommandSkillRng", AiChatCommandSkillRng, AiChatCommand)
--}}}
