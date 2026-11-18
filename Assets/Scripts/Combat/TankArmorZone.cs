using UnityEngine;

namespace WarBattleMobile.Combat
{
    // Attach to an individual armour hitbox collider.
    public sealed class TankArmorZone : MonoBehaviour
    {
        [SerializeField, Min(1f)] private float thicknessMillimetres = 100f;
        [SerializeField] private TankModule damagedModule = TankModule.Hull;

        public float ThicknessMillimetres => thicknessMillimetres;
        public TankModule DamagedModule => damagedModule;
    }
}