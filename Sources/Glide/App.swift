import SwiftUI
import AppKit

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    public static private(set) var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?

    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?
    private var lastCloseTime: TimeInterval = 0

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        AppDelegate.shared = delegate
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Offer to move to /Applications if running from Downloads/Desktop
        if InstallToApplications.promptAndMoveIfNeeded() {
            return
        }

        // Ensure accessory app without dock icon
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupMainMenu()
        installLocalKeyMonitor()
        updateAppearance()

        NotificationCenter.default.addObserver(
            forName: Notification.Name("GlideAppearanceChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateAppearance()
            }
        }

        // Start trackpad gesture manager
        TrackpadGestureManager.shared.start()

        // Check for updates in background after startup (if enabled in settings)
        if GestureConfiguration.shared.autoCheckUpdates {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                UpdateChecker.shared.checkForUpdates(explicit: false)
            }
        }

        NSLog("[Glide] Application initialized.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        removeGlobalClickMonitor()
        if let m = localKeyMonitor {
            NSEvent.removeMonitor(m)
            localKeyMonitor = nil
        }
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
        p.contentSize = NSSize(width: 320, height: 580)
        p.behavior = .transient
        p.animates = true
        p.delegate = self
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

        let isVisible = p.isShown && (p.contentViewController?.view.window?.isVisible == true)
        let timeSinceClose = ProcessInfo.processInfo.systemUptime - lastCloseTime

        if isVisible || timeSinceClose < 0.25 {
            closePopover()
        } else {
            openPopover(button: button)
        }
    }

    private func openPopover(button: NSStatusBarButton) {
        guard let p = popover else { return }
        updateAppearance()
        // Always reset to main tab when opening
        NotificationCenter.default.post(name: Notification.Name("GlideResetToMain"), object: nil)
        p.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        p.contentViewController?.view.window?.makeKey()
        installGlobalClickMonitor()
    }

    func closePopover() {
        lastCloseTime = ProcessInfo.processInfo.systemUptime
        guard let p = popover else { return }
        p.close()
        removeGlobalClickMonitor()
        NotificationCenter.default.post(name: Notification.Name("GlideResetToMain"), object: nil)
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        lastCloseTime = ProcessInfo.processInfo.systemUptime
        removeGlobalClickMonitor()
        NotificationCenter.default.post(name: Notification.Name("GlideResetToMain"), object: nil)
    }

    // MARK: - Appearance & Theme Synchronization

    func updateAppearance() {
        let mode = GestureConfiguration.shared.appearanceMode
        let appKitAppearance: NSAppearance? = switch mode {
        case "light": NSAppearance(named: .aqua)
        case "dark": NSAppearance(named: .darkAqua)
        default: nil
        }

        popover?.appearance = appKitAppearance
        aboutWindow?.appearance = appKitAppearance
        settingsWindow?.appearance = appKitAppearance
    }

    // MARK: - Main Menu & Keyboard Monitors

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Glide")

        let aboutItem = NSMenuItem(title: "About Glide", action: #selector(openAboutWindow), keyEquivalent: "")
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettingsWindow), keyEquivalent: ",")
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(closeActiveWindow), keyEquivalent: "w")
        let quitItem = NSMenuItem(title: "Quit Glide", action: #selector(requestQuitConfirmation), keyEquivalent: "q")

        appMenu.addItem(aboutItem)
        appMenu.addItem(settingsItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(closeItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func installLocalKeyMonitor() {
        if localKeyMonitor != nil { return }

        // Persistent local monitor: handles ⌘Q, ⌘W, ⌘,, and Escape across all Glide windows and popovers
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            let isCmd = event.modifierFlags.contains(.command)
            let char = event.charactersIgnoringModifiers?.lowercased()

            // ⌘Q: Request quit with confirmation dialog
            if isCmd && char == "q" {
                self.requestQuitConfirmation()
                return nil
            }

            // ⌘W: Close frontmost window or popover
            if isCmd && char == "w" {
                self.closeActiveWindow()
                return nil
            }

            // ⌘,: Toggle Settings
            if isCmd && char == "," {
                NotificationCenter.default.post(name: Notification.Name("GlideToggleSettings"), object: nil)
                return nil
            }

            // Escape: Dismiss active window or popover
            if event.keyCode == 53 {
                self.closeActiveWindow()
                return nil
            }

            return event
        }
    }

    // MARK: - Outside Click Monitor

    private func installGlobalClickMonitor() {
        removeGlobalClickMonitor()

        // Global monitor: dismisses popover when user clicks outside
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let p = self.popover else { return }
            guard p.isShown && (p.contentViewController?.view.window?.isVisible == true) else { return }

            let mouseLoc = NSEvent.mouseLocation

            // If click is on the status item button itself, ignore (togglePopover handles it)
            if let button = self.statusItem?.button, let win = button.window {
                let rectInWin = button.convert(button.bounds, to: nil)
                let buttonScreenRect = win.convertToScreen(rectInWin)
                if buttonScreenRect.contains(mouseLoc) {
                    return
                }
            }

            // If click is inside the popover window, do not dismiss
            if let popWin = p.contentViewController?.view.window, popWin.frame.contains(mouseLoc) {
                return
            }

            DispatchQueue.main.async {
                self.closePopover()
            }
        }
    }

    private func removeGlobalClickMonitor() {
        if let m = globalClickMonitor {
            NSEvent.removeMonitor(m)
            globalClickMonitor = nil
        }
    }

    // MARK: - Context Menu & Actions

    private func showContextMenu(button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettingsWindow), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "About Glide…", action: #selector(openAboutWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Glide", action: #selector(requestQuitConfirmation), keyEquivalent: "q"))
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func checkForUpdates() {
        closePopover()
        UpdateChecker.shared.checkForUpdates(explicit: true)
    }

    @objc func closeActiveWindow() {
        if let win = aboutWindow, win.isVisible {
            win.close()
            return
        }
        if let win = settingsWindow, win.isVisible {
            win.close()
            return
        }
        if let p = popover, p.isShown {
            closePopover()
            return
        }
    }

    @objc func openSettingsWindow() {
        closePopover()
        if settingsWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 580),
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
                    onQuit: { [weak self] in self?.quitApp() }
                )
            )
            win.contentView = hosting
            settingsWindow = win
        }
        updateAppearance()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAboutWindow() {
        closePopover()
        if aboutWindow == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 310),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            win.center()
            win.title = "About Glide"
            win.isReleasedWhenClosed = false
            let hosting = NSHostingView(rootView: AboutView(onClose: { [weak win] in win?.close() }))
            win.contentView = hosting
            aboutWindow = win
        }
        updateAppearance()
        aboutWindow?.center()
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        requestQuitConfirmation()
    }

    @objc func requestQuitConfirmation() {
        let isAnyViewVisible = (popover?.isShown == true) || (aboutWindow?.isVisible == true) || (settingsWindow?.isVisible == true)
        if isAnyViewVisible {
            NotificationCenter.default.post(name: Notification.Name("GlideRequestQuitConfirmation"), object: nil)
        } else {
            let alert = NSAlert()
            alert.messageText = "Quit Glide?"
            alert.informativeText = "Trackpad edge gestures will stop working until you relaunch Glide."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit Glide")
            alert.addButton(withTitle: "Cancel")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                NSApp.terminate(nil)
            }
        }
    }
}
