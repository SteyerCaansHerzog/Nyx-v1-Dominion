--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
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

    for _, inferno in Entity.find("CInferno") do
        local distance = clientOrigin:getDistance(inferno:m_vecOrigin())

        if distance < 220 then
            self.inferno = inferno

            return AiState.priority.AVOID_INFERNO
        end
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateAvoidInfernos:activate(ai) end

--- @param ai AiOptions
--- @return void
function AiStateAvoidInfernos:deactivate(ai)
    self:reset()
end

--- @return void
function AiStateAvoidInfernos:reset()
    self.inferno = nil
end

--- @param ai AiOptions
--- @return void
function AiStateAvoidInfernos:think(ai)
    self.activity = "Getting out of a fire"

    local clientOrigin = AiUtility.client:getOrigin()
    local eyeOrigin = Client.getEyeOrigin()
    local cameraAngles = Client.getCameraAngles()
    local infernoOrigin = self.inferno:m_vecOrigin()

    --- @type Node
    local targetNode
    --- @type Node
    local backupNode

    for _, node in pairs(ai.nodegraph.nodes) do
        if node.active and infernoOrigin:getDistance(node.origin) > 300 and clientOrigin:getDistance(node.origin) < 1024 then
            backupNode = node

            local fov = cameraAngles:getFov(eyeOrigin, node.origin)

            if fov > 55 then
                targetNode = node

                break
            end
        end
    end

    if not targetNode then
        targetNode = backupNode
    end

    if ai.nodegraph:canPathfind() and not ai.nodegraph.path then
        ai.nodegraph:pathfind(targetNode.origin, {
            objective = Node.types.GOAL,
            ignore = Client.getEid(),
            task = "Avoiding inferno",
            canUseInactive = true
        })
    end
end

return Nyx.class("AiStateAvoidInfernos", AiStateAvoidInfernos, AiState)
--}}}
