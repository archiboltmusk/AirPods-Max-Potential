import Foundation
import SwiftUI
import Combine
import AppKit

/// AirPods In-Case & Work-Session Lifecycle Manager.
/// When AirPods are put back into their charging case, the user's focus/listening session is finished.
/// Running background webcam tracking, audio decibel polling, or IMU loops is unnecessary and wasteful.
///
/// This manager coordinates:
/// 1. Immediate termination of camera and audio sensors (0.0% CPU utilization).
/// 2. Mode A: Deep Hibernation (sleeps silently in menu bar until AirPods reconnect).
/// 3. Mode B: Auto-Quit (gracefully terminates the app 15 seconds after AirPods enter their case).
@MainActor
public final class AirPodsInCaseLifecycleManager: ObservableObject {
    public static let shared = AirPodsInCaseLifecycleManager()
    
    @Published public var isInCase: Bool = false
    @Published public var actionOnCaseIn: ActionOnCaseIn = .deepHibernate {
        didSet {
            UserDefaults.standard.set(actionOnCaseIn.rawValue, forKey: "actionOnCaseIn")
        }
    }
    @Published public var isCountingDownToQuit: Bool = false
    @Published public var quitCountdownRemaining: Int = 15
    @Published public var lifecycleStatusMessage: String = "Monitoring Active Session"
    
    public enum ActionOnCaseIn: String, CaseIterable, Identifiable {
        case deepHibernate = "Deep Hibernate (0.0% CPU • Sleep in Menu Bar)"
        case autoQuit = "Auto-Quit App (15s Countdown After In-Case)"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .deepHibernate: return "moon.zzz.fill"
            case .autoQuit: return "power"
            }
        }
    }
    
    private var countdownTimer: Timer?
    
    private init() {
        if let savedAction = UserDefaults.standard.string(forKey: "actionOnCaseIn"),
           let action = ActionOnCaseIn(rawValue: savedAction) {
            self.actionOnCaseIn = action
        }
    }
    
    /// Triggered immediately when AirPods disconnect (placed in charging case)
    public func handleAirPodsPlacedInCase() {
        isInCase = true
        
        // 1. Immediately shut down optical webcam sentinel to protect privacy & battery
        if OpticalContinuitySentinel.shared.isRunning {
            OpticalContinuitySentinel.shared.stopSentinel()
        }
        
        // 2. Stop audio environment monitoring and active soundscapes
        if AdaptiveNightSoundscapeEngine.shared.isSoundscapeActive {
            AdaptiveNightSoundscapeEngine.shared.isSoundscapeActive = false
        }
        
        // 3. Act based on configured user preference
        switch actionOnCaseIn {
        case .deepHibernate:
            isCountingDownToQuit = false
            countdownTimer?.invalidate()
            countdownTimer = nil
            lifecycleStatusMessage = "AirPods in Case • Work Complete (0.0% CPU Standby)"
            
        case .autoQuit:
            startQuitCountdown()
        }
    }
    
    /// Triggered immediately when AirPods are removed from case and reconnect
    public func handleAirPodsRemovedFromCase() {
        isInCase = false
        isCountingDownToQuit = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        lifecycleStatusMessage = "AirPods Connected • Session Active"
    }
    
    public func cancelQuitCountdown() {
        isCountingDownToQuit = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        lifecycleStatusMessage = "Auto-Quit Cancelled • Hibernating in Menu Bar"
    }
    
    public func quitAppNow() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        NSApplication.shared.terminate(nil)
    }
    
    private func startQuitCountdown() {
        isCountingDownToQuit = true
        quitCountdownRemaining = 15
        lifecycleStatusMessage = "AirPods in case • Work complete. Quitting in \(quitCountdownRemaining)s..."
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.quitCountdownRemaining > 1 {
                    self.quitCountdownRemaining -= 1
                    self.lifecycleStatusMessage = "AirPods in case • Quitting in \(self.quitCountdownRemaining)s..."
                } else {
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
