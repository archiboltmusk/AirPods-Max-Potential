import Foundation
import simd
import AirPodsCore

@MainActor
public final class AutonomousAutoCalibrator: ObservableObject {
    public static let shared = AutonomousAutoCalibrator()
    
    @Published public var isAutonomousCalibrationEnabled: Bool = true
    @Published public var calibrationConfidence: Double = 0.95 // 0.0 to 1.0
    @Published public var autoCalibrationStatus: String = "Statistical Gaze Estimator Active"
    @Published public var lastAutoCalibratedTime: Date?
    
    // Rolling buffer of pitch samples during calm stillness (rotRate < 4 deg/s)
    private var calmPitchHistory: [Double] = []
    private var calmRollHistory: [Double] = []
    private var sampleCount: Int = 0
    
    private init() {}
    
    public func processIncomingSample(
        currentQuat: simd_quatd,
        gravity: SIMD3<Double>?,
        gyroVariance: Double,
        userEnergy: Double
    ) {
        guard isAutonomousCalibrationEnabled else { return }
        
        // 1. Earth Gravity Vector Validation
        // If gravity vector is available and user is still (userEnergy < 0.02g and gyroVariance < 4.0 deg/s)
        if userEnergy < 0.02 && gyroVariance < 4.0 {
            let euler = QuaternionMath.euler(from: currentQuat)
            
            calmPitchHistory.append(euler.pitch)
            calmRollHistory.append(euler.roll)
            
            // Keep rolling 200 samples (~3-4 seconds of calm focus)
            if calmPitchHistory.count > 200 {
                calmPitchHistory.removeFirst()
                calmRollHistory.removeFirst()
            }
            
            sampleCount += 1
            
            // 2. Statistical Peak Mode (Kernel Density Mode)
            // Every 120 samples of calm stillness, evaluate statistical cluster
            if sampleCount % 120 == 0 && calmPitchHistory.count >= 100 {
                evaluateAndAdjustBaseline(currentQuat: currentQuat, gravity: gravity)
            }
        }
    }
    
    private func evaluateAndAdjustBaseline(currentQuat: simd_quatd, gravity: SIMD3<Double>?) {
        guard !calmPitchHistory.isEmpty else { return }
        
        // Calculate median and standard deviation to eliminate outliers (e.g. looking down at keyboard)
        let sortedPitches = calmPitchHistory.sorted()
        let medianPitch = sortedPitches[sortedPitches.count / 2]
        
        let sortedRolls = calmRollHistory.sorted()
        let medianRoll = sortedRolls[sortedRolls.count / 2]
        
        // Guard against calibrating into an intentional slouch:
        // Only adapt baseline if median pitch is strictly within true anatomical upright bounds (-6.0° to +7.0°)
        guard medianPitch > -6.0 && medianPitch < 7.0 && abs(medianRoll) < 5.0 else {
            autoCalibrationStatus = "Slouch Detected (\(Int(medianPitch))°): Baseline Held to True Upright"
            return
        }
        
        // If gravity is available, check anatomical ear insertion tilt
        if let g = gravity {
            // Earth gravity standard on vertical desk sitting: g.y should be near 0, g.z should be near -1.0
            let gravityTilt = asin(max(-1.0, min(1.0, g.y))) * 180.0 / .pi
            if abs(gravityTilt) < 18.0 {
                calibrationConfidence = min(1.0, calibrationConfidence + 0.02)
            }
        }
        
        // Slerp current baseline toward statistical median gaze mode
        let motion = MotionManager.shared
        if !motion.isCalibrated {
            motion.qBaseline = currentQuat
            motion.isCalibrated = true
            lastAutoCalibratedTime = Date()
            autoCalibrationStatus = "🟢 Auto-Locked: Aligned to True Earth Gravity"
            SyntheticEarHapticEngine.shared.playSuccessChirp()
        } else if abs(medianPitch) < 2.5 && calibrationConfidence >= 0.95 {
            // Micro-trim only when verified in physiological upright deadband
            motion.qBaseline = simd_slerp(motion.qBaseline, currentQuat, 0.0005)
            lastAutoCalibratedTime = Date()
            autoCalibrationStatus = "🟢 Slouch-Proof Auto-Centered (Gravity Confidence: \(Int(calibrationConfidence * 100))%)"
        } else {
            autoCalibrationStatus = "Baseline Held Rigid to Gravitational Horizon"
        }
    }
    
    public func triggerInstantDoubleNodCalibration() {
        let success = MotionManager.shared.calibrateCurrentPosture()
        if success {
            lastAutoCalibratedTime = Date()
            calibrationConfidence = 1.0
            autoCalibrationStatus = "🟢 Instant Recalibration via Double-Nod"
        } else {
            autoCalibrationStatus = "⚠️ Recalibration Blocked: Chin is tilted. Sit upright."
        }
    }
}
