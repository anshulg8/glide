import AppKit

/// Prompts user to move Glide to /Applications on first launch if run from Downloads, Desktop, etc.
@MainActor
enum InstallToApplications {
    @discardableResult
    static func promptAndMoveIfNeeded() -> Bool {
        let bundleURL = Bundle.main.bundleURL
        let bundlePath = bundleURL.path

        // Already running from /Applications
        guard !bundlePath.hasPrefix("/Applications/") else { return false }

        // Ignore if running from Xcode / SPM debug build directory
        guard !bundlePath.contains("/.build/") && !bundlePath.contains("/DerivedData/") else { return false }

        let appName = bundleURL.lastPathComponent
        let destination = "/Applications/\(appName)"

        let alert = NSAlert()
        alert.messageText = "Move Glide to Applications folder?"
        alert.informativeText = "Glide works best from the Applications folder so that launch at login and background edge gestures run reliably."
        alert.alertStyle = .informational
        alert.icon = NSApp.applicationIconImage

        alert.addButton(withTitle: "Move to Applications Folder")
        let cancelButton = alert.addButton(withTitle: "Don't Move")
        cancelButton.keyEquivalent = "\u{1b}"

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return false }

        // If an existing copy exists in /Applications, remove it first
        if FileManager.default.fileExists(atPath: destination) {
            do {
                try FileManager.default.removeItem(atPath: destination)
            } catch {
                // If permission denied, use admin script
                _ = runAdminScript("/bin/rm -rf \(quoted(destination))")
            }
        }

        // Try direct copy first
        var copySuccess = false
        do {
            try FileManager.default.copyItem(atPath: bundlePath, toPath: destination)
            copySuccess = true
        } catch {
            // If standard copy fails due to permissions, copy using admin privileges
            let copyScript = "/usr/bin/ditto \(quoted(bundlePath)) \(quoted(destination))"
            if runAdminScript(copyScript) {
                copySuccess = true
            }
        }

        guard copySuccess else {
            showError("Couldn't move Glide to /Applications. You can manually drag it into Applications.")
            return false
        }

        // Remove quarantine attribute so Gatekeeper doesn't block future launches
        _ = runShell("/usr/bin/xattr", ["-cr", destination])

        // Re-apply ad-hoc signature on destination
        _ = runShell("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", destination])

        // Launch the installed copy from /Applications and exit current instance
        let destURL = URL(fileURLWithPath: destination)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = true

        Task { @MainActor in
            _ = try? await NSWorkspace.shared.openApplication(at: destURL, configuration: config)
            try? await Task.sleep(nanoseconds: 500_000_000)
            exit(0)
        }

        return true
    }

    private static func quoted(_ string: String) -> String {
        return "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func runAdminScript(_ bashCommand: String) -> Bool {
        let script = "do shell script \"\(bashCommand.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
        var error: NSDictionary?
        guard let asObj = NSAppleScript(source: script) else { return false }
        _ = asObj.executeAndReturnError(&error)
        return error == nil
    }

    @discardableResult
    private static func runShell(_ launchPath: String, _ args: [String]) -> Int32 {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = args
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus
        } catch {
            return -1
        }
    }

    private static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Couldn't move to Applications"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
