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
        private readonly HashSet<TankFaction> occupants = new HashSet<TankFaction>();
        private float progress;
        public string PointId => pointId;
        public TankTeam Owner => owner;
        public float CaptureProgress01 => Mathf.Clamp01(progress / captureSeconds);
        public bool IsContested { get; private set; }
        public event Action<CapturePoint, TankTeam> OwnershipChanged;
        public event Action<CapturePoint, TankTeam, float> ProgressChanged;

        private void Awake() { GetComponent<Collider>().isTrigger = true; }

        private void OnTriggerEnter(Collider other)
        {
            TankFaction f = other.GetComponentInParent<TankFaction>();
            if (f != null && f.IsCombatant) occupants.Add(f);
        }

        private void OnTriggerExit(Collider other)
        {
            TankFaction f = other.GetComponentInParent<TankFaction>();
            if (f != null) occupants.Remove(f);
        }

        private void Update()
        {
            occupants.RemoveWhere(f => f == null || !f.isActiveAndEnabled);
            int blue = 0, red = 0;
            foreach (TankFaction f in occupants)
            {
                if (f == null || !OverlapsTank(f)) continue;
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
                    ProgressChanged?.Invoke(this, capturing, CaptureProgress01);
                }
                return;
            }

            progress = Mathf.Min(captureSeconds, progress + Time.deltaTime);
            ProgressChanged?.Invoke(this, capturing, CaptureProgress01);
            if (progress >= captureSeconds)
            {
                owner = capturing;
                progress = 0f;
                OwnershipChanged?.Invoke(this, owner);
                ProgressChanged?.Invoke(this, capturing, 0f);
            }
        }

        private bool OverlapsTank(TankFaction faction)
        {
            Collider area = GetComponent<Collider>();
            foreach (Collider c in faction.GetComponentsInChildren<Collider>())
                if (c != null && !c.isTrigger && area.bounds.Intersects(c.bounds)) return true;
            return false;
        }
    }
}