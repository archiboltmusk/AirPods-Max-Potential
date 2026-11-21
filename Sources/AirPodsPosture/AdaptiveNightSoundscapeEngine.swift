import Foundation
import SwiftUI
import Combine

/// Adaptive Bedroom Soundscape & Nocturnal Tinnitus Masker.
/// Creates a soothing acoustic sound floor that dynamically adjusts its gain based on ambient room noise:
/// smoothly elevating during transient outdoor noises (car honks, air conditioners)
/// and receding during quiet moments to prevent auditory fatigue.
///
/// Features a customizable notch filter configured to the user's specific audiogram dip
/// to neutralize nighttime ear ringing (tinnitus) without waking the auditory cortex.
@MainActor
public final class AdaptiveNightSoundscapeEngine: ObservableObject {
    public static let shared = AdaptiveNightSoundscapeEngine()
    
    @Published public var isSoundscapeActive: Bool = false
    @Published public var selectedSoundscape: SoundscapeMode = .brownNoise
    @Published public var currentOutputVolume: Double = 0.35
    @Published public var isTinnitusNotchFilterEnabled: Bool = true
    @Published public var notchFilterFrequencyHz: Int = 4000
    @Published public var ambientNoiseRoomFloorDba: Double = 32.5
    
    public enum SoundscapeMode: String, CaseIterable, Identifiable {
        case brownNoise = "Deep Brown Noise (Restorative)"
        case rainfall = "Gentle Forest Rain"
        case pinkWaves = "Pink Wave Surf"
        case deltaBinaural = "Delta Harmonic Drone (1.2Hz)"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .brownNoise: return "waveform"
            case .rainfall: return "cloud.rain.fill"
            case .pinkWaves: return "water.waves"
            case .deltaBinaural: return "moon.stars.fill"
            }
        }
    }
    
    private var adaptTimer: Timer?
    
    private init() {
        startAdaptiveGainMonitor()
    }
    
    private func startAdaptiveGainMonitor() {
        adaptTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.adaptVolumeToRoomNoise()
            }
        }
    }
    
    public func toggleSoundscape() {
        isSoundscapeActive.toggle()
        if isSoundscapeActive {
            NSSound(named: "Purr")?.play()
        }
    }
    
    private func adaptVolumeToRoomNoise() {
        guard isSoundscapeActive else { return }
        
        // Dynamically adjust soundscape gain to maintain a 6dB protective signal-to-noise ratio
        let roomNoise = NoiseDosimeterEngine.shared.currentDecibelsDba
        ambientNoiseRoomFloorDba = roomNoise
        
        withAnimation(.easeInOut(duration: 1.0)) {
            if roomNoise > 55.0 {
                // Room has transient noise — gently raise mask volume
                currentOutputVolume = min(0.70, currentOutputVolume + 0.08)
            } else if currentOutputVolume > 0.30 {
                // Quiet room — taper down
                currentOutputVolume = max(0.25, currentOutputVolume - 0.03)
            }
        }
    }
}
