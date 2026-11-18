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
        private float scoreFraction;

        private void Start()
        {
            points = FindObjectsByType<CapturePoint>(FindObjectsSortMode.None);
            if (startOnSceneLoad) StartMatch();
        }

        public void StartMatch()
        {
            if (IsFinished) return;
            BlueScore = 0;
            RedScore = 0;
            TimeRemaining = matchDurationSeconds;
            scoreFraction = 0f;
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

            scoreFraction += Time.deltaTime * pointsPerOwnedPointPerSecond;
            int whole = Mathf.FloorToInt(scoreFraction);
            if (whole > 0)
            {
                scoreFraction -= whole;
                BlueScore += whole * blueOwned;
                RedScore += whole * redOwned;
                ScoreChanged?.Invoke(TankTeam.Blue, BlueScore, RedScore);
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