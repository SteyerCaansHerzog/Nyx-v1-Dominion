--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiStateEngage = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEngage"
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

    local skillMin = Math.clamp(tonumber(args[1]), 0, 4)
    local skillMax = Math.clamp(tonumber(args[2]), 0, 4)
    local skill = Client.getRandomInt(skillMin, skillMax)
    local engage = ai:getState(AiStateEngage)

    engage:setAimSkill(skill)

    ai.nodegraph:log("Updated skill level to %sx", skill)
end

return Nyx.class("AiChatCommandSkillRng", AiChatCommandSkillRng, AiChatCommand)
--}}}
