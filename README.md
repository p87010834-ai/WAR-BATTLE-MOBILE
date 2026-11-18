# WAR BATTLE MOBILE

A mobile combined-arms combat game planned for Unity 6 and URP, targeting Android.

## Development roadmap

1. Complete a playable tank-combat vertical slice.
2. Expand with aviation and naval combat.
3. Add large-scale online multiplayer and social systems.

## Tank-combat vertical slice

- Two teams with a player and AI bots.
- Tank movement, turret aiming, firing, reloading, ballistics, and armor penetration.
- Modular damage for hull, engine, turret, and tracks.
- A ruined-city map with cover, obstacles, and capture objectives.
- Match scoring, timer, victory/defeat flow, and mobile touch controls.
- HUD for health, ammunition, minimap, FPS, and network ping.

## Planned systems

- Aviation and naval vehicles and modes.
- Text chat (no voice chat), player gifts, and player reports.
- A skippable cinematic victory flyover with player names and match statistics.
- Dynamic volumetric clouds with temporary visual disturbances from passing aircraft and projectiles.
- Crew members represented only as visual models inside vehicles; no medical kits, healing, or revival mechanics.
- Target installed size of approximately 8.5 GB, achieved through quality assets, compression, optimization, and optional resource downloads rather than artificial padding.

## Unity project bootstrap

The repository now includes a Unity 6 project shell, URP/UGUI package manifest, and an Editor menu tool that generates a greybox tank scene and placeholder player/bot/projectile prefabs. Open the folder in Unity and run **Tools > WAR BATTLE MOBILE > Build Tank Vertical Slice**. See [Assets/WarBattleMobile/SETUP.md](Assets/WarBattleMobile/SETUP.md).

The generator is source code only and has not been executed in Unity in this workflow. The scene/prefabs are generated locally by the Unity Editor; no APK or verified playable build is currently available.

## Project status

The repository contains an early Unity C# prototype for tank movement, turret aiming, projectile ballistics, modular damage, bots, capture points, match rules, spawning/respawning, camera, runtime HUD/touch controls, procedural greybox city generation, destructible environment, and placeholder combat effects/audio.

This is not yet a complete playable game build. The repository currently lacks a configured Unity project/scene, authored tank and projectile prefabs, production art/audio assets, a configured minimap RenderTexture, final input setup, and verified Android build settings. Unity compilation, Play Mode integration, and device testing have not been confirmed. See `Docs/TANK_VERTICAL_SLICE_SETUP.md` for setup requirements and limitations.
