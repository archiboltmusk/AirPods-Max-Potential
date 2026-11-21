import Foundation
import AVFoundation

@MainActor
public final class SpatialAudioBiofeedback: ObservableObject {
    public static let shared = SpatialAudioBiofeedback()
    
    @Published public var isEnabled: Bool = false
    @Published public var isDemoPlaying: Bool = false
    @Published public var filterCutoffHz: Float = 20000.0 // 20kHz (open) down to 2kHz (muffled slouch)
    
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
            
            // Synthesize pleasant pink/ambient focus noise buffer
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
                    for ch in 0..<Int(format.channelCount) {
                        channels[ch][i] = pink * 0.35
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
    
    public func updateSlouchMuffle(deltaPitch: Double, threshold: Double) {
        // As user slouches forward (pitch deviates), smoothly drop low-pass cutoff
        let deviation = abs(deltaPitch)
        if deviation <= threshold {
            filterCutoffHz = 20000.0 // Pristine open spatial audio
        } else {
            let excess = min(deviation - threshold, 20.0)
            let ratio = Float(1.0 - (excess / 20.0)) // 1.0 down to 0.0
            filterCutoffHz = max(800.0, 800.0 + (ratio * 19200.0))
        }
        
        if let eq = lowPassFilter, eq.bands.count > 0 {
            eq.bands[0].frequency = filterCutoffHz
        }
    }
}
