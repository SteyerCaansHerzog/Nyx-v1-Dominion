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
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateWatch
--- @class AiStateWatch : AiStateBase
--- @field blacklist boolean[]
--- @field isWatching boolean
--- @field node NodeSpotWatchT
--- @field watchTime number
--- @field watchTimer Timer
local AiStateWatch = {
    name = "Watch",
    requiredNodes = {
        Node.spotWatchT
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
        self.watchTime = Math.getRandomFloat(6, 18)
        self.blacklist = {}

    	self:reset()
    end)
end

--- @return void
function AiStateWatch:assess()
    -- Handle hostage gamemode.
    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
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
        local node = self:getNode(Node.spotWatchT.weaponsOthers, 0.75)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    -- Snipers only.
    if LocalPlayer:hasSniper() then
        local node = self:getNode(Node.spotWatchT.weaponsSnipers, 0.85)

        if node then
            self.node = node

            return AiPriority.WATCH
        end
    end

    return AiPriority.IGNORE
end

--- @param weapons string
--- @param chance number
--- @return NodeSpotWatchT
function AiStateWatch:getNode(weapons, chance)
    local clientOrigin = LocalPlayer:getOrigin()

    for _, node in pairs(Nodegraph.get(Node.spotWatchT)) do repeat
        if self.blacklist[node.id] then
            break
        end

        if node.weapons ~= weapons then
            break
        end

        if clientOrigin:getDistance(node.floorOrigin) > 750 then
            break
        end

        -- Blacklist the node for now.
        if not Math.getChance(chance) then
            self.blacklist[node.id] = true

            break
        end

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(node.floorOrigin) < 100 then
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
function AiStateWatch:deactivate()
    self:reset()
end

--- @return void
function AiStateWatch:reset()
    if self.node then
        self.blacklist[self.node.id] = true
    end

    self.node = nil
    self.isWatching = false

    self.watchTimer:stop()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateWatch:think(cmd)
    if not self.node then
        return
    end

    self.activity = "Going to watch area"

    if AiUtility.plantedBomb then
        self:reset()

        return
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local distance = clientOrigin:getDistance(self.node.floorOrigin)

    if not self.isWatching then
        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(self.node.floorOrigin) < 64 then
                self.blacklist[self.node.id] = true

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

        if self.node.isAllowedToDuckAt then
            Pathfinder.duck()
        end

        if LocalPlayer:isHoldingSniper() then
            LocalPlayer.scope()
        end
    end

    if distance < 100 then
        self.activity = "Watching area"

        Pathfinder.counterStrafe()
        Pathfinder.blockTeammateAvoidance()

        self.ai.routines.manageWeaponScope:block()
    end

    if distance < 200 then
        self.ai.routines.manageGear:block()

        if not LocalPlayer:isHoldingGun() then
            if LocalPlayer:hasPrimary() then
                LocalPlayer.equipPrimary()
            else
                LocalPlayer.equipPistol()
            end
        end
    end

    if distance < 500 then
        VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 6, VirtualMouse.noise.none, "Watch look at angle")
    end
end

return Nyx.class("AiStateWatch", AiStateWatch, AiStateBase)
--}}}
