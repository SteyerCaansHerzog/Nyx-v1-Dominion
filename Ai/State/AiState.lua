--{{{ AiStateList
--- @class AiStateList
local AiStateList = {
	avoidInfernos = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateAvoidInfernos",
	boost = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBoost",
	chickenInteraction = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateChickenInteraction",
	developer = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDeveloper",
	evade = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvade",
	idle = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateIdle",
	sweep = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSweep",
	trafficControl = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateTrafficControl",
	watch = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateWatch",
	zombie = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateZombie",
}

return AiStateList
--}}}
