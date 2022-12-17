--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Chat = require "gamesense/Nyx/v1/Api/Chat"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Time = require "gamesense/Nyx/v1/Api/Time"
--}}}

--{{{ Modules
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ Definitions
--- @type ClientWriteManyConsoleItem[]
local LoggerCode = {
	[-1] = {
		color = ColorList.FONT_MUTED,
		chatColor = Chat.WHITE,
		text = Localization.logInfo,
	},
	[0] = {
		color = ColorList.OK,
		chatColor = Chat.GREEN,
		text = Localization.logOk,
	},
	[1] = {
		color = ColorList.ERROR,
		chatColor = Chat.RED,
		text = Localization.logError,
	},
	[2] = {
		color = ColorList.WARNING,
		chatColor = Chat.GOLD,
		text = Localization.logWarning,
	},
	[3] = {
		color = ColorList.INFO,
		chatColor = Chat.BLUE,
		text = Localization.logAlert,
	},
	[4] = {
		color = ColorList.INTERNAL,
		chatColor = Chat.PURPLE,
		text = Localization.logInternal,
	}
}
--}}}

--{{{ Logger
--- @class Logger : Class
--- @field benchmarkName string
--- @field benchmarkStartedAt number
--- @field errorsCache string[]
--- @field warningsCache string[]
--- @field lastErrorTimer Timer
--- @field lastWarningError Timer
local Logger = {
	INFO = -1,
	OK = 0,
	ERROR = 1,
	WARNING = 2,
	ALERT = 3,
	INTERNAL = 4,
}

--- @return void
function Logger.__setup()
	Logger.errorsCache = {}
	Logger.warningsCache = {}

	if Debug.isFilteringConsole then
		cvar.con_filter_enable:set_int(1)
		cvar.con_filter_text:set_string("Dominion")
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

	Logger.console(Logger.OK, Localization.benchmark, Logger.benchmarkName, delta, ticks)

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

	Logger.console(code, ...)

	local codeData = LoggerCode[code]

	Chat.sendMessage(string.format("%s[Nyx]%s %s%s %s", Chat.LIME, Chat.WHITE, codeData.chatColor, codeData.text, message))
end

--- @param code number
--- @vararg string
--- @return void
function Logger.console(code, ...)
	code = code or -1

	local message = string.format(...)
	local codeData = LoggerCode[code]
	local time = Time.getDateTime()

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED_EXTRA,
			text = string.format("[%02d:%02d] ", time.hour, time.minute)
		},
		codeData,
		{
			color = codeData.color:clone():desaturate(0.7):darken(0.05),
			text = message
		}
	})

	if code == Logger.ERROR then
		table.insert(Logger.errorsCache, message)
	elseif code == Logger.WARNING then
		table.insert(Logger.warningsCache, message)
	end
end

--- @param version string
--- @param date string
--- @return void
function Logger.credits(version, date)
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
			text = Localization.splashMotto
		}
	})

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = Localization.splashBuild
		},
		{
			color = ColorList.WARNING,
			text = string.format("v%s (%s)", version, date)
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
			text = Localization.splashDevelopedBy
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
			text = "| Discord: "
		},
		{
			color = ColorList.WARNING,
			text = "discord.gg/nyx"
		}
	})

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = Localization.splashLanguage
		},
		{
			color = ColorList.WARNING,
			text = Localization.language
		},
		{
			color = ColorList.FONT_MUTED,
			text = "."
		}
	})

	local time = Time.getDateTime()

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = string.format(Localization.splashCopyright, "2021", time.year)
		},
	})

	Client.writeManyConsole({
		{
			color = ColorList.FONT_MUTED,
			text = "| "
		},
		{
			color = ColorList.FONT_MUTED,
			text = string.format(Localization.splashLicense, time.day, time.month, time.year)
		},
		{
			color = ColorList.WARNING,
			text = Localization.splashLicenseNeverExpires
		},
		{
			color = ColorList.FONT_MUTED,
			text = "."
		},
	})

	if Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
		Client.writeManyConsole({
			{
				color = ColorList.FONT_MUTED,
				text = "| "
			},
			{
				color = ColorList.INFO,
				text = Localization.splashIsAdministrator
			},
			{
				color = ColorList.FONT_MUTED,
				text = "."
			}
		})
	end

	Client.writeBlankLines(3)
end

return Nyx.class("Logger", Logger)
--}}}
