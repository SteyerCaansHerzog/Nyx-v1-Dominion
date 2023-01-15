--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateRush
--- @class AiStateRush : AiStateBase
--- @field isRushing boolean
local AiStateRush = {
    name = "Rush",
    requiredNodes = {
        Node.spotPushCt
    }
}

--- @param fields AiStateRush
--- @return AiStateRush
function AiStateRush:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateRush:__init()
    Callbacks.roundStart(function()
        self.isRushing = Math.getChance(6)
    end)
end

--- @return void
function AiStateRush:assess()
    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
        if not LocalPlayer:isTerrorist() then
            return AiPriority.IGNORE
        end
    else
        if not LocalPlayer:isCounterTerrorist() then
            return AiPriority.IGNORE
        end
    end

    if AiUtility.plantedBomb then
        return AiPriority.IGNORE
    end

    return self.isRushing and AiPriority.RUSH or AiPriority.IGNORE
end

--- @return void
function AiStateRush:activate()
    local node = Nodegraph.getRandom(Node.spotPushCt)

    Pathfinder.moveToNode(node, {
        task = "Rush the map",
        onReachedGoal = function()
        	self.isRushing = false
        end
    })
end

--- @return void
function AiStateRush:deactivate()
    self.isRushing = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateRush:think(cmd)
    self.activity = "Rushing"
end

return Nyx.class("AiStateRush", AiStateRush, AiStateBase)
--}}}
