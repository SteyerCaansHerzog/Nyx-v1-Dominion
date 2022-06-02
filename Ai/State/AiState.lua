--{{{ AiStateList
--- @class AiStateList
local AiStateList = {
	avoidInfernos = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateAvoidInfernos",
	boost = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBoost",
	chickenInteraction = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateChickenInteraction",
	defend = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefend",
	defendHostageCarrier = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefendHostageCarrier",
	defuse = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefuse",
	developer = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDeveloper",
	drop = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDrop",
	evacuate = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvacuate",
	evade = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvade",
	flashbangDynamic = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFlashbangDynamic",
	follow = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFollow",
	freezetime = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFreezetime",
	graffiti = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGraffiti",

	idle = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateIdle",
	sweep = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSweep",
	trafficControl = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateTrafficControl",
	watch = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateWatch",
	zombie = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateZombie",
}

return AiStateList
--}}}
