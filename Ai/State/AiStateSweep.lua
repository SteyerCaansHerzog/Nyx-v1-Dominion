--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateSweep
--- @class AiStateSweep : AiStateBase
--- @field node Node
--- @field isPaused boolean
--- @field randomLookAtAngles Angle
local AiStateSweep = {
    name = "Sweep"
}

--- @param fields AiStateSweep
--- @return AiStateSweep
function AiStateSweep:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateSweep:__init()
	self.isPaused = false
end

--- @return void
function AiStateSweep:getAssessment()
    return AiPriority.SWEEP
end

--- @return void
function AiStateSweep:activate()
    self:move()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateSweep:think(cmd)
    self.activity = "Sweeping the map"

	if self.randomLookAtAngles ~= nil and not Pathfinder.isOnValidPath() and self.isPaused then
		VirtualMouse.lookAlongAngle(self.randomLookAtAngles, 4.5, VirtualMouse.noise.idle, "Sweep random look at")
	end

    if not Pathfinder.isOnValidPath() and not self.isPaused then
        self:move()
    end
end

--- @return void
function AiStateSweep:move()
	self.isPaused = true

	if Math.getChance(2) then
		self.randomLookAtAngles = nil
	end

    Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
        task = "Sweep the map",
        goalReachedRadius = 600,
		onReachedGoal = function()
			Client.fireAfterRandom(1, 4, function()
				self.randomLookAtAngles = Angle:new(Math.getRandomFloat(-12, 12), Math.getRandomFloat(-180, 180))
			end)

			Client.fireAfterRandom(0.1, 6, function()
				self.isPaused = false
			end)
		end,
		onFailedToFindPath = function()
			self:move()
		end
    })
end

return Nyx.class("AiStateSweep", AiStateSweep, AiStateBase)
--}}}
