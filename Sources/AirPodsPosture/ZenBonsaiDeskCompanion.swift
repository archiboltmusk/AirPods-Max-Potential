import Foundation
import SwiftUI

@MainActor
public final class ZenBonsaiDeskCompanion: ObservableObject {
    public static let shared = ZenBonsaiDeskCompanion()
    
    @Published public var healthPercentage: Int = 100 // 0 to 100
    @Published public var growthLevel: Int = 1
    @Published public var streakDays: Int = 1
    @Published public var statusMessage: String = "Blooming & Healthy"
    @Published public var treeIconName: String = "leaf.circle.fill"
    
    private var timer: Timer? = nil
    
    private init() {
        // Evaluated on posture events rather than running continuous timers
    }
    
    private func evaluateBonsai() {
        let state = MotionManager.shared.postureState
        let isTracking = MotionManager.shared.isTracking && MotionManager.shared.isConnected
        guard isTracking else { return }
        
        switch state {
        case .optimal:
            healthPercentage = min(100, healthPercentage + 1)
            if healthPercentage == 100 && growthLevel < 10 {
                growthLevel += 1
            }
            statusMessage = "Blooming & Thriving"
            treeIconName = "tree.fill"
        case .warning:
            statusMessage = "Leaves rustling slightly..."
        case .slouching:
            healthPercentage = max(10, healthPercentage - 2)
            statusMessage = "Branches drooping — sit upright to water"
            treeIconName = "tree"
        case .snoozed, .disconnected:
            break
        }
    }
}
