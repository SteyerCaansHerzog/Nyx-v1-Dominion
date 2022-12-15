--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateRescueHostage
--- @class AiStateRescueHostage : AiStateBase
local AiStateRescueHostage = {
    name = "Rescue Hostage",
    requiredNodes = {
        Node.objectiveCtSpawn
    },
    requiredGamemodes = {
        AiUtility.gamemodes.HOSTAGE
    }
}

--- @param fields AiStateRescueHostage
--- @return AiStateRescueHostage
function AiStateRescueHostage:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateRescueHostage:assess()
    if LocalPlayer:m_hCarriedHostage() == nil then
        return AiPriority.IGNORE
    end

    return AiPriority.RESCUE_HOSTAGE
end

--- @return void
function AiStateRescueHostage:activate()
    Pathfinder.moveToNode(Nodegraph.getOne(Node.objectiveCtSpawn), {
        task = "Rescue the hostage"
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateRescueHostage:think(cmd)
    self.activity = "Rescuing hostage"

    self.ai.routines.manageGear:block()

    LocalPlayer.equipAvailableWeapon()
end

return Nyx.class("AiStateRescueHostage", AiStateRescueHostage, AiStateBase)
--}}}
