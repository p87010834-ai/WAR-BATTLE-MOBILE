using System;
using System.Collections;
using UnityEngine;
using WarBattleMobile.Vehicle;

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
        [SerializeField] private TankTurretAim turretAim;

        public event Action<int, float> AmmunitionChanged;
        public bool IsReloading { get; private set; }
        public int Ammunition => ammunition;

        private void Awake()
        {
            if (aimCamera == null) aimCamera = Camera.main;
            if (tankHealth == null) tankHealth = GetComponentInParent<TankHealth>();
            if (turretAim == null) turretAim = GetComponentInParent<TankTurretAim>();
        }

        public void Fire()
        {
            if (IsReloading || ammunition <= 0 || muzzle == null || projectilePrefab == null)
                return;
            if (tankHealth != null && (tankHealth.IsDestroyed || tankHealth.TurretDisabled))
                return;

            Vector3 direction = muzzle.forward;
            if (aimCamera != null)
            {
                Ray aimRay = aimCamera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f));
                if (Physics.Raycast(aimRay, out RaycastHit aimHit, maxRange, aimLayers,
                    QueryTriggerInteraction.Ignore))
                {
                    if (tankHealth == null || aimHit.collider.GetComponentInParent<TankHealth>() != tankHealth)
                        direction = (aimHit.point - muzzle.position).normalized;
                }
            }

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
            yield return new WaitForSeconds(reloadSeconds);
            IsReloading = false;
        }
    }
}