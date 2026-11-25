# WAR BATTLE MOBILE — validation checklist

The GitHub Actions Android workflow performs these automated checks on every change under `godot/`:

1. Imports the Godot project and its resources.
2. Parses every GDScript file with Godot's `--check-only` mode. Any parse error fails the workflow.
3. Starts the main scene headlessly for a short smoke test.
4. Exports and signs a debug Android APK.
5. Uploads the APK as the `WAR-BATTLE-MOBILE-Android-debug` artifact.

## Manual device checks still required

Automated headless validation cannot replace testing on a physical Android device. Before calling a build device-verified, install it and check:

- First launch, menu navigation, hangar and vehicle selection.
- Tank movement, aiming, firing, damage, repair and respawn.
- Aircraft steering, throttle, pitch, roll and firing.
- Ship movement, firing, module damage and repair.
- Touch controls in portrait/landscape as configured.
- Settings persistence after closing and relaunching.
- Frame rate, memory use, device temperature and stability over a longer session.

Online accounts, authoritative multiplayer servers, matchmaking and cross-device persistence are not validated by this prototype workflow.
