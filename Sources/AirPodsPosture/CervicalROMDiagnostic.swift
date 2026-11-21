import Foundation

public struct ROMStage: Identifiable {
    public let id: String
    public let name: String
    public let instruction: String
    public let clinicalNormDegrees: Double
    public let axis: String
}

@MainActor
public final class CervicalROMDiagnostic: ObservableObject {
    public static let shared = CervicalROMDiagnostic()
    
    @Published public var isDiagnosticActive: Bool = false
    @Published public var currentStageIndex: Int = 0
    @Published public var peakAngleReached: Double = 0.0
    @Published public var testCompleted: Bool = false
    @Published public var flexibilityScore: Int = 100 // 0 to 100
    @Published public var mobilityAgeEstimate: Int = 25
    @Published public var stageResults: [String: Double] = [:]
    
    public let stages: [ROMStage] = [
        ROMStage(id: "extension", name: "1. Cervical Extension", instruction: "Slowly tilt your head back to gaze at the ceiling as far as comfortable.", clinicalNormDegrees: 60.0, axis: "pitch"),
        ROMStage(id: "flexion", name: "2. Cervical Flexion", instruction: "Slowly lower your chin towards your chest as far as comfortable.", clinicalNormDegrees: 50.0, axis: "pitch"),
        ROMStage(id: "lateral_left", name: "3. Lateral Flexion (Left)", instruction: "Tilt your left ear towards your left shoulder without lifting shoulders.", clinicalNormDegrees: 45.0, axis: "roll"),
        ROMStage(id: "lateral_right", name: "4. Lateral Flexion (Right)", instruction: "Tilt your right ear towards your right shoulder as far as comfortable.", clinicalNormDegrees: 45.0, axis: "roll"),
        ROMStage(id: "rotation_left", name: "5. Axial Rotation (Left)", instruction: "Smoothly turn your head to look over your left shoulder.", clinicalNormDegrees: 75.0, axis: "yaw"),
        ROMStage(id: "rotation_right", name: "6. Axial Rotation (Right)", instruction: "Smoothly turn your head to look over your right shoulder.", clinicalNormDegrees: 75.0, axis: "yaw")
    ]
    
    public var currentStage: ROMStage? {
        guard currentStageIndex < stages.count else { return nil }
        return stages[currentStageIndex]
    }
    
    private init() {}
    
    public func startTest() {
        isDiagnosticActive = true
        currentStageIndex = 0
        peakAngleReached = 0.0
        testCompleted = false
        stageResults.removeAll()
        MotionManager.shared.playFeedbackSound("Glass")
    }
    
    public func update(pitch: Double, roll: Double, yaw: Double) {
        guard isDiagnosticActive, let stage = currentStage else { return }
        
        let currentAngle: Double
        switch stage.axis {
        case "pitch": currentAngle = abs(pitch)
        case "roll": currentAngle = abs(roll)
        case "yaw": currentAngle = abs(yaw)
        default: currentAngle = 0
        }
        
        if currentAngle > peakAngleReached {
            peakAngleReached = currentAngle
        }
    }
    
    public func lockStageAndAdvance() {
        guard let stage = currentStage else { return }
        
        stageResults[stage.id] = peakAngleReached
        MotionManager.shared.playFeedbackSound("Tink")
        
        if currentStageIndex + 1 < stages.count {
            currentStageIndex += 1
            peakAngleReached = 0.0
        } else {
            completeDiagnostic()
        }
    }
    
    private func completeDiagnostic() {
        testCompleted = true
        isDiagnosticActive = false
        
        // Compute total flexibility against clinical norms
        var totalScoreRatio: Double = 0.0
        for stage in stages {
            let reached = stageResults[stage.id] ?? 0.0
            let ratio = min(1.2, reached / stage.clinicalNormDegrees)
            totalScoreRatio += ratio
        }
        
        let avgRatio = totalScoreRatio / Double(stages.count)
        flexibilityScore = Int(min(100.0, avgRatio * 100.0))
        
        // Biological mobility age estimate:
        // 100% flexibility = age 22, 70% flexibility = age 45, 50% = age 65
        let age = max(20, min(75, Int(68.0 - (avgRatio * 46.0))))
        mobilityAgeEstimate = age
        
        MotionManager.shared.playFeedbackSound("Hero")
    }
}
