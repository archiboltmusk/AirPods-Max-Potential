import Foundation
import AppKit

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
    
    private init() {
        autoDetectDisplaysFromNSScreen()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.autoDetectDisplaysFromNSScreen()
            }
        }
    }
    
    /// Auto-detects connected monitors via NSScreen and builds spatial angle map
    public func autoDetectDisplaysFromNSScreen() {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return }
        
        // Sort screens by horizontal position (Left to Right)
        let sorted = screens.sorted(by: { $0.frame.origin.x < $1.frame.origin.x })
        var newDisplays: [VirtualDisplayCoordinate] = []
        
        let centerIdx = sorted.count / 2
        for (i, screen) in sorted.enumerated() {
            let offset = Double(i - centerIdx)
            let yawCenter = offset * 32.0 // ~32° yaw angle per screen
            let name = screen.localizedName
            let id = i == centerIdx ? "primary" : (offset < 0 ? "left_\(abs(Int(offset)))" : "right_\(Int(offset))")
            let label = i == centerIdx ? "Primary (\(name))" : "\(name) (\(offset < 0 ? "Left" : "Right"))"
            
            // Retain existing tracked time if available
            let existingMins = displays.first(where: { $0.id == id })?.minutesSpentToday ?? 0.0
            
            newDisplays.append(VirtualDisplayCoordinate(
                id: id,
                name: label,
                yawAngleCenter: yawCenter,
                yawSpanDegrees: 26.0,
                minutesSpentToday: existingMins
            ))
        }
        self.displays = newDisplays
    }
    
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
        let leftMins = displays.filter { $0.yawAngleCenter < -15.0 }.reduce(0.0) { $0 + $1.minutesSpentToday }
        let rightMins = displays.filter { $0.yawAngleCenter > 15.0 }.reduce(0.0) { $0 + $1.minutesSpentToday }
        
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
