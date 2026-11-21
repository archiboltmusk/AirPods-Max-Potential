import Foundation

@MainActor
public final class PreMeetingPosturePrep: ObservableObject {
    public static let shared = PreMeetingPosturePrep()
    
    @Published public var isPrepActive: Bool = false
    @Published public var prepStepIndex: Int = 0
    @Published public var checklistCompleted: Bool = false
    
    public let prepSteps = [
        "1. Align Display Level: Ensure camera lens is level with your eye line.",
        "2. Retract Shoulders: Roll shoulders up, back, and gently down.",
        "3. Lift Sternum: Push chest forward slightly to decompress thoracic spine.",
        "4. Neutral Chin: Tuck chin slightly back (avoid turtle text-neck)."
    ]
    
    private init() {}
    
    public func startPrep() {
        isPrepActive = true
        prepStepIndex = 0
        checklistCompleted = false
        MotionManager.shared.playFeedbackSound("Glass")
    }
    
    public func nextStep() {
        if prepStepIndex + 1 < prepSteps.count {
            prepStepIndex += 1
            MotionManager.shared.playFeedbackSound("Tink")
        } else {
            completePrep()
        }
    }
    
    public func completePrep() {
        checklistCompleted = true
        isPrepActive = false
        MotionManager.shared.calibrateCurrentPosture()
        MotionManager.shared.playFeedbackSound("Hero")
    }
}
