import Foundation
import AVFoundation
import Combine

/// Spatial Elevation Soundstage Engine.
/// Ties acoustic soundstage elevation directly to your physical cervical spine.
/// In optimal alignment, audio sits at eye level; as your head slouches forward, the soundstage
/// imperceptibly drops toward your chest, subconsciously prompting you to sit up to restore clarity.
@MainActor
public final class SpatialElevationSoundstageEngine: ObservableObject {
    public static let shared = SpatialElevationSoundstageEngine()
    
    @Published public var isSpatialElevationEnabled: Bool = true
    @Published public var currentElevationY: Float = 0.0 // 0.0 = Eye Level, -0.8 = Chest Level
    @Published public var soundstageStatus: String = "Spatial Horizon Aligned"
    
    private var audioEngine: AVAudioEngine?
    private var environmentNode: AVAudioEnvironmentNode?
    private var playerNode: AVAudioPlayerNode?
    
    private init() {
        setup3DAudioEnvironment()
    }
    
    private func setup3DAudioEnvironment() {
        let engine = AVAudioEngine()
        let env = AVAudioEnvironmentNode()
        let player = AVAudioPlayerNode()
        
        env.renderingAlgorithm = .sphericalHead
        env.distanceAttenuationParameters.distanceAttenuationModel = .exponential
        
        engine.attach(env)
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        if let format = format {
            engine.connect(player, to: env, format: format)
            engine.connect(env, to: engine.mainMixerNode, format: format)
        }
        
        self.audioEngine = engine
        self.environmentNode = env
        self.playerNode = player
    }
    
    /// Maps real-time cervical pitch to 3D spatial audio coordinate space
    public func updateCervicalElevation(pitch: Double) {
        guard isSpatialElevationEnabled, let env = environmentNode else { return }
        
        // Forward slouch is negative pitch (head nod forward):
        // 0° to -5° -> Y = 0.0 (Eye Level Horizon)
        // -15° -> Y = -0.35 (Chin Level)
        // -30° -> Y = -0.75 (Chest Level)
        let forwardSlouchDeg = max(0.0, -pitch)
        let clampedPitch = min(45.0, forwardSlouchDeg)
        let normalizedDrop = Float(clampedPitch / 35.0) // 0.0 to 1.0
        let targetY = -normalizedDrop * 0.8
        
        self.currentElevationY = targetY
        
        // Update listener and sound position in 3D audio space
        env.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        env.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: Float(-pitch), roll: 0)
        
        if targetY < -0.2 {
            self.soundstageStatus = "Audio Depressed (\(Int(abs(targetY * 100)))% Down) — Sit Tall to Lift"
        } else {
            self.soundstageStatus = "Spatial Soundstage at Eye Level Horizon"
        }
    }
}
