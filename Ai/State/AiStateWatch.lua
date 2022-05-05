--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
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

--- @return void
function AiStateWatch:assess()
    if not AiUtility.client:isTerrorist() then
        return AiPriority.IGNORE
    end

    if self.watchTimer:isElapsedThenStop(self.watchTime) then
        self:reset()

        return AiPriority.IGNORE
    end

    if self.node then
        return AiPriority.WATCH
    end

    if AiUtility.plantedBomb or (AiUtility.bombCarrier and AiUtility.bombCarrier:is(AiUtility.client)) or AiUtility.roundTimer:isElapsed(25) then
        return AiPriority.IGNORE
    end

    if not AiUtility.client:hasPrimary() or AiUtility.client:hasRifle() then
        local node = self:getWatchNode(self.ai.nodegraph.objectiveWatchRifle, 3)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    if AiUtility.client:hasSniper() then
        local node = self:getWatchNode(self.ai.nodegraph.objectiveWatchSniper, 0.75)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    return AiPriority.IGNORE
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

--- @return void
function AiStateWatch:activate()
   self.ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,

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

--- @param cmd SetupCommandEvent
--- @return void
function AiStateWatch:think(cmd)
    if not self.node then
        return
    end

    self.activity = "Watching area"

    if AiUtility.plantedBomb then
        self:reset()

        return
    end

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

        cmd.in_duck = 1

        if AiUtility.client:isHoldingSniper() then
            Client.scope()
        end
    end

    if distance < 100 then
        self.ai.isQuickStopping = true
        self.ai.canUnscope = false
       self.ai.nodegraph.isAllowedToAvoidTeammates = false
    end

    if distance < 200 then
        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local trace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptionsPathfinding, "AiStateWatch.think<FindSpotVisible>")

       self.ai.view:lookAtLocation(trace.endPosition, 3, self.ai.view.noiseType.NONE, "Watch look at angle")

        self.ai.canUseKnife = false

        if not AiUtility.client:isHoldingGun() then
            if AiUtility.client:hasPrimary() then
                Client.equipPrimary()
            else
                Client.equipPistol()
            end
        end
    end

    if distance > 32 and self.ai.nodegraph:isIdle() then
       self.ai.nodegraph:pathfind(self.node.origin, {
            objective = Node.types.GOAL,
            task = "Watch angle"
        })
    end
end

return Nyx.class("AiStateWatch", AiStateWatch, AiState)
--}}}
