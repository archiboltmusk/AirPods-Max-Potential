import Foundation
import simd

/// Biomechanical IMU Kinematic Classifier & Anterior Translation (ZUPT) Engine.
/// Solves the core physics limitation of 6-axis IMUs:
/// 1. Differentiates angular pitch (head drop) from anterior translation ("Tech Neck" chin-poking).
/// 2. Uses windowed Zero-Velocity Update (ZUPT) double integration to calculate forward displacement without drift.
/// 3. Identifies full-torso bending vs unilateral side slouching (resting on one elbow).
/// 4. Filters out walking cadence (1.5–2.2 Hz vertical heel-strikes) to switch between Desk and Walking modes.
public enum KinematicPosturePattern: String, Sendable, Codable {
    case optimal = "Optimal Neutral Alignment"
    case headDrop = "Cervical Head Drop (Looking Down)"
    case techNeck = "Tech Neck (Anterior Chin Poke, Level Eyes)"
    case fullTorsoBend = "Full Torso Forward Bend"
    case sideSlouch = "Lateral Asymmetric Slouch (Leaning on Elbow)"
}

public enum ErgonomicActivityMode: String, Sendable, Codable {
    case deskSitting = "Desk Sitting Mode (Strict Kinematics)"
    case walkingActive = "Walking Mode (Cadence Filter Active)"
    case standingActive = "Standing Desk Mode"
}

@MainActor
public final class AnteriorZUPTKinematicEngine: ObservableObject {
    public static let shared = AnteriorZUPTKinematicEngine()
    
    // MARK: - Published Metrics
    @Published public var currentPattern: KinematicPosturePattern = .optimal
    @Published public var activityMode: ErgonomicActivityMode = .deskSitting
    @Published public var anteriorDisplacementCm: Double = 0.0 // Forward translation (cm)
    @Published public var isTechNeckDetected: Bool = false
    @Published public var stepCadenceHz: Double = 0.0
    @Published public var statusDescription: String = "Anterior Kinematics Synchronized"
    
    // MARK: - ZUPT Forward Translation Integration Variables
    private var forwardVelocityMPerS: Double = 0.0
    private var forwardDisplacementM: Double = 0.0
    private var isIntegratingBurst: Bool = false
    private var stillnessFrameCount: Int = 0
    private let zuptStillnessThresholdFrames: Int = 18 // ~300ms of stillness triggers ZUPT
    
    // MARK: - Walking Cadence Filter (1.5 - 2.2 Hz Peak Detector)
    private var verticalAccelBuffer: [(timestamp: TimeInterval, accelY: Double)] = []
    private var lastStepTime: TimeInterval = 0.0
    private var stepIntervals: [Double] = []
    
    // MARK: - Time-Gating Counters
    private var headDropDurationSeconds: Double = 0.0
    private var sideSlouchDurationSeconds: Double = 0.0
    private let sustainedPostureThresholdSeconds: Double = 10.0 // 10-15s to reject brief glances
    
    private init() {}
    
    /// Main 60Hz kinematic processing step called on every IMU packet
    public func processSample(
        pitch: Double,
        roll: Double,
        userAccel: SIMD3<Double>,
        rotRate: SIMD3<Double>,
        dt: Double = 1.0 / 60.0
    ) {
        // 1. Detect Walking Cadence (1.5 - 2.2 Hz vertical oscillation)
        updateWalkingCadence(accelY: userAccel.y, now: ProcessInfo.processInfo.systemUptime)
        
        // If actively walking, loosen desk posture rules and alert only if head is looking straight down
        if activityMode == .walkingActive {
            if pitch < -25.0 {
                currentPattern = .headDrop
                statusDescription = "⚠️ Walking Hazard: Eyes straight down at smartphone"
            } else {
                currentPattern = .optimal
                statusDescription = "Walking active (\(String(format: "%.1f", stepCadenceHz)) Hz) • Desk rules suspended"
            }
            return
        }
        
        // 2. Windowed ZUPT Forward Translation Double-Integration
        updateAnteriorTranslationZUPT(userAccelX: userAccel.x, userAccelZ: userAccel.z, rotRateMag: simd_length(rotRate), dt: dt)
        
        // 3. Multi-Pattern Biomechanical Classifier
        classifyPattern(pitch: pitch, roll: roll, rotRate: rotRate, dt: dt)
    }
    
    // MARK: - Windowed ZUPT Translation Physics
    
