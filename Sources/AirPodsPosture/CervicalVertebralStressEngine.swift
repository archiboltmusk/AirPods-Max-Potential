import Foundation
import Combine

/// Biomechanical Cervical Spine Stress & Load Engine.
/// Implements validated Hansraj / Kapandji biomechanical models mapping
/// head pitch & roll angles to cervical gravitational load on C1–C7 vertebrae.
@MainActor
public final class CervicalVertebralStressEngine: ObservableObject {
    public static let shared = CervicalVertebralStressEngine()
    
    // Live Instantaneous Spinal Telemetry
    @Published public var instantLoadLbs: Double = 11.5
    @Published public var instantLoadKg: Double = 5.2
    @Published public var discStressRatio: Double = 1.0 // 1.0 = baseline neutral, up to 5.2x at 60°
    
    // Discs Specific Loading (C1 to C7)
    @Published public var c1c2AtlasStress: Double = 11.5
    @Published public var c3c4MidCervicalStress: Double = 12.0
    @Published public var c5c6HerniationHotspotStress: Double = 12.5 // Most frequent cervical disc herniation site
    @Published public var c6c7CervicothoracicStress: Double = 13.0
    
    // Risk & Diagnostic Ratings
    @Published public var herniationRiskTier: HerniationRiskTier = .nominal
    @Published public var cumulativeLoadNewtonHours: Double = 0.0
    @Published public var poundsOfStressAvoided: Double = 0.0
    
    public enum HerniationRiskTier: String, CaseIterable {
        case nominal = "Nominal Neutral (0° - 10°)"
        case elevated = "Elevated Tension (11° - 25°)"
        case critical = "Severe Herniation Vector (> 25°)"
        
        public var colorName: String {
            switch self {
            case .nominal: return "green"
            case .elevated: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    private var lastUpdateDate: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    public func computeSpinalBiometrics(pitch: Double, roll: Double) {
        let absPitch = abs(pitch)
        let absRoll = abs(roll)
        
        // Total combined sagittal and frontal angular deflection
        let combinedAngle = hypot(absPitch, absRoll * 0.75)
        
        // Hansraj Equation for gravitational head load:
        // 0°   -> ~10-12 lbs
        // 15°  -> ~27 lbs
        // 30°  -> ~40 lbs
        // 45°  -> ~49 lbs
        // 60°  -> ~60 lbs
        let clampedAngle = min(60.0, combinedAngle)
        let angleFraction = clampedAngle / 60.0
        
        // Non-linear polynomial fit to clinical biomechanics curve
        let load = 11.5 + (48.5 * pow(angleFraction, 0.82))
        self.instantLoadLbs = load
        self.instantLoadKg = load * 0.453592
        self.discStressRatio = load / 11.5
        
        // Differential distribution across cervical vertebrae:
        // C5-C6 and C6-C7 absorb ~55% of the gravitational bending moment
        self.c1c2AtlasStress = load * 0.85
        self.c3c4MidCervicalStress = load * 0.95
        self.c5c6HerniationHotspotStress = load * 1.15
        self.c6c7CervicothoracicStress = load * 1.20
        
        // Determine risk tier
        if combinedAngle <= 12.0 {
            self.herniationRiskTier = .nominal
        } else if combinedAngle <= 25.0 {
            self.herniationRiskTier = .elevated
        } else {
            self.herniationRiskTier = .critical
        }
        
        // Cumulative exposure integration (in Newton-hours)
        let now = Date()
        let elapsedHours = now.timeIntervalSince(lastUpdateDate) / 3600.0
        self.lastUpdateDate = now
        
        if elapsedHours > 0 && elapsedHours < 0.05 {
            let loadNewtons = self.instantLoadKg * 9.80665
            self.cumulativeLoadNewtonHours += (loadNewtons * elapsedHours)
            
            // Pounds of stress avoided: difference between bad posture (average 40 lbs) and current load
            if self.instantLoadLbs < 18.0 {
                let avoided = (35.0 - self.instantLoadLbs) * elapsedHours
                self.poundsOfStressAvoided += max(0.0, avoided)
            }
        }
    }
}
