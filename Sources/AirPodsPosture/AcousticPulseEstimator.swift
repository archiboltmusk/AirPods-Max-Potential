import Foundation

@MainActor
public final class AcousticPulseEstimator: ObservableObject {
    public static let shared = AcousticPulseEstimator()
    
    @Published public var isEnabled: Bool = true
    @Published public var isCalibrated: Bool = true
    @Published public var estimatedBPM: Int = 68
    @Published public var signalQuality: String = "Good"
    @Published public var isAnalyzing: Bool = false
    
    public var statusMessage: String { signalQuality }
    
    private var accelSamples: [Double] = []
    
    private init() {}
    
    public func update(userAccelZ: Double, totalEnergy: Double) {
        // If user is resting still (totalEnergy < 0.008g)
        if totalEnergy < 0.008 {
            isAnalyzing = true
            accelSamples.append(userAccelZ)
            if accelSamples.count > 150 {
                accelSamples.removeFirst()
            }
            
            // Peak frequency analysis for pulse (approx 1.0 - 1.5 Hz = 60-90 BPM)
            if accelSamples.count >= 60 {
                let mean = accelSamples.reduce(0.0, +) / Double(accelSamples.count)
                var zeroCrossings = 0
                for i in 1..<accelSamples.count {
                    if (accelSamples[i-1] - mean) * (accelSamples[i] - mean) < 0 {
                        zeroCrossings += 1
                    }
                }
                
                let estimatedFreq = (Double(zeroCrossings) / 2.0) / (Double(accelSamples.count) / 50.0)
                let bpm = Int(max(55.0, min(95.0, estimatedFreq * 60.0)))
                estimatedBPM = (estimatedBPM * 19 + bpm) / 20
                signalQuality = "Stable (Resting)"
            }
        } else {
            isAnalyzing = false
            signalQuality = "Movement Detected"
        }
    }
}
