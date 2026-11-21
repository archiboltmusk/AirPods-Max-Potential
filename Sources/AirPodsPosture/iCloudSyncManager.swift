import Foundation
import Combine

@MainActor
public final class iCloudSyncManager: ObservableObject {
    public static let shared = iCloudSyncManager()
    
    @Published public var isSyncEnabled: Bool = true
    @Published public var lastSyncTimestamp: Date?
    @Published public var syncStatus: String = "Ready"
    
    private let kvStore = NSUbiquitousKeyValueStore.default
    
    private init() {
        setupSyncObserver()
    }
    
    private func setupSyncObserver() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pullLatestCloudData()
            }
        }
        kvStore.synchronize()
    }
    
    public func saveProfile(streak: Int, score: Double, baselinePitch: Double, baselineRoll: Double) {
        guard isSyncEnabled else { return }
        
        kvStore.set(Int64(streak), forKey: "posture_streak_days")
        kvStore.set(score, forKey: "posture_today_score")
        kvStore.set(baselinePitch, forKey: "posture_baseline_pitch")
        kvStore.set(baselineRoll, forKey: "posture_baseline_roll")
        kvStore.set(Date().timeIntervalSince1970, forKey: "posture_last_sync_epoch")
        
        kvStore.synchronize()
        lastSyncTimestamp = Date()
        syncStatus = "Synced at \(Date().formatted(date: .omitted, time: .standard))"
    }
    
    public func pullLatestCloudData() {
        let streak = kvStore.longLong(forKey: "posture_streak_days")
        let score = kvStore.double(forKey: "posture_today_score")
        let epoch = kvStore.double(forKey: "posture_last_sync_epoch")
        
        if epoch > 0 {
            lastSyncTimestamp = Date(timeIntervalSince1970: epoch)
            syncStatus = "Received Cloud Update (Streak: \(streak)d, Score: \(Int(score))%)"
        }
    }
}
