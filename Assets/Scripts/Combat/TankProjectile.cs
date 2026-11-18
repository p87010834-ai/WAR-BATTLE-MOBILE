using UnityEngine;
using WarBattleMobile.World;

namespace WarBattleMobile.Combat
{
    [RequireComponent(typeof(Rigidbody), typeof(Collider))]
    public sealed class TankProjectile : MonoBehaviour
    {
        [Header("Impact model")]
        [SerializeField, Range(0f, 89f)] private float ricochetAngle = 70f;
        [SerializeField, Min(0f)] private float minimumDamageFraction = 0.15f;
        [SerializeField, Min(0f)] private float penetrationDistanceLossPerMetre = 0.025f;
        [SerializeField, Min(0f)] private float impactImpulse = 8f;
        [Header("Blast")]
        [SerializeField, Min(0f)] private float blastRadius = 5.5f;
        [SerializeField, Min(0f)] private float blastDamage = 85f;
        [SerializeField] private bool blastDamagesVehicles;
        [SerializeField, Min(0f)] private float blastForce = 18f;
        [SerializeField, Range(0.1f, 3f)] private float blastVisualScale = 1f;
        [SerializeField] private AudioClip explosionClip;
        [Header("Audio")]
        [SerializeField] private AudioClip flightLoopClip;
        [SerializeField] private AudioClip impactClip;
        [SerializeField] private AudioClip ricochetClip;
        [SerializeField, Range(0f, 1f)] private float flightVolume = 0.35f;
        [SerializeField, Range(0f, 1f)] private float impactVolume = 0.8f;

        private Rigidbody body;
        private TankHealth owner;
        private float initialPenetration;
        private float damage;
        private float maximumDistance;
        private Vector3 launchPosition;
        private bool launched;
        private bool impacted;
        private AudioSource flightAudio;

        private void Awake()
        {
            body = GetComponent<Rigidbody>();
            body.useGravity = true;
            body.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
            body.interpolation = RigidbodyInterpolation.Interpolate;
            if (flightLoopClip != null)
            {
                flightAudio = gameObject.AddComponent<AudioSource>();
                flightAudio.clip = flightLoopClip;
                flightAudio.loop = true;
                flightAudio.volume = flightVolume;
                flightAudio.spatialBlend = 1f;
                flightAudio.minDistance = 4f;
                flightAudio.maxDistance = 90f;
                flightAudio.dopplerLevel = 0.8f;
                flightAudio.Play();
            }
        }

        public void Launch(Vector3 direction, float speed, float penetrationMm,
            float damageValue, float maxDistance, TankHealth firingTank)
        {
            owner = firingTank;
            initialPenetration = Mathf.Max(0f, penetrationMm);
            damage = Mathf.Max(0f, damageValue);
            maximumDistance = Mathf.Max(1f, maxDistance);
            launchPosition = transform.position;
            launched = true;

            if (owner != null)
            {
                Collider[] ownerColliders = owner.GetComponentsInChildren<Collider>();
                Collider projectileCollider = GetComponent<Collider>();
                foreach (Collider ownerCollider in ownerColliders)
                {
                    if (ownerCollider != null && projectileCollider != null)
                        Physics.IgnoreCollision(projectileCollider, ownerCollider, true);
                }
            }

            body.linearVelocity = direction.normalized * Mathf.Max(1f, speed);
        }

        private void FixedUpdate()
        {
            if (!launched || impacted) return;
            if (Vector3.Distance(launchPosition, transform.position) >= maximumDistance)
                Destroy(gameObject);
        }

        private void OnCollisionEnter(Collision collision)
        {
            if (!launched || impacted) return;

            TankHealth target = collision.collider.GetComponentInParent<TankHealth>();
            if (target != null && target == owner) return;

            impacted = true;
            DestructibleEnvironment destructible = collision.collider.GetComponentInParent<DestructibleEnvironment>();
            Vector3 velocity = body.linearVelocity;
            Vector3 incoming = velocity.sqrMagnitude > 0.01f ? velocity.normalized : transform.forward;
            ContactPoint contact = collision.GetContact(0);
            TankArmorZone armor = collision.collider.GetComponent<TankArmorZone>();
            float armourThickness = armor != null ? armor.ThicknessMillimetres : 80f;
            TankModule module = armor != null ? armor.DamagedModule : ResolveModule(collision.collider);

            // Angle is measured from the armour surface normal: 0 degrees is a square hit.
            float impactAngle = Vector3.Angle(-incoming, contact.normal);
            if (impactAngle >= ricochetAngle)
            {
                PlayImpactSound(ricochetClip);
                Destroy(gameObject);
                return;
            }

            float cosine = Mathf.Max(0.15f, Mathf.Cos(impactAngle * Mathf.Deg2Rad));
            float effectiveThickness = armourThickness / cosine;
            float travelled = Vector3.Distance(launchPosition, transform.position);
            float remainingPenetration = initialPenetration -
                travelled * penetrationDistanceLossPerMetre;

            if (destructible != null)
            {
                float environmentDamage = damage * Mathf.Clamp(remainingPenetration / Mathf.Max(1f, effectiveThickness), 0.2f, 1.5f);
                destructible.ApplyDamage(environmentDamage, contact.point, incoming, impactImpulse);
            }

            if (target != null && remainingPenetration >= effectiveThickness)
            {
                float penetrationRatio = Mathf.Clamp01(
                    (remainingPenetration - effectiveThickness) / Mathf.Max(1f, remainingPenetration));
                float appliedDamage = damage * Mathf.Lerp(
                    minimumDamageFraction, 1f, penetrationRatio);
                target.ApplyDamage(module, appliedDamage);
            }

            if (collision.rigidbody != null && impactImpulse > 0f)
                collision.rigidbody.AddForceAtPosition(incoming * impactImpulse,
                    contact.point, ForceMode.Impulse);

            PlayImpactSound(impactClip);
            if (blastRadius > 0f && blastDamage > 0f)
                TankExplosion.Detonate(contact.point, owner, blastRadius, blastDamage,
                    blastForce, blastVisualScale, explosionClip, blastDamagesVehicles);
            Destroy(gameObject);
        }

        private void PlayImpactSound(AudioClip clip)
        {
            if (clip != null)
                AudioSource.PlayClipAtPoint(clip, transform.position, impactVolume);
        }

        private static TankModule ResolveModule(Collider hitCollider)
        {
            string partName = hitCollider.gameObject.name.ToLowerInvariant();
            if (partName.Contains("engine")) return TankModule.Engine;
            if (partName.Contains("turret")) return TankModule.Turret;
            if (partName.Contains("lefttrack") || partName.Contains("left_track"))
                return TankModule.LeftTrack;
            if (partName.Contains("righttrack") || partName.Contains("right_track"))
                return TankModule.RightTrack;
            return TankModule.Hull;
        }
    }
}