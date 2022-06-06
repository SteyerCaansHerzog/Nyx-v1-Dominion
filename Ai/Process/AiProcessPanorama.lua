--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiProcessBase = require "gamesense/Nyx/v1/Dominion/Ai/Process/AiProcessBase"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiProcessPanorama
--- @class AiProcessPanorama : AiProcessBase
--- @field timer Timer
local AiProcessPanorama = {}

--- @param fields AiProcessPanorama
--- @return AiProcessPanorama
function AiProcessPanorama:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiProcessPanorama:__init()
	self.timer = Timer:new():startThenElapse()

	self:openAndEquipGraffitis()
	self:autoAcceptMatches()

	Callbacks.init(function()
		Client.fireAfter(1, function()
			self:unmutePlayers()
		end)
	end)

	Callbacks.playerConnectFull(function(e)
		Client.fireAfter(1, function()
			self:unmutePlayer(e.player)
		end)
	end)

	Callbacks.frameGlobal(function()
		self:autoAcceptAdminInvites()

		if self.timer:isElapsedThenRestart(30) then
			self:reconnectToOngoingMatch()
			self:closeAllPopups()
			self:acknowledgeNewInventoryItems()
		end
	end)
end

--- @return void
function AiProcessPanorama:autoAcceptMatches()
	if MenuGroup.autoAcceptMatches:get() then
		Panorama.LobbyAPI.SetLocalPlayerReady("accept")
	end

	Client.fireAfterRandom(4, 8, function()
		self:autoAcceptMatches()
	end)
end

--- @return void
function AiProcessPanorama:closeAllPopups()
	panorama.loadstring("UiToolkitAPI.CloseAllVisiblePopups()", "CSGOMainMenu")()
end

--- @return void
function AiProcessPanorama:acknowledgeNewInventoryItems()
	Panorama.InventoryAPI.AcknowledgeNewItems()
end

--- @return void
function AiProcessPanorama:reconnectToOngoingMatch()
	if not Server.isConnectingOrConnected() and Panorama.CompetitiveMatchAPI.HasOngoingMatch() then
		Panorama.CompetitiveMatchAPI.ActionReconnectToOngoingMatch()
	end
end

--- @return void
function AiProcessPanorama:autoAcceptAdminInvites()
	for i = 1, Panorama.PartyBrowserAPI.GetInvitesCount() do
		local lobbyId = Panorama.PartyBrowserAPI.GetInviteXuidByIndex(i - 1)
		local isAdminFound = false

		for j = 0, 5 do
			local xuid = Panorama.PartyBrowserAPI.GetPartyMemberXuid(lobbyId, j)

			if Config.isAdministrator(xuid) or (self.ai.reaper.isEnabled and self.ai.reaper.manifest.steamId64Map[xuid]) then
				Panorama.PartyBrowserAPI.ActionJoinParty(lobbyId)

				isAdminFound = true

				break
			end
		end

		if isAdminFound then
			break
		end
	end
end

--- @return void
function AiProcessPanorama:openAndEquipGraffitis()
	Panorama.InventoryAPI.SetInventorySortAndFilters("inv_sort_age", false, "", "", "")

	local totalItems = Panorama.InventoryAPI.GetInventoryCount() - 1
	local openedGraffiti = {}
	local unopenedGraffiti = {}

	for i = 0, totalItems do
		local idx = Panorama.InventoryAPI.GetInventoryItemIDByIndex(i)
		local set = Panorama.InventoryAPI.GetItemDefinitionName(idx)

		if set == "spray" then
			table.insert(unopenedGraffiti, idx)
		elseif set == "spraypaint" then
			table.insert(openedGraffiti, idx)
		end
	end

	Panorama.LoadoutAPI.EquipItemInSlot("noteam", Table.getRandom(openedGraffiti), "spray0")

	for id, spray in pairs(unopenedGraffiti) do
		Client.fireAfter(id, function()
			Panorama.InventoryAPI.UseTool(spray, spray)
		end)
	end
end

--- @param player Player
--- @return void
function AiProcessPanorama:unmutePlayer(player)
	local steamid64 = player:getSteamId64()

	if Panorama.GameStateAPI.IsSelectedPlayerMuted(steamid64) then
		Panorama.GameStateAPI.ToggleMute(steamid64)
	end
end

--- @return void
function AiProcessPanorama:unmutePlayers()
	for _, player in Player.findAll() do
		local steamid64 = player:getSteamId64()

		if Panorama.GameStateAPI.IsSelectedPlayerMuted(steamid64) then
			Panorama.GameStateAPI.ToggleMute(steamid64)
		end
	end
end

return Nyx.class("AiProcessPanorama", AiProcessPanorama, AiProcessBase)
--}}}
