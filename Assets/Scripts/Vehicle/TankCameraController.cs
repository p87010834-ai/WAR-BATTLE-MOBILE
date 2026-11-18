using UnityEngine;

namespace WarBattleMobile.Vehicle
{
    /// <summary>
    /// Third-person follow camera with orbit, pinch/scroll zoom, collision
    /// avoidance, and a closer aiming view. Attach to the scene's Main Camera.
    /// </summary>
    [RequireComponent(typeof(Camera))]
    public sealed class TankCameraController : MonoBehaviour
    {
        [Header("Target")]
        [SerializeField] private Transform target;
        [SerializeField] private Vector3 targetOffset = new Vector3(0f, 1.8f, 0f);

        [Header("Orbit")]
        [SerializeField, Range(10f, 80f)] private float pitch = 28f;
        [SerializeField] private float yaw;
        [SerializeField, Min(10f)] private float dragSensitivity = 0.22f;
        [SerializeField, Min(0.1f)] private float rotationSmoothness = 12f;

        [Header("Zoom")]
        [SerializeField, Min(2f)] private float normalDistance = 11f;
        [SerializeField, Min(2f)] private float minimumDistance = 5f;
        [SerializeField, Min(2f)] private float maximumDistance = 18f;
        [SerializeField, Min(2f)] private float aimingDistance = 5.5f;
        [SerializeField, Min(0.1f)] private float zoomSensitivity = 0.012f;
        [SerializeField, Min(0.1f)] private float zoomSmoothness = 8f;

        [Header("Collision")]
        [SerializeField, Min(0.05f)] private float collisionRadius = 0.25f;
        [SerializeField, Min(0f)] private float collisionPadding = 0.15f;
        [SerializeField] private LayerMask collisionLayers = ~0;

        [Header("Touch")]
        [SerializeField, Range(0.1f, 0.5f)] private float cameraTouchRegionStart = 0.76f;

        private Camera attachedCamera;
        private Vector3 positionVelocity;
        private float targetDistance;
        private float currentDistance;
        private float pinchPreviousDistance;
        private int orbitFingerId = -1;
        private bool aimingMode;

        public bool IsAimingMode => aimingMode;
        public Transform Target => target;

        private void Awake()
        {
            attachedCamera = GetComponent<Camera>();
            targetDistance = Mathf.Clamp(normalDistance, minimumDistance, maximumDistance);
            currentDistance = targetDistance;
            if (target != null && yaw == 0f) yaw = target.eulerAngles.y;
        }

        public void SetTarget(Transform newTarget)
        {
            target = newTarget;
            positionVelocity = Vector3.zero;
            if (target != null) yaw = target.eulerAngles.y;
        }

        public void SetAimingMode(bool enabled)
        {
            aimingMode = enabled;
            targetDistance = aimingMode
                ? Mathf.Clamp(aimingDistance, minimumDistance, maximumDistance)
                : Mathf.Clamp(normalDistance, minimumDistance, maximumDistance);
        }

        public void ToggleAimingMode()
        {
            SetAimingMode(!aimingMode);
        }

        private void LateUpdate()
        {
            if (target == null) return;
            ReadTouchInput();
            ReadMouseInput();

            float desiredDistance = aimingMode
                ? Mathf.Clamp(aimingDistance, minimumDistance, maximumDistance)
                : targetDistance;
            currentDistance = Mathf.Lerp(currentDistance, desiredDistance,
                1f - Mathf.Exp(-zoomSmoothness * Time.deltaTime));

            Vector3 lookPoint = target.position + targetOffset;
            Quaternion orbit = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 backward = -(orbit * Vector3.forward);
            float safeDistance = currentDistance;

            if (Physics.SphereCast(lookPoint, collisionRadius, backward,
                out RaycastHit hit, currentDistance, collisionLayers,
                QueryTriggerInteraction.Ignore))
            {
                if (!hit.transform.IsChildOf(target))
                    safeDistance = Mathf.Max(0.6f, hit.distance - collisionPadding);
            }

            Vector3 desiredPosition = lookPoint + backward * safeDistance;
            transform.position = Vector3.SmoothDamp(transform.position,
                desiredPosition, ref positionVelocity, 1f / Mathf.Max(0.1f, rotationSmoothness));
            Quaternion desiredRotation = Quaternion.LookRotation(
                lookPoint - transform.position, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, desiredRotation,
                1f - Mathf.Exp(-rotationSmoothness * Time.deltaTime));
        }

        private void ReadTouchInput()
        {
            if (Input.touchCount == 0)
            {
                orbitFingerId = -1;
                pinchPreviousDistance = 0f;
                return;
            }

            Touch first = Input.GetTouch(0);
            if (Input.touchCount >= 2)
            {
                Touch second = Input.GetTouch(1);
                if (IsInCameraRegion(first.position) && IsInCameraRegion(second.position))
                {
                    float distance = Vector2.Distance(first.position, second.position);
                    if (pinchPreviousDistance > 0f)
                        targetDistance = Mathf.Clamp(targetDistance -
                            (distance - pinchPreviousDistance) * zoomSensitivity,
                            minimumDistance, maximumDistance);
                    pinchPreviousDistance = distance;
                    orbitFingerId = -1;
                    return;
                }
            }
            pinchPreviousDistance = 0f;

            Touch orbitTouch = first;
            if (orbitFingerId < 0 && orbitTouch.phase == TouchPhase.Began &&
                IsInCameraRegion(orbitTouch.position))
                orbitFingerId = orbitTouch.fingerId;

            if (orbitTouch.fingerId == orbitFingerId &&
                (orbitTouch.phase == TouchPhase.Moved || orbitTouch.phase == TouchPhase.Stationary))
            {
                yaw += orbitTouch.deltaPosition.x * dragSensitivity;
                pitch = Mathf.Clamp(pitch - orbitTouch.deltaPosition.y * dragSensitivity, 12f, 72f);
            }

            if (orbitTouch.phase == TouchPhase.Ended || orbitTouch.phase == TouchPhase.Canceled)
                orbitFingerId = -1;
        }

        private void ReadMouseInput()
        {
#if UNITY_EDITOR || UNITY_STANDALONE
            if (Input.GetMouseButton(1))
            {
                yaw += Input.GetAxis("Mouse X") * dragSensitivity * 8f;
                pitch = Mathf.Clamp(pitch - Input.GetAxis("Mouse Y") * dragSensitivity * 8f, 12f, 72f);
            }
            float scroll = Input.mouseScrollDelta.y;
            if (Mathf.Abs(scroll) > 0.001f)
                targetDistance = Mathf.Clamp(targetDistance - scroll,
                    minimumDistance, maximumDistance);
#endif
        }

        private bool IsInCameraRegion(Vector2 screenPosition)
        {
            return screenPosition.y >= Screen.height * cameraTouchRegionStart;
        }
    }
}