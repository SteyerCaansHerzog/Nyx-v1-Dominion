--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
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
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateChickenInteraction
--- @class AiStateChickenInteraction : AiStateBase
--- @field targetChicken Entity
--- @field cooldownTimer Timer
--- @field blacklist boolean[]
--- @field interaction string
local AiStateChickenInteraction = {
    name = "Chicken Interaction",
    delayedMouseMin = 0.1,
    delayedMouseMax = 0.3
}

--- @param fields AiStateChickenInteraction
--- @return AiStateChickenInteraction
function AiStateChickenInteraction:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateChickenInteraction:__init()
    self.blacklist = {}
    self.cooldownTimer = Timer:new():startThenElapse()
    self.interaction = Table.getRandom({
        "kill", "collect"
    })

    Callbacks.levelInit(function()
        self.interaction = Table.getRandom({
            "kill", "collect"
        })
    end)

    Callbacks.roundStart(function()
    	self.blacklist = {}
    end)
end

--- @return void
function AiStateChickenInteraction:assess()
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return AiPriority.IGNORE
    end

    if not LocalPlayer:isHoldingKnife() then
        self.targetChicken = nil

        return AiPriority.IGNORE
    end

    if AiUtility.plantedBomb then
        self.targetChicken = nil

        return AiPriority.IGNORE
    end

    if not self.cooldownTimer:isElapsed(4) then
        return AiPriority.IGNORE
    end

    if self.targetChicken then
        return AiPriority.INTERACT_WITH_CHICKEN
    end

    --- @type Entity
    local closestChicken
    local closestChickenDistance = math.huge
    local playerOrigin = LocalPlayer:getOrigin()

    for _, chicken in Entity.find("CChicken") do
        if not self.blacklist[chicken.eid] then
            local chickenOrigin = chicken:m_vecOrigin()
            local distance = playerOrigin:getDistance(chickenOrigin)
            local fov = LocalPlayer.getCameraAngles():getFov(LocalPlayer.getEyeOrigin(), chickenOrigin)

            if fov < 40 and distance < 300 and distance < closestChickenDistance then
                closestChicken = chicken
                closestChickenDistance = distance
            end
        end
    end

    if not closestChicken then
        return AiPriority.IGNORE
    end

    self.targetChicken = closestChicken

    return AiPriority.INTERACT_WITH_CHICKEN
end

--- @return void
function AiStateChickenInteraction:activate()
    if not self.targetChicken then
        self:reset()

        return
    end

    self:move()
end

--- @return void
function AiStateChickenInteraction:deactivate()
    self.targetChicken = nil
end

--- @return void
function AiStateChickenInteraction:reset()
    self.targetChicken = nil

    self.cooldownTimer:restart()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateChickenInteraction:think(cmd)
    if self.interaction == "kill" then
        self.activity = "Intercepting hostile poultry"
    elseif self.interaction == "collect" then
        self.activity = "Picking up birds"
    end

    if not LocalPlayer:isHoldingKnife() then
        self:reset()

        return
    end

    local chickenOrigin = self.targetChicken:m_vecOrigin()

    if not chickenOrigin or chickenOrigin:isZero() then
        self:reset()

        return
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local distance = clientOrigin:getDistance(chickenOrigin)

    if distance > 500 then
        self:reset()

        return
    end

    if AiUtility.closestTeammate and clientOrigin:getDistance(AiUtility.closestTeammate:getOrigin()) < 80 then
        self:reset()

        return
    end

    if distance < 200 then
        View.lookAtLocation(chickenOrigin, 5.5, View.noise.minor, "ChickenInteraction look at chicken")
    end

    local fov = LocalPlayer.getCameraAngles():getFov(LocalPlayer.getEyeOrigin(), chickenOrigin)

    if distance < 64 and fov < 22 then
        self.ai.routines.lookAwayFromFlashbangs:block()
        self.ai.routines.manageGear:block()
        self.ai.routines.manageWeaponReload:block()

        if self.interaction == "kill" then
            cmd.in_attack = true
        elseif self.interaction == "collect" then
            cmd.in_use = true
        end

        self.blacklist[self.targetChicken.eid] = true

        self:reset()
    end

    if Pathfinder.isIdle() then
        self:move()
    end
end

--- @return void
function AiStateChickenInteraction:move()
    local task

    if self.interaction == "kill" then
        task = "Intercept hostile poultry"
    elseif self.interaction == "collect" then
        task = "Pick up birds"
    end

    Pathfinder.moveToLocation(self.targetChicken:m_vecOrigin():clone():offset(0, 0, 30), {
        task = task,
        onFailedToFindPath = function()
            if self.targetChicken then
                self.blacklist[self.targetChicken.eid] = true
            end

            self.targetChicken = nil
        end
    })
end

return Nyx.class("AiStateChickenInteraction", AiStateChickenInteraction, AiStateBase)
--}}}
