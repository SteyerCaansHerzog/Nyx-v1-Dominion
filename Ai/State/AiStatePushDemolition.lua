--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePushDemolition
--- @class AiStatePushDemolition : AiStateBase
--- @field isDeactivated boolean
--- @field node Node
--- @field site string
local AiStatePushDemolition = {
    name = "Push"
}

--- @param fields AiStatePushDemolition
--- @return AiStatePushDemolition
function AiStatePushDemolition:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePushDemolition:__init()
    Callbacks.roundPrestart(function()
        self.isDefendingBomb = false
        self.isDeactivated = false
        self.node = nil
    end)
end

--- @return void
function AiStatePushDemolition:assess()
    if AiUtility.gamemode == "hostage" then
        return AiPriority.IGNORE
    end

    if not LocalPlayer:isTerrorist() then
        return AiPriority.IGNORE
    end

    if self.isDeactivated or AiUtility.isBombPlanted() then
        return AiPriority.IGNORE
    end

    if AiUtility.roundTimer:isElapsed(30) then
        return AiPriority.IGNORE
    end

    return AiPriority.PUSH
end

--- @param site string
--- @return void
function AiStatePushDemolition:activate(site)
    if not site then
        site = self.site
    end

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
function AiStatePushDemolition:think(cmd)
    if not self.node then
        return
    end

    if not self.site then
        return
    end

    if self.site then
        self.activity = string.format("Pushing %s", self.site:upper())
    end

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end
end

--- @param site string
--- @return Node
function AiStatePushDemolition:getActivityNode(site)
    local nodes = {
        a = self.ai.nodegraph.objectiveAPush,
        b = self.ai.nodegraph.objectiveBPush
    }

    if not site then
        site = Math.getRandomInt(1, 2) == 1 and "a" or "b"
    end

    nodes = nodes[site]

    return nodes[Math.getRandomInt(1, #nodes)]
end

return Nyx.class("AiStatePushDemolition", AiStatePushDemolition, AiStateBase)
--}}}
