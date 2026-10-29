# Virtual Try-On – Spectacle AR (Flutter)

Real-time virtual spectacle try-on. The front camera feeds a **native Kotlin
ML Kit face tracker**; Flutter turns the result into a position / scale /
rotation for a vector spectacle frame drawn over the live preview.

> Platform: **Android** (minSdk 21). Flutter ↔ Kotlin via MethodChannel + EventChannel.

## Features
- Home screen + try-on screen with navigation
- Live camera preview with real-time face tracking
- Frame follows **position, head tilt (roll), turn (yaw), nod (pitch)** and **distance** (scale)
- 4 switchable frames (Classic Round, Bold Wayfarer, Sky Aviator, Rose Cat-Eye), applied instantly
- Status chip ("Tracking face" / "Looking for a face…"), debug overlay toggle, permission-denied & error states
- Pauses / resumes the camera with the app lifecycle

## Setup
Prerequisites: Flutter 3.22+ (Dart 3.3+), Android SDK, a physical Android device (camera + USB debugging).

```bash
cd source

# 1. Generate the Gradle wrapper / icons / etc. that are not checked in.
#    Existing files (lib/, pubspec.yaml, MainActivity.kt, AndroidManifest.xml) are kept.
#    If your Flutter version overwrites any of them, restore from git.
flutter create --platforms=android --org com.example --project-name virtual_tryon .

# 2. Two edits to android/app/build.gradle(.kts)  (see below)

# 3. Run
flutter pub get
flutter test
flutter run            # device connected
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

### Required Gradle edits (`android/app/build.gradle` or `build.gradle.kts`)
1. `minSdk` must be **21** or higher:
   - Kotlin DSL: `minSdk = 21`  ·  Groovy: `minSdkVersion 21`
2. Add the ML Kit dependency:
   - Kotlin DSL: `dependencies { implementation("com.google.mlkit:face-detection:16.1.7") }`
   - Groovy: `dependencies { implementation 'com.google.mlkit:face-detection:16.1.7' }`

(If `flutter create` generated a different package than `com.example.virtual_tryon`,
update the `package` line of the two `.kt` files and move them to match.)

## Dependencies
| Package | Why |
|---|---|
| `camera ^0.10.6` | Live preview + raw frame stream (Camera2 backend, NV21) |
| `provider ^6.1.2` | State management (ChangeNotifier) |
| `com.google.mlkit:face-detection:16.1.7` (native) | On-device face detection, landmarks and head Euler angles |

## Technologies
Flutter / Dart · Kotlin · Google ML Kit Face Detection · Flutter platform channels · CustomPainter vector graphics

## Project layout
```
lib/
  main.dart, app.dart, core/theme.dart
  models/        frame_model, tracking (native payload), face_pose (maths)
  services/      face_tracking_service  (Dart side of the channels)
  state/         try_on_controller      (camera + tracking + selection)
  ui/            home_screen, try_on_screen, widgets/{glasses_overlay, spectacle_painter, frame_selector}
android/app/src/main/kotlin/.../FaceTrackerPlugin.kt   (native ML Kit + channels)
test/face_pose_test.dart
```

## Implementation summary
1. `camera` streams NV21 frames (640×480).
2. Each frame is sent over the **MethodChannel** to Kotlin (`processFrame`); frames are skipped while one is in flight.
3. Kotlin runs ML Kit and pushes faces (bounds, eyes, Euler X/Y/Z) back on the **EventChannel**.
4. `FacePose` converts them to preview space (mirror-aware); an exponential filter smooths jitter.
5. `GlassesOverlay` positions at the eye midpoint, scales by eye distance, and applies a perspective matrix for roll / pitch / yaw.

Details: see `Technical_Documentation.md`.

## Assumptions
- Portrait use only (orientation locked); front camera only; one face (the largest) is tracked.
- Android front-camera preview is displayed mirrored; `TryOnController.previewMirrored` controls the matching flip.
- Frames are 2D vector drawings with a perspective transform, not 3D models.

## Known limitations
- **Android only.** iOS would need an equivalent Swift plugin (e.g. ML Kit / Vision) behind the same channel contract.
- Pseudo-3D: no real depth, so no temple arms occluded by ears and no occlusion by the face. At large yaw (> ~35°) the frame fades out.
- ML Kit head Euler angles are less accurate for pitch than for yaw/roll; angle gain constants (0.8 / 0.9) were chosen by eye and may need per-device tuning.
- Frame copy across the channel costs a few ms per frame; tracking is ~15–30 fps depending on device.
- Frames are not sized to the user's real face width (no calibration).
- Not yet tested on a physical device by the author of this scaffold: verify mirroring and yaw/roll signs on your phone first (use the bug-icon debug overlay).
