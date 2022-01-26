--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
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
--- @field aimPunchAngles Angle
--- @field enabled boolean
--- @field isCrosshairFloating boolean
--- @field isCrosshairUsingVelocity boolean
--- @field isCrosshairSmoothed boolean
--- @field isViewLocked boolean
--- @field lastCameraAngles Angle
--- @field lastLookAtLocationOrigin Vector3
--- @field lookAtAngles Angle
--- @field lookSpeed number
--- @field lookSpeedModifier number
--- @field nodegraph Nodegraph
--- @field noiseAngles Angle
--- @field overrideViewAngles Angle
--- @field pitchSineModifier number
--- @field randomizerInterval number
--- @field randomizerTimer Timer
--- @field recoilControl number
--- @field targetViewAngles Angle
--- @field useCooldown Timer
--- @field velocity Angle
--- @field velocityBoundary number
--- @field velocityGainModifier number
--- @field velocityResetSpeed number
--- @field viewAngles Angle
--- @field viewPitchOffset number
--- @field yawSineModifier number
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
    self.aimPunchAngles = Angle:new(0, 0)
    self.isCrosshairFloating = true
    self.isCrosshairUsingVelocity = true
    self.lastCameraAngles = Client.getCameraAngles()
    self.lookAtAngles = Client.getCameraAngles()
    self.lookSpeed = 0
    self.lookSpeedModifier = 1.5
    self.noiseAngles = Angle:new()
    self.pitchSineModifier = 1
    self.randomizerInterval = 1.5
    self.randomizerTimer = Timer:new():start()
    self.recoilControl = 2
    self.useCooldown = Timer:new():start()
    self.velocity = Angle:new()
    self.velocityBoundary = 20
    self.velocityGainModifier = 0.6
    self.velocityResetSpeed = 100
    self.viewAngles = Client.getCameraAngles()
    self.viewPitchOffset = 0
    self.yawSineModifier = 1
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
    -- Match camera angles to AI view angles.
    if self.viewAngles then
        Client.setCameraAngles(self.lookAtAngles)
    end

    -- View angles we want to look at.
    -- It's overriden by AI behaviours, look ahead of the active path, or rest.
    --- @type Angle
    local idealViewAngles = Client.getCameraAngles()

    if self.overrideViewAngles then
        -- AI wants to look at something particular.
        self:setIdealOverride(idealViewAngles)
    elseif self.nodegraph.path then
        -- Perform generic look behaviour.
        self:setIdealLookAhead(idealViewAngles)
        self:setIdealCheckCorner(idealViewAngles)
    end

    --- @type Angle
    local targetViewAngles = idealViewAngles
    local cameraAngles = Client.getCameraAngles()

    -- Apply velocity on angles. Creates the effect of "over-shooting" the target point
    -- when moving the mouse far and fast.
    self:setTargetVelocity(targetViewAngles)

    -- Makes the crosshair float about.
    self:setTargetFloat(targetViewAngles)

    -- Makes the crosshair curve.
    self:setTargetCurve(targetViewAngles)

    if self.isCrosshairSmoothed then
        self.isCrosshairSmoothed = false
    else
        -- Prevent smoothing all the way down to 0 delta.
        if cameraAngles:getMaxDiff(targetViewAngles) < 0.5 then
            return
        end
    end

    -- Lerp the real view angles.
    self:interpolateViewAngles(targetViewAngles)
end

--- @param targetViewAngles Angle
--- @return void
function AiView:interpolateViewAngles(targetViewAngles)
    self:setRandomizers()

    targetViewAngles:__add(self.noiseAngles)
    targetViewAngles:normalize()

    self.viewAngles:lerp(targetViewAngles, math.min(20, self.lookSpeed * self.lookSpeedModifier)):normalize()
end

