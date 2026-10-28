# Android build (APK for testing, AAB for Google Play)
1. In Godot: Editor > Manage Export Templates > Download (4.3).
2. Install a JDK 17 and the Android SDK, then set both paths in Editor > Editor Settings > Export > Android.
3. Project > Export > **Android** (preset already set up: arm64, landscape, package `com.yourstudio.thelastlight`).
   Change the package name to your own before publishing. It can never change after the first upload.
4. Debug test: plug in a phone with USB debugging on, then click the Android "remote deploy" icon in the editor.
5. Release: create a keystore, enter it under Keystore > Release, turn on "Use Gradle Build", set the export format to AAB, and export.
6. Upload the AAB in the Google Play Console (internal testing first).
