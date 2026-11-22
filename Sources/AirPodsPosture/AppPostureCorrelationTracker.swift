import Foundation
import AppKit

public struct AppPostureStat: Identifiable {
    public let id: String // App Name
    public var totalSeconds: TimeInterval
    public var slouchSeconds: TimeInterval
    
    public var postureScore: Int {
        guard totalSeconds > 0 else { return 100 }
        let goodSecs = max(0, totalSeconds - slouchSeconds)
        return Int((goodSecs / totalSeconds) * 100.0)
    }
}

@MainActor
public final class AppPostureCorrelationTracker: ObservableObject {
    public static let shared = AppPostureCorrelationTracker()
    
    @Published public var currentAppName: String = "Desktop"
    @Published public var stats: [AppPostureStat] = []
    
    private var timer: Timer? = nil
    
    private init() {
        startTracking()
    }
    
    public func startTracking() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor [weak self] in
                self?.currentAppName = app.localizedName ?? "Desktop"
            }
        }
        self.currentAppName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Desktop"
    }
    
    public func recordSample(isSlouching: Bool, duration: TimeInterval = 1.0) {
        let frontApp = currentAppName
        if let idx = stats.firstIndex(where: { $0.id == frontApp }) {
            stats[idx].totalSeconds += duration
            if isSlouching {
                stats[idx].slouchSeconds += duration
            }
        } else {
            stats.append(AppPostureStat(id: frontApp, totalSeconds: duration, slouchSeconds: isSlouching ? duration : 0.0))
        }
        stats.sort { $0.totalSeconds > $1.totalSeconds }
    }
}
