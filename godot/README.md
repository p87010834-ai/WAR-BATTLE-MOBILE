# WAR BATTLE MOBILE — Godot migration

Development is isolated on branch `godot-migration`. The previous Unity project is not modified.

## Current prototype systems
- Godot 4.4 project using the Compatibility renderer.
- Procedurally assembled 3D greybox arena and Russian HUD.
- Player tank movement, firing, armor and destruction.
- Three team capture objectives with neutral/blue/red ownership.
- Match countdown and team score from held objectives.
- Player and bot respawns after destruction.
- Allied and enemy bots dynamically select the nearest living opponent.
- Virtual joystick and touch fire control scripts.

## Controls
- W / S: forward / reverse
- A / D: turn
- Space: fire
- R: restart the match

## Status and limitations
This remains an early greybox prototype, not a finished game and not an APK. Tank visuals are primitive geometry. The capture/respawn/AI changes have been committed but have not yet been validated by launching Godot or running on an Android device. The GitHub Actions workflow is configured for a headless Godot check, but its result has not been confirmed.

Aircraft, ships, production-quality original models/materials/audio, full menus, accounts, authoritative online multiplayer/server infrastructure and Android export/signing remain to be implemented. The Unity project remains untouched.
