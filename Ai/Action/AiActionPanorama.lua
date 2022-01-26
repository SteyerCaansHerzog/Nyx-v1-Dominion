--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiAction = require "gamesense/Nyx/v1/Dominion/Ai/Action/AiAction"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
--}}}

--{{{ AiActionPanorama
--- @class AiActionPanorama : AiAction
--- @field timer Timer
local AiActionPanorama = {}

--- @param fields AiActionPanorama
--- @return AiActionPanorama
function AiActionPanorama:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiActionPanorama:__init()
	self.timer = Timer:new():startThenElapse()

	self:openAndEquipGraffitis()

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
function AiActionPanorama:closeAllPopups()
	panorama.loadstring('UiToolkitAPI.CloseAllVisiblePopups()', 'CSGOMainMenu')()
end

--- @return void
function AiActionPanorama:acknowledgeNewInventoryItems()
	Panorama.InventoryAPI.AcknowledgeNewItems()
end

--- @return void
function AiActionPanorama:reconnectToOngoingMatch()
	if not Server.isConnectingOrConnected() and Panorama.CompetitiveMatchAPI.HasOngoingMatch() then
		Panorama.CompetitiveMatchAPI.ActionReconnectToOngoingMatch()
	end
end

--- @return void
function AiActionPanorama:autoAcceptAdminInvites()
	for i = 1, Panorama.PartyBrowserAPI.GetInvitesCount() do
		local lobbyId = Panorama.PartyBrowserAPI.GetInviteXuidByIndex(i - 1)

		local found = false

		for j = 0, 5 do
			local xuid = Panorama.PartyBrowserAPI.GetPartyMemberXuid(lobbyId, j)

			if Table.contains(Config.administrators, xuid) then
				Panorama.PartyBrowserAPI.ActionJoinParty(lobbyId)

				found = true

				break
			end
		end

		if found then
			break
		end
	end
end

--- @return void
function AiActionPanorama:openAndEquipGraffitis()
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
function AiActionPanorama:unmutePlayer(player)
	local steamid64 = player:getSteam64()

	if Panorama.GameStateAPI.IsSelectedPlayerMuted(steamid64) then
		Panorama.GameStateAPI.ToggleMute(steamid64)
	end
end

--- @return void
function AiActionPanorama:unmutePlayers()
	for _, player in Player.findAll(function()
		return true
	end) do
		local steamid64 = player:getSteam64()

		if Panorama.GameStateAPI.IsSelectedPlayerMuted(steamid64) then
			Panorama.GameStateAPI.ToggleMute(steamid64)
		end
	end
end

return Nyx.class("AiActionPanorama", AiActionPanorama, AiAction)
--}}}
