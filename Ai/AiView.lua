--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiView
--- @class AiView : Class
--- @field enabled boolean
--- @field viewAngles Angle
--- @field targetViewAngles Angle
--- @field noiseAngles Angle
--- @field noiseTimer Timer
--- @field noiseInterval number
--- @field lookSpeed number
--- @field lookSpeedModifier number
--- @field overrideViewAngles Angle
--- @field nodegraph Nodegraph
--- @field aimPunchAngles Angle
--- @field lookAtAngles Angle
--- @field recoilControl number
--- @field useCooldown Timer
--- @field isViewLocked boolean
--- @field canUseCheckNode boolean
local AiView = {}

--- @param fields AiView
--- @return AiView
function AiView:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiView:__init()
    self:initFields()
    self:initEvents()
end

--- @return void
function AiView:initFields()
    self.viewAngles = Client.getCameraAngles()
    self.noiseAngles = Angle:new()
    self.noiseTimer = Timer:new():start()
    self.noiseInterval = 0
    self.lookSpeed = 0
    self.lookSpeedModifier = 1
    self.aimPunchAngles = Angle:new(0, 0)
    self.lookAtAngles = Client.getCameraAngles()
    self.recoilControl = 2
    self.useCooldown = Timer:new():start()
end

--- @return void
function AiView:initEvents()
    Callbacks.frame(function()
        if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableView:get() then
            return
        end

        if not self.enabled then
            return
        end

        self:setViewAngles()
    end)
end

--- @return void
function AiView:setViewAngles()
    if self.viewAngles then
        Client.setCameraAngles(self.lookAtAngles)
    end

    local targetViewAngles

    if self.overrideViewAngles then
        targetViewAngles = self.overrideViewAngles
    elseif self.nodegraph.path then
        --- @type Node
        local node
        local i = 4

        while not node and i > 0 do
            node = self.nodegraph.path[self.nodegraph.pathCurrent + i]

            i = i - 1
        end

        if self.noiseTimer:isElapsedThenRestart(self.noiseInterval) then
            if not self.overrideViewAngles then
                self.lookSpeed = Client.getRandomFloat(2, 5)
            end
        end

        if node then
            local origin = node.origin

            if node.type == Node.types.GOAL then
                origin = origin:clone():offset(0, 0, -18)
            end

            local lookAt = origin:clone():offset(0, 0, 46)

            targetViewAngles = Client.getEyeOrigin():getAngle(lookAt) + self.noiseAngles

            self.targetViewAngles = targetViewAngles
        elseif self.targetViewAngles then
            targetViewAngles = self.targetViewAngles
        end
    end

    if self.canUseCheckNode then
        local player = Player.getClient()
        local origin = player:getOrigin()
        local closestCheckNode = self.nodegraph:getClosestNodeOf(origin, Node.types.CHECK)

        if closestCheckNode and origin:getDistance(closestCheckNode.origin) < 150 then
            local isEnemyNearby = false
            local eyeOrigin = Client.getEyeOrigin()
            local lookOrigin = closestCheckNode.origin:clone():offset(0, 0, 46)
            local lookAtOrigin = lookOrigin:getTraceLine(lookOrigin + closestCheckNode.direction:getForward() * Vector3.MAX_DISTANCE,
                Client.getEid())

            for _, enemy in pairs(AiUtility.enemies) do
                if enemy:getOrigin():getDistance(lookAtOrigin) < 512 then
                    isEnemyNearby = true
                end
            end

            if isEnemyNearby then
                local cameraAngles = Client.getCameraAngles()
                local yawDelta = math.abs(closestCheckNode.direction.y - cameraAngles.y)

                if player:m_vecVelocity():getMagnitude() > 100 and yawDelta < 135 then
                    targetViewAngles = eyeOrigin:getAngle(lookAtOrigin)
                end
            end
        end
    end

    self.canUseCheckNode = true

    if not targetViewAngles then
        return
    end

    self.viewAngles:lerp(targetViewAngles, math.min(20, self.lookSpeed * self.lookSpeedModifier))

    self.lookSpeedModifier = 1.66
end

--- @param cmd SetupCommandEvent
--- @return void
function AiView:think(cmd)
    if not self.enabled then
        return
    end

    if not self.viewAngles then
        return
    end

    local player = Player.getClient()
    local origin = player:getOrigin()
    local aimPunchAngles = player:m_aimPunchAngle()
    local lookAtAngles = self.viewAngles:clone()

    self.aimPunchAngles = self.aimPunchAngles + (aimPunchAngles - self.aimPunchAngles) * 8 * Time.delta()

    lookAtAngles = (lookAtAngles - self.aimPunchAngles * self.recoilControl):normalize()

    self.lookAtAngles = lookAtAngles
    cmd.pitch = lookAtAngles.p
    cmd.yaw = lookAtAngles.y

    self.overrideViewAngles = nil
    self.isViewLocked = false

    -- Shoot out cover
    local shootNode = self.nodegraph:getClosestNodeOf(origin, {Node.types.SHOOT, Node.types.CROUCH_SHOOT})

    if shootNode and origin:getDistance(shootNode.origin) < 32 then
        local yawDelta = math.abs(shootNode.direction.y - lookAtAngles.y)

        if yawDelta < 135 and self:isPlayerBlocked(shootNode) then
            self.overrideViewAngles = shootNode.direction
            self.lookSpeed = 10
            self.isViewLocked = true

            if yawDelta < 15 then
                cmd.in_attack = 1
            end
        end
    end

    -- Use doors
    local node = self.nodegraph:getClosestNodeOf(origin, Node.types.DOOR)

    if node and origin:getDistance(node.origin) < 64 then
        local yawDelta = math.abs(node.direction.y - lookAtAngles.y)

        if yawDelta < 135 and self:isPlayerBlocked(node) then
            self.overrideViewAngles = node.direction
            self.lookSpeed = 10
            self.isViewLocked = true

            if self.useCooldown:isElapsedThenRestart(0.33) and yawDelta < 15 then
                cmd.in_use = 1
            end
        end
    end
end

--- @param origin Vector3
--- @param speed number
--- @return void
function AiView:lookAt(origin, speed)
    if self.isViewLocked then
        return
    end

    self.overrideViewAngles = Client.getEyeOrigin():getAngle(origin)
    self.lookSpeed = speed
end

--- @param angle Angle
--- @param speed number
--- @return void
function AiView:look(angle, speed)
    if self.isViewLocked then
        return
    end

    self.overrideViewAngles = angle
    self.lookSpeed = speed
end

--- @param node Node
--- @return boolean
function AiView:isPlayerBlocked(node)
    local playerOrigin = Player.getClient():getOrigin()
    local collisionOrigin = playerOrigin + Client.getCameraAngles():getForward() * 16
    local collisionBounds = collisionOrigin:getBounds(48, 48, 128, Vector3.align.BOTTOM)

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():offset(0, 0, 36):isInBounds(collisionBounds) then
            return false
        end
    end

    local nodeOrigin = node.origin:clone():offset(0, 0, 36)
    local offset = nodeOrigin + node.direction:getForward() * 48

    local _, fraction = nodeOrigin:getTraceLine(offset, Client.getEid())

    if fraction ~= 1 then
        return true
    end

    return false
end

return Nyx.class("AiView", AiView)
--}}}
