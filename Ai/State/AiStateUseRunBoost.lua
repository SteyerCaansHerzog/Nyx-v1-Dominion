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
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateUseRunBoost
--- @class AiStateUseRunBoost : AiStateBase
--- @field acknowledgeTimer Timer
--- @field blacklist boolean[]
--- @field booster Player
--- @field boostNode NodeTypeBoost
--- @field isBlockedThisRound boolean
--- @field isJumped boolean
--- @field isOnBooster boolean
--- @field isReady boolean
--- @field isUsingBoost boolean
--- @field waitNode NodeSpotWaitOnBoost
local AiStateUseRunBoost = {
    name = "Use Run Boost",
    requiredNodes = {
        Node.spotRunBoostCt,
        Node.spotRunBoostT,
    }
}

--- @param fields AiStateUseRunBoost
--- @return AiStateUseRunBoost
function AiStateUseRunBoost:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateUseRunBoost:__init()
    self.blacklist = {}
    self.acknowledgeTimer = Timer:new()

    Callbacks.roundStart(function()
        self.blacklist = {}
        self.isBlockedThisRound = false

    	self:reset()
    end)
end

--- @return void
function AiStateUseRunBoost:assess()
    if self.isJumped then
        return AiPriority.USE_RUN_BOOST_COMMIT
    end

    if Config.isPlayingSolo then
        return AiPriority.IGNORE
    end

    if self.isBlockedThisRound then
        return AiPriority.IGNORE
    end

    if not MenuGroup.useChatCommands:get() then
        return AiPriority.IGNORE
    end

    if AiUtility.isLastAlive then
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
        return AiPriority.USE_RUN_BOOST
    end

    if AiUtility.plantedAtBombsite then
        return AiPriority.IGNORE
    end

    if not AiUtility.closestTeammate or LocalPlayer:getOrigin():getDistance(AiUtility.closestTeammate:getOrigin()) > 1000 then
        return AiPriority.IGNORE
    end

    local node = self:getNode()

    if node then
        self.boostNode = node
        self.waitNode = node.waitNode

        return AiPriority.USE_RUN_BOOST
    end

    return AiPriority.IGNORE
end

--- @return NodeSpotBoostCt
function AiStateUseRunBoost:getNode()
    local clientOrigin = LocalPlayer:getOrigin()
    local nodeClass = LocalPlayer:isTerrorist() and Node.spotRunBoostT or Node.spotRunBoostCt
    -- Globally increase the weight of boost chances.
    local chanceMod = 0.5

    for _, node in pairs(Nodegraph.get(nodeClass)) do repeat
        if self.blacklist[node.id] then
            break
        end

        if clientOrigin:getDistance(node.floorOrigin) > 900 then
            break
        end

        local isTeammateDisrupting = false

        for _, teammate in pairs(AiUtility.teammates) do
            local teammateDistance = teammate:getOrigin():getDistance(node.floorOrigin)

            if teammateDistance < 32 then
                isTeammateDisrupting = true

                break
            end

            if teammateDistance < 800 then
                local fov = node.direction:getFov(node.lookFromOrigin, teammate:getEyeOrigin())

                if fov < AiUtility.visibleFovThreshold then
                    isTeammateDisrupting = true

                    break
                end
            end
        end

        if isTeammateDisrupting then
            self.blacklist[node.id] = true

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
function AiStateUseRunBoost:activate()
    self.isUsingBoost = false
    self.isReady = false
    self.isJumped = false
    self.booster = nil

    Pathfinder.moveToNode(self.waitNode, {
        task = "Use boost wait on teammate"
    })
end

--- @return void
function AiStateUseRunBoost:deactivate()
    self:reset()
end

--- @return void
function AiStateUseRunBoost:reset()
    if self.boostNode then
        self.blacklist[self.boostNode.id] = true
    end

    self.boostNode = nil
    self.isUsingBoost = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateUseRunBoost:think(cmd)
    self.activity = "Waiting to be run-boosted"

    if self.isJumped and LocalPlayer:isFlagActive(Player.flags.FL_ONGROUND) then
        self:reset()

        return
    end

    self.ai.states.flashbangDynamic:block()

    if not self.boostNode then
        self:reset()

        return
    end

    if self.booster and not self.booster:isAlive() then
        self:reset()

        return
    end

    for _, teammate in pairs(AiUtility.teammates) do repeat
        if self.booster and teammate:is(self.booster) then
            break
        end

        if teammate:getOrigin():getDistance(self.waitNode.floorOrigin) < 32 then
            self:reset()

            return
        end
    until true end

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

        self.ai.commands.boost:bark("RunBoost")
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

    if not self.isUsingBoost then
        if self.acknowledgeTimer:isElapsed(15) then
            self:reset()

            return
        end

    end

    local teammateDistanceToBoostNode = self.booster:getOrigin():getDistance(self.boostNode.floorOrigin)

    if teammateDistanceToBoostNode < 32 and self.booster:isFlagActive(Player.flags.FL_DUCKING) then
        self.isUsingBoost = true
    end

    -- We're not ready to use the boost as the teammate isn't ready themselves.
    if not self.isJumped and not self.isUsingBoost then
        return
    end

    -- Teammate moved off the spot.
    if not self.isJumped and teammateDistanceToBoostNode > 32 then
        self:reset()

        return
    end

    if not self.isJumped then
        Pathfinder.walk()
    end

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
    local angleToTeammate = clientOrigin:getAngle(boosterOrigin)

    -- Move at the booster.
    if clientOrigin:getDistance2(boosterOrigin) > 6 then
        Pathfinder.moveAtAngle(angleToTeammate)
    end

    if not self.isJumped and not isOnBooster then
        return
    end

    self.ai.routines.manageGear:block()

    LocalPlayer.equipKnife()

    self.activity = "Getting run-boosted"

    -- Jump to allow the booster to stand up.
    if not AiUtility.isEnemyVisible and not self.isJumped then
        Client.fireAfter(0.4, function()
            self.isJumped = true

            Pathfinder.jump()
        end)
    end

    if not self.isJumped then
        return
    end

    -- We haven't finished the jump.
    if not LocalPlayer:isFlagActive(Player.flags.FL_ONGROUND) then
        return
    end

    VirtualMouse.lookAlongAngle(self.boostNode.direction, 12, VirtualMouse.noise.moving, "Use run boost look along boost node")
    Pathfinder.moveAtAngle(self.boostNode.direction, true)

    if LocalPlayer:m_vecVelocity():getMagnitude() > 220 then
        Pathfinder.isAirStrafeJump = false

        Pathfinder.jump()

        self:reset()
    end
end

return Nyx.class("AiStateUseRunBoost", AiStateUseRunBoost, AiStateBase)
--}}}
