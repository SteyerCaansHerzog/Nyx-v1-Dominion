--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Chat = require "gamesense/Nyx/v1/Api/Chat"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ Definitions
--- @type ClientWriteManyConsoleItem[]
local LoggerCode = {
	[-1] = {
		color = ColorList.FONT_MUTED,
		chatColor = Chat.WHITE,
		text = "[INFO] ",
	},
	[0] = {
		color = ColorList.OK,
		chatColor = Chat.GREEN,
		text = "[OK] ",
	},
	[1] = {
		color = ColorList.ERROR,
		chatColor = Chat.RED,
		text = "[ERROR] "
	},
	[2] = {
		color = ColorList.WARNING,
		chatColor = Chat.GOLD,
		text = "[WARNING] "
	},
	[3] = {
		color = ColorList.INFO,
		chatColor = Chat.BLUE,
		text = "[ALERT] "
	}
}
--}}}

--{{{ Logger
--- @class Logger : Class
--- @field benchmarkName string
--- @field benchmarkStartedAt number
local Logger = {}

--- @return void
function Logger.__setup()
	if Debug.isFilteringConsole then
		cvar.con_filter_enable:set_int(1)
		cvar.con_filter_text:set_string("Dominio")
	else
		cvar.con_filter_enable:set_int(0)
	end
end

--- @param name string
--- @return void
function Logger.startBenchmark(name)
	Logger.benchmarkStartedAt = client.timestamp()
	Logger.benchmarkName = name
end

--- @return void
function Logger.stopBenchmark()
	local delta = (client.timestamp() - Logger.benchmarkStartedAt) / 1000
	local ticks = delta / globals.tickinterval()

	Logger.console(0, "Benchmark '%s' finished. Time: %.4fs (%.1f ticks).", Logger.benchmarkName, delta, ticks)

	Logger.benchmarkName = nil
	Logger.benchmarkStartedAt = nil
end

--- @vararg string
--- @return void
function Logger.message(code, ...)
	local message = string.format(...)

	if not message then
		return
	end

	--- @type ClientWriteManyConsoleItem
	local codeData = LoggerCode[code]

	Client.writeManyConsole({
		{
			color = ColorList.PRIMARY,
			text = "[Dominion] "
		},
		codeData,
		{
			color = codeData.color:clone():desaturate(0.7):darken(0.05),
			text = message
		}
	})

	Chat.sendMessage(string.format("%s[Dominion]%s %s%s %s", Chat.LIME, Chat.WHITE, codeData.chatColor, codeData.text, message))
end

--- @param code number
--- @vararg string
--- @return void
function Logger.console(code, ...)
	code = code or -1

	local codeData = LoggerCode[code]

	Client.writeManyConsole({
		{
			color = ColorList.PRIMARY,
			text = "[Dominion] "
		},
		codeData,
		{
			color = codeData.color:clone():desaturate(0.7):darken(0.05),
			text = string.format(...)
		}
	})
end

--- @param version string
function Logger.credits(version)
	Client.writeBlankLines(3)

	local lines = {
		"______   _______  _______ _________ _       _________ _______  _",
		"(  __  \\ (  ___  )(       )\\__   __/( (    /|\\__   __/(  ___  )( (    /|",
		"| (  \\  )| (   ) || () () |   ) (   |  \\  ( |   ) (   | (   ) ||  \\  ( |",
		"| |   ) || |   | || || || |   | |   |   \\ | |   | |   | |   | ||   \\ | |",
		"| |   | || |   | || |(_)| |   | |   | (\\ \\) |   | |   | |   | || (\\ \\) |",
		"| |   ) || |   | || |   | |   | |   | | \\   |   | |   | |   | || | \\   |",
		"| (__/  )| (___) || )   ( |___) (___| )  \\  |___) (___| (___) || )  \\  |",
		"(______/ (_______)|/     \\|\\_______/|/    )_)\\_______/(_______)|/    )_)",
	}

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "------------------------ "
		},
		{
			color = ColorList.WARNING,
			text = "nyx.to"
		},
		{
			color = ColorList.FONT_MUTED,
			text = " | "
		},
		{
			color = ColorList.WARNING,
			text = "discord.gg/nyx"
		},
		{
			color = ColorList.FONT_MUTED,
			text = " ------------------------"
		}
	})

	for _, line in pairs(lines) do
		Client.writeConsole(ColorList.PRIMARY, line)
	end

	Client.writeBlankLines(1)

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = "Competitive CS:GO AI built for official servers."
		}
	})

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = "Current build: "
		},
		{
			color = ColorList.WARNING,
			text = string.format("v%s", version)
		},
		{
			color = ColorList.FONT_MUTED,
			text = "."
		}
	})

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = "Developed and maintained by "
		},
		{
			color = ColorList.WARNING,
			text = "Kessie#0001"
		},
		{
			color = ColorList.FONT_MUTED,
			text = "."
		}
	})

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = "Copyright ©2021-2022, all rights reserved."
		},
	})

	Client.writeBlankLines(3)
end

return Nyx.class("Logger", Logger)
--}}}
