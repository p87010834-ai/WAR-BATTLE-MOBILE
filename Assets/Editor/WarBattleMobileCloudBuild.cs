using UnityEditor;
using UnityEditor.Build;
using UnityEngine;

namespace WarBattleMobile.EditorTools
{
    /// <summary>
    /// Unity Build Automation pre-export hook.
    /// Generates the greybox scene and required prefabs in the cloud builder
    /// before Unity exports the Android player.
    /// </summary>
    public static class WarBattleMobileCloudBuild
    {
        public static void PreExport()
        {
            Debug.Log("[WAR BATTLE MOBILE] Preparing project for Unity Build Automation.");

            WarBattleMobileProjectSetup.BuildTankVerticalSlice();
            WarBattleMobileProjectSetup.ValidateTankVerticalSliceAssetsOrThrow();

            PlayerSettings.companyName = "WAR BATTLE MOBILE";
            PlayerSettings.productName = "WAR BATTLE MOBILE";
            PlayerSettings.bundleVersion = "0.1.0";
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.SetApplicationIdentifier(
                BuildTargetGroup.Android, "com.warbattlemobile.game");
            PlayerSettings.Android.bundleVersionCode = 1;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.SetScriptingBackend(
                BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);

            Debug.Log("[WAR BATTLE MOBILE] Cloud build preparation completed.");
        }
    }
}
