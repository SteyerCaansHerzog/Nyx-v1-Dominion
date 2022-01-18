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
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ Enums
--- @class AiRadioMessage
local AiRadioMessage = {
    DEATH_CRY = "DeathCry",
    FRIENDLY_FIRE = "FriendlyFire",
    NEED_SMOKE = "NeedSmoke",
    NEED_QUIET = "NeedQuiet",
    HOLD_POSITION = "HoldPosition",
    SPOTTED_LOOSE_BOMB = "SpottedLooseBomb",
    WE_PLANTED = "WePlanted",
    SNIPER_WARNING = "SniperWarning",
    SPOTTED_BOMBER = "SpottedBomber",
    LAST_MAN_STANDING = "LastManStanding",
    SCARED_EMOTE = "ScaredEmote",
    THREE_ENEMIES_LEFT = "ThreeEnemiesLeft",
    TWO_ENEMIES_LEFT = "TwoEnemiesLeft",
    ONE_ENEMY_LEFT = "OneEnemyLeft",
    KILLED_MY_ENEMY = "KilledMyEnemy",
    MY_HEADSHOT = "MyHeadshot",
    I_KILLED_SNIPER = "IKilledSniper",
    SNIPER_KILLED = "SniperKilled",
    SAW_HEADSHOT = "SawHeadshot",
    STICK_TOGETHER = "StickTogether",
    FOLLOW_ME = "FollowMe",
    SPREAD_OUT = "SpreadOut",
    TEAM_FALL_BACK = "TeamFallBack",
    GO_GO_GO = "GoGoGo",
    ECO_ROUND = "EcoRound",
    SPEND_ROUND = "SpendRound",
    NEED_LEADER = "NeedLeader",
    NEED_DROP = "NeedDrop",
    NEED_PLAN = "NeedPlan",
    COVER_ME = "CoverMe",
    HELP = "help",
    HOLD_POSITION = "HoldPosition",
    SPOTTED_LOOSE_BOMB = "SpottedLooseBomb",
    GOING_TO_GUARD_LOOSE_BOMB = "GoingToGuardLooseBomb",
    PICKED_UP_C4 = "PickedUpC4",
    WE_PLANTED = "WePlanted",
    WAITING_FOR_HUMAN_TO_DEFUSE_BOMB = "WaitingForHumanToDefuseBomb",
    ENEMY_SPOTTED = "EnemySpotted",
    SNIPER_WARNING = "SniperWarning",
    SPOTTED_BOMBER = "SpottedBomber",
    CLEAR = "Clear",
    IM_ATTACKING = "ImAttacking",
    COVERING_FRIEND = "CoveringFriend",
    PINNED_DOWN = "PinnedDown",
    IN_COMBAT = "InCombat",
    WON_ROUND = "WonRound",
    ROUND_LOST = "RoundLost",
    THANKS = "Thanks",
    SORRY = "Sorry",
    COMPLIMENT = "Compliment",
    DISAGREE = "Disagree",
    AGREE = "Agree",
}

--- @class AiRadioColor
local AiRadioColor = {
    DEFAULT = "\x08",
    WHITE = "\x01",
    DARK_RED = "\x02",
    LILAC = "\x03",
    GREEN = "\x04",
    LIGHT_GREEN = "\x05",
    LIME = "\x06",
    RED = "\x07",
    GREY = "\x08",
    YELLOW = "\x09",
    CHALK = "\x0A",
    LIGHT_BLUE = "\x0B",
    BLUE = "\x0C",
    GREY2 = "\x0D",
    PURPLE = "\x0E",
    LIGHT_RED = "\x0F",
    GOLD = "\x10"
}
--}}}

--{{{ AiRadio
--- @class AiRadio : Class
--- @field enabled boolean
--- @field message AiRadioMessage
--- @field color AiRadioColor
--- @field cooldown Timer
local AiRadio = {
    enabled = true,
    message = AiRadioMessage,
    color = AiRadioColor
}

--- @param fields AiRadio
--- @return AiRadio
function AiRadio:new(fields)
	return Nyx.new(self, fields)
end

--- @return nil
function AiRadio:__init()
    self:initFields()
    self:initEvents()
end

--- @return nil
function AiRadio:initFields()
    self.cooldown = Timer:new(1)
end

--- @return nil
function AiRadio:initEvents()
    Callbacks.playerDeath(function(e)
        if e.attacker:isClient() then
            if e.victim:isEnemy() then
                if Client.getChance(10) then
                    self:speak(AiRadioMessage.DEATH_CRY, 1, 1, 2, "I %slike %stoblerones%s.", AiRadioColor.YELLOW, AiRadioColor.GOLD, AiRadioColor.DEFAULT)
                else
                    self:speak(AiRadioMessage.KILLED_MY_ENEMY, 1, 1, 2, "%s%s%s is down.", AiRadioColor.LIGHT_RED, e.victim:getName(), AiRadioColor.DEFAULT)
                end
            else
                self:speak(AiRadioMessage.SORRY, 1, 1, 2, "Sorry for the teamkill, %s%s%s!", AiRadioColor.LIME, e.victim:getName(), AiRadioColor.DEFAULT)
            end
        end

        if e.victim:isTeammate() then
            if AiUtility.client:getOrigin():getDistance(e.victim:getOrigin()) < 750 then
                self:speak(AiRadioMessage.PINNED_DOWN, 2, 0.5, 1, "%s%s%s is down!", AiRadioColor.LIME, e.victim:getName(), AiRadioColor.DEFAULT)
            end
        end
    end)
end

--- @param message string
--- @param chance number
--- @param minDelay number
--- @param maxDelay number
--- @vararg string
--- @return nil
function AiRadio:speak(message, chance, minDelay, maxDelay, ...)
    if true then
        return
    end

    if not AiRadio.enabled then
        return
    end

    if self.cooldown:isStarted() and not self.cooldown:isElapsedThenStop(self.cooldown.time) then
        return
    end

    if not Client.getChance(chance) then
        return
    end

    local text = string.format(...)

    message = "Null"

    Client.fireAfter(Client.getRandomFloat(minDelay, maxDelay), function()
    	Client.cmd(string.format('playerradio %s "%s%s%s"', message, AiRadioColor.DEFAULT, text, AiRadioColor.WHITE))
    end)
end

return Nyx.class("AiRadio", AiRadio)
--}}}
