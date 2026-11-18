using System;
using System.Collections.Generic;
using UnityEngine;

namespace WarBattleMobile.Combat
{
    public sealed class TankHealth : MonoBehaviour
    {
        [Serializable]
        private struct ModuleConfig
        {
            public TankModule module;
            [Min(1f)] public float health;
        }

        [SerializeField] private ModuleConfig[] modules =
        {
            new ModuleConfig { module = TankModule.Hull, health = 500f },
            new ModuleConfig { module = TankModule.Engine, health = 180f },
            new ModuleConfig { module = TankModule.Transmission, health = 160f },
            new ModuleConfig { module = TankModule.Turret, health = 220f },
            new ModuleConfig { module = TankModule.GunBreech, health = 120f },
            new ModuleConfig { module = TankModule.Optics, health = 90f },
            new ModuleConfig { module = TankModule.AmmunitionRack, health = 110f },
            new ModuleConfig { module = TankModule.LeftTrack, health = 140f },
            new ModuleConfig { module = TankModule.RightTrack, health = 140f }
        };

        private readonly Dictionary<TankModule, TankModuleState> states =
            new Dictionary<TankModule, TankModuleState>();

        public event Action<TankModule, float, float> ModuleHealthChanged;
        public event Action<TankModule> ModuleDisabled;
        public event Action TankDestroyed;

        public bool IsDestroyed { get; private set; }
        public bool EngineDisabled => IsDisabled(TankModule.Engine);
        public bool TransmissionDisabled => IsDisabled(TankModule.Transmission);
        public bool TurretDisabled => IsDisabled(TankModule.Turret);
        public bool GunBreechDisabled => IsDisabled(TankModule.GunBreech);
        public bool OpticsDisabled => IsDisabled(TankModule.Optics);
        public bool AmmunitionRackDisabled => IsDisabled(TankModule.AmmunitionRack);
        public bool LeftTrackDisabled => IsDisabled(TankModule.LeftTrack);
        public bool RightTrackDisabled => IsDisabled(TankModule.RightTrack);

        private void Awake()
        {
            states.Clear();
            foreach (ModuleConfig config in modules)
            {
                if (states.ContainsKey(config.module))
                {
                    Debug.LogWarning($"Duplicate tank module configuration: {config.module}", this);
                    continue;
                }
                states.Add(config.module, new TankModuleState(config.module, config.health));
            }

            AddDefaultIfMissing(TankModule.Hull, 500f);
            AddDefaultIfMissing(TankModule.Engine, 180f);
            AddDefaultIfMissing(TankModule.Transmission, 160f);
            AddDefaultIfMissing(TankModule.Turret, 220f);
            AddDefaultIfMissing(TankModule.GunBreech, 120f);
            AddDefaultIfMissing(TankModule.Optics, 90f);
            AddDefaultIfMissing(TankModule.AmmunitionRack, 110f);
            AddDefaultIfMissing(TankModule.LeftTrack, 140f);
            AddDefaultIfMissing(TankModule.RightTrack, 140f);
        }

        private void AddDefaultIfMissing(TankModule module, float health)
        {
            if (!states.ContainsKey(module))
                states.Add(module, new TankModuleState(module, health));
        }

        public bool IsDisabled(TankModule module)
        {
            return states.TryGetValue(module, out TankModuleState state) && state.IsDisabled;
        }

        public float GetHealth(TankModule module)
        {
            return states.TryGetValue(module, out TankModuleState state) ? state.CurrentHealth : 0f;
        }

        public float GetMaxHealth(TankModule module)
        {
            return states.TryGetValue(module, out TankModuleState state) ? state.MaxHealth : 0f;
        }

        public void ApplyDamage(TankModule module, float damage)
        {
            if (IsDestroyed || damage <= 0f || float.IsNaN(damage) || float.IsInfinity(damage)) return;

            if (!states.TryGetValue(module, out TankModuleState state))
            {
                Debug.LogWarning($"Tank module is not configured: {module}", this);
                return;
            }

            bool wasDisabled = state.IsDisabled;
            float applied = state.ApplyDamage(damage);
            if (applied <= 0f) return;

            ModuleHealthChanged?.Invoke(module, state.CurrentHealth, state.MaxHealth);

            if (!wasDisabled && state.IsDisabled)
            {
                ModuleDisabled?.Invoke(module);
                if (module == TankModule.Hull)
                {
                    IsDestroyed = true;
                    TankDestroyed?.Invoke();
                }
            }
        }
    }
}