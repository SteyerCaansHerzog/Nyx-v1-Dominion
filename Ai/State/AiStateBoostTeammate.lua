--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
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

--{{{ AiStateBoostTeammate
--- @class AiStateBoostTeammate : AiStateBase
--- @field boostNode NodeTypeBoost
--- @field boostOrigin Vector3
--- @field boostPlayer Player
--- @field isBoosting boolean
--- @field isRequesterBot boolean
--- @field isRunBoosting boolean
local AiStateBoostTeammate = {
    name = "Boost Teammate"
}

--- @param fields AiStateBoostTeammate
--- @return AiStateBoostTeammate
function AiStateBoostTeammate:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateBoostTeammate:__init()
    Callbacks.roundFreezeEnd(function()
    	self:reset()
    end)
end

--- @return number
function AiStateBoostTeammate:assess()
    if AiUtility.isBombPlanted() then
        return AiPriority.IGNORE
    end

    if self.boostPlayer then
        if LocalPlayer:getOrigin():getDistance2(self.boostPlayer:getOrigin()) < 256 then
            return AiPriority.BOOST_ACTIVE
        end

        return AiPriority.BOOST_PASSIVE
    end

    return AiPriority.IGNORE
end

--- @param player Player
--- @param origin Vector3
--- @param boostType string
--- @return void
function AiStateBoostTeammate:boost(player, origin, boostType, isRequesterBot)
    if isRequesterBot then
        local node = self:getNodeClass(boostType)
        local closestNode = Nodegraph.getClosest(player:getOrigin(), node)

        origin = closestNode.floorOrigin

        self.boostNode = closestNode
    end

    self.boostPlayer = player
    self.boostOrigin = origin
    self.isRunBoosting = boostType == "RunBoost"
    self.isRequesterBot = isRequesterBot
end

--- @param boostType string
--- @return NodeTypeBoost
function AiStateBoostTeammate:getNodeClass(boostType)
    if boostType == "NormalBoost" then
        return LocalPlayer:isTerrorist() and Node.spotBoostT or Node.spotBoostCt
    end

    if boostType == "OntoPositionBoost" then
        return LocalPlayer:isTerrorist() and Node.spotOntoPositionBoostStartT or Node.spotOntoPositionBoostStartCt
    end

    if boostType == "RunBoost" then
        return LocalPlayer:isTerrorist() and Node.spotRunBoostT or Node.spotRunBoostCt
    end
end

--- @return void
function AiStateBoostTeammate:activate()
    Pathfinder.moveToLocation(self.boostOrigin, {
        task = string.format("Boost %s", self.boostPlayer:getName()),
        isCounterStrafingOnGoal = true,
        goalReachedRadius = 6,
        onFailedToFindPath = function()
        	self:reset()
        end
    })

    self.ai.commands.boost.isTaken = false
end

--- @return void
function AiStateBoostTeammate:deactivate()
    self:reset()
end

--- @return void
function AiStateBoostTeammate:reset()
    self.boostPlayer = nil
    self.boostOrigin = nil
    self.boostNode = nil
    self.isBoosting = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateBoostTeammate:think(cmd)
    self.activity = "Going to boost teammate"

    if not self.boostPlayer or not self.boostPlayer:isAlive() then
        self:reset()

        return
    end

    local playerOrigin = LocalPlayer:getOrigin()
    local originDistance = playerOrigin:getDistance2(self.boostOrigin)
    local senderDistance = playerOrigin:getDistance(self.boostPlayer:getOrigin())

    if self.isBoosting and senderDistance > 128 then
        self:reset()

        return
    end

    if originDistance < 200 then
        self.activity = "Waiting to boost teammate"

        if self.boostNode then
            VirtualMouse.lookAlongAngle(self.boostNode.direction, 6, VirtualMouse.noise.none, "Boost teammate look along boost")
        end
    end

    local isRunBoostReady = true

    if senderDistance < 32 and originDistance < 32 then
        Pathfinder.blockTeammateAvoidance()
    end

    if senderDistance < 250 and originDistance < 50 then
        self.ai.routines.lookAwayFromFlashbangs:block()
        self.ai.states.evade:block()

        local bounds = playerOrigin:clone():offset(0, 0, 32):getBounds(Vector3.align.BOTTOM, 25, 25, 128)

        if originDistance < 64 and not self.boostPlayer:getOrigin():offset(0, 0, 48):isInBounds(bounds) then
            if senderDistance < 250 then
                Pathfinder.duck()

                isRunBoostReady = false
            end
        end
    end

    if self.isBoosting and self.isRunBoosting and isRunBoostReady and self.boostPlayer:isFlagActive(Player.flags.FL_ONGROUND) then
        local origin = self.boostPlayer:getOrigin() + self.boostPlayer:m_vecVelocity() * 0.5

        if playerOrigin:getDistance2(origin) > 30 then
            local angle = playerOrigin:getAngle(origin)

            Pathfinder.moveAtAngle(angle, true)
        end
    end

    if originDistance < 64 and senderDistance < 72 then
        self.activity = "Boosting teammate"
        self.isBoosting = true
    end

    Pathfinder.ifIdleThenRetryLastRequest()
end

return Nyx.class("AiStateBoostTeammate", AiStateBoostTeammate, AiStateBase)
--}}}
