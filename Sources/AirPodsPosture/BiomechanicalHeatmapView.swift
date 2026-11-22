import SwiftUI
import AppKit

public struct HourlySpineSample: Identifiable {
    public let id = UUID()
    public let hourLabel: String
    public let score: Int
    public let dominantSlouchType: String
}

public struct BiomechanicalHeatmapView: View {
    @State private var selectedIndex: Int = 11 // Default to current hour
    
    public let hours: [HourlySpineSample] = [
        HourlySpineSample(hourLabel: "9 AM", score: 95, dominantSlouchType: "Upright Focus"),
        HourlySpineSample(hourLabel: "10 AM", score: 92, dominantSlouchType: "Upright Focus"),
        HourlySpineSample(hourLabel: "11 AM", score: 88, dominantSlouchType: "Minor Tilt (Roll 6°)"),
        HourlySpineSample(hourLabel: "12 PM", score: 76, dominantSlouchType: "Lumbar Recline"),
        HourlySpineSample(hourLabel: "1 PM", score: 90, dominantSlouchType: "Post-Lunch Rest"),
        HourlySpineSample(hourLabel: "2 PM", score: 68, dominantSlouchType: "Tech-Neck Flexion (-18°)"),
        HourlySpineSample(hourLabel: "3 PM", score: 62, dominantSlouchType: "Thoracic Slump in Meeting"),
        HourlySpineSample(hourLabel: "4 PM", score: 82, dominantSlouchType: "Ergonomic Break Reset"),
        HourlySpineSample(hourLabel: "5 PM", score: 74, dominantSlouchType: "Fatigue Neck Protrusion"),
        HourlySpineSample(hourLabel: "6 PM", score: 89, dominantSlouchType: "Standing Desk Glide"),
        HourlySpineSample(hourLabel: "7 PM", score: 91, dominantSlouchType: "Optimal Alignment"),
        HourlySpineSample(hourLabel: "8 PM", score: 86, dominantSlouchType: "Evening Focus Session")
    ]
    
    public init() {}
    
    private func cellColor(for score: Int) -> Color {
        if score >= 85 { return CREDPalette.emeraldPlasma }
        if score >= 70 { return CREDPalette.champagneGold }
        return CREDPalette.moltenRuby
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(CREDPalette.champagneGold)
                        .font(.system(size: 11, weight: .bold))
                    Text("24-HOUR BIOMECHANICAL SCRUB BAR")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(CREDPalette.platinumWhite)
                }
                Spacer()
                Text("INTERACTIVE REPLAY")
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundColor(CREDPalette.phantomGray)
            }
            
            // Heatmap Matrix Cells
            HStack(spacing: 6) {
                ForEach(0..<hours.count, id: \.self) { idx in
                    let sample = hours[idx]
                    let isSelected = selectedIndex == idx
                    let color = cellColor(for: sample.score)
                    
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                            )
                            .shadow(color: isSelected ? color.opacity(0.8) : Color.clear, radius: 6)
                            .onTapGesture {
                                selectedIndex = idx
                                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                                MotionManager.shared.playFeedbackSound("Tink")
                            }
                        
                        Text(sample.hourLabel)
                            .font(.system(size: 8.5, weight: isSelected ? .bold : .medium, design: .monospaced))
                            .foregroundColor(isSelected ? CREDPalette.platinumWhite : CREDPalette.phantomGray)
                    }
                }
            }
            
            // Reconstructed Snapshot Detail Card
            let currentSample = hours[selectedIndex]
            let detailColor = cellColor(for: currentSample.score)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(currentSample.hourLabel.uppercased()) CERVICAL SNAPSHOT")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(CREDPalette.platinumWhite)
                    Text("SPINE HEALTH: \(currentSample.score)% · \(currentSample.dominantSlouchType.uppercased())")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(detailColor)
                }
                Spacer()
                Image(systemName: currentSample.score >= 80 ? "shield.checkmark.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(detailColor)
                    .font(.system(size: 14))
            }
            .padding(12)
            .credInsetTrough(cornerRadius: 10)
        }
        .padding(18)
        .credCard(cornerRadius: 18, elevation: 10)
    }
}
