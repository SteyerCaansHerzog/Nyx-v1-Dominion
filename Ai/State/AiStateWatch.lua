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
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateWatch
--- @class AiStateWatch : AiStateBase
--- @field blacklist boolean[]
--- @field isWatching boolean
--- @field node NodeSpotWatch
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
    -- Handle hostage gamemode.
    if AiUtility.gamemode == "hostage" then
        -- Only CTs should watch.
        if not AiUtility.client:isCounterTerrorist() then
            return AiPriority.IGNORE
        end
    else
        -- Only Ts should watch in demolition.
        if not AiUtility.client:isTerrorist() then
            return AiPriority.IGNORE
        end
    end

    -- We've finished watching an angle.
    if self.watchTimer:isElapsedThenStop(self.watchTime) then
        self:reset()

        return AiPriority.IGNORE
    end

    -- We have an active node.
    if self.node then
        return AiPriority.WATCH
    end

    -- We don't want to watch angles at bad times.
    if AiUtility.plantedBomb or (AiUtility.bombCarrier and AiUtility.bombCarrier:is(AiUtility.client)) or AiUtility.roundTimer:isElapsed(25) then
        return AiPriority.IGNORE
    end

    -- Other weapons.
    if not AiUtility.client:hasPrimary() or AiUtility.client:hasRifle() then
        local node = self:getWatchNode(Node.spotWatch.weaponsOthers, 3)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    -- Snipers only.
    if AiUtility.client:hasSniper() then
        local node = self:getWatchNode(Node.spotWatch.weaponsSnipers, 0.75)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    return AiPriority.IGNORE
end

--- @param weapons string
--- @param chance number
--- @return NodeSpotWatch
function AiStateWatch:getWatchNode(weapons, chance)
    local clientOrigin = AiUtility.client:getOrigin()

    for _, node in pairs(Nodegraph.get(Node.spotWatch)) do repeat
        if self.blacklist[node.id] then
            break
        end

        if node.weapons ~= weapons then
            break
        end

        if clientOrigin:getDistance(node.origin) > 750 then
            break
        end

        -- Blacklist the node for now.
        if not Client.getChance(chance) then
            self.blacklist[node.id] = true

            break
        end

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(node.origin) < 60 then
                break
            end
        end

        return node
    until true end
end

--- @return void
function AiStateWatch:activate()
    Pathfinder.moveToNode(self.node, {
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

    Pathfinder.ifIdleThenRetryLastRequest()

    if distance < 32 then
        self.watchTimer:ifPausedThenStart()

        self.isWatching = true

        cmd.in_duck = true

        if AiUtility.client:isHoldingSniper() then
            Client.scope()
        end
    end

    if distance < 100 then
        self.ai.isQuickStopping = true
        self.ai.canUnscope = false

        Pathfinder.isAllowedToAvoidTeammates = false
    end

    if distance < 200 then
        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local trace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptionsPathfinding, "AiStateWatch.think<FindSpotVisible>")

        View.lookAtLocation(trace.endPosition, 3, View.noise.none, "Watch look at angle")

        self.ai.canUseKnife = false

        if not AiUtility.client:isHoldingGun() then
            if AiUtility.client:hasPrimary() then
                Client.equipPrimary()
            else
                Client.equipPistol()
            end
        end
    end
end

return Nyx.class("AiStateWatch", AiStateWatch, AiStateBase)
--}}}
