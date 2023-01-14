--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
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
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateTeabag
--- @class AiStateTeabag : AiStateBase
--- @field enemyOriginsCache Vector3[]
--- @field teabagOrigin Vector3
--- @field duckTimer Timer
--- @field duckInterval number
--- @field duckHoldTime number
--- @field isAllowedToTeabag boolean
local AiStateTeabag = {
    name = "Teabag"
}

--- @param fields AiStateTeabag
--- @return AiStateTeabag
function AiStateTeabag:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateTeabag:__init()
    self.duckTimer = Timer:new():startThenElapse()
    self.duckInterval = 1
    self.duckHoldTime = 0.5

    Callbacks.roundStart(function()
    	self:reset()

        self.isAllowedToTeabag = Math.getChance(6)
    end)

    Callbacks.init(function()
        self.enemyOriginsCache = Table.populateForMaxPlayers(function()
            return Vector3:new()
        end)
    end)

    Callbacks.runCommand(function()
        for _, enemy in pairs(AiUtility.enemies) do
            self.enemyOriginsCache[enemy.eid] = enemy:getOrigin()
        end
    end)

    Callbacks.playerDeath(function(e)
        if not self.isAllowedToTeabag then
            return
        end

        if not e.attacker:isLocalPlayer() then
            return
        end

        if e.victim:isTeammate() then
            return
        end

        Client.fireAfter(0.1, function()
            if not AiUtility.isRoundOver then
                return
            end

            if AiUtility.enemiesAlive > 0 then
                return
            end

            self.teabagOrigin = self.enemyOriginsCache[e.victim.eid]
        end)
    end)
end

--- @return void
function AiStateTeabag:assess()
    return self.teabagOrigin and AiPriority.TEABAG_CORPSE or AiPriority.IGNORE
end

--- @return void
function AiStateTeabag:activate()
    Pathfinder.moveToLocation(self.teabagOrigin, {
        task = "Move to teabag corpse",
        onFailedToFindPath = function()
        	self.teabagOrigin = nil
        end
    })
end

--- @return void
function AiStateTeabag:deactivate()
    self:reset()
end

--- @return void
function AiStateTeabag:reset()
    self.teabagOrigin = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateTeabag:think(cmd)
    self.activity = "Going to teabag corpse"

    local distance = LocalPlayer:getOrigin():getDistance(self.teabagOrigin)

    if distance < 250 and distance > 32 then
        VirtualMouse.lookAtLocation(self.teabagOrigin, 6, VirtualMouse.noise.idle, "Teabag look at corpse")
    end

    if distance < 32 then
        self.activity = "Teabagging corpse"

        if self.duckTimer:isElapsed(self.duckInterval) then
            Pathfinder.duck()
        end

        if self.duckTimer:isElapsedThenRestart(self.duckInterval + self.duckHoldTime) then
            self.duckInterval = Math.getRandomFloat(0.6, 1.2)
            self.duckHoldTime = Math.getRandomFloat(0.33, 0.7)
        end
    end
end

return Nyx.class("AiStateTeabag", AiStateTeabag, AiStateBase)
--}}}