--- @param targetViewAngles Angle
--- @return void
function AiView:setTargetVelocity(targetViewAngles)
    if not self.isCrosshairUsingVelocity then
        self.isCrosshairUsingVelocity = true

        return
    end

    local cameraAngles = Client.getCameraAngles()

    -- Velocity increase is the difference between the last time we checked the camera angles and now.
    self.velocity = self.velocity + self.lastCameraAngles:getDiff(cameraAngles) * self.velocityGainModifier
    self.lastCameraAngles = cameraAngles

    -- Clamp the velocity within boundary.
    self.velocity.p = Math.clamp(self.velocity.p, -self.velocityBoundary, self.velocityBoundary)
    self.velocity.y = Math.clamp(self.velocity.y, -self.velocityBoundary, self.velocityBoundary)

    -- Reset the velocity to 0,0 over time.
    self.velocity:approach(Angle:new(), self.velocityResetSpeed)

    -- Velocity sine. This should make the over-swing become non-parallel to the aim target.
    local velocitySine = Angle:new(Animate.float(0, Math.clamp(self.velocity:getMagnitude() * 0.5, -8, 8), 1), 0)

    targetViewAngles:setFromAngle(targetViewAngles + (self.velocity + velocitySine))
end

--- @param targetViewAngles Angle
--- @return void
function AiView:setTargetCurve(targetViewAngles)
    -- Sine wave float the angles.
    local floatPitch = Animate.float(0, 50, 5)
    local floatYaw = Animate.float(0, 50, 2)

    -- Get the absolute difference of the angles.
    local deltaPitch = math.abs(targetViewAngles.p - self.viewAngles.p)
    local deltaYaw = math.abs(targetViewAngles.p - self.viewAngles.p)

    -- Scale the floating effect based on the difference.
    local modPitch = Math.clamp(Math.pct(deltaPitch, 180), 0, 1)
    local modYaw = Math.clamp(Math.pct(deltaYaw, 50), 0, 1)

    targetViewAngles:set(
        targetViewAngles.p + floatPitch * modPitch,
        targetViewAngles.y + floatYaw * modYaw
    )
end

--- @param targetViewAngles Angle
--- @return void
function AiView:setTargetFloat(targetViewAngles)
    -- Float the angles.
    local pitchSine = Animate.float(0, 1 * self.pitchSineModifier, 1 * self.pitchSineModifier)
    local yawSine = Animate.float(0, 2 * self.yawSineModifier, 1 * self.yawSineModifier)

    targetViewAngles:set(
        targetViewAngles.p + pitchSine,
        targetViewAngles.y + yawSine
    )
end

--- @return void
function AiView:setRandomizers()
    if Entity.getGameRules():m_bFreezePeriod() == 1 or not self.isCrosshairFloating then
        self.isCrosshairFloating = true
        self.yawSineModifier = 0
        self.pitchSineModifier = 0

        self.noiseAngles:set(0, 0)

        return
    end

    if self.randomizerTimer:isElapsedThenRestart(self.randomizerInterval) then
        self.randomizerInterval = Client.getRandomFloat(0.75, 2)

        self.noiseAngles:set(Client.getRandomFloat(-1, 2.25), Client.getRandomFloat(-2, 2))

        self.pitchSineModifier = Client.getRandomFloat(-1.5, 1.5)
        self.yawSineModifier = Client.getRandomFloat(-4, 4)
    end
end

--- @param idealViewAngles Angle
--- @return void
function AiView:setIdealOverride(idealViewAngles)
    idealViewAngles:setFromAngle(self.overrideViewAngles)
end

--- @param idealViewAngles Angle
--- @return void
function AiView:setIdealLookAhead(idealViewAngles)
    --- @type Node
    local lookAheadNode

    -- How far in the path to look ahead.
    local lookAheadTo = 3

    -- Select a node ahead in the path, and look closer until we find a valid node.
    while not lookAheadNode and lookAheadTo > 0 do
        lookAheadNode = self.nodegraph.path[self.nodegraph.pathCurrent + lookAheadTo]

        lookAheadTo = lookAheadTo - 1
    end

    -- A valid node was found
    if not lookAheadNode then
        return
    end

    local lookOrigin = lookAheadNode.origin:clone()

    -- Goal nodes that were based on other nodes' origins are +18z higher than they should be, so correct this.
    if lookAheadNode.type == Node.types.GOAL then
        lookOrigin:offset(0, 0, -18)
    end

    -- We want to look roughly head height of the goal.
    lookOrigin:offset(0, 0, 46)

    -- Set look speed so we don't use the speed set by AI behaviour.
    self.lookSpeed = 2.25

    -- Generate our look ahead view angles.
    idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(lookOrigin))
end

