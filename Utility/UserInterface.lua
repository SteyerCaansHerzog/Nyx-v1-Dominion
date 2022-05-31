--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ UserInterface
--- @class UserInterface : Class
local UserInterface = {}

--- @param drawPos Vector2
--- @param backgroundColor Color
--- @param borderColor Color
--- @return nil
function UserInterface.drawBackground(drawPos, backgroundColor, borderColor, height)
    local baseDimensions = Vector2:new(450, 0)
    local panelDimensions = Vector2:new(baseDimensions.x, height)

    drawPos:drawBlur(panelDimensions)
    drawPos:drawSurfaceRectangle(panelDimensions, backgroundColor)
    drawPos:drawSurfaceRectangle(Vector2:new(5, height), borderColor)
end

--- @param drawPos Vector2
--- @param font number
--- @param color Color
--- @vararg string
--- @return nil
function UserInterface.drawText(drawPos, font, color, ...)
    local paddingLeft = 10
    local paddingTop = 5

    drawPos:clone():offset(paddingLeft, paddingTop):drawSurfaceText(font, color, "l", string.format(...))
end

--- @param drawPos Vector2
--- @param font number
--- @param node NodeTypeBase
--- @return nil
function UserInterface.drawNode(drawPos, font, node)
    local paddingLeft = 10
    local paddingTop = 5

    drawPos:clone():offset(paddingLeft + 15, paddingTop + 12):drawCircle(8, node.colorPrimary):drawCircleOutline(12, 2, node.colorSecondary)

    drawPos:clone():offset(paddingLeft + 35, paddingTop):drawSurfaceText(font, node.colorPrimary, "l", string.format(
        "[%s] %s",
        node.type, node.name
    ))

    drawPos:offset(0, 35)
end

return Nyx.class("UserInterface", UserInterface)
--}}}
