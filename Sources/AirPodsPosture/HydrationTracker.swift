import Foundation

@MainActor
public final class HydrationTracker: ObservableObject {
    public static let shared = HydrationTracker()
    
    @Published public var isEnabled: Bool = true
    @Published public var waterGlassesLogged: Int = 3
    @Published public var lastDrinkDate: Date = Date()
    @Published public var minutesSinceLastDrink: Int = 18
    @Published public var reminderDue: Bool = false
    
    public var sipsToday: Int { waterGlassesLogged }
    public var estimatedVolumeOunces: String { "\(waterGlassesLogged * 8) oz" }
    public var recentSipMessage: String { "Last logged \(minutesSinceLastDrink)m ago" }
    
    private var tiltStartTime: Date? = nil
    private var timer: Timer? = nil
    
    private init() {
        let t = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkHydrationReminder()
            }
        }
        t.tolerance = 60.0
        timer = t
    }
    
    public func update(pitch: Double, roll: Double) {
        guard isEnabled else { return }
        
        let now = Date()
        
        // Drinking signature: head tilted back (+22° to +55° pitch) with minimal roll (< 10°)
        if pitch > 22.0 && pitch < 58.0 && abs(roll) < 12.0 {
            if tiltStartTime == nil {
                tiltStartTime = now
            }
            
            let elapsed = now.timeIntervalSince(tiltStartTime!)
            // Sustained tilt for 2.2 seconds = logged sip/glass
            if elapsed >= 2.2 {
                if now.timeIntervalSince(lastDrinkDate) > 60.0 { // prevent double counting within 1 min
                    waterGlassesLogged += 1
                    lastDrinkDate = now
                    reminderDue = false
                    MotionManager.shared.playFeedbackSound("Glass")
                }
                tiltStartTime = nil
            }
        } else {
            tiltStartTime = nil
        }
    }
    
    private func checkHydrationReminder() {
        let elapsed = Int(Date().timeIntervalSince(lastDrinkDate) / 60.0)
        minutesSinceLastDrink = elapsed
        
        if elapsed >= 90 && !reminderDue {
            reminderDue = true
            MotionManager.shared.playFeedbackSound("Ping")
        }
    }
}
