--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
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

--{{{ AiStateUseBoost
--- @class AiStateUseBoost : AiStateBase
--- @field acknowledgeTimer Timer
--- @field blacklist boolean[]
--- @field booster Player
--- @field boostNode NodeTypeBoost
--- @field boostTime number
--- @field boostTimer Timer
--- @field isReady boolean
--- @field isUsingBoost boolean
--- @field isWaiting boolean
--- @field waitNode NodeSpotWaitOnBoost
--- @field isOnBooster boolean
--- @field isJumped boolean
local AiStateUseBoost = {
    name = "Use Boost",
    requiredNodes = {
        Node.spotBoostCt,
        Node.spotBoostT,
    }
}

--- @param fields AiStateUseBoost
--- @return AiStateUseBoost
function AiStateUseBoost:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateUseBoost:__init()
    self.blacklist = {}
    self.boostTime = 16
    self.boostTimer = Timer:new()
    self.acknowledgeTimer = Timer:new()

    Callbacks.roundStart(function()
        self.boostTime = Math.getRandomFloat(6, 12)
        self.blacklist = {}

    	self:reset()
    end)
end

--- @return void
function AiStateUseBoost:assess()
    -- We've finished watching an angle.
    if self.boostTimer:isElapsedThenStop(self.boostTime) then
        self:reset()

        return AiPriority.IGNORE
    end

    if AiUtility.isBombPlanted() then
        return AiPriority.IGNORE
    end

    -- Exit so we can engage the enemy when they become visible.
    if AiUtility.isEnemyVisible then
        return AiPriority.IGNORE
    end

    if AiUtility.timeData.roundtime_remaining < 32 then
        return AiPriority.IGNORE
    end

    -- We have an active node.
    if self.boostNode then
        return AiPriority.USE_BOOST
    end

    if AiUtility.bombsitePlantAt then
        return AiPriority.IGNORE
    end

    if not AiUtility.closestTeammate or LocalPlayer:getOrigin():getDistance(AiUtility.closestTeammate:getOrigin()) > 1000 then
        return AiPriority.IGNORE
    end

    local node = self:getNode()

    if node then
        self.boostNode = node
        self.waitNode = node.waitNode

        return AiPriority.USE_BOOST
    end

    return AiPriority.IGNORE
end

--- @return NodeSpotBoostCt
function AiStateUseBoost:getNode()
    local clientOrigin = LocalPlayer:getOrigin()
    local nodeClass = LocalPlayer:isTerrorist() and Node.spotBoostT or Node.spotBoostCt
    -- Globally increase the weight of boost chances.
    local chanceMod = 2

    for _, node in pairs(Nodegraph.get(nodeClass)) do repeat
        if self.blacklist[node.id] then
            break
        end

        if clientOrigin:getDistance(node.floorOrigin) > 1200 then
            break
        end

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(node.floorOrigin) < 32 then
                self.blacklist[node.id] = true

                break
            end
        end

        local isEnemiesInFov = false

        for _, enemy in pairs(AiUtility.enemies) do
            local fov = node.direction:getFov(node.floorOrigin:clone():offset(0, 0, 128), enemy:getEyeOrigin())

            if fov < 35 then
                isEnemiesInFov = true

                break
            end
        end

        if not isEnemiesInFov then
            break
        end

        local chance = Math.getClamped(node.chance * chanceMod, 0, 100) * 0.01

        -- Blacklist the node for now.
        if not Math.getChance(chance) then
            self.blacklist[node.id] = true

            break
        end

        return node
    until true end
end

--- @return void
function AiStateUseBoost:activate()
    self.isWaiting = false
    self.isReady = false
    self.isJumped = false
    self.booster = nil

    Pathfinder.moveToNode(self.waitNode, {
        task = "Use boost wait on teammate"
    })
end

--- @return void
function AiStateUseBoost:deactivate()
    self:reset()
end

--- @return void
function AiStateUseBoost:reset()
    if self.boostNode then
        self.blacklist[self.boostNode.id] = true
    end

    self.boostNode = nil
    self.isUsingBoost = false

    self.boostTimer:stop()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateUseBoost:think(cmd)
    self.activity = "Waiting to be boosted"

    if not self.boostNode then
        self:reset()

        return
    end

    if self.booster and not self.booster:isAlive() then
        self:reset()

        return
    end

    -- This might cause the AI to die.
    self.ai.states.evade:block()

    local clientOrigin = LocalPlayer:getOrigin()
    local distanceToWaitNode = clientOrigin:getDistance(self.waitNode.origin)

    -- Look along wait node angles for human reasons.
    if distanceToWaitNode < 200 then
        VirtualMouse.lookAtLocation(self.waitNode.lookAtOrigin, 9, VirtualMouse.noise.idle, "Use boost look along wait node")
    end

    -- We're ready to be boosted.
    if distanceToWaitNode < 64 and not self.isReady then
        self.isReady = true

        self.ai.commands.boost:bark()
        self.acknowledgeTimer:start()
    end

    if not self.isReady then
        return
    end

    -- No booster yet.
    if not self.booster then
        -- We weren't acknowledged in a timely manner.
        if self.acknowledgeTimer:isElapsed(5) then
            self:reset()
        end

        return
    end

    -- The teammate never got to us in time.
    if not self.isWaiting and self.acknowledgeTimer:isElapsed(15) then
        self:reset()

        return
    end

    for _, teammate in pairs(AiUtility.teammates) do
        if not teammate:is(self.booster) and teammate:getOrigin():getDistance(self.waitNode.origin) < 16 then
            self:reset()

            return
        end
    end

    self.ai.routines.manageGear:block()

    LocalPlayer.equipAvailableWeapon()

    local teammateDistanceToBoostNode = self.booster:getOrigin():getDistance(self.boostNode.floorOrigin)

    if teammateDistanceToBoostNode < 32 and self.booster:isFlagActive(Player.flags.FL_DUCKING) then
        self.isWaiting = true
    end

    -- We're not ready to use the boost as the teammate isn't ready themselves.
    if not self.isWaiting then
        return
    end

    -- Teammate moved off the spot.
    if teammateDistanceToBoostNode > 32 then
        self:reset()

        return
    end

    Pathfinder.walk()
    Pathfinder.blockTeammateAvoidance()

    self.ai.routines.walk:block()
    self.ai.routines.handleGunfireAvoidance:block()
    self.ai.routines.manageWeaponScope:block()

    local boosterBounds = self.booster:getBounds()
    local jumpBounds = clientOrigin:getBounds(Vector3.align.UP, 18, 18, 32)
    local onBoosterBounds = clientOrigin:clone():offset(0, 0, -4):getBounds(Vector3.align.UP, 12, 12, 32)

    local isOnBooster = Vector3.isBoundsIntersecting(onBoosterBounds, boosterBounds)
    local isAbleToJump = Vector3.isBoundsIntersecting(jumpBounds, boosterBounds)

    -- Jump to get onto the booster's head.
    if isAbleToJump then
        Pathfinder.jump()
    end

    local boosterOrigin = self.booster:getOrigin()

    -- Move at the booster.
    if clientOrigin:getDistance2(boosterOrigin) > 6 then
        Pathfinder.moveAtAngle(clientOrigin:getAngle(boosterOrigin))
    end

    -- Look down the boost angle.
    VirtualMouse.lookAlongAngle(self.boostNode.direction, 12, VirtualMouse.noise.none, "Use boost look along boost node")

    if not isOnBooster then
        return
    end

    self.activity = "Watching from boost"

    if LocalPlayer:isTerrorist() then
        self.boostTimer:ifPausedThenStart()
    end

    LocalPlayer.scope()

    if not self.boostNode.isStandingHeight then
        Pathfinder.duck()
    end

    -- Jump to allow the booster to stand up.
    if not AiUtility.isEnemyVisible and self.boostNode.isStandingHeight and not self.isJumped then
        self.isJumped = true

        Client.fireAfter(0.4, function()
        	Pathfinder.jump()
        end)
    end
end

return Nyx.class("AiStateUseBoost", AiStateUseBoost, AiStateBase)
--}}}
