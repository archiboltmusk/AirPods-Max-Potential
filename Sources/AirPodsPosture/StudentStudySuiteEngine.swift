import Foundation
import CoreGraphics
import AppKit
import Combine

/// Student Study Suite Engine.
/// Designed specifically for high school, university, medical, law, and engineering students.
/// Features:
/// 1. Hands-Free Study Gestures: Nod to flip Anki cards / advance PDF lecture slides without taking hands off iPad/notebook.
/// 2. All-Nighter Micro-Sleep Guard: Detects nodding off during cramming sessions and plays wake-up chimes.
/// 3. Super-Learning 40Hz Gamma & 10Hz Alpha Binaural Soundscapes for memory retention and focus.
/// 4. Library Flat-Desk Laptop Angle Tolerance.
@MainActor
public final class StudentStudySuiteEngine: ObservableObject {
    public static let shared = StudentStudySuiteEngine()
    
    // Hands-Free Flashcard & Slide Gestures
    @Published public var isHandsFreeStudyGesturesEnabled: Bool = false
    @Published public var lastStudyGestureTriggered: String = "None"
    @Published public var cardsFlippedCount: Int = 0
    
    // All-Nighter Cramming & Drowsiness Mode
    @Published public var isCrammingModeActive: Bool = false
    @Published public var microSleepsCaughtCount: Int = 0
    @Published public var crammingSessionMinutes: Int = 0
    @Published public var drowsinessAlertBanner: String? = nil
    
    // Super-Learning Binaural Frequencies
    @Published public var selectedStudyFrequency: StudyWaveFrequency = .gamma40Hz
    @Published public var isStudyAudioPlaying: Bool = false
    
    public enum StudyWaveFrequency: String, CaseIterable, Identifiable {
        case gamma40Hz = "⚡️ 40Hz Gamma"
        case alpha10Hz = "📖 10Hz Alpha"
        case theta6Hz = "🔮 6Hz Theta"
        
        public var id: String { rawValue }
        
        public var shortTitle: String { rawValue }
        
        public var subtitle: String {
            switch self {
            case .gamma40Hz: return "Working memory encoding & rapid cognitive synthesis (40 Hz)"
            case .alpha10Hz: return "Relaxed reading flow, deep focus & comprehension (10 Hz)"
            case .theta6Hz: return "Subconscious concept mapping & deep visualization (6 Hz)"
            }
        }
        
        public var hz: Double {
            switch self {
            case .gamma40Hz: return 40.0
            case .alpha10Hz: return 10.0
            case .theta6Hz: return 6.0
            }
        }
        
        public var icon: String {
            switch self {
            case .gamma40Hz: return "brain.head.profile"
            case .alpha10Hz: return "book.fill"
            case .theta6Hz: return "sparkles"
            }
        }
    }
    
    private var lastGestureTime: Date = Date.distantPast
    private var crammingTimer: Timer?
    
    private init() {
        // Zero persistent background timers
    }
    
    private func startCrammingTimer() {
        crammingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isCrammingModeActive else { return }
                self.crammingSessionMinutes += 1
            }
        }
    }
    
    // MARK: - Hands-Free Study Gestures (Anki, Keynote, Preview, Canvas)
    
    /// Evaluates head pitch and roll for hands-free studying gestures
    public func processStudyGestures(pitch: Double, roll: Double) {
        guard isHandsFreeStudyGesturesEnabled else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) > 0.85 else { return } // 850ms rate limit
        
        // 1. Quick nod down (> 16° pitch drop) -> Emit Spacebar (Flip Anki card / advance slide)
        if pitch > 18.0 {
            emitVirtualKey(keyCode: 49) // 49 = Spacebar
            lastStudyGestureTriggered = "Nod Down • Flip Card / Slide (Space)"
            cardsFlippedCount += 1
            lastGestureTime = now
            SyntheticEarHapticEngine.shared.playTapticClick()
        }
        // 2. Head tilt right (> 14° roll) -> Emit Right Arrow (Good / Next Slide)
        else if roll > 14.0 {
            emitVirtualKey(keyCode: 124) // 124 = Right Arrow
            lastStudyGestureTriggered = "Tilt Right • Next Slide / 'Good' (→)"
            cardsFlippedCount += 1
            lastGestureTime = now
            SyntheticEarHapticEngine.shared.playSpatialEarTap(leftGain: 0.1, rightGain: 1.0, baseFreq: 180.0)
        }
        // 3. Head tilt left (< -14° roll) -> Emit Left Arrow (Again / Prev Slide)
        else if roll < -14.0 {
            emitVirtualKey(keyCode: 123) // 123 = Left Arrow
            lastStudyGestureTriggered = "Tilt Left • Prev Slide / 'Again' (←)"
            cardsFlippedCount += 1
            lastGestureTime = now
            SyntheticEarHapticEngine.shared.playSpatialEarTap(leftGain: 1.0, rightGain: 0.1, baseFreq: 180.0)
        }
    }
    
    private func emitVirtualKey(keyCode: CGKeyCode) {
        let src = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
           let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) {
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - All-Nighter Cramming Drowsiness Alert
    
    public func notifyMicroSleepCaught() {
        microSleepsCaughtCount += 1
        drowsinessAlertBanner = "💤 Micro-Sleep Caught: Head Jerk Detected! Stand up or grab water."
        SyntheticEarHapticEngine.shared.playSuccessChirp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.drowsinessAlertBanner = nil
        }
    }
    
    // MARK: - Super-Learning Audio Controls
    
    public func toggleStudyAudio() {
        if BinauralBeatsEngine.shared.isPlaying {
            BinauralBeatsEngine.shared.stop()
            isStudyAudioPlaying = false
        } else {
            switch selectedStudyFrequency {
            case .gamma40Hz:
                BinauralBeatsEngine.shared.selectedPreset = .gamma40
            case .alpha10Hz:
                BinauralBeatsEngine.shared.selectedPreset = .alpha10
            case .theta6Hz:
                BinauralBeatsEngine.shared.selectedPreset = .theta6
            }
            BinauralBeatsEngine.shared.start()
            isStudyAudioPlaying = true
        }
    }
}
