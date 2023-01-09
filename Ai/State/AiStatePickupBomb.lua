--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiStatePickupBomb
--- @class AiStatePickupBomb : AiStateBase
--- @field ignorePickup boolean
--- @field pickupBombFails number
--- @field pickupBombTimer Timer
--- @field pickupBombTime number
local AiStatePickupBomb = {
    name = "Pickup Bomb",
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
    }
}

--- @param fields AiStatePickupBomb
--- @return AiStatePickupBomb
function AiStatePickupBomb:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePickupBomb:__init()
    self.pickupBombFails = 0
    self.pickupBombTimer = Timer:new()
    self.pickupBombTime = Math.getRandomFloat(0.25, 3)

    Callbacks.roundStart(function(e)
        self.ignorePickup = false
        self.pickupBombFails = 0
        self.pickupBombTimer:stop()
    end)

    Callbacks.itemPickup(function(e)
        if e.item == "c4" then
            self.ignorePickup = false
            self.pickupBombFails = 0
            self.pickupBombTimer:stop()
        end
    end)

    Callbacks.itemRemove(function(e)
        if e.item == "c4" then
            self.ignorePickup = false
            self.pickupBombFails = 0
            self.pickupBombTimer:stop()
        end
    end)
end

--- @return void
function AiStatePickupBomb:assess()
    if self.ignorePickup then
        return AiPriority.IGNORE
    end

    if not LocalPlayer:isTerrorist() then
        return AiPriority.IGNORE
    end

    local bomb = Entity.findOne({"CC4"})

    if not bomb then
        return AiPriority.IGNORE
    end

    local owner = bomb:m_hOwnerEntity()

    if not owner and bomb:m_vecVelocity():getMagnitude() <= 10 then
        self.pickupBombTimer:ifPausedThenStart()

        if self.pickupBombTimer:isElapsed(self.pickupBombTime) then
            return AiPriority.PICKUP_BOMB
        end
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStatePickupBomb:activate()
    local bomb = Entity.findOne({"CC4"})

    if not bomb then
        return
    end

    local origin = bomb:m_vecOrigin()

    if not origin then
        return
    end

    if not self.ignorePickup and self.pickupBombTimer:isElapsed(1) then
        Pathfinder.moveToLocation(origin, {
            task = "Pick up the bomb",
            isPathfindingByCollisionLineOnFailure = true,
            onFailedToFindPath = function()
            	self.ignorePickup = true
            end
        })
    end
end

--- @return void
function AiStatePickupBomb:think()
    self.activity = "Going to pick up bomb"
end

return Nyx.class("AiStatePickupBomb", AiStatePickupBomb, AiStateBase)
--}}}
