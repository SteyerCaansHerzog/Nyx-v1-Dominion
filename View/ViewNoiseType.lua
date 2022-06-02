--{{{ Modules
local ViewNoise = require "gamesense/Nyx/v1/Dominion/View/ViewNoise"
--}}}

--- @class ViewNoiseType
--- @field none ViewNoise
--- @field idle ViewNoise
--- @field moving ViewNoise
--- @field minor ViewNoise
local ViewNoiseType = {
	none = ViewNoise:new({
		name = "None",
		timeExponent = 0,
		isBasedOnVelocity = false,
		isRandomlyToggled = false,

		pitchFineX = 0,
		pitchFineY = 0,
		pitchFineZ = 0,

		pitchSoftX = 0,
		pitchSoftY = 0,
		pitchSoftZ = 0,

		yawFineX = 0,
		yawFineY = 0,
		yawFineZ = 0,

		yawSoftX = 0,
		yawSoftY = 0,
		yawSoftZ = 0,
	}),
	idle = ViewNoise:new({
		name = "Idle",
		timeExponent = 50,
		isBasedOnVelocity = false,
		isRandomlyToggled = true,

		toggleIntervalMin = 1,
		toggleIntervalMax = 6,
		togglePeriodMin = 0.1,
		togglePeriodMax = 2.5,

		pitchFineX = 0.001,
		pitchFineY = 0.002,
		pitchFineZ = 0.0,

		pitchSoftX = 0.0008,
		pitchSoftY = 0.001,
		pitchSoftZ = 0.0015,

		yawFineX = 0.008,
		yawFineY = 0.0005,
		yawFineZ = 0.001,

		yawSoftX = 0.001,
		yawSoftY = 0.0002,
		yawSoftZ = 0.001,
	}),
	moving = ViewNoise:new({
		name = "Moving",
		timeExponent = 250,
		isBasedOnVelocity = true,
		isRandomlyToggled = false,

		pitchFineX = 0.006,
		pitchFineY = 0.005,
		pitchFineZ = 0.0033,

		pitchSoftX = 0.001,
		pitchSoftY = 0.001,
		pitchSoftZ = 0.001,

		yawFineX = 0.006,
		yawFineY = 0.045,
		yawFineZ = 0.0133,

		yawSoftX = 0.0012,
		yawSoftY = 0.0046,
		yawSoftZ = 0.007,
	}),
	minor = ViewNoise:new({
		name = "Minor",
		timeExponent = 50,
		isBasedOnVelocity = false,
		isRandomlyToggled = false,

		pitchFineX = 0.003,
		pitchFineY = 0.08,
		pitchFineZ = 0.057,

		pitchSoftX = 0.0,
		pitchSoftY = 0.0,
		pitchSoftZ = 0.0,

		yawFineX = 0.03,
		yawFineY = 0.0051,
		yawFineZ = 0.012,

		yawSoftX = 0.0,
		yawSoftY = 0.0,
		yawSoftZ = 0.0,
	}),
}

return ViewNoiseType
