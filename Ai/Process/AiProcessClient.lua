--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Process = require "gamesense/Nyx/v1/Api/Process"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Steamworks = require "gamesense/steamworks"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiProcessBase = require "gamesense/Nyx/v1/Dominion/Ai/Process/AiProcessBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
--}}}

--{{{ Definitions
--- @class AiProcessClientGsConfig
--- @field normal string
--- @field reaper string
--}}}

--{{{ AiProcessClient
--- @class AiProcessClient : AiProcessBase
--- @field isEnabled boolean
--- @field lastAppFocused boolean
--- @field isInGame boolean
local AiProcessClient = {}

--- @param fields AiProcessClient
--- @return AiProcessClient
function AiProcessClient:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiProcessClient:__init()
	self:setClientLoaderLock()
	self:setMisc()
	self:setCvars()

	if not Config.isAdministrator(Client.xuid) then
		self:purgeSteamFriendsList()
		self:setCrosshair()

		self.isEnabled = true
	end

	Callbacks.frameGlobal(function()
		if not self.isEnabled then
			return
		end

		self:setMenuStates()
		self:setAppFocusedFps()
		self:handleForceDisconnect()
	end)

	Callbacks.frame(function()
		if Server.isIngame() then
			self.isInGame = true
		end
	end)
end

--- @return void
function AiProcessClient:setMisc()
	if self.ai.reaper.isEnabled then
		Client.onNextFrame(function()
			config.load(Config.clientConfigs.reaper)
		end)

		return
	end

	-- Prevent loading configuration on master accounts.
	if not Config.isAdministrator(Client.xuid) then
		Client.onNextFrame(function()
			config.load(Config.clientConfigs.normal)
		end)

		local materials = {
			"vgui_white",
			"vgui/hud/800corner1",
			"vgui/hud/800corner2",
			"vgui/hud/800corner3",
			"vgui/hud/800corner4"
		}

		client.set_event_callback("paint", function()
			local r, g, b, a = 255, 255, 255, 255

			for i=1, #materials do
				local mat = materials[i]

				materialsystem.find_material(mat):alpha_modulate(a)
				materialsystem.find_material(mat):color_modulate(r, g, b)
			end
		end)
	end
end

--- @return void
function AiProcessClient:setClientLoaderLock()
	writefile(Config.getPath("Resource/Data/ClientLoaderLock"), "1")
end

--- @return void
function AiProcessClient:setMenuStates() end

--- @return void
function AiProcessClient:setAppFocusedFps()
	if self.ai.reaper.isEnabled or Config.isAdministrator(Client.xuid) then
		return
	end

	if Config.isTextModeAllowed then
		Client.setTextMode(Server.isIngame())
	end

	local isAppFocused = Process.isAppFocused()

	if isAppFocused ~= self.lastAppFocused then
		self.lastAppFocused = isAppFocused

		if isAppFocused then
			cvar.fps_max_menu:set_int(30)
			cvar.fps_max:set_int(64)
		else
			cvar.fps_max_menu:set_int(2)
		end
	end
end

--- @return void
function AiProcessClient:purgeSteamFriendsList()
	if not Config.isClearingSteamFriends then
		return
	end

	local ISteamFriends = Steamworks.ISteamFriends
	local EFriendFlags = Steamworks.EFriendFlags

	local callback = function()
		local friendsCount = ISteamFriends.GetFriendCount(EFriendFlags.All)

		for i = 1, friendsCount do
			local steamid = ISteamFriends.GetFriendByIndex(i - 1, EFriendFlags.All)

			ISteamFriends.RemoveFriend(steamid)
		end
	end

	callback()

	Steamworks.set_callback("PersonaStateChange_t", function()
		callback()
	end)
end

--- @return void
function AiProcessClient:setCrosshair()
	if not Config.isRandomizingCrosshair then
		return
	end

	local options = {
		cl_crosshairstyle = {4},
		cl_crosshair_drawoutline = {0, 1},
		cl_crosshairthickness = {1, 1.5},
		cl_crosshairsize = {2, 3},
		cl_crosshairgap = {1, 2, 3},
		cl_crosshaircolor = {0, 1, 2, 4, 5},
		cl_crosshair_outlinethickness = {0.5, 1},
	}

	for option, values in pairs(options) do
		Client.execute("%s %s", option, Table.getRandom(values))
	end
end

--- @return void
function AiProcessClient:setCvars()
	cvar.voice_mute:set_int(0)
	cvar.voice_enable:set_int(1)
	cvar.cl_mute_all_but_friends_and_party:set_int(0)
	cvar.cl_mute_enemy_team:set_int(0)
end

--- @return void
function AiProcessClient:handleForceDisconnect()
	if Config.isForceDisconnectingOnMapChange and not Server.isIngame() and self.isInGame then
		self.isInGame = false

		Client.execute("disconnect")
	end
end

return Nyx.class("AiProcessClient", AiProcessClient, AiProcessBase)
--}}}
