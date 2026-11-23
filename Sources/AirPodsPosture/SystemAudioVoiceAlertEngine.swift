import Foundation
import AppKit
import AVFoundation

/// System Sound Picker & Spoken Voice Cue Alert Engine.
/// Inspired by chandansgowda/posture-fix: offers 11 macOS system sounds with preview,
/// plus an in-ear spoken voice prompt ("Sit up straight").
@MainActor
public final class SystemAudioVoiceAlertEngine: ObservableObject {
    public static let shared = SystemAudioVoiceAlertEngine()

    public static let availableSystemSounds = [
        "Funk", "Glass", "Ping", "Submarine", "Hero",
        "Tink", "Sosumi", "Pop", "Purr", "Bottle", "Blow"
    ]

    @Published public var isSoundEnabled: Bool = true
    @Published public var isVoiceCueEnabled: Bool = true
    @Published public var selectedSoundName: String = "Funk" {
        didSet { reloadSound() }
    }
    @Published public var voiceCuePhrase: String = "Sit up straight"
    @Published public var alertCooldownSeconds: Double = 15.0

    private var sound: NSSound? = NSSound(named: "Funk")
    private let synth = AVSpeechSynthesizer()
    private var lastAlertTime: Date = .distantPast

    private init() {
        reloadSound()
    }

    private func reloadSound() {
        sound = NSSound(named: NSSound.Name(selectedSoundName)) ?? NSSound(named: "Funk")
    }

    public func previewSound() {
        sound?.stop()
        sound?.play()
    }

    public func previewVoice() {
        speakCue(voiceCuePhrase)
    }

    public func speakSlouchReminder() {
        guard isVoiceCueEnabled else { return }
        let now = Date()
        guard now.timeIntervalSince(lastAlertTime) >= alertCooldownSeconds else { return }
        lastAlertTime = now
        speakCue(voiceCuePhrase)
    }

    private func speakCue(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.05
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }
}
