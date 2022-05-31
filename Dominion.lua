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
---     gamesense/localization

--{{{ Modules
--local AiController = require "gamesense/Nyx/v1/Dominion/Ai/AiController"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local NodegraphEditor = require "gamesense/Nyx/v1/Dominion/Traversal/NodegraphEditor"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
local AiController = require "gamesense/Nyx/v1/Dominion/Ai/AiController"
--}}}

NodegraphEditor:new()
AiController:new()
