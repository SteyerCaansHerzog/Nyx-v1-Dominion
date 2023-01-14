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
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStatePushHostage
--- @class AiStatePushHostage : AiStateBase
--- @field node NodeSpotPushCt
local AiStatePushHostage = {
    name = "Push (Hostage)",
    requiredNodes = {
        Node.spotPushCt
    },
    requiredGamemodes = {
        AiUtility.gamemodes.HOSTAGE
    }
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
    if not LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    if self.isDeactivated then
        return AiPriority.IGNORE
    end

    if AiUtility.timeData.roundtime_elapsed > 30 then
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

    Pathfinder.moveToNode(node, {
        task = "Push the map",
        onReachedGoal = function()
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
    self.activity = "Pushing the map"

    Pathfinder.canRandomlyJump()
end

--- @return Node
function AiStatePushHostage:getActivityNode()
    return Nodegraph.getRandom(Node.spotPushCt)
end

return Nyx.class("AiStatePushHostage", AiStatePushHostage, AiStateBase)
--}}}
