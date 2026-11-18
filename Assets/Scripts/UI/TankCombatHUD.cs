using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace WarBattleMobile.UI
{
    /// <summary>
    /// Builds a compact runtime combat HUD. Assign the local player's components
    /// and, optionally, a minimap RenderTexture in the Inspector.
    /// </summary>
    public sealed class TankCombatHUD : MonoBehaviour
    {
        [Header("Local vehicle")]
        [SerializeField] private WarBattleMobile.Combat.TankHealth tankHealth;
        [SerializeField] private WarBattleMobile.Combat.TankWeapon tankWeapon;
        [SerializeField] private WarBattleMobile.Combat.TankFaction tankFaction;
        [SerializeField] private WarBattleMobile.Combat.TankMatchRules matchRules;

        [Header("Minimap")]
        [SerializeField] private RenderTexture minimapTexture;
        [SerializeField, Min(80f)] private float minimapSize = 170f;
        [SerializeField] private bool showMinimap = true;

        [Header("HUD")]
        [SerializeField] private bool showModuleStatus = true;
        [SerializeField] private Color healthyColor = new Color(0.2f, 0.8f, 0.35f);
        [SerializeField] private Color damagedColor = new Color(1f, 0.65f, 0.1f);
        [SerializeField] private Color disabledColor = new Color(0.85f, 0.2f, 0.15f);

        private readonly Dictionary<WarBattleMobile.Combat.TankModule, Image> moduleFills =
            new Dictionary<WarBattleMobile.Combat.TankModule, Image>();
        private readonly Dictionary<WarBattleMobile.Combat.TankModule, Text> moduleLabels =
            new Dictionary<WarBattleMobile.Combat.TankModule, Text>();

        private Text scoreText;
        private Text timerText;
        private Text ammoText;
        private Text hullText;
        private Image hullFill;
        private Image reloadFill;
        private Text reloadText;
        private Font font;

        private static readonly WarBattleMobile.Combat.TankModule[] HudModules =
        {
            WarBattleMobile.Combat.TankModule.Engine,
            WarBattleMobile.Combat.TankModule.Transmission,
            WarBattleMobile.Combat.TankModule.Turret,
            WarBattleMobile.Combat.TankModule.GunBreech,
            WarBattleMobile.Combat.TankModule.Optics,
            WarBattleMobile.Combat.TankModule.AmmunitionRack,
            WarBattleMobile.Combat.TankModule.LeftTrack,
            WarBattleMobile.Combat.TankModule.RightTrack
        };

        private void Awake()
        {
            if (tankHealth == null && tankFaction != null)
                tankHealth = tankFaction.GetComponent<WarBattleMobile.Combat.TankHealth>();
            if (matchRules == null)
                matchRules = FindFirstObjectByType<WarBattleMobile.Combat.TankMatchRules>();

            BuildHud();
            RefreshAll();
        }

        private void OnEnable()
        {
            Subscribe();
        }

        private void Start()
        {
            // Awake may have resolved scene references after OnEnable.
            Subscribe();
            RefreshAll();
        }

        private void OnDisable()
        {
            Unsubscribe();
        }

        private void Update()
        {
            UpdateTimer();
            UpdateReload();
            UpdateHull();
            UpdateModuleBars();
        }

        private void Subscribe()
        {
            if (tankHealth != null)
                tankHealth.ModuleHealthChanged += OnModuleHealthChanged;
            if (tankWeapon != null)
                tankWeapon.AmmunitionChanged += OnAmmunitionChanged;
            if (matchRules != null)
            {
                matchRules.ScoreChanged += OnScoreChanged;
                matchRules.TimeChanged += OnTimeChanged;
            }
        }

        private void Unsubscribe()
        {
            if (tankHealth != null)
                tankHealth.ModuleHealthChanged -= OnModuleHealthChanged;
            if (tankWeapon != null)
                tankWeapon.AmmunitionChanged -= OnAmmunitionChanged;
            if (matchRules != null)
            {
                matchRules.ScoreChanged -= OnScoreChanged;
                matchRules.TimeChanged -= OnTimeChanged;
            }
        }

        private void BuildHud()
        {
            font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            if (font == null)
                font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            GameObject canvasObject = new GameObject("Tank Combat HUD Canvas",
                typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasObject.transform.SetParent(transform, false);
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 50;

            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;

            scoreText = CreateText(canvasObject.transform, "Team Score", 25,
                new Vector2(0.5f, 1f), new Vector2(0.5f, 1f),
                new Vector2(0f, -28f), new Vector2(500f, 48f), TextAnchor.MiddleCenter);
            timerText = CreateText(canvasObject.transform, "Match Timer", 28,
                new Vector2(0.5f, 1f), new Vector2(0.5f, 1f),
                new Vector2(0f, -76f), new Vector2(220f, 48f), TextAnchor.MiddleCenter);

            CreatePanel(canvasObject.transform, "Vehicle Status Panel",
                new Vector2(0f, 0f), new Vector2(0f, 0f),
                new Vector2(24f, 24f), new Vector2(390f, showModuleStatus ? 270f : 100f));

            hullText = CreateText(canvasObject.transform, "Hull Health", 22,
                new Vector2(0f, 0f), new Vector2(0f, 0f),
                new Vector2(210f, 245f), new Vector2(350f, 34f), TextAnchor.MiddleLeft);
            hullFill = CreateBar(canvasObject.transform, "Hull Health Bar",
                new Vector2(0f, 0f), new Vector2(0f, 0f),
                new Vector2(210f, 220f), new Vector2(350f, 14f));

            if (showModuleStatus)
            {
                for (int i = 0; i < HudModules.Length; i++)
                {
                    var module = HudModules[i];
                    float y = 190f - i * 22f;
                    string label = module.ToString();
                    Text text = CreateText(canvasObject.transform, label, 15,
                        new Vector2(0f, 0f), new Vector2(0f, 0f),
                        new Vector2(92f, y), new Vector2(145f, 22f), TextAnchor.MiddleLeft);
                    Image fill = CreateBar(canvasObject.transform, label + " Bar",
                        new Vector2(0f, 0f), new Vector2(0f, 0f),
                        new Vector2(285f, y), new Vector2(185f, 10f));
                    moduleLabels[module] = text;
                    moduleFills[module] = fill;
                }
            }

            ammoText = CreateText(canvasObject.transform, "Ammunition", 24,
                new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-210f, 55f), new Vector2(360f, 48f), TextAnchor.MiddleRight);
            reloadText = CreateText(canvasObject.transform, "Reload Status", 17,
                new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-210f, 25f), new Vector2(360f, 26f), TextAnchor.MiddleRight);
            reloadFill = CreateBar(canvasObject.transform, "Reload Bar",
                new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-210f, 8f), new Vector2(300f, 9f));

            if (showMinimap)
            {
                GameObject mapPanel = CreatePanel(canvasObject.transform, "Minimap Panel",
                    new Vector2(1f, 1f), new Vector2(1f, 1f),
                    new Vector2(-24f, -24f), new Vector2(minimapSize, minimapSize));
                if (minimapTexture != null)
                {
                    GameObject rawObject = new GameObject("Minimap Image", typeof(RawImage));
                    rawObject.transform.SetParent(mapPanel.transform, false);
                    RectTransform rt = rawObject.GetComponent<RectTransform>();
                    rt.anchorMin = Vector2.zero;
                    rt.anchorMax = Vector2.one;
                    rt.offsetMin = new Vector2(4f, 4f);
                    rt.offsetMax = new Vector2(-4f, -4f);
                    rawObject.GetComponent<RawImage>().texture = minimapTexture;
                }
                else
                {
                    Text mapPlaceholder = CreateText(mapPanel.transform, "Minimap Setup", 15,
                        Vector2.zero, Vector2.one, Vector2.zero,
                        new Vector2(-12f, -12f), TextAnchor.MiddleCenter);
                    mapPlaceholder.text = "MINIMAP\nAssign a camera RenderTexture";
                }
            }
        }

        private GameObject CreatePanel(Transform parent, string objectName,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 anchoredPosition, Vector2 size)
        {
            GameObject panel = new GameObject(objectName, typeof(Image));
            panel.transform.SetParent(parent, false);
            RectTransform rt = panel.GetComponent<RectTransform>();
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.pivot = new Vector2(anchorMin.x, anchorMin.y);
            rt.anchoredPosition = anchoredPosition;
            rt.sizeDelta = size;
            panel.GetComponent<Image>().color = new Color(0.025f, 0.04f, 0.055f, 0.72f);
            return panel;
        }

        private Text CreateText(Transform parent, string objectName, int size,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 position, Vector2 dimensions,
            TextAnchor alignment)
        {
            GameObject go = new GameObject(objectName, typeof(Text));
            go.transform.SetParent(parent, false);
            RectTransform rt = go.GetComponent<RectTransform>();
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.pivot = new Vector2(anchorMin.x, anchorMin.y);
            rt.anchoredPosition = position;
            rt.sizeDelta = dimensions;
            Text text = go.GetComponent<Text>();
            text.font = font;
            text.fontSize = size;
            text.color = Color.white;
            text.alignment = alignment;
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.raycastTarget = false;
            return text;
        }

        private Image CreateBar(Transform parent, string objectName,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 position, Vector2 dimensions)
        {
            GameObject background = new GameObject(objectName + " Background", typeof(Image));
            background.transform.SetParent(parent, false);
            RectTransform bg = background.GetComponent<RectTransform>();
            bg.anchorMin = anchorMin;
            bg.anchorMax = anchorMax;
            bg.pivot = new Vector2(anchorMin.x, anchorMin.y);
            bg.anchoredPosition = position;
            bg.sizeDelta = dimensions;
            background.GetComponent<Image>().color = new Color(0.08f, 0.1f, 0.12f, 0.95f);

            GameObject fillObject = new GameObject(objectName + " Fill", typeof(Image));
            fillObject.transform.SetParent(background.transform, false);
            RectTransform fillRect = fillObject.GetComponent<RectTransform>();
            fillRect.anchorMin = Vector2.zero;
            fillRect.anchorMax = Vector2.one;
            fillRect.offsetMin = Vector2.zero;
            fillRect.offsetMax = Vector2.zero;
            Image fill = fillObject.GetComponent<Image>();
            fill.color = healthyColor;
            fill.type = Image.Type.Filled;
            fill.fillMethod = Image.FillMethod.Horizontal;
            fill.fillOrigin = (int)Image.OriginHorizontal.Left;
            fill.fillAmount = 1f;
            return fill;
        }

        private void RefreshAll()
        {
            UpdateHull();
            UpdateModuleBars();
            UpdateAmmo();
            UpdateTimer();
            UpdateReload();
            UpdateScore();
        }

        private void UpdateHull()
        {
            if (tankHealth == null || hullFill == null) return;
            float max = tankHealth.GetMaxHealth(WarBattleMobile.Combat.TankModule.Hull);
            float current = tankHealth.GetHealth(WarBattleMobile.Combat.TankModule.Hull);
            float ratio = max > 0f ? current / max : 0f;
            hullFill.fillAmount = ratio;
            hullFill.color = GetHealthColor(ratio);
            hullText.text = tankHealth.IsDestroyed ? "TANK DESTROYED" :
                $"HULL  {Mathf.CeilToInt(current)} / {Mathf.CeilToInt(max)}";
        }

        private void UpdateModuleBars()
        {
            if (tankHealth == null || !showModuleStatus) return;
            foreach (var module in HudModules)
            {
                if (!moduleFills.TryGetValue(module, out Image fill)) continue;
                float max = tankHealth.GetMaxHealth(module);
                float current = tankHealth.GetHealth(module);
                float ratio = max > 0f ? current / max : 0f;
                fill.fillAmount = ratio;
                fill.color = GetHealthColor(ratio);
                if (moduleLabels.TryGetValue(module, out Text label))
                    label.text = ratio <= 0f ? module + "  OFFLINE" : module.ToString();
            }
        }

        private Color GetHealthColor(float ratio)
        {
            if (ratio <= 0f) return disabledColor;
            if (ratio < 0.4f) return damagedColor;
            return healthyColor;
        }

        private void UpdateAmmo()
        {
            if (tankWeapon == null || ammoText == null) return;
            ammoText.text = $"AMMO  {tankWeapon.Ammunition}";
        }

        private void UpdateReload()
        {
            if (tankWeapon == null || reloadFill == null) return;
            reloadFill.fillAmount = tankWeapon.ReloadProgress01;
            reloadText.text = tankWeapon.IsReloading ? "RELOADING..." : "GUN READY";
        }

        private void UpdateTimer()
        {
            if (matchRules == null || timerText == null) return;
            int seconds = Mathf.CeilToInt(matchRules.TimeRemaining);
            timerText.text = $"{seconds / 60:00}:{seconds % 60:00}";
        }

        private void UpdateScore()
        {
            if (matchRules == null || scoreText == null) return;
            scoreText.text = $"BLUE  {matchRules.BlueScore}     |     RED  {matchRules.RedScore}";
        }

        private void OnModuleHealthChanged(WarBattleMobile.Combat.TankModule module,
            float current, float maximum)
        {
            if (module == WarBattleMobile.Combat.TankModule.Hull) UpdateHull();
            else UpdateModuleBars();
        }

        private void OnAmmunitionChanged(int amount, float reloadSeconds)
        {
            UpdateAmmo();
            UpdateReload();
        }

        private void OnScoreChanged(WarBattleMobile.Combat.TankTeam changedTeam,
            int blue, int red) => UpdateScore();

        private void OnTimeChanged(float seconds) => UpdateTimer();
    }
}