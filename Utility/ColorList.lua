--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
--}}}

return {
    -- Main.
    PRIMARY = Color:rgba(89, 199, 115),

    -- Status.
    OK = Color:rgba(71, 255, 102),
    INFO = Color:rgba(71, 212, 255),
    WARNING = Color:rgba(255, 203, 71),
    ERROR = Color:rgba(255, 89, 89),
    INTERNAL = Color:rgba(150, 150, 255),

    -- Background.
    BACKGROUND_1 = Color:rgba(50, 50, 50, 100),
    BACKGROUND_2 = Color:rgba(60, 60, 60, 100),
    BACKGROUND_3 = Color:rgba(80, 80, 80, 100),

    -- Font.
    FONT_NORMAL = Color:rgba(255, 255, 255),
    FONT_MUTED = Color:rgba(160, 160, 160),
    FONT_MUTED_EXTRA = Color:rgba(110, 110, 110),

    -- Teams.
    COUNTER_TERRORIST = Color:hsla(195, 0.8, 0.6),
    TERRORIST = Color:hsla(33, 0.8, 0.6),

    -- Reaper.
    IS_CLIENT_BG = Color:rgba(140, 140, 140, 100),
    IS_CLIENT_OUTLINE = Color:rgba(204, 204, 204, 255),
    IS_ATTACKED = Color:rgba(229, 113, 25, 255),
    IS_DEAD = Color:rgba(191, 63, 63, 50),
    IS_DISCONNECTED = Color:rgba(89, 89, 89, 100),
    IS_FINE = Color:rgba(51, 51, 51, 100),
    IS_FLASHED = Color:rgba(255, 255, 255, 255),
    IS_IN_SERVER = Color:rgba(63, 138, 191, 75),
    IS_THREATENED = Color:rgba(191, 148, 63, 100),
    TEXT_ATTACKED = Color:rgba(248, 183, 133, 255),
    TEXT_DEAD = Color:rgba(234, 71, 71, 255),
    TEXT_THREATENED = Color:rgba(249, 219, 158, 255),
}
