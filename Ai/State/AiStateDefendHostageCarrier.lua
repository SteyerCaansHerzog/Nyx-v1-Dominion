--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateDefendHostageCarrier
--- @class AiStateDefendHostageCarrier : AiStateBase
--- @field hostageCarrier Player
--- @field lastOrigin Vector3
local AiStateDefendHostageCarrier = {
    name = "Defend Hostage Carrier"
}

--- @param fields AiStateDefendHostageCarrier
--- @return AiStateDefendHostageCarrier
function AiStateDefendHostageCarrier:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDefendHostageCarrier:__init()
    Callbacks.roundStart(function()
    	self:reset()
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isClient() then
            self:reset()
        end

        if self.hostageCarrier and e.victim:is(self.hostageCarrier) then
            self:reset()
        end
    end)
end

--- @return void
function AiStateDefendHostageCarrier:assess()
    if AiUtility.gamemode ~= "hostage" then
        return AiPriority.IGNORE
    end

    if AiUtility.isHostageCarriedByTeammate and not AiUtility.client:m_hCarriedHostage() then
        local clientOrigin = AiUtility.client:getOrigin()

        --- @type Entity
        local closestHostageCarrier
        local closestDistance = math.huge

        for _, carrier in pairs(AiUtility.hostageCarriers) do
            local distance = clientOrigin:getDistance(carrier:getOrigin())

            if distance < closestDistance then
                closestDistance = distance
                closestHostageCarrier = carrier
            end
        end

        if closestDistance > 500 then
            return AiPriority.DEFEND_HOSTAGE_CARRIER_ACTIVE
        end

        if AiUtility.isClientThreatened then
            return AiPriority.IGNORE
        end

        return AiPriority.DEFEND_HOSTAGE_CARRIER_PASSIVE
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateDefendHostageCarrier:activate()
    self.hostageCarrier = Table.getRandomFromNonIndexed(AiUtility.hostageCarriers)
    self.lastOrigin = self.hostageCarrier:getOrigin()

    self:move()
end

--- @return void
function AiStateDefendHostageCarrier:reset()
    self.hostageCarrier = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefendHostageCarrier:think(cmd)
    self.activity = "Defending hostage carrier"

    local hostageCarrierOrigin = self.hostageCarrier:getOrigin()
    local distance = hostageCarrierOrigin:getDistance(self.lastOrigin)

    if distance > 64 then
        self.lastOrigin = hostageCarrierOrigin

        self:move()
    end

    if distance < 250 then
       View.lookAtLocation(self.hostageCarrier:getOrigin():offset(0, 0, 64), 4, View.noise.idle, "Follow look at player")
    end
end

--- @return void
function AiStateDefendHostageCarrier:move()
    --- @type Node[]
    local nodes = {}
    --- @type Node[]
    local closestNode
    local closestNodeDistance = math.huge

    for _, node in pairs(self.ai.nodegraph.nodes) do
        local distance = self.lastOrigin:getDistance(node.origin)

        if distance < 200 then
            table.insert(nodes, node)
        end

        if distance < closestNodeDistance then
            closestNodeDistance = distance
            closestNode = node
        end
    end

    local node = not Table.isEmpty(nodes) and Table.getRandom(nodes) or closestNode

   self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL
    })
end

return Nyx.class("AiStateDefendHostageCarrier", AiStateDefendHostageCarrier, AiStateBase)
--}}}
