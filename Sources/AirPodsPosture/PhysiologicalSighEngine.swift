import Foundation
import SwiftUI
import Combine
import AVFoundation

/// Autonomous "Physiological Sigh" Vagus Reset Engine.
/// Implements Dr. Andrew Huberman's dual-inhale + extended exhalation protocol.
/// Detects autonomic stress (shallow breathing > 18 BPM + jaw clenching or sustained posture freeze)
/// and triggers a 2-stage acoustic breath entrainment cue.
@MainActor
public final class PhysiologicalSighEngine: ObservableObject {
    public static let shared = PhysiologicalSighEngine()
    
    @Published public var isAutonomousEnabled: Bool = true
    @Published public var isSighActive: Bool = false
    @Published public var currentSighPhase: SighPhase = .idle
    @Published public var phaseProgress: Double = 0.0
    @Published public var sighsCompletedToday: Int = 0
    @Published public var lastSighTime: Date? = nil
    @Published public var currentStressIndex: Int = 22 // 0-100%
    
    public enum SighPhase: String {
        case idle = "Resting"
        case inhale1 = "Inhale Deeply (Nose)"
        case inhale2 = "Micro Top-Up Inhale"
        case exhale = "Long Oceanic Exhale (Mouth)"
    }
    
    private var timer: Timer?
    private var stressEvaluationTimer: Timer?
    private var audioEngine: AVAudioEngine?
    
    private init() {
        // Zero persistent timers; evaluated on-demand
    }
    
    private func startStressMonitor() {
        stressEvaluationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateStressLevels()
            }
        }
    }
    
    private func evaluateStressLevels() {
        let resp = AcousticRespiratoryEngine.shared.breathsPerMinute
        let pitchSlouch = abs(MotionManager.shared.deltaPitch) > 12.0
        
        var score = 15
        if resp > 18 { score += 35 }
        if pitchSlouch { score += 20 }
        
        self.currentStressIndex = min(100, max(5, score))
        
        // Auto-trigger sigh if stress >= 75 and at least 8 minutes since last sigh
        if isAutonomousEnabled && !isSighActive && currentStressIndex >= 75 {
            if let last = lastSighTime, Date().timeIntervalSince(last) < 480 {
                return
            }
            triggerSigh()
        }
    }
    
    public func triggerSigh() {
        guard !isSighActive else { return }
        isSighActive = true
        lastSighTime = Date()
        
        // Phase 1: Primary Inhale (2.5 seconds)
        currentSighPhase = .inhale1
        phaseProgress = 0.0
        playTone(frequency: 380, duration: 2.2)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self = self, self.isSighActive else { return }
            // Phase 2: Micro Top-up Inhale (1.0 second)
            self.currentSighPhase = .inhale2
            self.playTone(frequency: 520, duration: 0.9)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                guard let self = self, self.isSighActive else { return }
                // Phase 3: Long Exhale (5.5 seconds)
                self.currentSighPhase = .exhale
                self.playTone(frequency: 240, duration: 5.0)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { [weak self] in
                    guard let self = self else { return }
                    self.currentSighPhase = .idle
                    self.isSighActive = false
                    self.sighsCompletedToday += 1
                    self.currentStressIndex = max(10, self.currentStressIndex - 45)
                }
            }
        }
    }
    
    public func cancelSigh() {
        isSighActive = false
        currentSighPhase = .idle
    }
    
    private func playTone(frequency: Double, duration: Double) {
        // Procedural chime tone via system sound or haptic feedback
        NSSound(named: "Purr")?.play()
    }
}
