import Foundation
import CoreMotion
import SwiftUI
import Combine

/// AirPods Wear State & Collarbone Neck-Rest Sentinel.
/// 1. Detects when AirPods Max or Pro are hung around the neck resting on collarbones,
///    suppressing false 45° slouch alarms.
/// 2. Validates device motion capability for connected audio gear (flags non-supported models).
@MainActor
public final class AirPodsWearStateSentinel: ObservableObject {
    public static let shared = AirPodsWearStateSentinel()
    
    @Published public var isRestingOnNeck: Bool = false
    @Published public var isDeviceMotionSupported: Bool = true
    @Published public var unsupportedModelBannerMessage: String? = nil
    @Published public var neckRestEventsCount: Int = 0
    @Published public var statusMessage: String = "Worn on Head (Tracking Active)"
    
    private var staticNeckPoseStartTime: Date?
    
    private init() {
        validateMotionSupport()
    }
    
    public func validateMotionSupport() {
        let available = CMHeadphoneMotionManager().isDeviceMotionAvailable
        self.isDeviceMotionSupported = available
        if !available {
            self.unsupportedModelBannerMessage = "Connected earphones do not support 6-DOF motion. Use AirPods Pro, AirPods 3/4, or AirPods Max, or enable Optical Fallback."
        } else {
            self.unsupportedModelBannerMessage = nil
        }
    }
    
    /// Evaluates raw pitch, roll, and kinetic stillness for neck-rest signature
    public func evaluateWearPose(pitch: Double, roll: Double, yaw: Double, kineticEnergy: Double, rotRateMagnitude: Double) {
        // Collarbone resting signature:
        // When AirPods Max or Pro hang on the neck:
        // - Earcups twist flat against chest: |roll| > 70° OR pitch is down <-35°
        // - User is stationary or walking, but head rotation relative to headphones is static (rotRate < 2.5 deg/s)
        let isCollarboneGeometry = (abs(roll) > 70.0 || pitch < -35.0)
        let isStillInEarcups = rotRateMagnitude < 3.5 && kineticEnergy < 0.15
        
        if isCollarboneGeometry && isStillInEarcups {
            if staticNeckPoseStartTime == nil {
                staticNeckPoseStartTime = Date()
            }
            
            // If held in neck-rest orientation for > 3.0 seconds, engage neck-rest mode
            if let start = staticNeckPoseStartTime, Date().timeIntervalSince(start) > 3.0 {
                if !isRestingOnNeck {
                    isRestingOnNeck = true
                    neckRestEventsCount += 1
                    statusMessage = "⏸️ Resting on Neck / Collarbone • Posture Alerts Paused"
                }
            }
        } else {
            staticNeckPoseStartTime = nil
            if isRestingOnNeck {
                isRestingOnNeck = false
                statusMessage = "🎧 Worn on Head • Posture Active"
            }
        }
    }
}
