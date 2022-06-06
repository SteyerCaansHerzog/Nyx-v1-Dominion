--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ AiSentenceBase
--- @class AiSentenceBase : Class
--- @field structures string[]
--- @field insertions string[]
--- @field minDelay number
--- @field maxDelay number
--- @field probability number
--- @field maxUses number
---
--- @field uses number
local AiSentenceBase = {}

--- @return AiSentenceBase
function AiSentenceBase:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceBase:__init()
    if not self.minDelay then
        self.minDelay = 3
    end

    if not self.maxDelay then
        self.maxDelay = 6
    end

    if not self.probability then
        self.probability = 2
    end

    Callbacks.init(function()
        self.uses = 0
    end)
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceBase:replyToPlayerChat(e) end

--- @param e PlayerDeathEvent
--- @return void
function AiSentenceBase:replyToPlayerDeath(e) end

--- @return void
function AiSentenceBase:replyOnRoundStart() end

--- @return void
function AiSentenceBase:replyOnRoundEnd() end

--- @return void
function AiSentenceBase:replyOnMatchEnd() end

--- @return void
function AiSentenceBase:replyOnTick() end

--- @param e PlayerChatEvent
--- @return boolean
function AiSentenceBase:isValidReplyTarget(e)
    return e.sender:isEnemy()
end

--- @return boolean
function AiSentenceBase:canSpeak()
    if self.maxUses and self.uses >= self.maxUses then
        return false
    end

    if not Math.getChance(self.probability) then
        return false
    end

    return true
end

--- @param substructure string
--- @return void
function AiSentenceBase:speak(substructure)
    if not self:canSpeak() then
        return
    end

    local message = self:getMessage(substructure)
    local typingDelay = message:len() * 0.1

    Client.fireAfter(Math.getRandomFloat(typingDelay + self.minDelay, typingDelay + self.maxDelay), function()
        Messenger.send(message, false)
    end)
end

--- @param messages string[]
--- @return void
function AiSentenceBase:speakMultipleRaw(messages)
    if not self:canSpeak() then
        return
    end

    local totalTypingDelay = 0

    for _, message in pairs(messages) do
        local typingDelay = Math.getRandomFloat(1, 2) + message:len() * 0.075

        totalTypingDelay = totalTypingDelay + typingDelay

        Client.fireAfter(totalTypingDelay, function()
            Messenger.send(message)
        end)
    end
end

--- @param substructure string
--- @return string
function AiSentenceBase:getMessage(substructure)
    self.uses = self.uses + 1

    local structure

    if substructure then
        structure = Table.getRandom(self.structures[substructure])
    else
        structure = Table.getRandom(self.structures)
    end

    if self.insertions then
        for insertionId, insertion in pairs(self.insertions) do
            local text
            local insertionType = type(insertion)

            if insertionType == "string" then
                text = insertion
            elseif insertionType == "table" then
                text = Table.getRandom(insertion)
            elseif insertionType == "function" then
                text = insertion()
            end

            structure = structure:gsub(
                string.format("{%s}", insertionId),
                text
            )
        end
    end

    return structure
end

--- @param message string
--- @param str string|string[]
function AiSentenceBase.contains(message, str)
    if type(str) == "string" then
        return string.find(message:lower(), str:lower()) ~= nil
    end

    if type(str) == "table" then
        for _, item in pairs(str) do
            if string.find(message:lower(), item:lower()) ~= nil then
                return true
            end
        end
    end

    return false
end

return Nyx.class("AiSentenceBase", AiSentenceBase)
--}}}
