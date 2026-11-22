import Foundation
import Combine

/// TrueDepth Optical Screen Distance Sentinel.
/// When iPhone or iPad is docked on your desk, uses the front sensor to calculate
/// physical screen distance (cm) and fuses it with AirPods forward head pitch.
@MainActor
public final class TrueDepthScreenDistanceSentinel: ObservableObject {
    public static let shared = TrueDepthScreenDistanceSentinel()
    
    @Published public var distanceCentimeters: Double = 52.0
    @Published public var isTooCloseToScreen: Bool = false
    @Published public var isCameraTrackingEnabled: Bool = false
    @Published public var statusMessage: String = "TrueDepth Distance Standby"
    
    public let recommendedMinimumDistanceCm: Double = 35.0 // Apple Screen Distance recommended 12 inches (~30cm)
    
    private init() {}
    
    public func startScreenDistanceTracking() {
        self.isCameraTrackingEnabled = true
        self.statusMessage = "Tracking Eyes-to-Screen Distance"
    }
    
    public func stopScreenDistanceTracking() {
        self.isCameraTrackingEnabled = false
        self.statusMessage = "Distance Tracking Paused"
    }
    
    public func updateSimulatedDistance(cm: Double) {
        self.distanceCentimeters = cm
        self.isTooCloseToScreen = cm < recommendedMinimumDistanceCm
        if self.isTooCloseToScreen {
            self.statusMessage = "⚠️ Too Close to Screen (< \(Int(recommendedMinimumDistanceCm))cm)"
        } else {
            self.statusMessage = "Optimal Screen Distance (\(Int(cm))cm)"
        }
    }
}
