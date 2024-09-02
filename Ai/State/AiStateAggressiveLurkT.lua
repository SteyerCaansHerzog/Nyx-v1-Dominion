--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
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

--{{{ AiStateAggressiveLurkT
--- @class AiStateAggressiveLurkT : AiStateBase
--- @field node NodeSpotAggressiveLurkT
--- @field bombsite string
--- @field isSpotted boolean
--- @field isActiveThisRound boolean
--- @field lurkTimer Timer
--- @field lurkTime number
local AiStateAggressiveLurkT = {
	name = "Aggressive Lurk",
	requiredGamemodes = {
		AiUtility.gamemodes.DEMOLITION,
		AiUtility.gamemodes.WINGMAN,
	},
	requiredNodes = {
		Node.spotAggressiveLurkT
	}
}

--- @param fields AiStateAggressiveLurkT
--- @return AiStateAggressiveLurkT
function AiStateAggressiveLurkT:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiStateAggressiveLurkT:__init()
	self.lurkTimer = Timer:new()
	self.lurkTime = 10

	Callbacks.roundStart(function()
		self.isActiveThisRound = Math.getChance(3)
	end)
end

--- @return void
function AiStateAggressiveLurkT:getAssessment()
	if not self.isActiveThisRound then
		return AiPriority.IGNORE
	end

	if not LocalPlayer:isTerrorist() then
		return AiPriority.IGNORE
	end

	if AiUtility.bombCarrier and AiUtility.bombCarrier:is(LocalPlayer) then
		return AiPriority.IGNORE
	end

	if AiUtility.teammatesAlive <= 2 then
		return AiPriority.IGNORE
	end

	if self.isSpotted then
		return AiPriority.IGNORE
	end

	if self.lurkTimer:isElapsed(self.lurkTime) then
		return AiPriority.IGNORE
	end

	if AiUtility.bomb and not AiUtility.isBombPlanted() then
		return AiPriority.IGNORE
	end

	local bombDistance

	if AiUtility.bombCarrier then
		local bombsite, distance = Nodegraph.getClosestBombsite(AiUtility.bombCarrier:getOrigin())

		bombDistance = distance

		self.bombsite = bombsite.bombsite
	elseif AiUtility.bomb then
		local bombsite, distance = Nodegraph.getClosestBombsite(AiUtility.bomb:m_vecOrigin())

		bombDistance = distance

		self.bombsite = bombsite.bombsite
	end

	if not AiUtility.isBombPlanted() and bombDistance > 1600 then
		return AiPriority.IGNORE
	end

	return AiPriority.AGGRESSIVE_LURK
end

--- @return void
function AiStateAggressiveLurkT:activate()
	self.lurkTime = Math.getRandomFloat(10, 25)
	self.node = Nodegraph.getRandomForBombsite(Node.spotAggressiveLurkT, self.bombsite)

	Pathfinder.moveToNode(self.node, {
		task = string.format("Aggressively lurk near %s", self.bombsite)
	})
end

--- @return void
function AiStateAggressiveLurkT:reset()
	self.isSpotted = false
	self.node = nil

	self.lurkTimer:stop()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateAggressiveLurkT:think(cmd)
	self.activity = string.format("Going to aggressively lurk near %s", self.bombsite)

	if AiThreats.threatLevel == AiThreats.threatLevels.EXTREME then
		self.isSpotted = true
	end

	local clientOrigin = LocalPlayer:getOrigin()
	local distance = clientOrigin:getDistance(self.node.floorOrigin)

	if distance < 150 then
		self.lurkTimer:ifPausedThenStart()

		self.activity = string.format("Aggressively lurking near %s", self.bombsite)

		self.ai.routines.manageGear:block()

		LocalPlayer.equipAvailableWeapon()
		VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 3, VirtualMouse.noise.idle, "Aggressive lurk look at angle")
	end
end

return Nyx.class("AiStateAggressiveLurkT", AiStateAggressiveLurkT, AiStateBase)
--}}}
