using UnityEngine;

namespace WarBattleMobile.Combat
{
    public enum TankTeam
    {
        Neutral,
        Blue,
        Red
    }

    // Place on the tank root so players and AI can identify friend and foe.
    public sealed class TankFaction : MonoBehaviour
    {
        [SerializeField] private TankTeam team = TankTeam.Neutral;
        public TankTeam Team => team;
        public bool IsCombatant => team != TankTeam.Neutral;

        public void SetTeam(TankTeam newTeam)
        {
            team = newTeam;
        }
    }
}