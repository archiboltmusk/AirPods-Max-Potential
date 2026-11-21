import Foundation
import AVFoundation

@MainActor
public final class Spatial3DAnchorManager: ObservableObject {
    public static let shared = Spatial3DAnchorManager()
    
    @Published public var isAnchorActive: Bool = false
    @Published public var spatialDriftRatio: Double = 0.0 // 0.0 = centered, 1.0 = far off
    @Published public var anchorStatus: String = "Anchor Inactive"
    @Published public var volume: Float = 0.15
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var environmentNode: AVAudioEnvironmentNode?
    
    private init() {}
    
    public func toggleAnchor() {
        if isAnchorActive {
            stopAnchor()
        } else {
            startAnchor()
        }
    }
    
    public func startAnchor() {
        guard !isAnchorActive else { return }
        
        do {
            let engine = AVAudioEngine()
            let env = AVAudioEnvironmentNode()
            let player = AVAudioPlayerNode()
            
            engine.attach(env)
            engine.attach(player)
            
            // Output format (Stereo)
            let outputFormat = engine.outputNode.outputFormat(forBus: 0)
            
            // Connect player to 3D environment node
            let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            engine.connect(player, to: env, format: monoFormat)
            engine.connect(env, to: engine.mainMixerNode, format: outputFormat)
            
            // Anchor audio source strictly in front at (0, 0, -2.0 meters)
            player.renderingAlgorithm = .sphericalHead
            player.position = AVAudio3DPoint(x: 0, y: 0, z: -2.0)
            
            // Generate soothing subtle pink noise stream for 3D orientation reference
            let buffer = generatePinkNoiseBuffer(format: monoFormat, duration: 4.0)
            
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.volume = volume
            player.play()
            
            self.audioEngine = engine
            self.playerNode = player
            self.environmentNode = env
            self.isAnchorActive = true
            self.anchorStatus = "3D Acoustic Anchor Centered (0, 0, -2m)"
        } catch {
            anchorStatus = "Audio Engine Failed: \(error.localizedDescription)"
        }
    }
    
    public func stopAnchor() {
        playerNode?.stop()
        audioEngine?.stop()
        playerNode = nil
        environmentNode = nil
        audioEngine = nil
        isAnchorActive = false
        anchorStatus = "Anchor Inactive"
        spatialDriftRatio = 0.0
    }
    
    public func updateListenerOrientation(pitch: Double, roll: Double, yaw: Double) {
        guard isAnchorActive, let env = environmentNode else { return }
        
        // Convert head pitch, roll, yaw (degrees) into listener orientation angles
        let p = Float(pitch * .pi / 180.0)
        let y = Float(yaw * .pi / 180.0)
        let r = Float(roll * .pi / 180.0)
        
        env.listenerAngularOrientation = AVAudioMake3DAngularOrientation(y, p, r)
        
        // Calculate spatial drift from origin
        let drift = sqrt(pow(pitch, 2) + pow(yaw, 2) + pow(roll, 2))
        spatialDriftRatio = min(1.0, drift / 30.0)
        
        if drift < 6.0 {
            anchorStatus = "🎯 Perfectly Centered on Anchor"
        } else {
            let direction = yaw < 0 ? "Turn Right" : "Turn Left"
            anchorStatus = "⚠️ Drifting off-axis: \(direction) to re-center"
        }
    }
    
    private func generatePinkNoiseBuffer(format: AVAudioFormat, duration: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let channels = buffer.floatChannelData!
        let data = channels[0]
        
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
        
        for i in 0..<Int(frameCount) {
            let white = Float.random(in: -1.0...1.0)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926
            data[i] = (pink * 0.06)
        }
        return buffer
    }
}
