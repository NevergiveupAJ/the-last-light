# Making THE LAST LIGHT installable on iOS and Android

## Recommended route: Godot 4 native project
For a true native game, recreate/port the prototype gameplay into Godot 4 and export separate builds:

### Android
1. Install Godot 4 and the matching Android export templates.
2. Install the Android SDK/JDK versions recommended by the Godot version you use.
3. In Godot, configure Android export, package name (for example `com.yourstudio.thelastlight`), icon, orientation, and permissions.
4. Export an APK for local testing, then an AAB for Google Play.
5. Test on several Android devices and review performance, touch controls, audio, and save behavior.

### iOS
1. A Mac with Xcode is required for the usual Godot iOS export workflow.
2. Install the matching Godot export templates and configure an iOS export preset.
3. Set a unique bundle identifier, icons, launch screen, and signing/team settings in Xcode.
4. Build and test on a real iPhone/iPad, then archive and submit through App Store Connect.

## Faster prototype wrapper option
The browser build can be hosted on HTTPS and wrapped with a maintained web-to-app tool such as Capacitor. This is useful for a first test build, but test mobile input, full-screen behavior, audio policy, safe areas, and store requirements carefully. Keep the web game playable offline if that is a release requirement.

## Before publishing
- Replace placeholder app icons with original artwork.
- Add a privacy policy if collecting any user data or using analytics/ads.
- If monetizing, implement and test platform-compliant in-app purchases; do not imply purchases are present until they are implemented.
- Verify all music, sound effects, fonts, and art are original or properly licensed.
- Test accessibility, crashes, battery usage, screen sizes, and save/load behavior.
- Prepare screenshots, age rating, store description, support contact, and release notes.

No signing keys, developer accounts, store approvals, or compiled IPA/AAB are included in this starter ZIP.
