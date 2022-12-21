--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateGoToRandomLocation
--- @class AiStateGoToRandomLocation : AiStateBase
--- @field node Node
local AiStateGoToRandomLocation = {
    name = "Go to Random Location"
}

--- @param fields AiStateGoToRandomLocation
--- @return AiStateGoToRandomLocation
function AiStateGoToRandomLocation:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateGoToRandomLocation:assess()
    if not AiUtility.isRoundOver then
        return AiPriority.IGNORE
    end

    if AiUtility.enemiesAlive > 0 then
        return AiPriority.IGNORE
    end

    if AiUtility.isBombPlanted() then
        if not AiUtility.isBombDefused() and AiUtility.enemiesAlive > 0 then
            return AiPriority.IGNORE
        end
    end

    return AiPriority.GO_TO_RANDOM_LOCATION
end

--- @return void
function AiStateGoToRandomLocation:activate()
    self:move()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateGoToRandomLocation:think(cmd)
    if Pathfinder.isIdle() then
        self.activity = "Standing idle"
    else
        self.activity = "Going someplace random"
    end

    Pathfinder.canRandomlyJump()
end

--- @return void
function AiStateGoToRandomLocation:move()
    Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
        task = "Go to a random location",
        goalReachedRadius = 100
    })
end

return Nyx.class("AiStateGoToRandomLocation", AiStateGoToRandomLocation, AiStateBase)
--}}}
