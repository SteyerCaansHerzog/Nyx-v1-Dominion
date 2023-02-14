--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
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

--{{{ AiStatePick
--- @class AiStatePick : AiStateBase
--- @field blacklist boolean[]
--- @field isPicking boolean
--- @field node NodeSpotWatchCt
--- @field pickTime number
--- @field pickTimer Timer
--- @field isBlockedThisRound boolean
local AiStatePick = {
    name = "Pick",
    requiredNodes = {
        Node.spotWatchCt
    }
}

--- @param fields AiStatePick
--- @return AiStatePick
function AiStatePick:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePick:__init()
    self.blacklist = {}
    self.pickTime = 16
    self.pickTimer = Timer:new()

    Callbacks.roundStart(function()
        self.pickTime = Math.getRandomFloat(16, 32)
        self.blacklist = {}
        self.isBlockedThisRound = false

    	self:reset()
    end)
end

--- @return void
function AiStatePick:assess()
    if not LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    if self.isBlockedThisRound then
        return AiPriority.IGNORE
    end

    -- We've finished watching an angle.
    if self.pickTimer:isElapsedThenStop(self.pickTime) then
        self:reset()

        return AiPriority.IGNORE
    end

    -- Don't keep taking picks when the enemy aren't likely to be in positions to receive.
    if AiUtility.timeData.roundtime_elapsed > 35 then
        return AiPriority.IGNORE
    end

    -- Exit so we can engage the enemy when they become visible.
    if AiUtility.isEnemyVisible then
        return AiPriority.IGNORE
    end

    -- We have an active node.
    if self.node then
        return AiPriority.PICK
    end

    -- We don't want to watch angles at bad times.
    if AiUtility.bombsitePlantAt then
        return AiPriority.IGNORE
    end

    local node = self:getNode()

    if node then
        self.node = node

        return AiPriority.PICK
    end

    return AiPriority.IGNORE
end

--- @return NodeSpotWatchT
function AiStatePick:getNode()
    local clientOrigin = LocalPlayer:getOrigin()

    for _, node in pairs(Nodegraph.get(Node.spotWatchCt)) do repeat
        if self.blacklist[node.id] then
            break
        end

        if clientOrigin:getDistance(node.floorOrigin) > 1200 then
            break
        end

        -- Blacklist the node for now.
        if not Math.getChance(node.chance * 0.01) then
            self.blacklist[node.id] = true

            break
        end

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(node.floorOrigin) < 200 then
                break
            end
        end

        return node
    until true end
end

--- @return void
function AiStatePick:activate()
    self.node:generateWatchOrigin()

    Pathfinder.moveToLocation(self.node.watchOrigin, {
        task = "Pick angle"
    })
end

--- @return void
function AiStatePick:deactivate()
    self:reset()
end

--- @return void
function AiStatePick:reset()
    self.node = nil
    self.isPicking = false

    if self.node then
        self.blacklist[self.node.id] = true
    end

    self.pickTimer:stop()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePick:think(cmd)
    if not self.node then
        return
    end

    self.activity = "Going to pick at area"

    if AiUtility.bombsitePlantAt then
        self:reset()

        return
    end

    self.ai.routines.walk:block()

    local clientOrigin = LocalPlayer:getOrigin()
    local distance = clientOrigin:getDistance(self.node.watchOrigin)

    if not self.isPicking then
        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(self.node.floorOrigin) < self.node.maxLength * 2 then
                self.blacklist[self.node.id] = true

                self:reset()

                break
            end
        end
    end

    if not self.node then
        return
    end

    if distance < 32 then
        self.pickTimer:ifPausedThenStart()

        self.isPicking = true

        if self.node.isAllowedToDuckAt then
            Pathfinder.duck()
        end

        if LocalPlayer:isHoldingSniper() then
            LocalPlayer.scope()
        end
    end

    if distance < 100 then
        self.activity = "Picking at area"

        Pathfinder.counterStrafe()
        Pathfinder.blockTeammateAvoidance()

        self.ai.routines.manageWeaponScope:block()
    end

    if distance < 280 then
        self.ai.routines.manageGear:block()
        self.ai.states.evade:block()

        if not LocalPlayer:isHoldingGun() then
            if LocalPlayer:hasPrimary() then
                LocalPlayer.equipPrimary()
            else
                LocalPlayer.equipPistol()
            end
        end
    end

    if distance < 400 then
        VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 10, VirtualMouse.noise.none, "Pick look at angle")
    end
end

return Nyx.class("AiStatePick", AiStatePick, AiStateBase)
--}}}
