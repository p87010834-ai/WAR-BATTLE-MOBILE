using UnityEngine;
using WarBattleMobile.Combat;

namespace WarBattleMobile.Vehicle
{
    public sealed class TankTurretAim : MonoBehaviour
    {
        [SerializeField] private Transform turretYaw;
        [SerializeField] private Transform gunPitch;
        [SerializeField] private Camera aimCamera;
        [SerializeField] private LayerMask aimLayers = ~0;
        [SerializeField, Min(1f)] private float yawSpeed = 120f;
        [SerializeField, Min(1f)] private float pitchSpeed = 80f;
        [SerializeField] private float minPitch = -8f;
        [SerializeField] private float maxPitch = 18f;
        [SerializeField] private TankHealth tankHealth;

        private Vector2 aimScreenPosition;
        private bool hasAimPosition;

        private void Awake()
        {
            if (aimCamera == null)
                aimCamera = Camera.main;
            if (tankHealth == null)
                tankHealth = GetComponentInParent<TankHealth>();
        }

        // Connect this to the right-side touch area or aiming stick.
        public void SetAimScreenPosition(Vector2 screenPosition)
        {
            aimScreenPosition = screenPosition;
            hasAimPosition = true;
        }

        private void Update()
        {
            if (!hasAimPosition || aimCamera == null || turretYaw == null || gunPitch == null)
                return;
            if (tankHealth != null && (tankHealth.IsDestroyed || tankHealth.TurretDisabled))
                return;

            Ray ray = aimCamera.ScreenPointToRay(aimScreenPosition);
            if (!Physics.Raycast(ray, out RaycastHit hit, 1000f, aimLayers, QueryTriggerInteraction.Ignore))
                return;

            Vector3 flatDirection = hit.point - turretYaw.position;
            flatDirection.y = 0f;
            if (flatDirection.sqrMagnitude > 0.01f)
            {
                Quaternion targetYaw = Quaternion.LookRotation(flatDirection.normalized, Vector3.up);
                turretYaw.rotation = Quaternion.RotateTowards(
                    turretYaw.rotation, targetYaw, yawSpeed * Time.deltaTime);
            }

            Vector3 localTarget = gunPitch.parent.InverseTransformPoint(hit.point);
            float pitch = -Mathf.Atan2(localTarget.y, Mathf.Max(0.01f,
                new Vector2(localTarget.x, localTarget.z).magnitude)) * Mathf.Rad2Deg;
            pitch = Mathf.Clamp(pitch, minPitch, maxPitch);
            Quaternion targetPitch = Quaternion.Euler(pitch, 0f, 0f);
            gunPitch.localRotation = Quaternion.RotateTowards(
                gunPitch.localRotation, targetPitch, pitchSpeed * Time.deltaTime);
        }
    }
}