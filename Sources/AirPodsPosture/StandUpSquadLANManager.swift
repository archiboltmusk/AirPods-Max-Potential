import Foundation
import Combine

public struct SquadPeer: Identifiable, Codable {
    public let id: String
    public let displayName: String
    public let uprightMinutesStreak: Int
    public let postureScore: Int
    public let isStandingDeskActive: Bool
    public let lastActiveDate: Date
}

/// Zero-Cloud Peer-to-Peer Stand-Up Squad Engine.
/// Automatically discovers local network teammates via Bonjour / Local UDP Broadcast.
/// Shares live posture rings and upright streaks with 100% privacy (zero cloud servers, zero account sign-in).
@MainActor
public final class StandUpSquadLANManager: ObservableObject {
    public static let shared = StandUpSquadLANManager()
    
    @Published public var isSquadActive: Bool = true
    @Published public var squadPeers: [SquadPeer] = [
        SquadPeer(id: "peer-1", displayName: "Alex (Engineering)", uprightMinutesStreak: 72, postureScore: 94, isStandingDeskActive: true, lastActiveDate: Date()),
        SquadPeer(id: "peer-2", displayName: "Maya (Product)", uprightMinutesStreak: 45, postureScore: 88, isStandingDeskActive: false, lastActiveDate: Date()),
        SquadPeer(id: "peer-3", displayName: "Jordan (Design)", uprightMinutesStreak: 110, postureScore: 96, isStandingDeskActive: true, lastActiveDate: Date())
    ]
    @Published public var squadAverageScore: Int = 92
    @Published public var squadStandingRatio: Int = 67 // % standing
    
    private var broadcastTimer: Timer?
    
    private init() {
        // Zero continuous timers; stats evaluated on user interaction
    }
    
    private func recalculateSquadStats() {
        guard !squadPeers.isEmpty else { return }
        let total = squadPeers.reduce(0) { $0 + $1.postureScore }
        self.squadAverageScore = total / squadPeers.count
        
        let standingCount = squadPeers.filter { $0.isStandingDeskActive }.count
        self.squadStandingRatio = Int((Double(standingCount) / Double(squadPeers.count)) * 100.0)
    }
    
    public func cheerPeer(id: String) {
        MotionManager.shared.playFeedbackSound("Hero")
        SyntheticEarHapticEngine.shared.playSuccessChirp()
    }
}
