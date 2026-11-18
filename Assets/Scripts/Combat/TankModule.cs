using System;
using UnityEngine;

namespace WarBattleMobile.Combat
{
    public enum TankModule
    {
        Hull,
        Engine,
        Transmission,
        Turret,
        GunBreech,
        Optics,
        AmmunitionRack,
        LeftTrack,
        RightTrack
    }

    [Serializable]
    public sealed class TankModuleState
    {
        [SerializeField] private TankModule module;
        [SerializeField, Min(1f)] private float maxHealth = 100f;
        [SerializeField, Min(0f)] private float currentHealth = 100f;

        public TankModule Module => module;
        public float MaxHealth => maxHealth;
        public float CurrentHealth => currentHealth;
        public bool IsDisabled => currentHealth <= 0f;

        public TankModuleState(TankModule module, float health)
        {
            this.module = module;
            maxHealth = Mathf.Max(1f, health);
            currentHealth = maxHealth;
        }

        public float ApplyDamage(float amount)
        {
            float applied = Mathf.Clamp(amount, 0f, currentHealth);
            currentHealth -= applied;
            return applied;
        }

        public void RepairForSetup(float health)
        {
            currentHealth = Mathf.Clamp(health, 0f, maxHealth);
        }
    }
}