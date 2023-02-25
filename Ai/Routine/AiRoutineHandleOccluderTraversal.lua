--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiRoutineHandleOccluderTraversal
--- @class AiRoutineHandleOccluderTraversal : AiRoutineBase
--- @field infernoInsideOf Entity
--- @field isInfernoVisible boolean
--- @field isNearInferno boolean
--- @field isNearSmoke boolean
--- @field isSmokeVisible boolean
--- @field isWaitingOnOccluder boolean
--- @field jiggleCooldownTime number
--- @field jiggleCooldownTimer Timer
--- @field jiggleDirection string
--- @field jiggleTime number
--- @field jiggleTimer Timer
--- @field smokeInsideOf Entity
--- @field isSmokeWatchedByEnemy boolean
local AiRoutineHandleOccluderTraversal = {}

--- @param fields AiRoutineHandleOccluderTraversal
--- @return AiRoutineHandleOccluderTraversal
function AiRoutineHandleOccluderTraversal:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineHandleOccluderTraversal:__init()
	self.jiggleTimer = Timer:new():startThenElapse()
	self.jiggleCooldownTimer = Timer:new():startThenElapse()
	self.jiggleTime = 0
	self.jiggleCooldownTime = 0
end

--- @return void
function AiRoutineHandleOccluderTraversal:think()
	-- Yes, it is dumb that this is here.
	Pathfinder.isInsideInferno = false
	Pathfinder.isInsideSmoke = false

	self.infernoInsideOf = nil
	self.smokeInsideOf = nil
	self.isNearInferno = true
	self.isNearSmoke = false
	self.isWaitingOnOccluder = false
	self.isInfernoVisible = false
	self.isSmokeVisible = false

	local clientBounds = LocalPlayer:getBounds()
	local clientEyeOrigin = LocalPlayer.getEyeOrigin()

	-- if inside a fire then we have to get out of it
	-- if a fire is visible to use, find out if we're pathfind across it and wait on it.
	-- for smokes, maybe path away from the smoke more as standing in front of it is a death sentence.

	-- Find infernos.
	for _, inferno in Entity.find("CInferno") do repeat
		local infernoBounds = inferno:m_vecOrigin():getBounds(Vector3.align.CENTER, 256, 256, 64)

		-- Determine if we're nearby an inferno.
		if not Vector3.isBoundsIntersecting(clientBounds, infernoBounds) then
			break
		end

		self.isNearInferno = true

		local fires = inferno:getInfernoFires()

		for _, fire in pairs(fires) do
			local fireBounds = fire:getBounds(Vector3.align.CENTER, 200, 200, 48)

			-- Determine if we're inside an inferno.
			if Vector3.isBoundsIntersecting(clientBounds, fireBounds) then
				self.infernoInsideOf = inferno
			end

			local trace = Trace.getLineToPosition(clientEyeOrigin, fire:offset(0, 0, 18), AiUtility.traceOptionsVisible)

			-- Determine if an inferno is visible.
			if not trace.isIntersectingGeometry then
				self.isInfernoVisible = true
			end
		end
	until true end

	if self.infernoInsideOf then
		Pathfinder.isInsideInferno = true
	end

	self.isSmokeWatchedByEnemy = false

	-- Find smokes.
	for _, smoke in Entity.find("CSmokeGrenadeProjectile") do repeat
		local smokeTick = smoke:m_nSmokeEffectTickBegin()

		if not smokeTick or smokeTick == 0 then
			break
		end

		local smokeOrigin = smoke:m_vecOrigin()
		local smokeNearBounds = smokeOrigin:getBounds(Vector3.align.CENTER, 400, 400, 64)

		-- Determine if we're nearby a smoke.
		if not Vector3.isBoundsIntersecting(clientBounds, smokeNearBounds) then
			break
		end

		self.isNearSmoke = true

		local smokeMaxBounds = smokeOrigin:getBounds(Vector3.align.UP, 175, 175, 72)
		local smokeVisibleBox = smoke:m_vecOrigin():offset(0, 0, 48):getBox(Vector3.align.CENTER, 72, 72, 24)

		-- Are enemies watching the smoke?
		for _, enemy in pairs(AiUtility.enemies) do if self.isSmokeWatchedByEnemy then break end repeat
			if enemy:getOrigin():getDistance(smokeOrigin) < 600 then
				self.isSmokeWatchedByEnemy = true

				break
			end

			local eyeOrigin = enemy:getEyeOrigin()
			local cameraAngles = enemy:getCameraAngles()

			if cameraAngles:getFov(eyeOrigin, smokeOrigin) > 45 then
				break
			end

			self.isSmokeWatchedByEnemy = true
		until true end

		-- Are we inside a smoke?
		if Vector3.isBoundsIntersecting(clientBounds, smokeMaxBounds) then
			self.smokeInsideOf = smoke
		end

		for _, vertex in pairs(smokeVisibleBox) do
			local trace = Trace.getLineToPosition(clientEyeOrigin, vertex, AiUtility.traceOptionsVisible)

			-- Determine if a smoke is visible.
			if not trace.isIntersectingGeometry then
				self.isSmokeVisible = true
			end
		end
	until true end

	if self.smokeInsideOf then
		Pathfinder.isInsideSmoke = true
	end

	self:handleInferno()
	self:handleSmoke()
