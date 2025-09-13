# SupraTools

This is a collection of mods for Supra games (Surpraland, Supraland Crash, Supraland: SIU, Supraworld, etc.)

* These mods include Fast Travel (works for all games, press "F" on the map to teleport), Debug Camera, etc.

## Installation

* Download latest UE4SS-RE: https://github.com/UE4SS-RE/RE-UE4SS/releases
* Copy `ue4ss` folder and `dwmapi.dll` to `Binaries/Win64`, next to `*Win64-Shipping exe`.
* Copy all the files in the repository to `ue4ss/Mods/Supratools` folder.
* UE 5.6.1+ releases (Supraworld) may need editing `ue4ss/UE4SS-settings.ini`, e.g.:

```ini
[EngineVersionOverride]
MajorVersion = 5
MinorVersion = 6
```

* Run the game.
* Check `ue4ss/UE4SS.log` for issues.
* Read project wiki for details: https://github.com/joric/SupraTools/wiki

