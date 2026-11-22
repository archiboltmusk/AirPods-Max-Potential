import Foundation
import AVFoundation

/// Spatial Audio Soundstage Gravitation Engine.
/// Anchors acoustic soundstage to calibrated upright posture coordinates.
/// As posture drifts or slouches, audio dissipates with progressive acoustic occlusion and spatial pan,
/// triggering subconscious operant neuro-motor correction back to neutral alignment.
@MainActor
public final class SpatialAudioBiofeedback: ObservableObject {
    public static let shared = SpatialAudioBiofeedback()
    
    @Published public var isEnabled: Bool = false
    @Published public var isDemoPlaying: Bool = false
    @Published public var filterCutoffHz: Float = 20000.0 // 20kHz (open) down to 600Hz (occluded)
    @Published public var soundstagePan: Float = 0.0 // -1.0 (Left) to +1.0 (Right)
    @Published public var soundstageElevation: Float = 0.0 // 0.0 (Eye Level) to 1.0 (Overhead)
    @Published public var acousticOcclusionPercent: Int = 0
    
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var lowPassFilter: AVAudioUnitEQ?
    
    private init() {}
    
    public func startDemoSoundscape() {
        guard !isDemoPlaying else { return }
        
        do {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            let eq = AVAudioUnitEQ(numberOfBands: 1)
            
            let filterBand = eq.bands[0]
            filterBand.filterType = .lowPass
            filterBand.frequency = filterCutoffHz
            filterBand.bypass = false
            
            engine.attach(player)
            engine.attach(eq)
            
            let format = engine.outputNode.outputFormat(forBus: 0)
            engine.connect(player, to: eq, format: format)
            engine.connect(eq, to: engine.mainMixerNode, format: format)
            
            // Synthesize pleasant pink/ambient 40Hz gamma focus noise buffer
            let sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44100)
            let frameCount = AVAudioFrameCount(sampleRate * 2.0)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            buffer.frameLength = frameCount
            
            if let channels = buffer.floatChannelData {
                var b0: Float = 0, b1: Float = 0, b2: Float = 0
                for i in 0..<Int(frameCount) {
                    let white = (Float.random(in: -1.0...1.0)) * 0.12
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    let pink = b0 + b1 + b2 + white * 0.5362
                    
                    // Subtle 40Hz Gamma wave modulation for neuro-focus
                    let t = Float(i) / sampleRate
                    let gamma = sin(2.0 * .pi * 40.0 * t) * 0.04
                    
                    for ch in 0..<Int(format.channelCount) {
                        channels[ch][i] = (pink * 0.30) + gamma
                    }
                }
            }
            
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()
            
            self.engine = engine
            self.player = player
            self.lowPassFilter = eq
            self.isDemoPlaying = true
        } catch {
            print("SpatialAudioBiofeedback error:", error.localizedDescription)
        }
    }
    
    public func stopDemoSoundscape() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        lowPassFilter = nil
        isDemoPlaying = false
    }
    
    /// Legacy compatibility alias for MotionManager
    public func updateSlouchMuffle(deltaPitch: Double, threshold: Double) {
        updateGravitation(deltaPitch: deltaPitch, deltaRoll: 0.0, threshold: threshold)
    }
    
    /// Updates soundstage gravitation vector from pitch and roll kinematics
    public func updateGravitation(deltaPitch: Double, deltaRoll: Double, threshold: Double) {
        let pitchDev = abs(deltaPitch)
        let rollDev = deltaRoll
        
        // 1. Acoustic Occlusion (Filter Cutoff)
        if pitchDev <= threshold {
            filterCutoffHz = 20000.0
            acousticOcclusionPercent = 0
            soundstageElevation = 0.0
        } else {
            let excess = min(pitchDev - threshold, 25.0)
            let ratio = Float(excess / 25.0) // 0.0 to 1.0
            acousticOcclusionPercent = Int(ratio * 100.0)
            
            // Frequency drops exponentially from 20kHz down to 650Hz
            filterCutoffHz = max(650.0, 20000.0 - (ratio * 19350.0))
            soundstageElevation = ratio // Virtual sound lifts overhead/behind
        }
        
        // 2. Spatial Pan Gravitation (Pulls soundstage against the direction of tilt)
        let clampedRoll = Float(max(-30.0, min(30.0, rollDev)))
        self.soundstagePan = -(clampedRoll / 30.0) // If tilted right, sound moves left to pull head back
        
        // Apply to audio engine
        if let eq = lowPassFilter, eq.bands.count > 0 {
            eq.bands[0].frequency = filterCutoffHz
        }
        if let player = player {
            player.pan = soundstagePan
        }
    }
}
