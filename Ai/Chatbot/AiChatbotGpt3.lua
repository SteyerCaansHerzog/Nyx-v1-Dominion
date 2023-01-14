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
--}}}

--{{{ AiChatbotGpt3
--- @class AiChatbotGpt3 : AiChatbotBase
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
local AiChatbotGpt3 = {
	replyChance = 2,
	isEnabled = false,
	url = "https://api.openai.com/v1/completions",
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
		["Keith the Anarcho-Capitalist from Twitter"] = "$BOT is an edgy teenaged video game player. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and $BOT replies with sarcastic, highly political responses which are partially abbreviated with text-talk:",
		["Timmothy the Eleven Year Old"] = "$BOT is an eleven year old boy who is really into video games. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and $BOT replies with innocent and confused remarks:",
		["Roger the Hacker Man"] =  "$BOT is a software developer who loves to make cheat software in video games. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and $BOT replies with edgy comments about social culture and sometimes brags about how good he is at the game:",
		["Anna the College Student"] = "$BOT is a girl at college studying nursing. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and $BOT replies with very light and playful chat and uses anime emoticons:",
		["Jaydip the Horny Indian"] = "$BOT is a very horny Indian man. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and replies with heavy sexual overtones and a sense of desparation:",
		["Carl the Man of Faith"] = "$BOT is a conservative Christian. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and replies with calm, confident, short comments:",
		["Xiu the Fanatical Communist"] = "$BOT is Chinese. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and is very hostile and has bad English:",
		["Sven the Swedish Gamer"] = "$BOT is a Swedish hardcore gamer. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and is very arrogant:",
		["Magnus the Swedish Man"] = "$BOT is a Swedish gamer. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and is very nice and writes in the Swedish language:",
		["Bryce the Flamboyant"] = "$BOT is a gay gamer. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and is very nice, very flamboyant, and uses anime emoticons a lot:",
		["James the Reddit User"] = "$BOT is an avid reddit nolifer. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and responds to people in a nitpicking and condescending tone:",
		["Keily the Egirl"] = "$BOT is a slutty egirl who enjoys attention. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and responds to people in a flirting tone with heavy use of anime emoticons:",
		["Jenna the Middled Aged Woman"] = "$BOT is a middle aged female gamer. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and responds to people a friendly but bleak manner:",
		["Laurentio the Gypsie"] = "$BOT is a Romani gypsie. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and responds to people in an incredibly hostile and demeaning manner:",
		["Garry the Republican"] = "$BOT is an American republican and conspiracy theorist. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and replies with short, angry comments:",
		["Klaus the Apologist"] = "$BOT is German and a closet Nazi sympathiser. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and replies with short, passive aggressive comments:",
		["Jeremy the Brit"] = "$BOT is British and far right-wing. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and replies with short, blunt comments:",
		["Kyle the Brony"] = "$BOT is a brony who loves my little pony and his entire personality is my little pony. $BOT is currently playing CS:GO and '$ACTIVITY'. $BOT is speaking to $TARGET and replies with extra friendly, child-like language, and my little pony references:",
	}
}

--- @param fields AiChatbotGpt3
--- @return AiChatbotGpt3
function AiChatbotGpt3:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiChatbotGpt3:__init()
	if Config.openAiApiKey == "" then
		Logger.console(Logger.WARNING, Localization.chatbotGpt3NoApiKey)

		return
	end

	self.history = {}
	self.clearHistoryTimer = Timer:new()
	self.cooldownTimer = Timer:new():startThenElapse()
	self.repeatBlacklist = {}

	local persona, personaName = Table.getRandomFromNonIndexed(self.personas)

	self.persona = persona

	Logger.console(Logger.INFO, Localization.chatbotPersonaLoaded, personaName)

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
function AiChatbotGpt3:reply(sender, text, isTeamChat)
	self:requestConversationalReply(sender, text, isTeamChat)

	if Config.isResolvingTextToCommands then
		self:requestCommandReply(sender, text, isTeamChat)
	end
end

--- @param sender Player
--- @param text string
--- @param isTeamChat boolean
--- @return void
function AiChatbotGpt3:requestConversationalReply(sender, text, isTeamChat)
	-- Do not reply to all messages sent in a short timespan.
	if not self.cooldownTimer:isElapsed(5) then
		return
	end

	-- Don't reply to every message ever sent.
	-- Set AiChatbotGpt3.replyChance to 1 to always reply.
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

	local botName = String.getNormalized(Panorama.MyPersonaAPI.GetName())
	local targetName = String.getNormalized(sender:getName())

	-- Remember what the sender has said.
	table.insert(self.history[steamId64], {
		id = targetName,
		text = text
	})

	local history = self.history[steamId64]

	-- Create the prompt to submit to OpenAI.
	-- Set a default prompt here.
	local prompt = self:getFormattedPersona(botName, targetName)

	if not prompt then
		return
	end

	for _, item in pairs(history) do
		prompt = prompt .. string.format("\n%s: %s", item.id, item.text)
	end

	prompt = string.format("%s\n%s:", prompt, botName)

	-- HTTP POST data.
	local data = {
		prompt = prompt,
		temperature = 0.6,
		max_tokens = 48,
		top_p = 1,
		stop = {"\n", "...", ". . .", ":"},
		model = "text-davinci-003"
	}

	Http.post(self.url, {headers = self.headers, body = json.stringify(data)}, function(_, response)
		--- @type string
		local reply = json.parse(response.body).choices[1].text:sub(2)

		-- Lowercase and escape % characters.
		reply = reply:lower():gsub("%%", "%%%%")

		-- The AI is just repeating the sender.
		if reply == text then
			return
		end

		--- @type string[]
		local messages = Table.getExplodedString(reply, ".")
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
				id = botName,
				text = message
			})

			Client.fireAfter(delay, function()
				-- Ensure nobody has already said what we're about to say. Especially other AI.
				if not Table.contains(self.repeatBlacklist, message) then
					Messenger.send(message, isTeamChat)
				end
			end)
		until true end
	end)
