import SwiftUI

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
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.teal)
                Text("24-Hour Biomechanical Timeline Scrub Bar")
                    .font(.headline)
                Spacer()
                Text("Interactive Workday Replay")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Heatmap Matrix Cells
            HStack(spacing: 6) {
                ForEach(0..<hours.count, id: \.self) { idx in
                    let sample = hours[idx]
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(sample.score >= 85 ? Color.green : (sample.score >= 70 ? Color.orange : Color.red))
                            .frame(height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedIndex == idx ? Color.white : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedIndex = idx
                                MotionManager.shared.playFeedbackSound("Tink")
                            }
                        
                        Text(sample.hourLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(selectedIndex == idx ? .primary : .secondary)
                    }
                }
            }
            
            // Reconstructed Snapshot Detail Card
            let currentSample = hours[selectedIndex]
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentSample.hourLabel) Spine Snapshot")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                    Text("Spine Health: \(currentSample.score)% • Diagnosis: \(currentSample.dominantSlouchType)")
                        .font(.caption2)
                        .foregroundColor(currentSample.score >= 80 ? .green : .orange)
                }
                Spacer()
                Image(systemName: currentSample.score >= 80 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(currentSample.score >= 80 ? .green : .orange)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
    }
}
