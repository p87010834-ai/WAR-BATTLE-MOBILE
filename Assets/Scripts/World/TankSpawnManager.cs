using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using WarBattleMobile.Combat;
using WarBattleMobile.Vehicle;

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
        private Transform spawnedVehiclesRoot;

        private sealed class VehicleSlot
        {
            public GameObject Prefab;
            public TankTeam Team;
            public bool IsPlayer;
            public GameObject Instance;
            public bool RespawnQueued;
        }

        private void Start()
        {
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
                SpawnSlot(slot);
        }

        private void AddBotSlots(TankTeam team)
        {
            for (int i = 0; i < botsPerTeam; i++)
                AddSlot(botTankPrefab, team, false);
        }

        private void AddSlot(GameObject prefab, TankTeam team, bool isPlayer)
        {
            if (prefab == null || team == TankTeam.Neutral) return;
            slots.Add(new VehicleSlot { Prefab = prefab, Team = team, IsPlayer = isPlayer });
        }

        private void SpawnSlot(VehicleSlot slot)
        {
            if (slot == null || slot.Prefab == null || slot.Instance != null) return;

            TankSpawnPoint point = ChooseSpawnPoint(slot.Team);
            if (point == null)
            {
                Debug.LogWarning($"TankSpawnManager: no safe spawn point found for {slot.Team}.", this);
                return;
            }

            Vector3 position = point.transform.position + spawnOffset;
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
            }
            health.TankDestroyed += () => OnVehicleDestroyed(slot, vehicle);
        }

        private TankSpawnPoint ChooseSpawnPoint(TankTeam team)
        {
            TankSpawnPoint best = null;
            float bestThreatDistance = float.MinValue;

            foreach (TankSpawnPoint point in spawnPoints)
            {
                if (point == null || point.Team != team) continue;
                Vector3 candidatePosition = point.transform.position + spawnOffset;
                if (IsSpawnBlocked(candidatePosition))
                    continue;

                float nearestEnemy = float.MaxValue;
                TankFaction[] factions = FindObjectsByType<TankFaction>(FindObjectsSortMode.None);
                foreach (TankFaction faction in factions)
                {
                    if (faction == null || faction.Team == TankTeam.Neutral || faction.Team == team)
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
                    if (point == null || point.Team != team) continue;
                    Vector3 candidatePosition = point.transform.position + spawnOffset;
                    if (!IsSpawnBlocked(candidatePosition))
                        return point;
                }
            }
            return best;
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
            if (slot.Instance != destroyedVehicle || slot.RespawnQueued) return;
            slot.RespawnQueued = true;
            slot.Instance = null;
            StartCoroutine(RespawnAfterDelay(slot));
            Destroy(destroyedVehicle, 3f);
        }

        private IEnumerator RespawnAfterDelay(VehicleSlot slot)
        {
            yield return new WaitForSeconds(respawnDelay);
            if (this == null || !isActiveAndEnabled) yield break;
            while (slot.Instance == null && this != null && isActiveAndEnabled)
            {
                slot.RespawnQueued = false;
                SpawnSlot(slot);
                if (slot.Instance == null)
                    yield return new WaitForSeconds(2f);
            }
        }

    }
}