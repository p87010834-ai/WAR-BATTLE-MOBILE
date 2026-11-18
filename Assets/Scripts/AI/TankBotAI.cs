using UnityEngine;
using WarBattleMobile.Combat;
using WarBattleMobile.Vehicle;

namespace WarBattleMobile.AI
{
    [RequireComponent(typeof(TankMovement))]
    [RequireComponent(typeof(TankFaction))]
    public sealed class TankBotAI : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private TankHealth health;
        [SerializeField] private TankMovement movement;
        [SerializeField] private TankFaction faction;
        [SerializeField] private TankWeapon weapon;
        [SerializeField] private Transform turretYaw;
        [SerializeField] private Transform gunPitch;
        [SerializeField] private Transform muzzle;

        [Header("Combat")]
        [SerializeField, Min(5f)] private float detectionRange = 90f;
        [SerializeField, Min(5f)] private float preferredRange = 38f;
        [SerializeField, Min(0.1f)] private float targetRefreshSeconds = 0.5f;
        [SerializeField, Min(1f)] private float turretTurnSpeed = 65f;
        [SerializeField, Min(1f)] private float gunPitchSpeed = 40f;
        [SerializeField, Min(0.1f)] private float fireAngleTolerance = 4f;
        [SerializeField] private float minGunPitch = -8f;
        [SerializeField] private float maxGunPitch = 18f;
        [SerializeField] private LayerMask lineOfSightLayers = ~0;

        [Header("Objectives")]
        [SerializeField] private bool prioritizeCapturePoints = true;
        [SerializeField, Min(1f)] private float objectiveArrivalDistance = 7f;

        [Header("Driving")]
        [SerializeField, Min(1f)] private float obstacleCheckDistance = 12f;
        [SerializeField, Min(0f)] private float steeringStrength = 1f;

        [Header("Tactical Behaviour")]
        [SerializeField, Min(0.1f)] private float coverSearchInterval = 1.5f;
        [SerializeField, Min(0.5f)] private float coverSearchRadius = 12f;
        [SerializeField, Min(0.5f)] private float coverArrivalDistance = 2.5f;
        [SerializeField, Min(0.1f)] private float coverDurationAfterHit = 4f;
        [SerializeField, Min(0.1f)] private float coverCandidateClearance = 1.6f;
        [SerializeField, Min(0f)] private float alliedTargetFocusBonus = 18f;

        private TankHealth target;
        private float nextTargetRefresh;
        private float nextDecision;
        private Vector2 moveCommand;
        private bool isConfigured;
        private float underFireUntil;
        private float nextCoverSearch;
        private Vector3 coverPosition;
        private bool hasCoverPosition;

        private void Awake()
        {
            if (health == null) health = GetComponent<TankHealth>();
            if (movement == null) movement = GetComponent<TankMovement>();
            if (faction == null) faction = GetComponent<TankFaction>();
            if (weapon == null) weapon = GetComponent<TankWeapon>();

            isConfigured = health != null && movement != null && faction != null &&
                weapon != null && turretYaw != null && gunPitch != null && muzzle != null;

            if (!isConfigured)
                Debug.LogError("TankBotAI: assign health, movement, faction, weapon, turret, gun and muzzle.", this);
        }

        private void OnEnable()
        {
            if (health != null) health.ModuleHealthChanged += OnModuleHealthChanged;
        }

        private void OnModuleHealthChanged(TankModule module, float current, float maximum)
        {
            if (health == null || health.IsDestroyed) return;
            underFireUntil = Time.time + coverDurationAfterHit;
            hasCoverPosition = false;
        }