    private func updateAnteriorTranslationZUPT(userAccelX: Double, userAccelZ: Double, rotRateMag: Double, dt: Double) {
        // Forward acceleration in head's local horizontal plane (Z axis represents forward/backward in earbud frame)
        let aForwardMPerS2 = -userAccelZ * 9.80665 // Invert Z to represent anterior acceleration
        let linearSpeed = abs(aForwardMPerS2)
        
        let isMoving = linearSpeed > 0.12 || rotRateMag > 0.08
        
        if isMoving {
            // Burst Active: Integrate acceleration to velocity and displacement
            isIntegratingBurst = true
            stillnessFrameCount = 0
            forwardVelocityMPerS += aForwardMPerS2 * dt
            
            // Damp high-frequency acceleration jitter
            forwardVelocityMPerS *= 0.96
            forwardDisplacementM += forwardVelocityMPerS * dt
            
            // Constrain physical range (-5cm backward to +15cm forward)
            forwardDisplacementM = max(-0.05, min(0.15, forwardDisplacementM))
            anteriorDisplacementCm = forwardDisplacementM * 100.0
        } else {
            // Quasi-Static Stillness: Zero-Velocity Update (ZUPT)
            stillnessFrameCount += 1
            if stillnessFrameCount >= zuptStillnessThresholdFrames {
                // Hard reset velocity to 0 to prevent runaway integration drift
                forwardVelocityMPerS = 0.0
                isIntegratingBurst = false
                
                // Slowly decay translation baseline if sustained still for > 3 minutes
                if stillnessFrameCount > 1800 {
                    forwardDisplacementM *= 0.998
                    anteriorDisplacementCm = forwardDisplacementM * 100.0
                }
            }
        }
    }
    
    // MARK: - Biomechanical Kinematic Classifier
    
    private func classifyPattern(pitch: Double, roll: Double, rotRate: SIMD3<Double>, dt: Double) {
        let rotSpeedDeg = simd_length(rotRate) * 180.0 / .pi
        
        // Pattern 3: Full Torso Forward Bend (Bending over desk or floor)
        // High downward pitch (> 35°) combined with dynamic angular velocity
        if pitch < -35.0 && rotSpeedDeg > 25.0 {
            currentPattern = .fullTorsoBend
            statusDescription = "Full Torso Forward Bend (\(Int(pitch))°)"
            isTechNeckDetected = false
            return
        }
        
        // Pattern 2: Tech Neck (Anterior Head Translation with LEVEL Eyes)
        // Forward chin displacement > 3.5cm while pitch remains neutral (±6°)
        if anteriorDisplacementCm > 3.5 && abs(pitch) < 7.0 {
            isTechNeckDetected = true
            currentPattern = .techNeck
            statusDescription = "⚠️ Tech Neck Detected: Chin pushed \(String(format: "%.1f", anteriorDisplacementCm))cm forward"
            return
        } else {
            isTechNeckDetected = false
        }
        
        // Pattern 1: Cervical Head Drop (Looking down at laptop or phone)
        if pitch < -15.0 {
            headDropDurationSeconds += dt
            if headDropDurationSeconds >= sustainedPostureThresholdSeconds {
                currentPattern = .headDrop
                statusDescription = "⚠️ Head Drop Slouch (\(Int(pitch))° down for \(Int(headDropDurationSeconds))s)"
                return
            }
        } else {
            headDropDurationSeconds = max(0.0, headDropDurationSeconds - dt * 2.0)
        }
        
        // Pattern 4: Asymmetric Side Slouch (Leaning on elbow or one hand)
        if abs(roll) > 12.0 {
            sideSlouchDurationSeconds += dt
            if sideSlouchDurationSeconds >= sustainedPostureThresholdSeconds {
                currentPattern = .sideSlouch
                statusDescription = "⚠️ Asymmetric Side Slouch (Leaning \(Int(roll))° sideways)"
                return
            }
        } else {
            sideSlouchDurationSeconds = max(0.0, sideSlouchDurationSeconds - dt * 2.0)
        }
        
        // Default: Optimal Alignment
        currentPattern = .optimal
        statusDescription = "Optimal Neutral Spine & Chin Position"
    }
    
    // MARK: - Walking Cadence Filter (1.5 - 2.2 Hz)
    
    private func updateWalkingCadence(accelY: Double, now: TimeInterval) {
        verticalAccelBuffer.append((timestamp: now, accelY: accelY))
        verticalAccelBuffer.removeAll { now - $0.timestamp > 2.5 }
        
        guard verticalAccelBuffer.count >= 60 else { return }
        
        // Peak detector on vertical acceleration
        let peakThreshold = 0.18 // ~0.18g heel strike threshold
        
        if accelY > peakThreshold && (now - lastStepTime) > 0.35 && (now - lastStepTime) < 0.85 {
            let interval = now - lastStepTime
            lastStepTime = now
            stepIntervals.append(interval)
            if stepIntervals.count > 5 { stepIntervals.removeFirst() }
            
            let avgInterval = stepIntervals.reduce(0, +) / Double(stepIntervals.count)
            let freqHz = 1.0 / avgInterval
            self.stepCadenceHz = freqHz
            
            // Human walking cadence is 1.5 - 2.2 Hz (90 - 132 steps/min)
            if freqHz >= 1.4 && freqHz <= 2.3 && stepIntervals.count >= 3 {
                self.activityMode = .walkingActive
                return
            }
        }
        
        // Revert to desk sitting mode if no heel-strikes detected for 3 seconds
        if now - lastStepTime > 3.0 {
            self.activityMode = .deskSitting
            self.stepCadenceHz = 0.0
        }
    }
    
    public func resetForwardTranslation() {
        self.forwardVelocityMPerS = 0.0
        self.forwardDisplacementM = 0.0
        self.anteriorDisplacementCm = 0.0
        self.isTechNeckDetected = false
    }
}
