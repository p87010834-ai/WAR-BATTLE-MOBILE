# Tank vertical slice — Unity setup

This is an implementation scaffold for the tank-combat vertical slice, not a finished or tested Unity project. Scenes, prefabs, art, input bindings, effects, UI, bots, networking, and device testing still need integration.

## 1. Create the project

- Use Unity 6 with the Universal Render Pipeline (URP).
- Create an Android project and install the Input System package if using its UI components.
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
- Add TankWeapon to TankRoot; assign Muzzle, projectile prefab, and aiming camera.
- Keep the CharacterController on the root. Do not add a non-kinematic Rigidbody to the same root.

## 3. Projectile prefab

Create a small 3D object (for example, a capsule aligned along its local +Z axis) and make it a prefab.

- Add a Rigidbody and a non-trigger Collider.
- Add TankProjectile to the same object.
- Use a small collider and a mass appropriate to the shell; enable continuous dynamic collision detection (the script also configures this).
- Assign this prefab to TankWeapon.projectilePrefab.
- The projectile uses Unity gravity and physical travel time. It currently stops at the first collision; it does not penetrate through multiple objects.

## 4. Armour hitboxes

- Add separate colliders to the hull, turret, engine area, and track areas.
- Add TankArmorZone to each armour collider.
- Set the zone's thickness in millimetres and select the module it protects.
- If a collider has no TankArmorZone, the projectile uses a simplified 80 mm fallback.
- The impact angle is measured from the surface normal. Oblique hits have greater effective armour thickness; very shallow hits can ricochet.
- Penetration decreases with distance using a configurable linear approximation.
- A successful penetration damages the module associated with that armour zone. A non-penetrating hit does not apply module damage.

This is a starter approximation, not a certified real-world ballistics model. It does not yet model shell deformation, layered/composite armour, spall liners, fragments, fuse behavior, internal component geometry, or penetration through multiple layers.

## 5. Mobile controls

- Left virtual joystick: call `TankMovement.SetMoveInput(Vector2)` continuously; send zero when released.
- Right aiming touch area: call `TankTurretAim.SetAimScreenPosition(Vector2)` with screen pixel coordinates.
- Fire button: call `TankWeapon.Fire()` on button press.
- Subscribe to `TankWeapon.AmmunitionChanged` for ammunition/reload UI.

## 6. Damage behavior

- Configure module health values on TankHealth.
- If not using TankArmorZone, collider names containing `engine`, `turret`, `lefttrack`, or `righttrack` select the damaged module.
- Hull destruction raises TankDestroyed.
- Track damage reduces movement performance; engine damage stops propulsion; turret damage disables aiming and firing.

## 7. Next implementation tasks

1. Add penetration-through-multiple-layers and fragment/spall damage.
2. Add server-authoritative hit validation before online multiplayer.
3. Add AI tank navigation and combat behavior.
4. Build the ruined-city capture map, match rules, HUD, minimap, and touch-control prefab.
5. Add edit-mode tests, compile in Unity, verify Play Mode, then build and test on Android.

## Status

These C# files are initial integration scaffolding. They have not been compiled in Unity or tested on a device.