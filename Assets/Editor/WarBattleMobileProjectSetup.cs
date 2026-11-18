using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using WarBattleMobile.AI;
using WarBattleMobile.Combat;
using WarBattleMobile.UI;
using WarBattleMobile.Vehicle;
using WarBattleMobile.World;

namespace WarBattleMobile.EditorTools
{
    /// <summary>
    /// Generates a first runnable greybox scene and configured placeholder tank prefabs.
    /// Run via Tools > WAR BATTLE MOBILE > Build Tank Vertical Slice.
    /// </summary>
    public static class WarBattleMobileProjectSetup
    {
        private const string Root = "Assets/WarBattleMobile";
        private const string PrefabFolder = Root + "/Prefabs";
        private const string SceneFolder = Root + "/Scenes";
        private const string ScenePath = SceneFolder + "/TankVerticalSlice.unity";
        private const string PlayerPrefabPath = PrefabFolder + "/PlayerTank.prefab";
        private const string BotPrefabPath = PrefabFolder + "/BotTank.prefab";
        private const string ProjectilePrefabPath = PrefabFolder + "/TankProjectile.prefab";

        [MenuItem("Tools/WAR BATTLE MOBILE/Build Tank Vertical Slice")]
        public static void BuildTankVerticalSlice()
        {
            EnsureFolders();
            GameObject projectile = BuildProjectilePrefab();
            GameObject player = BuildTankPrefab(false, projectile);
            GameObject bot = BuildTankPrefab(true, projectile);
            BuildScene(player, bot);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            EditorSceneManager.OpenScene(ScenePath);
            Debug.Log("WAR BATTLE MOBILE: generated the greybox tank scene and placeholder prefabs. Enter Play Mode and inspect the Console validator before treating it as tested.");
        }

        [MenuItem("Tools/WAR BATTLE MOBILE/Validate Tank Vertical Slice Assets")]
        public static void ValidateTankVerticalSliceAssets()
        {
            int errors = 0;
            int warnings = 0;

            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(ScenePath) == null)
            {
                Debug.LogError("[WAR BATTLE MOBILE] Generated tank scene is missing. Run Build Tank Vertical Slice first.");
                errors++;
            }
            if (AssetDatabase.LoadAssetAtPath<GameObject>(PlayerPrefabPath) == null)
            {
                Debug.LogError("[WAR BATTLE MOBILE] Player tank prefab is missing.");
                errors++;
            }
            if (AssetDatabase.LoadAssetAtPath<GameObject>(BotPrefabPath) == null)
            {
                Debug.LogError("[WAR BATTLE MOBILE] Bot tank prefab is missing.");
                errors++;
            }
            if (AssetDatabase.LoadAssetAtPath<GameObject>(ProjectilePrefabPath) == null)
            {
                Debug.LogError("[WAR BATTLE MOBILE] Projectile prefab is missing.");
                errors++;
            }

            ValidatePrefab(PlayerPrefabPath, false, ref errors, ref warnings);
            ValidatePrefab(BotPrefabPath, true, ref errors, ref warnings);
            ValidatePrefab(ProjectilePrefabPath, false, ref errors, ref warnings);

            bool sceneInBuild = false;
            foreach (EditorBuildSettingsScene scene in EditorBuildSettings.scenes)
            {
                if (scene.path == ScenePath && scene.enabled)
                {
                    sceneInBuild = true;
                    break;
                }
            }
            if (!sceneInBuild)
            {
                Debug.LogError("[WAR BATTLE MOBILE] TankVerticalSlice scene is not enabled in Build Settings.");
                errors++;
            }

            string summary = "[WAR BATTLE MOBILE] Asset validation finished: " +
                errors + " error(s), " + warnings + " warning(s).";
            if (errors > 0) Debug.LogError(summary);
            else if (warnings > 0) Debug.LogWarning(summary);
            else Debug.Log(summary);
        }

        private static void ValidatePrefab(string path, bool expectBot,
            ref int errors, ref int warnings)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            if (prefab == null) return;

