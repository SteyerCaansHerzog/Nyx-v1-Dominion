--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateAvoidInfernos
--- @class AiStateAvoidInfernos : AiState
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
    local clientOrigin = AiUtility.client:getOrigin()

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
function AiStateAvoidInfernos:activate() end

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
    self.activity = "Getting out of a fire"

    if self.ai.nodegraph:isIdle() then
        local cover = self:getCoverNode(800, AiUtility.closestEnemy)

        self.ai.nodegraph:pathfind(cover.origin, {
            objective = Node.types.GOAL,
            task = "Avoiding inferno",
            canUseInactive = true
        })
    end
end

return Nyx.class("AiStateAvoidInfernos", AiStateAvoidInfernos, AiState)
--}}}
