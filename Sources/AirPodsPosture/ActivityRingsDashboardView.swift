import SwiftUI

public struct ActivityRingsDashboardView: View {
    public let postureScore: Double // 0 to 100
    public let hydrationGlasses: Int // Goal: 8
    public let romScore: Double // Goal: 100
    
    public init(postureScore: Double, hydrationGlasses: Int, romScore: Double) {
        self.postureScore = postureScore
        self.hydrationGlasses = hydrationGlasses
        self.romScore = romScore
    }
    
    public var body: some View {
        HStack(spacing: 24) {
            // Concentric Activity Rings
            ZStack {
                // Background Track Rings
                Circle()
                    .stroke(Color.green.opacity(0.18), lineWidth: 14)
                    .frame(width: 130, height: 130)
                Circle()
                    .stroke(Color.cyan.opacity(0.18), lineWidth: 14)
                    .frame(width: 98, height: 98)
                Circle()
                    .stroke(Color.purple.opacity(0.18), lineWidth: 14)
                    .frame(width: 66, height: 66)
                
                // Outer Ring: Posture Score %
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, postureScore / 100.0)))
                    .stroke(
                        AngularGradient(colors: [.green, .mint], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 130, height: 130)
                    .shadow(color: .green.opacity(0.4), radius: 4)
                
                // Middle Ring: Hydration (Glasses / 8)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, Double(hydrationGlasses) / 8.0)))
                    .stroke(
                        AngularGradient(colors: [.blue, .cyan], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 98, height: 98)
                    .shadow(color: .cyan.opacity(0.4), radius: 4)
                
                // Inner Ring: Cervical ROM Mobility %
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, romScore / 100.0)))
                    .stroke(
                        AngularGradient(colors: [.purple, .pink], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 66, height: 66)
                    .shadow(color: .purple.opacity(0.4), radius: 4)
            }
            .frame(width: 140, height: 140)
            
            // Legend & Real-Time Statistics
            VStack(alignment: .leading, spacing: 10) {
                // Posture Ring Legend
                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Posture Quality")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(postureScore))% Optimal Alignment")
                            .font(.caption.bold())
                    }
                }
                
                // Hydration Ring Legend
                HStack(spacing: 8) {
                    Circle().fill(Color.cyan).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Kinematic Hydration")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(hydrationGlasses) of 8 Glasses Ingested")
                            .font(.caption.bold())
                    }
                }
                
                // Cervical ROM Legend
                HStack(spacing: 8) {
                    Circle().fill(Color.purple).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Cervical Spine Mobility")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(romScore))% Mobility Index")
                            .font(.caption.bold())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
    }
}
