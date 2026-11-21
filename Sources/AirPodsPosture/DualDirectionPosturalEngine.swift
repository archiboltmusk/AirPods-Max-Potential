import Foundation
import Combine
import SwiftUI

/// Biomechanical Dual-Direction Postural Engine.
/// Inspired by SlouchGuard: explicitly differentiates Forward Slouching (text neck / head drop)
/// from Backward Lounging (chair slump / lumbar collapse / thoracic hyperextension).
@MainActor
public final class DualDirectionPosturalEngine: ObservableObject {
    public static let shared = DualDirectionPosturalEngine()

    public enum PostureDirection: String {
        case optimal = "Optimal Upright"
        case forwardSlouch = "Forward Slouch (Text Neck)"
        case backwardLounge = "Backward Lounge (Chair Slump)"
    }

    // Thresholds
    @Published public var forwardSlouchThreshold: Double = 12.0 // degrees downward (pitch < -12)
    @Published public var backwardLoungeThreshold: Double = 18.0 // degrees upward (pitch > +18)
    @Published public var directionGraceSeconds: Double = 3.0

    // Live State
    @Published public var currentDirection: PostureDirection = .optimal
    @Published public var forwardSlouchHoldSeconds: Double = 0.0
    @Published public var backwardLoungeHoldSeconds: Double = 0.0

    // Counters & Accumulated Durations
    @Published public var forwardSlouchCount: Int = 0
    @Published public var backwardLoungeCount: Int = 0
    @Published public var totalSlouchSeconds: Double = 0.0
    @Published public var totalLoungeSeconds: Double = 0.0
    @Published public var correctionsCount: Int = 0

    // Derived split
    public var totalPoorSeconds: Double { totalSlouchSeconds + totalLoungeSeconds }
    public var slouchVsLoungeSplit: (slouchPercent: Double, loungePercent: Double) {
        let total = totalPoorSeconds
        guard total > 0 else { return (50.0, 50.0) }
        let slouch = (totalSlouchSeconds / total) * 100.0
        return (slouch, 100.0 - slouch)
    }

    private var forwardDriftStart: Date? = nil
    private var backwardDriftStart: Date? = nil
    private var lastDirection: PostureDirection = .optimal

    private init() {}

    public func update(pitch: Double, dt: Double = 1.0 / 60.0) {
        let now = Date()

        if pitch <= -forwardSlouchThreshold {
            // Forward slouch drift
            backwardDriftStart = nil
            backwardLoungeHoldSeconds = 0.0

            if forwardDriftStart == nil {
                forwardDriftStart = now
            }
            let elapsed = now.timeIntervalSince(forwardDriftStart!)
            forwardSlouchHoldSeconds = elapsed

            if elapsed >= directionGraceSeconds {
                if currentDirection != .forwardSlouch {
                    forwardSlouchCount += 1
                    currentDirection = .forwardSlouch
                }
                totalSlouchSeconds += dt
                HourlyFatigueProfiler.shared.recordPoorSecond(at: now, dt: dt)
            }
        } else if pitch >= backwardLoungeThreshold {
            // Backward lounge drift
            forwardDriftStart = nil
            forwardSlouchHoldSeconds = 0.0

            if backwardDriftStart == nil {
                backwardDriftStart = now
            }
            let elapsed = now.timeIntervalSince(backwardDriftStart!)
            backwardLoungeHoldSeconds = elapsed

            if elapsed >= directionGraceSeconds {
                if currentDirection != .backwardLounge {
                    backwardLoungeCount += 1
                    currentDirection = .backwardLounge
                }
                totalLoungeSeconds += dt
                HourlyFatigueProfiler.shared.recordPoorSecond(at: now, dt: dt)
            }
        } else {
            // Returned to optimal zone
            if currentDirection != .optimal {
                correctionsCount += 1
                HourlyFatigueProfiler.shared.recordCorrection()
            }
            forwardDriftStart = nil
            backwardDriftStart = nil
            forwardSlouchHoldSeconds = 0.0
            backwardLoungeHoldSeconds = 0.0
            currentDirection = .optimal
        }

        lastDirection = currentDirection
    }

    public func resetCounters() {
        forwardSlouchCount = 0
        backwardLoungeCount = 0
        totalSlouchSeconds = 0.0
        totalLoungeSeconds = 0.0
        correctionsCount = 0
        currentDirection = .optimal
    }
}
