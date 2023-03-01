--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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

--{{{ AiStateLurkWithBomb
--- @class AiStateLurkWithBomb : AiStateBase
--- @field node NodeSpotLurkWithBomb
--- @field bombsite string
--- @field isSpotted boolean
local AiStateLurkWithBomb = {
	name = "Lurk With Bomb",
	requiredNodes = {
		Node.spotLurkWithBomb
	},
	requiredGamemodes = {
		AiUtility.gamemodes.DEMOLITION,
		AiUtility.gamemodes.WINGMAN,
	}
}

--- @param fields AiStateLurkWithBomb
--- @return AiStateLurkWithBomb
function AiStateLurkWithBomb:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiStateLurkWithBomb:__init()
	Callbacks.roundPrestart(function()
		self:reset()
	end)
end

--- @return void
function AiStateLurkWithBomb:assess()
	if not self.bombsite then
		return AiPriority.IGNORE
	end

	if self.isSpotted then
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

	if not AiUtility.bombCarrier or not AiUtility.bombCarrier:isLocalPlayer() then
		return AiPriority.IGNORE
	end

	if AiUtility.timeData.roundtime_elapsed > 35 then
		return AiPriority.IGNORE
	end

	local bombsiteNode = Nodegraph.getBombsite(self.bombsite)

	if LocalPlayer:getOrigin():getDistance(bombsiteNode.origin) < 1000 then
		return AiPriority.IGNORE
	end

	for _, teammate in pairs(AiUtility.teammates) do
		if teammate:getOrigin():getDistance(bombsiteNode.origin) < AiUtility.mapInfo.bombsiteRotateRadius * 1.25 then
			return AiPriority.IGNORE
		end
	end

	return AiPriority.LURK_WITH_BOMB
end

--- @return void
function AiStateLurkWithBomb:activate()
	self.node = Nodegraph.getRandomForBombsite(Node.spotLurkWithBomb, self.bombsite)

	Pathfinder.moveToNode(self.node, {
		task = string.format("Lurk with bomb near %s", self.bombsite)
	})
end

--- @param bombsite string
--- @return void
function AiStateLurkWithBomb:invoke(bombsite)
	self.bombsite = bombsite

	self:queueForReactivation()
end

--- @return void
function AiStateLurkWithBomb:reset()
	self.isSpotted = false
	self.node = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateLurkWithBomb:think(cmd)
	self.activity = string.format("Lurking with bomb near %s", self.bombsite)

	if AiThreats.threatLevel == AiThreats.threatLevels.EXTREME then
		self.isSpotted = true
	end

	local clientOrigin = LocalPlayer:getOrigin()
	local distance = clientOrigin:getDistance(self.node.floorOrigin)

	if distance < 150 then
		self.ai.routines.manageGear:block()

		LocalPlayer.equipAvailableWeapon()
		VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 3, VirtualMouse.noise.idle, "Lurk with bomb look at angle")
	end
end

return Nyx.class("AiStateLurkWithBomb", AiStateLurkWithBomb, AiStateBase)
--}}}
