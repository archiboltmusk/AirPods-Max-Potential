import Foundation

@MainActor
public final class MultiMonitorGuard: ObservableObject {
    public static let shared = MultiMonitorGuard()
    
    @Published public var isEnabled: Bool = true
    @Published public var centerPercentage: Double = 100.0
    @Published public var leftPercentage: Double = 0.0
    @Published public var rightPercentage: Double = 0.0
    @Published public var asymmetryStrainScore: Int = 0 // 0 to 100 (high = dangerous unilateral neck strain)
    @Published public var warningMessage: String? = nil
    
    private var yawHistory: [(timestamp: Date, yaw: Double)] = []
    private var lastWarningTime: Date? = nil
    
    private init() {}
    
    public func update(deltaYaw: Double) {
        guard isEnabled else { return }
        
        let now = Date()
        yawHistory.append((timestamp: now, yaw: deltaYaw))
        
        // Retain rolling 30-minute window
        yawHistory.removeAll { now.timeIntervalSince($0.timestamp) > 1800.0 }
        
        guard yawHistory.count > 30 else { return }
        
        let total = Double(yawHistory.count)
        let leftCount = Double(yawHistory.filter { $0.yaw < -18.0 }.count)
        let rightCount = Double(yawHistory.filter { $0.yaw > 18.0 }.count)
        let centerCount = Double(yawHistory.filter { abs($0.yaw) <= 18.0 }.count)
        
        leftPercentage = (leftCount / total) * 100.0
        rightPercentage = (rightCount / total) * 100.0
        centerPercentage = (centerCount / total) * 100.0
        
        // Calculate asymmetry strain: difference between left and right skew
        let dominantSide = max(leftPercentage, rightPercentage)
        if dominantSide > 55.0 && centerPercentage < 40.0 {
            asymmetryStrainScore = Int(min(100.0, (dominantSide - 40.0) * 2.5))
            let sideName = leftPercentage > rightPercentage ? "left" : "right"
            warningMessage = "Cervical strain alert: head turned toward \(sideName) monitor for \(Int(dominantSide))% of the past 30 mins. Center your primary window!"
            
            if let last = lastWarningTime, now.timeIntervalSince(last) < 600.0 {
                // Rate limit
            } else {
                lastWarningTime = now
                MotionManager.shared.playFeedbackSound("Submarine")
            }
        } else {
            asymmetryStrainScore = Int(max(0.0, (dominantSide - 30.0) * 1.5))
            warningMessage = nil
        }
    }
}
