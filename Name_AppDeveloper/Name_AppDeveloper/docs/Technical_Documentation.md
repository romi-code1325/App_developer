# Technical Documentation – Virtual Try-On

## 1. How face tracking works
- **Technology:** Google ML Kit Face Detection (on-device), run in Kotlin.
- Config: `PERFORMANCE_MODE_FAST`, `LANDMARK_MODE_ALL`, tracking enabled, min face size 0.15.
- **Frame path:** `camera` plugin (Camera2) → NV21 bytes → MethodChannel `processFrame` → `InputImage.fromByteArray(..., rotation, NV21)` → ML Kit.
- `rotation` = camera sensor orientation (app is portrait-locked) so ML Kit returns coordinates in the upright image.
- Per face we return: bounding box, left/right eye landmarks, head Euler angles X (pitch), Y (yaw), Z (roll), tracking id.
- Back-pressure: Dart skips camera frames while a `processFrame` call is pending, so latency never builds up.
- Dart picks the largest face, then smooths the pose with an exponential filter (α = 0.55) and tolerates 6 missed detections before hiding the frame (prevents flicker).

## 2. How the virtual frame is positioned and transformed
Every frame is vector-drawn in a 220×90 design box whose lens centres are exactly 100 units apart, so the design's "eye span" equals the user's inter-eye distance after scaling.

| Face property | Source | Transform applied |
|---|---|---|
| Position | midpoint of eye landmarks | box centred on that point (`Positioned`) |
| Size / distance | eye distance (px) | `Transform.scale(eyeDistance / 100)` – nearer face → larger pixels → larger frame |
| Tilt (roll) | `atan2` of the eye line | `rotateZ(roll)` |
| Turn (yaw) | Euler Y (sign flipped for mirrored preview) | `rotateY(yaw·0.9)` with a perspective entry `M[3][2] = 0.0012` |
| Nod (pitch) | Euler X | `rotateX(pitch·0.8)` |

- Matrix order `P · Rz · Rx · Ry · S` – yaw/pitch happen in head space, roll last in screen space.
- The overlay shares a `FittedBox(cover)` with the preview and is sized to the camera image, so image-pixel coordinates map directly to layout coordinates with no extra scaling code.
- Mirroring: the front-camera preview is mirrored; x is flipped (`imageWidth − x`) and yaw sign inverted.
- Opacity fades for |yaw| > ~34° so the frame doesn't look wrong when the face is in profile.

## 3. How Flutter communicates with native code
| Direction | Mechanism | Channel | Messages |
|---|---|---|---|
| Flutter → Kotlin | `MethodChannel` | `virtual_tryon/face_tracker` | `start`, `processFrame{bytes,width,height,rotation}`, `stop` |
| Kotlin → Flutter | `EventChannel` | `virtual_tryon/face_events` | map: `imageWidth`, `imageHeight`, `timestamp`, `faces[]` |

`FaceTrackerPlugin` is a self-contained `FlutterPlugin` registered in `MainActivity.configureFlutterEngine`. The `processFrame` future completes only after detection finishes (and after the event is emitted), giving natural flow control. Errors surface as `PlatformException` and are treated as "dropped frame".

## 4. Architecture / state management
`provider` + `ChangeNotifier` (`TryOnController`), scoped to the try-on route so the camera is released when the user leaves. Coarse state (status, selected frame, debug) uses `notifyListeners`; the ~30 Hz pose uses a `ValueNotifier<FacePose?>` so only the overlay repaints. Selecting a frame updates `selected` and the overlay redraws immediately.

## 5. Challenges and solutions
| Challenge | Solution |
|---|---|
| Coordinate mapping between sensor image, rotated image, mirrored preview and cover-fit screen | Do all maths in upright image space and put preview + overlay in one `FittedBox` |
| Mirror / sign conventions for roll and yaw | Roll computed from the eye line (convention-free); yaw sign flipped explicitly and unit-tested; `previewMirrored` constant for device quirks |
| Frame jitter from detector noise | EMA smoothing + miss tolerance |
| Frame backlog / lag | Drop frames while native call in flight |
| Cost of sending frames over a channel | Low resolution (640×480), NV21 single plane, no Dart-side conversion on the main path |
| Realistic look without 3D asset | Vector frames + perspective matrix (pseudo-3D) |
| Camera backend choice | `camera` pinned to 0.10.x (Camera2) for reliable NV21 streaming |

## 6. Possible next steps
Move the camera fully native (CameraX + Texture) to avoid per-frame channel copies; 3D frames with ARCore Augmented Faces / Filament for true occlusion; iOS plugin (ARKit / Vision); photo capture and share; face-width calibration.
