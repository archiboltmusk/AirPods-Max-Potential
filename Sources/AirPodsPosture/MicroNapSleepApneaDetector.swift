import Foundation

public struct FatigueAlertEvent: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let eventType: String
    public let severity: String
}

@MainActor
public final class MicroNapSleepApneaDetector: ObservableObject {
    public static let shared = MicroNapSleepApneaDetector()
    
    @Published public var isMonitoring: Bool = true
    @Published public var microSleepEpisodesDetected: Int = 0
    @Published public var currentArousalLevel: String = "Alert & Focused"
    @Published public var recentEvents: [FatigueAlertEvent] = []
    
    private var headDropStartTime: Date?
    
    private init() {}
    
    public func update(pitch: Double, userAccelZ: Double, totalEnergy: Double) {
        guard isMonitoring else { return }
        
        let now = Date()
        
        // Micro-Nap Signature (Sudden Loss of Muscle Tone in Cervical Extensors):
        // Pitch drops rapidly past -22 degrees with near-zero kinetic response, 
        // followed by an abrupt startle jerk back upright (acceleration spike > 0.45g).
        let isHeadDropped = pitch < -20.0
        
        if isHeadDropped {
            if headDropStartTime == nil {
                headDropStartTime = now
            }
            
            let dropDuration = now.timeIntervalSince(headDropStartTime!)
            if dropDuration > 3.5 {
                currentArousalLevel = "⚠️ Micro-Sleep In Progress (Loss of Cervical Tone)"
                
                // If abrupt jerk occurs during recovery
                if userAccelZ > 0.40 {
                    microSleepEpisodesDetected += 1
                    headDropStartTime = nil
                    currentArousalLevel = "Drowsy Jerk Detected: Stand up & Hydrate!"
                    recentEvents.append(FatigueAlertEvent(timestamp: now, eventType: "Cervical Head Drop Jerk", severity: "High"))
                    MotionManager.shared.playFeedbackSound("Hero")
                    NotificationManager.shared.sendCustomAlert(
                        title: "Micro-Sleep Alert",
                        body: "Sudden cervical head drop detected. Step away from your desk for a quick walk and drink water!"
                    )
                }
            }
        } else {
            headDropStartTime = nil
            if microSleepEpisodesDetected == 0 {
                currentArousalLevel = "Alert & Focused"
            }
        }
    }
}
