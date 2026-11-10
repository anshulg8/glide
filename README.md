# Glide

<p align="center">
  <img src="Resources/AppIcon.icns" width="128" height="128" alt="Glide Icon">
</p>

<p align="center">
  <strong>Native macOS Menu-Bar Utility for MacBook Trackpad Edge Gestures</strong>
</p>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9+-FA7343.svg?logo=swift&logoColor=white" alt="Swift 5.9+"></a>
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/macOS-14.0+-000000.svg?logo=apple&logoColor=white" alt="macOS 14+"></a>
  <img src="https://img.shields.io/badge/Dependencies-0-success.svg" alt="Zero Dependencies">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License"></a>
</p>

---

## 🌟 Open Source & Free for Everyone

**Glide is 100% free and open-source software under the [MIT License](LICENSE).**

Everyone is welcome to use, study, customize, fork, and contribute to this project. No paywalls, no telemetry, no background daemons, and zero third-party dependencies.

Created and maintained with ❤️ by **[Anshul Garg](http://anshulgarg.in/)**.

---

## ✨ Features

- **Left Edge Slide**: Smoothly adjusts display brightness (0% to 100%) via Apple Silicon native `DisplayServices.framework`.
- **Right Edge Slide**: Smoothly adjusts system output volume (0% to 100%) via CoreAudio.
- **Hardware Taptic Engine Feedback (`MTActuator`)**:
  - Crisp Force Touch mechanical click when a gesture engages or toggles mute (Actuation ID 6).
  - Subtle ratchet micro-ticks every ~3.5% adjustment increment as you slide (Actuation ID 1).
- **Rock-Solid Cursor Freeze**: The mouse pointer stays completely pinned and stationary during edge slides (`CGAssociateMouseAndMouseCursorPosition(0)` and per-frame `CGWarpMouseCursorPosition`), restoring seamlessly upon release.
- **Interactive Horizontal Sliders**: The menu bar popup features space-saving horizontal Brightness and Volume tracks that you can tap or drag directly, with real-time bidirectional sync.
- **Fine Control (`⇧ Shift` / `⌥ Option`)**: Holding Shift or Option scales adjustment speed down to `0.25×` for precision quarter-steps.
- **Quick Mute Corner Tap**: Double-tapping the top-right corner of the trackpad toggles system mute with haptic feedback.
- **Screen-Aware HUD Overlay**: Floating non-activating bezel (`NSPanel`) displaying volume/brightness icons and smooth progress bars on whichever monitor currently contains the cursor, fading after 1.2s.
- **Click-Outside Auto-Dismiss**: The menu bar dropdown automatically dismisses whenever you click anywhere outside or press Escape.
- **Preferences & Menu Bar UI**:
  - Menu-bar popup with sliders for Sensitivity, Edge Zone width, and feature toggles.
  - Settings sheet with side swapping, active height zone restriction (Entire Edge, Bottom Half, Bottom Quarter), modifier-key requirement, appearance theme, and launch at login (`SMAppService`).
- **Resource Efficient**: `LSUIElement = true` (runs exclusively in the menu bar without a Dock icon; 0% CPU at idle; ~320 KB release binary).

---

## 🛠 Project Structure

```
glide/
├── LICENSE                    # MIT Open Source License
├── Package.swift              # Pure SPM definition (zero external dependencies)
├── README.md
├── Resources/
│   ├── AppIcon.icns           # High-resolution application icon
│   └── Info.plist             # LSUIElement = true accessory configuration
├── scripts/
│   ├── bundle.sh              # Build release SPM executable, assemble Glide.app, and ad-hoc sign
│   └── generate_icon.swift    # App icon asset generator
└── Sources/
    └── Glide/
        ├── App.swift                  # NSApplicationDelegate, status item, popover lifecycle
        ├── Gestures/
        │   ├── BrightnessController.swift     # DisplayServices dynamic loader
        │   ├── GestureConfiguration.swift     # Observable settings & UserDefaults persistence
        │   ├── GestureOverlayController.swift # Screen-aware HUD bezel panel
        │   ├── MultitouchSupportBridge.swift  # MultitouchSupport & MTActuator bridge
        │   ├── TrackpadGestureManager.swift   # Gesture state machine, warp & haptics
        │   └── VolumeController.swift         # CoreAudio volume & mute controller
        └── UI/
            ├── AboutView.swift                # Dedicated About window
            ├── MenuBarPopupView.swift         # Main menu bar dropdown with horizontal sliders
            └── SettingsView.swift             # Settings sheet with first-class controls
```

---

## 🚀 Building & Running

### Requirements
- macOS 14.0 (Sonoma) or newer (Apple Silicon or Intel)
- Swift 5.9+ / Xcode Command Line Tools

### 1. Clone the Repository
```bash
git clone https://github.com/anshulg8/glide.git
cd glide
```

### 2. Build & Package `.app`
```bash
./scripts/bundle.sh release
```
This produces an ad-hoc signed, stripped `Glide.app` in the project root.

### 3. Launch
```bash
open Glide.app
```

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m "Add amazing feature"`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by **[Anshul Garg](http://anshulgarg.in/)**.
