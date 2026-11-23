import Foundation
import CoreAudio
import SwiftUI
import Combine

/// 3-Tier Posture Escalation & Audio Mute Fallback Engine.
/// 1. 3-Tier Escalation Curve with 15s hysteresis:
///    - Tier 1 (15s): Silent Menu Bar amber indicator
///    - Tier 2 (30s): Subtle spatial audio panning offset
///    - Tier 3 (60s): Gentle harmonic chime (-18 dBFS)
/// 2. Audio Mute Fallback:
///    - Queries CoreAudio output mute. If muted, automatically triggers
///      a native macOS Notification Banner instead of playing into silence.
@MainActor
public final class TieredPostureEscalationEngine: ObservableObject {
    public static let shared = TieredPostureEscalationEngine()
    
    public enum EscalationTier: Int {
        case optimal = 0
        case tier1_VisualOnly = 1     // 15s - 30s
        case tier2_SpatialShift = 2   // 30s - 60s
        case tier3_AudioChime = 3     // 60s+
        
        public var description: String {
            switch self {
            case .optimal: return "Optimal Upright"
            case .tier1_VisualOnly: return "Tier 1: Visual Amber Cue (15s)"
            case .tier2_SpatialShift: return "Tier 2: Subtle Spatial Panning (30s)"
            case .tier3_AudioChime: return "Tier 3: Harmonic Chime (60s)"
            }
        }
    }
    
    @Published public var currentTier: EscalationTier = .optimal
    @Published public var isOutputMuted: Bool = false
    @Published public var escalationTimeSeconds: Double = 0.0
    @Published public var fallbackNotificationsSentCount: Int = 0
    @Published public var statusMessage: String = "Escalation Engine Ready"
    
    private var slouchStartTime: Date?
    private var lastTierTriggered: EscalationTier = .optimal
    
    private init() {
        checkOutputMute()
    }
    
    /// Evaluates slouch duration and triggers the appropriate graduated tier
    public func updateSlouchDuration(isCompromised: Bool, deltaPitch: Double, deltaRoll: Double, allowsAudio: @autoclosure () -> Bool = false) {
        let now = Date()
        
        if isCompromised {
            if slouchStartTime == nil {
                slouchStartTime = now
            }
            escalationTimeSeconds = now.timeIntervalSince(slouchStartTime!)
            
            if escalationTimeSeconds >= 60.0 {
                transitionTo(tier: .tier3_AudioChime, pitch: deltaPitch, roll: deltaRoll, allowsAudio: allowsAudio)
            } else if escalationTimeSeconds >= 30.0 {
                transitionTo(tier: .tier2_SpatialShift, pitch: deltaPitch, roll: deltaRoll, allowsAudio: allowsAudio)
            } else if escalationTimeSeconds >= 15.0 {
                transitionTo(tier: .tier1_VisualOnly, pitch: deltaPitch, roll: deltaRoll, allowsAudio: allowsAudio)
            } else {
                currentTier = .optimal
            }
        } else if slouchStartTime != nil {
            slouchStartTime = nil
            escalationTimeSeconds = 0.0
            currentTier = .optimal
            lastTierTriggered = .optimal
            statusMessage = "Escalation Engine Ready"
        }
    }
    
    private func transitionTo(tier: EscalationTier, pitch: Double, roll: Double, allowsAudio: () -> Bool) {
        currentTier = tier
        guard tier != lastTierTriggered else { return }
        lastTierTriggered = tier
        
        checkOutputMute()
        
        switch tier {
        case .tier1_VisualOnly:
            statusMessage = "Tier 1: Silent Amber Pulse (Menu Bar)"
            DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Slight Forward Slouch Detected", autoDismissSeconds: 2.5)
            
        case .tier2_SpatialShift:
            statusMessage = "Tier 2: Subtle Spatial Panning Shift"
            if allowsAudio() {
                SyntheticEarHapticEngine.shared.playDirectionalPostureCue(pitch: pitch, roll: roll)
            } else {
                SyntheticEarHapticEngine.shared.performTrackpadHaptic()
            }
            
        case .tier3_AudioChime:
            statusMessage = "Tier 3: Posture Alert Triggered"
            if isOutputMuted || !allowsAudio() {
                // Audio is muted or user is in a meeting; fallback to macOS notification banner
                fallbackNotificationsSentCount += 1
                NotificationManager.shared.sendSlouchNotification(pitch: pitch, roll: roll)
            } else {
                // Play soft audible harmonic cue
                SyntheticEarHapticEngine.shared.playDirectionalPostureCue(
                    pitch: pitch,
                    roll: roll,
                    pitchThreshold: 8.0,
                    rollThreshold: 10.0
                )
            }
        case .optimal:
            break
        }
    }
    
    /// Checks CoreAudio default output mute flag
    public func checkOutputMute() {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )
        
        guard status == noErr, defaultOutputDeviceID != 0 else { return }
        
        var muted: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let err = AudioObjectGetPropertyData(defaultOutputDeviceID, &muteAddress, 0, nil, &muteSize, &muted)
        if err == noErr {
            self.isOutputMuted = (muted != 0)
        }
    }
}
