--{{{ Dependencies
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
--}}}

return {
    TINY = ISurface.createFont("Yu Gothic UI", 18, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    SMALL = ISurface.createFont("Yu Gothic UI", 21, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    SMALL_BOLD = ISurface.createFont("Yu Gothic UI", 21, ISurface.WEIGHT_BOLD, ISurface.FLAG_ANTIALIAS),
    MEDIUM = ISurface.createFont("Yu Gothic UI", 24, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    MEDIUM_BOLD = ISurface.createFont("Yu Gothic UI", 24, ISurface.WEIGHT_BOLD, ISurface.FLAG_ANTIALIAS),
    MEDIUM_LARGE = ISurface.createFont("Yu Gothic UI", 28, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    LARGE = ISurface.createFont("Yu Gothic UI", 36, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    LARGE_BOLD = ISurface.createFont("Yu Gothic UI", 36, ISurface.WEIGHT_BOLD, ISurface.FLAG_ANTIALIAS),
}
