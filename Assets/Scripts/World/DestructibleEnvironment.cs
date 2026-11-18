using UnityEngine;

namespace WarBattleMobile.World
{
    [DisallowMultipleComponent]
    public sealed class DestructibleEnvironment : MonoBehaviour
    {
        [Header("Durability")]
        [SerializeField, Min(1f)] private float hitPoints = 180f;
        [Header("Debris")]
        [SerializeField, Range(2, 10)] private int debrisPieces = 5;
        [SerializeField, Min(0f)] private float debrisImpulse = 5f;
        [SerializeField, Min(0.5f)] private float debrisLifetime = 10f;
        [SerializeField, Min(0f)] private float upwardBias = 0.35f;
        [Header("Dust")]
        [SerializeField, Range(0, 100)] private int dustParticleCount = 28;
        [SerializeField, Min(0.5f)] private float dustLifetime = 2.8f;

        private float currentHitPoints;
        private bool destroyed;
        private Renderer cachedRenderer;
        private Collider cachedCollider;

        private void Awake()
        {
            currentHitPoints = hitPoints;
            cachedRenderer = GetComponent<Renderer>();
            cachedCollider = GetComponent<Collider>();
        }

        public void Configure(float health, int pieces, float impulse)
        {
            hitPoints = Mathf.Max(1f, health);
            debrisPieces = Mathf.Clamp(pieces, 2, 10);
            debrisImpulse = Mathf.Max(0f, impulse);
            currentHitPoints = hitPoints;
        }

        public void ApplyDamage(float amount, Vector3 impactPoint, Vector3 impactDirection, float impulse)
        {
            if (destroyed || amount <= 0f) return;
            currentHitPoints = Mathf.Max(0f, currentHitPoints - amount);
            if (currentHitPoints <= 0f) BreakApart(impactPoint, impactDirection, impulse);
        }

        private void BreakApart(Vector3 impactPoint, Vector3 impactDirection, float incomingImpulse)
        {
            if (destroyed) return;
            destroyed = true;

            Bounds bounds = cachedRenderer != null ? cachedRenderer.bounds :
                cachedCollider != null ? cachedCollider.bounds :
                new Bounds(transform.position, Vector3.one * 2f);
            Material material = cachedRenderer != null ? cachedRenderer.sharedMaterial : null;
            Vector3 direction = impactDirection.sqrMagnitude > 0.001f
                ? impactDirection.normalized : Vector3.up;

            if (cachedRenderer != null) cachedRenderer.enabled = false;
            if (cachedCollider != null) cachedCollider.enabled = false;

            SpawnDust(bounds, impactPoint);

            for (int i = 0; i < debrisPieces; i++)
                SpawnDebris(bounds, material, impactPoint, direction, incomingImpulse, i);

            Destroy(gameObject);
        }

        private void SpawnDebris(Bounds bounds, Material material, Vector3 impactPoint,
            Vector3 impactDirection, float incomingImpulse, int index)
        {
            GameObject shard = GameObject.CreatePrimitive(PrimitiveType.Cube);
            shard.name = "Environment Debris";
            Vector3 half = bounds.extents;
            Vector3 offset = new Vector3(
                Random.Range(-half.x * 0.7f, half.x * 0.7f),
                Random.Range(-half.y * 0.35f, half.y * 0.35f),
                Random.Range(-half.z * 0.7f, half.z * 0.7f));
            shard.transform.position = bounds.center + offset;

            float baseScale = Mathf.Clamp(bounds.extents.magnitude / 3.5f, 0.25f, 2.2f);
            Vector3 size = new Vector3(
                baseScale * Random.Range(0.45f, 1.15f),
                baseScale * Random.Range(0.35f, 0.95f),
                baseScale * Random.Range(0.45f, 1.15f));
            shard.transform.localScale = size;
            shard.transform.rotation = Random.rotationUniform;

            Renderer shardRenderer = shard.GetComponent<Renderer>();
            if (material != null) shardRenderer.sharedMaterial = material;

            Rigidbody body = shard.AddComponent<Rigidbody>();
            body.mass = Mathf.Clamp(size.x * size.y * size.z * 0.45f, 0.35f, 22f);
            body.interpolation = RigidbodyInterpolation.Interpolate;
            body.collisionDetectionMode = CollisionDetectionMode.Continuous;
            Vector3 radial = (shard.transform.position - bounds.center).normalized;
            Vector3 force = (impactDirection * incomingImpulse + radial * debrisImpulse) /
                Mathf.Max(1, debrisPieces);
            force += Vector3.up * (upwardBias * debrisImpulse / Mathf.Max(1, debrisPieces));
            body.AddForceAtPosition(force, impactPoint, ForceMode.Impulse);
            body.AddTorque(Random.insideUnitSphere * debrisImpulse, ForceMode.Impulse);

            Destroy(shard, debrisLifetime);
        }

        private void SpawnDust(Bounds bounds, Vector3 impactPoint)
        {
            if (dustParticleCount <= 0) return;

            GameObject dustObject = new GameObject("Environment Destruction Dust");
            dustObject.transform.position = impactPoint.sqrMagnitude > 0.001f
                ? impactPoint : bounds.center;

            ParticleSystem particles = dustObject.AddComponent<ParticleSystem>();
            var main = particles.main;
            main.duration = 0.4f;
            main.loop = false;
            main.startLifetime = new ParticleSystem.MinMaxCurve(dustLifetime * 0.55f, dustLifetime);
            main.startSpeed = new ParticleSystem.MinMaxCurve(1.2f, 4.5f);
            main.startSize = new ParticleSystem.MinMaxCurve(0.35f, 1.25f);
            main.startColor = new Color(0.42f, 0.4f, 0.36f, 0.55f);
            main.maxParticles = 100;
            main.simulationSpace = ParticleSystemSimulationSpace.World;

            var emission = particles.emission;
            emission.rateOverTime = 0f;
            emission.SetBursts(new[] { new ParticleSystem.Burst(0f, (short)dustParticleCount) });

            var shape = particles.shape;
            shape.shapeType = ParticleSystemShapeType.Sphere;
            shape.radius = Mathf.Clamp(bounds.extents.magnitude * 0.18f, 0.4f, 2.5f);

            var velocity = particles.velocityOverLifetime;
            velocity.enabled = true;
            velocity.y = new ParticleSystem.MinMaxCurve(0.4f, 1.8f);

            var color = particles.colorOverLifetime;
            color.enabled = true;
            var gradient = new Gradient();
            gradient.SetKeys(
                new[]
                {
                    new GradientColorKey(new Color(0.48f, 0.46f, 0.42f), 0f),
                    new GradientColorKey(new Color(0.3f, 0.29f, 0.27f), 1f)
                },
                new[]
                {
                    new GradientAlphaKey(0.55f, 0f),
                    new GradientAlphaKey(0.3f, 0.65f),
                    new GradientAlphaKey(0f, 1f)
                });
            color.color = gradient;

            particles.Play();
            Destroy(dustObject, dustLifetime + 0.75f);
        }
    }
}