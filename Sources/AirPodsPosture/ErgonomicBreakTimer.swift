import Foundation
import Combine

@MainActor
public final class ErgonomicBreakTimer: ObservableObject {
    public static let shared = ErgonomicBreakTimer()
    
    @Published public var isEnabled: Bool = true
    @Published public var intervalMinutes: Double = 20.0
    @Published public var secondsRemaining: Double = 1200.0 // 20 mins
    @Published public var isBreakDue: Bool = false
    @Published public var breakDurationSeconds: Double = 20.0
    @Published public var activeBreakSeconds: Double = 0.0
    @Published public var isBreakActive: Bool = false
    
    private var timer: Timer? = nil
    
    private init() {
        startTimer()
    }
    
    public func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard isEnabled else { return }
        
        if isBreakActive {
            activeBreakSeconds += 1.0
            if activeBreakSeconds >= breakDurationSeconds {
                completeBreak()
            }
            return
        }
        
        if secondsRemaining > 0 {
            secondsRemaining -= 1.0
            if secondsRemaining <= 0 {
                isBreakDue = true
                MotionManager.shared.playFeedbackSound("Glass")
                NotificationManager.shared.sendBreakNotification()
            }
        }
    }
    
    public func startBreak() {
        isBreakActive = true
        activeBreakSeconds = 0
        isBreakDue = false
    }
    
    public func completeBreak() {
        isBreakActive = false
        isBreakDue = false
        activeBreakSeconds = 0
        secondsRemaining = intervalMinutes * 60.0
        MotionManager.shared.playFeedbackSound("Hero")
    }
    
    public func snoozeBreak(minutes: Double = 5.0) {
        isBreakDue = false
        isBreakActive = false
        secondsRemaining = minutes * 60.0
    }
    
    public func resetTimer() {
        isBreakDue = false
        isBreakActive = false
        activeBreakSeconds = 0
        secondsRemaining = intervalMinutes * 60.0
    }
}
