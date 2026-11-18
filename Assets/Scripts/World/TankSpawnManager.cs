using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using WarBattleMobile.Combat;
using WarBattleMobile.Vehicle;
using WarBattleMobile.UI;

namespace WarBattleMobile.World
{
    /// <summary>
    /// Spawns the local player and AI vehicles at team spawn points, then
    /// respawns destroyed vehicles after a configurable delay.
    /// </summary>
    public sealed class TankSpawnManager : MonoBehaviour
    {
        [Header("Vehicle prefabs")]
        [SerializeField] private GameObject playerTankPrefab;
        [SerializeField] private GameObject botTankPrefab;

        [Header("Match setup")]
        [SerializeField] private TankTeam playerTeam = TankTeam.Blue;
        [SerializeField, Min(0)] private int botsPerTeam = 2;
        [SerializeField] private bool spawnPlayerOnStart = true;
        [SerializeField] private bool spawnBotsOnStart = true;
        [SerializeField, Min(0f)] private float respawnDelay = 8f;

        [Header("Spawn safety")]
        [SerializeField, Min(0.5f)] private float clearanceRadius = 5f;
        [SerializeField, Min(0f)] private float enemySafeDistance = 28f;
        [SerializeField] private LayerMask obstructionLayers = ~0;
        [SerializeField] private Vector3 spawnOffset = new Vector3(0f, 0.5f, 0f);

        private readonly List<VehicleSlot> slots = new List<VehicleSlot>();
        private TankSpawnPoint[] spawnPoints;
        [SerializeField] private TankMatchRules matchRules;
        private Transform spawnedVehiclesRoot;
        private int blueSpawnSlots;
        private int redSpawnSlots;

        private sealed class VehicleSlot
        {
            public GameObject Prefab;
            public TankTeam Team;
            public bool IsPlayer;
            public GameObject Instance;
            public bool RespawnQueued;
            public int SpawnIndex;
        }

        private void Start()
        {
            if (matchRules == null) matchRules = FindFirstObjectByType<TankMatchRules>();
            spawnPoints = FindObjectsByType<TankSpawnPoint>(FindObjectsSortMode.None);
            if (spawnPoints.Length == 0)
            {
                Debug.LogError("TankSpawnManager: no TankSpawnPoint objects found. Generate the battlefield first.", this);
                enabled = false;
                return;
            }

            GameObject root = new GameObject("Spawned Vehicles");
            spawnedVehiclesRoot = root.transform;

            if (spawnPlayerOnStart)
            {
                if (playerTankPrefab == null)
                    Debug.LogError("TankSpawnManager: assign Player Tank Prefab.", this);
                else
                    AddSlot(playerTankPrefab, playerTeam, true);
            }

            if (spawnBotsOnStart)
            {
                if (botTankPrefab == null)
                    Debug.LogWarning("TankSpawnManager: Bot Tank Prefab is not assigned; bots will not spawn.", this);
                else
                {
                    AddBotSlots(TankTeam.Blue);
                    AddBotSlots(TankTeam.Red);
                }
            }

            foreach (VehicleSlot slot in slots)
            {
                SpawnSlot(slot);
                // Initial spawn can be temporarily blocked while the generated
                // map finishes creating colliders or another vehicle occupies
                // the preferred clearance area. Retry instead of leaving an
                // empty roster slot until the next destruction event.
                if (slot.Instance == null)
                    StartCoroutine(RetryInitialSpawn(slot));
            }
        }

        private IEnumerator RetryInitialSpawn(VehicleSlot slot)
        {
            while (slot != null && slot.Instance == null &&
                this != null && isActiveAndEnabled && !HasMatchEnded())
            {
                yield return new WaitForSeconds(2f);
                if (slot.Instance == null)
                    SpawnSlot(slot);
            }
        }

        private void AddBotSlots(TankTeam team)
        {
            for (int i = 0; i < botsPerTeam; i++)
                AddSlot(botTankPrefab, team, false);
        }

        private void AddSlot(GameObject prefab, TankTeam team, bool isPlayer)
        {
            if (prefab == null || team == TankTeam.Neutral) return;
            int spawnIndex = team == TankTeam.Blue ? blueSpawnSlots++ : redSpawnSlots++;
            slots.Add(new VehicleSlot
            {
                Prefab = prefab,
                Team = team,
                IsPlayer = isPlayer,
                SpawnIndex = spawnIndex
            });
        }

