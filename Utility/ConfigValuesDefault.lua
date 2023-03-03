--- @type DominionConfig
local Config = {
	-- List of SteamID64 strings for accounts allowed to use admin chat commands.
	administrators = {},

	-- GS configs to load when Dominion is loaded.
	clientConfigs = {
		-- GS config to load when in normal mode.
		normal = "Nyx-Dominion",

		-- GS config to load when in Reaper mode.
		reaper = "Nyx-Dominion-Reaper",
	},

	-- The volume of a Reaper client that is focused.
	clientFocusVolume = 0.15,

	-- The skill level to set the AI to by default.
	defaultSkillLevel = 4,

	-- The GPT version to use for the chatbot. "gpt3", "gpt35".
	gptVersion = "gpt3",

	-- Clear the AI's Steam friend list and any requests.
	isClearingSteamFriends = false,

	-- Enables debugging features.
	isDebugging = false,

	-- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
	isEmulatingRealUserInput = true,

	-- Auto-disconnects instead of loading map. Prevents computer crashes when running many bots.
	isForceDisconnectingOnMapChange = true,

	-- Enable this when running on the Dominion Service.
	isLiveClient = false,

	-- Prevents some AI behaviours that are only useful if multiple AI are playing together.
	isPlayingSolo = false,

	-- Create random crosshair every time Dominion is initialised.
	isRandomizingCrosshair = false,

	-- Try to resolve chat into commands. This is expensive.
	isResolvingTextToCommands = false,

	-- Enable this to disable Source engine rendering when applicable.
	isTextModeAllowed = true,

	-- Enable this to see AI visualisation information.
	isVisualiserEnabled = true,

	-- Language localization for logs and other text.
	language = "English",

	-- Set this to provide an API key for use with the Open AI chatbot.
	openAiApiKey = "",

	-- Root project directory for the Dominion folder. Must have /%s at the end.
	projectDirectory = "lua/gamesense/Nyx/v1/Dominion/%s",

	-- "rigid" for old method, "dynamic" for smoother new method.
	virtualMouseMode = "dynamic"
}

return Config
