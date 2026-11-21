import Foundation

@MainActor
public final class DrowsinessGuard: ObservableObject {
    public static let shared = DrowsinessGuard()
    
    @Published public var isEnabled: Bool = false
    @Published public var drowsinessIncidentCount: Int = 0
    @Published public var lastIncidentDate: Date? = nil
    @Published public var alertMessage: String? = nil
    
    private var pitchHistory: [(time: Date, pitch: Double)] = []
    private var lastAlertTime: Date? = nil
    
    private init() {}
    
    public func update(deltaPitch: Double, userAccelZ: Double) {
        guard isEnabled else { return }
        
        let now = Date()
        pitchHistory.append((time: now, pitch: deltaPitch))
        pitchHistory.removeAll { now.timeIntervalSince($0.time) > 4.0 }
        
        guard pitchHistory.count >= 20 else { return }
        
        // 1. Look for gradual downward drop over the past 2.5s (pitch drops by > 14°)
        let oldestPitch = pitchHistory.first?.pitch ?? deltaPitch
        let pitchDrop = oldestPitch - deltaPitch // positive if head dropped downward
        
        // 2. Look for sudden reflexive jerk upward: rapid positive user acceleration in Z (> 0.28g)
        let hasUpwardJerk = (userAccelZ > 0.28)
        
        if pitchDrop > 14.0 && hasUpwardJerk {
            if let last = lastAlertTime, now.timeIntervalSince(last) < 45.0 {
                return // rate limit alerts to once per 45s
            }
            
            lastAlertTime = now
            lastIncidentDate = now
            drowsinessIncidentCount += 1
            alertMessage = "Micro-sleep detected! Take a 5-minute movement break or grab water."
            
            MotionManager.shared.playFeedbackSound("Hero")
            NotificationManager.shared.sendBreakNotification()
            pitchHistory.removeAll()
        }
    }
}
