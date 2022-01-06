--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePush
--- @class AiStatePush : AiState
--- @field isDeactivated boolean
--- @field node Node
--- @field site string
local AiStatePush = {
    name = "Push"
}

--- @param fields AiStatePush
--- @return AiStatePush
function AiStatePush:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePush:__init()
    Callbacks.roundStart(function()
        self.isDefendingBomb = false
        self.isDeactivated = false
        self.node = nil
    end)
end

--- @return void
function AiStatePush:assess()
    local player = AiUtility.client

    if player:isTerrorist() and not self.isDeactivated then
        if not AiUtility.roundTimer:isStarted() or not AiUtility.roundTimer:isElapsed(15) then
            return AiState.priority.PUSH
        end
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @param site string
--- @return void
function AiStatePush:activate(ai, site)
    local node = self:getActivityNode(ai, site)

    if not node then
        return
    end

    self.site = site
    self.node = node

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = string.format("Push to %s site [%i]", node.site:upper(), node.id),
        onComplete = function()
            ai.nodegraph:log("Pushed onto %s site [%i]", node.site, node.id)

            self.isDeactivated = true
        end
    })
end

--- @param ai AiOptions
--- @return void
function AiStatePush:think(ai)
    if not ai.nodegraph.path and ai.nodegraph:canPathfind() then
        self:activate(ai, self.site)
    end
end

--- @param ai AiOptions
--- @param site string
--- @return Node
function AiStatePush:getActivityNode(ai, site)
    local nodes = {
        a = ai.nodegraph.objectiveAPush,
        b = ai.nodegraph.objectiveBPush
    }

    local site = site

    if not site then
        site = Client.getRandomInt(1, 2) == 1 and "a" or "b"
    end

    local nodes = nodes[site]

    return nodes[Client.getRandomInt(1, #nodes)]
end

return Nyx.class("AiStatePush", AiStatePush, AiState)
--}}}
