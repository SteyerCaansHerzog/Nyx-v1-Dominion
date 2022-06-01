--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateSeekHostage
--- @class AiStateSeekHostage : AiStateBase
--- @field node Node
--- @field activeHostage Entity
--- @field hostageOrigin Vector3
--- @field isHostageFound boolean
--- @field reseekTimer Timer
local AiStateSeekHostage = {
    name = "Seek Hostage"
}

--- @param fields AiStateSeekHostage
--- @return AiStateSeekHostage
function AiStateSeekHostage:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateSeekHostage:__init()
    self.reseekTimer = Timer:new():startThenElapse()

    Callbacks.roundPrestart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateSeekHostage:assess()
    if AiUtility.gamemode ~= "hostage" then
        return AiPriority.IGNORE
    end

    if AiUtility.isRoundOver then
        return AiPriority.IGNORE
    end

    if not LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    if AiUtility.isHostageCarriedByTeammate then
        return AiPriority.IGNORE
    end

    if AiUtility.isClientThreatened then
        return AiPriority.IGNORE
    end

    -- Find a hostage to rescue.
    self:findHostage()

    if self.activeHostage then
        local distance = LocalPlayer:getOrigin():getDistance(self.hostageOrigin)

        if distance < 600 then
            return AiPriority.SEEK_HOSTAGE_EXPEDITE
        end

        if distance < 1200 then
            return AiPriority.SEEK_HOSTAGE_ACTIVE
        end
    end

    return AiPriority.SEEK_HOSTAGE_PASSIVE
end

--- @return void
function AiStateSeekHostage:findHostage()
    local clientOrigin = LocalPlayer:getOrigin()
    --- @type Entity
    local closestHostage
    local closestDistance = math.huge

    for _, hostage in Entity.find("CHostage") do
        local distance = clientOrigin:getDistance(hostage:m_vecOrigin())

        if distance < closestDistance then
            closestDistance = distance
            closestHostage = hostage
        end
    end

    if not closestHostage then
        return
    end

    self.activeHostage = closestHostage
    self.hostageOrigin = self.activeHostage:m_vecOrigin()
end

--- @return void
function AiStateSeekHostage:activate()
    if self.activeHostage then
        self.ai.nodegraph:pathfind(self.hostageOrigin, {
            objective = Node.types.GOAL,
            task = string.format("Pick up hostage")
        })
    else
        local node = self:getActivityNode()

        if not node then
            return
        end

        self.node = node

        self.ai.nodegraph:pathfind(node.origin, {
            objective = Node.types.GOAL,
            task = string.format("Seek hostage")
        })
    end
end

--- @return void
function AiStateSeekHostage:reset()
    self.activeHostage = nil
    self.hostageOrigin = nil
    self.node = nil
    self.isHostageFound = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateSeekHostage:think(cmd)
    if not self.node and not self.activeHostage then
        return
    end

    if self.activeHostage then
        if not self.isHostageFound then
            self.isHostageFound = true

            self:activate()
        end

        if self.reseekTimer:isElapsedThenRestart(2) then
            self:activate()
        end

        local clientOrigin = LocalPlayer:m_vecOrigin()
        local lookAtOrigin = self.hostageOrigin:clone():offset(0, 0, 40)
        local distance = clientOrigin:getDistance(self.hostageOrigin)

        if distance < 250 then
            View.lookAtLocation(lookAtOrigin, 5, View.noise.none, "Seek hostage look at hostage")
        end

        if distance < 40 then
            self.activity = "Picking up hostage"

            local angles = Client.getEyeOrigin():getAngle(lookAtOrigin)

            if Client.getCameraAngles():getMaxDiff(angles) < 40 then
                cmd.in_use = true
            end
        else
            self.activity = "Going to hostage"
        end
    else
        self.activity = "Seeking hostages"
    end

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end
end

--- @return Node
function AiStateSeekHostage:getActivityNode()
    local nodes = self.ai.nodegraph.objectiveHostage

    return nodes[Math.getRandomInt(1, #nodes)]
end

return Nyx.class("AiStateSeekHostage", AiStateSeekHostage, AiStateBase)
--}}}
