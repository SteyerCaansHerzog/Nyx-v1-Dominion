--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Voice = require "gamesense/Nyx/v1/Api/Voice"
--}}}

--{{{ Definitions
--- @class AiVoicePackSpeakOptions
--- @field chance number
--- @field interrupt boolean
--- @field lock boolean
--- @field ignoreLock boolean
--- @field minDelay number
--- @field maxDelay number
--- @field condition fun(): boolean
--}}}

--{{{ AiVoicePack
--- @class AiVoicePack : Class
--- @field rootPath string
--- @field packPath string
--- @field defaultSpeakOptions AiVoicePackSpeakOptions
--- @field name string
--- @field dynamicGroups string[]
local AiVoicePack = {
    rootPath = "lua/gamesense/Nyx/v1/Dominion/Resource/Audio/Voice/%s/%s.wav",
    defaultSpeakOptions = {
        chance = 1,
        interrupt = false,
        lock = true,
        ignoreLock = false,
        minDelay = 0.33,
        maxDelay = 1
    }
}

--- @param fields AiVoicePack
--- @return AiVoicePack
function AiVoicePack:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiVoicePack:__init()
    self:unlock()

    self.dynamicGroups = {}
end

--- @param line string
--- @return string
function AiVoicePack:getFile(line)
    return string.format(self.rootPath, self.packPath, line)
end

--- @param line string
--- @param quantity number
--- @return string[]
function AiVoicePack:getFileSequence(line, quantity)
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
function AiVoicePack:getFiles(line)
    local result = {}

    for _, filename in pairs(line) do
        table.insert(result, self:getFile(filename))
    end

    return result
end

--- @return void
function AiVoicePack:lock()
    writefile("gamesense/Nyx/v1/Dominion/Resource/Data/AiVoiceLock", "1")
end

--- @return void
function AiVoicePack:unlock()
    writefile("gamesense/Nyx/v1/Dominion/Resource/Data/AiVoiceLock", "0")
end

--- @return void
function AiVoicePack:isLocked()
    return readfile("gamesense/Nyx/v1/Dominion/Resource/Data/AiVoiceLock") == "1"
end

--- @param lines string[]
--- @param options AiVoicePackSpeakOptions
--- @return void
function AiVoicePack:speak(lines, options)
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
--- @param options AiVoicePackSpeakOptions
--- @return void
function AiVoicePack:speakSequence(sequence, options)
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
--- @param options AiVoicePackSpeakOptions
--- @return void
function AiVoicePack:speakRandomSequence(sequences, options)
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
function AiVoicePack:getGroup(name, quantity)
    local result = {}

    for i = 1, quantity do
        result[i] = string.format("%s_%i", name, i)
    end

    return result
end

--- @param name string
--- @return string[]
function AiVoicePack:getGroupDynamic(name)
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
function AiVoicePack:speakEnemyKilledByClient(event) end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakTeammateKilledByClient(event) end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakClientKilledByEnemy(event) end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakClientKilledByTeammate(event) end
--}}}

--{{{ Hurt
--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakEnemyHurtByClient(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakTeammateHurtByClient(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakClientHurtByEnemy(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakClientHurtByTeammate(event) end
--}}}

--{{{ AI
--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePack:speakRequestTeammatesToRotate(bombsite) end

--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePack:speakRequestTeammatesToPush(bombsite) end

--- Must be implemented by AI. Triggered when enemy becomes aware of enemies and has decided to engage them.
---
--- @return void
function AiVoicePack:speakHearNearbyEnemies() end

--- Must be implemented by AI. Is related to HearNearbyEnemies.
---
--- @return void
function AiVoicePack:speakNotifyTeamOfBombCarrier() end

--- Must be implemented by AI.
---
--- @return void
function AiVoicePack:speakNotifyTeamOfBomb() end

--- @return void
function AiVoicePack:speakNotifyFlashbanged() end
--}}}

--{{{ Round Start
--- @return void
function AiVoicePack:speakRoundStart() end

--- @return void
function AiVoicePack:speakRoundStartPistolFirstHalf() end

--- @return void
function AiVoicePack:speakRoundStartPistolSecondHalf() end

--- @return void
function AiVoicePack:speakRoundStartWonPrevious() end

--- @return void
function AiVoicePack:speakRoundStartLostPrevious() end

--- @return void
function AiVoicePack:speakRoundStartMatchPointToTeam() end

--- @return void
function AiVoicePack:speakRoundStartMatchPointToOpposition() end

--- @return void
function AiVoicePack:speakRoundStartMatchPointFinalRound() end
--}}}

--{{{ Round End
--- @return void
function AiVoicePack:speakRoundEnd() end

--- @return void
function AiVoicePack:speakRoundEndWon() end

--- @return void
function AiVoicePack:speakRoundEndLost() end

--- @return void
function AiVoicePack:speakRoundEndHalftime() end
--}}}

--{{{ Game Start
--- @return void
function AiVoicePack:speakWarmupGreeting() end

--- @return void
function AiVoicePack:speakWarmupIdle() end
--}}}

--{{{ Game End
--- @return void
function AiVoicePack:speakGameEndWon() end

--- @return void
function AiVoicePack:speakGameEndLost() end
--}}}

--{{{ Utility
--- @return void
function AiVoicePack:speakClientDefusingBomb() end

--- @return void
function AiVoicePack:speakEnemyDefusingBomb() end

--- @return void
function AiVoicePack:speakCannotDefuseBomb() end

--- @return void
function AiVoicePack:speakClientPlantingBomb() end

--- @return void
function AiVoicePack:speakEnemyPlantingBomb() end

--- @return void
function AiVoicePack:speakClientThrowingFlashbang() end

--- @return void
function AiVoicePack:speakClientThrowingSmoke() end

--- @return void
function AiVoicePack:speakClientThrowingHeGrenade() end

--- @return void
function AiVoicePack:speakClientThrowingIncendiary() end
--}}}

--{{{ Comments
--- @return void
function AiVoicePack:speakLastAlive() end

--- @return void
function AiVoicePack:speakGifting() end

--- @return void
function AiVoicePack:speakGratitude() end

--- @return void
function AiVoicePack:speakAgreement() end

--- @return void
function AiVoicePack:speakDisagreement() end

--- @return void
function AiVoicePack:speakNoProblem() end
--}}}

return Nyx.class("AiVoicePack", AiVoicePack)
--}}}
