import Foundation
import Combine

@MainActor
public final class AcousticRespiratoryEngine: ObservableObject {
    public static let shared = AcousticRespiratoryEngine()
    
    @Published public var isMonitoring: Bool = true
    @Published public var breathsPerMinute: Int = 14 // Normal healthy adult range: 12 - 18
    @Published public var breathingPattern: String = "Normal Diaphragmatic"
    @Published public var screenApneaDetected: Bool = false
    @Published public var breathSamplesCount: Int = 0
    
    // Low-frequency micro-tilt wave samples (0.15 - 0.45 Hz)
    private var pitchSamples: [Double] = []
    private var lastBreathHoldStartTime: Date?
    
    private init() {}
    
    public func update(pitch: Double, userAccelZ: Double, totalEnergy: Double) {
        guard isMonitoring else { return }
        
        // During seated desk stillness (totalEnergy < 0.015g), breathing causes subtle thoracic expansion
        // that tilts the skull forward and backward at 0.2 - 0.35 Hz (12 - 20 breaths/min)
        if totalEnergy < 0.015 {
            pitchSamples.append(pitch)
            if pitchSamples.count > 180 { // ~3 seconds at 60Hz
                pitchSamples.removeFirst()
            }
            
            breathSamplesCount += 1
            
            // Peak-to-peak frequency detection for breath cycle
            if breathSamplesCount % 60 == 0 && pitchSamples.count >= 120 {
                analyzeBreathCycle()
            }
        } else {
            // Movement disrupts breathing estimation
            breathingPattern = "Movement / Speaking"
        }
    }
    
    private func analyzeBreathCycle() {
        let mean = pitchSamples.reduce(0.0, +) / Double(pitchSamples.count)
        var zeroCrossings = 0
        
        for i in 1..<pitchSamples.count {
            if (pitchSamples[i-1] - mean) * (pitchSamples[i] - mean) < 0 {
                zeroCrossings += 1
            }
        }
        
        let cycles = Double(zeroCrossings) / 2.0
        let seconds = Double(pitchSamples.count) / 60.0
        let freqHz = cycles / seconds
        let bpm = Int(freqHz * 60.0)
        
        if bpm >= 8 && bpm <= 28 {
            breathsPerMinute = (breathsPerMinute * 4 + bpm) / 5
            
            if breathsPerMinute > 20 {
                breathingPattern = "Rapid / Shallow (Sympathetic Stress)"
            } else if breathsPerMinute < 10 {
                breathingPattern = "Slow & Deep (Parasympathetic Relaxation)"
            } else {
                breathingPattern = "Optimal Diaphragmatic Rhythm"
            }
            screenApneaDetected = false
        } else if bpm < 6 {
            // Screen Apnea: Unconsciously holding breath while reading or writing complex code
            screenApneaDetected = true
            breathingPattern = "⚠️ Screen Apnea: Inhale deeply and exhale!"
        }
    }
}
