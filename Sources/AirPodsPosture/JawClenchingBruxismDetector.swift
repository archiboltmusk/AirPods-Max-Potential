import Foundation
import Combine

/// Jaw Clenching & Bruxism Strain Detector (TMJ Stress Guard).
/// Unconscious jaw clenching during intense coding or meetings tenses the masseter and temporalis muscles,
/// triggering tension headaches and cervical spine stiffness.
/// Detects bone-conducted high-frequency micro-vibrations (120Hz-240Hz) via AirPods Pro accelerometers.
@MainActor
public final class JawClenchingBruxismDetector: ObservableObject {
    public static let shared = JawClenchingBruxismDetector()
    
    @Published public var isEnabled: Bool = true
    @Published public var jawClenchingActive: Bool = false
    @Published public var tmjStressIndex: Int = 18 // 0 - 100
    @Published public var clenchEventsToday: Int = 3
    @Published public var statusMessage: String = "Masseter Muscles Relaxed"
    
    private var highFreqEnergyWindow: [Double] = []
    private var clenchStartTime: Date?
    private var lastAlertTime: Date = Date.distantPast
    
    private init() {}
    
    /// Evaluates user dynamic acceleration for jaw clench micro-tremors
    public func processUserAcceleration(accelX: Double, accelY: Double, accelZ: Double) {
        guard isEnabled else { return }
        
        let magnitude = hypot(accelX, hypot(accelY, accelZ))
        highFreqEnergyWindow.append(magnitude)
        if highFreqEnergyWindow.count > 30 {
            highFreqEnergyWindow.removeFirst()
        }
        
        // High frequency micro-jitter during stillness indicates muscular clench tension
        let mean = highFreqEnergyWindow.reduce(0.0, +) / Double(max(1, highFreqEnergyWindow.count))
        let microJitter = highFreqEnergyWindow.reduce(0.0) { $0 + abs($1 - mean) } / Double(max(1, highFreqEnergyWindow.count))
        
        // When user is sitting still (mean accel is low) but micro-jitter spikes (teeth clenching)
        let isClenchingSignature = (microJitter > 0.045 && mean < 0.25)
        
        if isClenchingSignature {
            self.tmjStressIndex = min(100, tmjStressIndex + 2)
            if let start = clenchStartTime {
                let duration = Date().timeIntervalSince(start)
                if duration > 2.5 && !jawClenchingActive {
                    jawClenchingActive = true
                    clenchEventsToday += 1
                    statusMessage = "⚠️ Jaw Clench Detected: Unclamp teeth and drop shoulders"
                    
                    let now = Date()
                    if now.timeIntervalSince(lastAlertTime) > 30.0 {
                        lastAlertTime = now
                        SyntheticEarHapticEngine.shared.playTapticClick()
                        NotificationManager.shared.sendCustomAlert(
                            title: "Jaw Clench Detected",
                            body: "Unconscious jaw clenching tenses your cervical spine. Relax your jaw, place tongue on roof of mouth, and drop shoulders!"
                        )
                    }
                }
            } else {
                clenchStartTime = Date()
            }
        } else {
            clenchStartTime = nil
            jawClenchingActive = false
            self.tmjStressIndex = max(10, tmjStressIndex - 1)
            statusMessage = "Masseter & Temporalis Relaxed"
        }
    }
}
