--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Shorthand = require "gamesense/Nyx/v1/Api/Shorthand"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiChatCommandEval
--- @class AiChatCommandEval : AiChatCommandBase
--- @field environment table
local AiChatCommandEval = {
    cmd = "e",
    requiredArgs = 0,
    isAdminOnly = true,
    isValidIfSelfInvoked = false,
    environment = {},
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandEval:invoke(ai, sender, args)
    local evalStr = Table.getImplodedTable(args, " ")

    local exposedModules = {
        env = self.environment,
        ai = ai,
        aip = AiPriority,
        aiu = AiUtility,
        cfg = Config,
        col = Color,
        cl = Client,
        ca = Callbacks,
        e = Entity,
        ef = Entity.find,
        lp = LocalPlayer,
        ms = Messenger,
        n = Node,
        ng = Nodegraph,
        nt = NodeType,
        p = Pathfinder,
        pl = Player,
        ang = Angle,
        sf = string.format,
        t = Time,
        tr = Trace,
        v2 = Vector2,
        v3 = Vector3,
        pr = function(...)
            print(string.format(...))
        end,
        say = function(...)
        	Messenger.send(string.format(...), false)
        end,
        info = function(...)
        	ai.processes.info:addInfo(string.format(...))
        end,
        rnd = function(origin, radius, colorCode)
        	local colors = {
                w = Color.WHITE,
                r = Color.RED,
                g = Color.GREEN,
                b = Color.BLUE
            }

            local color

            if colorCode == "team" then
                color = LocalPlayer:isTerrorist() and ColorList.TERRORIST or ColorList.COUNTER_TERRORIST
            else
                color = colors[colorCode] or colors.w
            end

            colorCode = colorCode or "w"

            ai.processes.info:addRenderable({
                origin = origin,
                color = color,
                radius = radius
            })
        end
    }

    local result = Shorthand.evaluate(evalStr, exposedModules)

    if not result.isOk then
        Logger.console(Logger.ERROR, "Evaluation failed with: %s", result.error)
        Logger.console(Logger.ERROR, "Tried to evaluate: %s", result.expanded)

        return Localization.cmdRejectionLuaError
    end
end

return Nyx.class("AiChatCommandEval", AiChatCommandEval, AiChatCommandBase)
--}}}
