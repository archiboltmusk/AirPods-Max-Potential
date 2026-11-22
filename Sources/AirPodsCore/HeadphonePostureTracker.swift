import Foundation
@preconcurrency import CoreMotion
import simd
import Combine

/// Reference-Grade Gimbal-Lock-Free Headphone Posture Tracker.
/// Uses Apple's simd quaternion algebra and Earth-gravity vector projection [0, 0, -1]
/// to eliminate gimbal lock, absorb individual AirPods ear-canal insertion angles,
/// and provide 85th-percentile upright gravity auto-calibration.
@MainActor
public final class HeadphonePostureTracker: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = HeadphonePostureTracker()
    
    private let motionManager = CMHeadphoneMotionManager()
    private let processingQueue = OperationQueue()
    
    // Baseline orientation stored as a unit quaternion (immune to gimbal lock)
    @Published public private(set) var baselineQuaternion: simd_quatd?
    
    // Sliding window buffer for 85th-percentile automatic upright calibration
    private var staticPitchSamples: [(timestamp: TimeInterval, quat: simd_quatd, rawPitch: Double)] = []
    public let calibrationWindowSeconds: TimeInterval = 180.0 // 3-minute rolling window
    
    // Published telemetry (in degrees)
    @Published public var relativePitchDeg: Double = 0.0   // Negative = forward head drop (slouch)
    @Published public var relativeRollDeg: Double = 0.0    // Lateral tilt
    @Published public var isCalibrated: Bool = false
    @Published public var isSlouching: Bool = false
    @Published public var isStill: Bool = false
    @Published public var sensorLocationText: String = "Auto Detect"
    
    public override init() {
        super.init()
        processingQueue.name = "com.archiboltmusk.headphoneMotion"
        processingQueue.maxConcurrentOperationCount = 1
    }
    
    public func startTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.startDeviceMotionUpdates(to: processingQueue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            Task { @MainActor [weak self] in
                self?.process(motion: motion)
            }
        }
    }
    
    public func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// Manual override if the user wants to snap calibration immediately
    public func calibrateNow(with motion: CMDeviceMotion) {
        let q = motion.attitude.simdQuaternion
        baselineQuaternion = q.normalized
        isCalibrated = true
    }
    
    /// Direct calibration using raw quaternion
    public func calibrateManual(quat: simd_quatd) {
        baselineQuaternion = quat.normalized
        isCalibrated = true
    }
    
    public func process(motion: CMDeviceMotion) {
        let currentQuat = motion.attitude.simdQuaternion.normalized
        let gravity = SIMD3<Double>(motion.gravity.x, motion.gravity.y, motion.gravity.z)
        let rotRate = SIMD3<Double>(motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
        let userAccel = SIMD3<Double>(motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
        
        // 1. Check for quasi-static stillness (gating out walking, nodding, talking)
        let still = simd_length(rotRate) < 0.05 && simd_length(userAccel) < 0.02
        self.isStill = still
        
        // 2. Auto-calibration via upper-percentile upright gravity tracking
        if !isCalibrated && still {
            updateAutoCalibration(timestamp: motion.timestamp, quat: currentQuat, gravity: gravity)
        }
        
        guard let qBase = baselineQuaternion else { return }
        
        // 3. Gimbal-lock-free relative rotation: q_rel = q_base^-1 * q_current
        let qRelative = simd_mul(qBase.inverse, currentQuat).normalized
        
        // 4. Project the Earth-down vector [0, 0, -1] into the calibrated head frame
        // In Core Motion's reference frame, Z points straight up (against gravity).
        // Rotating [0, 0, -1] by qRelative gives the gravity vector in the user's calibrated head coordinates.
        let calibratedGravity = qRelative.act(SIMD3<Double>(0, 0, -1))
        
        // 5. Sensor Location Normalization (Left vs Right earbud)
        var forwardSign: Double = -1.0
        var lateralSign: Double = 1.0
        
        switch motion.sensorLocation {
        case .headphoneLeft:
            self.sensorLocationText = "Left AirPod (Primary Hub)"
            forwardSign = -1.0
            lateralSign = 1.0
        case .headphoneRight:
            self.sensorLocationText = "Right AirPod (Primary Hub)"
            forwardSign = -1.0
            lateralSign = 1.0
        default:
            self.sensorLocationText = "Headphone IMU"
            forwardSign = -1.0
            lateralSign = 1.0
        }
        
        // 6. Extract gravity-referenced Pitch and Roll via 2-argument atan2 (no gimbal lock at ±90°)
        // Pitch: forward/backward tilt relative to the calibrated upright plane
        let pitchRad = atan2(forwardSign * calibratedGravity.y, -calibratedGravity.z)
        // Roll: left/right lateral tilt relative to the calibrated upright plane
        let rollRad = atan2(lateralSign * calibratedGravity.x, -calibratedGravity.z)
        
        let pitchDeg = pitchRad * 180.0 / .pi
        let rollDeg = rollRad * 180.0 / .pi
        
        self.relativePitchDeg = pitchDeg
        self.relativeRollDeg = rollDeg
        self.isSlouching = pitchDeg < -15.0 || abs(rollDeg) > 12.0
    }
    
    private func updateAutoCalibration(timestamp: TimeInterval, quat: simd_quatd, gravity: SIMD3<Double>) {
        // Compute raw elevation angle against Earth's gravity vector (independent of yaw drift)
        // Higher values correspond to a more upright head position
        let rawElevation = asin(simd_clamp(-gravity.y, -1.0, 1.0))
        
        staticPitchSamples.append((timestamp, quat, rawElevation))
        staticPitchSamples.removeAll { timestamp - $0.timestamp > calibrationWindowSeconds }
        
        // Wait until we have at least ~3-5 seconds of still samples
        guard staticPitchSamples.count >= 100 else { return }
        
        // Sort by raw elevation and pick the 85th percentile (natural upright posture, ignoring slumps)
        let sorted = staticPitchSamples.sorted { $0.rawPitch < $1.rawPitch }
        let targetIndex = Int(Double(sorted.count) * 0.85)
        
        baselineQuaternion = sorted[targetIndex].quat
        self.isCalibrated = true
    }
}

// MARK: - CoreMotion to SIMD Helper Extension
public extension CMAttitude {
    var simdQuaternion: simd_quatd {
        let q = self.quaternion
        return simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
    }
}
