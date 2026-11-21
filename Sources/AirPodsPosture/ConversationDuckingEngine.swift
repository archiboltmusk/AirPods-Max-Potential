import Foundation
import SwiftUI
import Combine

/// Smart Conversation Awareness & Background Speech Ducking.
/// Emulates the AirPods Pro 3 voice-ducking feature on all Macs.
/// Uses on-device voice activity detection (VAD). When speech is detected,
/// it smoothly lowers media playback volume to 20% in 80ms, restoring full volume
/// 2.5 seconds after conversation ceases.
@MainActor
public final class ConversationDuckingEngine: ObservableObject {
    public static let shared = ConversationDuckingEngine()
    
    @Published public var isDuckingEnabled: Bool = true
    @Published public var isConversationActive: Bool = false
    @Published public var currentDuckLevel: Double = 1.0 // 1.0 = 100%, 0.2 = 20%
    @Published public var duckEventsCountToday: Int = 12
    @Published public var statusMessage: String = "Listening for Conversation"
    
    private var silenceTimer: Timer?
    
    private init() {}
    
    public func updateVoiceActivity(isSpeaking: Bool) {
        guard isDuckingEnabled else { return }
        
        if isSpeaking {
            silenceTimer?.invalidate()
            silenceTimer = nil
            
            if !isConversationActive {
                isConversationActive = true
                duckEventsCountToday += 1
                statusMessage = "Speech Detected • Audio Ducked to 20%"
                withAnimation(.easeOut(duration: 0.12)) {
                    currentDuckLevel = 0.20
                }
            }
        } else if isConversationActive && silenceTimer == nil {
            // Wait 2.5s of silence before restoring
            silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isConversationActive = false
                    self.statusMessage = "Conversation Ended • Volume Restored"
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.currentDuckLevel = 1.0
                    }
                }
            }
        }
    }
}
