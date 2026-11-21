import Foundation
import SwiftUI
import Combine

public enum BreathingPattern: String, CaseIterable, Identifiable {
    case boxBreathing = "Box Breathing (4-4-4-4 Focus)"
    case relaxing478 = "4-7-8 Deep Relaxation"
    case energizing = "Energizing (4-2-4)"
    
    public var id: String { rawValue }
    
    public var inhaleSeconds: Double {
        switch self {
        case .boxBreathing: return 4.0
        case .relaxing478: return 4.0
        case .energizing: return 4.0
        }
    }
    
    public var holdInSeconds: Double {
        switch self {
        case .boxBreathing: return 4.0
        case .relaxing478: return 7.0
        case .energizing: return 2.0
        }
    }
    
    public var exhaleSeconds: Double {
        switch self {
        case .boxBreathing: return 4.0
        case .relaxing478: return 8.0
        case .energizing: return 4.0
        }
    }
    
    public var holdOutSeconds: Double {
        switch self {
        case .boxBreathing: return 4.0
        case .relaxing478: return 0.0
        case .energizing: return 0.0
        }
    }
}

public enum BreathingPhase: String {
    case inhale = "Inhale..."
    case holdIn = "Hold Breath"
    case exhale = "Exhale Slowly..."
    case holdOut = "Hold Empty"
}

@MainActor
public final class ResonanceBreathingCoach: ObservableObject {
    public static let shared = ResonanceBreathingCoach()
    
    @Published public var isActive: Bool = false
    @Published public var selectedPattern: BreathingPattern = .boxBreathing
    @Published public var currentPhase: BreathingPhase = .inhale
    @Published public var phaseProgress: Double = 0.0 // 0.0 to 1.0
    @Published public var secondsInCurrentPhase: Double = 0.0
    @Published public var completedCycles: Int = 0
    @Published public var visualCircleScale: CGFloat = 1.0
    
    private var timer: Timer? = nil
    
    private init() {}
    
    public func startSession() {
        isActive = true
        currentPhase = .inhale
        phaseProgress = 0.0
        secondsInCurrentPhase = 0.0
        completedCycles = 0
        visualCircleScale = 1.0
        MotionManager.shared.playFeedbackSound("Glass")
        startTimer()
    }
    
    public func stopSession() {
        isActive = false
        timer?.invalidate()
        timer = nil
        visualCircleScale = 1.0
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard isActive else { return }
        
        secondsInCurrentPhase += 0.1
        let duration = durationForCurrentPhase()
        phaseProgress = min(1.0, secondsInCurrentPhase / duration)
        
        // Update circle scale
        switch currentPhase {
        case .inhale:
            visualCircleScale = 1.0 + CGFloat(phaseProgress) * 0.45
        case .holdIn:
            visualCircleScale = 1.45
        case .exhale:
            visualCircleScale = 1.45 - CGFloat(phaseProgress) * 0.45
        case .holdOut:
            visualCircleScale = 1.0
        }
        
        if secondsInCurrentPhase >= duration {
            advancePhase()
        }
    }
    
    private func durationForCurrentPhase() -> Double {
        switch currentPhase {
        case .inhale: return selectedPattern.inhaleSeconds
        case .holdIn: return selectedPattern.holdInSeconds
        case .exhale: return selectedPattern.exhaleSeconds
        case .holdOut: return selectedPattern.holdOutSeconds
        }
    }
    
    private func advancePhase() {
        secondsInCurrentPhase = 0.0
        phaseProgress = 0.0
        
        switch currentPhase {
        case .inhale:
            if selectedPattern.holdInSeconds > 0 {
                currentPhase = .holdIn
            } else {
                currentPhase = .exhale
            }
        case .holdIn:
            currentPhase = .exhale
            MotionManager.shared.playFeedbackSound("Pop")
        case .exhale:
            if selectedPattern.holdOutSeconds > 0 {
                currentPhase = .holdOut
            } else {
                completeCycle()
            }
        case .holdOut:
            completeCycle()
        }
    }
    
    private func completeCycle() {
        completedCycles += 1
        currentPhase = .inhale
        MotionManager.shared.playFeedbackSound("Tink")
    }
}
