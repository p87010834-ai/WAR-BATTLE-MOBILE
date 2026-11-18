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
- Add `MobileTankControls` to the local player's TankRoot. It creates a left movement joystick, a right-side drag-to-aim surface, and a FIRE button. Assign the TankMovement, TankTurretAim, and TankWeapon references, or leave them empty for same-object auto-detection.
- The aim touch position is sent to both the turret controller and weapon, so the shell camera ray follows the point the player is aiming at. The fire button fires once per press; it does not auto-repeat.
- Subscribe to `TankWeapon.AmmunitionChanged` for ammunition/reload UI. The weapon also exposes `ReloadProgress01` (0 to 1) and `IsReloading` for a live reload bar.
- Subscribe to `TankHealth.ModuleHealthChanged` and `ModuleDisabled` to display module damage.

## 6. Current limitations and next tasks

- Ballistics use Unity Rigidbody gravity and first-contact collision; no multi-layer penetration, fragments, spall, fuse, or server authority yet.
- Armour and penetration calculations are gameplay approximations, not a validated real-world simulation.
- Advanced AI navigation, final art, a configured minimap camera/RenderTexture, automated tests, and Android device testing remain outstanding. Core starter scripts for match rules, capture points, HUD, touch controls, and spawning are present but still need Unity scene/prefab integration.
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

Prototype limitations: team spawning and basic respawn are implemented by TankSpawnManager, but there is no team balancing, round reset, overtime, network authority, NavMesh routing, or sophisticated multi-bot roles. Simple AI may get stuck on complex geometry. Match rules collect capture points once when the scene starts, so create all points before the match begins.


## 9. Runtime combat HUD

- Add `TankCombatHUD` to a scene UI manager GameObject.
- Assign the local player's `TankHealth`, `TankWeapon`, and `TankFaction` references in the Inspector. Assign the scene's `TankMatchRules`; if left empty, the HUD searches for one at startup.
- The HUD creates its own Screen Space Overlay canvas. It displays Blue/Red score, match countdown, hull health, individual module condition, ammunition count, and reload progress.
- The module panel shows engine, transmission, turret, gun breech, optics, ammunition rack, and both tracks. Disabled modules are marked OFFLINE.
- For a live minimap, create a second orthographic camera looking down at the battlefield, set its target texture to a RenderTexture asset, and assign that same RenderTexture to `TankCombatHUD.minimapTexture`. Set the minimap camera's culling mask to the map/vehicle layers you want visible. If no texture is assigned, the HUD displays a setup placeholder rather than a blank map.
- The minimap camera, RenderTexture asset, scene references, safe-area positioning, final visual styling, and device-specific scaling still require Unity Editor setup and testing.
- This HUD uses Unity's built-in `UnityEngine.UI` legacy Text/Image components; ensure the Unity UI package is available in the project.


## 10. Runtime mobile touch controls

- Add `MobileTankControls` to the local player tank root. Enable `Create Controls`.
- The script creates a Screen Space Overlay canvas with a movement joystick in the lower-left, drag-to-aim area on the lower-right, and a fire button in the lower-right corner.
- Assign `TankMovement`, `TankTurretAim`, and `TankWeapon`; if they are on the same GameObject, the script finds them automatically.
- Joystick input is normalized and resets to zero when the controlling finger is released. Aim and movement use separate pointer IDs, allowing two-finger driving and aiming. The fire control fires once on touch-down.
- The aim touch position is sent to both `TankTurretAim` and `TankWeapon`, keeping turret aim and shell direction aligned.
- The component creates an EventSystem with the legacy `StandaloneInputModule` only if the scene has no EventSystem. If using the new Input System exclusively, add an EventSystem with `InputSystemUIInputModule` before play.
- This is a functional starter layout, not final art. Safe-area positioning, configurable button placement, left-handed layout, sensitivity settings, haptics, desktop keyboard/gamepad controls, and Android device testing remain future tasks.


