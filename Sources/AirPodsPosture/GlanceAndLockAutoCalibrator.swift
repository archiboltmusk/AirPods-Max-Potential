import Foundation
import Combine
import SwiftUI

/// "Glance & Lock" Zero-Click Autonomous Screen Calibration.
/// Magic zero-click onboarding: When you put on your AirPods and look at your Mac display
/// for 3 steady seconds, it automatically locks your neutral upright baseline with a gentle soft chime.
@MainActor
public final class GlanceAndLockAutoCalibrator: ObservableObject {
    public static let shared = GlanceAndLockAutoCalibrator()
    
    @Published public var isGlanceLockEnabled: Bool = true
    @Published public var glanceLockHoldProgress: Double = 0.0 // 0.0 to 1.0
    @Published public var hasLockedSessionBaseline: Bool = false
    @Published public var statusMessage: String = "Glance at your screen for 3s to auto-calibrate"
    
    private var steadyStartTime: Date?
    private var lockCooldownTime: Date = .distantPast
    
    private init() {}
    
    /// Evaluates raw head stability and screen-facing posture to trigger autonomous calibration
    public func evaluateGlance(pitch: Double, roll: Double, rotRate: Double, isConnected: Bool) {
        guard isGlanceLockEnabled && isConnected else {
            steadyStartTime = nil
            glanceLockHoldProgress = 0.0
            return
        }
        
        let now = Date()
        // Once locked, don't re-lock for at least 15 minutes unless reset
        guard now.timeIntervalSince(lockCooldownTime) > 900.0 || !hasLockedSessionBaseline else {
            return
        }
        
        // Steady gaze criteria:
        // - Pitch: Looking level (-4° to +8°)
        // - Roll: Level shoulders (< 4°)
        // - Rotation: Minimal head jitter (< 1.8 deg/s)
        let isLevelGaze = (pitch >= -4.5 && pitch <= 8.5) && abs(roll) < 4.5
        let isStill = rotRate < 1.8
        
        if isLevelGaze && isStill {
            if steadyStartTime == nil {
                steadyStartTime = now
            }
            
            let elapsed = now.timeIntervalSince(steadyStartTime!)
            glanceLockHoldProgress = min(1.0, elapsed / 3.0)
            
            if elapsed >= 3.0 {
                executeGlanceLock()
            }
        } else {
            steadyStartTime = nil
            glanceLockHoldProgress = 0.0
        }
    }
    
    private func executeGlanceLock() {
        steadyStartTime = nil
        glanceLockHoldProgress = 1.0
        hasLockedSessionBaseline = true
        lockCooldownTime = Date()
        
        // Execute calibration lock
        let success = MotionManager.shared.calibrateCurrentPosture()
        if success {
            statusMessage = "✨ Calibrated: Locked to your screen"
            DynamicIslandNotchHaloManager.shared.triggerExpansion(
                message: "Glance & Lock: Calibrated to Display",
                autoDismissSeconds: 3.0
            )
        }
    }
    
    public func resetLock() {
        hasLockedSessionBaseline = false
        lockCooldownTime = .distantPast
        glanceLockHoldProgress = 0.0
        steadyStartTime = nil
        statusMessage = "Glance at screen for 3s to auto-calibrate"
    }
}
