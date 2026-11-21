import SwiftUI

/// Procedural Analog Film Grain & Warm Ember Canvas.
/// Inspired by the cinematic filmic aesthetic of https://www.human-md.ai.
public struct AnalogFilmGrainCanvasView: View {
    public let postureScore: Int
    
    @State private var phase: CGFloat = 0.0
    
    public init(postureScore: Int = 100) {
        self.postureScore = postureScore
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // 1. Deep Obsidian Espresso Base
                let baseRect = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(baseRect),
                    with: .color(HumanCinemaDesignSystem.Palette.obsidian)
                )
                
                // 2. Warm Human Pulse Radial Light (Top-Left Warmth)
                let pulseAlpha = 0.12 + 0.04 * sin(time * 0.8)
                let emberCenter = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
                let emberRadius = max(size.width, size.height) * 0.65
                
                context.fill(
                    Path(ellipseIn: CGRect(x: emberCenter.x - emberRadius, y: emberCenter.y - emberRadius, width: emberRadius * 2, height: emberRadius * 2)),
                    with: .radialGradient(
                        Gradient(colors: [
                            HumanCinemaDesignSystem.Palette.vermilion.opacity(pulseAlpha),
                            HumanCinemaDesignSystem.Palette.emberAmber.opacity(pulseAlpha * 0.4),
                            .clear
                        ]),
                        center: emberCenter,
                        startRadius: 0,
                        endRadius: emberRadius
                    )
                )
                
                // 3. Bottom-Right Subdued Sepia Light
                let sepiaCenter = CGPoint(x: size.width * 0.85, y: size.height * 0.8)
                let sepiaRadius = max(size.width, size.height) * 0.55
                context.fill(
                    Path(ellipseIn: CGRect(x: sepiaCenter.x - sepiaRadius, y: sepiaCenter.y - sepiaRadius, width: sepiaRadius * 2, height: sepiaRadius * 2)),
                    with: .radialGradient(
                        Gradient(colors: [
                            HumanCinemaDesignSystem.Palette.mutedSepia.opacity(0.08),
                            .clear
                        ]),
                        center: sepiaCenter,
                        startRadius: 0,
                        endRadius: sepiaRadius
                    )
                )
                
                // 4. Procedural Micro-Film Grain Simulation
                // We generate a deterministic pseudo-random scatter of subtle grain specks
                let grainSeed = Int(time * 12.0) % 8
                let step: CGFloat = 32.0
                var grainPath = Path()
                
                for x in stride(from: CGFloat(grainSeed * 4), to: size.width, by: step) {
                    for y in stride(from: CGFloat(grainSeed * 3), to: size.height, by: step) {
                        let offset = sin(x * 12.9898 + y * 78.233) * 6.0
                        let rect = CGRect(x: x + offset, y: y + offset, width: 1.2, height: 1.2)
                        grainPath.addRect(rect)
                    }
                }
                
                context.fill(
                    grainPath,
                    with: .color(HumanCinemaDesignSystem.Palette.parchment.opacity(0.035))
                )
            }
        }
        .ignoresSafeArea()
    }
}
