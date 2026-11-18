using System;
using System.Collections;
using UnityEngine;
using WarBattleMobile.Vehicle;

namespace WarBattleMobile.Combat
{
    public sealed class TankWeapon : MonoBehaviour
    {
        [SerializeField] private Transform muzzle;
        [SerializeField] private Camera aimCamera;
        [SerializeField] private LayerMask hitLayers = ~0;
        [SerializeField, Min(1f)] private float muzzleVelocity = 120f;
        [SerializeField, Min(0.1f)] private float reloadSeconds = 5f;
        [SerializeField, Min(0f)] private float baseDamage = 100f;
        [SerializeField, Min(1f)] private float maxRange = 800f;
        [SerializeField] private int ammunition = 20;
        [SerializeField] private TankHealth tankHealth;
        [SerializeField] private TankTurretAim turretAim;

        public event Action<int, float> AmmunitionChanged;
        public bool IsReloading { get; private set; }
        public int Ammunition => ammunition;

        private void Awake()
        {
            if (aimCamera == null)
                aimCamera = Camera.main;
            if (tankHealth == null)
                tankHealth = GetComponentInParent<TankHealth>();
            if (turretAim == null)
                turretAim = GetComponentInParent<TankTurretAim>();
        }

        // Connect the fire button's OnClick event to this method.
        public void Fire()
        {
            if (IsReloading || ammunition <= 0 || muzzle == null)
                return;
            if (tankHealth != null &&
                (tankHealth.IsDestroyed || tankHealth.TurretDisabled))
                return;

            ammunition--;
            AmmunitionChanged?.Invoke(ammunition, reloadSeconds);
            Vector3 direction = muzzle.forward;

            if (aimCamera != null)
            {
                Ray ray = aimCamera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f));
                if (Physics.Raycast(ray, out RaycastHit aimHit, maxRange, hitLayers,
                    QueryTriggerInteraction.Ignore))
                    direction = (aimHit.point - muzzle.position).normalized;
            }

            if (Physics.Raycast(muzzle.position, direction, out RaycastHit hit,
                maxRange, hitLayers, QueryTriggerInteraction.Ignore))
            {
                TankHealth target = hit.collider.GetComponentInParent<TankHealth>();
                if (target != null && target != tankHealth)
                {
                    TankModule module = ResolveModule(hit.collider);
                    float distanceFactor = Mathf.Clamp01(1f - hit.distance / (maxRange * 1.5f));
                    float damage = baseDamage * Mathf.Lerp(0.55f, 1f, distanceFactor);
                    target.ApplyDamage(module, damage);
                }
            }

            StartCoroutine(ReloadRoutine());
        }

        private static TankModule ResolveModule(Collider hitCollider)
        {
            string objectName = hitCollider.gameObject.name.ToLowerInvariant();
            if (objectName.Contains("engine")) return TankModule.Engine;
            if (objectName.Contains("turret")) return TankModule.Turret;
            if (objectName.Contains("lefttrack") || objectName.Contains("left_track"))
                return TankModule.LeftTrack;
            if (objectName.Contains("righttrack") || objectName.Contains("right_track"))
                return TankModule.RightTrack;
            return TankModule.Hull;
        }

        private IEnumerator ReloadRoutine()
        {
            IsReloading = true;
            yield return new WaitForSeconds(reloadSeconds);
            IsReloading = false;
        }
    }
}