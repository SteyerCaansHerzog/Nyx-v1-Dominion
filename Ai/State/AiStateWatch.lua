--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateWatch
--- @class AiStateWatch : AiState
--- @field blacklist boolean[]
--- @field isWatching boolean
--- @field node Node
--- @field watchTime number
--- @field watchTimer Timer
local AiStateWatch = {
    name = "Watch"
}

--- @param fields AiStateWatch
--- @return AiStateWatch
function AiStateWatch:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateWatch:__init()
    self.blacklist = {}
    self.watchTime = 10
    self.watchTimer = Timer:new()

    Callbacks.roundStart(function()
        self.watchTime = Client.getRandomFloat(8, 16)

    	self:reset()
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function AiStateWatch:assess(nodegraph)
    if not AiUtility.client:isTerrorist() then
        return AiState.priority.IGNORE
    end

    if self.watchTimer:isElapsedThenStop(self.watchTime) then
        self:reset()

        return AiState.priority.IGNORE
    end

    if self.node then
        return AiState.priority.WATCH
    end

    if AiUtility.plantedBomb or (AiUtility.bombCarrier and AiUtility.bombCarrier:is(AiUtility.client)) or AiUtility.roundTimer:isElapsed(25) then
        return AiState.priority.IGNORE
    end

    if not AiUtility.client:hasPrimary() or AiUtility.client:hasRifle() then
        local node = self:getWatchNode(nodegraph.objectiveWatchRifle, 3)

        if node then
            self.node = node

            return AiState.priority.WATCH
        end
    end

    if AiUtility.client:hasSniper() then
        local node = self:getWatchNode(nodegraph.objectiveWatchSniper, 0.75)

        if node then
            self.node = node

            return AiState.priority.WATCH
        end
    end

    return AiState.priority.IGNORE
end

--- @param nodes Node[]
--- @param chance number
--- @return Node
function AiStateWatch:getWatchNode(nodes, chance)
    if Table.isEmpty(nodes) then
        return
    end

    local clientOrigin = AiUtility.client:getOrigin()

    for _, node in pairs(nodes) do repeat
        if self.blacklist[node.id] then
            break
        end

        if clientOrigin:getDistance(node.origin) > 750 then
            break
        end

        if not Client.getChance(chance) then
            self.blacklist[node.id] = true

            break
        end

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(node.origin) < 72 then
                break
            end
        end

        return node
    until true end
end

--- @param ai AiOptions
--- @return void
function AiStateWatch:activate(ai)
    ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = "Watch angle"
    })
end

--- @return void
function AiStateWatch:reset()
    self.node = nil
    self.blacklist = {}
    self.isWatching = false

    self.watchTimer:stop()
end

--- @param ai AiOptions
--- @return void
function AiStateWatch:think(ai)
    local clientOrigin = AiUtility.client:getOrigin()
    local distance = clientOrigin:getDistance(self.node.origin)

    if not self.isWatching then
        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(self.node.origin) < 64 then
                self:reset()

                break
            end
        end
    end

    if not self.node then
        return
    end

    if distance < 32 then
        self.watchTimer:ifPausedThenStart()

        self.isWatching = true

        ai.cmd.in_duck = 1

        if AiUtility.client:isHoldingSniper() then
            Client.scope()
        end
    end

    if distance < 100 then
        ai.controller.isQuickStopping = true
        ai.view.isCrosshairFloating = false
        ai.controller.canUnscope = false
        ai.controller.canAntiBlock = false
    end

    if distance < 200 then
        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local trace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptions)

        ai.view:lookAtLocation(trace.endPosition, 3)

        ai.controller.canUseKnife = false

        if not AiUtility.client:isHoldingGun() then
            Client.equipWeapon()
        end
    end

    if distance > 32 and not ai.nodegraph.path and ai.nodegraph:canPathfind() then
        ai.nodegraph:pathfind(self.node.origin, {
            objective = Node.types.GOAL,
            ignore = Client.getEid(),
            task = "Watch angle"
        })
    end
end

return Nyx.class("AiStateWatch", AiStateWatch, AiState)
--}}}
