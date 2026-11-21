import Foundation
import AVFoundation

public enum BinauralWaveFrequency: String, CaseIterable, Identifiable {
    case gamma40 = "40 Hz Gamma (Deep Coding & Problem Solving)"
    case beta14 = "14 Hz Beta (Active Focus & Productivity)"
    case alpha10 = "10 Hz Alpha (Relaxed Flow & Stress Reduction)"
    case theta6 = "6 Hz Theta (Creativity & Intuition)"
    
    public var id: String { rawValue }
    
    public var baseFrequencyHz: Double {
        switch self {
        case .gamma40: return 216.0
        case .beta14: return 200.0
        case .alpha10: return 190.0
        case .theta6: return 180.0
        }
    }
    
    public var beatDifferenceHz: Double {
        switch self {
        case .gamma40: return 40.0
        case .beta14: return 14.0
        case .alpha10: return 10.0
        case .theta6: return 6.0
        }
    }
}

@MainActor
public final class ProceduralBinauralSoundscapeEngine: ObservableObject {
    public static let shared = ProceduralBinauralSoundscapeEngine()
    
    @Published public var isPlaying: Bool = false
    @Published public var selectedWave: BinauralWaveFrequency = .gamma40
    @Published public var masterVolume: Float = 0.22
    @Published public var statusMessage: String = "Procedural Audio Synthesizer Ready"
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private init() {}
    
    public func togglePlay() {
        if isPlaying {
            stopAudio()
        } else {
            startAudio()
        }
    }
    
    public func startAudio() {
        guard !isPlaying else { return }
        
        do {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
            engine.connect(player, to: engine.mainMixerNode, format: stereoFormat)
            
            let buffer = generateBinauralBuffer(format: stereoFormat, duration: 4.0)
            try engine.start()
            
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.volume = masterVolume
            player.play()
            
            self.audioEngine = engine
            self.playerNode = player
            self.isPlaying = true
            self.statusMessage = "Playing \(selectedWave.rawValue)"
        } catch {
            statusMessage = "Audio Engine Failed: \(error.localizedDescription)"
        }
    }
    
    public func stopAudio() {
        playerNode?.stop()
        audioEngine?.stop()
        playerNode = nil
        audioEngine = nil
        isPlaying = false
        statusMessage = "Synthesizer Idle"
    }
    
    public func updatePostureModulation(postureScore: Int) {
        guard isPlaying, let player = playerNode else { return }
        
        // Dynamic Ergonomic Modulation:
        // As posture drops below 75%, subtly attenuate volume and collapse binaural separation
        if postureScore < 70 {
            player.volume = masterVolume * 0.45
        } else {
            player.volume = masterVolume
        }
    }
    
    private func generateBinauralBuffer(format: AVAudioFormat, duration: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftFreq = selectedWave.baseFrequencyHz
        let rightFreq = selectedWave.baseFrequencyHz + selectedWave.beatDifferenceHz
        
        let channels = buffer.floatChannelData!
        let leftData = channels[0]
        let rightData = channels[1]
        
        let sampleRate = Float(format.sampleRate)
        let twoPi = 2.0 * Float.pi
        
        for i in 0..<Int(frameCount) {
            let t = Float(i) / sampleRate
            let leftSine = sin(twoPi * Float(leftFreq) * t) * 0.35
            let rightSine = sin(twoPi * Float(rightFreq) * t) * 0.35
            
            // Add subtle pink noise floor for acoustic fullness
            let noise = Float.random(in: -0.015...0.015)
            leftData[i] = leftSine + noise
            rightData[i] = rightSine + noise
        }
        return buffer
    }
}
