--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
--}}}

--{{{ AiStateDrop
--- @class AiStateDrop : AiState
--- @field droppingGearTimer Timer
--- @field isDroppingGear boolean
--- @field requestingPlayer Player
--- @field requestableGear fun(): nil This is the equip function to equip the item to drop.
--- @field requestedGear string
local AiStateDrop = {
    name = "Drop",
    requestableGear = {
        bomb = Client.equipBomb,
        weapon = Client.equipPrimary
    }
}

--- @param fields AiStateDrop
--- @return AiStateDrop
function AiStateDrop:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDrop:__init()
    self.droppingGearTimer = Timer:new()
    self.isDroppingGear = false
end

--- @param player Player
--- @param requestedGear string
--- @return void
function AiStateDrop:dropGear(player, requestedGear)
    self.requestingPlayer = player
    self.isDroppingGear = true
    self.requestedGear = requestedGear

    self.requestableGear[requestedGear]()
end

--- @return number
function AiStateDrop:assess()
    return self.isDroppingGear and AiPriority.DROP or AiPriority.IGNORE
end

--- @return void
function AiStateDrop:activate()
    self.ai.nodegraph:pathfind(self.requestingPlayer:getOrigin(), {
        task = "Drop teammate my item"
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDrop:think(cmd)
    self.activity = string.format("Dropping %s", self.requestedGear)

    self.ai.canLookAwayFromFlash = false
    self.ai.canUseGear = false

    local player = AiUtility.client
    local distance = player:getOrigin():getDistance(self.requestingPlayer:getOrigin())
    local hitbox = self.requestingPlayer:getOrigin():offset(0, 0, 64)
    local isFreezeTime = Entity.getGameRules():m_bFreezePeriod() == 1

    if isFreezeTime or distance < 300 then
        self.ai.view:lookAtLocation(hitbox, 8, self.ai.view.noiseType.MINOR, "Drop look at requester")
    end

    if isFreezeTime or distance < 200 then
        -- Stop approaching the player.
        if self.ai.nodegraph:isActive() then
            self.ai.nodegraph:clearPath("Drop reached destination")
        end

        local fov = Client.getCameraAngles():getFov(Client.getEyeOrigin(), hitbox)

        -- We're looking close enough to the player.
        if fov < 20 then
            self.droppingGearTimer:ifPausedThenStart()

            -- We need to buy something before we can drop.
            if isFreezeTime and not player:hasWeapons(AiUtility.mainWeapons) and player:m_iAccount() > 3200 then
                UserInput.execute("buy m4a4; buy ak47; buy m4a1_silencer")
            end

            -- Drop gear.
            if self.droppingGearTimer:isElapsedThenStop(0.33) then
                self.ai.voice.pack:speakGifting()

                Client.dropGear()

                self.isDroppingGear = false

                -- We need to rebuy.
                if isFreezeTime or AiUtility.roundTimer:isNotElapsed(5) then
                    self:buyGear()
                end
            end
        end
    end
end

--- @return void
function AiStateDrop:buyGear()
    Client.fireAfter(Client.getRandomFloat(0.75, 1.25), function()
        if not AiUtility.client:hasWeapons(AiUtility.mainWeapons) then
            local balance = AiUtility.client:m_iAccount()

            if not balance or (balance and balance >= 3200) then
                UserInput.execute("buy m4a4; buy ak47; buy m4a1_silencer")
            end
        end
    end)
end

return Nyx.class("AiStateDrop", AiStateDrop, AiState)
--}}}
