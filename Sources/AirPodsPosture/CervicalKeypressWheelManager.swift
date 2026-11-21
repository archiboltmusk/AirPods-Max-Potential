import Foundation
import CoreGraphics
import AppKit

@MainActor
public final class CervicalKeypressWheelManager: ObservableObject {
    public static let shared = CervicalKeypressWheelManager()
    
    @Published public var isKeypressWheelEnabled: Bool = false
    @Published public var selectedCommand: String = "Neutral"
    
    private var isHoldingWheelModifier: Bool = false
    private var lastTriggerTime: Date = Date()
    
    private init() {
        setupKeyMonitor()
    }
    
    private func setupKeyMonitor() {
        // Monitor for Option key press
        NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self = self, self.isKeypressWheelEnabled else { return }
                
                let isOptionPressed = event.modifierFlags.contains(.option)
                if isOptionPressed && !self.isHoldingWheelModifier {
                    self.isHoldingWheelModifier = true
                    self.selectedCommand = "Ready to Tilt"
                } else if !isOptionPressed && self.isHoldingWheelModifier {
                    self.isHoldingWheelModifier = false
                    self.executeSelectedCommand()
                }
            }
            return event
        }
    }
    
    public func update(pitch: Double, roll: Double, yaw: Double) {
        guard isKeypressWheelEnabled && isHoldingWheelModifier else { return }
        
        // Map 4 cardinal head directions while holding Option:
        // Tilt Up -> Mission Control
        // Tilt Down -> App Expose
        // Tilt Left -> Switch Left Desktop Space
        // Tilt Right -> Switch Right Desktop Space
        if pitch > 18.0 {
            selectedCommand = "Mission Control"
        } else if pitch < -18.0 {
            selectedCommand = "Application Exposé"
        } else if roll < -18.0 {
            selectedCommand = "Desktop Space Left"
        } else if roll > 18.0 {
            selectedCommand = "Desktop Space Right"
        } else {
            selectedCommand = "Center (Cancel)"
        }
    }
    
    private func executeSelectedCommand() {
        switch selectedCommand {
        case "Mission Control":
            simulateSystemKey(key: 160) // F3 / Mission Control
            MotionManager.shared.playFeedbackSound("Pop")
        case "Application Exposé":
            simulateSystemKey(key: 160)
            MotionManager.shared.playFeedbackSound("Pop")
        case "Desktop Space Left":
            SpatialSpacesManager.shared.switchSpace(direction: "left")
            MotionManager.shared.playFeedbackSound("Pop")
        case "Desktop Space Right":
            SpatialSpacesManager.shared.switchSpace(direction: "right")
            MotionManager.shared.playFeedbackSound("Pop")
        default:
            break
        }
        selectedCommand = "Neutral"
    }
    
    private func simulateSystemKey(key: UInt8) {
        let src = CGEventSource(stateID: .hidSystemState)
        let evDown = CGEvent(keyboardEventSource: src, virtualKey: 160, keyDown: true)
        let evUp = CGEvent(keyboardEventSource: src, virtualKey: 160, keyDown: false)
        evDown?.post(tap: .cghidEventTap)
        evUp?.post(tap: .cghidEventTap)
    }
}
