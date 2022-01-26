--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Table = require "gamesense/Nyx/v1/Api/Table"

local Steamworks = require "gamesense/steamworks"
--}}}

--{{{ Modules
local AiAction = require "gamesense/Nyx/v1/Dominion/Ai/Action/AiAction"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
--}}}

--{{{ FFI
local isAppFocused = vtable_bind("engine.dll", "VEngineClient014", 196, "bool(__thiscall*)(void*)")
--}}}

--{{{ AiActionSetBaseState
--- @class AiActionSetBaseState : AiAction
--- @field lastAppFocusState boolean
local AiActionSetBaseState = {}

--- @param fields AiActionSetBaseState
--- @return AiActionSetBaseState
function AiActionSetBaseState:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiActionSetBaseState:__init()
	self:setClientLoaderLock()

	if Config.isLiveClient and not Table.contains(Config.administrators, Panorama.MyPersonaAPI.GetXuid()) then
		self:purgeSteamFriendsList()
		self:setCrosshair()
	end

	Callbacks.init(function()
		self:setPrngSeed()
	end)

	Callbacks.frameGlobal(function()
		self:setAppFocusedFps()
	end)

	Callbacks.roundStart(function()
		Client.execute("showconsole")
	end)
end

--- @return void
function AiActionSetBaseState:setClientLoaderLock()
	writefile("lua/gamesense/Nyx/v1/Dominion/Resource/Data/ClientLoaderLock", "1")
end

--- @return void
function AiActionSetBaseState:setAppFocusedFps()
	local isAppFocusedState = isAppFocused()

	if isAppFocusedState ~= self.lastAppFocusState then
		self.lastAppFocusState = isAppFocusedState

		if isAppFocusedState then
			cvar.fps_max_menu:set_int(30)
		else
			cvar.fps_max_menu:set_int(1)
		end
	end
end

--- @return void
function AiActionSetBaseState:setPrngSeed()
	if entity.get_local_player() then
		for _ = 0, entity.get_local_player() * 100 do
			client.random_float(0, 1)
		end
	end
end

--- @return void
function AiActionSetBaseState:purgeSteamFriendsList()
	-- Please don't delete my main account's friends list.
	if Panorama.MyPersonaAPI.GetXuid() == "76561199102984662" then
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
		cl_crosshairdot = {0, 0, 1},
		cl_crosshaircolor = {0, 1, 2, 4, 5},
		cl_crosshair_t = {0, 0, 0, 0, 0, 0, 1},
		cl_crosshair_outlinethickness = {0.5, 1},
	}

	for option, values in pairs(options) do
		Client.execute("%s %s", option, Table.getRandom(values))
	end
end

return Nyx.class("AiActionSetBaseState", AiActionSetBaseState, AiAction)
--}}}
