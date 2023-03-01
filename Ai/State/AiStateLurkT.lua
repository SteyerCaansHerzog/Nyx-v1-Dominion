--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateLurkT
--- @class AiStateLurkT : AiStateBase
--- @field node NodeSpotLurkT
--- @field bombsite string
--- @field isSpotted boolean
--- @field isActive boolean
local AiStateLurkT = {
	name = "Lurk",
	requiredGamemodes = {
		AiUtility.gamemodes.DEMOLITION,
		AiUtility.gamemodes.WINGMAN,
	},
	requiredNodes = {
		Node.spotLurkT
	}
}

--- @param fields AiStateLurkT
--- @return AiStateLurkT
function AiStateLurkT:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiStateLurkT:__init()
	Callbacks.roundPrestart(function()
		self:reset()

		self.isActive = Math.getChance(8)

		self:invokeAndSetOppositeBombsite(AiUtility.randomBombsite)
	end)
end

--- @return void
function AiStateLurkT:assess()
	if not self.isActive then
		return AiPriority.IGNORE
	end

	if not self.bombsite then
		return AiPriority.IGNORE
	end

	if self.isSpotted then
		return AiPriority.IGNORE
	end

	if LocalPlayer.isCarryingBomb() then
		return AiPriority.IGNORE
	end

	if AiUtility.isLastAlive then
		return AiPriority.IGNORE
	end

	if AiUtility.gameRules:m_bFreezePeriod() == 1 then
		return AiPriority.IGNORE
	end

	if not LocalPlayer:isTerrorist() then
		return AiPriority.IGNORE
	end

	if AiUtility.plantedBomb or AiUtility.isBombBeingPlantedByTeammate then
		self.isActive = false

		return AiPriority.IGNORE
	end

	if AiUtility.timeData.roundtime_elapsed > 30 then
		return AiPriority.IGNORE
	end

	return AiPriority.LURK
end

--- @return void
function AiStateLurkT:activate()
	self.node = Nodegraph.getRandomForBombsite(Node.spotLurkT, self.bombsite)

	Pathfinder.moveToNode(self.node, {
		task = string.format("Lurk near %s", self.bombsite)
	})
end

--- @param bombsite string
--- @return void
function AiStateLurkT:invokeAndSetOppositeBombsite(bombsite)
	if bombsite == "A" then
		bombsite = "B"
	elseif bombsite == "B" then
		bombsite = "A"
	end

	self.bombsite = bombsite

	self:queueForReactivation()
end

--- @return void
function AiStateLurkT:reset()
	self.isSpotted = false
	self.node = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateLurkT:think(cmd)
	self.activity = string.format("Going to lurk near %s", self.bombsite)

	if AiThreats.threatLevel == AiThreats.threatLevels.EXTREME then
		self.isSpotted = true
	end

	local clientOrigin = LocalPlayer:getOrigin()
	local distance = clientOrigin:getDistance(self.node.floorOrigin)

	if distance < 150 then
		self.activity = string.format("Lurking near %s", self.bombsite)

		self.ai.routines.manageGear:block()

		LocalPlayer.equipAvailableWeapon()
		VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 3, VirtualMouse.noise.idle, "Lurk look at angle")
	end
end

return Nyx.class("AiStateLurkT", AiStateLurkT, AiStateBase)
--}}}
