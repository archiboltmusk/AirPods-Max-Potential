import Foundation
import AppKit

@MainActor
public final class SpatialSoundstageManager: ObservableObject {
    public static let shared = SpatialSoundstageManager()
    
    @Published public var isEnabled: Bool = false
    @Published public var virtualPanPosition: Float = 0.0 // -1.0 (Left) to +1.0 (Right)
    @Published public var frontAppName: String = "Center"
    
    private var timer: Timer? = nil
    
    private init() {
        // Zero continuous timers; updated on demand when enabled
    }
    
    private func updatePan() {
        guard isEnabled, let screen = NSScreen.main else {
            virtualPanPosition = 0
            return
        }
        
        // Query position of frontmost window
        let script = """
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            tell frontApp
                try
                    set winPos to position of first window
                    set winSize to size of first window
                    return {item 1 of winPos, item 1 of winSize}
                end try
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let res = appleScript.executeAndReturnError(&error)
            if error == nil, let list = res.coerce(toDescriptorType: typeAEList) {
                let winX = list.atIndex(1)?.int32Value ?? 0
                let winW = list.atIndex(2)?.int32Value ?? 0
                let centerX = Double(winX) + Double(winW) / 2.0
                let screenMidX = Double(screen.frame.width) / 2.0
                
                // Map to -1.0 ... +1.0
                let pan = Float(max(-1.0, min(1.0, (centerX - screenMidX) / screenMidX)))
                self.virtualPanPosition = pan
                self.frontAppName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "App"
            }
        }
    }
}
