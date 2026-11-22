import Foundation
import IOKit.pwr_mgt
import Combine

/// macOS App Nap & System Idle Sleep Assertion Manager.
/// Prevents macOS Grand Central Dispatch and power management from throttling or freezing
/// background motion telemetry and overnight sleep tracking when the screen locks.
@MainActor
public final class AppNapPowerAssertionManager: ObservableObject {
    public static let shared = AppNapPowerAssertionManager()
    
    @Published public var isAssertionHeld: Bool = false
    @Published public var assertionTypeDescription: String = "Idle (No Power Assertion)"
    
    private var assertionID: IOPMAssertionID = 0
    
    private init() {}
    
    /// Acquires power assertion preventing background thread freeze
    public func acquireSleepTrackingAssertion(reason: String = "AirPods Posture & Sleep Monitoring") {
        guard !isAssertionHeld else { return }
        
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        
        if success == kIOReturnSuccess {
            isAssertionHeld = true
            assertionTypeDescription = "⚡️ App Nap Prevented: \(reason)"
        }
    }
    
    /// Releases assertion to let Mac enter deep standby when appropriate
    public func releaseAssertion() {
        guard isAssertionHeld else { return }
        
        let success = IOPMAssertionRelease(assertionID)
        if success == kIOReturnSuccess {
            isAssertionHeld = false
            assertionID = 0
            assertionTypeDescription = "💤 Power Assertion Released (0.0% CPU Standby)"
        }
    }
}
