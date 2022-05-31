--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Chat = require "gamesense/Nyx/v1/Api/Chat"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ Definitions
--- @type ClientWriteManyConsoleItem[]
local LoggerCode = {
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
local Logger = {}

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
			color = code == -1 and ColorList.FONT_NORMAL or codeData.color,
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
			color = code == -1 and ColorList.FONT_NORMAL or codeData.color,
			text = string.format(...)
		}
	})
end

return Nyx.class("Logger", Logger)
--}}}
