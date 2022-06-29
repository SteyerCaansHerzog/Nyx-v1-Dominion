--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateLurkT
--- @class AiStateLurkT : AiStateBase
--- @field node NodeSpotLurkT
--- @field bombsite string
--- @field isSpotted boolean
--- @field isActive boolean
local AiStateLurkT = {
	name = "Lurk",
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

		self.isActive = Math.getChance(10)

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

	if LocalPlayer.hasBomb() then
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
	self.activity = string.format("Lurking near %s", self.bombsite)

	if AiUtility.isClientThreatenedMajor then
		self.isSpotted = true
	end

	local clientOrigin = LocalPlayer:getOrigin()
	local distance = clientOrigin:getDistance(self.node.origin)

	if distance < 150 then
		self.ai.routines.manageGear:block()

		LocalPlayer.equipAvailableWeapon()
		View.lookAtLocation(self.node.lookAtOrigin, 3, View.noise.idle, "Lurk look at angle")
	end
end

return Nyx.class("AiStateLurkT", AiStateLurkT, AiStateBase)
--}}}
