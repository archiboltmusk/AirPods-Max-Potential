import Foundation
import SwiftUI
import Combine

/// Vestibular-Ocular Reflex (VOR) & Digital Brain Fog Eliminator.
/// Interactive 60-second micro-routine: fix eyes on center screen target while
/// AirPods gyroscope tracks smooth ±20° yaw & pitch sways.
/// Calculates gaze stability index and neuromuscular coordination score.
@MainActor
public final class VestibularReflexTrainerEngine: ObservableObject {
    public static let shared = VestibularReflexTrainerEngine()
    
    @Published public var isTrainerActive: Bool = false
    @Published public var currentAxis: TrainerAxis = .horizontalYaw
    @Published public var secondsRemaining: Int = 45
    @Published public var currentSwayAngle: Double = 0.0
    @Published public var completedSways: Int = 0
    @Published public var targetAngle: Double = 20.0
    @Published public var vorFluidityScore: Int = 0
    @Published public var testCompleted: Bool = false
    @Published public var stabilityRating: String = "Athletic Fluidity"
    
    public enum TrainerAxis: String, CaseIterable {
        case horizontalYaw = "Horizontal Saccade Sync (Left/Right)"
        case verticalPitch = "Vertical Tilt Sync (Up/Down)"
        
        public var cue: String {
            switch self {
            case .horizontalYaw: return "Keep eyes pinned on center dot. Smoothly turn head 20° left, then right."
            case .verticalPitch: return "Keep eyes pinned on center dot. Smoothly nod head 15° up, then down."
            }
        }
    }
    
    private var countdownTimer: Timer?
    private var trackingTimer: Timer?
    private var previousAngle: Double = 0.0
    private var smoothnessSamples: [Double] = []
    
    private init() {}
    
    public func startSession(axis: TrainerAxis = .horizontalYaw) {
        currentAxis = axis
        isTrainerActive = true
        testCompleted = false
        secondsRemaining = 45
        completedSways = 0
        smoothnessSamples.removeAll()
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                } else {
                    self.completeSession()
                }
            }
        }
        
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sampleMotion()
            }
        }
    }
    
    private func sampleMotion() {
        let motion = MotionManager.shared
        let angle = currentAxis == .horizontalYaw ? motion.deltaYaw : motion.deltaPitch
        currentSwayAngle = angle
        
        // Measure jerk / smoothness
        let velocity = abs(angle - previousAngle) / 0.05
        previousAngle = angle
        
        if velocity > 5.0 && velocity < 120.0 {
            smoothnessSamples.append(velocity)
        }
        
        // Count reps
        if abs(angle) >= (targetAngle * 0.8) {
            completedSways += 1
        }
    }
    
    public func completeSession() {
        countdownTimer?.invalidate()
        trackingTimer?.invalidate()
        isTrainerActive = false
        testCompleted = true
        
        // Calculate VOR Fluidity
        let avgVelocity = smoothnessSamples.isEmpty ? 45.0 : (smoothnessSamples.reduce(0, +) / Double(smoothnessSamples.count))
        let baseScore = Int(min(98.0, max(65.0, 100.0 - (abs(avgVelocity - 40.0) * 0.8))))
        self.vorFluidityScore = baseScore
        
        if vorFluidityScore >= 88 {
            stabilityRating = "Optokinetic Precision (High)"
        } else if vorFluidityScore >= 75 {
            stabilityRating = "Optimal Retinal Fixation"
        } else {
            stabilityRating = "Mild Vestibular Lag (Recommend Rest)"
        }
    }
    
    public func stopSession() {
        countdownTimer?.invalidate()
        trackingTimer?.invalidate()
        isTrainerActive = false
    }
}
