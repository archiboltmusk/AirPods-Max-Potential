import Foundation
import Combine

/// Posture-Gated Pomodoro Deep Work Focus Engine.
/// A 25-minute deep work timer that ONLY counts down when cervical posture quality is optimal (Score >= 80%).
/// When slouching occurs, the timer gently pauses and displays an amber focus halo, gamifying upright posture into productivity.
@MainActor
public final class PostureGatedPomodoroEngine: ObservableObject {
    public static let shared = PostureGatedPomodoroEngine()
    
    @Published public var isRunning: Bool = false
    @Published public var isPosturePaused: Bool = false
    @Published public var sessionDurationMinutes: Double = 25.0
    @Published public var secondsRemaining: Double = 25.0 * 60.0
    @Published public var completedSessionsToday: Int = 3
    @Published public var uprightFocusMinutesEarned: Double = 75.0
    @Published public var slouchedSecondsPaused: Double = 0.0
    
    private var timer: Timer?
    
    private init() {
        startEngineLoop()
    }
    
    private func startEngineLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    public func startSession() {
        self.isRunning = true
        self.isPosturePaused = false
        SyntheticEarHapticEngine.shared.playSuccessChirp()
    }
    
    public func pauseSession() {
        self.isRunning = false
    }
    
    public func resetSession() {
        self.isRunning = false
        self.isPosturePaused = false
        self.secondsRemaining = sessionDurationMinutes * 60.0
    }
    
    private func tick() {
        guard isRunning else { return }
        let motion = MotionManager.shared
        
        let isUpright = (motion.postureScore >= 80)
        
        if isUpright {
            self.isPosturePaused = false
            if secondsRemaining > 0 {
                secondsRemaining -= 1.0
                uprightFocusMinutesEarned += (1.0 / 60.0)
            } else {
                // Completed session!
                completedSessionsToday += 1
                resetSession()
                SyntheticEarHapticEngine.shared.playSuccessChirp()
                NotificationManager.shared.sendCustomAlert(
                    title: "🎉 Pomodoro Complete!",
                    body: "25 minutes of upright posture deep work achieved! Stand up and roll your shoulders."
                )
            }
        } else {
            // Slouching! Posture-Gate pauses the timer!
            self.isPosturePaused = true
            slouchedSecondsPaused += 1.0
        }
    }
}
