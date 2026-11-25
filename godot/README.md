# WAR BATTLE MOBILE — Godot migration

Development is isolated on branch `godot-migration`; the legacy Unity project is untouched.

## Prototype systems
- Godot 4.4 Compatibility-renderer 3D greybox arena and Russian HUD.
- Player tank controls, firing, armor and destruction.
- Three team capture points, ownership, match timer and team scoring.
- Player and bot respawns.
- Team bots select the nearest living opponent.
- Shell impacts pass hit positions into a localized module-damage model:
  - frontal impacts can disable the gun temporarily;
  - rear impacts damage the engine and reduce speed;
  - side impacts can damage tracks and reduce turning;
  - module condition is shown in the HUD.
- Virtual joystick and touch fire-control scripts.

## Controls
- W / S: forward / reverse
- A / D: turn
- Space: fire
- R: restart

## Status
This is an early greybox prototype, not a finished game or APK. Vehicle geometry is placeholder geometry. Recent gameplay code has been committed but has not been validated by running Godot or on an Android device. The configured GitHub Actions headless check has not yet been confirmed.

Still outstanding: proper original vehicle and environment art, sound, aircraft, ships, authoritative online multiplayer/server infrastructure, accounts and social systems, production UI, Android export/signing and device performance testing.