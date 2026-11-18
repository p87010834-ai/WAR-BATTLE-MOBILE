using UnityEngine;
using WarBattleMobile.Combat;

namespace WarBattleMobile.Vehicle
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class TankMovement : MonoBehaviour
    {
        [SerializeField, Min(0f)] private float forwardSpeed = 7f;
        [SerializeField, Min(0f)] private float reverseSpeed = 3f;
        [SerializeField, Min(0f)] private float turnSpeed = 65f;
        [SerializeField, Range(0f, 1f)] private float damagedEngineSpeedFactor = 0.35f;
        [SerializeField, Range(0f, 1f)] private float damagedTransmissionTurnFactor = 0.2f;
        [SerializeField] private float gravity = -20f;
        [SerializeField] private TankHealth tankHealth;

        private CharacterController controller;
        private Vector2 movementInput;
        private float verticalVelocity;

        public Vector2 MovementInput => movementInput;
        public float CurrentSpeed => controller != null ? controller.velocity.magnitude : 0f;

        private void Awake()
        {
            controller = GetComponent<CharacterController>();
            if (tankHealth == null) tankHealth = GetComponent<TankHealth>();
        }

        public void SetMoveInput(Vector2 input)
        {
            movementInput = Vector2.ClampMagnitude(input, 1f);
        }

        private void Update()
        {
            if (tankHealth != null && tankHealth.IsDestroyed) return;

            float trackFactor = 1f;
            float engineFactor = 1f;
            float transmissionTurnFactor = 1f;

            if (tankHealth != null)
            {
                if (tankHealth.LeftTrackDisabled && tankHealth.RightTrackDisabled)
                    trackFactor = 0f;
                else if (tankHealth.LeftTrackDisabled || tankHealth.RightTrackDisabled)
                    trackFactor = 0.45f;

                if (tankHealth.EngineDisabled)
                    engineFactor = damagedEngineSpeedFactor;
                if (tankHealth.TransmissionDisabled)
                    transmissionTurnFactor = damagedTransmissionTurnFactor;
            }

            float throttle = movementInput.y;
            float speed = throttle >= 0f ? forwardSpeed : reverseSpeed;
            Vector3 move = transform.forward *
                (throttle * speed * trackFactor * engineFactor);

            float steering = movementInput.x * turnSpeed * trackFactor *
                transmissionTurnFactor;
            if (Mathf.Abs(throttle) > 0.05f)
                transform.Rotate(0f, steering * Time.deltaTime * Mathf.Sign(throttle), 0f);

            if (controller.isGrounded && verticalVelocity < 0f)
                verticalVelocity = -2f;
            verticalVelocity += gravity * Time.deltaTime;
            move.y = verticalVelocity;
            controller.Move(move * Time.deltaTime);
        }
    }
}