        private void Update()
        {
            if (!isConfigured) return;
            if (health.IsDestroyed)
            {
                movement.SetMoveInput(Vector2.zero);
                return;
            }

            if (Time.time >= nextTargetRefresh)
            {
                target = FindBestTarget();
                nextTargetRefresh = Time.time + targetRefreshSeconds;
            }

            if (target == null || target.IsDestroyed)
            {
                if (prioritizeCapturePoints)
                {
                    CapturePoint objective = FindObjective();
                    if (objective != null)
                    {
                        Vector3 toObjective = objective.transform.position - transform.position;
                        float objectiveDistance = toObjective.magnitude;
                        if (objectiveDistance > objectiveArrivalDistance)
                        {
                            if (Time.time >= nextDecision)
                            {
                                UpdateDriving(toObjective, objectiveDistance);
                                nextDecision = Time.time + 0.15f;
                            }
                            movement.SetMoveInput(moveCommand);
                        }
                        else movement.SetMoveInput(Vector2.zero);
                        return;
                    }
                }
                movement.SetMoveInput(Vector2.zero);
                return;
            }

            if (Time.time < underFireUntil)
            {
                if (!hasCoverPosition || Time.time >= nextCoverSearch)
                {
                    hasCoverPosition = TryFindCover(target, out coverPosition);
                    nextCoverSearch = Time.time + coverSearchInterval;
                }

                if (hasCoverPosition)
                {
                    Vector3 toCover = coverPosition - transform.position;
                    float coverDistance = Vector3.ProjectOnPlane(toCover, Vector3.up).magnitude;
                    if (coverDistance > coverArrivalDistance)
                    {
                        if (Time.time >= nextDecision)
                        {
                            UpdateDriving(toCover, coverDistance);
                            nextDecision = Time.time + 0.15f;
                        }
                        movement.SetMoveInput(moveCommand);
                        AimAt(GetPredictedTargetPoint(target));
                        return;
                    }

                    movement.SetMoveInput(Vector2.zero);
                    AimAt(GetPredictedTargetPoint(target));
                    return;
                }
            }
            else
            {
                hasCoverPosition = false;
            }

            Vector3 targetPoint = GetPredictedTargetPoint(target);
            Vector3 toTarget = targetPoint - transform.position;
            float distance = toTarget.magnitude;

            AimAt(targetPoint);
            if (Time.time >= nextDecision)
            {
                UpdateDriving(toTarget, distance);
                nextDecision = Time.time + 0.15f;
            }
            movement.SetMoveInput(moveCommand);

            if (distance <= detectionRange && HasLineOfSight(target, targetPoint) &&
                Vector3.Angle(muzzle.forward, (targetPoint - muzzle.position).normalized)
                    <= fireAngleTolerance)
            {
                weapon.FireInDirection((targetPoint - muzzle.position).normalized);
            }
        }

        private TankHealth FindBestTarget()
        {
            TankFaction[] factions = FindObjectsByType<TankFaction>(FindObjectsSortMode.None);
            TankBotAI[] alliedBots = FindObjectsByType<TankBotAI>(FindObjectsSortMode.None);
            TankHealth best = null;
            float bestDistance = detectionRange;

            foreach (TankFaction candidateFaction in factions)
            {
                if (candidateFaction == null || !candidateFaction.isActiveAndEnabled ||
                    candidateFaction == faction || !candidateFaction.IsCombatant ||
                    candidateFaction.Team == TankTeam.Neutral || candidateFaction.Team == faction.Team)
                    continue;

                TankHealth candidate = candidateFaction.GetComponent<TankHealth>();
                if (candidate == null || !candidate.isActiveAndEnabled || candidate.IsDestroyed) continue;

                float distance = Vector3.Distance(transform.position, candidate.transform.position);
                int alliedFocus = 0;
                // Cache the scene's bot list once for this candidate evaluation.
                // Ignore disabled/inactive bots so stale target references do not
                // distort team focus after destruction or scene transitions.
                foreach (TankBotAI ally in alliedBots)
                {
                    if (ally == null || ally == this || !ally.isActiveAndEnabled ||
                        ally.faction == null || !ally.faction.IsCombatant ||
                        ally.faction.Team != faction.Team || ally.health == null ||
                        !ally.health.isActiveAndEnabled || ally.health.IsDestroyed)
                        continue;
                    if (ally.target == candidate) alliedFocus++;
                }

                float targetCost = distance - alliedFocus * alliedTargetFocusBonus;
                if (targetCost < bestDistance)
                {
                    bestDistance = targetCost;
                    best = candidate;
                }
            }
            return best;
        }

