--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiRoutineVoteController
--- @class AiRoutineVoteController : AiRoutineBase
--- @field lastAliveTimer Timer
--- @field isVotedAlready boolean
local AiRoutineVoteController = {}

--- @param fields AiRoutineVoteController
--- @return AiRoutineVoteController
function AiRoutineVoteController:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineVoteController:__init()
	self.lastAliveTimer = Timer:new()

	Callbacks.levelInit(function()
		self.isVotedAlready = false
	end)

	Callbacks.roundStart(function()
		self.lastAliveTimer:stop()
	end)

	Callbacks.playerDeath(function(e)
		Client.fireAfter(0.1, function()
			if not self.ai.isEnabled then
				return
			end

			if self.isVotedAlready then
				return
			end

			if e.victim:isOtherTeammate()
				and AiUtility.teammatesTotal < 2
				and AiUtility.teammatesAlive == 0
				and Math.getChance(20)
				and self.lastAliveTimer:isElapsed(8)
			then
				Client.fireAfterRandom(1, 3, function()
					Client.voteKick(e.victim)
					self.ai.chatbots.normal.sentences.sayVoteKick:speak()

					self.isVotedAlready = true
				end)
			end

			if e.victim:isTeammate() then
				self.lastAliveTimer:start()
			end
		end)
	end)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineVoteController:think(cmd) end

return Nyx.class("AiRoutineVoteController", AiRoutineVoteController, AiRoutineBase)
--}}}
