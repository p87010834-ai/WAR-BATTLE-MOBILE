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
- Subscribe to `TankWeapon.AmmunitionChanged` for ammunition/reload UI. The weapon also exposes `ReloadProgress01` (0 to 1) and `IsReloading` for a live reload bar.
- Subscribe to `TankHealth.ModuleHealthChanged` and `ModuleDisabled` to display module damage.

## 6. Current limitations and next tasks

- Ballistics use Unity Rigidbody gravity and first-contact collision; no multi-layer penetration, fragments, spall, fuse, or server authority yet.
- Armour and penetration calculations are gameplay approximations, not a validated real-world simulation.
- AI navigation, match rules, capture map, HUD, minimap, touch-control prefab, automated tests, and Android device testing remain to be built.
- These scripts have not been compiled in Unity or tested on a device.


## 7. Basic tank bots

The first AI implementation is a simple combat opponent, not a full tactical commander.

- Add `TankFaction` to every player-controlled and AI tank root. Assign `Blue` or `Red`; leave `Neutral` for non-combatant vehicles.
- Add `TankBotAI` to the bot root. It requires `TankMovement` and `TankFaction`.
- Assign the bot's `TankHealth`, `TankMovement`, `TankFaction`, `TankWeapon`, `TurretYaw`, `GunPitch`, and `Muzzle` references in the Inspector.
- For an AI tank, leave `TankWeapon.aimCamera` empty so it does not use the player's camera aiming ray.
- Ensure the projectile prefab and muzzle are configured exactly as for a player tank.
- Bots periodically select the nearest living enemy team member in detection range, rotate the turret and gun toward it, keep a preferred engagement distance, reverse or steer around a detected obstacle, check line of sight, and fire when aligned.
- Use different team values for opposing sides. A bot will not target its own team or neutral objects.

AI limitations: target selection is nearest-enemy only; driving uses simple forward/reverse steering and a single obstacle ray, not NavMesh pathfinding. Bots do not yet use cover intelligently, capture objectives, coordinate squads, lead moving targets, or use server-authoritative decisions. Configure `lineOfSightLayers` to include terrain, obstacles, and vehicle hitboxes while excluding decorative triggers where appropriate.


## 8. Capture points and match rules

- Create a GameObject for each objective, add a BoxCollider or SphereCollider with Is Trigger enabled, and add CapturePoint.
- Give each point a unique Point Id, set its capture duration, and size its trigger volume for the intended capture zone. The script enforces trigger mode at runtime.
- Add TankFaction to every participating tank root and set its team to Blue or Red. The tank's non-trigger colliders must overlap the capture volume.
- Add one TankMatchRules component to a scene manager object. Configure match duration, score limit, and points earned per owned objective per second.
- A point captures when only one team is present for the configured duration. If both teams are inside, progress pauses. If no team is present, progress pauses. The owning team earns score while holding points.
- Subscribe to CapturePoint.OwnershipChanged and ProgressChanged for objective markers and capture bars. Subscribe to TankMatchRules.ScoreChanged, TimeChanged, and MatchEnded for the scoreboard, timer, and result screen.
- Bots seek the nearest neutral or enemy-owned capture point when they have no active enemy target. They stop inside the objective radius and contest it through team presence.

Prototype limitations: no spawn system, respawn flow, team balancing, round reset, overtime, network authority, NavMesh routing, or sophisticated multi-bot roles. Simple AI may get stuck on complex geometry. Match rules collect capture points once when the scene starts, so create all points before the match begins.


## 9. Runtime combat HUD

- Add `TankCombatHUD` to a scene UI manager GameObject.
- Assign the local player's `TankHealth`, `TankWeapon`, and `TankFaction` references in the Inspector. Assign the scene's `TankMatchRules`; if left empty, the HUD searches for one at startup.
- The HUD creates its own Screen Space Overlay canvas. It displays Blue/Red score, match countdown, hull health, individual module condition, ammunition count, and reload progress.
- The module panel shows engine, transmission, turret, gun breech, optics, ammunition rack, and both tracks. Disabled modules are marked OFFLINE.
- For a live minimap, create a second orthographic camera looking down at the battlefield, set its target texture to a RenderTexture asset, and assign that same RenderTexture to `TankCombatHUD.minimapTexture`. Set the minimap camera's culling mask to the map/vehicle layers you want visible. If no texture is assigned, the HUD displays a setup placeholder rather than a blank map.
- The minimap camera, RenderTexture asset, scene references, safe-area positioning, final visual styling, and device-specific scaling still require Unity Editor setup and testing.
- This HUD uses Unity's built-in `UnityEngine.UI` legacy Text/Image components; ensure the Unity UI package is available in the project.
