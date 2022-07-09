--{{{ Dependencies
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
--}}}

return {
    TINY = ISurface.createFont("Yu Gothic UI", 18, ISurface.WEIGHT_NORMAL, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    TINY_BOLD = ISurface.createFont("Yu Gothic UI", 18, ISurface.WEIGHT_BOLD, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    SMALL = ISurface.createFont("Yu Gothic UI", 21, ISurface.WEIGHT_NORMAL, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    SMALL_BOLD = ISurface.createFont("Yu Gothic UI", 21, ISurface.WEIGHT_BOLD, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    MEDIUM = ISurface.createFont("Yu Gothic UI", 24, ISurface.WEIGHT_NORMAL, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    MEDIUM_BOLD = ISurface.createFont("Yu Gothic UI", 24, ISurface.WEIGHT_BOLD, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    MEDIUM_LARGE = ISurface.createFont("Yu Gothic UI", 28, ISurface.WEIGHT_NORMAL, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    LARGE = ISurface.createFont("Yu Gothic UI", 36, ISurface.WEIGHT_NORMAL, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
    LARGE_BOLD = ISurface.createFont("Yu Gothic UI", 36, ISurface.WEIGHT_BOLD, bit.bor(ISurface.FLAG_ANTIALIAS, ISurface.FLAG_DROPSHADOW)),
}
