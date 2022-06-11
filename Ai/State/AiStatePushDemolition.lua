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
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStatePushDemolition
--- @class AiStatePushDemolition : AiStateBase
--- @field isDeactivated boolean
--- @field node NodeSpotPushT
local AiStatePushDemolition = {
    name = "Push (Demolition)",
    requiredNodes = {
        Node.spotPushT
    },
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
    }
}

--- @param fields AiStatePushDemolition
--- @return AiStatePushDemolition
function AiStatePushDemolition:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePushDemolition:__init()
    self:setActivityNode()

    Callbacks.roundPrestart(function()
        self.isDefendingBomb = false
        self.isDeactivated = false

        self:setActivityNode()
    end)
end

--- @return void
function AiStatePushDemolition:assess()
    if not LocalPlayer:isTerrorist() then
        return AiPriority.IGNORE
    end

    if self.isDeactivated or AiUtility.isBombPlanted() or AiUtility.timeData.roundtime_elapsed > 35 then
        return AiPriority.IGNORE
    end

    return AiPriority.PUSH
end

--- @return void
function AiStatePushDemolition:activate()
    Pathfinder.moveToNode(self.node, {
        task = string.format("Push to %s site", self.node.bombsite),
        onReachedGoal = function()
        	self.isDeactivated = true
        end
    })
end

--- @param bombsite string
--- @return void
function AiStatePushDemolition:invoke(bombsite)
    self:setActivityNode(bombsite)
    self:queueForReactivation()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePushDemolition:think(cmd)
    self.activity = string.format("Pushing %s", self.node.bombsite)
end

--- @param bombsite string
--- @return NodeSpotPushT
function AiStatePushDemolition:setActivityNode(bombsite)
    bombsite = bombsite or AiUtility.randomBombsite

    self.node = Nodegraph.getRandomForBombsite(Node.spotPushT, bombsite)
end

return Nyx.class("AiStatePushDemolition", AiStatePushDemolition, AiStateBase)
--}}}
