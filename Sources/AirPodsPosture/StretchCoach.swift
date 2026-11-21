import Foundation
import SwiftUI
import Combine

public struct StretchExercise: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let targetAxis: Axis
    public let minAngle: Double
    public let maxAngle: Double
    public let holdDuration: Double
    public let instruction: String
    public let icon: String
    
    public enum Axis {
        case pitch
        case roll
        case yaw
    }
}

@MainActor
public final class StretchCoach: ObservableObject {
    public static let shared = StretchCoach()
    
    public let exercises: [StretchExercise] = [
        StretchExercise(
            id: "lookup",
            title: "Ceiling Gaze (Extension)",
            subtitle: "Relieves hunchback cervical strain",
            targetAxis: .pitch,
            minAngle: 15.0,
            maxAngle: 45.0,
            holdDuration: 4.0,
            instruction: "Tilt your chin upward towards the ceiling and hold.",
            icon: "arrow.up.circle.fill"
        ),
        StretchExercise(
            id: "chin_tuck",
            title: "Gentle Chin Tuck (Flexion)",
            subtitle: "Relieves upper neck suboccipital tension",
            targetAxis: .pitch,
            minAngle: -40.0,
            minAngleValue: -35.0,
            maxAngle: -15.0,
            holdDuration: 4.0,
            instruction: "Gently lower your chin toward your chest and hold.",
            icon: "arrow.down.circle.fill"
        ),
        StretchExercise(
            id: "tilt_left",
            title: "Left Ear to Shoulder",
            subtitle: "Stretches the right trapezius and levator scapulae",
            targetAxis: .roll,
            minAngle: -35.0,
            minAngleValue: -35.0,
            maxAngle: -12.0,
            holdDuration: 4.0,
            instruction: "Gently tilt your head so your left ear moves toward your left shoulder.",
            icon: "arrow.left.circle.fill"
        ),
        StretchExercise(
            id: "tilt_right",
            title: "Right Ear to Shoulder",
            subtitle: "Stretches the left trapezius and levator scapulae",
            targetAxis: .roll,
            minAngle: 12.0,
            maxAngle: 35.0,
            holdDuration: 4.0,
            instruction: "Gently tilt your head toward your right shoulder.",
            icon: "arrow.right.circle.fill"
        ),
        StretchExercise(
            id: "turn_left",
            title: "Look Over Left Shoulder",
            subtitle: "Mobilizes cervical rotation",
            targetAxis: .yaw,
            minAngle: -45.0,
            minAngleValue: -45.0,
            maxAngle: -18.0,
            holdDuration: 4.0,
            instruction: "Smoothly turn your head to look over your left shoulder.",
            icon: "arrow.counterclockwise.circle.fill"
        ),
        StretchExercise(
            id: "turn_right",
            title: "Look Over Right Shoulder",
            subtitle: "Mobilizes cervical rotation",
            targetAxis: .yaw,
            minAngle: 18.0,
            maxAngle: 45.0,
            holdDuration: 4.0,
            instruction: "Smoothly turn your head to look over your right shoulder.",
            icon: "arrow.clockwise.circle.fill"
        )
    ]
    
    @Published public var isActive: Bool = false
    @Published public var currentExerciseIndex: Int = 0
    @Published public var currentHoldTime: Double = 0.0
    @Published public var isInTargetZone: Bool = false
    @Published public var isCompleted: Bool = false
    
    private var timer: Timer? = nil
    
    public var currentExercise: StretchExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    public func startSession() {
        isActive = true
        isCompleted = false
        currentExerciseIndex = 0
        currentHoldTime = 0
        isInTargetZone = false
        startLoop()
    }
    
    public func stopSession() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    public func update(motion: MotionManager) {
        guard isActive, !isCompleted, let exercise = currentExercise else { return }
        
        let currentAngle: Double
        switch exercise.targetAxis {
        case .pitch:
            currentAngle = motion.deltaPitch
        case .roll:
            currentAngle = motion.deltaRoll
        case .yaw:
            currentAngle = motion.deltaYaw
        }
        
        let inZone: Bool
        if exercise.minAngle < exercise.maxAngle {
            inZone = (currentAngle >= exercise.minAngle && currentAngle <= exercise.maxAngle)
        } else {
            inZone = (currentAngle >= exercise.maxAngle && currentAngle <= exercise.minAngle)
        }
        
        isInTargetZone = inZone
    }
    
    private func startLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isActive && !self.isCompleted, let exercise = self.currentExercise else { return }
                
                if self.isInTargetZone {
                    self.currentHoldTime += 0.1
                    if self.currentHoldTime >= exercise.holdDuration {
                        self.completeCurrentExercise()
                    }
                } else {
                    // Decay hold time slowly if user drifts out
                    self.currentHoldTime = max(0, self.currentHoldTime - 0.05)
                }
            }
        }
    }
    
    private func completeCurrentExercise() {
        currentHoldTime = 0
        isInTargetZone = false
        MotionManager.shared.playFeedbackSound("Glass")
        
        if currentExerciseIndex + 1 < exercises.count {
            currentExerciseIndex += 1
        } else {
            isCompleted = true
            isActive = false
            timer?.invalidate()
            timer = nil
            MotionManager.shared.playFeedbackSound("Hero")
        }
    }
}

private extension StretchExercise {
    init(id: String, title: String, subtitle: String, targetAxis: Axis, minAngle: Double, minAngleValue: Double, maxAngle: Double, holdDuration: Double, instruction: String, icon: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.targetAxis = targetAxis
        self.minAngle = minAngle
        self.maxAngle = maxAngle
        self.holdDuration = holdDuration
        self.instruction = instruction
        self.icon = icon
    }
}
