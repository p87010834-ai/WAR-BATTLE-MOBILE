using UnityEngine;
using WarBattleMobile.Combat;

namespace WarBattleMobile.World
{
    /// <summary>
    /// Builds a playable greybox urban battlefield from primitive meshes.
    /// This is a layout/prototyping tool; replace primitive visuals with authored
    /// modular art before production.
    /// </summary>
    public sealed class UrbanBattlefieldGenerator : MonoBehaviour
    {
        [Header("Generation")]
        [SerializeField] private bool generateOnStart = true;
        [SerializeField] private int randomSeed = 1847;
        [SerializeField, Min(2)] private int blocksPerSide = 3;
        [SerializeField, Min(35f)] private float blockSize = 42f;
        [SerializeField, Min(8f)] private float roadWidth = 14f;
        [SerializeField, Min(0.5f)] private float groundThickness = 1f;

        [Header("Buildings")]
        [SerializeField, Range(0f, 1f)] private float buildingDensity = 0.72f;
        [SerializeField, Min(5f)] private float minBuildingHeight = 7f;
        [SerializeField, Min(5f)] private float maxBuildingHeight = 22f;
        [SerializeField, Range(0f, 1f)] private float ruinChance = 0.28f;
        [SerializeField, Range(1, 5)] private int facadeWindowRows = 3;
        [SerializeField, Range(2, 5)] private int facadeWindowsPerRow = 3;
        [SerializeField] private bool addRoadMarkings = true;

        [Header("Objectives")]
        [SerializeField] private int capturePointCount = 3;
        [SerializeField, Min(1f)] private float captureRadius = 11f;

        [Header("Environment")]
        [SerializeField] private bool addBoundaryWalls = true;
        [SerializeField] private bool addStreetCover = true;

        private Transform generatedRoot;
        private Material groundMaterial;
        private Material roadMaterial;
        private Material buildingMaterial;
        private Material ruinMaterial;
        private Material coverMaterial;
        private Material objectiveMaterial;
        private Material glassMaterial;
        private Material trimMaterial;
        private Material roadMarkingMaterial;
        private Material rooftopMaterial;

        private float MapSize => blocksPerSide * blockSize + (blocksPerSide + 1) * roadWidth;

        private void Awake()
        {
            // Generate before other scene components run Start(), so match and spawn
            // managers can discover objectives and spawn points deterministically.
            if (generateOnStart) Generate();
        }

        [ContextMenu("Generate Urban Battlefield")]
        public void Generate()
        {
            RemovePrevious();
            Random.InitState(randomSeed);
            CreateMaterials();

            GameObject root = new GameObject("Generated Urban Battlefield");
            root.transform.SetParent(transform, false);
            generatedRoot = root.transform;

            float size = MapSize;
            CreateCube("Ground", new Vector3(0f, -groundThickness * 0.5f, 0f),
                new Vector3(size + roadWidth * 2f, groundThickness, size + roadWidth * 2f),
                groundMaterial, true);

            BuildRoadGrid(size);
            if (addRoadMarkings) BuildRoadMarkings(size);
            BuildCityBlocks();
            if (addStreetCover) BuildStreetCover();
            if (addBoundaryWalls) BuildBoundary(size);
            BuildObjectives();
            BuildSpawnMarkers(size);
        }

        private void RemovePrevious()
        {
            Transform old = transform.Find("Generated Urban Battlefield");
            if (old != null)
            {
                if (Application.isPlaying) Destroy(old.gameObject);
                else DestroyImmediate(old.gameObject);
            }
            generatedRoot = null;
        }

        private void CreateMaterials()
        {
            groundMaterial = MakeMaterial(new Color(0.24f, 0.25f, 0.23f));
            roadMaterial = MakeMaterial(new Color(0.12f, 0.13f, 0.14f));
            buildingMaterial = MakeMaterial(new Color(0.38f, 0.37f, 0.34f));
            ruinMaterial = MakeMaterial(new Color(0.29f, 0.28f, 0.26f));
            coverMaterial = MakeMaterial(new Color(0.21f, 0.23f, 0.22f));
            objectiveMaterial = MakeMaterial(new Color(0.12f, 0.55f, 0.95f, 0.55f));
            glassMaterial = MakeMaterial(new Color(0.12f, 0.19f, 0.22f));
            trimMaterial = MakeMaterial(new Color(0.19f, 0.2f, 0.2f));
            roadMarkingMaterial = MakeMaterial(new Color(0.72f, 0.68f, 0.54f));
            rooftopMaterial = MakeMaterial(new Color(0.25f, 0.25f, 0.23f));
        }

        private Material MakeMaterial(Color color)
        {
            Shader shader = Shader.Find("Universal Render Pipeline/Lit");
            if (shader == null) shader = Shader.Find("Standard");
            Material material = new Material(shader);
            material.color = color;
            return material;
        }

