using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace WarBattleMobile.UI
{
    /// <summary>
    /// Runtime touch controls: left movement joystick, right drag-to-aim surface,
    /// and a fire button. Attach this component to the local player's tank root.
    /// </summary>
    public sealed class MobileTankControls : MonoBehaviour
    {
        [Header("Player references")]
        [SerializeField] private WarBattleMobile.Vehicle.TankMovement movement;
        [SerializeField] private WarBattleMobile.Vehicle.TankTurretAim turretAim;
        [SerializeField] private WarBattleMobile.Combat.TankWeapon weapon;

        [Header("Display")]
        [SerializeField] private bool createControls = true;
        [SerializeField, Range(0.1f, 0.45f)] private float joystickRadiusNormalized = 0.16f;
        [SerializeField, Range(0.1f, 0.5f)] private float fireButtonSizeNormalized = 0.17f;

        private RectTransform joystickBase;
        private RectTransform joystickHandle;
        private int joystickPointerId = int.MinValue;
        private int aimPointerId = int.MinValue;

        private void Awake()
        {
            if (movement == null) movement = GetComponent<WarBattleMobile.Vehicle.TankMovement>();
            if (turretAim == null) turretAim = GetComponent<WarBattleMobile.Vehicle.TankTurretAim>();
            if (weapon == null) weapon = GetComponent<WarBattleMobile.Combat.TankWeapon>();
            if (createControls) BuildControls();
        }

        private void OnDisable()
        {
            if (movement != null) movement.SetMoveInput(Vector2.zero);
            joystickPointerId = int.MinValue;
            aimPointerId = int.MinValue;
            if (joystickHandle != null) joystickHandle.anchoredPosition = Vector2.zero;
        }

        private void BuildControls()
        {
            EnsureEventSystem();

            GameObject canvasObject = new GameObject("Mobile Tank Controls Canvas",
                typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasObject.transform.SetParent(transform, false);
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 60;

            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;

            Image aimImage = CreateImage(canvasObject.transform, "Aim Touch Area",
                new Vector2(0.48f, 0f), new Vector2(1f, 0.72f),
                Vector2.zero, Vector2.zero, new Color(1f, 1f, 1f, 0.015f));
            aimImage.raycastTarget = true;
            aimImage.gameObject.AddComponent<MobileControlSurface>()
                .Initialize(this, MobileControlSurface.SurfaceType.Aim);

            float radius = Screen.width * joystickRadiusNormalized;
            Image baseImage = CreateImage(canvasObject.transform, "Movement Joystick",
                Vector2.zero, Vector2.zero, new Vector2(55f + radius, 55f + radius),
                new Vector2(radius * 2f, radius * 2f), new Color(0.08f, 0.12f, 0.16f, 0.55f));
            joystickBase = baseImage.rectTransform;
            baseImage.gameObject.AddComponent<MobileControlSurface>()
                .Initialize(this, MobileControlSurface.SurfaceType.Joystick);

            Image handleImage = CreateImage(baseImage.transform, "Joystick Handle",
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                Vector2.zero, new Vector2(radius * 0.72f, radius * 0.72f),
                new Color(0.65f, 0.75f, 0.82f, 0.72f));
            handleImage.raycastTarget = false;
            joystickHandle = handleImage.rectTransform;

            float fireSize = Screen.width * fireButtonSizeNormalized;
            Image fireImage = CreateImage(canvasObject.transform, "FIRE Button",
                new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-fireSize * 0.85f, fireSize * 0.85f),
                new Vector2(fireSize, fireSize), new Color(0.65f, 0.12f, 0.08f, 0.82f));
            fireImage.gameObject.AddComponent<MobileControlSurface>()
                .Initialize(this, MobileControlSurface.SurfaceType.Fire);

            Text fireLabel = CreateText(fireImage.transform, "FIRE Label", "FIRE", 26);
            RectTransform labelRect = fireLabel.rectTransform;
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;
        }

        private void EnsureEventSystem()
        {
            if (EventSystem.current != null) return;
            GameObject eventSystem = new GameObject("EventSystem",
                typeof(EventSystem), typeof(StandaloneInputModule));
            eventSystem.transform.SetParent(transform, false);
        }

        private Image CreateImage(Transform parent, string objectName,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 position, Vector2 size, Color color)
        {
            GameObject go = new GameObject(objectName, typeof(Image));
            go.transform.SetParent(parent, false);
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = new Vector2(anchorMin.x, anchorMin.y);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
            Image image = go.GetComponent<Image>();
            image.color = color;
            return image;
        }

        private Text CreateText(Transform parent, string objectName, string value, int size)
        {
            GameObject go = new GameObject(objectName, typeof(Text));
            go.transform.SetParent(parent, false);
            Text text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            if (text.font == null)
                text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.text = value;
            text.fontSize = size;
            text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = Color.white;
            text.raycastTarget = false;
            return text;
        }

        internal void SurfacePointerDown(MobileControlSurface.SurfaceType type,
            PointerEventData eventData)
        {
            if (type == MobileControlSurface.SurfaceType.Joystick)
            {
                if (joystickPointerId != int.MinValue) return;
                joystickPointerId = eventData.pointerId;
                UpdateJoystick(eventData.position, eventData.pressEventCamera);
            }
            else if (type == MobileControlSurface.SurfaceType.Aim)
            {
                if (aimPointerId != int.MinValue) return;
                aimPointerId = eventData.pointerId;
                UpdateAim(eventData.position);
            }
            else if (type == MobileControlSurface.SurfaceType.Fire && weapon != null)
            {
                weapon.Fire();
            }
        }

        internal void SurfaceDrag(MobileControlSurface.SurfaceType type, PointerEventData eventData)
        {
            if (type == MobileControlSurface.SurfaceType.Joystick &&
                eventData.pointerId == joystickPointerId)
                UpdateJoystick(eventData.position, eventData.pressEventCamera);
            else if (type == MobileControlSurface.SurfaceType.Aim &&
                eventData.pointerId == aimPointerId)
                UpdateAim(eventData.position);
        }

        internal void SurfacePointerUp(MobileControlSurface.SurfaceType type, PointerEventData eventData)
        {
            if (type == MobileControlSurface.SurfaceType.Joystick &&
                eventData.pointerId == joystickPointerId)
            {
                joystickPointerId = int.MinValue;
                if (movement != null) movement.SetMoveInput(Vector2.zero);
                if (joystickHandle != null) joystickHandle.anchoredPosition = Vector2.zero;
            }
            else if (type == MobileControlSurface.SurfaceType.Aim &&
                eventData.pointerId == aimPointerId)
            {
                aimPointerId = int.MinValue;
            }
        }

        private void UpdateJoystick(Vector2 screenPosition, Camera eventCamera)
        {
            if (joystickBase == null) return;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(
                joystickBase, screenPosition, eventCamera, out Vector2 localPoint);
            float radius = joystickBase.rect.width * 0.5f;
            Vector2 offset = localPoint - joystickBase.rect.center;
            if (offset.magnitude > radius) offset = offset.normalized * radius;
            if (joystickHandle != null) joystickHandle.anchoredPosition = offset;
            if (movement != null)
                movement.SetMoveInput(radius > 0f ? offset / radius : Vector2.zero);
        }

        private void UpdateAim(Vector2 screenPosition)
        {
            if (turretAim != null) turretAim.SetAimScreenPosition(screenPosition);
            if (weapon != null) weapon.SetAimScreenPosition(screenPosition);
        }
    }

    public sealed class MobileControlSurface : MonoBehaviour,
        IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        public enum SurfaceType { Joystick, Aim, Fire }
        private MobileTankControls owner;
        private SurfaceType surfaceType;

        public void Initialize(MobileTankControls controls, SurfaceType type)
        {
            owner = controls;
            surfaceType = type;
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (owner != null) owner.SurfacePointerDown(surfaceType, eventData);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (owner != null) owner.SurfaceDrag(surfaceType, eventData);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (owner != null) owner.SurfacePointerUp(surfaceType, eventData);
        }
    }
}