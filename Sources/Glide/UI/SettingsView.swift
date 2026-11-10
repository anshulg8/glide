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

            // Settings Content List
            VStack(alignment: .leading, spacing: 14) {
                // Section: Edge Gestures
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edge Gestures")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
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

                        // Bottom Quarter Only
                        SettingsRow(
                            icon: "rectangle.bottomhalf.filled",
                            iconColor: .secondary,
                            title: "Bottom Quarter Only",
                            subtitle: "Ignore touches above the lower 25%"
                        ) {
                            Toggle("", isOn: Binding(
                                get: { config.edgeZoneHeightMode == 2 },
                                set: { config.edgeZoneHeightMode = $0 ? 2 : 0 }
                            ))
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                        }
                        .contextMenu {
                            Button("Entire Edge (100%)") { config.edgeZoneHeightMode = 0 }
                            Button("Bottom Half (50%)") { config.edgeZoneHeightMode = 1 }
                            Button("Bottom Quarter (25%)") { config.edgeZoneHeightMode = 2 }
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

                // Section: While Sliding
                VStack(alignment: .leading, spacing: 8) {
                    Text("While Sliding")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
                        // Freeze Cursor
                        SettingsRow(
                            icon: "location.north.fill",
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
                            icon: "slider.horizontal.2",
                            iconBg: Color(red: 0.42, green: 0.33, blue: 0.96),
                            iconColor: .white,
                            title: "Fine Control",
                            subtitle: "Hold ⇧ ⌥ for quarter steps"
                        ) {
                            Toggle("", isOn: $config.isFineControlEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.42, green: 0.33, blue: 0.96)))
                        }
                    }
                }

                Divider()

                // Section: General
                VStack(alignment: .leading, spacing: 8) {
                    Text("General")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
                        // Appearance
                        HStack(spacing: 10) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(Circle())

                            Text("Appearance")
                                .font(.system(size: 13, weight: .medium))

                            Spacer()

                            Picker("", selection: Binding(
                                get: { config.appearanceMode == "dark" ? "dark" : "light" },
                                set: { config.appearanceMode = $0 }
                            )) {
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 110)
                        }

                        // Open at Login
                        SettingsRow(
                            icon: "power",
                            iconBg: Color(red: 0.42, green: 0.33, blue: 0.96),
                            iconColor: .white,
                            title: "Open at Login",
                            subtitle: ""
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

            Spacer(minLength: 8)

            Divider()

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
                    Menu("Active Trackpad Height") {
                        Button("Entire Edge (Full)") { config.edgeZoneHeightMode = 0 }
                        Button("Bottom Half (50%)") { config.edgeZoneHeightMode = 1 }
                        Button("Bottom Quarter (25%)") { config.edgeZoneHeightMode = 2 }
                    }
                    Toggle("Visual Overlay HUD", isOn: $config.showOverlay)
                    Divider()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .foregroundColor(.primary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
                .fixedSize()
        }
    }
}