--- @param idealViewAngles Angle
--- @return void
function AiView:setIdealCheckCorner(idealViewAngles)
    local player = AiUtility.client
    local clientOrigin = player:getOrigin()
    local closestCheckNode = self.nodegraph:getClosestNodeOf(clientOrigin, Node.types.CHECK)

    -- The AI isn't near enough to a check node to use one.
    if not closestCheckNode or clientOrigin:getDistance(closestCheckNode.origin) > 200 then
        return
    end

    local isEnemyActivatingCheck = false
    local clientEyeOrigin = Client.getEyeOrigin()
    local checkOrigin = closestCheckNode.origin:clone():offset(0, 0, 46)
    local checkDirection = closestCheckNode.direction
    local trace = Trace.getLineAtAngle(checkOrigin, checkDirection, AiUtility.traceOptions)
    local checkNearOrigin = trace.endPosition

    -- Find an enemy matching the check node's criteria.
    for _, enemy in pairs(AiUtility.enemies) do
        if enemy:getOrigin():getDistance(checkNearOrigin) < 256 then
            isEnemyActivatingCheck = true

            break
        end
    end

    -- We should use the check node.
    if isEnemyActivatingCheck then
        local cameraAngles = Client.getCameraAngles()
        local diff = cameraAngles:getMaxDiff(closestCheckNode.direction)

        -- Prevent the AI looking when its velocity is low, or the AI is facing well away from the check node.
        if player:m_vecVelocity():getMagnitude() > 100 and diff < 135 then
            -- Find the point that the check node is looking at.
            local trace = Trace.getLineAtAngle(checkOrigin, closestCheckNode.direction, AiUtility.traceOptions)

            -- Set look speed so we don't use the speed set by AI behaviour.
            self.lookSpeed = 4.5

            idealViewAngles:setFromAngle(clientEyeOrigin:getAngle(trace.endPosition))
        end
    end
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

    -- Don't set view angles during warmup. The bots look in random directions. People keep noticing it.
    if Entity.getGameRules():m_bWarmupPeriod() == 1 then
        return
    end

    local player = AiUtility.client
    local origin = player:getOrigin()
    local aimPunchAngles = player:m_aimPunchAngle()
    local correctedViewAngles = self.viewAngles:clone()

    self.aimPunchAngles = self.aimPunchAngles + (aimPunchAngles - self.aimPunchAngles) * 20 * Time.getDelta()

    correctedViewAngles = (correctedViewAngles - self.aimPunchAngles * self.recoilControl):normalize()

    self.lookAtAngles = correctedViewAngles
    cmd.pitch = correctedViewAngles.p
    cmd.yaw = correctedViewAngles.y

    self.overrideViewAngles = nil
    self.isViewLocked = false

    -- Shoot out cover
    local shootNode = self.nodegraph:getClosestNodeOf(origin, {Node.types.SHOOT, Node.types.CROUCH_SHOOT})

    if shootNode and origin:getDistance(shootNode.origin) < 48 then
        local yawDelta = math.abs(shootNode.direction.y - correctedViewAngles.y)

        if yawDelta < 135 and self:isPlayerBlocked(shootNode) then
            self.overrideViewAngles = shootNode.direction
            self.lookSpeed = 4
            self.isViewLocked = true

            if yawDelta < 15 then
                cmd.in_attack = 1
            end
        end
    end

    -- Use doors
    local node = self.nodegraph:getClosestNodeOf(origin, Node.types.DOOR)

    if node and origin:getDistance(node.origin) < 128 then
        local yawDelta = math.abs(node.direction.y - correctedViewAngles.y)

        if yawDelta < 135 and self:isPlayerBlocked(node) then
            self.overrideViewAngles = node.direction
            self.lookSpeed = 4
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
function AiView:lookAtLocation(origin, speed)
    if self.isViewLocked then
        return
    end

    self.overrideViewAngles = Client.getEyeOrigin():getAngle(origin)
    self.lookSpeed = speed
    self.lastLookAtLocationOrigin = origin
end

--- @param angle Angle
--- @param speed number
--- @return void
function AiView:lookInDirection(angle, speed)
    if self.isViewLocked then
        return
    end

    self.overrideViewAngles = angle
    self.lookSpeed = speed
    self.lastLookAtLocationOrigin = nil
end

--- @param node Node
--- @return boolean
function AiView:isPlayerBlocked(node)
    local playerOrigin = AiUtility.client:getOrigin()
    local collisionOrigin = playerOrigin + Client.getCameraAngles():getForward() * 25
    local collisionBounds = collisionOrigin:getBounds(Vector3.align.CENTER, 48, 48, 256)

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
