--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Voice = require "gamesense/Nyx/v1/Api/Voice"
--}}}

--{{{ Modules
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
--}}}

--{{{ Definitions
--- @class AiVoicePackBaseSpeakOptions
--- @field chance number
--- @field interrupt boolean
--- @field lock boolean
--- @field ignoreLock boolean
--- @field minDelay number
--- @field maxDelay number
--- @field condition fun(): boolean
--}}}

--{{{ AiVoicePackBase
--- @class AiVoicePackBase : Class
--- @field rootPath string
--- @field packPath string
--- @field defaultSpeakOptions AiVoicePackBaseSpeakOptions
--- @field name string
--- @field dynamicGroups string[]
local AiVoicePackBase = {
    rootPath = Config.getPath("Resource/Audio/Voice/%s/%s.wav"),
    defaultSpeakOptions = {
        chance = 1,
        interrupt = false,
        lock = true,
        ignoreLock = false,
        minDelay = 0.33,
        maxDelay = 1
    }
}

--- @param fields AiVoicePackBase
--- @return AiVoicePackBase
function AiVoicePackBase:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiVoicePackBase:__init()
    self:unlock()

    self.dynamicGroups = {}
end

--- @param line string
--- @return string
function AiVoicePackBase:getFile(line)
    return string.format(self.rootPath, self.packPath, line)
end

--- @param line string
--- @param quantity number
--- @return string[]
function AiVoicePackBase:getFileSequence(line, quantity)
    local result = {}

    for i = 1, quantity do
        result[i] = string.format(
            self.rootPath,
            self.packPath,
            string.format("%s%i", line, i)
        )
    end

    return result
end

--- @param line string[]
--- @return string[]
function AiVoicePackBase:getFiles(line)
    local result = {}

    for _, filename in pairs(line) do
        table.insert(result, self:getFile(filename))
    end

    return result
end

--- @return void
function AiVoicePackBase:lock()
    writefile("gamesense/Nyx/v1/Dominion/Resource/Data/AiVoiceLock", "1")
end

--- @return void
function AiVoicePackBase:unlock()
    writefile("gamesense/Nyx/v1/Dominion/Resource/Data/AiVoiceLock", "0")
end

--- @return void
function AiVoicePackBase:isLocked()
    return readfile("gamesense/Nyx/v1/Dominion/Resource/Data/AiVoiceLock") == "1"
end

--- @param lines string[]
--- @param options AiVoicePackBaseSpeakOptions
--- @return void
function AiVoicePackBase:speak(lines, options)
    if not lines then
        return
    end

    if not options then
        options = {}
    end

    Table.setMissing(options, self.defaultSpeakOptions)

    if not Math.getChance(options.chance) then
        return
    end

    if not options.ignoreLock and self:isLocked() then
        return
    end

    if options.lock then
        self:lock()
    end

    local delay = Math.getRandomFloat(options.minDelay, options.maxDelay)

    Client.fireAfter(delay, function()
        if not options.condition or (options.condition and options.condition()) then
            local line = self:getFile(Table.getRandom(lines))
            local duration = Voice.play(line, options.interrupt)

            if duration then
                Client.fireAfter(duration, function()
                    self:unlock()
                end)
            end
        end
    end)
end

--- @param sequence string[]
--- @param options AiVoicePackBaseSpeakOptions
--- @return void
function AiVoicePackBase:speakSequence(sequence, options)
    if not options then
        options = {}
    end

    Table.setMissing(options, self.defaultSpeakOptions)

    if not Math.getChance(options.chance) then
        return
    end

    if not options.ignoreLock and self:isLocked() then
        return
    end

    if options.lock then
        self:lock()
    end

    Client.fireAfter(Math.getRandomFloat(options.minDelay, options.maxDelay), function()
        local finalSequence = {}

        for key, lineOrLines in pairs(sequence) do
            local typeOf = type(lineOrLines)

            if typeOf == "string" then
                finalSequence[key] = self:getFile(lineOrLines)
            elseif typeOf == "table" then
                finalSequence[key] = self:getFile(Table.getRandom(lineOrLines))
            end
        end

        local duration = Voice.playSequence(finalSequence, options.interrupt)

        Client.fireAfter(duration, function()
            self:unlock()
        end)
    end)
end

--- @param sequences string[]
--- @param options AiVoicePackBaseSpeakOptions
--- @return void
function AiVoicePackBase:speakRandomSequence(sequences, options)
    if not options then
        options = {}
    end

    Table.setMissing(options, self.defaultSpeakOptions)

    if not Math.getChance(options.chance) then
        return
    end

    if not options.ignoreLock and self:isLocked() then
        return
    end

    if options.lock then
        self:lock()
    end

    Client.fireAfter(Math.getRandomFloat(options.minDelay, options.maxDelay), function()
        local sequence = Table.getRandom(sequences)
        local finalSequence = {}

        for key, lineOrLines in pairs(sequence) do
            local typeOf = type(lineOrLines)

            if typeOf == "string" then
                finalSequence[key] = self:getFile(lineOrLines)
            elseif typeOf == "table" then
                finalSequence[key] = self:getFile(Table.getRandom(lineOrLines))
            end
        end

        local duration = Voice.playSequence(finalSequence, options.interrupt)

        Client.fireAfter(duration, function()
            self:unlock()
        end)
    end)
end

--- @param name string
--- @param quantity number
--- @return string[]
function AiVoicePackBase:getGroup(name, quantity)
    local result = {}

    for i = 1, quantity do
        result[i] = string.format("%s_%i", name, i)
    end

    return result
end

--- @param name string
--- @return string[]
function AiVoicePackBase:getGroupDynamic(name)
    if self.dynamicGroups[name] then
        return self.dynamicGroups[name]
    end

    local result = {}

    for i = 1, 256 do
        local name = string.format("%s_%i", name, i)
        local filepath = self:getFile(name)

        if not readfile(filepath) then
            break
        end

        result[i] = name
    end

    if Table.isEmpty(result) then
        return nil
    end

    self.dynamicGroups[name] = result

    return result
end

--{{{ Kills
--- @param event PlayerDeathEvent
--- @return void
function AiVoicePackBase:speakEnemyKilledByClient(event) end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePackBase:speakTeammateKilledByClient(event) end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePackBase:speakClientKilledByEnemy(event) end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePackBase:speakClientKilledByTeammate(event) end
--}}}

--{{{ Hurt
--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackBase:speakEnemyHurtByClient(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackBase:speakTeammateHurtByClient(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackBase:speakClientHurtByEnemy(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackBase:speakClientHurtByTeammate(event) end
--}}}

--{{{ AI
--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePackBase:speakRequestTeammatesToRotate(bombsite) end

--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePackBase:speakRequestTeammatesToPush(bombsite) end

--- Must be implemented by AI. Triggered when enemy becomes aware of enemies and has decided to engage them.
---
--- @return void
function AiVoicePackBase:speakHearNearbyEnemies() end

--- Must be implemented by AI. Is related to HearNearbyEnemies.
---
--- @return void
function AiVoicePackBase:speakNotifyTeamOfBombCarrier() end

--- Must be implemented by AI.
---
--- @return void
function AiVoicePackBase:speakNotifyTeamOfBomb() end

--- @return void
function AiVoicePackBase:speakNotifyFlashbanged() end
--}}}

--{{{ Round Start
--- @return void
function AiVoicePackBase:speakRoundStart() end

--- @return void
function AiVoicePackBase:speakRoundStartPistolFirstHalf() end

--- @return void
function AiVoicePackBase:speakRoundStartPistolSecondHalf() end

--- @return void
function AiVoicePackBase:speakRoundStartWonPrevious() end

--- @return void
function AiVoicePackBase:speakRoundStartLostPrevious() end

--- @return void
function AiVoicePackBase:speakRoundStartMatchPointToTeam() end

--- @return void
function AiVoicePackBase:speakRoundStartMatchPointToOpposition() end

--- @return void
function AiVoicePackBase:speakRoundStartMatchPointFinalRound() end
--}}}

--{{{ Round End
--- @return void
function AiVoicePackBase:speakRoundEnd() end

--- @return void
function AiVoicePackBase:speakRoundEndWon() end

--- @return void
function AiVoicePackBase:speakRoundEndLost() end

--- @return void
function AiVoicePackBase:speakRoundEndHalftime() end
--}}}

--{{{ Game Start
--- @return void
function AiVoicePackBase:speakWarmupGreeting() end

--- @return void
function AiVoicePackBase:speakWarmupIdle() end
--}}}

--{{{ Game End
--- @return void
function AiVoicePackBase:speakGameEndWon() end

--- @return void
function AiVoicePackBase:speakGameEndLost() end
--}}}

--{{{ Utility
--- @return void
function AiVoicePackBase:speakClientDefusingBomb() end

--- @return void
function AiVoicePackBase:speakEnemyDefusingBomb() end

--- @return void
function AiVoicePackBase:speakCannotDefuseBomb() end

--- @return void
function AiVoicePackBase:speakClientPlantingBomb() end

--- @return void
function AiVoicePackBase:speakEnemyPlantingBomb() end

--- @return void
function AiVoicePackBase:speakClientThrowingFlashbang() end

--- @return void
function AiVoicePackBase:speakClientThrowingSmoke() end

--- @return void
function AiVoicePackBase:speakClientThrowingHeGrenade() end

--- @return void
function AiVoicePackBase:speakClientThrowingIncendiary() end
--}}}

--{{{ Comments
--- @return void
function AiVoicePackBase:speakLastAlive() end

--- @return void
function AiVoicePackBase:speakGifting() end

--- @return void
function AiVoicePackBase:speakGratitude() end

--- @return void
function AiVoicePackBase:speakAgreement() end

--- @return void
function AiVoicePackBase:speakDisagreement() end

--- @return void
function AiVoicePackBase:speakNoProblem() end
--}}}

return Nyx.class("AiVoicePackBase", AiVoicePackBase)
--}}}
