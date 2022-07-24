--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceTemplate
--- @class AiSentenceTemplate : AiSentenceBase
--- @field messages table<number, string[]>
--- @field timer Timer
--- @field interval number
local AiSentenceTemplate = {
    messages = {
        { "it's really cold out" },
        { "uwu?" },
        { "brb" },
        { "my mom is 25" },
        { "hmm" },
        {
            "i really pine for a toblerone",
            "like right now",
            "brb",
        },
        {
            "sec",
            "i think the landlord is at the door"
        },
        {
            "why doesn't my team",
            "fucking drop me",
            "i keep asking"
        },
        {
            "you know",
            "i really wish my mom loved me as much as daddy did"
        },
        {
            "i need a shit",
            "fuck"
        },
        {
            "can we hurry this game up?",
            "like i really need to kill my dog real quick"
        },
        {
            "please play harder"
        },
        {
            "a'ight",
            "i'm finna shoot my dog brb"
        },
        {
            "you guys watch sparkles?",
            "i really love that guy",
            "appreciate his enthusiasm for hydraulic presses"
        },
        {
            "i don't like the cut of your gob",
            "wait that's not how ur meant to say that"
        },
        {
            "sussy",
            "fucking",
            "baka"
        },
        {
            "omg stop moaning down the mic",
            "fuck wrong chat"
        },
        {
            "i rly need to wank",
            "uh",
            "wrong chat"
        },
        {
            "i don't think my team know how to use the keyboard"
        },
        {
            "i think i found my sister's weed last night",
            "do i report her to the authorities?"
        },
        {
            "sorry",
            "it's really hard playing from the gym."
        },
        {
            "keep going",
            "you're gonna make me come"
        },
        {
            "vote yes...",
            "fucking morons"
        },
        {
            "very cool",
            "super cool in fact",
        },
        {
            "i rly hope none of you fucks are french",
            "i'm srs"
        },
        {
            "my uncle shot himself yesterday",
            "this is for you uncle",
            "make u proud"
        },
        {
            "shit",
            "i think i stepped on my cat"
        },
        {
            "sorry i'm bad",
            "can't hear the game",
            "mom's ventilator is rly loud and dad doesn't want to turn it off"
        },
        {
            "grr"
        },
        {
            "i'd fuck whoopie goldberg",
            "i swear that's a bind"
        },
        {
            "tomorrow's another day",
            "and my team'll still be shit"
        },
        {
            "imposter",
            "amogus",
            "sus",
            "sussy baka",
            "uwu",
            "i fuck dogs"
        },
        {
            "śtatnasfoiyr æ vim csenzand",
            "se leer lass go oþrplaaz",
            "set dellane antsaveihht"
        },
        {
            "achoo!",
            "fuck.",
            "sorry",
            "i need a wipe"
        },
        {
            "how the fuck he stand",
            "on 10 perc"
        },
        {
            "this is paul's abortion clinic and pizzeria, where yesterday's loss is todays sauce. how can I help you today?"
        },
        {
            "grind my balls on an axe!",
            "cum-scented candle",
            "cum-broiled eggs",
            "cum-christ consciousness",
            "third-eye, cum spy",
            "cum-scrote sailboat",
            "semen speed racer",
            "off-road cum chode",
            "my uterus came out!"
        },
        {
            "i fucked a fairy in half",
            "how do i piece her back together?",
            "she cost like $2k"
        },
        {
            "fuck everyone named alex",
        }
    }
}

--- @return AiSentenceTemplate
function AiSentenceTemplate:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceTemplate:__init()
    self.__parent.__init(self)

    self.probability = 10
    self.maxUses = 4
    self.structures = {}
    self.insertions = {}
    self.timer = Timer:new():start()
    self.interval = Math.getRandomFloat(300, 500)
end

--- @return void
function AiSentenceTemplate:replyOnTick()
    if self.timer:isElapsedThenRestart(self.interval) then
        self.interval = Math.getRandomFloat(300, 500)

        self:speakMultipleRaw(Table.getRandom(self.messages))
    end
end

return Nyx.class("AiSentenceTemplate", AiSentenceTemplate, AiSentenceBase)
--}}}
