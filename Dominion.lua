--- Copyright, Steyer Caans Herzog <kessie@nyx.to>
--- All rights reserved.
---
--- Dependencies:
--- - Nyx-v1-API <https://github.com/SteyerCaansHerzog/Nyx-v1-Api>
--- - CSGO-Weapon-Data <https://gamesense.pub/forums/viewtopic.php?id=18807>
--- - Localization-API <https://gamesense.pub/forums/viewtopic.php?id=30643>
--- - Web-Sockets-API <https://gamesense.pub/forums/viewtopic.php?id=23653>

--{{{ Modules
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"

Logger.credits("2.0.0-beta")

require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"

local Ai = require "gamesense/Nyx/v1/Dominion/Ai/Ai"
local NodegraphEditor = require "gamesense/Nyx/v1/Dominion/Traversal/NodegraphEditor"
--}}}

Ai:new()
NodegraphEditor:new()
