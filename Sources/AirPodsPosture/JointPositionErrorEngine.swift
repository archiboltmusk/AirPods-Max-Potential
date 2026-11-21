import Foundation
import SwiftUI
import Combine

/// Cervical Joint Position Error (JPE) Proprioceptive Diagnostic Engine.
/// Physical therapy gold standard: tests suboccipital mechanoreceptor accuracy.
/// Patient closes eyes, rotates 45° left/right, and attempts to return to exact neutral.
/// Computes error angle (Δ°) indicating sensory drift and chronic ligament fatigue.
@MainActor
public final class JointPositionErrorEngine: ObservableObject {
    public static let shared = JointPositionErrorEngine()
    
    @Published public var isTestActive: Bool = false
    @Published public var currentStep: TestStep = .step1CalibrateCenter
    @Published public var baselinePitch: Double = 0.0
    @Published public var baselineYaw: Double = 0.0
    @Published public var leftErrorDegrees: Double = 0.0
    @Published public var rightErrorDegrees: Double = 0.0
    @Published public var compositeErrorDegrees: Double = 0.0
    @Published public var proprioceptionGrade: String = "Athletic Grade (<3.0°)"
    @Published public var testCompleted: Bool = false
    
    public enum TestStep: String {
        case step1CalibrateCenter = "1. Sit upright, look dead center, and lock neutral baseline."
        case step2RotateLeft = "2. Close your eyes. Turn head 45° to the LEFT, then return to what you feel is neutral center."
        case step3RotateRight = "3. Close your eyes. Turn head 45° to the RIGHT, then return to what you feel is neutral center."
        case step4Results = "Diagnostic Complete • Suboccipital Proprioceptive Profile"
    }
    
    private init() {}
    
    public func startTest() {
        isTestActive = true
        testCompleted = false
        currentStep = .step1CalibrateCenter
        leftErrorDegrees = 0.0
        rightErrorDegrees = 0.0
        compositeErrorDegrees = 0.0
    }
    
    public func lockBaseline() {
        let motion = MotionManager.shared
        baselinePitch = motion.deltaPitch
        baselineYaw = motion.deltaYaw
        currentStep = .step2RotateLeft
        NSSound(named: "Pop")?.play()
    }
    
    public func lockLeftReposition() {
        let motion = MotionManager.shared
        let yawDelta = abs(motion.deltaYaw - baselineYaw)
        let pitchDelta = abs(motion.deltaPitch - baselinePitch)
        leftErrorDegrees = sqrt(pow(yawDelta, 2) + pow(pitchDelta, 2))
        currentStep = .step3RotateRight
        NSSound(named: "Pop")?.play()
    }
    
    public func lockRightReposition() {
        let motion = MotionManager.shared
        let yawDelta = abs(motion.deltaYaw - baselineYaw)
        let pitchDelta = abs(motion.deltaPitch - baselinePitch)
        rightErrorDegrees = sqrt(pow(yawDelta, 2) + pow(pitchDelta, 2))
        
        compositeErrorDegrees = (leftErrorDegrees + rightErrorDegrees) / 2.0
        
        if compositeErrorDegrees <= 3.0 {
            proprioceptionGrade = "Athletic Precision (<3.0° Error)"
        } else if compositeErrorDegrees <= 5.0 {
            proprioceptionGrade = "Normal Range (3.0°–5.0° Error)"
        } else {
            proprioceptionGrade = "Suboccipital Drift (>5.0° Error — PT Recommended)"
        }
        
        currentStep = .step4Results
        testCompleted = true
        isTestActive = false
        NSSound(named: "Hero")?.play()
    }
    
    public func cancelTest() {
        isTestActive = false
        currentStep = .step1CalibrateCenter
    }
}
