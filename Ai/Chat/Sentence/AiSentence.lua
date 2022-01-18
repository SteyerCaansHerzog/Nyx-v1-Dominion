--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ AiSentence
--- @class AiSentence : Class
--- @field structures string[]
--- @field insertions string[]
--- @field minDelay number
--- @field maxDelay number
--- @field probability number
--- @field maxUses number
---
--- @field uses number
local AiSentence = {}

--- @return AiSentence
function AiSentence:new()
    return Nyx.new(self)
end

--- @return nil
function AiSentence:__init()
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

--- @param chat PlayerChatEvent
--- @return boolean
function AiSentence:isValidReplyTarget(chat)
    return chat.sender:isEnemy()
end

--- @return boolean
function AiSentence:canSpeak()
    if self.maxUses and self.uses >= self.maxUses then
        return false
    end

    if not Client.getChance(self.probability) then
        return false
    end

    return true
end

--- @param substructure string
--- @return nil
function AiSentence:speak(substructure)
    if not self:canSpeak() then
        return
    end

    local message = self:getMessage(substructure)

    local extendDelay = message:len() * 0.1

    Client.fireAfter(Client.getRandomFloat(extendDelay + self.minDelay, extendDelay + self.maxDelay), function()
        Messenger.send(message, false)
    end)
end

--- @param substructure string
--- @return string
function AiSentence:getMessage(substructure)
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
function AiSentence.contains(message, str)
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

return Nyx.class("AiSentence", AiSentence)
--}}}
