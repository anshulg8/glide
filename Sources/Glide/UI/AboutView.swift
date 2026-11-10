import SwiftUI
import AppKit

/// Dedicated About window for Glide.
public struct AboutView: View {
    var onClose: () -> Void
    @ObservedObject private var updateChecker = UpdateChecker.shared

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Icon in soft accent container
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.glideAccent.opacity(0.12))
                    .frame(width: 76, height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.glideAccent.opacity(0.25), lineWidth: 1)
                    )

                GlideTrackpadIcon(size: 50)
            }
            .shadow(color: Color.glideAccent.opacity(0.16), radius: 8, x: 0, y: 3)
            .padding(.top, 4)

            // Title & Version
            VStack(spacing: 4) {
                Text("Glide")
                    .font(.system(size: 22, weight: .bold))

                HStack(spacing: 8) {
                    Text("Version \(updateChecker.currentVersion)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))

                    Button(action: {
                        updateChecker.checkForUpdates(explicit: true)
                    }) {
                        HStack(spacing: 3) {
                            if updateChecker.isChecking {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 10, height: 10)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            Text("Check for Updates")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color.glideAccent)
                    }
                    .buttonStyle(.plain)
                    .disabled(updateChecker.isChecking)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
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
                    HStack(spacing: 5) {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                        Text("anshulgarg.in")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.glideAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.glideAccent.opacity(0.12))
                    .cornerRadius(12)
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 88, height: 28)
                    .background(Color.glideAccent)
                    .cornerRadius(7)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 6)
        }
        .tint(Color.glideAccent)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 340)
    }
}

