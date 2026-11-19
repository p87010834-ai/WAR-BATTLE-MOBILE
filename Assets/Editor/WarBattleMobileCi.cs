using System;
using System.Linq;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace WarBattleMobile.EditorTools
{
    /// <summary>
    /// Batch-mode entry point for a reproducible Android greybox build.
    /// Generates the starter scene and prefabs before invoking BuildPipeline.
    /// </summary>
    public static class WarBattleMobileCi
    {
        private const string AndroidOutput = "Build/Android/WAR-BATTLE-MOBILE.apk";

        public static void BuildAndroid()
        {
            Debug.Log("[WAR BATTLE MOBILE CI] Generating the tank vertical slice assets.");
            WarBattleMobileProjectSetup.BuildTankVerticalSlice();
            WarBattleMobileProjectSetup.ValidateTankVerticalSliceAssetsOrThrow();

            ConfigureLegacyInputHandling();
            ConfigureAndroidPlayerSettings();
            Directory.CreateDirectory(Path.GetDirectoryName(AndroidOutput));

            EditorBuildSettingsScene[] enabledScenes = EditorBuildSettings.scenes
                .Where(scene => scene.enabled)
                .ToArray();

            if (enabledScenes.Length == 0)
                throw new InvalidOperationException(
                    "No enabled scenes are configured in Editor Build Settings.");

            if (!enabledScenes.Any(scene =>
                scene.path == "Assets/WarBattleMobile/Scenes/TankVerticalSlice.unity"))
            {
                throw new InvalidOperationException(
                    "Generated TankVerticalSlice scene is not enabled in Build Settings.");
            }

            if (!EditorUserBuildSettings.SwitchActiveBuildTarget(
                BuildTargetGroup.Android, BuildTarget.Android))
            {
                throw new InvalidOperationException(
                    "Could not switch the Unity build target to Android. " +
                    "Verify Android Build Support is installed in the Unity environment.");
            }

            BuildPlayerOptions options = new BuildPlayerOptions
            {
                scenes = enabledScenes.Select(scene => scene.path).ToArray(),
                locationPathName = AndroidOutput,
                target = BuildTarget.Android,
                options = BuildOptions.None
            };

            Debug.Log("[WAR BATTLE MOBILE CI] Building Android APK to " + AndroidOutput);
            BuildReport report = BuildPipeline.BuildPlayer(options);

            if (report == null || report.summary.result != BuildResult.Succeeded)
            {
                string result = report == null
                    ? "No BuildReport was returned."
                    : "Build result: " + report.summary.result +
                      "; errors: " + report.summary.totalErrors +
                      "; warnings: " + report.summary.totalWarnings + ".";
                throw new BuildFailedException(
                    "WAR BATTLE MOBILE Android build failed. " + result);
            }

            Debug.Log("[WAR BATTLE MOBILE CI] Android APK build succeeded: " +
                AndroidOutput + " (" + report.summary.totalSize + " bytes).");
        }

        /// <summary>
        /// The current mobile controls and camera use UnityEngine.Input and
        /// StandaloneInputModule. Keep the legacy input backend enabled so
        /// touch UI and camera input work in the Android player.
        /// </summary>
        private static void ConfigureLegacyInputHandling()
        {
            PlayerSettings settings = null;

            // Unity 6 stores global Player Settings on BuildProfile. Resolve it
            // reflectively so this project remains compatible with Unity 6.0
            // without taking a compile-time dependency on Build Profile APIs.
            Type buildProfileType = Type.GetType(
                "UnityEditor.Build.Profile.BuildProfile, UnityEditor.CoreModule");
            if (buildProfileType != null)
            {
                FieldInfo globalSettingsField = buildProfileType.GetField(
                    "s_GlobalPlayerSettings",
                    BindingFlags.Static | BindingFlags.NonPublic);
                if (globalSettingsField != null)
                    settings = globalSettingsField.GetValue(null) as PlayerSettings;

                MethodInfo getActiveProfile = buildProfileType.GetMethod(
                    "GetActiveBuildProfile",
                    BindingFlags.Public | BindingFlags.Static);
                object activeProfile = getActiveProfile != null
                    ? getActiveProfile.Invoke(null, null) : null;
                if (activeProfile != null)
                {
                    FieldInfo overrideField = buildProfileType.GetField(
                        "m_PlayerSettings",
                        BindingFlags.Instance | BindingFlags.NonPublic);
                    if (overrideField != null)
                    {
                        PlayerSettings overrideSettings =
                            overrideField.GetValue(activeProfile) as PlayerSettings;
                        if (overrideSettings != null) settings = overrideSettings;
                    }
                }
            }

            if (settings == null)
                settings = Resources.FindObjectsOfTypeAll<PlayerSettings>().FirstOrDefault();

            if (settings == null)
                throw new InvalidOperationException(
                    "Could not locate Unity Player Settings to configure Active Input Handling.");

            SerializedObject serializedSettings = new SerializedObject(settings);
            SerializedProperty activeInputHandler =
                serializedSettings.FindProperty("activeInputHandler");
            if (activeInputHandler == null)
                throw new InvalidOperationException(
                    "Unity Player Settings has no activeInputHandler property. " +
                    "Configure Active Input Handling to Input Manager (Old) or Both.");

            // 0 = Input Manager (Old). The project currently uses the legacy
            // Input API and StandaloneInputModule, and does not require the new
            // Input System package for this first playable build.
            activeInputHandler.intValue = 0;
            serializedSettings.ApplyModifiedProperties();

            Debug.Log("[WAR BATTLE MOBILE CI] Active Input Handling set to Input Manager (Old).");
        }

        private static void ConfigureAndroidPlayerSettings()
        {
            PlayerSettings.companyName = "WAR BATTLE MOBILE";
            PlayerSettings.productName = "WAR BATTLE MOBILE";
            PlayerSettings.bundleVersion = "0.1.0";
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.runInBackground = false;
            PlayerSettings.SetApplicationIdentifier(
                BuildTargetGroup.Android, "com.warbattlemobile.game");
            PlayerSettings.Android.bundleVersionCode = 1;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.SetScriptingBackend(
                BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
        }
    }
}
