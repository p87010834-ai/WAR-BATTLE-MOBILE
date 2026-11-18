using System;
using System.Linq;
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
    }
}
