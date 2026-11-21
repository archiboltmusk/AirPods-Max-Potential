import Foundation
import Combine
import AVFoundation
import AppKit

/// Kinematic 5-Phase Repetition Counter for Cervical Spine Physical Therapy.
/// Inspired by allenv0/AirPosture: idle -> entering -> holding -> completing -> recovering.
@MainActor
public final class CervicalRepCounterEngine: ObservableObject {
    public static let shared = CervicalRepCounterEngine()
    
    public enum ExerciseType: String, CaseIterable, Identifiable {
        case chinTuck = "Chin Tuck (Retraction)"
        case neckExtension = "Neck Extension"
        case leftLateralTilt = "Left Lateral Flexion"
        case rightLateralTilt = "Right Lateral Flexion"
        case leftAxialRotation = "Left Cervical Scan"
        case rightAxialRotation = "Right Cervical Scan"
        
        public var id: String { rawValue }
        
        public var targetAngle: Double {
            switch self {
            case .chinTuck: return -12.0 // Pitch down/retract
            case .neckExtension: return 18.0 // Pitch back/up
            case .leftLateralTilt: return -18.0 // Roll left
            case .rightLateralTilt: return 18.0 // Roll right
            case .leftAxialRotation: return -35.0 // Yaw left
            case .rightAxialRotation: return 35.0 // Yaw right
            }
        }
        
        public var motionAxis: String {
            switch self {
            case .chinTuck, .neckExtension: return "Pitch"
            case .leftLateralTilt, .rightLateralTilt: return "Roll"
            case .leftAxialRotation, .rightAxialRotation: return "Yaw"
            }
        }
    }
    
    public enum Phase: String {
        case idle = "Ready (Neutral)"
        case entering = "Moving to Pose"
        case holding = "Holding Pose..."
        case completing = "Rep Completed!"
        case recovering = "Return to Upright (Lockout)"
    }
    
    @Published public var currentExercise: ExerciseType = .chinTuck
    @Published public var currentPhase: Phase = .idle
    @Published public var currentReps: Int = 0
    @Published public var targetReps: Int = 10
    @Published public var holdProgress: Double = 0.0 // 0.0 to 1.0
    @Published public var holdDuration: Double = 3.0 // seconds to hold
    @Published public var recoveryRemaining: Double = 0.0
    @Published public var totalSessionReps: Int = 0
    @Published public var isSessionActive: Bool = false
    
    private var holdStartTime: Date? = nil
    private var recoveryEndTime: Date? = nil
    private let tolerance: Double = 6.0 // +/- 6 degrees
    private let recoveryDelay: Double = 2.0 // anti-gaming cooldown
    
    private init() {}
    
    public func startSession(exercise: ExerciseType = .chinTuck, target: Int = 10) {
        currentExercise = exercise
        targetReps = target
        currentReps = 0
        holdProgress = 0.0
        currentPhase = .idle
        isSessionActive = true
    }
    
    public func stopSession() {
        isSessionActive = false
        currentPhase = .idle
        holdProgress = 0.0
    }
    
    public func update(pitch: Double, roll: Double, yaw: Double) {
        guard isSessionActive else { return }
        let now = Date()
        
        // 1. Check recovery lockout
        if let recEnd = recoveryEndTime {
            let rem = recEnd.timeIntervalSince(now)
            if rem > 0 {
                recoveryRemaining = rem
                currentPhase = .recovering
                holdProgress = 0.0
                return
            } else {
                recoveryEndTime = nil
                recoveryRemaining = 0.0
                currentPhase = .idle
            }
        }
        
        // 2. Extract current angle according to exercise axis
        let currentAngle: Double
        switch currentExercise {
        case .chinTuck, .neckExtension:
            currentAngle = pitch
        case .leftLateralTilt, .rightLateralTilt:
            currentAngle = roll
        case .leftAxialRotation, .rightAxialRotation:
            currentAngle = yaw
        }
        
        let target = currentExercise.targetAngle
        let isInPose = abs(currentAngle - target) <= tolerance
        
        // 3. FSM Update
        if isInPose {
            if holdStartTime == nil {
                // Entering pose
                holdStartTime = now
                currentPhase = .holding
                holdProgress = 0.0
            } else if let start = holdStartTime {
                let elapsed = now.timeIntervalSince(start)
                holdProgress = min(1.0, elapsed / holdDuration)
                currentPhase = .holding
                
                if elapsed >= holdDuration {
                    // Rep completed!
                    currentReps += 1
                    totalSessionReps += 1
                    currentPhase = .completing
                    holdStartTime = nil
                    holdProgress = 1.0
                    recoveryEndTime = now.addingTimeInterval(recoveryDelay)
                    
                    // Trigger sound/haptic
                    NSSound(named: "Glass")?.play()
                    SyntheticEarHapticEngine.shared.playSuccessChirp()
                    
                    if currentReps >= targetReps {
                        isSessionActive = false
                        currentPhase = .idle
                    }
                }
            }
        } else {
            // Not in pose
            if holdStartTime != nil {
                holdStartTime = nil
                holdProgress = 0.0
            }
            if recoveryEndTime == nil {
                currentPhase = .idle
            }
        }
    }
}
