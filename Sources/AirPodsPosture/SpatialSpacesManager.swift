import Foundation
import CoreGraphics
import AppKit

@MainActor
public final class SpatialSpacesManager: ObservableObject {
    public static let shared = SpatialSpacesManager()
    
    @Published public var isEnabled: Bool = false
    @Published public var triggerAngleThreshold: Double = 28.0 // degrees yaw
    @Published public var lastSwitchedDirection: String = "Center"
    
    private var lastSwitchTime: Date = Date()
    private var isInNeutralZone: Bool = true
    
    private init() {}
    
    public func update(deltaYaw: Double) {
        guard isEnabled else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastSwitchTime) > 1.2 else { return }
        
        // Hysteresis: user must return toward center (< 15°) before triggering another space switch
        if abs(deltaYaw) < 15.0 {
            isInNeutralZone = true
            lastSwitchedDirection = "Center (Primary)"
            return
        }
        
        guard isInNeutralZone else { return }
        
        // Yaw negative = looking left -> switch to left space (Control + Left Arrow)
        if deltaYaw < -triggerAngleThreshold {
            triggerSpaceSwitch(left: true)
            lastSwitchTime = now
            isInNeutralZone = false
            lastSwitchedDirection = "Switched to Left Space"
            MotionManager.shared.playFeedbackSound("Pop")
        }
        // Yaw positive = looking right -> switch to right space (Control + Right Arrow)
        else if deltaYaw > triggerAngleThreshold {
            triggerSpaceSwitch(left: false)
            lastSwitchTime = now
            isInNeutralZone = false
            lastSwitchedDirection = "Switched to Right Space"
            MotionManager.shared.playFeedbackSound("Pop")
        }
    }
    
    public func switchSpace(direction: String) {
        if direction == "left" {
            triggerSpaceSwitch(left: true)
        } else {
            triggerSpaceSwitch(left: false)
        }
    }
    
    private func triggerSpaceSwitch(left: Bool) {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyCode: CGKeyCode = left ? 123 : 124 // 123 = Left Arrow, 124 = Right Arrow
        
        if let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
           let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) {
            down.flags = .maskControl
            up.flags = .maskControl
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
}
