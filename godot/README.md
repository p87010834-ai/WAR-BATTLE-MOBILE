# WAR BATTLE MOBILE — Godot migration

Development is isolated on branch `godot-migration`; the legacy Unity project and `main` branch are untouched.

## Implemented prototype foundations
- Godot 4.4 Compatibility-renderer 3D greybox arena and Russian HUD.
- Player tank movement, firing, armor, module damage, destruction and respawn.
- Three team capture points, ownership, match timer and team scoring.
- AI tank opponents, nearest-target selection and bot respawns.
- Stationary field repair for the player (E / mobile button).
- Swept ray collision for fast tank shells.
- Virtual joystick, mobile fire and repair controls.
- Aircraft foundation: procedural low-poly test airframe, flight control, throttle, pitch/roll/yaw inputs, and ray-tested cannon projectile.
- Naval foundation: procedural test ship, movement, steering, health and weapon placeholder.
- Weather foundation: moving procedural cloud clusters and fog state control.
- Local profile foundation: save/load, level progression to 100, experience, battle statistics and daily reward date guard.
- Match rule helpers for 1–10 players per team, timer formatting and winner text.

## Controls
Tank: W/S move, A/D turn, Space fire, E repair, R restart.
Aircraft test controller: I/K pitch, J/L roll, A/D yaw, W/S throttle, Space fire.
Ship test controller: W/S throttle, A/D steering, Space fire.

## Important status and limitations
This is an early development prototype, NOT a complete game and NOT an Android APK. The new aircraft and ship scripts are reusable foundations and are not yet wired into a vehicle-selection/combined-arms match flow. The weather system currently supplies moving placeholder clouds and fog; it does not yet simulate full rain, snow, seasons, or live real-world weather. The profile is local-only and is not an account/server system.

Not implemented: authoritative online multiplayer, matchmaking, dedicated servers, accounts/authentication, friends, parties, clans, global clan territory war, chat/moderation, shop/payments, battle pass, ranked seasons, missions/events, replay/free camera, production maps, original production-grade vehicle assets, sound, full damage models for aircraft/ships, carrier operations, complete localization/settings UI, Android export/signing, anti-cheat, analytics, backend services and device performance/thermal testing.

## Validation
Code is committed to GitHub but has not been run in the Godot editor or on an Android device in this session. GitHub Actions is configured for a headless import/run check; its result must be inspected before claiming the project passes. Placeholder geometry and scripts must be tested and corrected before expanding toward production.
