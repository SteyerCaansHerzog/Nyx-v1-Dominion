# Nyx.to Dominion AI
Competitive matchmaking bot for CS:GO.

## Deprecated
This is v1 of Dominion. However v2 is the latest. Please select the v2 branch if you intend to use the latest codebase.

## Dependencies
- https://github.com/SteyerCaansHerzog/Nyx-v1-Api
- https://gamesense.pub/forums/viewtopic.php?id=18807
- https://gamesense.pub/forums/viewtopic.php?id=30643
- https://gamesense.pub/forums/viewtopic.php?id=23653

## Installation
Place the project in the `Counter-Strike Global Offensive` directory under `lua/gamesense/Nyx/v1/Dominion`.

Create a Lua file under `lua` named `Nyx-v1-Dominion.lua` and insert the following code:
```lua
require "gamesense/Nyx/v1/Dominion/Dominion"
```

Create a client config named `Nyx-v1-Dominion`. The config data to import can be found under `lua/gamesense/Nyx/v1/Dominion/Resource/Configuration/Nyx-v1-Dominion.cfg`.

Dominion-specific configuration can be found under `lua/gamesense/Nyx/v1/Dominion/Utility/Config.lua`.
