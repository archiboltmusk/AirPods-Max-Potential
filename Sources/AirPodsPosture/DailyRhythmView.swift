import SwiftUI

public struct DailyRhythmView: View {
    @ObservedObject var motion = MotionManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DAILY RHYTHM & MOBILITY")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(CREDPalette.champagneGold)
                        Text("Biomechanical Fatigue Replay & Guided Spine Mobility")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(CREDPalette.platinumWhite)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                // 1. 24-Hour Biomechanical Scrub Bar
                BiomechanicalHeatmapView()
                
                // 2. Guided Cervical Spine Mobility Routine
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "figure.mind.and.body")
                            .foregroundColor(CREDPalette.electricCyan)
                            .font(.system(size: 14, weight: .bold))
                        Text("GUIDED CERVICAL RESET (2-MIN)")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(CREDPalette.platinumWhite)
                        Spacer()
                    }
                    
                    StretchCoachView(motion: motion)
                }
                .padding(20)
                .credCard(cornerRadius: 18, elevation: 8)
            }
            .padding(24)
        }
    }
}
