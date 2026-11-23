import Foundation
import AVFoundation
import AppKit

/// Directional Synthetic Ear-Haptic & MacBook Trackpad Haptic Engine.
/// Transduces precise low-frequency acoustic impulse waves into physical ear cartilage micro-taps,
/// paired with MacBook Force Touch trackpad tactile haptics.
/// Automatically silences audio cues during meetings (Zoom, Teams, Meet) and defaults to silent trackpad pulses.
@MainActor
public final class SyntheticEarHapticEngine: ObservableObject {
    public static let shared = SyntheticEarHapticEngine()
    
    @Published public var isHapticAudioEnabled: Bool = true
    @Published public var isTrackpadHapticEnabled: Bool = true
    @Published public var hapticVolume: Float = 0.40
    @Published public var isDirectionalModeEnabled: Bool = true
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var lastTapTime: Date = Date.distantPast
    
    private init() {
        // Audio engine initialized strictly on demand to prevent continuous coreaudiod power assertions
    }
    
    private func ensureAudioEngine() {
        guard audioEngine == nil else { return }
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        guard NSApp != nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              NSClassFromString("XCTest") == nil else { return }
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
        guard let format = format else { return }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Keep engine stopped when idle so coreaudiod does NOT hold a continuous audio power assertion!
        self.audioEngine = engine
        self.playerNode = player
        self.audioFormat = format
    }
    
    /// Triggers silent MacBook Force Touch trackpad haptics
    public func performTrackpadHaptic(pattern: NSHapticFeedbackManager.FeedbackPattern = .alignment) {
        guard isTrackpadHapticEnabled && NSApp != nil else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }
    
    /// Directional Posture Biofeedback: Plays targeted micro-tap into left ear, right ear, or dual ear.
    public func playDirectionalPostureCue(pitch: Double, roll: Double, pitchThreshold: Double = 12.0, rollThreshold: Double = 10.0) {
        let now = Date()
        guard now.timeIntervalSince(lastTapTime) > 0.85 else { return } // Hysteresis limiter
        
        // Meeting Guard: If in a call, suppress audio and deliver silent trackpad haptic
        if CallActivitySentinel.shared.shouldSuppressAudioCue() {
            performTrackpadHaptic(pattern: .alignment)
            lastTapTime = now
            return
        }
        
        // Optional subtle trackpad assist
        if isTrackpadHapticEnabled && (pitch > pitchThreshold || abs(roll) > rollThreshold) {
            performTrackpadHaptic(pattern: .generic)
        }
        
        if roll > rollThreshold {
            // Tilting head to the right -> cue right ear to level left
            playSpatialEarTap(leftGain: 0.05, rightGain: 1.0, baseFreq: 155.0, durationSeconds: 0.02)
            lastTapTime = now
        } else if roll < -rollThreshold {
            // Tilting head to the left -> cue left ear to level right
            playSpatialEarTap(leftGain: 1.0, rightGain: 0.05, baseFreq: 155.0, durationSeconds: 0.02)
            lastTapTime = now
        } else if abs(pitch) > pitchThreshold {
            // Forward slouch -> dual-ear deep 52Hz cartilage resonance pulse
            playSpatialEarTap(leftGain: 0.9, rightGain: 0.9, baseFreq: 52.0, durationSeconds: 0.035)
            lastTapTime = now
        }
    }
    
    /// Generates a calibrated directional synthetic ear-tap buffer
    public func playSpatialEarTap(leftGain: Float, rightGain: Float, baseFreq: Double = 160.0, durationSeconds: Double = 0.018) {
        guard isHapticAudioEnabled else { return }
        ensureAudioEngine()
        guard let format = audioFormat, let engine = audioEngine, let player = playerNode else { return }
        
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return }
        
        let vol = Double(hapticVolume)
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = exp(-t * 260.0) * vol
            let sample = Float(sin(2.0 * .pi * baseFreq * t) * envelope)
            
            leftChannel[frame] = sample * leftGain
            rightChannel[frame] = sample * rightGain
        }
        
        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    if let p = self?.playerNode, !p.isPlaying {
                        self?.audioEngine?.pause()
                    }
                }
            }
            if !player.isPlaying {
                player.play()
            }
        } catch {
            // Audio start fallback
        }
    }
    
    /// Generates a single crisp 12ms synthetic Taptic tick (Apple Watch digital crown feel)
    public func playTapticClick() {
        performTrackpadHaptic(pattern: .levelChange)
        playSpatialEarTap(leftGain: 0.9, rightGain: 0.9, baseFreq: 160.0, durationSeconds: 0.015)
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
        performTrackpadHaptic(pattern: .alignment)
        guard isHapticAudioEnabled else { return }
        ensureAudioEngine()
        guard let format = audioFormat, let engine = audioEngine, let player = playerNode else { return }
        
        let sampleRate = format.sampleRate
        let durationSeconds = 0.04
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return }
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / durationSeconds
            let freq = 520.0 + (progress * 440.0)
            let envelope = sin(.pi * progress) * Double(hapticVolume * 0.7)
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope)
            
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    if let p = self?.playerNode, !p.isPlaying {
                        self?.audioEngine?.pause()
                    }
                }
            }
            if !player.isPlaying {
                player.play()
            }
        } catch {
            // Audio start fallback
        }
    }
}
