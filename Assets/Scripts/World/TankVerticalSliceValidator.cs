using UnityEngine;
using UnityEngine.EventSystems;
using WarBattleMobile.Combat;
using WarBattleMobile.UI;
using WarBattleMobile.Vehicle;

namespace WarBattleMobile.World
{
    /// <summary>
    /// Reports missing scene-level wiring for the tank vertical slice.
    /// This is a diagnostic helper; it does not create assets or repair references.
    /// </summary>
    [DefaultExecutionOrder(10000)]
    public sealed class TankVerticalSliceValidator : MonoBehaviour
    {
        [SerializeField] private bool validateOnStart = true;

        private void Start()
        {
            if (validateOnStart) ValidateScene();
        }

        [ContextMenu("Validate Tank Vertical Slice")]
        public void ValidateScene()
        {
            int errors = 0;
            int warnings = 0;

            if (FindFirstObjectByType<UrbanBattlefieldGenerator>() == null)
                Warn("No UrbanBattlefieldGenerator found. A battlefield must be present or generated.", ref warnings);

            CapturePoint[] points = FindObjectsByType<CapturePoint>(FindObjectsSortMode.None);
            if (points.Length == 0)
                Error("No CapturePoint components found.", ref errors);

            TankSpawnPoint[] spawns = FindObjectsByType<TankSpawnPoint>(FindObjectsSortMode.None);
            bool hasBlueSpawn = false;
            bool hasRedSpawn = false;
            foreach (TankSpawnPoint spawn in spawns)
            {
                if (spawn == null) continue;
                if (spawn.Team == TankTeam.Blue) hasBlueSpawn = true;
                if (spawn.Team == TankTeam.Red) hasRedSpawn = true;
            }
            if (!hasBlueSpawn) Error("No Blue team TankSpawnPoint found.", ref errors);
            if (!hasRedSpawn) Error("No Red team TankSpawnPoint found.", ref errors);

            if (FindFirstObjectByType<TankMatchRules>() == null)
                Error("No TankMatchRules component found.", ref errors);
            TankSpawnManager spawnManager = FindFirstObjectByType<TankSpawnManager>();
            if (spawnManager == null)
                Error("No TankSpawnManager component found.", ref errors);
            else if (!spawnManager.isActiveAndEnabled)
                Error("TankSpawnManager exists but is disabled.", ref errors);

            TankMatchRules matchRules = FindFirstObjectByType<TankMatchRules>();
            if (matchRules != null && matchRules.IsFinished && matchRules.IsRunning)
                Error("Match rules report both finished and running.", ref errors);

            if (FindFirstObjectByType<TankCombatHUD>() == null)
                Warn("No TankCombatHUD found. Combat will run without the prototype HUD.", ref warnings);

            Camera mainCamera = Camera.main;
            if (mainCamera == null)
                Error("No camera tagged MainCamera found.", ref errors);
            else if (mainCamera.GetComponent<TankCameraController>() == null)
                Warn("MainCamera has no TankCameraController.", ref warnings);

            if (FindFirstObjectByType<EventSystem>() == null)
                Warn("No EventSystem found. Runtime mobile UI may create one, but verify the active Input Module.", ref warnings);

            TankFaction[] vehicles = FindObjectsByType<TankFaction>(FindObjectsSortMode.None);
            int activeBlue = 0;
            int activeRed = 0;
            int playerControls = 0;
            foreach (TankFaction faction in vehicles)
            {
                if (faction == null || !faction.isActiveAndEnabled || !faction.IsCombatant)
                    continue;

                TankHealth liveHealth = faction.GetComponent<TankHealth>();
                if (liveHealth == null || !liveHealth.isActiveAndEnabled || liveHealth.IsDestroyed)
                    continue;

                if (faction.Team == TankTeam.Blue) activeBlue++;
                else if (faction.Team == TankTeam.Red) activeRed++;
                if (faction.GetComponent<MobileTankControls>() != null)
                    playerControls++;
            }

            if (vehicles.Length == 0)
                Warn("No tank vehicles found. Check TankSpawnManager prefab assignments and spawn points.", ref warnings);
            if (activeBlue == 0)
                Error("No living Blue combat vehicle is active.", ref errors);
            if (activeRed == 0)
                Error("No living Red combat vehicle is active.", ref errors);
            if (playerControls == 0)
                Error("No active vehicle has MobileTankControls; the local player cannot drive.", ref errors);

            if (spawnManager != null && spawnManager.ConfiguredSlotCount > 0 &&
                spawnManager.ActiveVehicleCount < spawnManager.ConfiguredSlotCount)
                Warn("Some configured vehicle slots are still waiting for a safe spawn. Active " +
                    spawnManager.ActiveVehicleCount + " of " + spawnManager.ConfiguredSlotCount + ".", ref warnings);

            foreach (TankFaction faction in vehicles)
            {
                if (faction == null) continue;
                if (faction.GetComponent<TankHealth>() == null)
                    Error(faction.name + " has no TankHealth on its root.", ref errors);
                if (faction.GetComponent<TankMovement>() == null)
                    Warn(faction.name + " has no TankMovement on its root.", ref warnings);
                if (faction.GetComponent<TankWeapon>() == null)
                    Warn(faction.name + " has no TankWeapon on its root.", ref warnings);
            }

            string summary = "Tank vertical slice validation finished: " +
                errors + " error(s), " + warnings + " warning(s).";
            if (errors > 0) Debug.LogError(summary, this);
            else if (warnings > 0) Debug.LogWarning(summary, this);
            else Debug.Log(summary, this);
        }

        private void Error(string message, ref int count)
        {
            count++;
            Debug.LogError("[Tank Vertical Slice] " + message, this);
        }

        private void Warn(string message, ref int count)
        {
            count++;
            Debug.LogWarning("[Tank Vertical Slice] " + message, this);
        }
    }
}
