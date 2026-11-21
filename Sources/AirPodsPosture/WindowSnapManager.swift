import Foundation
import AppKit

@MainActor
public final class WindowSnapManager: ObservableObject {
    public static let shared = WindowSnapManager()
    
    @Published public var isSnapEnabled: Bool = false
    @Published public var lastSnappedDirection: String = "None"
    
    private var lastSnapTime: Date = Date()
    private var isNeutral: Bool = true
    
    private init() {}
    
    public func update(pitch: Double, roll: Double) {
        guard isSnapEnabled else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastSnapTime) > 1.5 else { return }
        
        if abs(roll) < 10.0 && abs(pitch) < 10.0 {
            isNeutral = true
            return
        }
        
        guard isNeutral else { return }
        
        // Tilt roll left -> snap left
        if roll < -24.0 {
            snapFrontWindow(position: "left")
            lastSnappedDirection = "Snapped Left Half"
            isNeutral = false
            lastSnapTime = now
            MotionManager.shared.playFeedbackSound("Pop")
        }
        // Tilt roll right -> snap right
        else if roll > 24.0 {
            snapFrontWindow(position: "right")
            lastSnappedDirection = "Snapped Right Half"
            isNeutral = false
            lastSnapTime = now
            MotionManager.shared.playFeedbackSound("Pop")
        }
        // Nod up -> maximize
        else if pitch > 25.0 {
            snapFrontWindow(position: "maximize")
            lastSnappedDirection = "Maximized"
            isNeutral = false
            lastSnapTime = now
            MotionManager.shared.playFeedbackSound("Pop")
        }
    }
    
    private func snapFrontWindow(position: String) {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        
        var x = f.origin.x
        var y = f.origin.y
        var w = f.size.width
        var h = f.size.height
        
        switch position {
        case "left":
            w = f.size.width / 2.0
        case "right":
            x = f.origin.x + (f.size.width / 2.0)
            w = f.size.width / 2.0
        default: // maximize
            break
        }
        
        let script = """
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            tell frontApp
                try
                    set position of first window to {\(Int(x)), \(Int(y))}
                    set size of first window to {\(Int(w)), \(Int(h))}
                end try
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            _ = appleScript.executeAndReturnError(nil)
        }
    }
}
