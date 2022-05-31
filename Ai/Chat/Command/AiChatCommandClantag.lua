--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandClantag
--- @class AiChatCommandClantag : AiChatCommandBase
--- @field clantag string
local AiChatCommandClantag = {
    cmd = "tag",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @return void
function AiChatCommandClantag:__init()
    Callbacks.levelInit(function()
    	self:setClantag(self.clantag)
    end)
end

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandClantag:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    -- Commands are space-delimeted, so we need to get them and re-insert the spaces.
    local clantag = Table.getImploded(args, " ")

    self:setClantag(clantag)

    self.clantag = clantag
end

--- @param clantag string
--- @return void
function AiChatCommandClantag:setClantag(clantag)
    if clantag then
        client.set_clan_tag(clantag)
    else
        client.set_clan_tag()
    end
end

return Nyx.class("AiChatCommandClantag", AiChatCommandClantag, AiChatCommandBase)
--}}}
