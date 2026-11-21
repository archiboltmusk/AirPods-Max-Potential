import Foundation
import AppKit

@MainActor
public final class DictationTriggerManager: ObservableObject {
    public static let shared = DictationTriggerManager()
    
    @Published public var isEnabled: Bool = false
    @Published public var lastTriggerDate: Date? = nil
    
    private var nodHistory: [Date] = []
    
    private init() {}
    
    public func recordNod() {
        guard isEnabled else { return }
        
        let now = Date()
        nodHistory.append(now)
        nodHistory.removeAll { now.timeIntervalSince($0) > 1.2 }
        
        // Double-nod detected (two nods within 1.2 seconds)
        if nodHistory.count >= 2 {
            nodHistory.removeAll()
            lastTriggerDate = now
            triggerDictation()
        }
    }
    
    private func triggerDictation() {
        MotionManager.shared.playFeedbackSound("Hero")
        
        // Trigger macOS Dictation shortcut (fn fn) or speech recognition
        let script = "tell application \"System Events\" to key code 63"
        if let appleScript = NSAppleScript(source: script) {
            _ = appleScript.executeAndReturnError(nil)
        }
    }
}
