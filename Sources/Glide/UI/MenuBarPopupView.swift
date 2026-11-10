import SwiftUI
import AppKit

public struct GlideTrackpadIcon: View {
    public var size: CGFloat = 22

    public init(size: CGFloat = 22) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.primary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                )

            HStack {
                // Left edge bar (Brightness - orange)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(red: 0.95, green: 0.58, blue: 0.15))
                    .frame(width: size * 0.14, height: size * 0.55)
                    .padding(.leading, size * 0.12)

                Spacer()

                // Right edge bar (Volume - blue)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(red: 0.2, green: 0.55, blue: 0.95))
                    .frame(width: size * 0.14, height: size * 0.55)
                    .padding(.trailing, size * 0.12)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Main menu-bar dropdown view matching menubar-main.png.
public struct MenuBarPopupView: View {
    @Bindable var config = GestureConfiguration.shared

    @State private var brightnessVal: Float = BrightnessController.shared.currentBrightness()
    @State private var volumeVal: Float = VolumeController.shared.currentVolume()
    @State private var isMuted: Bool = VolumeController.shared.isMuted()
    @State private var showSettings: Bool = false
    @State private var showQuitConfirmation: Bool = false

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        Group {
            if showSettings {
                SettingsView(
                    onBack: { showSettings = false },
                    onQuit: { NSApp.terminate(nil) }
                )
            } else {
                mainContent
            }
        }
        .preferredColorScheme(colorScheme)
        .onReceive(timer) { _ in
            brightnessVal = BrightnessController.shared.currentBrightness()
            volumeVal = VolumeController.shared.currentVolume()
            isMuted = VolumeController.shared.isMuted()
        }
        .onAppear {
            showSettings = false
            brightnessVal = BrightnessController.shared.currentBrightness()
            volumeVal = VolumeController.shared.currentVolume()
            isMuted = VolumeController.shared.isMuted()
        }
        .onDisappear {
            showSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlideResetToMain"))) { _ in
            showSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlideShowSettings"))) { _ in
            showSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
            showSettings = false
        }
        .frame(width: 320, height: 580)
    }

    private var colorScheme: ColorScheme? {
        switch config.appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                GlideTrackpadIcon(size: 24)
                Text("Glide")
                    .font(.system(size: 16, weight: .bold))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // Top Status Card (Horizontal Sliders)
            VStack(spacing: 14) {
                // Brightness Slider Row
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.95, green: 0.58, blue: 0.15))
                            Text("BRIGHTNESS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(round(brightnessVal * 100)))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    HorizontalControlSlider(
                        value: Binding(
                            get: { Double(brightnessVal) },
                            set: { newValue in
                                let fVal = Float(newValue)
                                brightnessVal = BrightnessController.shared.setBrightness(fVal)
                            }
                        ),
                        accentColor: Color(red: 0.95, green: 0.58, blue: 0.15)
                    )
                }

                // Volume Slider Row
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.95))
                            Text(isMuted ? "MUTED" : "VOLUME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(round(volumeVal * 100)))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }

                    HorizontalControlSlider(
                        value: Binding(
                            get: { Double(volumeVal) },
                            set: { newValue in
                                let fVal = Float(newValue)
                                volumeVal = VolumeController.shared.setVolume(fVal)
                                isMuted = VolumeController.shared.isMuted()
                            }
                        ),
                        accentColor: Color(red: 0.2, green: 0.55, blue: 0.95)
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Feature Rows & Sliders
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    // Haptic Feedback Row
                    HStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(red: 0.42, green: 0.33, blue: 0.96))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptic Feedback")
                                .font(.system(size: 13, weight: .medium))
                            Text("Clicks as you slide")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Picker("", selection: $config.hapticStrength) {
                            Text("Strong").tag(2)
                            Text("Subtle").tag(1)
                            Text("Off").tag(0)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 90)
                    }

                    // Quick Mute Row
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(red: 0.42, green: 0.33, blue: 0.96))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Mute")
                                .font(.system(size: 13, weight: .medium))
                            Text("Double-tap the top-right corner")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $config.isQuickMuteEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                    }

                    // Brightness Toggle
                    HStack(spacing: 10) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(red: 0.95, green: 0.58, blue: 0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Brightness Control")
                                .font(.system(size: 13, weight: .medium))
                            Text(config.isSwapSides ? "Slide along right edge" : "Slide along left edge")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $config.isBrightnessEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                    }

                    // Volume Toggle
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(red: 0.2, green: 0.55, blue: 0.95))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Volume Control")
                                .font(.system(size: 13, weight: .medium))
                            Text(config.isSwapSides ? "Slide along left edge" : "Slide along right edge")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $config.isVolumeEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // Sensitivity Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "gauge.with.needle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(red: 0.42, green: 0.33, blue: 0.96))
                                .clipShape(Circle())

                            Text("Sensitivity")
                                .font(.system(size: 13, weight: .medium))

                            Spacer()

                            Text(String(format: "%.1f×", config.brightnessSensitivity))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                        }

                        CustomStepSlider(
                            value: Binding(
                                get: { config.brightnessSensitivity },
                                set: {
                                    config.brightnessSensitivity = $0
                                    config.volumeSensitivity = $0
                                }
                            ),
                            range: 0.4...2.6,
                            steps: 9
                        )
                        .padding(.leading, 38)
                    }

                    // Edge Width Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.left.and.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(red: 0.42, green: 0.33, blue: 0.96))
                                .clipShape(Circle())

                            Text("Edge Width")
                                .font(.system(size: 13, weight: .medium))

                            Spacer()

                            Text("\(Int(round(config.edgeZoneWidth * 100)))%")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                        }

                        CustomStepSlider(
                            value: $config.edgeZoneWidth,
                            range: 0.04...0.15,
                            steps: 8
                        )
                        .padding(.leading, 38)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            Divider()
                .padding(.top, 4)

            // Footer
            HStack {
                Button(action: { showSettings = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                        Text("Settings")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)

                Spacer()

                Menu {
                    Button("Check for Updates…") {
                        AppDelegate.shared?.closePopover()
                        UpdateChecker.shared.checkForUpdates(explicit: true)
                    }
                    Button("Reset to Defaults") {
                        config.resetToDefaults()
                    }
                    Button("About Glide") {
                        AppDelegate.shared?.openAboutWindow()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: { showQuitConfirmation = true }) {
                    Image(systemName: "power")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit Glide")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Quit Glide?", isPresented: $showQuitConfirmation) {
            Button("Quit Glide", role: .destructive) {
                NSApp.terminate(nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Trackpad edge gestures will stop working until you relaunch Glide.")
        }
    }
}

/// Custom slider with purple fill, white thumb knob, and subtle tick dots matching menubar-main.png.
struct CustomStepSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let steps: Int

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let normalized = max(0, min(1, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
            let thumbX = CGFloat(normalized) * (width - 20) + 10

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 18)

                // Tick dots
                HStack(spacing: 0) {
                    ForEach(0..<steps, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.2))
                            .frame(width: 3, height: 3)
                        if i < steps - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 10)

                // Active purple fill
                Capsule()
                    .fill(Color(red: 0.42, green: 0.33, blue: 0.96))
                    .frame(width: thumbX + 6, height: 18)

                // White circular thumb knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .position(x: thumbX, y: 9)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = max(0, min(width, gesture.location.x))
                        let percent = Double(clampedX / width)
                        let rawVal = range.lowerBound + percent * (range.upperBound - range.lowerBound)
                        value = max(range.lowerBound, min(range.upperBound, rawVal))
                    }
            )
        }
        .frame(height: 18)
    }
}

/// Interactive horizontal slider for direct brightness and volume dragging.
struct HorizontalControlSlider: View {
    @Binding var value: Double // 0.0 ... 1.0
    let accentColor: Color

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clampedVal = max(0.0, min(1.0, value))
            let thumbX = CGFloat(clampedVal) * (width - 16) + 8

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 16)

                // Active filled track
                Capsule()
                    .fill(accentColor)
                    .frame(width: max(16, thumbX + 8), height: 16)

                // White circular thumb knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                    .position(x: thumbX, y: 8)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = max(0, min(width, gesture.location.x))
                        let percent = Double(clampedX / width)
                        value = max(0.0, min(1.0, percent))
                    }
            )
        }
        .frame(height: 16)
    }
}