        private void BuildRoadGrid(float size)
        {
            float half = size * 0.5f;
            CreateCube("Main East-West Road", new Vector3(0f, 0.015f, 0f),
                new Vector3(size + roadWidth, 0.08f, roadWidth), roadMaterial, false);
            CreateCube("Main North-South Road", new Vector3(0f, 0.02f, 0f),
                new Vector3(roadWidth, 0.08f, size + roadWidth), roadMaterial, false);

            for (int i = 0; i <= blocksPerSide; i++)
            {
                float coordinate = -half + roadWidth * 0.5f + i * (blockSize + roadWidth);
                CreateCube("Horizontal Street " + i, new Vector3(0f, 0.025f, coordinate),
                    new Vector3(size + roadWidth, 0.07f, roadWidth), roadMaterial, false);
                CreateCube("Vertical Street " + i, new Vector3(coordinate, 0.03f, 0f),
                    new Vector3(roadWidth, 0.07f, size + roadWidth), roadMaterial, false);
            }
        }

        private void BuildCityBlocks()
        {
            float start = -MapSize * 0.5f + roadWidth + blockSize * 0.5f;
            for (int x = 0; x < blocksPerSide; x++)
            for (int z = 0; z < blocksPerSide; z++)
            {
                Vector3 center = new Vector3(start + x * (blockSize + roadWidth), 0f,
                    start + z * (blockSize + roadWidth));
                BuildSingleBlock(center, x, z);
            }
        }

        private void BuildSingleBlock(Vector3 center, int blockX, int blockZ)
        {
            int buildings = Random.Range(2, 5);
            for (int i = 0; i < buildings; i++)
            {
                if (Random.value > buildingDensity) continue;
                float width = Random.Range(9f, 16f);
                float depth = Random.Range(9f, 17f);
                float height = Random.Range(minBuildingHeight, maxBuildingHeight);
                Vector2 offset = Random.insideUnitCircle * (blockSize * 0.24f);
                Vector3 position = center + new Vector3(offset.x, height * 0.5f, offset.y);
                bool ruined = Random.value < ruinChance;
                Material material = ruined ? ruinMaterial : buildingMaterial;

                GameObject building = CreateCube(
                    $"Building_{blockX}_{blockZ}_{i}" + (ruined ? "_Ruin" : ""),
                    position, new Vector3(width, height, depth), material, true);

                DestructibleEnvironment destructible = building.AddComponent<DestructibleEnvironment>();
                destructible.Configure(ruined ? 110f : 260f, ruined ? 3 : 5, ruined ? 3.5f : 6f);

                if (ruined)
                {
                    // Broken roofline and rubble are visual blockout details only.
                    float missingCorner = width * 0.28f;
                    CreateCube("Collapsed Roof Section",
                        position + new Vector3(width * 0.28f, height * 0.42f, 0f),
                        new Vector3(missingCorner, height * 0.16f, depth * 0.9f),
                        coverMaterial, true);
                    CreateRubble(position, width, depth);
                }
                else
                {
                    AddFacadeBands(position, width, height, depth);
                    AddBuildingWindows(position, width, height, depth);
                    AddRooftopEquipment(position, width, height, depth);
                }
            }
        }

        private void AddFacadeBands(Vector3 center, float width, float height, float depth)
        {
            float bandY = Mathf.Max(2f, height * 0.35f);
            CreateCube("Facade ledge", center + new Vector3(0f, bandY, depth * 0.505f),
                new Vector3(width * 0.92f, 0.35f, 0.45f), ruinMaterial, false);
            CreateCube("Facade ledge", center + new Vector3(0f, bandY, -depth * 0.505f),
                new Vector3(width * 0.92f, 0.35f, 0.45f), ruinMaterial, false);
        }

        private void AddBuildingWindows(Vector3 center, float width, float height, float depth)
        {
            int rows = Mathf.Clamp(facadeWindowRows, 1, 5);
            int columns = Mathf.Clamp(facadeWindowsPerRow, 2, 5);
            float floorSpacing = height / (rows + 1f);
            float windowWidth = Mathf.Min(1.35f, width / (columns * 2.4f));
            float windowHeight = Mathf.Min(1.55f, floorSpacing * 0.48f);

            for (int row = 0; row < rows; row++)
            {
                float y = center.y - height * 0.5f + floorSpacing * (row + 1);
                for (int column = 0; column < columns; column++)
                {
                    float x = center.x - width * 0.5f + width * (column + 1f) / (columns + 1f);
                    CreateWindow(x, y, center.z + depth * 0.505f, windowWidth, windowHeight, false);
                    CreateWindow(x, y, center.z - depth * 0.505f, windowWidth, windowHeight, false);
                }

                int sideColumns = Mathf.Max(2, columns - 1);
                for (int column = 0; column < sideColumns; column++)
                {
                    float z = center.z - depth * 0.5f + depth * (column + 1f) / (sideColumns + 1f);
                    CreateWindow(center.x + width * 0.505f, y, z, windowWidth, windowHeight, true);
                    CreateWindow(center.x - width * 0.505f, y, z, windowWidth, windowHeight, true);
                }
            }
        }

