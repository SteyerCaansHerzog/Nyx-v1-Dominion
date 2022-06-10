--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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

--{{{ AiProcessClient
--- @class AiProcessClient : AiProcessBase
--- @field isEnabled boolean
--- @field lastAppFocused boolean
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

	if not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
		self:purgeSteamFriendsList()
		self:setCrosshair()

		self.isEnabled = true
	end

	Callbacks.frameGlobal(function()
		-- Disable AA correction because Gamesense has severe brain damage.
		for _, enemy in pairs(AiUtility.enemies) do
			plist.set(enemy.eid, "Correction active", false)
		end

		if not self.isEnabled then
			return
		end

		self:setMenuStates()
		self:setAppFocusedFps()
	end)
end

--- @return void
function AiProcessClient:setMisc()
	if self.ai.reaper.isEnabled then
		return
	end

	-- Prevent loading configuration on master accounts.
	if not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
		Client.fireAfter(1, function()
			config.load("Nyx-v1-Dominion")
		end)

		local materials = {
			"vgui_white",
			"vgui/hud/800corner1",
			"vgui/hud/800corner2",
			"vgui/hud/800corner3",
			"vgui/hud/800corner4"
		}

		client.set_event_callback("paint", function()
			local r, g, b, a = 75, 75, 75, 175

			for i=1, #materials do
				local mat = materials[i]

				materialsystem.find_material(mat):alpha_modulate(a)
				materialsystem.find_material(mat):color_modulate(r, g, b)
			end
		end)
	else
		if Config.isDebugging then
			local Debug = require "gamesense/Nyx/v1/Api/Debug"
			local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

			Debug:new({
				VectorsAngles.Vector3
			})
		end
	end
end

--- @return void
function AiProcessClient:setClientLoaderLock()
	writefile("lua/gamesense/Nyx/v1/Dominion/Resource/Data/ClientLoaderLock", "1")
end

--- @return void
function AiProcessClient:setMenuStates() end

--- @return void
function AiProcessClient:setAppFocusedFps()
	if self.ai.reaper.isEnabled then
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

return Nyx.class("AiProcessClient", AiProcessClient, AiProcessBase)
--}}}
