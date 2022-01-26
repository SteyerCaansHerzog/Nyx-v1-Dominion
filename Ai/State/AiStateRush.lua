--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateRush
--- @class AiStateRush : AiState
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
        self.canRushThisRound = Client.getRandomInt(1, 5) == 1
    end)
end

--- @return void
function AiStateRush:assess()
    local player = AiUtility.client

    if not player:isCounterTerrorist() then
        return AiState.priority.IGNORE
    end

    return self.canRushThisRound and AiState.priority.RUSH or AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateRush:activate(ai)
    local nodes = Table.new({ai.nodegraph.tSpawn}, ai.nodegraph.objectiveRush)
    local node = Table.getRandom(nodes, Node)

    if not node then
        self.canRushThisRound = false

        return
    end

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = "Rushing map zone",
        onComplete = function()
            self.canRushThisRound = false

            ai.nodegraph:log("Finished rushing")
        end
    })
end

--- @return void
function AiStateRush:deactivate()
    self.canRushThisRound = false
end

--- @param ai AiOptions
--- @return void
function AiStateRush:think(ai)
    if not ai.nodegraph.path then
        self.canRushThisRound = false
    end
end

return Nyx.class("AiStateRush", AiStateRush, AiState)
--}}}
