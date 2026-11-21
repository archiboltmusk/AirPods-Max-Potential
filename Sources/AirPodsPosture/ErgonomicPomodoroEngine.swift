import Foundation
import Combine

@MainActor
public final class ErgonomicPomodoroEngine: ObservableObject {
    public static let shared = ErgonomicPomodoroEngine()
    
    @Published public var isRunning: Bool = false
    @Published public var isBreakMode: Bool = false
    @Published public var secondsRemaining: Int = 1500 // 25 minutes
    @Published public var sprintPostureScores: [Int] = []
    @Published public var completedSprintsCount: Int = 0
    @Published public var averageSprintPosture: Int = 100
    
    public var isFocusPhase: Bool { isRunning && !isBreakMode }
    
    public var formattedTimeRemaining: String {
        let mins = secondsRemaining / 60
        let secs = secondsRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var stateDescription: String {
        if !isRunning { return "Ready" }
        return isBreakMode ? "Break (5m)" : "Deep Focus (Avg: \(averageSprintPosture)%)"
    }
    
    public func startFocusSprint() {
        startSprint()
    }
    
    public func pauseSprint() {
        stopSprint()
    }
    
    public func update(score: Double) {
        // Intentionally no-op per frame; sampled at 1Hz during tick()
    }
    
    private var timer: Timer? = nil
    
    private init() {}
    
    public func startSprint() {
        isRunning = true
        isBreakMode = false
        secondsRemaining = 1500
        sprintPostureScores.removeAll()
        MotionManager.shared.playFeedbackSound("Hero")
        startTimer()
    }
    
    public func stopSprint() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        secondsRemaining = 1500
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard isRunning else { return }
        
        // Sample current posture score
        let currentScore = MotionManager.shared.postureScore
        sprintPostureScores.append(currentScore)
        averageSprintPosture = sprintPostureScores.reduce(0, +) / max(1, sprintPostureScores.count)
        
        if secondsRemaining > 0 {
            secondsRemaining -= 1
        } else {
            completeInterval()
        }
    }
    
    private func completeInterval() {
        if !isBreakMode {
            // Work interval finished -> check if posture qualifies
            completedSprintsCount += 1
            isBreakMode = true
            secondsRemaining = 300 // 5 minute stretch break
            MotionManager.shared.playFeedbackSound("Hero")
            NotificationManager.shared.sendBreakNotification()
        } else {
            // Break finished -> ready for next sprint
            isBreakMode = false
            isRunning = false
            secondsRemaining = 1500
            MotionManager.shared.playFeedbackSound("Glass")
        }
    }
}
