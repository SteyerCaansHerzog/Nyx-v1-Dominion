*Please see Dominion's v2 tree for the latest versions. The default, v1, is a legacy version.*

# Nyx.to Dominion AI
Competitive matchmaking bot for CS:GO.

## Dependencies
- Nyx-API https://github.com/SteyerCaansHerzog/Nyx-v1-Api (use branch `v2`)
- CSGO-Weapon-Data https://gamesense.pub/forums/viewtopic.php?id=18807
- Localization-API https://gamesense.pub/forums/viewtopic.php?id=30643
- Web-Sockets-API https://gamesense.pub/forums/viewtopic.php?id=23653
- Trace https://gamesense.pub/forums/viewtopic.php?id=32949

## Installation
Place the project in the `Counter-Strike Global Offensive` directory under `lua/gamesense/Nyx/v1/Dominion`.

Create a Lua file under `lua` named `Nyx-Dominion.lua` and insert the following code:

Copy the `Utility/ConfigValuesDefault.lua` file to `Utility/ConfigValues.lua` and use this file to configure the AI.

```lua
require "gamesense/Nyx/v1/Dominion/Dominion"
```

Create a client config named `Nyx-v1-Dominion`. The config data to import can be found under `lua/gamesense/Nyx/v1/Dominion/Resource/Configuration/Nyx-v1-Dominion.cfg`.

Dominion-specific configuration can be found under `lua/gamesense/Nyx/v1/Dominion/Utility/Config.lua`.

## Supported Maps
- Inferno
- Mirage
- Office
- Overpass
