--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
local WeaponInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/WeaponInfo"
--}}}

--{{{ AiStatePickupItems
--- @class AiStatePickupItems : AiStateBase
--- @field currentPriority number
--- @field entityBlacklist boolean[]
--- @field item Entity
--- @field lookAtItem boolean
--- @field recalculateItemsTimer Timer
--- @field useCooldown Timer
--- @field watchDropsFrom Player[]
--- @field watchedItems table<number, table<number, Entity>>
local AiStatePickupItems = {
    name = "Pickup Items",
    delayedMouseMin = 0,
    delayedMouseMax = 0.2
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
    self.watchDropsFrom = {}

    Callbacks.setupCommand(function()
        if self.recalculateItemsTimer:isElapsedThenRestart(2) then
            self.item = nil
        end

        for _, teammate in pairs(self.watchDropsFrom) do
            local weapons = teammate:getWeapons()

            if not self.watchedItems[teammate.eid] then
                self.watchedItems[teammate.eid] = {}
            end

            for _, weapon in pairs(weapons) do
                self.watchedItems[teammate.eid][weapon.eid] = weapon
            end

            for _, weapon in pairs(self.watchedItems[teammate.eid]) do
                if weapon:m_hOwner() ~= teammate.eid and not self.entityBlacklist[weapon.eid] then
                    self.entityBlacklist[weapon.eid] = true

                    self.watchDropsFrom[teammate.eid] = nil

                    Client.fireAfter(20, function()
                        self.entityBlacklist[weapon.eid] = nil
                    end)
                end
            end
        end
    end)

    Callbacks.roundPrestart(function()
        self.item = nil
        self.entityBlacklist = {}
        self.watchDropsFrom = {}
        self.watchedItems = {}
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

    Callbacks.itemRemove(function(e)
        if not self.watchDropsFrom[e.player.eid] then
            return
        end
    end)
end

--- @return void
function AiStatePickupItems:assess()
    if self.item then
        return self.currentPriority
    end

    local origin = LocalPlayer:getOrigin()

    if LocalPlayer:isCounterTerrorist() and LocalPlayer:m_bHasDefuser() == 0 then
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

    for _, weapon in pairs(LocalPlayer:getWeapons()) do
        local priority = WeaponInfo.dispositions[weapon.classname]

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

    for _, weapon in Entity.find(WeaponInfo.classnames) do repeat
        -- Item is blacklisted.
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

        local priority = WeaponInfo.dispositions[weapon.classname]

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

        local priority = AiPriority.PICKUP_WEAPON

        if not LocalPlayer:hasPrimary() then
            priority = AiPriority.PICKUP_WEAPON_URGENT
        elseif AiUtility.isRoundOver then
            priority = AiPriority.PICKUP_WEAPON_ROUND_OVER
        end

        self.currentPriority = priority

        return self.currentPriority
    end

    return AiPriority.IGNORE
end

--- @param items number[]
--- @return Entity
function AiStatePickupItems:getNearbyItems(items)
    local origin = LocalPlayer:getOrigin()
    local isFreezetime = AiUtility.gameRules:m_bFreezePeriod() == 1

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

        if not isFreezetime then
            local weaponOrigin = item:m_vecOrigin()

            if origin:getDistance(weaponOrigin) > 1024 or item:m_vecVelocity():getMagnitude() > 16 then
                break
            end

            local trace = Trace.getLineToPosition(Client.getEyeOrigin(), weaponOrigin, AiUtility.traceOptionsPathfinding, "AiStatePickupItems.getNearbyItems<FindVisibleItems>")

            if trace.isIntersectingGeometry then
                break
            end
        end

        return item
    until true end
end

--- @param player Player
--- @return void
function AiStatePickupItems:temporarilyBlacklistDroppedItemsFrom(player)
    self.watchDropsFrom[player.eid] = player

    Client.fireAfter(20, function()
    	self.watchDropsFrom[player.eid] = nil
    end)
end

--- @return void
function AiStatePickupItems:activate() end

--- @return void
function AiStatePickupItems:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePickupItems:think(cmd)
    -- Why are we here?
    if not self.item then
        -- It's one of life's greatest mysteries.
        return
    end

    local weapon = CsgoWeapons[self.item:m_iItemDefinitionIndex()]

    if weapon then
        self.activity = string.format("Picking up %s", weapon.name)
    end

    local owner = self.item:m_hOwnerEntity()
    local isDefuseKit = self.item.classname == "CEconEntity"

    if isDefuseKit and LocalPlayer:m_bHasDefuser() == 1 then
        self.item = nil

        return
    end

    if self.item:m_vecOrigin() == nil or owner then
        self.item = nil

        if AiUtility.gameRules:m_bFreezePeriod() == 1 and owner == LocalPlayer.eid then
            self.ai.voice.pack:speakGratitude()
        end

        return
    end

    local itemOrigin = self.item:m_vecOrigin()
    local floorTrace = Trace.getLineInDirection(itemOrigin, Vector3.align.DOWN, AiUtility.traceOptionsPathfinding)

    if itemOrigin:getDistance(floorTrace.endPosition) < 10 and Pathfinder.isIdle() then
        Pathfinder.moveToLocation(self.item:m_vecOrigin(), {
            task = "Pick up item",
            isConnectingGoalByCollisionLine = true,
            onFailedToFindPath = function()
                self.entityBlacklist[self.item.eid] = true

                self.item = nil
            end
        })
    end

    local origin = LocalPlayer:getOrigin()
    local weaponOrigin = self.item:m_vecOrigin()
    local distance = origin:getDistance(weaponOrigin)

    if self.lookAtItem and distance < 250 then
       View.lookAtLocation(weaponOrigin, 10, View.noise.idle, "PickupItems look at item")
    end

    if distance < 128 and self.useCooldown:isElapsedThenRestart(0.1) then
        cmd.in_use = true
    end
end

return Nyx.class("AiStatePickupItems", AiStatePickupItems, AiStateBase)
--}}}
