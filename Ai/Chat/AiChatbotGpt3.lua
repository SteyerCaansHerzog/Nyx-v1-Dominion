--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Http = require "gamesense/http"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiChatbot = require "gamesense/Nyx/v1/Dominion/Ai/Chat/AiChatbot"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
--}}}

--{{{ AiChatbotGpt3
--- @class AiChatbotGpt3 : AiChatbot
--- @field url string
--- @field headers string[]
--- @field history table<number, string[]>
--- @field clearHistoryTimer Timer
--- @field cooldownTimer Timer
--- @field repeatBlacklist string[]
--- @field validCharacters boolean[]
--- @field replyChance number
local AiChatbotGpt3 = {
	replyChance = 3,
	url = "https://api.openai.com/v1/engines/davinci/completions",
	headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. Config.openAiApiKey},
	validCharacters = {
		["1"] = true,
		["2"] = true,
		["3"] = true,
		["4"] = true,
		["5"] = true,
		["6"] = true,
		["7"] = true,
		["8"] = true,
		["9"] = true,
		["0"] = true,
		["q"] = true,
		["w"] = true,
		["e"] = true,
		["r"] = true,
		["t"] = true,
		["y"] = true,
		["u"] = true,
		["i"] = true,
		["o"] = true,
		["p"] = true,
		["a"] = true,
		["s"] = true,
		["d"] = true,
		["f"] = true,
		["g"] = true,
		["h"] = true,
		["j"] = true,
		["k"] = true,
		["l"] = true,
		["z"] = true,
		["x"] = true,
		["c"] = true,
		["v"] = true,
		["b"] = true,
		["n"] = true,
		["m"] = true,
		["!"] = true,
		["\""] = true,
		["'"] = true,
		["%"] = true,
		["&"] = true,
		["*"] = true,
		["-"] = true,
		[" "] = true,
		[","] = true,
		["."] = true,
		["/"] = true,
		["?"] = true,
		[":"] = true
	}
}

--- @param fields AiChatbotGpt3
--- @return AiChatbotGpt3
function AiChatbotGpt3:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiChatbotGpt3:__init()
	self.history = {}
	self.clearHistoryTimer = Timer:new()
	self.cooldownTimer = Timer:new():startThenElapse()
	self.repeatBlacklist = {}

	if Config.openAiApiKey ~= "" then
		Callbacks.playerChat(function(e)
			self:processChatMessage(e)
		end)
	end
end

--- @param e PlayerChatEvent
--- @return void
function AiChatbotGpt3:processChatMessage(e)
	-- We must be enabled via chat command.
	if not self.isEnabled then
		return
	end

	-- Lowercased to ensure blacklist always works.
	local text = e.text:lower()

	-- Prevent replying with the same text that a teammate has already sent.
	-- Useful to prevent multiple AI replies from being identical.
	if e.sender:isTeammate() then
		table.insert(self.repeatBlacklist, text)

		-- Only keep a short memory of blacklisted sentences.
		if #self.repeatBlacklist > 8 then
			table.remove(self.repeatBlacklist, 1)
		end
	end

	-- Ignore our own messages, and ignore our teammates.
	if e.sender:isClient() or e.sender:isTeammate() then
		return
	end

	-- Ignore AI chat commands.
	-- Admins may send from the enemy team.
	if text:sub(1, 1) == "/" then
		return
	end

	-- Do not reply to all messages sent in a short timespan.
	if not self.cooldownTimer:isElapsed(3) then
		return
	end

	-- Don't reply to every message ever sent.
	-- Set AiChatbotGpt3.replyChance to 1 to always reply.
	if not Client.getChance(self.replyChance) then
		return
	end

	local length = text:len()

	-- Ignore messages that are either too short to be meaningful,
	-- or messages too long to be worth deconstructing.
	if length < 8 or length > 64 then
		return
	end

	-- Verify the message is composed only of valid characters.
	-- We refuse to reply to messages in non-Latin languages or that contain non-language tokens.
	for i = 1, #text do
		local char = text:sub(i, i)

		if not self.validCharacters[char] then
			return
		end
	end

	-- Initiate a cooldown.
	self.cooldownTimer:start()

	-- Reply to the sender.
	self:reply(e.sender, text)
end

--- @param sender Player
--- @param text string
--- @return void
function AiChatbotGpt3:reply(sender, text)
	-- Clear out all of our chat history after 60 seconds of inactivity.
	-- Lets us move on from previous conversations.
	if self.clearHistoryTimer:isElapsedThenStop(60) then
		self.history = {}
	end

	self.clearHistoryTimer:start()

	local steamId64 = sender:getSteamId64()

	-- Setup missing history.
	if not self.history[steamId64] then
		self.history[steamId64] = {}
	end

	-- Keep a short memory of the conversation.
	if #self.history[steamId64] > 6 then
		table.remove(self.history[steamId64], 1)
	end

	-- Remember what the sender has said.
	table.insert(self.history[steamId64], {
		id = "Stranger",
		text = text
	})

	local history = self.history[steamId64]

	-- Create the prompt to submit to OpenAI.
	local prompt = ""

	for _, item in pairs(history) do
		prompt = prompt .. string.format("\n%s: %s", item.id, item.text)
	end

	prompt = prompt .. "\nUs:"

	-- HTTP POST data.
	local data = {
		prompt = prompt,
		temperature = 0.6,
		max_tokens = 48,
		top_p = 1,
		stop = {"\n", "...", ". . .", ":"}
	}

	Http.post(self.url, {headers = self.headers, body = json.stringify(data)}, function(_, response)
		--- @type string
		local reply = json.parse(response.body).choices[1].text:sub(2)

		-- The AI is just repeating the sender.
		if reply == text then
			return
		end

		-- Create a natural delay before replying to the sender.
		local delay = Client.getRandomFloat(1, 4) + (reply:len() * Client.getRandomFloat(0.09, 0.15))

		-- Remember what we have replied.
		table.insert(self.history[steamId64], {
			id = "Us",
			text = reply
		})

		Client.fireAfter(delay, function()
			-- Ensure nobody has already said what we're about to say. Especially other AI.
			if not Table.contains(self.repeatBlacklist, reply) then
				Messenger.send(reply, false)
			end
		end)
	end)
end

return Nyx.class("AiChatbotGpt3", AiChatbotGpt3, AiChatbot)
--}}}
