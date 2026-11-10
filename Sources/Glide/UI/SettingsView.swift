import SwiftUI
import ServiceManagement

/// Settings view matching menubar-settings.png.
public struct SettingsView: View {
    @Bindable var config = GestureConfiguration.shared
    var onBack: () -> Void
    var onQuit: () -> Void

    public init(onBack: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onBack = onBack
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                GlideTrackpadIcon(size: 24)
                Text("Settings")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Edge Gestures section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Edge Gestures")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            // Swap Sides
                            SettingsRow(
                                icon: "arrow.left.arrow.right",
                                iconColor: .secondary,
                                title: "Swap Sides",
                                subtitle: config.isSwapSides ? "Left: Volume · Right: Brightness" : "Left: Brightness · Right: Volume"
                            ) {
                                Toggle("", isOn: $config.isSwapSides)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                            }

                            // Active Height Picker
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 10) {
                                    Image(systemName: "rectangle.bottomthird.inset.filled")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Active Trackpad Height")
                                            .font(.system(size: 13, weight: .medium))
                                        Text(heightModeDescription)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                Picker("", selection: $config.edgeZoneHeightMode) {
                                    Text("Entire Edge").tag(0)
                                    Text("Bottom Half").tag(1)
                                    Text("Bottom Quarter").tag(2)
                                }
                                .pickerStyle(.segmented)
                                .padding(.leading, 38)
                            }

                            // Require Fn or Option
                            SettingsRow(
                                icon: "option",
                                iconColor: .secondary,
                                title: "Require Fn or ⌥",
                                subtitle: "Only slide while holding a modifier"
                            ) {
                                Toggle("", isOn: $config.requireModifier)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                            }
                        }
                    }

                    Divider()

                    // While Sliding section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("While Sliding")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            // Freeze Cursor
                            SettingsRow(
                                icon: "cursorarrow.rays",
                                iconBg: Color(red: 0.42, green: 0.33, blue: 0.96),
                                iconColor: .white,
                                title: "Freeze Cursor",
                                subtitle: "Pointer stays put while sliding"
                            ) {
                                Toggle("", isOn: $config.isCursorFreezeEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                            }

                            // Fine Control
                            SettingsRow(
                                icon: "slider.horizontal.below.sun.max",
                                iconBg: Color(red: 0.42, green: 0.33, blue: 0.96),
                                iconColor: .white,
                                title: "Fine Control",
                                subtitle: "Hold ⇧ ⌥ for quarter steps (0.25×)"
                            ) {
                                Toggle("", isOn: $config.isFineControlEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                            }

                            // Visual Overlay HUD
                            SettingsRow(
                                icon: "macwindow.on.rectangle",
                                iconBg: Color(red: 0.42, green: 0.33, blue: 0.96),
                                iconColor: .white,
                                title: "Overlay HUD",
                                subtitle: "Floating bezel indicator on screen"
                            ) {
                                Toggle("", isOn: $config.showOverlay)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                            }
                        }
                    }

                    Divider()

                    // General section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("General")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            // Appearance
                            HStack(spacing: 10) {
                                Image(systemName: "circle.lefthalf.striped.horizontal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.primary.opacity(0.06))
                                    .clipShape(Circle())

                                Text("Appearance")
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                Picker("", selection: $config.appearanceMode) {
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                    Text("Auto").tag("system")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }

                            // Open at Login
                            SettingsRow(
                                icon: "power",
                                iconBg: Color(red: 0.42, green: 0.33, blue: 0.96),
                                iconColor: .white,
                                title: "Open at Login",
                                subtitle: "Launch Glide automatically at startup"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { config.launchAtLogin },
                                    set: { config.launchAtLogin = $0 }
                                ))
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            Divider()
                .padding(.top, 8)

            // Footer
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Version 1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    Button("Reset to Defaults") {
                        config.resetToDefaults()
                    }
                    Button("About Glide") {
                        NSApp.orderFrontStandardAboutPanel(nil)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: onQuit) {
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
        .frame(width: 320, height: 530)
    }

    private var heightModeDescription: String {
        switch config.edgeZoneHeightMode {
        case 0: return "Responds along full height of trackpad"
        case 1: return "Ignore touches above the lower 50%"
        case 2: return "Ignore touches above the lower 25%"
        default: return ""
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    var icon: String
    var iconBg: Color? = nil
    var iconColor: Color = .primary
    var title: String
    var subtitle: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconBg ?? Color.primary.opacity(0.06))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            trailing
        }
    }
}

