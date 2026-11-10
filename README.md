# Glide

A lightweight, native macOS menu-bar utility written from scratch in Swift (macOS 14+, Swift 5.9+) with **zero third-party dependencies**.

Glide lets you adjust **Display Brightness** and **System Volume** by sliding along the left and right edges of your MacBook trackpad — complete with physical Force Touch haptic clicks and ratchet micro-ticks, rock-solid cursor freeze, modifier-key fine tuning, quick-mute corner double-tap, screen-aware floating bezel HUDs, and an EdgeBar-style menu-bar dropdown & settings interface.

---

## ✨ Features

- **Left Edge Slide**: Smoothly adjusts display brightness (0% to 100%) via private `DisplayServices.framework`.
- **Right Edge Slide**: Smoothly adjusts system output volume (0% to 100%) via CoreAudio.
- **Hardware Taptic Engine Feedback (`MTActuator`)**:
  - Mechanical click on gesture engagement and quick mute (Actuation ID 6).
  - Subtle ratchet micro-ticks every ~3.5% adjustment step (Actuation ID 1).
- **Cursor Freeze**: Pointer stays pinned without jumping or drifting while sliding along the edge (`CGAssociateMouseAndMouseCursorPosition(0)` and per-frame `CGWarpMouseCursorPosition`).
- **Fine Control (`⇧ Shift` / `⌥ Option`)**: Scales adjustment rate to `0.25×` for precision quarter-steps.
- **Quick Mute Corner Tap**: Double-tapping the top-right corner of the trackpad toggles system mute with haptic feedback.
- **Screen-Aware HUD Overlay**: Floating non-activating bezel (`NSPanel`) displaying brightness/volume icons and progress bars on whichever monitor contains the cursor, fading after 1.2s.
- **EdgeBar-Style Menu Bar Dropdown & Settings**:
  - Main popup with live brightness/volume meters, haptic strength selector, quick toggles, sensitivity, and edge width sliders.
  - Settings panel with swap sides, active height zones (Entire Edge, Bottom Half, Bottom Quarter), modifier requirements, appearance theme, and launch at login (`SMAppService`).
- **Pure Native & Lightweight**: `LSUIElement = true` (menu bar only, 0% CPU at idle, ~320 KB release binary).

---

## 🛠 Project Layout

```
glide/
├── Package.swift
├── Resources/
│   ├── AppIcon.icns
│   └── Info.plist
├── scripts/
│   ├── bundle.sh              # Build release SPM executable, package Glide.app, ad-hoc sign
│   └── generate_icon.swift    # App icon generator
└── Sources/
    └── Glide/
        ├── App.swift                  # NSApplicationDelegate, status item, lifecycle
        ├── Gestures/
        │   ├── BrightnessController.swift     # DisplayServices dynamic loader
        │   ├── GestureConfiguration.swift     # Observable settings & UserDefaults persistence
        │   ├── GestureOverlayController.swift # Screen-aware HUD bezel panel
        │   ├── MultitouchSupportBridge.swift  # MultitouchSupport & MTActuator bridge
        │   ├── TrackpadGestureManager.swift   # Gesture state machine, warp & haptics
        │   └── VolumeController.swift         # CoreAudio volume & mute controller
        └── UI/
            ├── MenuBarPopupView.swift         # Menu bar dropdown matching menubar-main.png
            └── SettingsView.swift             # Settings view matching menubar-settings.png
```

---

## 🚀 Building & Running

### Requirements
- macOS 14.0+ (Apple Silicon or Intel)
- Xcode Command Line Tools / Swift 5.9+

### Build & Package
```bash
./scripts/bundle.sh release
```
This produces `Glide.app` ready to launch.

### Launch
```bash
open Glide.app
```
