import AppKit
import SwiftUI

public enum GestureIndicatorType {
    case brightness
    case volume
}

final class GestureOverlayModel: ObservableObject {
    @Published var type: GestureIndicatorType = .brightness
    @Published var value: Float = 0.5
    @Published var isMuted: Bool = false
}

struct GestureOverlayView: View {
    @ObservedObject var model: GestureOverlayModel

    var iconName: String {
        switch model.type {
        case .brightness:
            if model.value < 0.25 {
                return "sun.min.fill"
            } else {
                return "sun.max.fill"
            }
        case .volume:
            if model.isMuted || model.value <= 0.001 {
                return "speaker.slash.fill"
            } else if model.value < 0.33 {
                return "speaker.wave.1.fill"
            } else if model.value < 0.66 {
                return "speaker.wave.2.fill"
            } else {
                return "speaker.wave.3.fill"
            }
        }
    }

    var accentColor: Color {
        switch model.type {
        case .brightness:
            return Color.orange
        case .volume:
            return Color.blue
        }
    }

    var title: String {
        switch model.type {
        case .brightness: return "Brightness"
        case .volume: return model.isMuted ? "Muted" : "Volume"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(round(model.value * 100)))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.12))
                            .frame(height: 6)

                        Capsule()
                            .fill(accentColor)
                            .frame(width: max(6, geo.size.width * CGFloat(max(0, min(1, model.value)))), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 220, height: 58)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 6)
        }
    }
}

@MainActor
public final class GestureOverlayController {
    public static let shared = GestureOverlayController()

    private var panel: NSPanel?
    private var model = GestureOverlayModel()
    private var dismissWorkItem: DispatchWorkItem?

    private init() {
        setupPanel()
    }

    private func setupPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 58),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.isFloatingPanel = true
        p.hidesOnDeactivate = false
        p.ignoresMouseEvents = true
        p.isReleasedWhenClosed = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hosting = NSHostingView(rootView: GestureOverlayView(model: model))
        hosting.frame = NSRect(x: 0, y: 0, width: 220, height: 58)
        p.contentView = hosting
        self.panel = p
    }

    public func show(type: GestureIndicatorType, value: Float, isMuted: Bool = false) {
        guard GestureConfiguration.shared.showOverlay else { return }

        model.type = type
        model.value = value
        model.isMuted = isMuted

        guard let panel else { return }

        // Position overlay on screen that contains the mouse pointer
        let mouseLoc = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        if let frame = screen?.visibleFrame {
            let x = frame.midX - (220 / 2)
            let y = frame.minY + 90
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        // Set opacity to 1.0 immediately and order front
        panel.alphaValue = 1.0
        panel.orderFrontRegardless()

        let item = DispatchWorkItem { [weak self] in
            guard let self, let p = self.panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.25
                p.animator().alphaValue = 0.0
            }, completionHandler: {
                if p.alphaValue == 0.0 {
                    p.orderOut(nil)
                    p.alphaValue = 1.0
                }
            })
        }
        self.dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: item)
    }
}

