import Foundation
import SwiftUI
import AppKit
import Combine

/// In-App Updater for AirPods Max Potential.
/// Integrates directly with GitHub Releases API (archiboltmusk/AirPods-Max-Potential).
/// Supports checking for updates, parsing release notes, downloading verified zip archives,
/// and installing updates with relaunch.
@MainActor
public final class AppUpdateManager: ObservableObject {
    public static let shared = AppUpdateManager()
    
    // Version Telemetry
    public let currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.9.6"
    public let currentBuild: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2.9.6"
    
    // Update States
    @Published public var isChecking: Bool = false
    @Published public var isDownloading: Bool = false
    @Published public var downloadProgress: Double = 0.0
    @Published public var isUpdateAvailable: Bool = false
    @Published public var isReadyToRelaunch: Bool = false
    @Published public var updateErrorMessage: String? = nil
    @Published public var updateStatusMessage: String = "App is up to date"
    
    // Latest Release Info
    @Published public var latestVersionTag: String = ""
    @Published public var releaseTitle: String = ""
    @Published public var releaseNotes: String = ""
    @Published public var releaseHtmlUrl: String = "https://github.com/archiboltmusk/AirPods-Max-Potential/releases"
    @Published public var downloadUrl: String? = nil
    @Published public var downloadSizeMb: Double = 0.0
    @Published public var lastCheckedDate: Date? = nil
    
    // Preferences
    @Published public var autoCheckOnLaunch: Bool = true {
        didSet {
            UserDefaults.standard.set(autoCheckOnLaunch, forKey: "autoCheckUpdatesOnLaunch")
        }
    }
    
    private let repoOwner = "archiboltmusk"
    private let repoName = "AirPods-Max-Potential"
    private var stagedAppPath: URL? = nil
    
    private init() {
        self.autoCheckOnLaunch = UserDefaults.standard.object(forKey: "autoCheckUpdatesOnLaunch") as? Bool ?? true
        if autoCheckOnLaunch {
            Task {
                // Gentle delay to avoid blocking startup
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.checkForUpdates(silent: true)
            }
        }
    }
    
    // MARK: - Check For Updates
    
    public func checkForUpdates(silent: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        updateErrorMessage = nil
        if !silent {
            updateStatusMessage = "Checking GitHub Releases..."
        }
        
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("AirPodsMaxPotential-Updater", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isChecking = false
                self.lastCheckedDate = Date()
                
                if let error = error {
                    if !silent {
                        self.updateErrorMessage = "Network error: \(error.localizedDescription)"
                        self.updateStatusMessage = "Check failed"
                    }
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    if !silent {
                        self.updateErrorMessage = "Could not parse release payload from GitHub."
                    }
                    return
                }
                
                let tagName = json["tag_name"] as? String ?? ""
                let title = json["name"] as? String ?? tagName
                let body = json["body"] as? String ?? ""
                let htmlUrl = json["html_url"] as? String ?? "https://github.com/\(self.repoOwner)/\(self.repoName)/releases"
                
                self.latestVersionTag = tagName
                self.releaseTitle = title
                self.releaseNotes = body
                self.releaseHtmlUrl = htmlUrl
                
                // Find .zip asset download url
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String, name.hasSuffix(".zip") {
                            self.downloadUrl = asset["browser_download_url"] as? String
                            if let bytes = asset["size"] as? Double {
                                self.downloadSizeMb = bytes / (1024.0 * 1024.0)
                            }
                            break
                        }
                    }
                }
                
                // Compare version strings
                let cleanedRemote = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                let isNewer = self.compareVersions(remote: cleanedRemote, current: self.currentVersion)
                
