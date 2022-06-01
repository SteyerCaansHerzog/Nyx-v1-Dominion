--- Copyright, Steyer Caans Herzog <kessie@nyx.to>
--- All rights reserved.
---
--- Dependencies:
--- - Nyx-v1-API <https://github.com/SteyerCaansHerzog/Nyx-v1-Api>
--- - CSGO-Weapon-Data <https://gamesense.pub/forums/viewtopic.php?id=18807>
--- - Localization-API <https://gamesense.pub/forums/viewtopic.php?id=30643>

--{{{ Dependencies
-- Initialise the local player before all other AI modules.
require "gamesense/Nyx/v1/Api/LocalPlayer"
--}}}

--{{{ Modules
local NodegraphEditor = require "gamesense/Nyx/v1/Dominion/Traversal/NodegraphEditor"
local AiController = require "gamesense/Nyx/v1/Dominion/Ai/AiController"
--}}}

AiController:new()
NodegraphEditor:new()
