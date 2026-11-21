import Foundation
import AVFoundation

@MainActor
public final class SyntheticEarHapticEngine: ObservableObject {
    public static let shared = SyntheticEarHapticEngine()
    
    @Published public var isHapticAudioEnabled: Bool = true
    @Published public var hapticVolume: Float = 0.35
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
        guard let format = format else { return }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
            self.audioEngine = engine
            self.playerNode = player
            self.audioFormat = format
        } catch {
            print("Failed to start SyntheticEarHapticEngine: \(error)")
        }
    }
    
    /// Generates a single crisp 12ms synthetic Taptic tick (simulates Apple Watch digital crown / haptic engine)
    public func playTapticClick() {
        guard isHapticAudioEnabled, let format = audioFormat, let player = playerNode else { return }
        
        let sampleRate = format.sampleRate
        let durationSeconds = 0.015 // 15 ms
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return }
        
        let baseFreq = 160.0 // 160Hz low resonant thump
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // Exponential rapid decay envelope: e^(-t * 280)
            let envelope = exp(-t * 280.0) * Double(hapticVolume)
            let sample = Float(sin(2.0 * .pi * baseFreq * t) * envelope)
            
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
    
    /// Generates a double micro-tap for warning threshold transitions
    public func playGentleDoubleTap() {
        playTapticClick()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.playTapticClick()
        }
    }
    
    /// Generates a crisp rising resonant tick on successful calibration lock
    public func playSuccessChirp() {
        guard isHapticAudioEnabled, let format = audioFormat, let player = playerNode else { return }
        
        let sampleRate = format.sampleRate
        let durationSeconds = 0.04 // 40 ms
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return }
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / durationSeconds
            let freq = 520.0 + (progress * 440.0) // 520Hz rising to 960Hz
            let envelope = sin(.pi * progress) * Double(hapticVolume * 0.7)
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope)
            
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
}
