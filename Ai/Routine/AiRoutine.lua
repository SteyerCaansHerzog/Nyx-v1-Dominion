--{{{ AiRoutine
--- @class AiRoutine
local AiRoutine = {
	buyGear = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBuyGear",
	handleGunfireAvoidance = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineHandleGunfireAvoidance",
	handleOccluderTraversal = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineHandleOccluderTraversal",
	handleRotates = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineHandleRotates",
	lookAwayFromFlashbangs = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineLookAwayFromFlashbangs",
	manageEconomy = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageEconomy",
	manageGear = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageGear",
	manageWeaponReload = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageWeaponReload",
	manageWeaponScope = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageWeaponScope",
	resolveFlyGlitch = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineResolveFlyGlitch",
	voteController = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineVoteController",
}

return AiRoutine
--}}}