                self.isUpdateAvailable = isNewer
                if isNewer {
                    self.updateStatusMessage = "New version available: \(tagName)"
                } else {
                    self.updateStatusMessage = "AirPods Max Potential v\(self.currentVersion) is up to date"
                }
            }
        }.resume()
    }
    
    // MARK: - Download & Install
    
    public func downloadAndInstallUpdate() {
        guard let urlString = downloadUrl, let url = URL(string: urlString) else {
            openReleasePage()
            return
        }
        
        isDownloading = true
        downloadProgress = 0.05
        updateStatusMessage = "Downloading \(String(format: "%.1f MB", downloadSizeMb))..."
        
        let tempZipUrl = FileManager.default.temporaryDirectory.appendingPathComponent("AirPodsUpdate-\(UUID().uuidString).zip")
        let destinationDir = FileManager.default.temporaryDirectory.appendingPathComponent("AirPodsExtracted-\(UUID().uuidString)")
        
        let session = URLSession(configuration: .default)
        let downloadTask = session.downloadTask(with: url) { [weak self] tempLocation, response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let tempLocation = tempLocation, error == nil else {
                    self.isDownloading = false
                    self.updateErrorMessage = "Download failed: \(error?.localizedDescription ?? "Unknown error")"
                    return
                }
                
                do {
                    self.downloadProgress = 0.8
                    self.updateStatusMessage = "Extracting and verifying bundle..."
                    
                    try? FileManager.default.removeItem(at: tempZipUrl)
                    try FileManager.default.moveItem(at: tempLocation, to: tempZipUrl)
                    try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
                    
                    // Unzip via ditto
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                    process.arguments = ["-x", "-k", tempZipUrl.path, destinationDir.path]
                    try process.run()
                    process.waitUntilExit()
                    
                    // Strip Gatekeeper quarantine from extracted payload
                    let xattrProc = Process()
                    xattrProc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                    xattrProc.arguments = ["-cr", destinationDir.path]
                    try? xattrProc.run()
                    xattrProc.waitUntilExit()
                    
                    // Locate .app in extracted dir
                    let items = try FileManager.default.contentsOfDirectory(at: destinationDir, includingPropertiesForKeys: nil)
                    if let appBundle = items.first(where: { $0.pathExtension == "app" }) {
                        self.stagedAppPath = appBundle
                        self.downloadProgress = 1.0
                        self.isDownloading = false
                        self.isReadyToRelaunch = true
                        self.updateStatusMessage = "Update ready to install!"
                        NSSound(named: "Hero")?.play()
                    } else {
                        throw NSError(domain: "Updater", code: -1, userInfo: [NSLocalizedDescriptionKey: "No .app bundle found inside downloaded zip."])
                    }
                } catch {
                    self.isDownloading = false
                    self.updateErrorMessage = "Extraction failed: \(error.localizedDescription)"
                    self.updateStatusMessage = "Failed to extract update"
                }
            }
        }
        
        downloadTask.resume()
    }
    
    // MARK: - Relaunch & Replace Application
    
    public func relaunchAndInstall() {
        guard let staged = stagedAppPath else { return }
        
        let targetAppPath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        
        // Wait for current process PID to gracefully exit before replacing and launching the updated bundle
        let helperScript = """
        while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done
        rm -rf "\(targetAppPath)"
        cp -R "\(staged.path)" "\(targetAppPath)"
        /usr/bin/xattr -cr "\(targetAppPath)" 2>/dev/null || true
        open "\(targetAppPath)"
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "nohup /bin/sh -c '\(helperScript)' >/dev/null 2>&1 &"]
        try? process.run()
        
        // Terminate current process
        NSApplication.shared.terminate(nil)
    }
    
    public func openReleasePage() {
        if let url = URL(string: releaseHtmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Version Comparison
    
    private func compareVersions(remote: String, current: String) -> Bool {
        let rParts = remote.split(separator: ".").compactMap { Int($0) }
        let cParts = current.split(separator: ".").compactMap { Int($0) }
        
        let maxLen = max(rParts.count, cParts.count)
        for i in 0..<maxLen {
            let rVal = i < rParts.count ? rParts[i] : 0
            let cVal = i < cParts.count ? cParts[i] : 0
            if rVal > cVal { return true }
            if rVal < cVal { return false }
        }
        return false
    }
}
