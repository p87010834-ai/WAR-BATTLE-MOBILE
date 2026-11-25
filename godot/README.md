# WAR BATTLE MOBILE — Godot migration

This folder is the new engine-independent-from-Unity project root. The Unity project is left untouched in the repository history and on the main branch; development is isolated on branch `godot-migration`.

## Current prototype
- Godot 4.4 project, Compatibility renderer for broad mobile GPU support.
- Procedurally assembled 3D greybox arena.
- Player tank movement, turret and shell firing.
- Four basic enemy tanks with pursuit and firing behavior.
- Armor/health and destruction loop.
- Russian combat HUD.

## Controls (desktop smoke-test)
- W / S: forward / reverse
- A / D: turn
- Space: fire
- R: restart after defeat

## Important status
This is an early playable-prototype foundation, not the finished game and not an APK. The tank visuals are primitive greybox geometry. Mobile touch controls, aircraft, ships, multiplayer/server authority, production art/audio, menus and Android export configuration are still pending. No Unity Editor or Unity cloud build is required for this Godot project.

## Next development milestones
1. Validate the project with Godot headless CI and fix parser/runtime errors.
2. Add touch controls and a mobile camera.
3. Replace greybox tank parts with original optimized models/materials.
4. Add capture points, respawn rules and improved bot tactics.
5. Configure Android export and produce a test APK through a cloud runner.
