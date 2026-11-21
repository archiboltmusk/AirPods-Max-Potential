import Foundation
import Combine

public struct SkeletalJoint3D: Codable, Identifiable {
    public let id: String
    public let x: Double
    public let y: Double
    public let z: Double
    public let confidence: Double
}

public struct TrueDepthPoseFrame: Codable {
    public let headX: Double
    public let headY: Double
    public let headZ: Double
    public let leftShoulderY: Double
    public let rightShoulderY: Double
    public let sternumZ: Double
    public let shoulderImbalanceDegrees: Double
    public let timestamp: Date
}

@MainActor
public final class TrueDepthVisionBridgeManager: ObservableObject {
    public static let shared = TrueDepthVisionBridgeManager()
    
    @Published public var isPeerConnected: Bool = false
    @Published public var connectedDeviceName: String = "No Camera Connected"
    @Published public var shoulderImbalanceAngle: Double = 0.0
    @Published public var sternumProtractionDistance: Double = 0.0 // cm forward
    @Published public var visionTrackingActive: Bool = false
    @Published public var framesReceived: Int = 0
    
    private init() {
        // Ready for iOS Vision Sidecar Camera packets over Bonjour / UDP / WebSockets
    }
    
    public func processIncomingVisionFrame(imbalance: Double, protraction: Double) {
        self.shoulderImbalanceAngle = imbalance
        self.sternumProtractionDistance = protraction
        self.framesReceived += 1
        self.visionTrackingActive = true
    }
    
    public func connectDevice(name: String) {
        self.isPeerConnected = true
        self.connectedDeviceName = name
    }
}
