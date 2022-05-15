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
local AiAction = require "gamesense/Nyx/v1/Dominion/Ai/Action/AiAction"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiActionSetBaseState
--- @class AiActionSetBaseState : AiAction
--- @field isEnabled boolean
--- @field lastAppFocused boolean
local AiActionSetBaseState = {}

--- @param fields AiActionSetBaseState
--- @return AiActionSetBaseState
function AiActionSetBaseState:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiActionSetBaseState:__init()
	self:setClientLoaderLock()
	self:setMisc()

	if not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
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
	end)
end

--- @return void
function AiActionSetBaseState:setMisc()
	if self.ai.reaper.isEnabled then
		return
	end

	-- Prevent loading configuration on master accounts.
	if not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
		config.load("Nyx-v1-Dominion")

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
function AiActionSetBaseState:setClientLoaderLock()
	writefile("lua/gamesense/Nyx/v1/Dominion/Resource/Data/ClientLoaderLock", "1")
end

--- @return void
function AiActionSetBaseState:setMenuStates()
	-- Force dormancy to be disabled.
	-- This feature is currently extremely broken and completely ruins the AI.
	Menu.dormantRef:set(false)
end

--- @return void
function AiActionSetBaseState:setAppFocusedFps()
	if self.ai.reaper.isEnabled then
		return
	end

	Client.setTextMode(Server.isIngame())

	local isAppFocused = Process.isAppFocused()

	if isAppFocused ~= self.lastAppFocused then
		self.lastAppFocused = isAppFocused

		if isAppFocused then
			cvar.fps_max_menu:set_int(30)
		else
			cvar.fps_max_menu:set_int(2)
		end
	end
end

--- @return void
function AiActionSetBaseState:purgeSteamFriendsList()
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
function AiActionSetBaseState:setCrosshair()
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

return Nyx.class("AiActionSetBaseState", AiActionSetBaseState, AiAction)
--}}}
