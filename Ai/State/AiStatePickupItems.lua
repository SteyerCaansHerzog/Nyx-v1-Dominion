--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePickupItems
--- @class AiStatePickupItems : AiState
--- @field currentPriority number
--- @field entityBlacklist boolean[]
--- @field item Entity
--- @field lookAtItem boolean
--- @field recalculateItemsTimer Timer
--- @field useCooldown Timer
local AiStatePickupItems = {
    name = "PickupItems"
}

--- @param fields AiStatePickupItems
--- @return AiStatePickupItems
function AiStatePickupItems:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePickupItems:__init()
    self.useCooldown = Timer:new():startThenElapse()
    self.recalculateItemsTimer = Timer:new():startThenElapse()
    self.entityBlacklist = {}

    Callbacks.runCommand(function()
        if self.recalculateItemsTimer:isElapsedThenRestart(2) then
            self.item = nil
        end
    end)

    Callbacks.roundStart(function()
        self.item = nil
        self.entityBlacklist = {}
    end)

    Callbacks.itemRemove(function(e)
        self.item = nil
    end)

    Callbacks.itemPickup(function(e)
        Client.onNextTick(function()
            if e.player:isClient() then
                self.item = nil
            end
        end)
    end)
end

--- @return void
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

            self.currentPriority = AiPriority.PICKUP_DEFUSER

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
    local closestDistance = math.huge

    for _, weapon in Entity.find(AiUtility.weaponNames) do repeat
        -- Item is blacklisted due to being out of reach.
        if self.entityBlacklist[weapon.eid] then
            break
        end

        -- Entity isn't valid anymore.
        if not weapon:isValid() then
            break
        end

        -- Item has been picked up.
        if weapon:m_hOwner() then
            break
        end

        local priority = AiUtility.weaponPriority[weapon.classname]

        -- Item is not in our list of items worth picking up.
        if not priority then
            break
        end

        local distance = origin:getDistance(weapon:m_vecOrigin())

        -- Item is too far away.
        if distance > 1024 then
            break
        end

        if priority < highestPriority then
            -- Item is lower priority than the best item we've found.

            break
        elseif priority == highestPriority then
            -- Item is the same priority as the best item we've found.

            -- Item is closer to us, so it's better to want this one instead. Otherwise ignore it.
            if distance < closestDistance then
                closestDistance = distance
            else
                break
            end
        end

        highestPriority = priority
        chosenWeapon = weapon
    until true end

    -- We have an item we would like, and it's better than anything we have equipped.
    if chosenWeapon and highestPriority > lowestPriority then
        self.item = chosenWeapon
        self.lookAtItem = true

        self.currentPriority = AiUtility.isRoundOver and AiPriority.ROUND_OVER_PICKUP_ITEMS or AiPriority.PICKUP_WEAPON

        return self.currentPriority
    end

    return AiPriority.IGNORE
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

        local trace = Trace.getLineToPosition(Client.getEyeOrigin(), weaponOrigin, AiUtility.traceOptionsPathfinding)

        if trace.isIntersectingGeometry then
            break
        end

        return item
    until true end
end

--- @return void
function AiStatePickupItems:activate() end

--- @return void
function AiStatePickupItems:deactivate()
    if self.item and self.item:m_hOwnerEntity() == Client.getEid() then
        if AiUtility.client:hasPrimary() then
            Client.equipPrimary()
        else
            Client.equipPistol()
        end
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePickupItems:think(cmd)
    local weapon = CsgoWeapons[self.item:m_iItemDefinitionIndex()]

    if weapon then
        self.activity = string.format("Picking up %s", weapon.name)
    end

    local owner = self.item:m_hOwnerEntity()
    local isDefuseKit = self.item.classname == "CEconEntity"

    if isDefuseKit and AiUtility.client:m_bHasDefuser() == 1 then
        self.item = nil

        return
    end

    if self.item:m_vecOrigin() == nil or owner then
        self.item = nil

        if Entity.getGameRules():m_bFreezePeriod() == 1 and owner == AiUtility.client.eid then
            self.ai.voice.pack:speakGratitude()
        end

        return
    end

    local player = AiUtility.client
    local origin = player:getOrigin()
    local weaponOrigin = self.item:m_vecOrigin()
    local distance = origin:getDistance(weaponOrigin)
    local trace = Trace.getLineInDirection(weaponOrigin, Vector3:new(0, 0, -1), AiUtility.traceOptionsPathfinding)
    local weaponDistanceToFloor = weaponOrigin:getDistance(trace.endPosition)

    if self.ai.nodegraph.pathfindFails > 2 and weaponDistanceToFloor < 10 then
        self.entityBlacklist[self.item.eid] = true

        self.item = nil

        return
    end

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:pathfind(self.item:m_vecOrigin(), {
            objective = Node.types.GOAL,
            task = "Picking up dropped weapon",
            onComplete = function()
               self.ai.nodegraph:log("At dropped weapon")
            end
        })
    end

    if self.lookAtItem and distance < 250 then
       self.ai.view:lookAtLocation(weaponOrigin, 5, self.ai.view.noiseType.IDLE, "PickupItems look at item")
    end

    if distance < 128 and self.useCooldown:isElapsedThenRestart(0.1) then
        cmd.in_use = 1
    end
end

return Nyx.class("AiStatePickupItems", AiStatePickupItems, AiState)
--}}}
