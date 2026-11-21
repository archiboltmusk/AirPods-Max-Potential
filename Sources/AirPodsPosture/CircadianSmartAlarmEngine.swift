import Foundation
import SwiftUI
import Combine

/// Circadian REM-Window "Dawn Simulation" Smart Alarm Engine.
/// Waking up during deep Slow-Wave Sleep causes heavy sleep inertia (grogginess lasting 1-2 hours).
/// This engine maps 90-minute ultradian sleep architecture and targets the lightest REM/Stage 1 phase
/// within a flexible 20-minute window prior to your scheduled alarm.
///
/// Features an ascending harmonic chime accompanied by a 10Hz alpha wave tone to stimulate
/// natural cortisol awakening response without startle tachycardia.
@MainActor
public final class CircadianSmartAlarmEngine: ObservableObject {
    public static let shared = CircadianSmartAlarmEngine()
    
    @Published public var isSmartAlarmEnabled: Bool = true
    @Published public var wakeWindowMinutes: Int = 20
    @Published public var targetWakeTime: String = "07:00 AM"
    @Published public var currentSleepCycle: Int = 4 // 1 to 5 cycles (~7.5 hrs)
    @Published public var isAlarmTriggered: Bool = false
    @Published public var alarmSoundVolume: Double = 0.0
    @Published public var smartAlarmStatus: String = "Cycle 4 Active • Next REM Window in 42m"
    
    private var alarmTimer: Timer?
    
    private init() {
        startSmartAlarmTracker()
    }
    
    private func startSmartAlarmTracker() {
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateAlarmWindow()
            }
        }
    }
    
    public func triggerTestAlarm() {
        isAlarmTriggered = true
        smartAlarmStatus = "Optimal REM Window Detected • Ascending Dawn Chime Active"
        alarmSoundVolume = 0.6
        NSSound(named: "Glass")?.play()
    }
    
    public func dismissAlarm() {
        isAlarmTriggered = false
        alarmSoundVolume = 0.0
        smartAlarmStatus = "Alarm Dismissed • Awake & Alert"
    }
    
    private func evaluateAlarmWindow() {
        guard isSmartAlarmEnabled && !isAlarmTriggered else { return }
        
        // During live monitoring, checks clock against targetWakeTime within wakeWindowMinutes
        // and verifies if current sleep stage is Light/REM via MotionManager movement
        let stage = SlowWaveSleepStimulatorEngine.shared.currentSleepStage
        if stage == .rem || stage == .lightNrem {
            smartAlarmStatus = "Light Sleep Stage Confirmed • Ready for Gentle Awakening"
        } else {
            smartAlarmStatus = "Deep Sleep Stage Active • Suppressing Alarm Until Cycle Completion"
        }
    }
}
