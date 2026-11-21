import Foundation
import CoreGraphics
import AppKit

@MainActor
public final class DisplayDistanceGuardManager: ObservableObject {
    public static let shared = DisplayDistanceGuardManager()
    
    @Published public var isGuardEnabled: Bool = true
    @Published public var estimatedEyeDistanceCm: Double = 62.0 // Normal healthy viewing distance: 50 - 75 cm
    @Published public var isViewingTooClose: Bool = false
    @Published public var tooCloseSecondsCount: Int = 0
    @Published public var statusMessage: String = "Eye Distance Optimal (~62cm)"
    
    private var baselineZAcceleration: Double = 0.0
    private var forwardStrainStartTime: Date?
    
    private init() {}
    
    public func update(pitch: Double, userAccelZ: Double) {
        guard isGuardEnabled else { return }
        
        let now = Date()
        
        // Forward crane/lean towards display:
        // When pitch dips forward (pitch < -14°) and stays forward, 
        // distance to display shrinks from ~65cm to <38cm (CVS risk zone).
        let forwardDeflection = max(0, -pitch)
        let distanceEstimate = max(24.0, min(85.0, 68.0 - (forwardDeflection * 1.8)))
        estimatedEyeDistanceCm = (estimatedEyeDistanceCm * 0.9) + (distanceEstimate * 0.1)
        
        if estimatedEyeDistanceCm < 42.0 {
            if forwardStrainStartTime == nil {
                forwardStrainStartTime = now
            }
            
            let elapsed = now.timeIntervalSince(forwardStrainStartTime!)
            if elapsed > 6.0 {
                isViewingTooClose = true
                tooCloseSecondsCount += 1
                statusMessage = "⚠️ Too Close to Screen (~\(Int(estimatedEyeDistanceCm))cm): Lean back to protect eyesight!"
                
                // Trigger screen zoom out cue / gentle alert
                if tooCloseSecondsCount % 12 == 1 {
                    MotionManager.shared.playFeedbackSound("Ping")
                }
            }
        } else {
            forwardStrainStartTime = nil
            isViewingTooClose = false
            statusMessage = "Viewing Distance Optimal (~\(Int(estimatedEyeDistanceCm))cm)"
        }
    }
}
