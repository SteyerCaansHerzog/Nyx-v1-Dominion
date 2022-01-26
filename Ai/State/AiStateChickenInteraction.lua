--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateChickenInteraction
--- @class AiStateChickenInteraction : AiState
--- @field targetChicken Entity
--- @field cooldownTimer Timer
--- @field blacklist boolean[]
--- @field interaction string
local AiStateChickenInteraction = {
    name = "Chicken Interaction"
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
    self.interaction = Client.getChance(2) and "kill" or "collect"

    Callbacks.levelInit(function()
        self.interaction = Client.getChance(2) and "kill" or "collect"
    end)

    Callbacks.roundStart(function()
    	self.blacklist = {}
    end)
end

--- @return void
function AiStateChickenInteraction:assess()
    if Entity.getGameRules():m_bFreezePeriod() == 1 then
        return AiState.priority.IGNORE
    end

    if AiUtility.plantedBomb then
        return AiState.priority.IGNORE
    end

    if not self.cooldownTimer:isElapsed(4) then
        return AiState.priority.IGNORE
    end

    if self.targetChicken then
        return AiState.priority.INTERACT_WITH_CHICKEN
    end

    if not AiUtility.client:isHoldingKnife() then
        self.targetChicken = nil

        return AiState.priority.IGNORE
    end

    --- @type Entity
    local closestChicken
    local closestChickenDistance = math.huge
    local playerOrigin = AiUtility.client:getOrigin()

    for _, chicken in Entity.find("CChicken") do
        if not self.blacklist[chicken.eid] then
            local chickenOrigin = chicken:m_vecOrigin()
            local distance = playerOrigin:getDistance(chickenOrigin)
            local fov = Client.getCameraAngles():getFov(Client.getEyeOrigin(), chickenOrigin)

            if fov < 40 and distance < 300 and distance < closestChickenDistance then
                closestChicken = chicken
                closestChickenDistance = distance
            end
        end
    end

    if not closestChicken then
        return AiState.priority.IGNORE
    end

    self.targetChicken = closestChicken

    return AiState.priority.INTERACT_WITH_CHICKEN
end

--- @param ai AiOptions
--- @return void
function AiStateChickenInteraction:activate(ai) end

--- @return void
function AiStateChickenInteraction:deactivate()
    self.targetChicken = nil
end

--- @return void
function AiStateChickenInteraction:reset()
    self.targetChicken = nil

    self.cooldownTimer:restart()
end

--- @param ai AiOptions
--- @return void
function AiStateChickenInteraction:think(ai)
    if not AiUtility.client:isHoldingKnife() then
        self:reset()

        return
    end

    local chickenOrigin = self.targetChicken:m_vecOrigin()

    if not chickenOrigin or chickenOrigin:isZero() then
        self:reset()

        return
    end

    if ai.nodegraph:canPathfind() and not ai.nodegraph.path then
        ai.nodegraph:pathfind(self.targetChicken:m_vecOrigin(), {
            objective = Node.types.ENEMY,
            retry = false,
            ignore = Client.getEid(),
            task = string.format("Go to chicken (%s)", self.interaction),
            onFail = function()
                self.blacklist[self.targetChicken.eid] = true

                self.targetChicken = nil
            end
        })
    end

    local playerOrigin = AiUtility.client:getOrigin()
    local distance = playerOrigin:getDistance(chickenOrigin)

    if distance > 500 then
        self:reset()

        return
    end

    if distance < 200 then
        ai.view:lookAtLocation(chickenOrigin, 5.5)
    end

    local fov = Client.getCameraAngles():getFov(Client.getEyeOrigin(), chickenOrigin)

    if distance < 64 and fov < 22 then
        ai.controller.canLookAwayFromFlash = false
        ai.controller.canUseGear = false
        ai.controller.canReload = false

        if self.interaction == "kill" then
            ai.cmd.in_attack = 1
        elseif self.interaction == "collect" then
            ai.cmd.in_use = 1
        end

        self.blacklist[self.targetChicken.eid] = true

        self:reset()
    end
end

return Nyx.class("AiStateChickenInteraction", AiStateChickenInteraction, AiState)
--}}}
