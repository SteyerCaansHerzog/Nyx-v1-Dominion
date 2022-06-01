--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiStateAvoidInfernos
--- @class AiStateAvoidInfernos : AiStateBase
--- @field inferno Entity
--- @field isInsideInferno boolean
local AiStateAvoidInfernos = {
    name = "Avoid Infernos"
}

--- @param fields AiStateAvoidInfernos
--- @return AiStateAvoidInfernos
function AiStateAvoidInfernos:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateAvoidInfernos:__init() end

--- @return void
function AiStateAvoidInfernos:assess()
    local clientOrigin = LocalPlayer:getOrigin()

    -- Find an inferno that we're probably inside of.
    for _, inferno in Entity.find("CInferno") do
        local distance = clientOrigin:getDistance(inferno:m_vecOrigin())

        -- We're doing a cheap way of detecting if we're inside a molotov.
        -- May require tweaking.
        if distance < 300 then
            self.inferno = inferno

            return AiPriority.AVOID_INFERNO
        end
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateAvoidInfernos:activate()
    self:move()
end

--- @return void
function AiStateAvoidInfernos:deactivate()
    self:reset()
end

--- @return void
function AiStateAvoidInfernos:reset()
    self.inferno = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateAvoidInfernos:think(cmd)
    self.activity = "Avoiding inferno"

    if Pathfinder.isIdle() then
        self:move()
    end
end

--- @return void
function AiStateAvoidInfernos:move()
    Pathfinder.moveToNode(self:getCoverNode(800, AiUtility.closestEnemy), {
        task = "Get out of inferno",
        isAllowedToTraverseInfernos = true,
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true
    })
end

return Nyx.class("AiStateAvoidInfernos", AiStateAvoidInfernos, AiStateBase)
--}}}
