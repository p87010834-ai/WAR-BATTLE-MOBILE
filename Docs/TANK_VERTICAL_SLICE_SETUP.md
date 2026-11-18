# Tank vertical slice — Unity setup

This is an implementation scaffold for the tank-combat vertical slice, not a finished or tested Unity project. Scenes, prefabs, art, input bindings, effects, UI, bots, networking, and device testing still need integration.

## 1. Create the project

- Use Unity 6 with the Universal Render Pipeline (URP).
- Create an Android project and install the Input System package if using its UI components.
- Create folders matching the paths under `Assets/Scripts`.

## 2. Tank prefab

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

## 3. Projectile prefab and armour zones

- Create a small shell object with a Rigidbody, non-trigger Collider, and TankProjectile component.
- Assign the prefab to TankWeapon.projectilePrefab.
- Add separate armour colliders to hull, turret, engine, transmission, breech, optics, ammunition rack, and track hit areas.
- Add TankArmorZone to each armour collider. Set its thickness in millimetres and its damagedModule field.
- The projectile currently stops at the first collision. This starter model does not yet simulate penetration through multiple physical layers.
- Oblique impacts increase effective armour thickness; shallow impacts can ricochet. Penetration decreases with distance using a simple linear approximation.

## 4. Internal module damage and gameplay consequences

Configure module health in TankHealth. Suggested hitbox mapping:

| Hitbox area | TankModule | Consequence at zero health |
|---|---|---|
| Hull | Hull | Vehicle destroyed |
| Engine | Engine | Maximum movement speed is reduced |
| Transmission | Transmission | Steering response is heavily reduced |
| Turret ring | Turret | Turret aiming is disabled |
| Gun breech | GunBreech | Cannon cannot fire |
| Sights / optics | Optics | Aiming input no longer controls the turret |
| Ammunition rack | AmmunitionRack | Remaining ammunition is set to zero |
| Left track | LeftTrack | Mobility and turning are reduced |
| Right track | RightTrack | Mobility and turning are reduced |

A module reaching zero health raises the ModuleDisabled event once. ModuleHealthChanged reports current and maximum health for HUD bars and damage indicators. Hull destruction raises TankDestroyed.

The ammunition rack is disabled without an automatic explosion in this prototype. Crew injury/loss, fire propagation, ammo cook-off, repair, and recovery systems are not implemented.

## 5. Mobile controls

- Left virtual joystick: call `TankMovement.SetMoveInput(Vector2)` continuously; send zero when released.
- Right aiming touch area: call `TankTurretAim.SetAimScreenPosition(Vector2)` with screen pixel coordinates.
- Fire button: call `TankWeapon.Fire()` on button press.
- Subscribe to `TankWeapon.AmmunitionChanged` for ammunition/reload UI.
- Subscribe to `TankHealth.ModuleHealthChanged` and `ModuleDisabled` to display module damage.

## 6. Current limitations and next tasks

- Ballistics use Unity Rigidbody gravity and first-contact collision; no multi-layer penetration, fragments, spall, fuse, or server authority yet.
- Armour and penetration calculations are gameplay approximations, not a validated real-world simulation.
- AI navigation, match rules, capture map, HUD, minimap, touch-control prefab, automated tests, and Android device testing remain to be built.
- These scripts have not been compiled in Unity or tested on a device.
