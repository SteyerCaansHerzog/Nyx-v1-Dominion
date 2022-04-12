--{{{ Dependencies
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
--}}}

return {
    TINY = ISurface.createFont("Segoe UI", 18, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    SMALL = ISurface.createFont("Segoe UI", 21, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    SMALL_BOLD = ISurface.createFont("Segoe UI", 21, ISurface.WEIGHT_BOLD, ISurface.FLAG_ANTIALIAS),
    MEDIUM = ISurface.createFont("Segoe UI", 24, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    MEDIUM_BOLD = ISurface.createFont("Segoe UI", 24, ISurface.WEIGHT_BOLD, ISurface.FLAG_ANTIALIAS),
    MEDIUM_LARGE = ISurface.createFont("Segoe UI", 28, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    LARGE = ISurface.createFont("Segoe UI", 36, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS),
    LARGE_BOLD = ISurface.createFont("Segoe UI", 36, ISurface.WEIGHT_BOLD, ISurface.FLAG_ANTIALIAS),
}
