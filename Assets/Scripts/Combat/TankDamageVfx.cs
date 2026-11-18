using UnityEngine;

namespace WarBattleMobile.Combat
{
    /// <summary>
    /// Lightweight runtime placeholder effects driven by tank module condition.
    /// Replace these generated particle systems with authored VFX prefabs for production.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(TankHealth))]
    public sealed class TankDamageVfx : MonoBehaviour
    {
        [Header("Optional emitter anchors")]
        [SerializeField] private Transform engineSmokePoint;
        [SerializeField] private Transform hullSmokePoint;
        [SerializeField] private Transform firePoint;

        [Header("Thresholds")]
        [SerializeField, Range(0.1f, 1f)] private float lightSmokeThreshold = 0.75f;
        [SerializeField, Range(0.05f, 0.9f)] private float heavySmokeThreshold = 0.35f;
        [SerializeField, Range(0.01f, 0.8f)] private float fireThreshold = 0.15f;

        private TankHealth health;
        private ParticleSystem engineSmoke;
        private ParticleSystem hullSmoke;
        private ParticleSystem fire;
        private bool destroyed;

        private void Awake()
        {
            health = GetComponent<TankHealth>();
            engineSmoke = CreateEmitter("Engine Smoke", engineSmokePoint, new Color(0.24f, 0.25f, 0.26f, 0.72f),
                5f, 2.6f, 0.55f, 1.4f, 0.35f);
            hullSmoke = CreateEmitter("Hull Smoke", hullSmokePoint, new Color(0.18f, 0.19f, 0.2f, 0.82f),
                8f, 3.4f, 0.75f, 2.1f, 0.5f);
            fire = CreateEmitter("Damage Fire", firePoint, new Color(1f, 0.34f, 0.06f, 0.95f),
                12f, 0.9f, 0.28f, 0.85f, 0.28f);
        }

        private void OnEnable()
        {
            if (health == null) health = GetComponent<TankHealth>();
            health.ModuleHealthChanged += OnModuleHealthChanged;
            health.ModuleDisabled += OnModuleDisabled;
            health.TankDestroyed += OnTankDestroyed;
        }

        private void Start()
        {
            RefreshAll();
        }

        private void OnDisable()
        {
            if (health == null) return;
            health.ModuleHealthChanged -= OnModuleHealthChanged;
            health.ModuleDisabled -= OnModuleDisabled;
            health.TankDestroyed -= OnTankDestroyed;
        }

        private void OnModuleHealthChanged(TankModule module, float current, float maximum)
        {
            if (destroyed || maximum <= 0f) return;
            if (module == TankModule.Engine || module == TankModule.Hull)
                RefreshAll();
        }

        private void OnModuleDisabled(TankModule module)
        {
            if (destroyed) return;
            if (module == TankModule.Engine)
                SetRate(engineSmoke, 15f);
            if (module == TankModule.Hull)
                OnTankDestroyed();
        }

        private void RefreshAll()
        {
            if (health == null || destroyed) return;

            float engineRatio = Ratio(TankModule.Engine);
            float hullRatio = Ratio(TankModule.Hull);

            SetRate(engineSmoke, engineRatio <= 0f ? 15f :
                engineRatio < lightSmokeThreshold ? Mathf.Lerp(3f, 12f,
                    Mathf.InverseLerp(lightSmokeThreshold, 0f, engineRatio)) : 0f);

            float hullSmokeRate = hullRatio < heavySmokeThreshold
                ? Mathf.Lerp(7f, 20f, Mathf.InverseLerp(heavySmokeThreshold, 0f, hullRatio))
                : hullRatio < lightSmokeThreshold
                    ? Mathf.Lerp(2f, 7f, Mathf.InverseLerp(lightSmokeThreshold, heavySmokeThreshold, hullRatio))
                    : 0f;
            SetRate(hullSmoke, hullSmokeRate);

            float fireRate = hullRatio <= fireThreshold
                ? Mathf.Lerp(5f, 14f, Mathf.InverseLerp(fireThreshold, 0f, hullRatio))
                : 0f;
            SetRate(fire, fireRate);
        }

        private float Ratio(TankModule module)
        {
            float max = health.GetMaxHealth(module);
            return max > 0f ? Mathf.Clamp01(health.GetHealth(module) / max) : 1f;
        }

        private static void SetRate(ParticleSystem system, float rate)
        {
            if (system == null) return;
            var emission = system.emission;
            emission.rateOverTime = Mathf.Max(0f, rate);
            if (rate > 0f)
            {
                if (!system.isPlaying) system.Play();
            }
            else if (system.isPlaying)
            {
                system.Stop(true, ParticleSystemStopBehavior.StopEmitting);
            }
        }

        private void OnTankDestroyed()
        {
            if (destroyed) return;
            destroyed = true;
            DetachAndFade(engineSmoke, 18, 4.5f);
            DetachAndFade(hullSmoke, 30, 5f);
            DetachAndFade(fire, 24, 3.5f);
        }

        private static void DetachAndFade(ParticleSystem system, int burstCount, float lifetime)
        {
            if (system == null) return;
            Transform emitter = system.transform;
            emitter.SetParent(null, true);

            var emission = system.emission;
            emission.enabled = false;
            system.Emit(burstCount);
            system.Stop(true, ParticleSystemStopBehavior.StopEmitting);
            Destroy(emitter.gameObject, lifetime);
        }

        private ParticleSystem CreateEmitter(string emitterName, Transform anchor, Color tint,
            float rate, float lifetime, float size, float speed, float radius)
        {
            var emitterObject = new GameObject(emitterName);
            emitterObject.transform.SetParent(anchor != null ? anchor : transform, false);
            emitterObject.transform.localPosition = Vector3.zero;
            emitterObject.transform.localRotation = Quaternion.identity;

            var system = emitterObject.AddComponent<ParticleSystem>();
            var main = system.main;
            main.loop = true;
            main.playOnAwake = false;
            main.duration = 2f;
            main.startLifetime = lifetime;
            main.startSpeed = speed;
            main.startSize = size;
            main.startColor = tint;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.maxParticles = 180;
            main.stopAction = ParticleSystemStopAction.Destroy;

            var emission = system.emission;
            emission.rateOverTime = rate;

            var shape = system.shape;
            shape.enabled = true;
            shape.shapeType = ParticleSystemShapeType.Sphere;
            shape.radius = radius;

            var velocity = system.velocityOverLifetime;
            velocity.enabled = true;
            velocity.space = ParticleSystemSimulationSpace.World;
            velocity.y = new ParticleSystem.MinMaxCurve(0.7f, 1.8f);
            velocity.x = new ParticleSystem.MinMaxCurve(-0.25f, 0.25f);

            var color = system.colorOverLifetime;
            color.enabled = true;
            var gradient = new Gradient();
            gradient.SetKeys(
                new[]
                {
                    new GradientColorKey(tint, 0f),
                    new GradientColorKey(new Color(tint.r, tint.g, tint.b, 1f), 1f)
                },
                new[]
                {
                    new GradientAlphaKey(tint.a, 0f),
                    new GradientAlphaKey(tint.a * 0.7f, 0.55f),
                    new GradientAlphaKey(0f, 1f)
                });
            color.color = gradient;

            var renderer = emitterObject.GetComponent<ParticleSystemRenderer>();
            renderer.renderMode = ParticleSystemRenderMode.Billboard;
            renderer.minParticleSize = 0.01f;
            renderer.maxParticleSize = 0.35f;

            return system;
        }
    }
}