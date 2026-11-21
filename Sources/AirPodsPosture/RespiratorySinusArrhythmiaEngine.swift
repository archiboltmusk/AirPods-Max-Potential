import Foundation
import Combine

/// Respiratory Sinus Arrhythmia (RSA) & Vagal Tone Posture Synchronizer.
/// Correlates cervical spine lordosis with thoracic expansion and parasympathetic vagus nerve activation.
/// Upright posture expands thoracic volume by up to 22%, increasing Heart Rate Variability (HRV) and lowering stress.
@MainActor
public final class RespiratorySinusArrhythmiaEngine: ObservableObject {
    public static let shared = RespiratorySinusArrhythmiaEngine()
    
    // Telemetry & Vagal Tone
    @Published public var vagalToneScore: Int = 82 // 0 - 100 Index
    @Published public var rsaGainRatio: Double = 1.18 // Expiration / Inspiration HRV coupling ratio
    @Published public var thoracicExpansionPercent: Int = 94 // 100% = full neutral lordosis
    @Published public var parasympatheticState: String = "Vagal Parasympathetic Tone: Optimal"
    
    // Live Biofeedback Delta
    @Published public var hrvBoostFromUprightMs: Double = 8.4 // ms gained by avoiding thoracic compression
    
    private var syncTimer: Timer?
    
    private init() {
        startVagalLoop()
    }
    
    private func startVagalLoop() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.computeVagalDynamics()
            }
        }
    }
    
    public func computeVagalDynamics() {
        let motion = MotionManager.shared
        let respiratory = AcousticRespiratoryEngine.shared
        let watch = AppleWatchBridgeManager.shared
        
        let pitch = abs(motion.deltaPitch)
        let roll = abs(motion.deltaRoll)
        let bpm = Double(respiratory.breathsPerMinute)
        let baseHRV = watch.hrvSDNN > 0 ? watch.hrvSDNN : 52.0
        
        // Thoracic expansion: as pitch approaches 0° (neutral lordosis), chest expands fully
        let slumpPenalty = min(40.0, pitch * 1.5 + roll * 0.8)
        self.thoracicExpansionPercent = max(60, Int(100.0 - slumpPenalty))
        
        // RSA Ratio: optimal at 5.5 - 7.5 breaths/min (coherent resonance) with upright spine
        let coherenceFactor = max(0.4, 1.0 - abs(bpm - 6.0) * 0.08)
        let postureFactor = Double(self.thoracicExpansionPercent) / 100.0
        
        self.rsaGainRatio = 1.0 + (0.35 * coherenceFactor * postureFactor)
        
        // Vagal Tone Index (0-100)
        let rawTone = (baseHRV * 0.5) + (Double(self.thoracicExpansionPercent) * 0.35) + (coherenceFactor * 25.0)
        self.vagalToneScore = max(30, min(100, Int(rawTone)))
        
        // HRV Boost gained from upright posture
        self.hrvBoostFromUprightMs = max(0.0, (Double(self.thoracicExpansionPercent - 70) * 0.32))
        
        // Clinical diagnostic state
        if vagalToneScore >= 80 {
            parasympatheticState = "Vagal Tone: Coherent (Optimal Stress Recovery)"
        } else if vagalToneScore >= 60 {
            parasympatheticState = "Vagal Tone: Moderate (Minor Thoracic Compression)"
        } else {
            parasympatheticState = "Vagal Tone: Suppressed (Hunched Clavicular Breathing)"
        }
    }
}
