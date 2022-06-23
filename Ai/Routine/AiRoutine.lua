--{{{ AiRoutine
--- @class AiRoutine
local AiRoutine = {
	buyGear = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBuyGear",
	lookAwayFromFlashbangs = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineLookAwayFromFlashbangs",
	manageEconomy = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageEconomy",
	manageGear = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageGear",
	manageWeaponReload = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageWeaponReload",
	manageWeaponScope = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineManageWeaponScope",
	resolveFlyGlitch = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineResolveFlyGlitch",
}

return AiRoutine
--}}}
