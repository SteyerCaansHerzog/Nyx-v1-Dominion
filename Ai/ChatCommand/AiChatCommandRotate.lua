--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiChatCommandRotate
--- @class AiChatCommandRotate : AiChatCommandBase
local AiChatCommandRotate = {
    cmd = "rot",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandRotate:invoke(ai, sender, args)
    if Entity.getGameRules():m_bFreezePeriod() == 1 then
        return self.FREEZETIME
    end

    if AiUtility.mapInfo.gamemode == "hostage" then
        return self.GAMEMODE_IS_NOT_DEMOLITION
    end

    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    if AiUtility.plantedBomb then
        return self.BOMB_IS_PLANTED
    end

    local objective = args[1]

    if objective ~= "a" and objective ~= "b" then
        return
    end

    objective = objective:upper()

    local node = Nodegraph.getBombsite(objective)

    -- We're already near the site. It would be pointless to activate the rotation.
    if LocalPlayer:getOrigin():getDistance(node.origin) < 1000 then
        return Localization.cmdRejectionAlreadyNearBombsite
    end

    Pathfinder.blockRoute(Nodegraph.getBombsite(objective))

    ai.states.patrol:reset()
    ai.states.rotate:invoke(objective)

    ai.states.defend.defendingSite = objective
    ai.states.defend.bombsite = objective
    ai.states.plant.bombsite = objective
    ai.states.lurkWithBomb.bombsite = objective
    ai.states.defend.isSpecificNodeSet = false
end

return Nyx.class("AiChatCommandRotate", AiChatCommandRotate, AiChatCommandBase)
--}}}
