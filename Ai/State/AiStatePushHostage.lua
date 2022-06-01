--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePushHostage
--- @class AiStatePushHostage : AiStateBase
--- @field node Node
local AiStatePushHostage = {
    name = "Push"
}

--- @param fields AiStatePushHostage
--- @return AiStatePushHostage
function AiStatePushHostage:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePushHostage:__init()
    Callbacks.roundPrestart(function()
        self.isDeactivated = false
        self.node = nil
    end)
end

--- @return void
function AiStatePushHostage:assess()
    if AiUtility.gamemode ~= "hostage" then
        return AiPriority.IGNORE
    end

    if not AiUtility.client:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    if self.isDeactivated then
        return AiPriority.IGNORE
    end

    if not AiUtility.roundTimer:isStarted() or AiUtility.roundTimer:isElapsed(30) then
        return AiPriority.IGNORE
    end

    return AiPriority.PUSH
end

--- @return void
function AiStatePushHostage:activate()
    local node = self:getActivityNode()

    if not node then
        return
    end

    self.node = node

   self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        task = string.format("Push the map"),
        onComplete = function()
            self.isDeactivated = true
        end
    })
end

--- @return void
function AiStatePushHostage:deactivate()
    self.isDeactivated = true
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePushHostage:think(cmd)
    if not self.node then
        return
    end

    self.activity = "Pushing the map"

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end
end

--- @return Node
function AiStatePushHostage:getActivityNode()
    local nodes = self.ai.nodegraph.objectivePushHostage

    return nodes[Math.getRandomInt(1, #nodes)]
end

return Nyx.class("AiStatePushHostage", AiStatePushHostage, AiStateBase)
--}}}
