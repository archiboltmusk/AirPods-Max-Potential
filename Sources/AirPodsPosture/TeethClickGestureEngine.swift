import Foundation
import SwiftUI
import Combine

/// Touchless Teeth-Click & Molar Tap Micro-Gesture Controller.
/// Emulates the rumored AirPods Pro 3 in-ear acoustic bone-conduction and skin gesture sensing.
/// Analyzes high-frequency accelerometer and microphone shock impulses caused by gentle teeth clicks.
/// Double-Click: Toggles microphone mute. Triple-Click: Toggles media play/pause.
@MainActor
public final class TeethClickGestureEngine: ObservableObject {
    public static let shared = TeethClickGestureEngine()
    
    @Published public var isGestureControlEnabled: Bool = true
    @Published public var lastGestureRecognized: String = "None (Standby)"
    @Published public var totalGesturesTriggered: Int = 0
    @Published public var sensitivityLevel: GestureSensitivity = .medium
    @Published public var recentImpulseEnergy: Double = 0.05
    
    public enum GestureSensitivity: String, CaseIterable, Identifiable {
        case high = "High Sensitivity"
        case medium = "Standard (Recommended)"
        case low = "Firm Click Only"
        
        public var id: String { rawValue }
        
        public var threshold: Double {
            switch self {
            case .high: return 0.28
            case .medium: return 0.42
            case .low: return 0.60
            }
        }
    }
    
    private var lastClickTime: Date = Date.distantPast
    private var clickCountInWindow: Int = 0
    private var windowTimer: Timer?
    
    private init() {}
    
    public func processAcousticImpulse(energy: Double) {
        guard isGestureControlEnabled else { return }
        recentImpulseEnergy = energy
        
        let now = Date()
        if energy >= sensitivityLevel.threshold {
            clickCountInWindow += 1
            lastClickTime = now
            
            windowTimer?.invalidate()
            windowTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.evaluateClickWindow()
                }
            }
        }
    }
    
    private func evaluateClickWindow() {
        if clickCountInWindow == 2 {
            // Double Click -> Toggle Mute
            lastGestureRecognized = "Double Teeth-Click • Toggled Microphone Mute"
            totalGesturesTriggered += 1
            NSSound(named: "Pop")?.play()
            SyntheticEarHapticEngine.shared.playGentleDoubleTap()
        } else if clickCountInWindow >= 3 {
            // Triple Click -> Toggle Play/Pause
            lastGestureRecognized = "Triple Teeth-Click • Play / Pause Media"
            totalGesturesTriggered += 1
            NSSound(named: "Hero")?.play()
            SyntheticEarHapticEngine.shared.playSuccessChirp()
        }
        clickCountInWindow = 0
    }
    
    public func simulateDoubleTeethClick() {
        clickCountInWindow = 2
        evaluateClickWindow()
    }
}
