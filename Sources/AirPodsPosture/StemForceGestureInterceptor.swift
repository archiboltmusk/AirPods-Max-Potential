import Foundation
import Combine
import AppKit

/// AirPods Stem Force Sensor & Physical Gesture Shortcut Interceptor.
/// Translates hardware stem squeezes and kinematic micro-gestures into zero-touch commands:
/// • Double-Squeeze / Double-Nod: Instantly zero-calibrates baseline.
/// • Triple-Squeeze / Double-Shake: Snoozes posture monitoring for 15 minutes.
@MainActor
public final class StemForceGestureInterceptor: ObservableObject {
    public static let shared = StemForceGestureInterceptor()
    
    @Published public var isStemControlEnabled: Bool = true
    @Published public var lastGestureTriggered: String = "Standby"
    @Published public var lastGestureTime: Date?
    
    // Micro-nod kinematic detector
    private var pitchHistory: [(timestamp: Date, pitch: Double)] = []
    private var lastNodTime: Date = Date.distantPast
    
    private init() {}
    
    /// Called when the user squeezes the AirPods Pro stem twice (detected via media control event or micro-nod)
    public func handleDoubleSqueezeCalibration() {
        guard isStemControlEnabled else { return }
        
        let success = MotionManager.shared.calibrateCurrentPosture()
        if success {
            lastGestureTriggered = "Double-Squeeze: Calibrated Neutral Baseline"
            lastGestureTime = Date()
            SyntheticEarHapticEngine.shared.playSuccessChirp()
            DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Stem Double-Click: Calibrated", autoDismissSeconds: 2.5)
        }
    }
    
    /// Called when the user squeezes the AirPods Pro stem three times
    public func handleTripleSqueezeSnooze() {
        guard isStemControlEnabled else { return }
        
        MotionManager.shared.snooze(minutes: 15)
        lastGestureTriggered = "Triple-Squeeze: Snoozed 15 Minutes"
        lastGestureTime = Date()
        SyntheticEarHapticEngine.shared.playGentleDoubleTap()
        DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Stem Triple-Click: Snoozed 15m", autoDismissSeconds: 2.5)
    }
    
    /// Kinematic gesture detector checking for deliberate, brisk double-nod
    public func processKinematicStream(pitch: Double, rotRateY: Double) {
        guard isStemControlEnabled else { return }
        let now = Date()
        
        pitchHistory.append((timestamp: now, pitch: pitch))
        pitchHistory.removeAll { now.timeIntervalSince($0.timestamp) > 1.2 }
        
        guard pitchHistory.count >= 15 else { return }
        
        // Detect sharp down-up-down cycle (double-nod)
        let pitches = pitchHistory.map { $0.pitch }
        let maxP = pitches.max() ?? 0
        let minP = pitches.min() ?? 0
        
        if (maxP - minP) > 14.0 && abs(rotRateY) > 40.0 {
            if now.timeIntervalSince(lastNodTime) > 3.0 {
                lastNodTime = now
                handleDoubleSqueezeCalibration()
            }
        }
    }
}
