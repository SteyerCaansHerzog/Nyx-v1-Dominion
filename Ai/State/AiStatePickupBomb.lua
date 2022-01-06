--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
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
    name = "PickupBomb",
    canDelayActivation = true
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
        return AiState.priority.IGNORE
    end

    if not AiUtility.client:isTerrorist() then
        return AiState.priority.IGNORE
    end

    local bomb = Entity.findOne({"CC4"})

    if not bomb then
        return AiState.priority.IGNORE
    end

    local owner = bomb:m_hOwnerEntity()

    if not owner and bomb:m_vecVelocity():getMagnitude() <= 10 then
        self.pickupBombTimer:ifPausedThenStart()

        if self.pickupBombTimer:isElapsed(2) then
            return AiState.priority.PICKUP_BOMB
        end
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStatePickupBomb:activate(ai)
    local bomb = Entity.findOne({"CC4"})

    if not bomb then
        return
    end

    local origin = bomb:m_vecOrigin()

    if not origin then
        return
    end

    if not self.ignorePickup and self.pickupBombTimer:isElapsed(2) then
        ai.nodegraph:pathfind(origin, {
            objective = Node.types.GOAL,
            ignore = Client.getEid(),
            task = "Pick up bomb",
            line = true,
            onComplete = function()
                ai.nodegraph:log("Picking up the bomb")
            end,
            onFail = function()
                self.pickupBombFails = self.pickupBombFails + 1

                ai.nodegraph:log("Bomb is unreachable (ignoring it)")
            end
        })
    end
end

--- @param ai AiOptions
--- @return void
function AiStatePickupBomb:think(ai)
    if self.pickupBombFails > 3 then
        self.ignorePickup = true
    end

    if not ai.nodegraph.path and ai.nodegraph.lastPathfindTimer:isElapsed(1) then
        self:activate(ai)
    end
end

return Nyx.class("AiStatePickupBomb", AiStatePickupBomb, AiState)
--}}}
