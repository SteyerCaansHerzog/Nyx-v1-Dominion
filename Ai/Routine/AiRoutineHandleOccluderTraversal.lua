--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiRoutineHandleOccluderTraversal
--- @class AiRoutineHandleOccluderTraversal : AiRoutineBase
--- @field infernoInsideOf Entity
--- @field smokeInsideOf Entity
--- @field isWaitingOnInferno boolean
local AiRoutineHandleOccluderTraversal = {}

--- @param fields AiRoutineHandleOccluderTraversal
--- @return AiRoutineHandleOccluderTraversal
function AiRoutineHandleOccluderTraversal:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineHandleOccluderTraversal:__init() end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineHandleOccluderTraversal:think(cmd)
	self.infernoInsideOf = nil
	self.smokeInsideOf = nil
	self.isWaitingOnInferno = false

	local clientOrigin = LocalPlayer:getOrigin()

	-- Find an inferno that we're probably inside of.
	for _, inferno in Entity.find("CInferno") do
		local distance = clientOrigin:getDistance(inferno:m_vecOrigin())

		-- We're doing a cheap way of detecting if we're inside a molotov.
		-- May require tweaking.
		if distance < 280 then
			self.infernoInsideOf = inferno

			break
		end
	end

	-- Do not stand still inside of an inferno.
	if self.infernoInsideOf then
		return
	end

	if not Pathfinder.isOnValidPath() then
		return
	end

	local isTraversingMolotov = false

	for _, node in pairs(Pathfinder.path.nodes) do if isTraversingMolotov then break end repeat
		if not node.isOccludedByInferno then
			break
		end

		local distance = clientOrigin:getDistance(node.origin)

		if distance > 400 then
			break
		end

		isTraversingMolotov = true

		break
	until true end

	-- No molotov.
	if not isTraversingMolotov then
		return
	end

	self.isWaitingOnInferno = true

	Pathfinder.standStill()
end

return Nyx.class("AiRoutineHandleOccluderTraversal", AiRoutineHandleOccluderTraversal, AiRoutineBase)
--}}}
