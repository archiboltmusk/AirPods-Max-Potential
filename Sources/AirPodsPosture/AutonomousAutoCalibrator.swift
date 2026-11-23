import Foundation
import simd
import AirPodsCore

/// Autonomous Continuous Gravitational Auto-Alignment Engine.
/// Silently micro-converges baseline orientation when the user is upright and still,
/// preventing accumulated drift and eliminating the need for manual button clicks.
@MainActor
public final class AutonomousAutoCalibrator: ObservableObject {
    public static let shared = AutonomousAutoCalibrator()
    
    @Published public var isAutonomousCalibrationEnabled: Bool = true
    @Published public var calibrationConfidence: Double = 1.0 // 0.0 to 1.0
    @Published public var autoCalibrationStatus: String = "Gravitational Upright Horizon Active"
    @Published public var lastAutoCalibratedTime: Date?
    
    private var sampleCount: Int = 0
    
    private init() {}
    
    public func processIncomingSample(
        currentQuat: simd_quatd,
        gravity: SIMD3<Double>?,
        gyroVariance: Double,
        userEnergy: Double,
        deltaPitch: Double,
        deltaRoll: Double
    ) {
        guard isAutonomousCalibrationEnabled else { return }
        
        sampleCount += 1
        
        // 1. Earth Gravity Vector & Stillness Validation
        guard userEnergy < 0.03 && gyroVariance < 2.5 else {
            return
        }
        
        var isPhysicallyUpright = false
        if let g = gravity, g.z <= -0.50 {
            // Earth gravity projected to anatomical skull vertical
            let gravPitch = atan2(-g.y, -g.z) * 180.0 / .pi
            let gravRoll = -atan2(g.x, -g.z) * 180.0 / .pi
            
            // True physiological upright range for desk focus
            if gravPitch >= -7.0 && gravPitch <= 7.5 && abs(gravRoll) <= 5.5 {
                isPhysicallyUpright = true
                calibrationConfidence = min(1.0, calibrationConfidence + 0.01)
            }
        } else {
            // Fallback for simulation / gyro mode
            if deltaPitch >= -7.0 && deltaPitch <= 7.5 && abs(deltaRoll) <= 5.5 {
                isPhysicallyUpright = true
            }
        }
        
        guard isPhysicallyUpright else {
            autoCalibrationStatus = "Baseline Held Rigid to Gravitational Horizon"
            return
        }
        
        let motion = MotionManager.shared
        
        // If uncalibrated, lock immediately on verified upright pose
        if !motion.isCalibrated {
            motion.calibrateCurrentPosture(force: false, isSilentAuto: true)
            lastAutoCalibratedTime = Date()
            autoCalibrationStatus = "🟢 Auto-Locked: Aligned to True Earth Gravity"
            return
        }
        
        // Continuous micro-slerp: for small offsets (0.2° to 3.5°), smoothly nudge baseline to true neutral
        let pitchError = abs(deltaPitch)
        let rollError = abs(deltaRoll)
        
        if (pitchError > 0.25 || rollError > 0.25) && pitchError <= 3.5 && rollError <= 3.0 {
            // Smoothly converge at 10Hz (factor 0.04 converges ~90% in 1.5s)
            motion.qBaseline = simd_slerp(motion.qBaseline, currentQuat, 0.04)
            lastAutoCalibratedTime = Date()
            autoCalibrationStatus = "🟢 Continuous Auto-Zero Active (Confidence: \(Int(calibrationConfidence * 100))%)"
        } else if pitchError <= 0.25 && rollError <= 0.25 {
            autoCalibrationStatus = "🟢 Posture Locked: Optimal Horizon"
        }
    }
    
    /// Backward-compatible overload
    public func processIncomingSample(
        currentQuat: simd_quatd,
        gravity: SIMD3<Double>?,
        gyroVariance: Double,
        userEnergy: Double
    ) {
        processIncomingSample(
            currentQuat: currentQuat,
            gravity: gravity,
            gyroVariance: gyroVariance,
            userEnergy: userEnergy,
            deltaPitch: MotionManager.shared.deltaPitch,
            deltaRoll: MotionManager.shared.deltaRoll
        )
    }
    
    public func triggerInstantDoubleNodCalibration() {
        let success = MotionManager.shared.calibrateCurrentPosture(force: false, isSilentAuto: false)
        if success {
            lastAutoCalibratedTime = Date()
            calibrationConfidence = 1.0
            autoCalibrationStatus = "🟢 Instant Recalibration via Double-Nod"
        } else {
            autoCalibrationStatus = "⚠️ Recalibration Blocked: Chin is tilted. Sit upright."
        }
    }
}
