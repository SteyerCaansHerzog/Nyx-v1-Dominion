--{{{ Dependencies
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandSkill
--- @class AiChatCommandSkill : AiChatCommand
local AiChatCommandSkill = {
    cmd = "skill",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandSkill:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local skill = Math.clamp(tonumber(args[1]), 0, 10)

    ai.states.engage:setAimSkill(skill)

    ai.nodegraph:log("Updated skill level to %sx", skill)
end

return Nyx.class("AiChatCommandSkill", AiChatCommandSkill, AiChatCommand)
--}}}
