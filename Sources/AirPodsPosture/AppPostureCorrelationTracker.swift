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
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleCurrentApp()
            }
        }
    }
    
    private func sampleCurrentApp() {
        let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Desktop"
        self.currentAppName = frontApp
        
        let isSlouching = (MotionManager.shared.postureState == .slouching)
        let isTracking = MotionManager.shared.isTracking && MotionManager.shared.isConnected
        guard isTracking else { return }
        
        if let idx = stats.firstIndex(where: { $0.id == frontApp }) {
            stats[idx].totalSeconds += 2.0
            if isSlouching {
                stats[idx].slouchSeconds += 2.0
            }
        } else {
            stats.append(AppPostureStat(id: frontApp, totalSeconds: 2.0, slouchSeconds: isSlouching ? 2.0 : 0.0))
        }
        
        // Sort by total time spent
        stats.sort { $0.totalSeconds > $1.totalSeconds }
    }
}
