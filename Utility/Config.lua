--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local ConfigValues = require "gamesense/Nyx/v1/Dominion/Utility/ConfigValues"
local ConfigValuesDefault = require "gamesense/Nyx/v1/Dominion/Utility/ConfigValuesDefault"
--}}}

--{{{ Config
--- @class DominionConfig : Class
--- @field administrators string[]
--- @field clientConfigs AiProcessClientGsConfig
--- @field clientFocusVolume number
--- @field defaultSkillLevel number
--- @field gptVersion string
--- @field isClearingSteamFriends boolean
--- @field isDebugging boolean
--- @field isEmulatingRealUserInput boolean
--- @field isForceDisconnectingOnMapChange boolean
--- @field isLiveClient boolean
--- @field isPlayingSolo boolean
--- @field isRandomizingCrosshair boolean
--- @field isResolvingTextToCommands boolean
--- @field isTextModeAllowed boolean
--- @field isVisualiserEnabled boolean
--- @field language string
--- @field openAiApiKey string
--- @field projectDirectory string
--- @field virtualMouseMode string rigid | dynamic
local Config = {}

--- @return void
function Config:__setup()
	for k, v in pairs(ConfigValuesDefault) do
		Config[k] = v
	end

	if ConfigValues then
		for k, v in pairs(ConfigValues) do
			Config[k] = v
		end
	end

	Config.administrators = Table.getMap(Config.administrators)
end

--- @param steamId64 string
--- @return boolean
function Config.isAdministrator(steamId64)
	return Config.administrators[steamId64] ~= nil
end

--- @param pathFragment string
--- @return string
function Config.getPath(pathFragment)
	return string.format(Config.projectDirectory, pathFragment)
end

return Nyx.class("Config", Config)
--}}}
