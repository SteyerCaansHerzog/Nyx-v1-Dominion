--- Nyx.to Domnion
---
--- AI service for CS:GO. Play competitive matchmaking with intuitive bots.
---
--- author Steyer Caans Herzog, Nyx.to <kessie@nyx.to>
--- domain https://nyx.to/dominion
---
--- language LuaJIT
--- license Proprietary
---
--- dependencies
---     gamesense/nyx
---     gamesense/csgo_weapons

--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
--}}}

-- This must be executed as the very first setupCommand event that runs. Before everything else.
-- It is responsible for ensuring RNG between AI clients on the same server is properly randomised.
Callbacks.setupCommand(function()
    if entity.get_local_player() then
        for _ = 0, entity.get_local_player() * 100 do
            client.random_float(0, 1)
        end
    end
end)

--{{{ Modules
local AiController = require "gamesense/Nyx/v1/Dominion/Ai/AiController"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Pathfinding/Nodegraph"
local NodegraphEditor = require "gamesense/Nyx/v1/Dominion/Pathfinding/NodegraphEditor"
--}}}

local nodegraph = Nodegraph:new()

NodegraphEditor:new({
    nodegraph = nodegraph
})

AiController:new({
    nodegraph = nodegraph
})