        private void CreateWindow(float x, float y, float z, float width, float height, bool sideWall)
        {
            Vector3 size = sideWall
                ? new Vector3(0.045f, height, width)
                : new Vector3(width, height, 0.045f);
            CreateCube("Dark Window", new Vector3(x, y, z), size, glassMaterial, false);

            float frame = 0.09f;
            if (sideWall)
            {
                CreateCube("Window Frame", new Vector3(x, y - height * 0.5f, z),
                    new Vector3(0.08f, frame, width + frame), trimMaterial, false);
                CreateCube("Window Frame", new Vector3(x, y + height * 0.5f, z),
                    new Vector3(0.08f, frame, width + frame), trimMaterial, false);
            }
            else
            {
                CreateCube("Window Sill", new Vector3(x, y - height * 0.5f, z),
                    new Vector3(width + frame, frame, 0.08f), trimMaterial, false);
            }
        }

        private void AddRooftopEquipment(Vector3 center, float width, float height, float depth)
        {
            float roofY = center.y + height * 0.5f + 0.45f;
            float unitWidth = Mathf.Min(2.2f, width * 0.22f);
            CreateCube("Rooftop Ventilation Unit",
                center + new Vector3(width * 0.22f, height * 0.5f + 0.55f, depth * 0.12f),
                new Vector3(unitWidth, 0.9f, unitWidth), rooftopMaterial, false);
            CreateCube("Roof Parapet",
                new Vector3(center.x, roofY, center.z + depth * 0.48f),
                new Vector3(width, 0.55f, 0.35f), trimMaterial, false);
        }

        private void BuildRoadMarkings(float size)
        {
            float half = size * 0.5f;
            float dashLength = 3.2f;
            float dashGap = 3.8f;
            float step = dashLength + dashGap;
            int dashCount = Mathf.FloorToInt(size / step);

            for (int i = 0; i < dashCount; i++)
            {
                float coordinate = -half + step * i + dashLength * 0.5f;
                CreateCube("Road Centre Dash", new Vector3(coordinate, 0.075f, 0f),
                    new Vector3(dashLength, 0.025f, 0.18f), roadMarkingMaterial, false);
                CreateCube("Road Centre Dash", new Vector3(0f, 0.078f, coordinate),
                    new Vector3(0.18f, 0.025f, dashLength), roadMarkingMaterial, false);
            }

            for (int i = 0; i < blocksPerSide; i++)
            {
                float coordinate = -half + roadWidth + blockSize * 0.5f + i * (blockSize + roadWidth);
                CreateCube("Crosswalk Stripe", new Vector3(coordinate, 0.08f, -roadWidth * 0.31f),
                    new Vector3(0.55f, 0.025f, roadWidth * 0.32f), roadMarkingMaterial, false);
                CreateCube("Crosswalk Stripe", new Vector3(-roadWidth * 0.31f, 0.08f, coordinate),
                    new Vector3(roadWidth * 0.32f, 0.025f, 0.55f), roadMarkingMaterial, false);
            }
        }

        private void CreateRubble(Vector3 buildingCenter, float width, float depth)
        {
            for (int i = 0; i < 4; i++)
            {
                Vector2 offset = Random.insideUnitCircle * 8f;
                float scale = Random.Range(1.2f, 3.2f);
                GameObject rubble = CreateCube("Rubble",
                    new Vector3(buildingCenter.x + offset.x, scale * 0.25f,
                        buildingCenter.z + offset.y),
                    new Vector3(scale * 1.4f, scale * 0.5f, scale),
                    coverMaterial, true);
                rubble.transform.rotation = Quaternion.Euler(
                    Random.Range(-8f, 8f), Random.Range(0f, 180f), Random.Range(-8f, 8f));
            }
        }

        private void BuildStreetCover()
        {
            float half = MapSize * 0.5f;
            for (int i = 0; i < blocksPerSide; i++)
            {
                float lane = -half + roadWidth + blockSize * 0.5f + i * (blockSize + roadWidth);
                CreateDestructibleCube("Concrete road barrier",
                    new Vector3(lane, 0.7f, -roadWidth * 0.32f),
                    new Vector3(7f, 1.4f, 2.2f), coverMaterial, 95f);
                CreateDestructibleCube("Concrete road barrier",
                    new Vector3(-roadWidth * 0.32f, 0.7f, lane),
                    new Vector3(2.2f, 1.4f, 7f), coverMaterial, 95f);
                if (i % 2 == 0)
                {
                    CreateDestructibleCube("Abandoned vehicle cover",
                        new Vector3(lane, 0.9f, roadWidth * 0.32f),
                        new Vector3(5.5f, 1.8f, 2.5f), ruinMaterial, 130f);
                }
            }
        }

