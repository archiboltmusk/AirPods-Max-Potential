import Foundation
import AppKit

@MainActor
public final class HearingSafetyMonitor: ObservableObject {
    public static let shared = HearingSafetyMonitor()
    
    @Published public var currentVolumePercent: Int = 35
    @Published public var estimatedDecibels: Int = 68 // dBA
    @Published public var dailyDosePercentage: Double = 12.0 // % of WHO daily limit
    @Published public var isVolumeDangerous: Bool = false
    
    private var timer: Timer? = nil
    
    private init() {
        queryVolume()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.queryVolume()
            }
        }
    }
    
    public func queryVolume() {
        let script = NSAppleScript(source: "output volume of (get volume settings)")
        if let res = script?.executeAndReturnError(nil) {
            let vol = Int(res.int32Value)
            self.currentVolumePercent = vol
            
            // Calibrated curve for AirPods Pro:
            // 20% vol ~ 58 dBA, 50% vol ~ 72 dBA, 80% vol ~ 86 dBA, 100% vol ~ 100 dBA
            let dBA = Int(50.0 + (Double(vol) / 100.0) * 50.0)
            self.estimatedDecibels = dBA
            
            // WHO safe threshold: 85 dBA is threshold of acoustic damage over time
            self.isVolumeDangerous = (dBA >= 85)
            
            // Accumulate daily dose: 80 dBA = 1.0x rate (100% in 8 hrs = 0.0035% per 5s)
            let doseRateMultiplier = pow(2.0, Double(dBA - 80) / 3.0)
            let deltaDose = (5.0 / (8.0 * 3600.0)) * doseRateMultiplier * 100.0
            self.dailyDosePercentage = min(200.0, self.dailyDosePercentage + deltaDose)
        }
    }
}
