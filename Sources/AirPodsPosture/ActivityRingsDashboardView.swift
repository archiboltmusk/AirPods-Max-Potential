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
    
    private var postureProgress: CGFloat {
        CGFloat(max(0.0, min(1.0, postureScore / 100.0)))
    }
    
    private var hydrationProgress: CGFloat {
        CGFloat(max(0.0, min(1.0, Double(hydrationGlasses) / 8.0)))
    }
    
    private var romProgress: CGFloat {
        CGFloat(max(0.0, min(1.0, romScore / 100.0)))
    }

    public var body: some View {
        HStack(spacing: 24) {
            // Concentric Dials
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: 12)
                    .frame(width: 124, height: 124)
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: 12)
                    .frame(width: 94, height: 94)
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: 12)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: postureProgress)
                    .stroke(
                        AngularGradient(
                            colors: [CREDPalette.emeraldPlasma, CREDPalette.electricCyan, CREDPalette.emeraldPlasma],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 124, height: 124)
                    .shadow(color: CREDPalette.emeraldPlasma.opacity(0.4), radius: 4)
                
                Circle()
                    .trim(from: 0, to: hydrationProgress)
                    .stroke(
                        AngularGradient(
                            colors: [CREDPalette.electricCyan, Color.blue, CREDPalette.electricCyan],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 94, height: 94)
                    .shadow(color: CREDPalette.electricCyan.opacity(0.4), radius: 4)
                
                Circle()
                    .trim(from: 0, to: romProgress)
                    .stroke(
                        AngularGradient(
                            colors: [CREDPalette.champagneGold, Color.orange, CREDPalette.champagneGold],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                    .shadow(color: CREDPalette.champagneGold.opacity(0.4), radius: 4)
            }
            .frame(width: 136, height: 136)
            
            // Telemetry Legend
            VStack(alignment: .leading, spacing: 12) {
                CREDTelemetryLegendRow(
                    color: CREDPalette.emeraldPlasma,
                    title: "POSTURE QUALITY QUOTIENT",
                    value: "\(Int(postureScore))% OPTIMAL NEUTRAL"
                )
                CREDTelemetryLegendRow(
                    color: CREDPalette.electricCyan,
                    title: "KINEMATIC HYDRATION CADENCE",
                    value: "\(hydrationGlasses) OF 8 INGESTION QUOTA"
                )
                CREDTelemetryLegendRow(
                    color: CREDPalette.champagneGold,
                    title: "CERVICAL SPINE MOBILITY INDEX",
                    value: "\(Int(romScore))% FULL RANGE OF MOTION"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(CREDPalette.cardSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(CREDPalette.specularRimStroke, lineWidth: 1)
        )
    }
}

public struct CREDTelemetryLegendRow: View {
    public let color: Color
    public let title: String
    public let value: String
    
    public init(color: Color, title: String, value: String) {
        self.color = color
        self.title = title
        self.value = value
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.7), radius: 3)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(CREDPalette.phantomGray)
                Text(value)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(CREDPalette.platinumWhite)
            }
        }
    }
}
