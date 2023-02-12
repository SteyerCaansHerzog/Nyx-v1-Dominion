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
--- @field activityIntervalTimer Timer
--- @field blockAcceptingInvitesTimer Timer
local AiProcessPanorama = {}

--- @param fields AiProcessPanorama
--- @return AiProcessPanorama
function AiProcessPanorama:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiProcessPanorama:__init()
	self.activityIntervalTimer = Timer:new():startThenElapse()
	self.blockAcceptingInvitesTimer = Timer:new():startThenElapse()

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

		if self.activityIntervalTimer:isElapsedThenRestart(30) then
			self:reconnectToOngoingMatch()
			self:acknowledgeNewInventoryItems()
			self:closeAllPopups()
		end
	end)
end

--- @return void
function AiProcessPanorama:autoAcceptMatches()
	if MenuGroup.autoAcceptMatches:get() and not Server.isIngame() then
		Panorama.LobbyAPI.SetLocalPlayerReady("accept")
	end

	Client.fireAfterRandom(4, 8, function()
		self:autoAcceptMatches()
	end)
end

--- @return void
function AiProcessPanorama:closeAllPopups()
	if not Server.isIngame() then
		panorama.loadstring("UiToolkitAPI.CloseAllVisiblePopups()", "CSGOMainMenu")()
	end
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
	local isAbleToAccept = self.blockAcceptingInvitesTimer:isElapsed(4)
	local isLobbyFound = false

	for lobbyIdx = 0, Panorama.PartyBrowserAPI.GetInvitesCount() - 1 do repeat
		local lobbyId = Panorama.PartyBrowserAPI.GetInviteXuidByIndex(lobbyIdx)

		-- We've found a lobby we can join. Clear any other lobbies so we don't try to join them too.
		if isLobbyFound then
			Panorama.PartyBrowserAPI.ClearInvite(lobbyId)

			break
		end

		-- Find a party member we are allowed to join.
		for playerIdx = 0, 5 do
			local xuid = Panorama.PartyBrowserAPI.GetPartyMemberXuid(lobbyId, playerIdx)
			local isJoinable = Config.isAdministrator(xuid) or (self.ai.reaper.isEnabled and self.ai.reaper.manifest.steamId64Map[xuid])

			-- Join party, otherwise clear the invite.
			if isAbleToAccept and isJoinable then
				Panorama.PartyBrowserAPI.ActionJoinParty(lobbyId)

				self.blockAcceptingInvitesTimer:start()

				isLobbyFound = true

				break
			else
				Panorama.PartyBrowserAPI.ClearInvite(lobbyId)
			end
		end
	until true end
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
