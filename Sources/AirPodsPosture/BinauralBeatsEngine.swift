import Foundation
import AVFoundation

public enum BinauralPreset: String, CaseIterable, Identifiable {
    case gamma40 = "40 Hz Gamma (Hyper-Focus & Coding)"
    case alpha10 = "10 Hz Alpha (Relaxed Flow State)"
    case theta6 = "6 Hz Theta (Deep Creative Insight)"
    
    public var id: String { rawValue }
    
    public var beatFrequency: Double {
        switch self {
        case .gamma40: return 40.0
        case .alpha10: return 10.0
        case .theta6: return 6.0
        }
    }
    
    public var baseCarrierFrequency: Double {
        switch self {
        case .gamma40: return 200.0 // 200 Hz Left, 240 Hz Right
        case .alpha10: return 210.0 // 210 Hz Left, 220 Hz Right
        case .theta6: return 150.0  // 150 Hz Left, 156 Hz Right
        }
    }
}

@MainActor
public final class BinauralBeatsEngine: ObservableObject {
    public static let shared = BinauralBeatsEngine()
    
    @Published public var isPlaying: Bool = false
    @Published public var selectedPreset: BinauralPreset = .gamma40 {
        didSet {
            if isPlaying {
                stop()
                start()
            }
        }
    }
    @Published public var volume: Float = 0.25 {
        didSet {
            engine?.mainMixerNode.outputVolume = volume
        }
    }
    
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    
    private init() {}
    
    public func start() {
        guard !isPlaying else { return }
        
        do {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            let sampleRate: Double = 44100.0
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }
            engine.connect(player, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = volume
            
            let frameCount = AVAudioFrameCount(sampleRate * 4.0) // 4 second loop
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            buffer.frameLength = frameCount
            
            let leftFreq = selectedPreset.baseCarrierFrequency
            let rightFreq = selectedPreset.baseCarrierFrequency + selectedPreset.beatFrequency
            
            if let channels = buffer.floatChannelData {
                let leftChannel = channels[0]
                let rightChannel = channels[1]
                
                for i in 0..<Int(frameCount) {
                    let t = Double(i) / sampleRate
                    // Smooth pure sine tones
                    leftChannel[i] = Float(sin(2.0 * .pi * leftFreq * t)) * 0.4
                    rightChannel[i] = Float(sin(2.0 * .pi * rightFreq * t)) * 0.4
                }
            }
            
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()
            
            self.engine = engine
            self.player = player
            self.isPlaying = true
        } catch {
            print("BinauralBeatsEngine error:", error.localizedDescription)
        }
    }
    
    public func stop() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        isPlaying = false
    }
}
