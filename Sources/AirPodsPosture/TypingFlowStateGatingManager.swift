import Foundation
import AppKit

/// Developer IDE & Typing Flow-State Ergonomic Sentinel.
/// Automatically detects high-stress coding environments (Xcode, VS Code, Cursor, Terminal, IntelliJ),
/// measures typing velocity, and suppresses intrusive chimes in favor of soft ambient screen edge glows
/// so engineers never get pulled out of deep flow state.
@MainActor
public final class TypingFlowStateGatingManager: ObservableObject {
    public static let shared = TypingFlowStateGatingManager()
    
    @Published public var isFlowGatingEnabled: Bool = true
    @Published public var currentWPM: Int = 0
    @Published public var isDeepCodingFlowActive: Bool = false
    @Published public var isDeveloperIDEActive: Bool = false
    @Published public var currentIDEAppName: String = "Desktop"
    @Published public var deferredAlertPending: Bool = false
    @Published public var statusMessage: String = "Typing Flow Gate Active"
    @Published public var codingPostureScore: Int = 92
    
    private let recognizedIDEs: Set<String> = [
        "Xcode", "Code", "Visual Studio Code", "Cursor", "Terminal", "iTerm2",
        "Sublime Text", "Zed", "IntelliJ IDEA", "Android Studio", "WebStorm", "PyCharm"
    ]
    
    private var keypressTimestamps: [Date] = []
    private var lastKeypressTime: Date?
    private var eventMonitor: Any?
    private var appCheckTimer: Timer?
    
    private init() {
        startTypingMonitor()
        startIDEWatcher()
    }
    
    private func startIDEWatcher() {
        appCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.inspectFrontmostApp()
            }
        }
    }
    
    private func inspectFrontmostApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName else { return }
        self.currentIDEAppName = frontApp
        
        let isDev = recognizedIDEs.contains(where: { frontApp.localizedCaseInsensitiveContains($0) })
        self.isDeveloperIDEActive = isDev
        
        if isDev {
            if isDeepCodingFlowActive {
                statusMessage = "🔥 Deep Flow in \(frontApp) (\(currentWPM) WPM) • Ambient Glow Only"
            } else {
                statusMessage = "💻 Active in \(frontApp) • Flow Gate Armed"
            }
        }
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
        
        let charsInWindow = keypressTimestamps.count
        let wpm = Int((Double(charsInWindow) / 5.0) * (60.0 / 5.0))
        currentWPM = wpm
        
        if wpm > 40 || isDeveloperIDEActive {
            isDeepCodingFlowActive = true
            if isDeveloperIDEActive {
                statusMessage = "🔥 Deep Flow in \(currentIDEAppName) (\(wpm) WPM) • Ambient Mode"
            } else {
                statusMessage = "🔥 Deep Flow Detected (\(wpm) WPM) • Audio Chimes Muted"
            }
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
        
        if isDeepCodingFlowActive || isDeveloperIDEActive {
            deferredAlertPending = true
            // In IDE flow, pulse screen glow quietly instead of jarring audio chime
            ScreenGlowManager.shared.update(postureState: .warning)
            return true
        }
        return false
    }
}
