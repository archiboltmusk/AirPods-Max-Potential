import Foundation

@MainActor
public final class StandingDeskTracker: ObservableObject {
    public static let shared = StandingDeskTracker()
    
    @Published public var isStanding: Bool = false
    @Published public var secondsSittingToday: TimeInterval = 0
    @Published public var secondsStandingToday: TimeInterval = 0
    @Published public var standingGoalMinutes: Int = 120 // 2 hours goal
    
    private var accelZHistory: [Double] = []
    private var lastTickTime: Date = Date()
    
    private init() {}
    
    public func update(userAccelZ: Double, totalEnergy: Double) {
        accelZHistory.append(abs(userAccelZ))
        if accelZHistory.count > 60 {
            accelZHistory.removeFirst()
        }
        
        let avgZMovement = accelZHistory.reduce(0.0, +) / Double(max(1, accelZHistory.count))
        
        // Standing exhibits continuous micro-bobbing and weight shifts (avgZMovement > 0.015g)
        // Sitting is virtually static (avgZMovement < 0.006g)
        let detectedStanding = (avgZMovement > 0.014 && totalEnergy > 0.02)
        if detectedStanding != isStanding {
            isStanding = detectedStanding
        }
        
        let now = Date()
        let dt = now.timeIntervalSince(lastTickTime)
        lastTickTime = now
        
        if dt > 0 && dt < 2.0 {
            if isStanding {
                secondsStandingToday += dt
            } else {
                secondsSittingToday += dt
            }
        }
    }
}
