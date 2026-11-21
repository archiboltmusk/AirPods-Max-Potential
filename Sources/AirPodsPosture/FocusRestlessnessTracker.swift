import Foundation

@MainActor
public final class FocusRestlessnessTracker: ObservableObject {
    public static let shared = FocusRestlessnessTracker()
    
    @Published public var focusScore: Int = 92 // 0 to 100%
    @Published public var restlessnessIndex: Int = 8 // 0 to 100%
    @Published public var focusStreakMinutes: Int = 0
    @Published public var focusStateDescription: String = "Deep Flow State"
    
    private var gyroSamples: [Double] = []
    private var focusStartTime: Date = Date()
    
    private init() {}
    
    public func update(rotRateX: Double, rotRateY: Double, rotRateZ: Double) {
        let magnitude = sqrt(pow(rotRateX, 2) + pow(rotRateY, 2) + pow(rotRateZ, 2))
        gyroSamples.append(magnitude)
        
        // Retain last 120 samples (~2.5s at 50Hz)
        if gyroSamples.count > 120 {
            gyroSamples.removeFirst(gyroSamples.count - 120)
        }
        
        guard gyroSamples.count >= 30 else { return }
        
        let mean = gyroSamples.reduce(0.0, +) / Double(gyroSamples.count)
        let variance = gyroSamples.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(gyroSamples.count)
        let standardDev = sqrt(variance)
        
        // Steady posture has low standard dev (< 4.0 deg/s)
        // Restless fidgeting has high standard dev (> 18.0 deg/s)
        let restlessRaw = min(100.0, (standardDev / 25.0) * 100.0)
        restlessnessIndex = (restlessnessIndex * 19 + Int(restlessRaw)) / 20
        
        let calculatedFocus = max(10, min(100, 100 - restlessnessIndex))
        focusScore = (focusScore * 19 + calculatedFocus) / 20
        
        if focusScore > 75 {
            focusStateDescription = "Deep Cognitive Flow"
        } else if focusScore > 50 {
            focusStateDescription = "Active Desk Work"
        } else {
            focusStateDescription = "Restless / Cognitive Fatigue"
        }
        
        let elapsed = Int(Date().timeIntervalSince(focusStartTime) / 60.0)
        focusStreakMinutes = elapsed
    }
}
