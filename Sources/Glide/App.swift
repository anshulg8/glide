import SwiftUI
import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure accessory app without dock icon
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()

        // Start trackpad gesture manager
        TrackpadGestureManager.shared.start()

        NSLog("[Glide] Application initialized.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        TrackpadGestureManager.shared.stop()
    }

    // MARK: - Status Item & Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Render crisp menu bar template icon
        let icon = createMenuBarIcon()
        button.image = icon
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func createMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let trackpadRect = CGRect(x: 2, y: 3, width: 14, height: 12)
            let path = CGPath(roundedRect: trackpadRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)

            // Outline of trackpad
            ctx.setLineWidth(1.2)
            NSColor.labelColor.setStroke()
            ctx.addPath(path)
            ctx.strokePath()

            // Left edge indicator bar
            let leftBar = CGRect(x: 3.2, y: 5.5, width: 1.5, height: 7)
            ctx.addPath(CGPath(roundedRect: leftBar, cornerWidth: 0.5, cornerHeight: 0.5, transform: nil))
            ctx.fillPath()

            // Right edge indicator bar
            let rightBar = CGRect(x: 13.3, y: 5.5, width: 1.5, height: 7)
            ctx.addPath(CGPath(roundedRect: rightBar, cornerWidth: 0.5, cornerHeight: 0.5, transform: nil))
            ctx.fillPath()

            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Popover

    private func setupPopover() {
        let p = NSPopover()
        p.contentSize = NSSize(width: 320, height: 530)
        p.behavior = .transient
        p.animates = true
        p.contentViewController = NSHostingController(rootView: MenuBarPopupView())
        self.popover = p
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let p = popover else { return }

        let currentEvent = NSApp.currentEvent
        if currentEvent?.type == .rightMouseUp {
            showContextMenu(button: button)
            return
        }

        if p.isShown {
            p.performClose(sender)
        } else {
            p.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            p.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu(button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettingsWindow), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Glide", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openSettingsWindow() {
        if settingsWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 530),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.center()
            win.title = "Glide Settings"
            win.isReleasedWhenClosed = false
            let hosting = NSHostingView(
                rootView: SettingsView(
                    onBack: { [weak win] in win?.close() },
                    onQuit: { NSApp.terminate(nil) }
                )
            )
            win.contentView = hosting
            settingsWindow = win
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

