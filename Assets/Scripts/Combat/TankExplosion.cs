using System.Collections.Generic;
using UnityEngine;
using WarBattleMobile.World;

namespace WarBattleMobile.Combat
{
    /// <summary>
    /// Area impact for tank shells. Uses a capped non-alloc overlap query for mobile performance.
    /// </summary>
    public static class TankExplosion
    {
        private static readonly Collider[] OverlapBuffer = new Collider[64];
        private static readonly HashSet<int> ProcessedTargets = new HashSet<int>();
        private static readonly HashSet<int> ProcessedBodies = new HashSet<int>();

        public static void Detonate(Vector3 position, TankHealth owner, float radius,
            float maximumDamage, float force, float visualScale, AudioClip sound,
            bool damageVehicles = false)
        {
            radius = Mathf.Max(0.1f, radius);
            int count = Physics.OverlapSphereNonAlloc(position, radius, OverlapBuffer,
                Physics.AllLayers, QueryTriggerInteraction.Ignore);
            ProcessedTargets.Clear();
            ProcessedBodies.Clear();

            for (int i = 0; i < count; i++)
            {
                Collider hit = OverlapBuffer[i];
                OverlapBuffer[i] = null;
                if (hit == null) continue;

                TankHealth tank = hit.GetComponentInParent<TankHealth>();
                if (damageVehicles && tank != null && tank != owner && !tank.IsDestroyed)
                {
                    int id = tank.GetInstanceID();
                    if (ProcessedTargets.Add(id))
                    {
                        float distance = Vector3.Distance(position, tank.transform.position);
                        float factor = 1f - Mathf.Clamp01(distance / radius);
                        tank.ApplyDamage(TankModule.Hull, maximumDamage * factor);
                    }
                }

                DestructibleEnvironment destructible =
                    hit.GetComponentInParent<DestructibleEnvironment>();
                if (destructible != null)
                {
                    int id = destructible.GetInstanceID();
                    if (ProcessedTargets.Add(id))
                    {
                        Vector3 closest = hit.ClosestPoint(position);
                        float distance = Vector3.Distance(position, closest);
                        float factor = 1f - Mathf.Clamp01(distance / radius);
                        destructible.ApplyDamage(maximumDamage * factor, closest,
                            (closest - position).normalized, force * factor);
                    }
                }

                Rigidbody rigidbody = hit.attachedRigidbody;
                if (rigidbody != null && !rigidbody.isKinematic &&
                    (owner == null || !rigidbody.transform.IsChildOf(owner.transform)) &&
                    ProcessedBodies.Add(rigidbody.GetInstanceID()))
                    rigidbody.AddExplosionForce(force, position, radius, 0.6f, ForceMode.Impulse);
            }

            SpawnVisual(position, radius, visualScale);
            if (sound != null) AudioSource.PlayClipAtPoint(sound, position, 1f);
        }

        private static void SpawnVisual(Vector3 position, float radius, float scale)
        {
            GameObject effect = new GameObject("Tank Shell Explosion");
            effect.transform.position = position;
            effect.transform.localScale = Vector3.one * Mathf.Max(0.1f, scale);
            ParticleSystem particles = effect.AddComponent<ParticleSystem>();
            var main = particles.main;
            main.duration = 0.55f;
            main.loop = false;
            main.startLifetime = new ParticleSystem.MinMaxCurve(0.2f, 0.65f);
            main.startSpeed = new ParticleSystem.MinMaxCurve(radius * 0.5f, radius * 1.5f);
            main.startSize = new ParticleSystem.MinMaxCurve(0.35f, 1.1f);
            main.startColor = new Color(1f, 0.48f, 0.12f, 0.9f);
            main.maxParticles = 48;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            var emission = particles.emission;
            emission.rateOverTime = 0f;
            emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 32) });
            var shape = particles.shape;
            shape.shapeType = ParticleSystemShapeType.Sphere;
            shape.radius = 0.35f;
            var renderer = particles.GetComponent<ParticleSystemRenderer>();
            renderer.renderMode = ParticleSystemRenderMode.Billboard;
            particles.Play();
            Object.Destroy(effect, 2f);
        }
    }
}