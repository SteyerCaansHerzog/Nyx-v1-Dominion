--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ ViewNoise
--- @class ViewNoise : Class
--- @field isBasedOnVelocity boolean
--- @field isRandomlyToggled boolean
--- @field name string
--- @field pitchFineX number
--- @field pitchFineY number
--- @field pitchFineZ number
--- @field pitchSoftX number
--- @field pitchSoftY number
--- @field pitchSoftZ number
--- @field timeExponent number
--- @field toggleInterval number
--- @field toggleIntervalMax number
--- @field toggleIntervalMin number
--- @field toggleIntervalTimer Timer
--- @field togglePeriod number
--- @field togglePeriodMax number
--- @field togglePeriodMin number
--- @field togglePeriodTimer Timer
--- @field yawFineX number
--- @field yawFineY number
--- @field yawFineZ number
--- @field yawSoftX number
--- @field yawSoftY number
--- @field yawSoftZ number
local ViewNoise = {}

--- @param fields ViewNoise
--- @return ViewNoise
function ViewNoise:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function ViewNoise:__init()
	self.toggleIntervalTimer = Timer:new():start()
	self.togglePeriodTimer = Timer:new()
	self.toggleInterval = 0
	self.toggleIntervalMin = 1
	self.toggleIntervalMax = 16
	self.togglePeriod = 0
	self.togglePeriodMin = 0.1
	self.togglePeriodMax = 1
end

return Nyx.class("ViewNoise", ViewNoise)
--}}}