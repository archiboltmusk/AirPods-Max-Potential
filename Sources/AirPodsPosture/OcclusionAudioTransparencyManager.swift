import Foundation
import CoreAudio

@MainActor
public final class OcclusionAudioTransparencyManager: ObservableObject {
    public static let shared = OcclusionAudioTransparencyManager()
    
    @Published public var isFeatureEnabled: Bool = true
    @Published public var isChewingDetected: Bool = false
    @Published public var masticationEventsCount: Int = 0
    @Published public var statusMessage: String = "Laryngeal & Jaw Acoustic Guard Ready"
    
    // Rolling buffer of high-frequency gyro micro-oscillations
    private var highFreqGyroSamples: [Double] = []
    private var lastMasticationTime: Date?
    
    private init() {}
    
    public func update(rotRateX: Double, rotRateY: Double, rotRateZ: Double, userAccelZ: Double) {
        guard isFeatureEnabled else { return }
        
        let now = Date()
        
        // Mastication / Chewing creates distinctive rhythmic 1.2 - 2.5 Hz vertical jaw oscillations
        // with high-frequency micro-yaw vibration (lateral jaw articulation)
        let microVibe = sqrt(pow(rotRateX, 2) + pow(rotRateY, 2) + pow(rotRateZ, 2))
        highFreqGyroSamples.append(microVibe)
        if highFreqGyroSamples.count > 45 {
            highFreqGyroSamples.removeFirst()
        }
        
        guard highFreqGyroSamples.count >= 30 else { return }
        
        // Compute standard deviation of micro-vibrations
        let mean = highFreqGyroSamples.reduce(0.0, +) / Double(highFreqGyroSamples.count)
        let variance = highFreqGyroSamples.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(highFreqGyroSamples.count)
        let stdDev = sqrt(variance)
        
        // Chewing signature: rhythmic bursts with micro-stdDev between 14.0 and 42.0 deg/s
        if stdDev > 14.0 && stdDev < 42.0 && abs(userAccelZ) < 0.12 {
            if lastMasticationTime == nil || now.timeIntervalSince(lastMasticationTime!) > 2.0 {
                isChewingDetected = true
                masticationEventsCount += 1
                lastMasticationTime = now
                statusMessage = "Mastication / Chewing Active (Occlusion Relieved)"
                
                // Mute slouch chimes while eating to prevent false positive annoyance
                MotionManager.shared.snooze(minutes: 5)
            }
        } else {
            if let last = lastMasticationTime, now.timeIntervalSince(last) > 3.0 {
                isChewingDetected = false
                statusMessage = "Acoustic Guard Neutral"
            }
        }
    }
}
