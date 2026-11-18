using UnityEngine;
using WarBattleMobile.Combat;

namespace WarBattleMobile.Vehicle
{
    /// <summary>
    /// Inspector-configured spatial audio for a tank: engine/track loops,
    /// cannon fire, incoming damage, module failure, and destruction.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class TankAudioController : MonoBehaviour
    {
        [Header("Loop clips")]
        [SerializeField] private AudioClip engineLoop;
        [SerializeField] private AudioClip trackLoop;
        [SerializeField, Range(0f, 1f)] private float engineVolume = 0.65f;
        [SerializeField, Range(0f, 1f)] private float trackVolume = 0.45f;

        [Header("One-shot clips")]
        [SerializeField] private AudioClip cannonFire;
        [SerializeField] private AudioClip reloadStart;
        [SerializeField] private AudioClip armourHit;
        [SerializeField] private AudioClip moduleDisabled;
        [SerializeField] private AudioClip vehicleDestroyed;
        [SerializeField, Range(0f, 1f)] private float combatVolume = 0.85f;

        [Header("Engine response")]
        [SerializeField, Min(0.1f)] private float enginePitchAtIdle = 0.8f;
        [SerializeField, Min(0.1f)] private float enginePitchAtSpeed = 1.45f;
        [SerializeField, Min(0.1f)] private float engineResponse = 5f;
        [SerializeField, Min(0.1f)] private float trackVolumeThreshold = 0.08f;

        [Header("References")]
        [SerializeField] private TankMovement movement;
        [SerializeField] private TankWeapon weapon;
        [SerializeField] private TankHealth health;

        private AudioSource engineSource;
        private AudioSource trackSource;
        private float currentEnginePitch;

        private void Awake()
        {
            if (movement == null) movement = GetComponent<TankMovement>();
            if (weapon == null) weapon = GetComponent<TankWeapon>();
            if (health == null) health = GetComponent<TankHealth>();

            engineSource = CreateLoopSource("Engine Audio", engineLoop, engineVolume, 0.8f, 100f);
            trackSource = CreateLoopSource("Track Audio", trackLoop, trackVolume, 0.6f, 65f);
            currentEnginePitch = enginePitchAtIdle;
        }

        private AudioSource CreateLoopSource(string sourceName, AudioClip clip,
            float volume, float minDistance, float maxDistance)
        {
            GameObject sourceObject = new GameObject(sourceName);
            sourceObject.transform.SetParent(transform, false);
            AudioSource source = sourceObject.AddComponent<AudioSource>();
            source.clip = clip;
            source.loop = true;
            source.playOnAwake = false;
            source.spatialBlend = 1f;
            source.rolloffMode = AudioRolloffMode.Logarithmic;
            source.minDistance = minDistance;
            source.maxDistance = maxDistance;
            source.volume = volume;
            if (clip != null) source.Play();
            return source;
        }

        private void OnEnable()
        {
            if (weapon != null) weapon.ShotFired += HandleShotFired;
            if (health != null)
            {
                health.ModuleHealthChanged += HandleModuleHealthChanged;
                health.ModuleDisabled += HandleModuleDisabled;
                health.TankDestroyed += HandleTankDestroyed;
            }
        }

        private void Start()
        {
            // Components on the same prefab are initialized before Start.
            if (weapon != null) weapon.ShotFired -= HandleShotFired;
            if (health != null)
            {
                health.ModuleHealthChanged -= HandleModuleHealthChanged;
                health.ModuleDisabled -= HandleModuleDisabled;
                health.TankDestroyed -= HandleTankDestroyed;
            }
            if (weapon != null) weapon.ShotFired += HandleShotFired;
            if (health != null)
            {
                health.ModuleHealthChanged += HandleModuleHealthChanged;
                health.ModuleDisabled += HandleModuleDisabled;
                health.TankDestroyed += HandleTankDestroyed;
            }
        }

        private void Update()
        {
            if (movement == null) return;
            float speedFactor = Mathf.Clamp01(movement.CurrentSpeed / 8f);
            float throttleFactor = Mathf.Abs(movement.MovementInput.y);
            float desiredPitch = Mathf.Lerp(enginePitchAtIdle, enginePitchAtSpeed,
                Mathf.Max(speedFactor, throttleFactor * 0.65f));
            currentEnginePitch = Mathf.Lerp(currentEnginePitch, desiredPitch,
                1f - Mathf.Exp(-engineResponse * Time.deltaTime));
            if (engineSource != null)
            {
                engineSource.pitch = currentEnginePitch;
                engineSource.volume = engineVolume * (0.75f + speedFactor * 0.25f);
            }

            bool movingTracks = throttleFactor >= trackVolumeThreshold;
            if (trackSource != null)
            {
                if (movingTracks && !trackSource.isPlaying && trackSource.clip != null)
                    trackSource.Play();
                else if (!movingTracks && trackSource.isPlaying)
                    trackSource.Pause();
                trackSource.pitch = Mathf.Lerp(0.85f, 1.25f, speedFactor);
                trackSource.volume = trackVolume * throttleFactor;
            }
        }

        private void HandleShotFired()
        {
            PlayOneShot(cannonFire);
            PlayOneShot(reloadStart);
        }

        private void HandleModuleHealthChanged(TankModule module, float current, float maximum)
        {
            if (maximum > 0f && current < maximum)
                PlayOneShot(armourHit);
        }

        private void HandleModuleDisabled(TankModule module)
        {
            PlayOneShot(moduleDisabled);
        }

        private void HandleTankDestroyed()
        {
            PlayOneShot(vehicleDestroyed);
            if (engineSource != null) engineSource.Stop();
            if (trackSource != null) trackSource.Stop();
        }

        private void PlayOneShot(AudioClip clip)
        {
            if (clip != null)
                AudioSource.PlayClipAtPoint(clip, transform.position, combatVolume);
        }

        private void OnDisable()
        {
            if (weapon != null) weapon.ShotFired -= HandleShotFired;
            if (health != null)
            {
                health.ModuleHealthChanged -= HandleModuleHealthChanged;
                health.ModuleDisabled -= HandleModuleDisabled;
                health.TankDestroyed -= HandleTankDestroyed;
            }
        }
    }
}