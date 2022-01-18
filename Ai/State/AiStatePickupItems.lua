--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePickupItems
--- @class AiStatePickupItems : AiState
--- @field item Entity
--- @field currentPriority number
--- @field useCooldown Timer
--- @field lookAtItem boolean
--- @field entityBlacklist boolean[]
local AiStatePickupItems = {
    name = "PickupItems"
}

--- @param fields AiStatePickupItems
--- @return AiStatePickupItems
function AiStatePickupItems:new(fields)
    return Nyx.new(self, fields)
end

--- @return nil
function AiStatePickupItems:__init()
    self.useCooldown = Timer:new():startThenElapse()
    self.entityBlacklist = {}

    Callbacks.roundStart(function()
        self.item = nil
        self.entityBlacklist = {}
    end)
end

--- @return nil
function AiStatePickupItems:assess()
    if self.item then
        return self.currentPriority
    end

    local player = AiUtility.client
    local origin = player:getOrigin()

    if player:isCounterTerrorist() and player:m_bHasDefuser() == 0 then
        self.item = self:getNearbyItems({Weapons.DEFUSER})

        if self.item then
            self.lookAtItem = false

            self.currentPriority = AiState.priority.PICKUP_DEFUSER

            return self.currentPriority
        end
    end

    --- @type Entity
    local mainWeapon
    local lowestPriority = math.huge

    for _, weapon in pairs(player:getWeapons()) do
        local priority = AiUtility.weaponPriority[weapon.classname]

        if priority and priority < lowestPriority then
            lowestPriority = priority
            mainWeapon = weapon
        end
    end

    if not mainWeapon then
        lowestPriority = 0
    end

    --- @type Entity
    local chosenWeapon
    local highestPriority = -1

    for _, weapon in Entity.find(AiUtility.weaponNames) do
        local priority = AiUtility.weaponPriority[weapon.classname]

        if not self.entityBlacklist[weapon.eid] and
            not weapon:m_hOwner()
            and weapon:isValid()
            and (priority and priority > highestPriority)
            and origin:getDistance(weapon:m_vecOrigin()) < 1024
        then
            highestPriority = priority
            chosenWeapon = weapon
        end
    end

    if chosenWeapon and highestPriority > lowestPriority then
        self.item = chosenWeapon
        self.lookAtItem = true

        self.currentPriority = AiUtility.isRoundOver and AiState.priority.ROUND_OVER_PICKUP_ITEMS or AiState.priority.PICKUP_WEAPON

        return self.currentPriority
    end

    return AiState.priority.IGNORE
end

--- @param items number[]
--- @return Entity
function AiStatePickupItems:getNearbyItems(items)
    local player = AiUtility.client
    local origin = player:getOrigin()

    for _, item in Entity.find(items) do repeat
        if self.entityBlacklist[item.eid] then
            break
        end

        if not item:isValid() then
            break
        end

        if item:m_hOwner() then
            break
        end

        local weaponOrigin = item:m_vecOrigin()

        if origin:getDistance(weaponOrigin) > 1024 or item:m_vecVelocity():getMagnitude() > 16 then
            break
        end

        local trace = Trace.getLineToPosition(Client.getEyeOrigin(), weaponOrigin, AiUtility.traceOptions)

        if trace.isIntersectingGeometry then
            break
        end

        return item
    until true end
end

--- @param ai AiOptions
--- @return nil
function AiStatePickupItems:activate(ai) end

--- @return nil
function AiStatePickupItems:deactivate()
    if self.item and self.item:m_hOwner() == Client.getEid() then
        Client.equipWeapon()
    end
end

--- @param ai AiOptions
--- @return nil
function AiStatePickupItems:think(ai)
    local owner = self.item:m_hOwnerEntity()
    local isDefuseKit = self.item.classname == "CEconEntity"

    if isDefuseKit and AiUtility.client:m_bHasDefuser() == 1 then
        self.item = nil

        return
    end

    if self.item:m_vecOrigin() == nil or owner then
        self.item = nil

        if Entity.getGameRules():m_bFreezePeriod() == 1 and owner == AiUtility.client.eid then
            ai.voice.pack:speakGratitude()
        end

        return
    end

    local player = AiUtility.client
    local origin = player:getOrigin()
    local weaponOrigin = self.item:m_vecOrigin()
    local distance = origin:getDistance(weaponOrigin)
    local trace = Trace.getLineInDirection(weaponOrigin, Vector3:new(0, 0, -1), AiUtility.traceOptions)
    local weaponDistanceToFloor = weaponOrigin:getDistance(trace.endPosition)

    if ai.nodegraph.pathfindFails > 2 and weaponDistanceToFloor < 10 then
        self.entityBlacklist[self.item.eid] = true

        self.item = nil

        return
    end

    if (ai.nodegraph:canPathfind() and ai.nodegraph.pathfindFails > 0) or (ai.nodegraph:canPathfind() and not ai.nodegraph.path) then
        ai.nodegraph:pathfind(self.item:m_vecOrigin(), {
            objective = Node.types.GOAL,
            ignore = Client.getEid(),
            task = "Picking up dropped weapon",
            onComplete = function()
                ai.nodegraph:log("At dropped weapon")
            end
        })
    end

    ai.view.canUseCheckNode = false

    if self.lookAtItem and distance < 200 then
        ai.view:lookAtLocation(weaponOrigin, 6.5)
    end

    if distance < 128 and self.useCooldown:isElapsedThenRestart(0.1) then
        ai.cmd.in_use = 1
    end
end

return Nyx.class("AiStatePickupItems", AiStatePickupItems, AiState)
--}}}
