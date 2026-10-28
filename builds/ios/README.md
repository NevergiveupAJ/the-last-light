# iOS build
You need a Mac with Xcode and an Apple Developer account.
1. In Godot: Editor > Manage Export Templates > Download (4.3).
2. Project > Export > **iOS** (preset already set up). Fill in App Store Team ID and change the bundle id `com.yourstudio.thelastlight` to your own.
3. Export. Godot makes an Xcode project. Open it, set signing, and run it on a real iPhone or iPad.
4. Product > Archive in Xcode, then upload to App Store Connect (TestFlight first).
The main menu hides "Quit" on iOS, as Apple requires.
