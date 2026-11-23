import Foundation
import Combine
import SwiftUI
import simd
import AirPodsCore

/// "Glance & Lock" Zero-Click Autonomous Screen Calibration & Auto-Recovery.
/// When you put on AirPods or sit straight facing your Mac display for 2 steady seconds,
/// it automatically locks or restores your neutral upright baseline with a gentle tactile haptic.
@MainActor
public final class GlanceAndLockAutoCalibrator: ObservableObject {
    public static let shared = GlanceAndLockAutoCalibrator()
    
    @Published public var isGlanceLockEnabled: Bool = true
    @Published public var glanceLockHoldProgress: Double = 0.0 // 0.0 to 1.0
    @Published public var hasLockedSessionBaseline: Bool = false
    @Published public var statusMessage: String = "Glance at your screen to auto-calibrate"
    @Published public var lastAutoCalibratedTime: Date?
    
    private var steadyStartTime: Date?
    private var lockCooldownTime: Date = .distantPast
    private let cooldownDuration: Double = 10.0 // 10s debounce after calibration
    private let requiredHoldDuration: Double = 2.0 // 2.0 seconds of steady upright gaze
    
    private init() {}
    
    /// Evaluates raw head stability and screen-facing posture to trigger autonomous calibration
    public func evaluate(
        currentQuat: simd_quatd,
        gravity: SIMD3<Double>?,
        deltaPitch: Double,
        deltaRoll: Double,
        rotRate: Double,
        userEnergy: Double,
        isConnected: Bool
    ) {
        guard isGlanceLockEnabled && isConnected else {
            if glanceLockHoldProgress > 0 {
                steadyStartTime = nil
                glanceLockHoldProgress = 0.0
            }
            return
        }
        
        let now = Date()
        
        // Cooldown debounce: after auto-aligning, wait 10s before triggering again
        guard now.timeIntervalSince(lockCooldownTime) > cooldownDuration else {
            return
        }
        
        // 1. Physical Upright Determination via Absolute Earth Gravity
        var isUprightPhysically = false
        if let g = gravity {
            // AirPods must be worn in-ear (gravity pointing predominantly down through Z)
            if g.z <= -0.50 {
                // Pitch and Roll relative to Earth's gravitational down vector
                let gravPitch = atan2(-g.y, -g.z) * 180.0 / .pi
                let gravRoll = -atan2(g.x, -g.z) * 180.0 / .pi
                
                // Physiological desk-viewing bounds: gaze straight ahead at monitor
                if gravPitch >= -7.0 && gravPitch <= 7.5 && abs(gravRoll) <= 5.5 {
                    isUprightPhysically = true
                }
            }
        } else {
            // Fallback when gravity is unavailable (e.g. simulated mode)
            if deltaPitch >= -7.0 && deltaPitch <= 7.5 && abs(deltaRoll) <= 5.5 {
                isUprightPhysically = true
            }
        }
        
        // 2. Physical Stillness Determination (user is seated, focused on screen)
        let isStill = rotRate < 2.5 && userEnergy < 0.035
        
        // 3. Misalignment Check: Does calibration actually need to be fixed?
        let motion = MotionManager.shared
        let isMisaligned = !motion.isCalibrated || abs(deltaPitch) >= 1.2 || abs(deltaRoll) >= 1.2
        
        // 4. Progress or Execution
        if isUprightPhysically && isStill && isMisaligned {
            if steadyStartTime == nil {
                steadyStartTime = now
            }
            
            let elapsed = now.timeIntervalSince(steadyStartTime!)
            glanceLockHoldProgress = min(1.0, elapsed / requiredHoldDuration)
            statusMessage = "Holding upright gaze: \(String(format: "%.1f", max(0, requiredHoldDuration - elapsed)))s"
            
            if elapsed >= requiredHoldDuration {
                executeGlanceLock()
            }
        } else {
            steadyStartTime = nil
            if glanceLockHoldProgress > 0.0 {
                glanceLockHoldProgress = 0.0
            }
        }
    }
    
    /// Backward-compatible wrapper
    public func evaluateGlance(pitch: Double, roll: Double, rotRate: Double, isConnected: Bool) {
        evaluate(
            currentQuat: MotionManager.shared.qBaseline,
            gravity: SIMD3<Double>(MotionManager.shared.gravityX, MotionManager.shared.gravityY, MotionManager.shared.gravityZ),
            deltaPitch: pitch,
            deltaRoll: roll,
            rotRate: rotRate,
            userEnergy: MotionManager.shared.totalKineticEnergy,
            isConnected: isConnected
        )
    }
    
    private func executeGlanceLock() {
        steadyStartTime = nil
        glanceLockHoldProgress = 0.0
        hasLockedSessionBaseline = true
        lockCooldownTime = Date()
        lastAutoCalibratedTime = Date()
        
        // Execute silent autonomous calibration lock
        let success = MotionManager.shared.calibrateCurrentPosture(force: false, isSilentAuto: true)
        if success {
            statusMessage = "✨ Auto-Aligned: Posture Centered"
        }
    }
    
    public func resetLock() {
        hasLockedSessionBaseline = false
        lockCooldownTime = .distantPast
        glanceLockHoldProgress = 0.0
        steadyStartTime = nil
        statusMessage = "Glance at screen to auto-calibrate"
    }
    
    #if DEBUG
    public func setSteadyStartTimeForTesting(_ date: Date) {
        self.steadyStartTime = date
    }
    #endif
}