        private void SpawnSlot(VehicleSlot slot)
        {
            if (slot == null || slot.Prefab == null || slot.Instance != null || HasMatchEnded()) return;

            TankSpawnPoint point = ChooseSpawnPoint(slot);
            if (point == null)
            {
                Debug.LogWarning($"TankSpawnManager: no safe spawn point found for {slot.Team}.", this);
                return;
            }

            Vector3 position = GetSlotSpawnPosition(point, slot);
            Quaternion rotation = point.transform.rotation;
            GameObject vehicle = Instantiate(slot.Prefab, position, rotation, spawnedVehiclesRoot);
            vehicle.name = (slot.IsPlayer ? "Player " : "Bot ") + slot.Team + " Tank";
            TankFaction faction = vehicle.GetComponent<TankFaction>();
            if (faction == null) faction = vehicle.AddComponent<TankFaction>();
            faction.SetTeam(slot.Team);

            TankHealth health = vehicle.GetComponent<TankHealth>();
            if (health == null)
            {
                Debug.LogError($"TankSpawnManager: prefab {slot.Prefab.name} has no TankHealth.", vehicle);
                Destroy(vehicle);
                return;
            }

            slot.Instance = vehicle;
            slot.RespawnQueued = false;
            if (slot.IsPlayer)
            {
                TankCameraController cameraController = FindFirstObjectByType<TankCameraController>();
                if (cameraController != null)
                {
                    Transform cameraTarget = vehicle.transform.Find("CameraTarget");
                    cameraController.SetTarget(cameraTarget != null ? cameraTarget : vehicle.transform);
                }

                TankCombatHUD hud = FindFirstObjectByType<TankCombatHUD>();
                if (hud != null)
                    hud.BindVehicle(health, vehicle.GetComponent<TankWeapon>(), faction);
            }
            health.TankDestroyed += () => OnVehicleDestroyed(slot, vehicle);
        }

        private TankSpawnPoint ChooseSpawnPoint(VehicleSlot slot)
        {
            TankSpawnPoint best = null;
            float bestThreatDistance = float.MinValue;
            TankFaction[] factions = FindObjectsByType<TankFaction>(FindObjectsSortMode.None);

            foreach (TankSpawnPoint point in spawnPoints)
            {
                if (point == null || point.Team != slot.Team) continue;
                Vector3 candidatePosition = GetSlotSpawnPosition(point, slot);
                if (IsSpawnBlocked(candidatePosition))
                    continue;

                float nearestEnemy = float.MaxValue;
                foreach (TankFaction faction in factions)
                {
                    if (faction == null || faction.Team == TankTeam.Neutral || faction.Team == slot.Team)
                        continue;
                    float distance = Vector3.Distance(candidatePosition, faction.transform.position);
                    if (distance < nearestEnemy) nearestEnemy = distance;
                }

                if (nearestEnemy < enemySafeDistance) continue;
                if (nearestEnemy > bestThreatDistance)
                {
                    bestThreatDistance = nearestEnemy;
                    best = point;
                }
            }

            // A team's own spawn point remains a fallback if no point passes the
            // enemy-distance rule. Still reject physically obstructed locations.
            if (best == null)
            {
                foreach (TankSpawnPoint point in spawnPoints)
                {
                    if (point == null || point.Team != slot.Team) continue;
                    Vector3 candidatePosition = GetSlotSpawnPosition(point, slot);
                    if (!IsSpawnBlocked(candidatePosition))
                        return point;
                }
            }
            return best;
        }

        private Vector3 GetSlotSpawnPosition(TankSpawnPoint point, VehicleSlot slot)
        {
            // The generated map has one marker per team. Spread each team roster
            // around that marker so player and bots do not stack into one collider.
            Vector3 localOffset = Vector3.zero;
            if (slot.SpawnIndex > 0)
            {
                int ring = (slot.SpawnIndex + 3) / 4;
                int positionInRing = (slot.SpawnIndex - 1) % 4;
                float distance = 9f * ring;
                switch (positionInRing)
                {
                    case 0: localOffset = Vector3.right * distance; break;
                    case 1: localOffset = Vector3.left * distance; break;
                    case 2: localOffset = Vector3.forward * distance; break;
                    default: localOffset = Vector3.back * distance; break;
                }
            }
            return point.transform.position + point.transform.TransformDirection(localOffset) + spawnOffset;
        }

        private bool HasMatchEnded()
        {
            return matchRules != null && matchRules.IsFinished;
        }

        private bool IsSpawnBlocked(Vector3 position)
        {
            // Lift the clearance sphere so the ground plane beneath the vehicle
            // does not count as an obstruction.
            Vector3 sphereCenter = position + Vector3.up * clearanceRadius;
            return Physics.CheckSphere(sphereCenter, clearanceRadius,
                obstructionLayers, QueryTriggerInteraction.Ignore);
        }

        private void OnVehicleDestroyed(VehicleSlot slot, GameObject destroyedVehicle)
        {
            if (slot.Instance != destroyedVehicle || slot.RespawnQueued || HasMatchEnded()) return;
            slot.RespawnQueued = true;
            slot.Instance = null;
            StartCoroutine(RespawnAfterDelay(slot));
            Destroy(destroyedVehicle, 3f);
        }

        private IEnumerator RespawnAfterDelay(VehicleSlot slot)
        {
            yield return new WaitForSeconds(respawnDelay);
            if (this == null || !isActiveAndEnabled || HasMatchEnded()) yield break;
            while (slot.Instance == null && this != null && isActiveAndEnabled && !HasMatchEnded())
            {
                slot.RespawnQueued = false;
                SpawnSlot(slot);
                if (slot.Instance == null)
                    yield return new WaitForSeconds(2f);
            }
        }

    }
}