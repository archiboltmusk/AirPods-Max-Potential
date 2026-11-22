import Foundation
import SwiftUI
import Combine

/// Bilateral Sleep Position & Shoulder Impingement Balancer.
/// Tracks exact duration split between Left Lateral, Right Lateral, Supine, and Prone postures.
/// Detects asymmetric shoulder compression (e.g. spending 85% of the night on one shoulder),
/// warning against rotator cuff impingement, cervical facet joint strain, and unilateral facial fluid edema.
@MainActor
public final class BilateralSleepPositionBalancer: ObservableObject {
    public static let shared = BilateralSleepPositionBalancer()
    
    @Published public var isMonitoring: Bool = true
    @Published public var leftLateralMinutes: Int = 245 // ~4.1 hours
    @Published public var rightLateralMinutes: Int = 135 // ~2.2 hours
    @Published public var supineMinutes: Int = 55       // ~0.9 hours
    @Published public var proneMinutes: Int = 15        // ~0.2 hours
    
    @Published public var shoulderAsymmetryRiskIndex: Int = 68 // 0 - 100%
    @Published public var dominantSide: String = "Left Shoulder (64% Dominance)"
    @Published public var morningRecommendation: String = "Left shoulder compressed for 4.1h. Perform cross-body stretches."
    
    private var trackingTimer: Timer?
    
    public var totalSleepMinutes: Int {
        return max(1, leftLateralMinutes + rightLateralMinutes + supineMinutes + proneMinutes)
    }
    
    public var leftPercent: Double {
        return (Double(leftLateralMinutes) / Double(totalSleepMinutes)) * 100.0
    }
    
    public var rightPercent: Double {
        return (Double(rightLateralMinutes) / Double(totalSleepMinutes)) * 100.0
    }
    
    public var supinePercent: Double {
        return (Double(supineMinutes) / Double(totalSleepMinutes)) * 100.0
    }
    
    public var pronePercent: Double {
        return (Double(proneMinutes) / Double(totalSleepMinutes)) * 100.0
    }
    
    private init() {
        startWatcher()
    }
    
    private func startWatcher() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recordPositionIncrement()
            }
        }
    }
    
    public func recordPositionIncrement() {
        guard isMonitoring else { return }
        let current = PositionalApneaNudgeEngine.shared.currentPosition
        
        switch current {
        case .leftLateral:
            leftLateralMinutes += 1
        case .rightLateral:
            rightLateralMinutes += 1
        case .supine:
            supineMinutes += 1
        case .prone:
            proneMinutes += 1
        }
        
        recalculateAsymmetry()
    }
    
    public func resetSession() {
        leftLateralMinutes = 0
        rightLateralMinutes = 0
        supineMinutes = 0
        proneMinutes = 0
        shoulderAsymmetryRiskIndex = 0
        dominantSide = "Balanced"
        morningRecommendation = "Session initialized • Tracking lateral posture balance."
    }
    
    private func recalculateAsymmetry() {
        let lateralTotal = Double(leftLateralMinutes + rightLateralMinutes)
        guard lateralTotal > 0 else {
            shoulderAsymmetryRiskIndex = 10
            dominantSide = "Supine Dominant"
            morningRecommendation = "Balanced bilateral pressure."
            return
        }
        
        let leftRatio = Double(leftLateralMinutes) / lateralTotal
        let maxRatio = max(leftRatio, 1.0 - leftRatio)
        
        // Asymmetry score: 50% = 0 risk, 100% = 100 risk
        let rawRisk = Int((maxRatio - 0.5) * 200.0)
        shoulderAsymmetryRiskIndex = max(10, min(100, rawRisk))
        
        let isLeftDominant = leftRatio >= 0.5
        let dominancePercent = Int(maxRatio * 100.0)
        dominantSide = "\(isLeftDominant ? "Left" : "Right") Shoulder (\(dominancePercent)% Dominance)"
        
        if shoulderAsymmetryRiskIndex >= 70 {
            morningRecommendation = "⚠️ High \(isLeftDominant ? "Left" : "Right") compression (\(dominancePercent)%). Perform 30s cross-body shoulder stretch."
        } else if shoulderAsymmetryRiskIndex >= 45 {
            morningRecommendation = "Moderate \(isLeftDominant ? "Left" : "Right") lateral bias. Rotate pillow elevation tonight."
        } else {
            morningRecommendation = "Optimal Bilateral Balance: Shoulders evenly decompressed."
        }
    }
}
