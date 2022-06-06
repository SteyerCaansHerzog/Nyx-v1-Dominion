--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
--}}}

--{{{ AiRoutineResolveFlyGlitch
--- @class AiRoutineResolveFlyGlitch : AiRoutineBase
--- @field values number[]
--- @field timer Timer
local AiRoutineResolveFlyGlitch = {}

--- @param fields AiRoutineResolveFlyGlitch
--- @return AiRoutineResolveFlyGlitch
function AiRoutineResolveFlyGlitch:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineResolveFlyGlitch:__init()
	self.values = {}
	self.timer = Timer:new():startThenElapse()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineResolveFlyGlitch:think(cmd)
	local playerOrigin = LocalPlayer:getOrigin()

	if self.timer:isElapsedThenRestart(0.75) then
		self.values = {}
	end

	table.insert(self.values, playerOrigin.z)

	local lastValue = self.values[1]
	local isLastValueGreater = false
	local fails = 0

	for _, value in pairs(self.values) do repeat
		value = math.floor(value)

		if value == lastValue then
			break
		end

		if value > lastValue and not isLastValueGreater then
			isLastValueGreater = true
			lastValue = value

			fails = fails + 1
		elseif value < lastValue and isLastValueGreater then
			isLastValueGreater = false
			lastValue = value

			fails = fails + 1
		end

		lastValue = value
	until true end

	local onGround = LocalPlayer:getFlag(Player.flags.FL_ONGROUND)

	if not onGround and fails > 10 then
		cmd.in_jump = true
	end
end

return Nyx.class("AiRoutineResolveFlyGlitch", AiRoutineResolveFlyGlitch, AiRoutineBase)
--}}}
