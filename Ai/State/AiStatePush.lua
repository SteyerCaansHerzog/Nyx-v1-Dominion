--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
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

    if player:isTerrorist() and not self.isDeactivated and not AiUtility.isBombPlanted() then
        if AiUtility.roundTimer:isElapsed(20) then
            return AiPriority.PUSH
        end
    end

    return AiPriority.IGNORE
end

--- @param site string
--- @return void
function AiStatePush:activate(site)
    local node = self:getActivityNode(site)

    if not node then
        return
    end

    self.site = site
    self.node = node

   self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        task = string.format("Push to %s site [%i]", node.site:upper(), node.id),
        onComplete = function()
           self.ai.nodegraph:log("Pushed onto %s site [%i]", node.site, node.id)

            self.isDeactivated = true
        end
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePush:think(cmd)
    if not self.site then
        return
    end

    if self.site then
        self.activity = string.format("Pushing %s", self.site:upper())
    end

    if self.ai.nodegraph:isIdle() then
        self:activate(self.site)
    end
end

--- @param site string
--- @return Node
function AiStatePush:getActivityNode(site)
    local nodes = {
        a =self.ai.nodegraph.objectiveAPush,
        b =self.ai.nodegraph.objectiveBPush
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
