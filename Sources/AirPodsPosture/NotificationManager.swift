import Foundation
import UserNotifications
import AppKit

@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var isAuthorized: Bool = false
    @Published public var notificationsEnabled: Bool = true
    
    private var lastNotificationTime: Date? = nil
    
    private init() {
        requestAuthorization()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.isAuthorized = granted
            }
        }
    }
    
    public func sendSlouchNotification(pitch: Double, roll: Double) {
        guard notificationsEnabled else { return }
        
        let now = Date()
        if let last = lastNotificationTime, now.timeIntervalSince(last) < 20.0 {
            return // rate limit
        }
        lastNotificationTime = now
        
        let content = UNMutableNotificationContent()
        content.title = "Posture Alert"
        let pitchStr = pitch < 0 ? "\(Int(abs(pitch)))° downward" : "\(Int(pitch))° upward"
        content.body = "Slouch detected (\(pitchStr)). Sit upright to reset."
        content.sound = nil // Sound handled separately by MotionManager
        
        let request = UNNotificationRequest(
            identifier: "posture-alert-\(now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    public func sendBreakNotification() {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "20-20-20 Ergonomic Rest Due"
        content.body = "Look 20 feet away for 20 seconds and roll your shoulders."
        
        let request = UNNotificationRequest(
            identifier: "break-timer-alert",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    public func sendCustomAlert(title: String, body: String) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: "custom-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
