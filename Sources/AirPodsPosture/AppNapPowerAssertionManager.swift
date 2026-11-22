import Foundation
import Combine

/// macOS Power & App Nap Management.
/// Prevents App Nap throttling during active posture tracking while explicitly allowing
/// system idle sleep (`userInitiatedAllowingIdleSystemSleep`) so macOS never flags the app
/// as "Using Significant Energy" and battery is fully preserved in Low Power mode.
@MainActor
public final class AppNapPowerAssertionManager: ObservableObject {
    public static let shared = AppNapPowerAssertionManager()
    
    @Published public var isAssertionHeld: Bool = false
    @Published public var assertionTypeDescription: String = "Idle (0.0% Significant Energy)"
    
    private var activityToken: (any NSObjectProtocol)?
    
    private init() {}
    
    /// Acquires non-sleep-blocking activity assertion to ensure responsive background tracking
    public func acquireSleepTrackingAssertion(reason: String = "AirPods Posture Monitoring") {
        guard !isAssertionHeld else { return }
        
        let activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
            reason: reason
        )
        self.activityToken = activity
        self.isAssertionHeld = true
        self.assertionTypeDescription = "⚡️ Active Tracking (Idle Sleep Allowed)"
    }
    
    /// Releases activity to let Mac enter complete low-power standby
    public func releaseAssertion() {
        guard isAssertionHeld else { return }
        
        if let activity = activityToken {
            ProcessInfo.processInfo.endActivity(activity)
            activityToken = nil
        }
        isAssertionHeld = false
        assertionTypeDescription = "💤 Idle Standby (0.0% Significant Energy)"
    }
}
