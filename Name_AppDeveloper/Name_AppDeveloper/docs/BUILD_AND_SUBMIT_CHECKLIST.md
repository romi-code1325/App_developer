# Remaining steps (need a real machine / device)
1. Follow README setup, run on a real Android phone, check the frame sits on your eyes.
   - Frame mirrored / off to the wrong side → flip `TryOnController.previewMirrored`.
   - Turning left makes it turn right → negate the yaw in `FacePose.fromFace`.
2. `flutter build apk --release` → copy to `App_Build.apk`.
3. Record a 2–5 min screen + front-view demo (all 4 frames, tilt, turn, move closer/farther) → `Demo_Video.mp4`.
4. Export `Technical_Documentation.md` to `Technical_Documentation.pdf`.
5. Private GitHub repo; invite soham.ghugare@gmail.com and akhil.raibhog@gmail.com.
6. Rename folder to `YourName_AppDeveloper`, zip, upload to Drive ("Anyone with the link can view"), submit the form.
