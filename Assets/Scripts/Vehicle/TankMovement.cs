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
        [SerializeField] private float gravity = -20f;
        [SerializeField] private TankHealth tankHealth;

        private CharacterController controller;
        private Vector2 movementInput;
        private float verticalVelocity;

        private void Awake()
        {
            controller = GetComponent<CharacterController>();
            if (tankHealth == null)
                tankHealth = GetComponent<TankHealth>();
        }

        // Connect on-screen joystick values to this method.
        public void SetMoveInput(Vector2 input)
        {
            movementInput = Vector2.ClampMagnitude(input, 1f);
        }

        private void Update()
        {
            if (tankHealth != null && tankHealth.IsDestroyed)
                return;

            float trackFactor = 1f;
            if (tankHealth != null)
            {
                if (tankHealth.LeftTrackDisabled && tankHealth.RightTrackDisabled)
                    trackFactor = 0f;
                else if (tankHealth.LeftTrackDisabled || tankHealth.RightTrackDisabled)
                    trackFactor = 0.45f;
            }

            float throttle = movementInput.y;
            float speed = throttle >= 0f ? forwardSpeed : reverseSpeed;
            Vector3 move = transform.forward * (throttle * speed * trackFactor);

            float steering = movementInput.x * turnSpeed * trackFactor;
            if (Mathf.Abs(throttle) > 0.05f)
                transform.Rotate(0f, steering * Time.deltaTime * Mathf.Sign(throttle), 0f);

            if (controller.isGrounded && verticalVelocity < 0f)
                verticalVelocity = -2f;

            verticalVelocity += gravity * Time.deltaTime;
            move.y = verticalVelocity;

            if (tankHealth != null && tankHealth.EngineDisabled)
                move.x = move.z = 0f;

            controller.Move(move * Time.deltaTime);
        }
    }
}