import Foundation
import AppKit

@MainActor
public final class TypingFlowStateGatingManager: ObservableObject {
    public static let shared = TypingFlowStateGatingManager()
    
    @Published public var isFlowGatingEnabled: Bool = true
    @Published public var currentWPM: Int = 0
    @Published public var isDeepCodingFlowActive: Bool = false
    @Published public var deferredAlertPending: Bool = false
    @Published public var statusMessage: String = "Typing Flow Gate Active"
    
    private var keypressTimestamps: [Date] = []
    private var lastKeypressTime: Date?
    private var eventMonitor: Any?
    
    private init() {
        startTypingMonitor()
    }
    
    private func startTypingMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.recordKeypress()
            }
            return event
        }
    }
    
    private func recordKeypress() {
        guard isFlowGatingEnabled else { return }
        
        let now = Date()
        lastKeypressTime = now
        keypressTimestamps.append(now)
        
        // Rolling 5-second window to calculate typing velocity (WPM)
        keypressTimestamps.removeAll { now.timeIntervalSince($0) > 5.0 }
        
        // Standard typing speed calculation: (characters / 5) * (60 / elapsed seconds)
        let charsInWindow = keypressTimestamps.count
        let wpm = Int((Double(charsInWindow) / 5.0) * (60.0 / 5.0))
        currentWPM = wpm
        
        if wpm > 45 {
            isDeepCodingFlowActive = true
            statusMessage = "🔥 Deep Flow Detected (\(wpm) WPM) • Posture Alerts Delayed"
        } else {
            isDeepCodingFlowActive = false
            statusMessage = "Standard Pace (\(wpm) WPM)"
            
            // If an alert was deferred and typing paused for > 2 seconds, trigger deferred alert
            if deferredAlertPending {
                deferredAlertPending = false
                MotionManager.shared.triggerSlouchAlert()
            }
        }
    }
    
    public func shouldSuppressAlertForFlow() -> Bool {
        guard isFlowGatingEnabled else { return false }
        
        if isDeepCodingFlowActive {
            deferredAlertPending = true
            return true // Suppress alert while typing code actively
        }
        return false
    }
}
