--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateRush
--- @class AiStateRush : AiStateBase
--- @field canRushThisRound boolean
local AiStateRush = {
    name = "Rush"
}

--- @param fields AiStateRush
--- @return AiStateRush
function AiStateRush:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateRush:__init()
    Callbacks.roundStart(function()
        self.canRushThisRound = Client.getChance(8)
    end)
end

--- @return void
function AiStateRush:assess()
    if AiUtility.gamemode == "hostage" then
        if not AiUtility.client:isTerrorist() then
            return AiPriority.IGNORE
        end
    else
        if not AiUtility.client:isCounterTerrorist() then
            return AiPriority.IGNORE
        end
    end

    if AiUtility.plantedBomb then
        return AiPriority.IGNORE
    end

    return self.canRushThisRound and AiPriority.RUSH or AiPriority.IGNORE
end

--- @return void
function AiStateRush:activate()
    local nodes = Table.new(self.ai.nodegraph.objectiveRush)
    local node = Table.getRandom(nodes, Node)

    if not node then
        self.canRushThisRound = false

        return
    end

   self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        task = "Rushing map zone",
        onComplete = function()
            self.canRushThisRound = false

           self.ai.nodegraph:log("Finished rushing")
        end
    })
end

--- @return void
function AiStateRush:deactivate()
    self.canRushThisRound = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateRush:think(cmd)
    self.activity = "Rushing"

    if self.ai.nodegraph:isIdle() then
        self.canRushThisRound = false
    end
end

return Nyx.class("AiStateRush", AiStateRush, AiStateBase)
--}}}