        private bool TryFindCover(TankHealth enemy, out Vector3 bestPosition)
        {
            bestPosition = transform.position;
            if (enemy == null || enemy.IsDestroyed) return false;

            Vector3 enemyPoint = GetTargetPoint(enemy);
            float bestScore = float.MaxValue;
            bool found = false;
            const int directions = 16;

            for (int i = 0; i < directions; i++)
            {
                float angle = i * (360f / directions);
                Vector3 radial = Quaternion.Euler(0f, angle, 0f) * Vector3.forward;
                for (int ring = 0; ring < 2; ring++)
                {
                    float radius = coverSearchRadius * (ring == 0 ? 0.55f : 1f);
                    Vector3 sample = transform.position + radial * radius;
                    Vector3 rayStart = sample + Vector3.up * 8f;
                    if (!Physics.Raycast(rayStart, Vector3.down, out RaycastHit groundHit,
                        16f, lineOfSightLayers, QueryTriggerInteraction.Ignore))
                        continue;

                    Vector3 candidate = groundHit.point;
                    Vector3 clearancePoint = candidate + Vector3.up * 1.25f;
                    Collider[] overlaps = Physics.OverlapSphere(clearancePoint,
                        Mathf.Min(coverCandidateClearance, 0.9f), lineOfSightLayers, QueryTriggerInteraction.Ignore);
                    bool blockedByVehicle = false;
                    foreach (Collider overlap in overlaps)
                    {
                        if (overlap == null || overlap.transform.IsChildOf(transform) ||
                            overlap.GetComponentInParent<TankHealth>() == enemy)
                            continue;
                        blockedByVehicle = true;
                        break;
                    }
                    if (blockedByVehicle) continue;

                    Vector3 toCandidate = clearancePoint - enemyPoint;
                    float sightDistance = toCandidate.magnitude;
                    if (sightDistance <= 0.1f) continue;
                    RaycastHit[] sightHits = Physics.RaycastAll(enemyPoint, toCandidate / sightDistance,
                        sightDistance, lineOfSightLayers, QueryTriggerInteraction.Ignore);
                    System.Array.Sort(sightHits, (a, b) => a.distance.CompareTo(b.distance));

                    bool blockedSight = false;
                    foreach (RaycastHit sightHit in sightHits)
                    {
                        if (sightHit.collider == null ||
                            sightHit.collider.transform.IsChildOf(enemy.transform) ||
                            sightHit.collider.transform.IsChildOf(transform))
                            continue;
                        blockedSight = true;
                        break;
                    }
                    if (!blockedSight) continue;

                    float travelCost = Vector3.Distance(transform.position, candidate);
                    float score = travelCost + Mathf.Abs(Vector3.SignedAngle(
                        transform.forward, radial, Vector3.up)) * 0.025f;
                    if (score < bestScore)
                    {
                        bestScore = score;
                        bestPosition = candidate;
                        found = true;
                    }
                }
            }
            return found;
        }

        private CapturePoint FindObjective()
        {
            CapturePoint[] points = FindObjectsByType<CapturePoint>(FindObjectsSortMode.None);
            CapturePoint best = null;
            float bestDistance = float.MaxValue;
            TankBotAI[] alliedBots = FindObjectsByType<TankBotAI>(FindObjectsSortMode.None);
            foreach (CapturePoint point in points)
            {
                if (point == null || !point.isActiveAndEnabled || point.Owner == faction.Team) continue;
                float distance = Vector3.Distance(transform.position, point.transform.position);
                int nearbyAllies = 0;
                foreach (TankBotAI ally in alliedBots)
                {
                    if (ally == null || ally == this || !ally.isActiveAndEnabled ||
                        ally.faction == null || !ally.faction.IsCombatant ||
                        ally.faction.Team != faction.Team || ally.health == null ||
                        !ally.health.isActiveAndEnabled || ally.health.IsDestroyed)
                        continue;
                    if (Vector3.Distance(ally.transform.position, point.transform.position) < 24f)
                        nearbyAllies++;
                }

                // Prefer an objective that is not already crowded by this bot's team.
                float assignmentCost = distance + nearbyAllies * 35f;
                if (assignmentCost < bestDistance)
                {
                    bestDistance = assignmentCost;
                    best = point;
                }
            }
            return best;
        }

        private void AimAt(Vector3 targetPoint)
        {
            Vector3 direction = targetPoint - turretYaw.position;
            Vector3 flatDirection = Vector3.ProjectOnPlane(direction, Vector3.up);
            if (flatDirection.sqrMagnitude > 0.001f)
            {
                Quaternion yaw = Quaternion.LookRotation(flatDirection.normalized, Vector3.up);
                turretYaw.rotation = Quaternion.RotateTowards(
                    turretYaw.rotation, yaw, turretTurnSpeed * Time.deltaTime);
            }

            Transform pitchParent = gunPitch.parent;
            if (pitchParent == null) return;
            Vector3 localDirection = pitchParent.InverseTransformDirection(
                (targetPoint - gunPitch.position).normalized);
            float pitch = -Mathf.Atan2(localDirection.y,
                Mathf.Max(0.001f, new Vector2(localDirection.x, localDirection.z).magnitude))
                * Mathf.Rad2Deg;
            pitch = Mathf.Clamp(pitch, minGunPitch, maxGunPitch);
            Quaternion desiredPitch = Quaternion.Euler(pitch, 0f, 0f);
            gunPitch.localRotation = Quaternion.RotateTowards(
                gunPitch.localRotation, desiredPitch, gunPitchSpeed * Time.deltaTime);
        }

