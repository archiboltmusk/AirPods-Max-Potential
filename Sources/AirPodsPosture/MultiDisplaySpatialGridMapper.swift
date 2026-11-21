import Foundation

public struct VirtualDisplayCoordinate: Identifiable, Codable {
    public let id: String
    public let name: String
    public let yawAngleCenter: Double // Target yaw in degrees
    public let yawSpanDegrees: Double // Angular width
    public var minutesSpentToday: Double
}

@MainActor
public final class MultiDisplaySpatialGridMapper: ObservableObject {
    public static let shared = MultiDisplaySpatialGridMapper()
    
    @Published public var isMultiDisplayMappingEnabled: Bool = true
    @Published public var displays: [VirtualDisplayCoordinate] = [
        VirtualDisplayCoordinate(id: "primary", name: "Primary Display (Center)", yawAngleCenter: 0.0, yawSpanDegrees: 24.0, minutesSpentToday: 184.0),
        VirtualDisplayCoordinate(id: "left", name: "Secondary Display (Left)", yawAngleCenter: -34.0, yawSpanDegrees: 22.0, minutesSpentToday: 42.0),
        VirtualDisplayCoordinate(id: "right", name: "Auxiliary Display (Right)", yawAngleCenter: 34.0, yawSpanDegrees: 22.0, minutesSpentToday: 18.0)
    ]
    @Published public var activeDisplayId: String = "primary"
    @Published public var unilateralStrainRisk: String = "Balanced Cervical Distribution"
    
    private var lastUpdateDate: Date = Date()
    
    private init() {}
    
    public func update(yaw: Double) {
        guard isMultiDisplayMappingEnabled else { return }
        
        let now = Date()
        let elapsedMins = now.timeIntervalSince(lastUpdateDate) / 60.0
        lastUpdateDate = now
        
        // Find which display user's head is facing
        var foundId = "primary"
        for i in 0..<displays.count {
            let d = displays[i]
            let diff = abs(yaw - d.yawAngleCenter)
            if diff <= (d.yawSpanDegrees / 2.0) {
                foundId = d.id
                displays[i].minutesSpentToday += elapsedMins
                break
            }
        }
        
        activeDisplayId = foundId
        
        // Check unilateral cervical strain:
        // If > 45 minutes continuous on side displays without returning to center
        let leftMins = displays.first(where: { $0.id == "left" })?.minutesSpentToday ?? 0
        let rightMins = displays.first(where: { $0.id == "right" })?.minutesSpentToday ?? 0
        
        if leftMins > 60.0 && rightMins < 15.0 {
            unilateralStrainRisk = "⚠️ Left Sternocleidomastoid Overload: Reposition tasks to Primary Display!"
        } else if rightMins > 60.0 && leftMins < 15.0 {
            unilateralStrainRisk = "⚠️ Right Cervical Overload: Reposition tasks to Primary Display!"
        } else {
            unilateralStrainRisk = "Balanced Cervical Distribution"
        }
    }
    
    public func calibrateDisplayAtCurrentYaw(id: String) {
        let currentYaw = MotionManager.shared.deltaYaw
        if let idx = displays.firstIndex(where: { $0.id == id }) {
            let old = displays[idx]
            displays[idx] = VirtualDisplayCoordinate(
                id: old.id,
                name: old.name,
                yawAngleCenter: currentYaw,
                yawSpanDegrees: old.yawSpanDegrees,
                minutesSpentToday: old.minutesSpentToday
            )
            MotionManager.shared.playFeedbackSound("Hero")
        }
    }
}
