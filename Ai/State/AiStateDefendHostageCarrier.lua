--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateDefendHostageCarrier
--- @class AiStateDefendHostageCarrier : AiStateBase
--- @field hostageCarrier Player
--- @field lastOrigin Vector3
local AiStateDefendHostageCarrier = {
    name = "Defend Hostage Carrier",
    requiredGamemodes = {
        AiUtility.gamemodes.HOSTAGE
    }
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
        if e.victim:isLocalPlayer() then
            self:reset()
        end

        if self.hostageCarrier and e.victim:is(self.hostageCarrier) then
            self:reset()
        end
    end)
end

--- @return void
function AiStateDefendHostageCarrier:assess()
    if AiUtility.isHostageCarriedByTeammate and not LocalPlayer:m_hCarriedHostage() then
        local clientOrigin = LocalPlayer:getOrigin()

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

        if AiUtility.isClientThreatenedMinor then
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
       VirtualMouse.lookAtLocation(self.hostageCarrier:getOrigin():offset(0, 0, 64), 4, VirtualMouse.noise.idle, "Follow look at player")
    end
end

--- @return void
function AiStateDefendHostageCarrier:move()
    local node = Nodegraph.getRandom(Node.traverseGeneric, self.lastOrigin, 200)

    Pathfinder.moveToNode(node, {
        task = "Follow hostage carrier",
        goalReachedRadius = 150
    })
end

return Nyx.class("AiStateDefendHostageCarrier", AiStateDefendHostageCarrier, AiStateBase)
--}}}
