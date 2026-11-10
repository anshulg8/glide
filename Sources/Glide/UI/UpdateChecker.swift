import Foundation
import AppKit

/// Simple, zero-dependency update checker using GitHub's public Releases API.
@MainActor
public final class UpdateChecker: ObservableObject {
    public static let shared = UpdateChecker()

    @Published public private(set) var isChecking: Bool = false
    @Published public private(set) var availableUpdateVersion: String? = nil

    private let repoOwner = "anshulg8"
    private let repoName = "glide"

    private init() {}

    /// Current version from Info.plist (defaults to "1.0.0").
    public var currentVersion: String {
        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !ver.isEmpty {
            return ver
        }
        return "1.0.1"
    }

    /// Checks for updates against GitHub Releases.
    /// - Parameter explicit: If `true`, shows "Up to date" or error dialogs. If `false`, only alerts when an update is found.
    public func checkForUpdates(explicit: Bool = true) {
        guard !isChecking else { return }
        isChecking = true

        Task {
            defer { self.isChecking = false }
            do {
                let release = try await fetchLatestRelease()
                let remoteVersion = cleanVersion(release.tagName)
                let localVersion = cleanVersion(self.currentVersion)

                if isVersion(remoteVersion, newerThan: localVersion) {
                    self.availableUpdateVersion = remoteVersion
                    showUpdateAvailableAlert(
                        newVersion: remoteVersion,
                        releaseName: release.name ?? "Glide \(remoteVersion)",
                        releaseUrl: release.htmlUrl,
                        downloadUrl: release.zipAssetUrl
                    )
                } else {
                    self.availableUpdateVersion = nil
                    if explicit {
                        showUpToDateAlert(version: localVersion)
                    }
                }
            } catch {
                if explicit {
                    showErrorAlert(error: error)
                }
            }
        }
    }

    // MARK: - API Fetch

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlUrl: String
        let name: String?
        let body: String?
        let assets: [GitHubAsset]?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
            case name
            case body
            case assets
        }

        var zipAssetUrl: String? {
            assets?.first(where: { $0.name.lowercased().hasSuffix(".zip") })?.browserDownloadUrl
        }
    }

    private struct GitHubAsset: Decodable {
        let name: String
        let browserDownloadUrl: String

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // GitHub API requires a User-Agent header; requests without it receive HTTP 403 Forbidden
        request.setValue("Glide-App/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "UpdateChecker",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)."]
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    // MARK: - Version Comparison

    /// Strips leading 'v', 'V', whitespace, and builds clean version string.
    private func cleanVersion(_ raw: String) -> String {
        raw.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\r\n"))
    }

    /// Compares two semantic version strings (e.g. "1.0.1" vs "1.0.0").
    /// Returns true if v1 > v2.
    public func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        let p1 = v1.split(separator: ".").compactMap { Int($0) }
        let p2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(p1.count, p2.count)

        for i in 0..<maxCount {
            let n1 = i < p1.count ? p1[i] : 0
            let n2 = i < p2.count ? p2[i] : 0
            if n1 > n2 { return true }
            if n1 < n2 { return false }
        }
        return false
    }

    // MARK: - User Dialogs

    private func showUpdateAvailableAlert(
        newVersion: String,
        releaseName: String,
        releaseUrl: String,
        downloadUrl: String?
    ) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Glide \(newVersion) is now available (you have \(currentVersion)).\n\nWould you like to download the update?"
        alert.alertStyle = .informational

        // Buttons
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "View Release Notes")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            // Download update (prefer direct zip download URL, fallback to release page)
            let targetString = downloadUrl ?? releaseUrl
            if let targetUrl = URL(string: targetString) {
                NSWorkspace.shared.open(targetUrl)
            }
        case .alertSecondButtonReturn:
            // View release notes on GitHub
            if let notesUrl = URL(string: releaseUrl) {
                NSWorkspace.shared.open(notesUrl)
            }
        default:
            break
        }
    }

    private func showUpToDateAlert(version: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "You're Up to Date!"
        alert.informativeText = "Glide \(version) is currently the newest version available."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showErrorAlert(error: Error) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Check for Updates"
        alert.informativeText = "Unable to check for updates right now.\n\nPlease check your internet connection or visit the GitHub releases page directly."
        alert.alertStyle = .warning

        alert.addButton(withTitle: "Visit GitHub Releases")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let releasesUrl = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases") {
                NSWorkspace.shared.open(releasesUrl)
            }
        }
    }
}

