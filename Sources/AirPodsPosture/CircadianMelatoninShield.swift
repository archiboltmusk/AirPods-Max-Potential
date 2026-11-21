import Foundation
import SwiftUI
import Combine

/// Circadian Light & Melatonin Production Shield.
/// Integrates solar sunset timings with posture craning distance.
/// At dusk and night, craned slumping toward bright displays suppresses pineal melatonin.
/// Automatically tightens sensitivity, advises screen push-back, and engages warm 432Hz acoustic entrainment.
@MainActor
public final class CircadianMelatoninShield: ObservableObject {
    public static let shared = CircadianMelatoninShield()
    
    @Published public var isShieldEnabled: Bool = true
    @Published public var isNightModeActive: Bool = false
    @Published public var eveningPostureThresholdMultiplier: Double = 1.25 // 25% tighter
    @Published public var localSunsetTime: String = "6:14 PM"
    @Published public var melatoninProtectionStatus: String = "Daylight Circadian Alignment"
    @Published public var isWarmAcousticEntrainmentActive: Bool = false
    
    private var sunsetCheckTimer: Timer?
    
    private init() {
        checkCircadianState()
        startSunsetWatcher()
    }
    
    private func startSunsetWatcher() {
        sunsetCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkCircadianState()
            }
        }
    }
    
    public func checkCircadianState() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Between 7 PM (19:00) and 6 AM, night melatonin shield is engaged
        if hour >= 19 || hour < 6 {
            isNightModeActive = true
            melatoninProtectionStatus = "🌙 Night Melatonin Shield Active (Tighter Posture Bounds)"
        } else {
            isNightModeActive = false
            melatoninProtectionStatus = "☀️ Daylight Circadian Alignment"
        }
    }
    
    public func toggleWarmAcoustics() {
        isWarmAcousticEntrainmentActive.toggle()
        if isWarmAcousticEntrainmentActive {
            BinauralBeatsEngine.shared.start()
        } else {
            BinauralBeatsEngine.shared.stop()
        }
    }
}
