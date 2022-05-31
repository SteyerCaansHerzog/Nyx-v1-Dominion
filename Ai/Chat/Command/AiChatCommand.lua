--{{{ AiChatCommand
--- @class AiChatCommand
local AiChatCommand = {
	afk = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAfk",
	aim = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAim",
	bt = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBacktrack",
	bomb = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBomb",
	chat = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandChat",
	tag = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandClantag",
	cmd = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandCmd",
	buy = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBuy",
	dc = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandDisconnect",
	drop = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandDrop",
	eco = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandEco",
	ai = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandEnabled",
	follow = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandFollow",
	force = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandForce",
	go = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandGo",
	knife = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandKnife",
	know = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandKnow",
	log = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandLog",
	noise = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandNoise",
	ok = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandOk",
	assist = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAssist",
	reload = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandReload",
	rot = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandRotate",
	rush = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandRush",
	save = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSave",
	skill = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSkill",
	skipmatch = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSkipMatch",
	scramble = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandScramble",
	stop = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandStop",
	vote = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandVote",
	wait = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandWait",
}

return AiChatCommand
--}}}