## 11. Procedural destroyed-city blockout

- Add `UrbanBattlefieldGenerator` to an empty scene GameObject named `Battlefield Generator`.
- Leave `Generate On Start` enabled to create the greybox city when Play begins, or use the component context menu command `Generate Urban Battlefield` while editing.
- The generator creates a ground plane, a grid of crossing streets, randomly placed building blocks, a configurable number of damaged structures with rubble, concrete street barriers, perimeter walls, three capture objectives by default, and opposing spawn markers.
- Set `Random Seed` to reproduce the same layout. Adjust `Blocks Per Side`, `Block Size`, `Road Width`, building density, building height, and ruin chance to vary the arena.
- Capture objectives are created with `CapturePoint` triggers and visible placeholder rings. Place team tanks near the Blue/Red spawn markers; the markers are visual references and do not spawn vehicles automatically.
- This generator is a greybox/prototype layout, not a finished city asset. It uses Unity primitive meshes and placeholder materials; it does not yet contain authored architecture, windows/interiors, road markings, lighting setup, navigation mesh, destructible buildings, debris simulation, audio, or optimized LODs.
- Generated capture points are placed along the central east-west road. The generator creates all points at runtime before the first frame's match logic update; ensure `TankMatchRules` collects scene objectives after generation. If automatic scene-start ordering causes missed points, generate the map in the editor and disable runtime generation before adding/starting match rules.
- The script creates placeholder materials at runtime. For production, replace them with shared URP materials and combine/instance repeated geometry to reduce draw calls.


## 12. Team spawns, player/bot deployment, and respawning

- The procedural battlefield generator creates two team spawn markers. Each marker now carries a `TankSpawnPoint` component configured for Blue or Red.
- Add `TankSpawnManager` to a scene manager GameObject. Assign a player tank prefab and a bot tank prefab. The player prefab should include `TankHealth`, `TankMovement`, `TankTurretAim`, `TankWeapon`, a camera setup, and `MobileTankControls`. The bot prefab should include `TankHealth`, `TankMovement`, `TankFaction`, `TankWeapon`, `TankBotAI`, turret/gun transforms, and a projectile prefab assignment.
- Choose the player's team and the number of bots per team. The manager spawns the player and the configured number of bots for each side.
- Every spawned vehicle receives its team assignment at runtime. When its hull is destroyed, the vehicle is removed after a short delay and respawns after the configured respawn delay.
- Spawn selection checks physical clearance and distance to enemy vehicles. If no point meets the enemy safety distance, it falls back to an unblocked spawn point belonging to the correct team.
- Generate the map before scene Start methods execute. The generator now builds the map in Awake so match rules and the spawn manager can discover capture points and team spawn markers during Start.
- This is a local prototype spawn flow. It does not yet include multiplayer authority, spawn-wave synchronization, team balancing, spawn protection, selectable vehicle loadouts, spawn menu UI, tickets, or match-end respawn lockout. The generated city currently has one spawn marker per team, so safe alternatives are limited until more spawn points are authored.
- Prefabs, spawn manager references, collision layers, and the actual respawn loop still require Unity Editor setup and play-mode testing.


## 13. Third-person camera, orbit, zoom, and aiming view

- Add `TankCameraController` to the scene's Main Camera. Set its Target to the player's tank `CameraTarget` child (recommended) or tank root. The spawn manager automatically assigns the camera target when it creates or respawns the player vehicle.
- Tune Target Offset, normal/minimum/maximum distance, pitch, and collision layers in the Inspector. The camera follows smoothly and sphere-casts against level geometry to avoid clipping through walls.
- On touch devices, drag in the upper camera strip (above 76% of screen height) to orbit around the tank. Pinch with two fingers in that strip to zoom. The lower-right drag surface remains reserved for turret aiming and the lower-left remains reserved for movement.
- The generated mobile controls now include an AIM toggle. It switches to a closer camera distance and back to the normal third-person view. Turret aiming remains controlled by dragging in the lower-right aim area.
- In the Unity Editor/standalone, hold the right mouse button and move to orbit; use the mouse wheel to zoom.
- Keep the camera's collision layer mask configured for buildings and terrain. Exclude the player's own vehicle layer if possible to avoid camera collision against its own colliders.
- This camera is a functional prototype. Shoulder swapping, camera shake, aim reticle, lock-on, accessibility settings, cinematic transitions, and physical-device tuning remain future work. The camera and controls have not yet been compiled or tested in Unity.