        private void BuildBoundary(float size)
        {
            float outer = size + roadWidth * 2f;
            float wallHeight = 5f;
            float wallThickness = 2f;
            CreateCube("North perimeter wall", new Vector3(0f, wallHeight * 0.5f, outer * 0.5f),
                new Vector3(outer, wallHeight, wallThickness), ruinMaterial, true);
            CreateCube("South perimeter wall", new Vector3(0f, wallHeight * 0.5f, -outer * 0.5f),
                new Vector3(outer, wallHeight, wallThickness), ruinMaterial, true);
            CreateCube("East perimeter wall", new Vector3(outer * 0.5f, wallHeight * 0.5f, 0f),
                new Vector3(wallThickness, wallHeight, outer), ruinMaterial, true);
            CreateCube("West perimeter wall", new Vector3(-outer * 0.5f, wallHeight * 0.5f, 0f),
                new Vector3(wallThickness, wallHeight, outer), ruinMaterial, true);
        }

        private void BuildObjectives()
        {
            int count = Mathf.Max(1, capturePointCount);
            float spacing = blockSize + roadWidth;
            for (int i = 0; i < count; i++)
            {
                float x = (i - (count - 1) * 0.5f) * spacing;
                Vector3 position = new Vector3(x, 0f, 0f);
                GameObject objective = new GameObject("Capture Point " + (char)('A' + i));
                objective.transform.SetParent(generatedRoot, false);
                objective.transform.localPosition = position;

                SphereCollider trigger = objective.AddComponent<SphereCollider>();
                trigger.isTrigger = true;
                trigger.radius = captureRadius;
                CapturePoint capture = objective.AddComponent<CapturePoint>();
                capture.Configure(((char)('A' + i)).ToString(), 12f);

                GameObject ring = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                ring.name = "Objective Zone Visual";
                ring.transform.SetParent(objective.transform, false);
                ring.transform.localPosition = new Vector3(0f, 0.08f, 0f);
                ring.transform.localScale = new Vector3(captureRadius * 2f, 0.04f, captureRadius * 2f);
                Collider ringCollider = ring.GetComponent<Collider>();
                if (ringCollider != null) Destroy(ringCollider);
                ring.GetComponent<Renderer>().sharedMaterial = objectiveMaterial;

                // Keep a reference alive for Unity serialization/debugging and avoid unused warning.
                if (capture == null) Debug.LogWarning("CapturePoint component could not be created.");
            }
        }

        private void BuildSpawnMarkers(float size)
        {
            float x = size * 0.5f - roadWidth * 0.5f;
            CreateSpawn("Blue Team Spawn", new Vector3(-x, 0.15f, -x),
                new Color(0.15f, 0.45f, 1f), TankTeam.Blue);
            CreateSpawn("Red Team Spawn", new Vector3(x, 0.15f, x),
                new Color(1f, 0.2f, 0.15f), TankTeam.Red);
        }

        private void CreateSpawn(string label, Vector3 position, Color color, TankTeam team)
        {
            GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = label + " Marker";
            marker.transform.SetParent(generatedRoot, false);
            marker.transform.localPosition = position;
            marker.transform.localScale = new Vector3(5f, 0.15f, 5f);
            marker.AddComponent<TankSpawnPoint>().Configure(team);
            Collider collider = marker.GetComponent<Collider>();
            if (collider != null) Destroy(collider);
            Material markerMaterial = MakeMaterial(color);
            marker.GetComponent<Renderer>().sharedMaterial = markerMaterial;
        }

        private GameObject CreateDestructibleCube(string objectName, Vector3 position,
            Vector3 scale, Material material, float health)
        {
            GameObject piece = CreateCube(objectName, position, scale, material, true);
            piece.AddComponent<DestructibleEnvironment>().Configure(health, 3, 4f);
            return piece;
        }

        private GameObject CreateCube(string objectName, Vector3 position, Vector3 scale,
            Material material, bool withCollider)
        {
            GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
            cube.name = objectName;
            cube.transform.SetParent(generatedRoot, false);
            cube.transform.localPosition = position;
            cube.transform.localScale = scale;
            Renderer renderer = cube.GetComponent<Renderer>();
            if (renderer != null) renderer.sharedMaterial = material;
            if (!withCollider)
            {
                Collider collider = cube.GetComponent<Collider>();
                if (collider != null) Destroy(collider);
            }
            return cube;
        }
    }
}