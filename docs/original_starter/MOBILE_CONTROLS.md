# Mobile Control Layout

Suggested landscape layout:
- Left thumb: virtual joystick for movement.
- Right half of screen: swipe area for camera/look.
- Buttons: Sprint, Crouch, Jump, Interact, Flashlight, Inventory, Pause.
- HUD: health, stamina, flashlight battery, current objective, fuse count.
- Accessibility: adjustable sensitivity, left-handed layout, button scaling, vibration toggle, subtitles.

Wire joystick output to `Player.set_mobile_movement(Vector2)`.
Wire sprint and crouch press/release to `set_mobile_sprint(bool)` and `set_mobile_crouch(bool)`.
Use TouchScreenButton or a custom Control-based joystick. The scripts do not automatically create the UI.
