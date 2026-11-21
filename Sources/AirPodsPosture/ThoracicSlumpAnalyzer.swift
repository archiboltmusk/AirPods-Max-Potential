import Foundation

public enum SpinalSlumpType: String {
    case optimal = "Spine Neutral & Decompressed"
    case chinTiltOnly = "Cervical Flexion (Chin Down Only)"
    case fullTorsoSlump = "Thoracic & Lumbar Slump (Torso Sunk)"
}

@MainActor
public final class ThoracicSlumpAnalyzer: ObservableObject {
    public static let shared = ThoracicSlumpAnalyzer()
    
    @Published public var slumpType: SpinalSlumpType = .optimal
    @Published public var correctiveCues: String = "Spine well aligned."
    
    private init() {}
    
    public func update(deltaPitch: Double, gravityY: Double, gravityZ: Double, userAccelZ: Double) {
        guard abs(deltaPitch) > 10.0 else {
            slumpType = .optimal
            correctiveCues = "Spine neutral and decompressed."
            return
        }
        
        // When user only tilts chin down:
        // pitch is negative, but gravity projects primarily along Y axis with minimal vertical torso sink
        // When full torso slumps forward in chair:
        // gravity projects strongly on both axes and vertical torso compression occurs
        let forwardTiltMagnitude = abs(gravityY)
        let verticalCompression = abs(gravityZ)
        
        if forwardTiltMagnitude > 0.35 && verticalCompression < 0.85 {
            slumpType = .fullTorsoSlump
            correctiveCues = "Torso compression detected: push your sternum upward and roll shoulders back, not just your chin!"
        } else {
            slumpType = .chinTiltOnly
            correctiveCues = "Neck flexion detected: gently raise your gaze and tuck your chin slightly back."
        }
    }
}
