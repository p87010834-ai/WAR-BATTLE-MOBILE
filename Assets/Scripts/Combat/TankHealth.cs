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
            new ModuleConfig { module = TankModule.Turret, health = 220f },
            new ModuleConfig { module = TankModule.LeftTrack, health = 140f },
            new ModuleConfig { module = TankModule.RightTrack, health = 140f }
        };

        private readonly Dictionary<TankModule, TankModuleState> states =
            new Dictionary<TankModule, TankModuleState>();

        public event Action<TankModule, float, float> ModuleHealthChanged;
        public event Action TankDestroyed;

        public bool IsDestroyed { get; private set; }
        public bool EngineDisabled => IsDisabled(TankModule.Engine);
        public bool TurretDisabled => IsDisabled(TankModule.Turret);
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

            if (!states.ContainsKey(TankModule.Hull))
                states.Add(TankModule.Hull, new TankModuleState(TankModule.Hull, 500f));
        }

        public bool IsDisabled(TankModule module)
        {
            return states.TryGetValue(module, out TankModuleState state) && state.IsDisabled;
        }

        public float GetHealth(TankModule module)
        {
            return states.TryGetValue(module, out TankModuleState state) ? state.CurrentHealth : 0f;
        }

        public void ApplyDamage(TankModule module, float damage)
        {
            if (IsDestroyed || damage <= 0f)
                return;

            if (!states.TryGetValue(module, out TankModuleState state))
            {
                Debug.LogWarning($"Tank module is not configured: {module}", this);
                return;
            }

            float applied = state.ApplyDamage(damage);
            if (applied <= 0f)
                return;

            ModuleHealthChanged?.Invoke(module, state.CurrentHealth, state.MaxHealth);

            if (module == TankModule.Hull && state.IsDisabled)
            {
                IsDestroyed = true;
                TankDestroyed?.Invoke();
            }
        }
    }
}