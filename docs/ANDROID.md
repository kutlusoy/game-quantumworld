# Quantum World: Android Build

Status: the export preset is prepared but has **not been tested on a device or emulator yet**. The game runs on desktop with the same renderer (GL Compatibility) and landscape layout; touch controls are implemented but only verified through input simulation.

## Requirements

- Godot 4.3 with export templates for 4.3 installed (Editor > Manage Export Templates).
- JDK 17.
- Android SDK with platform-tools, build-tools 34.0.0, platform 34 and CMake 3.10.2 (command line tools are enough).
- Editor settings (Editor > Editor Settings > Export > Android): Java SDK path and Android SDK path.
- A debug keystore (Godot can use `~/.android/debug.keystore`; create one with `keytool -genkeypair -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`), referenced in the editor settings.

## Debug APK

```
godot --headless --path . --import
mkdir -p build
godot --headless --path . --export-debug Android build/quantumworld.apk
adb install -r build/quantumworld.apk
```

The preset in `export_presets.cfg` builds arm64-v8a only (all current phones), without Gradle, immersive mode on, package id `com.quantumworld.game`. Landscape orientation and ETC2/ASTC texture import are set in `project.godot`.

## Release

Create a release keystore and keep it out of the repository (`*.keystore` and `*.jks` are ignored). Do not commit passwords: enter them in the export dialog or pass them through the environment. For Google Play use an AAB: enable Gradle build in the preset (requires installing the Android build template) and set the export format to AAB.

## Checklist before the first device test

1. Frame rate on a mid-range phone (the world builds in about 120 ms on desktop; terrain uses 32x32 chunks and tree MultiMesh).
2. Touch layout on different aspect ratios (stretch mode is `canvas_items` with `keep` aspect, so bars may appear on very wide screens).
3. Avatar triangle budget (about 10k per avatar) with several avatars on screen once ghost players exist.
4. Save file location (`user://save.json`, `user://avatar.json`) survives app restarts.
5. Audio, once added.
