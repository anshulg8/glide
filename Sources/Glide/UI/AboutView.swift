import SwiftUI
import AppKit

/// Dedicated About window for Glide.
public struct AboutView: View {
    var onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Icon
            GlideTrackpadIcon(size: 68)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .padding(.top, 6)

            // Title & Version
            VStack(spacing: 3) {
                Text("Glide")
                    .font(.system(size: 22, weight: .bold))
                Text("Version 1.0")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Creator attribution
            VStack(spacing: 5) {
                Text("Created by")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text("Anshul Garg")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Button(action: {
                    if let url = URL(string: "http://anshulgarg.in/") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                        Text("anshulgarg.in")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.42, green: 0.33, blue: 0.96))
                }
                .buttonStyle(.plain)
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.vertical, 4)

            Divider()

            // Feature Highlights
            VStack(spacing: 5) {
                Text("MacBook Trackpad Edge Gestures")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Display Brightness  •  System Volume  •  Force Touch Haptics")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Close button
            Button(action: onClose) {
                Text("Close")
                    .font(.system(size: 13, weight: .medium))
                    .frame(minWidth: 80)
            }
            .keyboardShortcut(.defaultAction)
            .padding(.top, 4)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 340)
    }
}

