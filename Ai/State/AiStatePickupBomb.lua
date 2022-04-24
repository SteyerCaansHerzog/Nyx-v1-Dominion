--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePickupBomb
--- @class AiStatePickupBomb : AiState
--- @field ignorePickup boolean
--- @field pickupBombFails number
--- @field pickupBombTimer Timer
local AiStatePickupBomb = {
    name = "PickupBomb"
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

    if not AiUtility.client:isTerrorist() then
        return AiPriority.IGNORE
    end

    local bomb = Entity.findOne({"CC4"})

    if not bomb then
        return AiPriority.IGNORE
    end

    local owner = bomb:m_hOwnerEntity()

    if not owner and bomb:m_vecVelocity():getMagnitude() <= 10 then
        self.pickupBombTimer:ifPausedThenStart()

        if self.pickupBombTimer:isElapsed(2) then
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

    if not self.ignorePickup and self.pickupBombTimer:isElapsed(2) then
       self.ai.nodegraph:pathfind(origin, {
            objective = Node.types.GOAL,
            task = "Pick up bomb",
            onComplete = function()
               self.ai.nodegraph:log("Picking up the bomb")
            end,
            onFail = function()
                self.pickupBombFails = self.pickupBombFails + 1

               self.ai.nodegraph:log("Bomb is unreachable (ignoring it)")
            end
        })
    end
end

--- @return void
function AiStatePickupBomb:think()
    self.activity = "Going to pick up bomb"

    if self.pickupBombFails > 3 then
        self.ignorePickup = true
    end

    if self.ai.nodegraph:isIdle() and self.ai.nodegraph.lastPathfindTimer:isElapsed(1) then
        self:activate()
    end
end

return Nyx.class("AiStatePickupBomb", AiStatePickupBomb, AiState)
--}}}
