# WAR BATTLE MOBILE — Godot migration

Development is isolated on branch `godot-migration`; the legacy Unity project is untouched.

## Prototype systems
- Godot 4.4 Compatibility-renderer 3D greybox arena and Russian HUD.
- Player tank movement, firing, armor, module damage and destruction.
- Three team capture points, ownership, match timer and team scoring.
- Player and bot respawns; bots dynamically select the nearest living opponent.
- Localized tank module damage: gun disabled temporarily, engine damage reduces speed, track damage reduces turning.
- Stationary field repair for the player: hold E on desktop or the mobile РЕМОНТ button; stay still while repairing.
- Swept ray collision for fast tank shells, helping prevent them tunneling through thin obstacles.
- Virtual joystick, mobile fire and repair controls.

## Controls
- W / S: forward / reverse
- A / D: turn
- Space: fire
- E: repair (must remain stationary)
- R: restart

## Status
This is an early greybox prototype, not a finished game or APK. Vehicle geometry is placeholder geometry. Recent code changes are committed but have not been validated by running Godot or on an Android device. The configured GitHub Actions headless check has not yet been confirmed.

Still outstanding: original production vehicle/environment art, sound, aircraft, ships, authoritative online multiplayer/server infrastructure, accounts and social systems, production UI, Android export/signing and device performance testing.