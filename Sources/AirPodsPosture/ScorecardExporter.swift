import Foundation
import AppKit

@MainActor
public final class ScorecardExporter: ObservableObject {
    public static let shared = ScorecardExporter()
    
    private init() {}
    
    public func generateScorecardText() -> String {
        let motion = MotionManager.shared
        let standing = StandingDeskTracker.shared
        let focus = FocusRestlessnessTracker.shared
        let hearing = HearingSafetyMonitor.shared
        let bonsai = ZenBonsaiDeskCompanion.shared
        
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        return """
        ====================================================
               AIRPODSIQ ERGONOMIC HEALTH SCORECARD
        ====================================================
        Generated on: \(dateStr)
        Device: AirPods Pro 2 / AirPods Max
        
        [ 1. POSTURE & ERGONOMIC HEALTH ]
        - Overall Posture Score: \(motion.postureScore)%
        - Total Tracked Time: \(formatTime(motion.secondsTracked))
        - Time in Optimal Posture: \(formatTime(motion.secondsGoodPosture))
        - Slouch Time: \(formatTime(motion.secondsSlouching))
        - Slouch Incidents: \(motion.slouchEventCount)
        
        [ 2. SIT / STAND DESK BALANCE ]
        - Time Sitting Today: \(formatTime(standing.secondsSittingToday))
        - Time Standing Today: \(formatTime(standing.secondsStandingToday))
        - Current State: \(standing.isStanding ? "Standing" : "Sitting")
        
        [ 3. COGNITIVE FLOW & RESTLESSNESS ]
        - Focus Flow Score: \(focus.focusScore)% (\(focus.focusStateDescription))
        - Restlessness Index: \(focus.restlessnessIndex)%
        - Continuous Focus Streak: \(focus.focusStreakMinutes) minutes
        
        [ 4. HEARING & ACOUSTIC SAFETY ]
        - Output Decibels: \(hearing.estimatedDecibels) dBA (\(hearing.currentVolumePercent)% volume)
        - Daily WHO Noise Dose: \(String(format: "%.1f%%", hearing.dailyDosePercentage))
        
        [ 5. ZEN ERGONOMIC COMPANION ]
        - Bonsai Health: \(bonsai.healthPercentage)%
        - Growth Level: Level \(bonsai.growthLevel) (\(bonsai.statusMessage))
        ====================================================
        """
    }
    
    public func copyToClipboard() {
        let text = generateScorecardText()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        MotionManager.shared.playFeedbackSound("Hero")
    }
    
    public func saveToFile() {
        let text = generateScorecardText()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AirPodsIQ-Health-Scorecard.txt"
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
            MotionManager.shared.playFeedbackSound("Hero")
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let hrs = mins / 60
        if hrs > 0 {
            return String(format: "%dh %02dm", hrs, mins % 60)
        }
        return String(format: "%dm", mins)
    }
}
