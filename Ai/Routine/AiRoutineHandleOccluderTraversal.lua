--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiRoutineHandleOccluderTraversal
--- @class AiRoutineHandleOccluderTraversal : AiRoutineBase
--- @field infernoInsideOf Entity
--- @field smokeInsideOf Entity
--- @field isWaitingOnOccluder boolean
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
	-- Yes, it is dumb that this is here.
	Pathfinder.isInsideInferno = false
	Pathfinder.isInsideSmoke = false

	self.infernoInsideOf = nil
	self.smokeInsideOf = nil
	self.isWaitingOnOccluder = false

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

	if self.infernoInsideOf then
		Pathfinder.isInsideInferno = true
	end

	-- Find an inferno that we're probably inside of.
	for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
		local smokeTick = smoke:m_nFireEffectTickBegin()

		if smokeTick and smokeTick > 0 and clientOrigin:getDistance(smoke:m_vecOrigin()) < 115 then
			local distance = clientOrigin:getDistance(smoke:m_vecOrigin())

			if distance < 200 then
				self.smokeInsideOf = smoke

				break
			end
		end
	end

	if self.smokeInsideOf then
		Pathfinder.isInsideSmoke = true
	end

	self:handleInferno()
	self:handleSmoke()
end

--- @return void
function AiRoutineHandleOccluderTraversal:handleInferno()
	local clientOrigin = LocalPlayer:getOrigin()

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

		if distance > 500 then
			break
		end

		isTraversingMolotov = true

		break
	until true end

	if not isTraversingMolotov then
		return
	end

	self.isWaitingOnOccluder = true

	Pathfinder.standStill()
end

--- @return void
function AiRoutineHandleOccluderTraversal:handleSmoke()
	local clientOrigin = LocalPlayer:getOrigin()

	if self.smokeInsideOf then
		return
	end

	if not Pathfinder.isOnValidPath() then
		return
	end

	if AiUtility.plantedBomb then
		if LocalPlayer:isTerrorist() and AiUtility.isBombBeingDefusedByEnemy then
			return
		end

		if LocalPlayer:isCounterTerrorist() and AiUtility.isBombBeingPlantedByEnemy then
			return
		end

		if AiUtility.bombDetonationTime < 25 then
			return
		end

		if AiUtility.bombDetonationTime < 30 and AiUtility.teammatesAlive >= 3 then
			return
		end
	end

	local isTraversingSmoke = false

	for _, node in pairs(Pathfinder.path.nodes) do if isTraversingSmoke then break end repeat
		if not node.isOccludedBySmoke then
			break
		end

		local distance = clientOrigin:getDistance(node.origin)

		if distance > 600 then
			break
		end

		isTraversingSmoke = true

		break
	until true end

	if not isTraversingSmoke then
		return
	end

	if AiUtility.closestEnemy and clientOrigin:getDistance(AiUtility.closestEnemy:getOrigin()) > 750 then
		return
	end

	self.isWaitingOnOccluder = true

	Pathfinder.standStill()
end

return Nyx.class("AiRoutineHandleOccluderTraversal", AiRoutineHandleOccluderTraversal, AiRoutineBase)
--}}}
