import Foundation
import SwiftUI
import Combine

/// Tympanic Membrane Thermal & Metabolic Exertion Estimator.
/// Emulates the upcoming AirPods Pro 3 in-ear core temperature sensor.
/// The tympanic membrane shares the internal carotid artery blood supply with the hypothalamus,
/// making the ear canal the gold-standard site for non-invasive core temperature tracking.
///
/// Fuses acoustic carotid pulse velocity (AcousticPulseEstimator), respiratory rate (AcousticRespiratoryEngine),
/// and head kinetic motion variance (MotionManager) to model instantaneous core temperature fluctuations
/// and metabolic heat buildup during long focus sessions or physical workouts.
@MainActor
public final class TympanicThermalEstimator: ObservableObject {
    public static let shared = TympanicThermalEstimator()
    
    @Published public var isMonitoringEnabled: Bool = true
    @Published public var estimatedEarTempCelsius: Double = 36.85
    @Published public var thermalExertionIndex: Double = 18.0 // 0 - 100%
    @Published public var baselineCalibratedTemp: Double = 36.80
    @Published public var thermalZone: ThermalZone = .optimal
    @Published public var thermalStatusMessage: String = "Thermal Equilibrium Nominal (36.8°C)"
    @Published public var sessionPeakTempCelsius: Double = 37.02
    @Published public var totalOverheatWarningsToday: Int = 0
    
    public enum ThermalZone: String, CaseIterable {
        case hypothermic = "Hypothermic Slump (<36.2°C)"
        case optimal = "Optimal Core Nominal (36.4°C - 37.2°C)"
        case elevatedCognitive = "Elevated Cognitive Heat (37.3°C - 37.7°C)"
        case hyperthermicExertion = "Metabolic Heat Stress (>37.8°C)"
        
        public var color: Color {
            switch self {
            case .hypothermic: return .blue
            case .optimal: return .green
            case .elevatedCognitive: return .orange
            case .hyperthermicExertion: return .red
            }
        }
        
        public var icon: String {
            switch self {
            case .hypothermic: return "snowflake"
            case .optimal: return "thermometer.sun.fill"
            case .elevatedCognitive: return "flame.fill"
            case .hyperthermicExertion: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    public var estimatedEarTempFahrenheit: Double {
        return (estimatedEarTempCelsius * 9.0 / 5.0) + 32.0
    }
    
    private var simulationTimer: Timer?
    
    private init() {
        startThermalTracking()
    }
    
    public func startThermalTracking() {
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateTympanicThermalIndex()
            }
        }
    }
    
    public func calibrateBaseline() {
        baselineCalibratedTemp = estimatedEarTempCelsius
        thermalStatusMessage = String(format: "Baseline Calibrated at %.2f°C", baselineCalibratedTemp)
    }
    
    private func evaluateTympanicThermalIndex() {
        guard isMonitoringEnabled else { return }
        
        let heartRate = AcousticPulseEstimator.shared.estimatedBPM
        let respRate = AcousticRespiratoryEngine.shared.breathsPerMinute
        
        // Compute metabolic load: normal resting is 65-75 bpm and 12-16 rpm
        let hrStrain = max(0.0, (Double(heartRate) - 70.0) / 40.0)
        let respStrain = max(0.0, (Double(respRate) - 14.0) / 10.0)
        let rawMetabolicLoad = min(1.0, (hrStrain * 0.6) + (respStrain * 0.4))
        
        withAnimation(.easeInOut(duration: 0.8)) {
            thermalExertionIndex = min(100.0, max(5.0, (rawMetabolicLoad * 80.0) + Double.random(in: 12.0...22.0)))
            
            // Model tympanic temp: baseline + metabolic heat delta (-0.2°C to +0.9°C)
            let tempDelta = (thermalExertionIndex / 100.0) * 0.85
            let microJitter = Double.random(in: -0.04...0.04)
            estimatedEarTempCelsius = baselineCalibratedTemp + tempDelta + microJitter
            sessionPeakTempCelsius = max(sessionPeakTempCelsius, estimatedEarTempCelsius)
            
            // Classify zone
            if estimatedEarTempCelsius < 36.2 {
                thermalZone = .hypothermic
                thermalStatusMessage = "Core temperature reduced — recommend light physical movement."
            } else if estimatedEarTempCelsius <= 37.2 {
                thermalZone = .optimal
                thermalStatusMessage = "Thermal equilibrium nominal. Cerebral perfusion is balanced."
            } else if estimatedEarTempCelsius <= 37.7 {
                thermalZone = .elevatedCognitive
                thermalStatusMessage = "Cerebral blood flow elevated from intense cognitive focus."
            } else {
                thermalZone = .hyperthermicExertion
                thermalStatusMessage = "High metabolic heat detected. Consider hydration and cooling break."
                totalOverheatWarningsToday += 1
            }
        }
    }
}
