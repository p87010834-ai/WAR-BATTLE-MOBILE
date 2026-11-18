using System;
using UnityEngine;

namespace WarBattleMobile.Combat
{
    public sealed class TankMatchRules : MonoBehaviour
    {
        [SerializeField, Min(60f)] private float matchDurationSeconds = 600f;
        [SerializeField, Min(1)] private int scoreLimit = 1000;
        [SerializeField, Min(0f)] private float pointsPerOwnedPointPerSecond = 1f;
        [SerializeField] private bool startOnSceneLoad = true;

        public event Action<TankTeam, int, int> ScoreChanged;
        public event Action<float> TimeChanged;
        public event Action<TankTeam> MatchEnded;
        public int BlueScore { get; private set; }
        public int RedScore { get; private set; }
        public float TimeRemaining { get; private set; }
        public bool IsRunning { get; private set; }
        public bool IsFinished { get; private set; }
        public TankTeam WinningTeam { get; private set; } = TankTeam.Neutral;

        private CapturePoint[] points;
        private float blueScoreFraction;
        private float redScoreFraction;

        private void Start()
        {
            if (startOnSceneLoad) StartMatch();
        }

        public void StartMatch()
        {
            // Prevent a second caller (for example a scene bootstrapper) from
            // silently resetting scores and the timer during an active round.
            if (IsFinished || IsRunning) return;
            points = FindObjectsByType<CapturePoint>(FindObjectsSortMode.None);
            BlueScore = 0;
            RedScore = 0;
            TimeRemaining = matchDurationSeconds;
            blueScoreFraction = 0f;
            redScoreFraction = 0f;
            IsRunning = true;
            ScoreChanged?.Invoke(TankTeam.Blue, BlueScore, RedScore);
            TimeChanged?.Invoke(TimeRemaining);
        }

        private void Update()
        {
            if (!IsRunning || IsFinished) return;
            TimeRemaining = Mathf.Max(0f, TimeRemaining - Time.deltaTime);
            TimeChanged?.Invoke(TimeRemaining);

            int blueOwned = 0, redOwned = 0;
            foreach (CapturePoint p in points)
            {
                if (p == null) continue;
                if (p.Owner == TankTeam.Blue) blueOwned++;
                else if (p.Owner == TankTeam.Red) redOwned++;
            }

            blueScoreFraction += Time.deltaTime * pointsPerOwnedPointPerSecond * blueOwned;
            redScoreFraction += Time.deltaTime * pointsPerOwnedPointPerSecond * redOwned;
            int blueWhole = Mathf.FloorToInt(blueScoreFraction);
            int redWhole = Mathf.FloorToInt(redScoreFraction);
            if (blueWhole > 0 || redWhole > 0)
            {
                blueScoreFraction -= blueWhole;
                redScoreFraction -= redWhole;
                BlueScore = Mathf.Min(scoreLimit, BlueScore + blueWhole);
                RedScore = Mathf.Min(scoreLimit, RedScore + redWhole);
                if (blueWhole > 0)
                    ScoreChanged?.Invoke(TankTeam.Blue, BlueScore, RedScore);
                if (redWhole > 0)
                    ScoreChanged?.Invoke(TankTeam.Red, BlueScore, RedScore);
            }

            if (BlueScore >= scoreLimit || RedScore >= scoreLimit || TimeRemaining <= 0f)
            {
                TankTeam winner = BlueScore == RedScore ? TankTeam.Neutral :
                    (BlueScore > RedScore ? TankTeam.Blue : TankTeam.Red);
                FinishMatch(winner);
            }
        }

        private void FinishMatch(TankTeam winner)
        {
            if (IsFinished) return;
            IsFinished = true;
            IsRunning = false;
            WinningTeam = winner;
            MatchEnded?.Invoke(winner);
        }
    }
}