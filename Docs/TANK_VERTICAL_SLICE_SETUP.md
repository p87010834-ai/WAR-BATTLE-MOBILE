# Tank vertical slice — Unity setup

This is the first implementation scaffold for the tank-combat vertical slice. It is source code and setup guidance, not a finished or tested Unity project. Unity scenes, prefabs, art, input bindings, effects, UI, bots, networking, and device testing remain to be integrated.

## 1. Create the project

- Use Unity 6 with the Universal Render Pipeline (URP).
- Create an Android project and install the Input System package if you plan to use its UI components.
- Create folders matching the paths under `Assets/Scripts`.

## 2. Build a tank prefab

Suggested hierarchy:

```text
TankRoot
├── Visuals
│   ├── Hull
│   ├── TurretYaw
│   │   └── GunPitch
│   │       └── Muzzle
│   ├── LeftTrack
│   └── RightTrack
└── CameraTarget
```

- Add a CharacterController and TankMovement to TankRoot.
- Add TankHealth to TankRoot.
- Add TankTurretAim to TankRoot; assign TurretYaw and GunPitch.
- Add TankWeapon to TankRoot; assign Muzzle and the aiming camera.
- Add colliders to targetable vehicle parts. Put them on layers included by the weapon's hitLayers mask.
- Keep the CharacterController on the root. Do not add a non-kinematic Rigidbody to the same root.

## 3. Mobile controls

The scripts expose public methods so a mobile UI can call them:

- Left virtual joystick: call `TankMovement.SetMoveInput(Vector2)` continuously; send zero when released.
- Right aiming touch area: call `TankTurretAim.SetAimScreenPosition(Vector2)` with screen pixel coordinates.
- Fire button: call `TankWeapon.Fire()` on button press.
- Add a separate reload/ammunition display by subscribing to `TankWeapon.AmmunitionChanged`.

The current aiming script expects a screen position supplied by the UI. A production implementation should add touch ownership, pointer capture, sensitivity settings, and an explicit camera/reticle design.

## 4. Damage setup and limitations

- Configure module health values on TankHealth.
- Name part collider objects with `engine`, `turret`, `lefttrack`, or `righttrack` to route hits to those modules. Other colliders route to the hull.
- Hull destruction raises TankDestroyed. Subscribe to it to trigger the vehicle destruction flow.
- Track damage currently reduces movement performance; engine damage currently stops propulsion; turret damage disables aiming and firing.
- This starter damage model is intentionally simplified. It does not yet implement armor thickness, shell penetration, ricochet, spalling, crew casualties, component hitboxes, server authority, or physical projectile travel. The weapon uses a raycast hit and an immediate damage result.

## 5. Next implementation tasks

1. Add a projectile simulation with gravity, travel time, impact point, and server-authoritative hit validation.
2. Implement armor zones, penetration calculation, ricochet, and damage transfer.
3. Add AI tank navigation and combat behavior.
4. Build the ruined-city capture map, match rules, HUD, minimap, and touch-control prefab.
5. Create automated edit-mode tests and verify the scene in Unity Play Mode, then build and test on Android.

## Status

The C# files are initial integration scaffolding. They have not been compiled in Unity or tested on a device.