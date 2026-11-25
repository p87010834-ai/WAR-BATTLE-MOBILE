# WAR BATTLE MOBILE — Godot migration

Development is isolated on branch `godot-migration`; the legacy Unity project and `main` branch are untouched.

## Current prototype foundations
- Godot 4.4 Compatibility-renderer 3D greybox arena and Russian HUD.
- Player tank movement, firing, armor, module damage, destruction and respawn.
- Three team capture points, ownership, match timer and team scoring.
- AI tank opponents, nearest-target selection and bot respawns.
- Stationary field repair for the player (E / mobile button).
- Swept ray collision for fast tank shells.
- Virtual joystick, mobile fire and repair controls.
- Responsive combat HUD anchors: top status panel stretches with screen width and control hints stay attached to the bottom edge.
- Aircraft prototype: procedural low-poly test airframe, pitch/roll/yaw, throttle and ray-tested cannon projectile.
- Naval prototype: procedural test ship, movement, steering, health and weapon placeholder.
- Weather prototype: moving procedural cloud clusters and fog controls.
- Local profile: save/load, level progression to 100, XP, battle stats and daily reward date guard.
- Local settings persistence: audio levels, graphics preset value, sensitivity, language and control options.
- Local mission progress and reward claims; local season XP and 50-tier progression state.
- Achievement persistence and initial battle/victory/kill milestones.
- Username validation (3–16 chars; Cyrillic/Latin/digits/underscore/hyphen) and a basic profanity mask for chat text.
- Replay sample recorder writing local JSON telemetry.
- ENet host/join/leave session wrapper (transport foundation only; not a production online game service).
- Vehicle catalog data and RU/EN text lookup foundations.
- Match rule helpers for 1–10 players per team and score/timer utilities.

## Controls
Tank: W/S move, A/D turn, Space fire, E repair, R restart.
Aircraft test controller: I/K pitch, J/L roll, A/D yaw, W/S throttle, Space fire.
Ship test controller: W/S throttle, A/D steering, Space fire.

## Critical implementation status
This is an early prototype, NOT a complete game and NOT an Android APK. Tank combat is the only mode currently running in the main arena. Aircraft and ship scripts are not yet integrated into a vehicle selection flow or a shared combined-arms battle. Weather, profile, settings, missions, achievements, season state, replay and social rules are local foundations, not complete production systems.

The ENet wrapper can host/join a peer session but there is no authoritative dedicated server, matchmaking, persistence backend, account authentication, anti-cheat, secure economy, cross-device profile sync or production network protocol. Local profile/mission/season/achievement data can be modified on the device and must not be trusted for a live competitive game. Chat filtering is only a client-side preliminary mask; server moderation and reporting are absent.

## Still required for a full release
- Production-grade original vehicle models, animations, materials, damage visuals, sound and licensed/original effects.
- Complete maps, collision/navigation, destructible environments, carrier operations and spawn systems.
- Fully integrated tanks + aircraft + ships, balanced combat, complete aircraft/ship damage and weapon physics.
- Dedicated authoritative multiplayer servers, matchmaking, reconnect, lag compensation, server-side validation, anti-cheat and regional infrastructure.
- Accounts, secure cloud saves, friends, parties, clans, clan territory war, gifts and referral system.
- Server-backed missions, daily/weekly rewards, battle pass, ranked seasons, events, shop and purchase validation.
- Full localization, responsive mobile UI, hangar, vehicle progression, settings screens, accessibility and tutorial.
- Replay playback/free camera and export/share.
- AI GUARD moderation dashboard, player reports, chat server filters and admin tools.
- Android export preset, signing configuration, device compatibility, performance profiling, thermal management and store compliance.
- Automated unit/integration tests, multiplayer load tests, security review and real-device QA.

## Cloud Android build
- `export_presets.cfg` defines a debug APK export named "Android" for ARM64 devices.
- `.github/workflows/godot-android-build.yml` installs Godot 4.4.1 export templates, Java 17 and Android SDK dependencies, imports/parses the project, runs a short headless smoke test, exports a debug APK and uploads it as a 14-day GitHub Actions artifact.
- The workflow creates a temporary debug signing key for CI. This is for testing only; it is not a production release signing key.
- The workflow runs on pushes to `godot-migration` when Godot files or this workflow change, and can also be started manually from GitHub Actions.

## Validation
The cloud build workflow has been committed but has not yet been confirmed successful. The project has not yet been opened or run in the Godot editor or on an Android device in this session. Do not treat committed source or a configured workflow as a verified build. A successful CI run and APK artifact are still required.
