--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateRescueHostage
--- @class AiStateRescueHostage : AiStateBase
local AiStateRescueHostage = {
    name = "Rescue Hostage"
}

--- @param fields AiStateRescueHostage
--- @return AiStateRescueHostage
function AiStateRescueHostage:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateRescueHostage:assess()
    if AiUtility.gamemode ~= "hostage" then
        return AiPriority.IGNORE
    end

    if AiUtility.client:m_hCarriedHostage() == nil then
        return AiPriority.IGNORE
    end

    return AiPriority.RESCUE_HOSTAGE
end

--- @return void
function AiStateRescueHostage:activate()
    self.ai.nodegraph:pathfind(self.ai.nodegraph.objectiveCtSpawn.origin, {
        objective = Node.types.GOAL,
        task = string.format("Rescue hostage")
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateRescueHostage:think(cmd)
    self.activity = "Rescuing hostage"

    self.ai.canUseKnife = false

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end
end

return Nyx.class("AiStateRescueHostage", AiStateRescueHostage, AiStateBase)
--}}}
