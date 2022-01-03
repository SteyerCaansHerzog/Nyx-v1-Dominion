--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiVoicePack = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePack"
--}}}

--{{{ AiVoicePackSmamuel
--- @class AiVoicePackSmamuel : AiVoicePack
local AiVoicePackSmamuel = {
    packPath = "Smamuel"
}

--- @param fields AiVoicePackSmamuel
--- @return AiVoicePackSmamuel
function AiVoicePackSmamuel:new(fields)
	return Nyx.new(self, fields)
end

--{{{ Kills
--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakEnemyKilledByClient(event)
    self:speak({
        "EnemyKilledByClient_1",
        "EnemyKilledByClient_2",
        "EnemyKilledByClient_3",
        "EnemyKilledByClient_4",
        "EnemyKilledByClient_5",
        "EnemyKilledByClient_6",
    }, {
        chance = 2,
        maxDelay = 1
    })
end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakTeammateKilledByClient(event)

end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakClientKilledByEnemy(event)
    self:speak({
        "ClientKilledByEnemy_1",
        "ClientKilledByEnemy_2",
        "ClientKilledByEnemy_3",
    }, {
        chance = 2,
        maxDelay = 1
    })
end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakClientKilledByTeammate(event)
    self:speak({
        "ClientKilledByTeammate_1",
        "ClientKilledByTeammate_2",
        "ClientKilledByTeammate_3",
    }, {
        chance = 1,
        maxDelay = 1
    })
end
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
function AiVoicePack:speakClientHurtByTeammate(event)
    self:speak({
        "ClientHurtByTeammate_1",
        "ClientHurtByTeammate_2",
        "ClientHurtByTeammate_3",
    }, {
        chance = 2,
        maxDelay = 1
    })
end
--}}}

--{{{ Awareness
--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePack:speakRequestTeammatesToRotate(bombsite)
    if bombsite == "a" then
        self:speak({
            "RequestTeammatesToRotateA_1",
            "RequestTeammatesToRotateA_2",
            "RequestTeammatesToRotateA_3",
        }, {
            chance = 2,
            maxDelay = 1
        })
    elseif bombsite == "b" then
        self:speak({
            "RequestTeammatesToRotateB_1",
            "RequestTeammatesToRotateB_2",
            "RequestTeammatesToRotateB_3",
        }, {
            chance = 2,
            maxDelay = 1
        })
    end
end

--- Must be implemented by AI. Triggered when enemy becomes aware of enemies and has decided to engage them.
---
--- @return void
function AiVoicePack:speakHearNearbyEnemies()
    self:speak({
        "HearNearbyEnemies_1",
        "HearNearbyEnemies_2",
        "HearNearbyEnemies_3",
        "HearNearbyEnemies_4",
        "HearNearbyEnemies_5",
        "HearNearbyEnemies_6",
        "HearNearbyEnemies_7",
    }, {
        chance = 2,
        maxDelay = 1
    })
end

--- Must be implemented by AI. Is related to HearNearbyEnemies.
---
--- @return void
function AiVoicePack:speakNotifyTeamOfBombCarrier()
    self:speak({
        "NotifyTeamOfBombCarrier_1",
        "NotifyTeamOfBombCarrier_2",
        "NotifyTeamOfBombCarrier_3",
        "NotifyTeamOfBombCarrier_4",
    }, {
        chance = 2,
        maxDelay = 1
    })
end

--- Must be implemented by AI.
---
--- @return void
function AiVoicePack:speakNotifyTeamOfBomb() end
--}}}

--{{{ Round Start
--- @return void
function AiVoicePack:speakRoundStart()
    self:speak({
        "RoundStart_1",
        "RoundStart_2",
        "RoundStart_3",
    }, {
        chance = 3,
        maxDelay = 4
    })
end
--}}}

--{{{ Round End
--- @return void
function AiVoicePack:speakRoundEndWon()
    self:speak({
        "RoundEndWon_1",
        "RoundEndWon_2",
        "RoundEndWon_3",
    }, {
        chance = 3,
        maxDelay = 4
    })
end

--- @return void
function AiVoicePack:speakRoundEndLost()
    self:speak({
        "RoundEndLost_1",
        "RoundEndLost_2",
        "RoundEndLost_3",
    }, {
        chance = 3,
        maxDelay = 4
    })
end
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
function AiVoicePack:speakClientDefusingBomb()
    self:speak({
        "ClientDefusingBomb_1",
    }, {
        chance = 1,
        maxDelay = 1
    })
end

--- @return void
function AiVoicePack:speakEnemyDefusingBomb()
    self:speak({
        "EnemyDefusingBomb_1",
        "EnemyDefusingBomb_2",
    }, {
        chance = 1,
        maxDelay = 2
    })
end

--- @return void
function AiVoicePack:speakClientPlantingBomb()
    self:speak({
        "ClientPlantingBomb_1",
    }, {
        chance = 1,
        maxDelay = 1
    })
end

--- @return void
function AiVoicePack:speakEnemyPlantingBomb()
    self:speak({
        "EnemyPlantingBomb_1",
        "EnemyPlantingBomb_2",
    }, {
        chance = 1,
        maxDelay = 2
    })
end

--- @return void
function AiVoicePack:speakClientThrowingFlashbang()
    self:speak({
        "ClientThrowingFlashbang_1",
        "ClientThrowingFlashbang_2",
        "ClientThrowingFlashbang_3",
        "ClientThrowingFlashbang_4",
    }, {
        chance = 1,
        maxDelay = 0.4
    })
end

--- @return void
function AiVoicePack:speakClientThrowingSmoke()
    self:speak({
        "ClientThrowingSmoke_1",
        "ClientThrowingSmoke_2",
    }, {
        chance = 2,
        maxDelay = 0.4
    })
end

--- @return void
function AiVoicePack:speakClientThrowingHeGrenade()
    self:speak({
        "ClientThrowingHeGrenade_1",
        "ClientThrowingHeGrenade_2",
    }, {
        chance = 2,
        maxDelay = 0.4
    })
end

--- @return void
function AiVoicePack:speakClientThrowingIncendiary()
self:speak({
        "ClientThrowingIncendiary_1",
        "ClientThrowingIncendiary_2",
    }, {
        chance = 2,
        maxDelay = 0.4
    })end
--}}}

return Nyx.class("AiVoicePackSmamuel", AiVoicePackSmamuel, AiVoicePack)
--}}}