end

--- @return void
function AiRoutineHandleOccluderTraversal:handleInferno()
	if self.infernoInsideOf then
		return
	end

	if not Pathfinder.isOnValidPath() then
		return
	end

	local isTraversingMolotov = false
	--- @type NodeTypeBase
	local infernoNode

	for _, node in pairs(Pathfinder.path.nodes) do if isTraversingMolotov then break end repeat
		if not node.isOccludedByInferno then
			break
		end

		isTraversingMolotov = true
		infernoNode = node

		break
	until true end

	if not isTraversingMolotov then
		return
	end

	self.isWaitingOnOccluder = true

	self:jiggle(infernoNode)
end

--- @return void
function AiRoutineHandleOccluderTraversal:handleSmoke()
	if not self.isNearSmoke then
		return
	end

	if not self.isSmokeWatchedByEnemy then
		return
	end

	if not Pathfinder.isOnValidPath() then
		return
	end

	if AiUtility.plantedBomb then
		if AiUtility.bombDetonationTime < 25 then
			return
		end

		if AiUtility.bombDetonationTime < 30 and AiUtility.teammatesAlive >= 3 then
			return
		end

		if AiUtility.isBombBeingDefusedByEnemy then
			return
		end
	end

	if AiUtility.isBombBeingPlantedByEnemy then
		return
	end

	if AiUtility.timeData.roundtime_remaining < 30 then
		return
	end

	if AiUtility.isBombPlanted()
		and LocalPlayer:isCounterTerrorist()
		and LocalPlayer:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) < 250
	then
		return
	end

	if LocalPlayer:m_bIsDefusing() == 1 then
		return
	end

	local isTraversingSmoke = false
	--- @type NodeTypeBase
	local smokeNode

	for _, node in pairs(Pathfinder.path.nodes) do if isTraversingSmoke then break end repeat
		if not node.isOccludedBySmoke then
			break
		end

		isTraversingSmoke = true
		smokeNode = node

		break
	until true end

	if not isTraversingSmoke then
		return
	end

	self.isWaitingOnOccluder = true

	self:jiggle(smokeNode)
end

--- @param node NodeTypeBase
--- @return void
function AiRoutineHandleOccluderTraversal:jiggle(node)
	local clientOrigin = LocalPlayer:getOrigin()

	VirtualMouse.lookAtLocationPassively(node.origin:clone():offset(0, 0, 64))

	if not self.jiggleCooldownTimer:isElapsed(self.jiggleCooldownTime) then
		Pathfinder.standStill()

		return
	end

	if self.jiggleTimer:isElapsedThenRestart(self.jiggleTime) then
		if Math.getChance(4) then
			self.jiggleCooldownTime = Math.getRandomFloat(0.2, 2)
			self.jiggleCooldownTimer:start()
		end

		self.jiggleTime = Math.getRandomFloat(0.25, 0.5)
		self.jiggleDirection = self.jiggleDirection == "left" and "right" or "left"
	else
		local directions = {
			left = clientOrigin:getAngle(node.origin):offset(0, -90),
			right = clientOrigin:getAngle(node.origin):offset(0, 90)
		}

		Pathfinder.walk()
		Pathfinder.moveAtAngle(directions[self.jiggleDirection])
	end
end

return Nyx.class("AiRoutineHandleOccluderTraversal", AiRoutineHandleOccluderTraversal, AiRoutineBase)
--}}}