end

--- @param sender Player
--- @param text string
--- @param isTeamChat boolean
--- @return void
function AiChatbotGpt3:requestCommandReply(sender, text, isTeamChat)
	if not isTeamChat then
		return
	end

	local prompt = [[Classify the following text and match it to the following commands by their description, which are formatted as "/command_name = description". Only respond with the command's name and nothing else:

Text: "%s"

Commands:
/rot a = we have been asked to go/come/rotate to the A bombsite, or the text is asking for help there. "A" can be in lowercase as "a".
/rot b = we have been asked to go/come/rotate to the B bombsite, or the text is asking for help there.
/follow = we have been asked to follow/come with our teammate.
/bomb = we have been asked to drop the C4/bomb to our teammate.
/eco = we have been asked to "eco", which means to "save" our money and buy nothing.
/force = we have been asked to "force buy", which means to use our low money supply and buy cheap weapons.
/wait - we have been asked to wait at the person's location.
/drop = we have been asked to drop/give our gun/weapon or purchase/buy a gun/weapon to give.
/assist = we have been asked to help/assist and go to the person's location.

Classification:]]

	prompt = string.format(prompt, text)

	-- HTTP POST data.
	local data = {
		prompt = prompt,
		temperature = 0.6,
		max_tokens = 64,
		top_p = 1,
		stop = {"\n"},
		model = "text-davinci-003"
	}

	Http.post(self.url, {headers = self.headers, body = json.stringify(data)}, function(_, response)
		--- @type string
		local reply = json.parse(response.body).choices[1].text:sub(2)

		-- Lowercase and escape % characters.
		reply = reply:lower():gsub("%%", "%%%%")

		self.ai:processCommand({
			sender = sender,
			text = reply,
			teamonly = true,
			name = sender:getName()
		})
	end)
end

--- @param botName string
--- @param targetName string
--- @return string
function AiChatbotGpt3:getFormattedPersona(botName, targetName)
	local activity = self.ai.currentState and self.ai.currentState.activity or "Nothing"
	local persona = self.persona

	persona = persona:gsub("$BOT", botName)
	persona = persona:gsub("$TARGET", targetName)
	persona = persona:gsub("$ACTIVITY", activity)

	return persona
end

return Nyx.class("AiChatbotGpt3", AiChatbotGpt3, AiChatbotBase)
--}}}
