import Foundation
import AVFoundation

@MainActor
public final class HeadphoneAudioKeeper: ObservableObject {
    public static let shared = HeadphoneAudioKeeper()
    
    @Published public var isRunning: Bool = false
    
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        
        do {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            // Connect to main mixer with low volume
            let mixer = engine.mainMixerNode
            mixer.outputVolume = 0.0001 // imperceptible
            
            let format = engine.outputNode.outputFormat(forBus: 0)
            engine.connect(player, to: mixer, format: format)
            
            try engine.start()
            player.play()
            
            self.engine = engine
            self.player = player
            self.isRunning = true
        } catch {
            print("HeadphoneAudioKeeper start notice:", error.localizedDescription)
        }
    }
    
    public func stop() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        isRunning = false
    }
}
