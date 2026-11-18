using System;
using System.Collections;
using UnityEngine;

namespace WarBattleMobile.Combat
{
    public sealed class TankWeapon : MonoBehaviour
    {
        [SerializeField] private Transform muzzle;
        [SerializeField] private GameObject projectilePrefab;
        [SerializeField] private Camera aimCamera;
        [SerializeField] private LayerMask aimLayers = ~0;
        [SerializeField, Min(1f)] private float muzzleVelocity = 120f;
        [SerializeField, Min(0.1f)] private float reloadSeconds = 5f;
        [SerializeField, Min(1f)] private float penetrationMillimetres = 300f;
        [SerializeField, Min(1f)] private float projectileDamage = 120f;
        [SerializeField, Min(1f)] private float maxRange = 1500f;
        [SerializeField] private int ammunition = 20;
        [SerializeField] private TankHealth tankHealth;

        public event Action<int, float> AmmunitionChanged;
        public bool IsReloading { get; private set; }
        public int Ammunition => ammunition;
        public float ReloadProgress01 => !IsReloading ? 1f :
            1f - Mathf.Clamp01((reloadEndsAt - Time.time) / Mathf.Max(0.1f, reloadSeconds));
        private float reloadEndsAt;
        private Vector2 aimScreenPosition;
        private bool hasAimScreenPosition;

        private void Awake()
        {
            if (aimCamera == null) aimCamera = Camera.main;
            if (tankHealth == null) tankHealth = GetComponentInParent<TankHealth>();
        }

        private void OnEnable()
        {
            if (tankHealth != null)
                tankHealth.ModuleDisabled += HandleModuleDisabled;
        }

        private void Start()
        {
            if (tankHealth != null)
            {
                tankHealth.ModuleDisabled -= HandleModuleDisabled;
                tankHealth.ModuleDisabled += HandleModuleDisabled;
                if (tankHealth.AmmunitionRackDisabled)
                    SetAmmunitionToZero();
            }
        }

        private void OnDisable()
        {
            if (tankHealth != null)
                tankHealth.ModuleDisabled -= HandleModuleDisabled;
        }

        private void HandleModuleDisabled(TankModule module)
        {
            if (module == TankModule.AmmunitionRack)
                SetAmmunitionToZero();
        }

        private void SetAmmunitionToZero()
        {
            ammunition = 0;
            AmmunitionChanged?.Invoke(ammunition, reloadSeconds);
        }

        public void SetAimScreenPosition(Vector2 screenPosition)
        {
            aimScreenPosition = screenPosition;
            hasAimScreenPosition = true;
        }

        // Fire follows the latest touch aim point; without touch input it uses screen centre.
        public void Fire()
        {
            Vector3 direction = muzzle != null ? muzzle.forward : transform.forward;
            if (aimCamera != null)
            {
                Ray aimRay = hasAimScreenPosition
                    ? aimCamera.ScreenPointToRay(aimScreenPosition)
                    : aimCamera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f));
                if (Physics.Raycast(aimRay, out RaycastHit aimHit, maxRange, aimLayers,
                    QueryTriggerInteraction.Ignore))
                {
                    if (tankHealth == null ||
                        aimHit.collider.GetComponentInParent<TankHealth>() != tankHealth)
                        direction = aimHit.point - (muzzle != null ? muzzle.position : transform.position);
                }
            }
            TryFire(direction);
        }

        // AI and scripted turrets provide their own world-space firing direction.
        public void FireInDirection(Vector3 worldDirection)
        {
            TryFire(worldDirection);
        }

        private void TryFire(Vector3 direction)
        {
            if (IsReloading || ammunition <= 0 || muzzle == null || projectilePrefab == null)
                return;
            if (tankHealth != null &&
                (tankHealth.IsDestroyed || tankHealth.TurretDisabled ||
                 tankHealth.GunBreechDisabled || tankHealth.AmmunitionRackDisabled))
                return;
            if (direction.sqrMagnitude < 0.0001f) return;

            direction.Normalize();
            GameObject projectileObject = Instantiate(
                projectilePrefab, muzzle.position, Quaternion.LookRotation(direction));
            TankProjectile projectile = projectileObject.GetComponent<TankProjectile>();
            if (projectile == null)
            {
                Debug.LogError("Projectile prefab requires TankProjectile component.", projectilePrefab);
                Destroy(projectileObject);
                return;
            }

            projectile.Launch(direction, muzzleVelocity, penetrationMillimetres,
                projectileDamage, maxRange, tankHealth);
            ammunition--;
            AmmunitionChanged?.Invoke(ammunition, reloadSeconds);
            StartCoroutine(ReloadRoutine());
        }

        private IEnumerator ReloadRoutine()
        {
            IsReloading = true;
            reloadEndsAt = Time.time + reloadSeconds;
            yield return new WaitForSeconds(reloadSeconds);
            IsReloading = false;
        }
    }
}