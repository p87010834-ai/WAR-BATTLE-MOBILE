# WAR BATTLE MOBILE — Unity project bootstrap

## Required editor

- Unity 6.0 (the project version file targets 6000.0.35f1)
- Android Build Support, Android SDK & NDK Tools, and OpenJDK for Android builds
- URP 17 and UGUI 2 are declared in Packages/manifest.json

## Generate the first tank scene

1. Open the repository folder as a Unity project.
2. Wait for Package Manager to resolve URP and UGUI and for Unity to finish importing scripts.
3. If the Console shows compile errors, fix those before continuing. The repository has not yet been compiled in a Unity Editor in this workflow.
4. From the Unity menu choose **Tools > WAR BATTLE MOBILE > Build Tank Vertical Slice**.
5. The editor tool creates:
   - `Assets/WarBattleMobile/Scenes/TankVerticalSlice.unity`
   - `Assets/WarBattleMobile/Prefabs/PlayerTank.prefab`
   - `Assets/WarBattleMobile/Prefabs/BotTank.prefab`
   - `Assets/WarBattleMobile/Prefabs/TankProjectile.prefab`
6. Open the generated scene if it is not already open, then enter Play Mode.
7. Read all `[Tank Vertical Slice]` messages in the Console. Resolve errors before evaluating gameplay.
8. Check player movement, aiming, firing, reload, bot movement/fire, capture progress, team score, destruction and respawn.

## What the generated setup is

This is a greybox integration scaffold, not finished art or a production-ready game. Tank bodies and turrets are primitive meshes, the battlefield is procedural, the HUD is runtime-generated, and audio/minimap art are not assigned. The bot logic is intentionally basic. The editor command generates local Unity assets only after the project is opened in the Unity Editor; a GitHub commit cannot execute that command.

## Known limitations before calling this a playable build

- The setup tool and gameplay scripts still need Unity compilation and Play Mode testing.
- The current placeholder tank prefab uses a CharacterController and primitive visual geometry; it is not a final physically simulated tracked vehicle.
- The minimap panel is a placeholder until a minimap camera and RenderTexture are configured.
- Production vehicle models, animations, materials, effects, sound banks, menus, networking, accounts and matchmaking are not included in this scaffold.
- Android Player Settings, signing, performance profiling and device testing remain to be configured and verified.
