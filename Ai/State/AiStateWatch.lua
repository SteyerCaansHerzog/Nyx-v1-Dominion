--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
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
    name = "Watch",
    requiredNodes = {
        Node.spotWatch
    }
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
        self.watchTime = Math.getRandomFloat(8, 16)

    	self:reset()
    end)
end

--- @return void
function AiStateWatch:assess()
    -- Handle hostage gamemode.
    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        -- Only CTs should watch.
        if not LocalPlayer:isCounterTerrorist() then
            return AiPriority.IGNORE
        end
    else
        -- Only Ts should watch in demolition.
        if not LocalPlayer:isTerrorist() then
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
    if AiUtility.plantedBomb or (AiUtility.bombCarrier and AiUtility.bombCarrier:is(LocalPlayer)) or AiUtility.timeData.roundtime_remaining < 60 then
        return AiPriority.IGNORE
    end

    -- Other weapons.
    if not LocalPlayer:hasPrimary() or LocalPlayer:hasRifle() then
        local node = self:getWatchNode(Node.spotWatch.weaponsOthers, 3)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    -- Snipers only.
    if LocalPlayer:hasSniper() then
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
    local clientOrigin = LocalPlayer.origin

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
        if not Math.getChance(chance) then
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

    local clientOrigin = LocalPlayer.origin
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

        if LocalPlayer:isHoldingSniper() then
            LocalPlayer.scope()
        end
    end

    if distance < 100 then
        Pathfinder.counterStrafe()
        Pathfinder.blockTeammateAvoidance()

        self.ai.routines.manageWeaponScope:block()
    end

    if distance < 200 then
        View.lookAtLocation(self.node.lookAtOrigin, 3, View.noise.none, "Watch look at angle")

        self.ai.routines.manageGear:block()

        if not LocalPlayer:isHoldingGun() then
            if LocalPlayer:hasPrimary() then
                LocalPlayer.equipPrimary()
            else
                LocalPlayer.equipPistol()
            end
        end
    end
end

return Nyx.class("AiStateWatch", AiStateWatch, AiStateBase)
--}}}