        private void UpdateDriving(Vector3 toTarget, float distance)
        {
            Vector3 flatDirection = Vector3.ProjectOnPlane(toTarget, Vector3.up).normalized;
            float signedAngle = Vector3.SignedAngle(transform.forward, flatDirection, Vector3.up);
            float steering = Mathf.Clamp(signedAngle / 55f, -1f, 1f);

            Vector3 origin = transform.position + Vector3.up * 0.8f;
            bool obstacleAhead = HasObstacleAhead(origin);

            float throttle;
            if (obstacleAhead && Mathf.Abs(signedAngle) < 35f)
            {
                throttle = -0.35f;
                steering = signedAngle >= 0f ? -1f : 1f;
            }
            else if (distance > preferredRange * 1.25f)
            {
                throttle = Mathf.Abs(signedAngle) > 115f ? -0.25f : 1f;
            }
            else if (distance < preferredRange * 0.65f)
            {
                throttle = -0.45f;
            }
            else
            {
                throttle = 0f;
            }

            if (Mathf.Abs(steering) < 0.12f) steering = 0f;
            moveCommand = Vector2.ClampMagnitude(
                new Vector2(steering * steeringStrength, throttle), 1f);
        }

        private bool HasObstacleAhead(Vector3 origin)
        {
            RaycastHit[] hits = Physics.RaycastAll(origin, transform.forward,
                obstacleCheckDistance, lineOfSightLayers, QueryTriggerInteraction.Ignore);
            System.Array.Sort(hits, (a, b) => a.distance.CompareTo(b.distance));

            foreach (RaycastHit hit in hits)
            {
                if (hit.collider == null || hit.collider.transform.IsChildOf(transform))
                    continue;
                return true;
            }
            return false;
        }

        private bool HasLineOfSight(TankHealth enemy, Vector3 destination)
        {
            Vector3 origin = muzzle.position;
            Vector3 direction = destination - origin;
            float distance = direction.magnitude;
            if (distance <= 0.01f) return true;

            RaycastHit[] hits = Physics.RaycastAll(origin, direction / distance, distance,
                lineOfSightLayers, QueryTriggerInteraction.Ignore);
            System.Array.Sort(hits, (a, b) => a.distance.CompareTo(b.distance));
            foreach (RaycastHit hit in hits)
            {
                if (hit.collider == null || hit.collider.transform.IsChildOf(transform))
                    continue;
                return hit.collider.GetComponentInParent<TankHealth>() == enemy;
            }
            return false;
        }

        private Vector3 GetPredictedTargetPoint(TankHealth tank)
        {
            Vector3 targetPoint = GetTargetPoint(tank);
            TankMovement targetMovement = tank.GetComponent<TankMovement>();
            if (targetMovement == null || weapon.MuzzleVelocity <= 1f)
                return targetPoint;

            float distance = Vector3.Distance(muzzle.position, targetPoint);
            float travelTime = Mathf.Clamp(distance / weapon.MuzzleVelocity, 0f, 2f);
            Vector3 targetVelocity = targetMovement.Velocity;
            targetVelocity.y = 0f;
            return targetPoint + targetVelocity * travelTime;
        }

        private static Vector3 GetTargetPoint(TankHealth tank)
        {
            Collider[] colliders = tank.GetComponentsInChildren<Collider>();
            Bounds bounds = new Bounds(tank.transform.position + Vector3.up, Vector3.one);
            bool found = false;
            foreach (Collider item in colliders)
            {
                if (item == null || item.isTrigger) continue;
                if (!found) { bounds = item.bounds; found = true; }
                else bounds.Encapsulate(item.bounds);
            }
            return found ? bounds.center : tank.transform.position + Vector3.up;
        }

        private void OnDisable()
        {
            if (health != null) health.ModuleHealthChanged -= OnModuleHealthChanged;
            if (movement != null) movement.SetMoveInput(Vector2.zero);
        }
    }
}