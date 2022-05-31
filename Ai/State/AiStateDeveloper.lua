--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiStateDeveloper
--- @class AiStateDeveloper : AiStateBase
local AiStateDeveloper = {
    name = "Developer"
}

--- @param fields AiStateDeveloper
--- @return AiStateDeveloper
function AiStateDeveloper:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDeveloper:__init() end

--- @return void
function AiStateDeveloper:assess()
    return AiPriority.IGNORE
end

--- @return void
function AiStateDeveloper:activate()
    Pathfinder.moveToNode(Nodegraph.getById(267), {
        isPathfindingFromNearestNodeIfNoConnections = false
    })

    -- Kirsty.
    if AiUtility.client:getSteamId64() == "76561198816968549" then
        Pathfinder.moveToNode(Nodegraph.getById(155))
    end

    -- Bropp.
    if AiUtility.client:getSteamId64() == "76561198373386496" then
        Pathfinder.moveToNode(Nodegraph.getById(270))
    end

    -- Retard community banned.
    if AiUtility.client:getSteamId64() == "76561198117895205" then
        Pathfinder.moveToNode(Nodegraph.getById(172))
    end
end

--- @return void
function AiStateDeveloper:reset() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDeveloper:think(cmd)
    self.activity = "Testing"

    Pathfinder.ifIdleThenRetryLastRequest()
end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiStateBase)
--}}}
