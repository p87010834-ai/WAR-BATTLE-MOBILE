using System;
using System.Collections.Generic;
using UnityEngine;

namespace WarBattleMobile.Combat
{
    [RequireComponent(typeof(Collider))]
    public sealed class CapturePoint : MonoBehaviour
    {
        [SerializeField] private string pointId = "A";
        [SerializeField, Min(1f)] private float captureSeconds = 12f;
        [SerializeField] private TankTeam owner = TankTeam.Neutral;
        private readonly Dictionary<TankFaction, int> occupants = new Dictionary<TankFaction, int>();
        private float progress;
        private TankTeam capturingTeam = TankTeam.Neutral;
        public string PointId => pointId;
        public TankTeam Owner => owner;
        public float CaptureProgress01 => Mathf.Clamp01(progress / captureSeconds);
        public bool IsContested { get; private set; }

        public void Configure(string id, float captureDurationSeconds)
        {
            if (!string.IsNullOrWhiteSpace(id)) pointId = id;
            captureSeconds = Mathf.Max(1f, captureDurationSeconds);
        }

        public event Action<CapturePoint, TankTeam> OwnershipChanged;
        public event Action<CapturePoint, TankTeam, float> ProgressChanged;

        private void Awake() { GetComponent<Collider>().isTrigger = true; }

        private void OnTriggerEnter(Collider other)
        {
            if (other == null || other.isTrigger) return;
            TankFaction f = other.GetComponentInParent<TankFaction>();
            if (f == null || !f.IsCombatant || !IsAliveCombatant(f)) return;
            occupants.TryGetValue(f, out int count);
            occupants[f] = count + 1;
        }

        private void OnTriggerExit(Collider other)
        {
            TankFaction f = other.GetComponentInParent<TankFaction>();
            if (f == null || !occupants.TryGetValue(f, out int count)) return;
            if (count <= 1) occupants.Remove(f);
            else occupants[f] = count - 1;
        }

        private void Update()
        {
            List<TankFaction> stale = null;
            foreach (KeyValuePair<TankFaction, int> entry in occupants)
            {
                if (!IsAliveCombatant(entry.Key) || entry.Value <= 0)
                {
                    if (stale == null) stale = new List<TankFaction>();
                    stale.Add(entry.Key);
                }
            }
            if (stale != null)
                foreach (TankFaction faction in stale) occupants.Remove(faction);

            // Count each living vehicle once, regardless of how many of its
            // colliders overlap the capture trigger.
            int blue = 0, red = 0;
            foreach (KeyValuePair<TankFaction, int> entry in occupants)
            {
                TankFaction f = entry.Key;
                if (!IsAliveCombatant(f)) continue;
                if (f.Team == TankTeam.Blue) blue++;
                else if (f.Team == TankTeam.Red) red++;
            }

            IsContested = blue > 0 && red > 0;
            if (IsContested || (blue == 0 && red == 0)) return;

            TankTeam capturing = blue > 0 ? TankTeam.Blue : TankTeam.Red;
            if (capturing == owner)
            {
                if (progress > 0f)
                {
                    progress = Mathf.Max(0f, progress - Time.deltaTime * 0.5f);
                    if (progress <= 0f) capturingTeam = TankTeam.Neutral;
                    ProgressChanged?.Invoke(this, capturingTeam, CaptureProgress01);
                }
                return;
            }

            // Progress belongs to one attacking team only. If control changes,
            // the new side must start its own capture rather than inheriting
            // the previous team's nearly completed progress.
            if (capturingTeam != capturing)
            {
                progress = 0f;
                capturingTeam = capturing;
            }

            progress = Mathf.Min(captureSeconds, progress + Time.deltaTime);
            ProgressChanged?.Invoke(this, capturing, CaptureProgress01);
            if (progress >= captureSeconds)
            {
                owner = capturing;
                progress = 0f;
                capturingTeam = TankTeam.Neutral;
                OwnershipChanged?.Invoke(this, owner);
                ProgressChanged?.Invoke(this, capturing, 0f);
            }
        }

        private static bool IsAliveCombatant(TankFaction faction)
        {
            if (faction == null || !faction.isActiveAndEnabled ||
                !faction.gameObject.activeInHierarchy || !faction.IsCombatant)
                return false;

            TankHealth health = faction.GetComponent<TankHealth>();
            return health != null && !health.IsDestroyed;
        }
    }
}