            GameObject root = PrefabUtility.LoadPrefabContents(path);
            try
            {
                RequireComponent<TankFaction>(root, path, ref errors);
                RequireComponent<TankHealth>(root, path, ref errors);
                RequireComponent<TankMovement>(root, path, ref errors);
                RequireComponent<TankTurretAim>(root, path, ref errors);
                RequireComponent<TankWeapon>(root, path, ref errors);

                if (expectBot)
                    RequireComponent<TankBotAI>(root, path, ref errors);
                else
                    RequireComponent<MobileTankControls>(root, path, ref errors);

                if (root.transform.Find("CameraTarget") == null && !expectBot)
                {
                    Debug.LogError("[WAR BATTLE MOBILE] Player prefab has no CameraTarget child: " + path);
                    errors++;
                }

                if (root.GetComponent<CharacterController>() == null)
                {
                    Debug.LogError("[WAR BATTLE MOBILE] Vehicle prefab has no CharacterController: " + path);
                    errors++;
                }

                if (root.GetComponentsInChildren<TankArmorZone>(true).Length < 5)
                {
                    Debug.LogError("[WAR BATTLE MOBILE] Vehicle prefab has too few armour hitboxes: " + path);
                    errors++;
                }

                TankWeapon weapon = root.GetComponent<TankWeapon>();
                SerializedObject serializedWeapon = new SerializedObject(weapon);
                SerializedProperty projectile = serializedWeapon.FindProperty("projectilePrefab");
                if (projectile == null || projectile.objectReferenceValue == null)
                {
                    Debug.LogError("[WAR BATTLE MOBILE] TankWeapon has no projectile prefab assigned: " + path);
                    errors++;
                }
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static void RequireComponent<T>(GameObject root, string path,
            ref int errors) where T : Component
        {
            if (root.GetComponent<T>() != null) return;
            Debug.LogError("[WAR BATTLE MOBILE] Missing " + typeof(T).Name + " on prefab root: " + path);
            errors++;
        }

        private static void EnsureFolders()
        {
            CreateFolder("Assets", "WarBattleMobile");
            CreateFolder(Root, "Prefabs");
            CreateFolder(Root, "Scenes");
        }

        private static void CreateFolder(string parent, string name)
        {
            string path = parent + "/" + name;
            if (!AssetDatabase.IsValidFolder(path))
                AssetDatabase.CreateFolder(parent, name);
        }

        private static GameObject BuildProjectilePrefab()
        {
            GameObject existing = AssetDatabase.LoadAssetAtPath<GameObject>(ProjectilePrefabPath);
            if (existing != null) AssetDatabase.DeleteAsset(ProjectilePrefabPath);

            GameObject projectile = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            projectile.name = "TankProjectile";
            projectile.transform.localScale = Vector3.one * 0.24f;
            Rigidbody body = projectile.AddComponent<Rigidbody>();
            body.mass = 0.08f;
            body.useGravity = true;
            body.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
            projectile.AddComponent<TankProjectile>();
            GameObject prefab = PrefabUtility.SaveAsPrefabAsset(projectile, ProjectilePrefabPath);
            Object.DestroyImmediate(projectile);
            return prefab;
        }

        private static GameObject BuildTankPrefab(bool withBotAI, GameObject projectilePrefab)
        {
            string path = withBotAI ? BotPrefabPath : PlayerPrefabPath;
            if (AssetDatabase.LoadAssetAtPath<GameObject>(path) != null)
                AssetDatabase.DeleteAsset(path);

            GameObject tank = new GameObject(withBotAI ? "BotTank" : "PlayerTank");
            CharacterController controller = tank.AddComponent<CharacterController>();
            controller.height = 2.1f;
            controller.radius = 1.12f;
            controller.center = new Vector3(0f, 1.05f, 0f);
            controller.stepOffset = 0.35f;
            controller.slopeLimit = 35f;

            tank.AddComponent<TankFaction>();
            TankHealth health = tank.AddComponent<TankHealth>();
            TankMovement movement = tank.AddComponent<TankMovement>();

            GameObject hull = GameObject.CreatePrimitive(PrimitiveType.Cube);
            hull.name = "Hull Visual";
            hull.transform.SetParent(tank.transform, false);
            hull.transform.localPosition = new Vector3(0f, 0.85f, 0f);
            hull.transform.localScale = new Vector3(2.8f, 1.15f, 4.2f);
            RemoveCollider(hull);

            GameObject turret = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            turret.name = "TurretYaw";
            turret.transform.SetParent(tank.transform, false);
            turret.transform.localPosition = new Vector3(0f, 1.55f, 0f);
            turret.transform.localScale = new Vector3(1.55f, 0.32f, 1.75f);
            RemoveCollider(turret);

            GameObject gun = GameObject.CreatePrimitive(PrimitiveType.Cube);
            gun.name = "GunPitch";
            gun.transform.SetParent(turret.transform, false);
            gun.transform.localPosition = new Vector3(0f, 0.05f, 0.95f);
            gun.transform.localScale = new Vector3(0.28f, 0.28f, 1.9f);
            RemoveCollider(gun);

            GameObject muzzle = new GameObject("Muzzle");
            muzzle.transform.SetParent(gun.transform, false);
            muzzle.transform.localPosition = new Vector3(0f, 0f, 0.58f);

            // Separate armour hitboxes make the modular damage model reachable.
            // Their outer edges extend beyond the movement capsule so impacts can
            // resolve to tracks, turret, engine and gun breech instead of only Hull.
            AddArmorHitbox(tank.transform, "Hull Armour Hitbox",
                new Vector3(0f, 0.85f, 0f), new Vector3(2.8f, 1.15f, 4.2f),
                TankModule.Hull, 90f);
            AddArmorHitbox(tank.transform, "Engine Armour Hitbox",
                new Vector3(0f, 0.88f, -2.22f), new Vector3(1.05f, 0.82f, 0.78f),
                TankModule.Engine, 65f);
            AddArmorHitbox(tank.transform, "Turret Armour Hitbox",
                new Vector3(0f, 1.58f, 0f), new Vector3(2.85f, 0.72f, 2.75f),
                TankModule.Turret, 160f);
            AddArmorHitbox(tank.transform, "Gun Breech Armour Hitbox",
                new Vector3(0f, 1.62f, 1.52f), new Vector3(0.62f, 0.48f, 0.82f),
                TankModule.GunBreech, 110f);
            AddArmorHitbox(tank.transform, "Transmission Armour Hitbox",
                new Vector3(0f, 0.48f, 2.22f), new Vector3(1.05f, 0.62f, 0.78f),
                TankModule.Transmission, 55f);
            AddArmorHitbox(tank.transform, "Ammunition Rack Armour Hitbox",
                new Vector3(0f, 1.58f, -0.82f), new Vector3(0.92f, 0.38f, 0.9f),
                TankModule.AmmunitionRack, 45f);
            AddArmorHitbox(tank.transform, "Optics Armour Hitbox",
                new Vector3(0f, 2.02f, -0.28f), new Vector3(0.38f, 0.22f, 0.38f),
                TankModule.Optics, 35f);
            AddArmorHitbox(tank.transform, "Left Track Armour Hitbox",
                new Vector3(-1.34f, 0.34f, 0f), new Vector3(0.48f, 0.68f, 3.6f),
                TankModule.LeftTrack, 55f);
            AddArmorHitbox(tank.transform, "Right Track Armour Hitbox",
                new Vector3(1.34f, 0.34f, 0f), new Vector3(0.48f, 0.68f, 3.6f),
                TankModule.RightTrack, 55f);

            GameObject cameraTarget = new GameObject("CameraTarget");
            cameraTarget.transform.SetParent(tank.transform, false);
            cameraTarget.transform.localPosition = new Vector3(0f, 1.7f, 0f);

            TankTurretAim aim = tank.AddComponent<TankTurretAim>();
            SetObject(aim, "turretYaw", turret.transform);
            SetObject(aim, "gunPitch", gun.transform);
            SetObject(aim, "tankHealth", health);

            TankWeapon weapon = tank.AddComponent<TankWeapon>();
            SetObject(weapon, "muzzle", muzzle.transform);
            SetObject(weapon, "projectilePrefab", projectilePrefab);
            SetObject(weapon, "tankHealth", health);

            if (withBotAI)
            {
                TankBotAI ai = tank.AddComponent<TankBotAI>();
                SetObject(ai, "health", health);
                SetObject(ai, "movement", movement);
                SetObject(ai, "faction", tank.GetComponent<TankFaction>());
                SetObject(ai, "weapon", weapon);
                SetObject(ai, "turretYaw", turret.transform);
                SetObject(ai, "gunPitch", gun.transform);
                SetObject(ai, "muzzle", muzzle.transform);
            }
            else
            {
                MobileTankControls controls = tank.AddComponent<MobileTankControls>();
                SetObject(controls, "movement", movement);
                SetObject(controls, "turretAim", aim);
                SetObject(controls, "weapon", weapon);
            }

            GameObject prefab = PrefabUtility.SaveAsPrefabAsset(tank, path);
            Object.DestroyImmediate(tank);
            return prefab;
        }

        private static void AddArmorHitbox(Transform tankRoot, string objectName,
            Vector3 localPosition, Vector3 size, TankModule module, float thickness)
        {
            GameObject hitbox = new GameObject(objectName);
            hitbox.transform.SetParent(tankRoot, false);
            hitbox.transform.localPosition = localPosition;
            BoxCollider collider = hitbox.AddComponent<BoxCollider>();
            collider.size = size;
            TankArmorZone armor = hitbox.AddComponent<TankArmorZone>();
            SerializedObject serialized = new SerializedObject(armor);
            serialized.FindProperty("thicknessMillimetres").floatValue = thickness;
            serialized.FindProperty("damagedModule").enumValueIndex = (int)module;
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void RemoveCollider(GameObject target)
        {
            Collider collider = target.GetComponent<Collider>();
            if (collider != null) Object.DestroyImmediate(collider);
        }

        private static void SetObject(Object target, string propertyName, Object value)
        {
            SerializedObject serialized = new SerializedObject(target);
            SerializedProperty property = serialized.FindProperty(propertyName);
            if (property == null)
            {
                Debug.LogWarning("Could not configure serialized field '" + propertyName + "' on " + target.name);
                return;
            }
            property.objectReferenceValue = value;
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void BuildScene(GameObject playerPrefab, GameObject botPrefab)
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            scene.name = "TankVerticalSlice";

            GameObject battlefield = new GameObject("Urban Battlefield");
            battlefield.AddComponent<UrbanBattlefieldGenerator>();

            GameObject rulesObject = new GameObject("Match Rules");
            rulesObject.AddComponent<TankMatchRules>();

            GameObject cameraObject = GameObject.FindWithTag("MainCamera");
            if (cameraObject == null)
            {
                cameraObject = new GameObject("Main Camera");
                cameraObject.tag = "MainCamera";
                cameraObject.AddComponent<Camera>();
                cameraObject.AddComponent<AudioListener>();
            }
            TankCameraController cameraController = cameraObject.GetComponent<TankCameraController>();
            if (cameraController == null) cameraController = cameraObject.AddComponent<TankCameraController>();
            cameraObject.transform.position = new Vector3(0f, 12f, -18f);
            cameraObject.transform.rotation = Quaternion.Euler(25f, 0f, 0f);

            GameObject spawnObject = new GameObject("Tank Spawn Manager");
            TankSpawnManager spawnManager = spawnObject.AddComponent<TankSpawnManager>();
            SetObject(spawnManager, "playerTankPrefab", playerPrefab);
            SetObject(spawnManager, "botTankPrefab", botPrefab);

            GameObject hudObject = new GameObject("Tank Combat HUD");
            TankCombatHUD hud = hudObject.AddComponent<TankCombatHUD>();
            SetObject(hud, "matchRules", rulesObject.GetComponent<TankMatchRules>());

            GameObject validatorObject = new GameObject("Tank Vertical Slice Validator");
            validatorObject.AddComponent<TankVerticalSliceValidator>();

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(ScenePath, true)
            };
        }
    }
}
