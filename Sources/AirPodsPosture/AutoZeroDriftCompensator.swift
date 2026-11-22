import Foundation
import simd
import Combine

/// Continuous Center-Seeking EWMA Yaw Drift Compensator & Slouch Guard.
/// 1. Continuously compensates for magnetometer-less gyro yaw drift using an Exponentially
///    Weighted Moving Average (EWMA) model with a 20-minute half-life.
/// 2. Slouch Guard: Prevents locking a slouched posture as the "upright baseline".
@MainActor
public final class AutoZeroDriftCompensator: ObservableObject {
    public static let shared = AutoZeroDriftCompensator()
    
    @Published public var isDriftCompensationEnabled: Bool = true
    @Published public var accumulatedYawDriftOffsetDegrees: Double = 0.0
    @Published public var lastAutoZeroDate: Date = Date()
    @Published public var statusMessage: String = "Continuous Yaw Alignment Active"
    
    // EWMA smoothing factor: for 60Hz telemetry, 0.00008 corresponds to ~20 min half-life
    private let alphaDrift: Double = 0.00008
    private var smoothedYawOffset: Double = 0.0
    
    private init() {}
    
    /// Updates rolling center-seeking baseline when user is relatively still facing display
    public func updateDrift(currentYaw: Double, userKineticEnergy: Double, rotRate: Double) {
        guard isDriftCompensationEnabled else { return }
        
        // Only adapt when user is in steady-state focus (< 2 deg/sec rotation)
        guard rotRate < 2.0 && userKineticEnergy < 0.08 else { return }
        
        // Smoothly pull offset toward the current yaw (center-seeking display anchor)
        smoothedYawOffset = (1.0 - alphaDrift) * smoothedYawOffset + alphaDrift * currentYaw
        accumulatedYawDriftOffsetDegrees = smoothedYawOffset
    }
    
    /// Applies drift compensation to incoming relative yaw
    public func compensatedYaw(_ rawRelativeYaw: Double) -> Double {
        guard isDriftCompensationEnabled else { return rawRelativeYaw }
        return rawRelativeYaw - smoothedYawOffset
    }
    
    /// Validates if a calibration attempt is anatomically upright
    public func validateCalibrationPose(pitch: Double, roll: Double) -> (isValid: Bool, warning: String?) {
        if pitch < -6.5 {
            return (false, "Slouch Detected: Head tilted down \(Int(abs(pitch)))°. Lift chin to horizon.")
        }
        if pitch > 10.0 {
            return (false, "Head tilted backward \(Int(pitch))°. Level gaze before calibrating.")
        }
        if abs(roll) > 6.0 {
            return (false, "Head tilted sideways \(Int(abs(roll)))°. Level shoulders.")
        }
        return (true, nil)
    }
}
