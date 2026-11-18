using UnityEngine;
using WarBattleMobile.Combat;

namespace WarBattleMobile.World
{
    /// <summary>Team-specific spawn transform used by TankSpawnManager.</summary>
    public sealed class TankSpawnPoint : MonoBehaviour
    {
        [SerializeField] private TankTeam team = TankTeam.Neutral;
        public TankTeam Team => team;

        public void Configure(TankTeam value)
        {
            team = value;
        }
    }
}