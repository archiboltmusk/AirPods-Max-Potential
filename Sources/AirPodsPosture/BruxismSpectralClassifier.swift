import Foundation
import Combine

/// Spectral Cadence & Mastication Rejection Classifier.
/// Distinguishes rhythmic chewing (eating lunch, chewing gum at 1.0–1.8 Hz)
/// and vocal tract speech vibrations from true isometric TMJ jaw clenching and nocturnal bruxism.
@MainActor
public final class BruxismSpectralClassifier: ObservableObject {
    public static let shared = BruxismSpectralClassifier()
    
    @Published public var isChewingDetected: Bool = false
    @Published public var isSpeakingSuppressed: Bool = false
    @Published public var trueClenchDetected: Bool = false
    @Published public var rejectedChewingEventsCount: Int = 0
    @Published public var statusMessage: String = "Monitoring Jaw Kinematics"
    
    private var cycleTimestamps: [Date] = []
    private var lastPeakValue: Double = 0.0
    private var isRising: Bool = false
    
    private init() {}
    
    /// Evaluates user dynamic acceleration for chewing cadence vs isometric clench
    public func evaluateKinematics(accelMagnitude: Double, microJitter: Double) -> Bool {
        let now = Date()
        
        // 1. Check if speech is currently active (via Conversation Ducking or Active VoIP Call)
        if ConversationDuckingEngine.shared.isConversationActive || CallActivitySentinel.shared.isInCall {
            isSpeakingSuppressed = true
            isChewingDetected = false
            trueClenchDetected = false
            return false // Mute bruxism detection during active vocalization
        } else {
            isSpeakingSuppressed = false
        }
        
        // 2. Detect cyclic cadence for chewing (peak detector on microJitter)
        if microJitter > 0.040 && !isRising && microJitter > lastPeakValue {
            isRising = true
        } else if microJitter < lastPeakValue && isRising {
            isRising = false
            cycleTimestamps.append(now)
            // Keep window of last 6 cycles (~3-5 seconds)
            cycleTimestamps.removeAll { now.timeIntervalSince($0) > 4.0 }
        }
        lastPeakValue = microJitter
        
        // Compute cadence frequency (Hz)
        if cycleTimestamps.count >= 3 {
            let intervals = zip(cycleTimestamps, cycleTimestamps.dropFirst()).map { $1.timeIntervalSince($0) }
            let avgInterval = intervals.reduce(0.0, +) / Double(intervals.count)
            let frequencyHz = avgInterval > 0 ? (1.0 / avgInterval) : 0.0
            
            // Typical mastication / chewing cycle is 1.0 Hz - 1.8 Hz
            if frequencyHz >= 0.9 && frequencyHz <= 2.0 {
                if !isChewingDetected {
                    isChewingDetected = true
                    rejectedChewingEventsCount += 1
                    statusMessage = "🍽️ Mastication / Chewing Detected • TMJ Alarm Suppressed"
                }
                trueClenchDetected = false
                return false // Suppress TMJ alert
            }
        }
        
        isChewingDetected = false
        
        // 3. True Isometric Clench: sustained high micro-jitter without sinusoidal cyclic repetition
        let isIsometricLock = (microJitter > 0.045 && accelMagnitude < 0.22)
        trueClenchDetected = isIsometricLock
        if trueClenchDetected {
            statusMessage = "⚠️ True Isometric Jaw Clench Detected"
        }
        return trueClenchDetected
    }
}
