using UnityEngine;

namespace WarBattleMobile.World
{
    [DisallowMultipleComponent]
    public sealed class DestructibleEnvironment : MonoBehaviour
    {
        [SerializeField, Min(1f)] private float hitPoints = 180f;
        [SerializeField, Range(2, 6)] private int debrisPieces = 4;
        [SerializeField, Min(0f)] private float debrisImpulse = 5f;
        [SerializeField, Min(0.5f)] private float debrisLifetime = 10f;

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
            debrisPieces = Mathf.Clamp(pieces, 2, 6);
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
                cachedCollider != null ? cachedCollider.bounds : new Bounds(transform.position, Vector3.one * 2f);
            Material material = cachedRenderer != null ? cachedRenderer.sharedMaterial : null;
            Vector3 direction = impactDirection.sqrMagnitude > 0.001f ? impactDirection.normalized : Vector3.up;
            if (cachedRenderer != null) cachedRenderer.enabled = false;
            if (cachedCollider != null) cachedCollider.enabled = false;

            for (int i = 0; i < debrisPieces; i++)
            {
                GameObject shard = GameObject.CreatePrimitive(PrimitiveType.Cube);
                shard.name = "Environment Debris";
                shard.transform.position = bounds.center + Random.insideUnitSphere * 0.22f;
                Vector3 size = new Vector3(
                    Mathf.Max(0.25f, bounds.size.x / 3f) * Random.Range(0.45f, 0.9f),
                    Mathf.Max(0.25f, bounds.size.y / 2f) * Random.Range(0.35f, 0.8f),
                    Mathf.Max(0.25f, bounds.size.z / 3f) * Random.Range(0.45f, 0.9f));
                shard.transform.localScale = size;
                Renderer shardRenderer = shard.GetComponent<Renderer>();
                if (material != null) shardRenderer.sharedMaterial = material;
                Rigidbody body = shard.AddComponent<Rigidbody>();
                body.mass = Mathf.Clamp(size.x * size.y * size.z * 0.35f, 0.5f, 18f);
                Vector3 radial = (shard.transform.position - bounds.center).normalized;
                Vector3 force = (direction * incomingImpulse + radial * debrisImpulse) / Mathf.Max(1, debrisPieces);
                body.AddForceAtPosition(force, impactPoint, ForceMode.Impulse);
                body.AddTorque(Random.insideUnitSphere * debrisImpulse, ForceMode.Impulse);
                Destroy(shard, debrisLifetime);
            }
            Destroy(gameObject);
        }
    }
}