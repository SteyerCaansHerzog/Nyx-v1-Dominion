--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Http = require "gamesense/http"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Server = require "gamesense/Nyx/v1/Api/Server"
local String = require "gamesense/Nyx/v1/Api/String"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}
--{{{ Modules
local AiChatbotBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbotBase"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatbotGpt35
--- @class AiChatbotGpt35 : AiChatbotBase
--- @field clearHistoryTimer Timer
--- @field cooldownTimer Timer
--- @field headers string[]
--- @field history table<number, string[]>
--- @field persona string
--- @field personas string[]
--- @field ranks string[]
--- @field repeatBlacklist string[]
--- @field replyChance number
--- @field url string
--- @field validCharacters boolean[]
local AiChatbotGpt35 = {
	replyChance = 4,
	isEnabled = false,
	url = "https://api.openai.com/v1/chat/completions",
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
		[":"] = true,
		[";"] = true,
		["#"] = true,
		["_"] = true,
		["^"] = true,
		["("] = true,
		[")"] = true,
		["ä"] = true,
		["ö"] = true,
		["ü"] = true,
		["ß"] = true,
		["þ"] = true,
		["ð"] = true,
		["å"] = true,
		["ø"] = true,
	},
	personas = {
		Friendly = "You are a friendly person, who gives brief responses to the user. You are capable of replying only in English."
	}
}

--- @param fields AiChatbotGpt35
--- @return AiChatbotGpt35
function AiChatbotGpt35:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiChatbotGpt35:__init()
	if Config.openAiApiKey == "" then
		Logger.console(Logger.WARNING, Localization.chatbotGpt3NoApiKey)

		return
	end

	self.history = {}
	self.clearHistoryTimer = Timer:new()
	self.cooldownTimer = Timer:new():startThenElapse()
	self.repeatBlacklist = {}

	local persona, personaName = Table.getRandomFromNonIndexed(self.personas)
	local personaKeys = Table.getKeys(self.personas)

	self.persona = persona

	MenuGroup.showPersonas = MenuGroup.group:addCheckbox("> Show Personas"):setParent(MenuGroup.master)

	MenuGroup.persona = MenuGroup.group:addList("    > Persona", personaKeys):set(Table.getIndexOf(personaKeys, personaName) - 1):addCallback(function(item)
		personaName = personaKeys[item:get() + 1]

		if self.persona ~= self.personas[personaName] then
    		self.persona = self.personas[personaName]
		end
    end):setParent(MenuGroup.showPersonas)

	Callbacks.playerChat(function(e)
		self:processChatMessage(e)
	end)

	Callbacks.frameGlobal(function()
		if not Server.isIngame() then
			Messenger.reset()
		end
	end)
end

--- @param e PlayerChatEvent
--- @return void
function AiChatbotGpt35:processChatMessage(e)
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

	-- Ignore our own messages.
	if e.sender:isLocalPlayer() then
		return
	end

	-- Ignore teammates in global chat.
	if not e.teamonly and e.sender:isTeammate() then
		return
	end

	local initialChar = text:sub(1, 1)

	-- Ignore AI chat commands.
	-- Admins may send from the enemy team.
	if initialChar == "/" or initialChar == " " then
		return
	end

	local length = text:len()

	-- Ignore messages that are either too short to be meaningful,
	-- or messages too long to be worth deconstructing.
	if length < 6 then
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

	-- Reply to the sender.
	self:reply(e.sender, text, e.teamonly)

	-- Initiate a cooldown.
	self.cooldownTimer:start()
end

--- @param sender Player
--- @param text string
--- @param isTeamChat boolean
--- @return void
function AiChatbotGpt35:reply(sender, text, isTeamChat)
	self:requestConversationalReply(sender, text, isTeamChat)
end

--- @param sender Player
--- @param text string
--- @param isTeamChat boolean
--- @return void
function AiChatbotGpt35:requestConversationalReply(sender, text, isTeamChat)
	-- Do not reply to all messages sent in a short timespan.
	if not self.cooldownTimer:isElapsed(5) then
		return
	end

	-- Don't reply to every message ever sent.
	-- Set AiChatbotGpt35.replyChance to 1 to always reply.
	if not Math.getChance(self.replyChance) then
		return
	end

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
		id = "user",
		text = text
	})

	-- HTTP POST data.
	local data = {
		model = "gpt-3.5-turbo",
		messages = {
			{role = "system", content = self.persona}
		},
		user = sender:getName()
	}

	for _, entry in pairs(self.history[steamId64]) do
		table.insert(data.messages, {
			role = entry.id,
			content = entry.text
		})
	end

	Http.post(self.url, {headers = self.headers, body = json.stringify(data)}, function(_, response)
		--- @type string
		local reply = json.parse(response.body).choices[1].message.content

		-- Lowercase and escape % characters.
		reply = reply:lower():gsub("%%", "%%%%")
		reply = reply:gsub("\n", "")

		-- The AI is just repeating the sender.
		if reply == text then
			return
		end

		--- @type string[]
		local messages = Table.getTableFromStringByMaxLengthRespectSpaces(reply, 100)
		local delay = 0

		for _, message in pairs(messages) do
			if message:len() > 127 then
				return
			end
		end

		for _, message in pairs(messages) do repeat
			-- The AI is trying to send a blank message.
			if message == " " or message == "" then
				break
			end

			-- Create a natural delay before replying to the sender.
			delay = delay + Math.getRandomFloat(1, 2) + (message:len() * Math.getRandomFloat(0.06, 0.1))

			-- Remember what we have replied.
			table.insert(self.history[steamId64], {
				id = "assistant",
				text = message
			})

			Client.fireAfter(delay, function()
				-- Ensure nobody has already said what we're about to say. Especially other AI.
				if not Table.isValueInArray(self.repeatBlacklist, message) then
					Messenger.send(isTeamChat, message)
				end
			end)
		until true end
	end)
end

return Nyx.class("AiChatbotGpt35", AiChatbotGpt35, AiChatbotBase)
--}}}