## 14. Tank combat audio and projectile sound

- Add `TankAudioController` to each tank root (player and bot). It creates spatial AudioSources for the engine and track loops automatically; assign loop clips and one-shot clips in the Inspector.
- Assign engine idle/moving loop audio to `Engine Loop` and continuous track movement audio to `Track Loop`. Engine pitch responds to movement speed/throttle; track audio pauses when the tank is stationary.
- Assign `Cannon Fire`, `Reload Start`, `Armour Hit`, `Module Disabled`, and `Vehicle Destroyed` clips. Cannon and reload sounds play when a round is fired; damage and module events trigger their corresponding sounds.
- On the projectile prefab's `TankProjectile`, optionally assign `Flight Loop Clip` for a moving spatial shell whistle, `Impact Clip` for a normal impact, and `Ricochet Clip` for a ricochet. The flight loop is attached to the projectile so it moves through the world; impact audio is played at the collision position.
- Use short, clean, seamless loop clips for engines/tracks and mono clips for positional one-shots where possible. Import distant ambience as stereo only when it is intended to be non-positional. Tune AudioSource min/max distance and volume in the Inspector for mobile speakers/headphones.
- This system provides audio hooks and runtime sources, not bundled sound assets. The project still needs properly licensed/created audio clips assigned in prefabs, plus mixer groups, snapshots, audio pooling, performance profiling, and Android device mix testing. No sound assets are included automatically.


## 15. Destructible city environment

- The procedural city now marks building blocks, concrete road barriers, and abandoned-vehicle cover as destructible.
- Add DestructibleEnvironment to an environment mesh with a Renderer and Collider. Configure hit points, debris count (2–6), debris impulse, and debris lifetime in the Inspector.
- Tank shells apply damage on collision. When health reaches zero, the original mesh and collider are removed and replaced by a capped set of temporary physics debris pieces pushed by the impact.
- Regular buildings receive more health than already-ruined structures; barriers and abandoned cover use lower prototype health values.
- Debris is capped per object and self-destructs after a short lifetime for mobile performance. This is a simple break-apart effect, not structural fracture: no interiors, collapse propagation, persistent rubble, dust/smoke particles, blast-radius damage, or server synchronization yet.
- Play Mode profiling and Android device tuning remain required. These scripts have not been compiled or tested in Unity.


## 16. Shell explosions and blast damage

- `TankExplosion` creates a short-lived particle burst at shell impact and applies distance-falloff damage inside a configurable radius.
- Configure each projectile's Blast Radius, Blast Damage, Blast Force, Blast Visual Scale, and Explosion Clip. A zero blast radius or zero blast damage disables area damage.
- Nearby enemy tanks receive hull damage; nearby `DestructibleEnvironment` objects receive radial damage; non-kinematic rigidbodies receive an outward impulse. The firing tank is excluded from tank splash damage.
- The overlap query is capped at 64 colliders and uses a non-allocating physics query. Multiple colliders belonging to the same tank or destructible are deduplicated per blast.
- The generated particle effect is a lightweight placeholder burst, not a production fireball, smoke column, dust cloud, shockwave distortion, or shrapnel simulation. No persistent burning, chain reaction, line-of-sight occlusion, multiplayer replication, or pooled effects are implemented yet.
- Assign a licensed explosion clip on the projectile prefab. Tune blast values and particle count on target Android devices; Unity compilation and Play Mode/device testing have not yet been performed.
