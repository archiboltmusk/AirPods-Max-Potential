import Foundation
import AppKit

@MainActor
public final class FaceTimeHeadReactionsManager: ObservableObject {
    public static let shared = FaceTimeHeadReactionsManager()
    
    @Published public var isReactionsEnabled: Bool = true
    @Published public var lastReactionTriggered: String = "None"
    
    private var lastReactionDate: Date = Date()
    
    private init() {}
    
    public func checkReactionGestures(pitch: Double, roll: Double, yaw: Double) {
        guard isReactionsEnabled else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastReactionDate) > 2.5 else { return }
        
        // Double Nod (pitch oscillation) -> Thumbs Up
        if abs(pitch) > 18.0 && abs(roll) < 8.0 && abs(yaw) < 8.0 {
            lastReactionDate = now
            lastReactionTriggered = "👍 Thumbs Up Reaction Sent"
            MotionManager.shared.playFeedbackSound("Pop")
        }
        // Lateral Head Tilt (>32° roll) -> Quick Mute Toggle
        else if abs(roll) > 32.0 {
            lastReactionDate = now
            lastReactionTriggered = "🎙️ Head-Tilt Microphone Toggle"
            AudioEnvironmentMonitor.shared.toggleMute()
            MotionManager.shared.playFeedbackSound("Pop")
        }
    }
}
