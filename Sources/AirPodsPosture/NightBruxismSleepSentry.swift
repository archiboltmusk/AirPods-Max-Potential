import Foundation
import SwiftUI
import Combine

/// Nocturnal Bruxism & Sleep Jaw Clenching Sentry.
/// Evaluates night-time masseter micro-vibrations and clenching duration
/// for users wearing AirPods during sleep or evening rest.
@MainActor
public final class NightBruxismSleepSentry: ObservableObject {
    public static let shared = NightBruxismSleepSentry()
    
    @Published public var isSleepModeActive: Bool = false
    @Published public var nocturnalClenchBoutsCount: Int = 0
    @Published public var totalClenchDurationSeconds: Double = 0.0
    @Published public var morningTmjRiskScore: Int = 12 // 0-100%
    @Published public var sleepSessionHours: Double = 0.0
    @Published public var sentryReportSummary: String = "Normal Resting Tone"
    
    private var sleepSessionStart: Date?
    private var clenchActiveStart: Date?
    private var watcherTimer: Timer?
    
    private init() {
        startWatcher()
    }
    
    private func startWatcher() {
        watcherTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateNocturnalState()
            }
        }
    }
    
    public func toggleSleepSentry() {
        isSleepModeActive.toggle()
        if isSleepModeActive {
            sleepSessionStart = Date()
            nocturnalClenchBoutsCount = 0
            totalClenchDurationSeconds = 0.0
            morningTmjRiskScore = 10
            sentryReportSummary = "Active Sleep Monitoring Engaged"
        } else {
            finalizeReport()
        }
    }
    
    private func evaluateNocturnalState() {
        guard isSleepModeActive else { return }
        
        if let start = sleepSessionStart {
            sleepSessionHours = Date().timeIntervalSince(start) / 3600.0
        }
        
        let clenching = JawClenchingBruxismDetector.shared.jawClenchingActive
        if clenching {
            if clenchActiveStart == nil {
                clenchActiveStart = Date()
                nocturnalClenchBoutsCount += 1
            } else {
                totalClenchDurationSeconds += 2.0
            }
        } else {
            clenchActiveStart = nil
        }
        
        // Compute TMJ Morning Risk
        let riskFromBouts = min(50, nocturnalClenchBoutsCount * 6)
        let riskFromDuration = min(50, Int(totalClenchDurationSeconds / 15.0) * 8)
        morningTmjRiskScore = min(100, max(5, riskFromBouts + riskFromDuration))
        
        if morningTmjRiskScore >= 60 {
            sentryReportSummary = "Elevated Clenching Detected • Morning TMJ Soreness Likely"
        } else if morningTmjRiskScore >= 35 {
            sentryReportSummary = "Moderate Night Bruxism • Apply Warm Jaw Compress"
        } else {
            sentryReportSummary = "Low Jaw Tension • Optimal Parasympathetic Sleep"
        }
    }
    
    private func finalizeReport() {
        if nocturnalClenchBoutsCount > 0 {
            sentryReportSummary = "Session ended: \(nocturnalClenchBoutsCount) clench events recorded across \(String(format: "%.1f", sleepSessionHours))h."
        } else {
            sentryReportSummary = "Session complete: zero abnormal clenching observed."
        }
    }
}
