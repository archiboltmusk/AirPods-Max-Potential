import SwiftUI

public struct FluidChromaticCanvasView: View {
    public let postureScore: Int
    
    @State private var phase: CGFloat = 0.0
    
    public init(postureScore: Int) {
        self.postureScore = postureScore
    }
    
    // Dynamic color palette based on posture health
    private var primaryOrbColor: Color {
        if postureScore >= 80 {
            return Color(red: 0.0, green: 0.85, blue: 0.72) // Bioluminescent Cyan
        } else if postureScore >= 60 {
            return Color(red: 0.95, green: 0.55, blue: 0.15) // Deep Amber
        } else {
            return Color(red: 0.92, green: 0.22, blue: 0.35) // Neon Crimson
        }
    }
    
    private var secondaryOrbColor: Color {
        if postureScore >= 80 {
            return Color(red: 0.12, green: 0.45, blue: 0.95) // Deep Sapphire
        } else if postureScore >= 60 {
            return Color(red: 0.65, green: 0.25, blue: 0.85) // Ultraviolet
        } else {
            return Color(red: 0.55, green: 0.08, blue: 0.25) // Wine Red
        }
    }
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let s1 = sin(time * 0.45)
                let c1 = cos(time * 0.35)
                
                // Base deep space gradient
                let baseRect = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(baseRect),
                    with: .linearGradient(
                        Gradient(colors: [Color(red: 0.04, green: 0.04, blue: 0.07), Color(red: 0.02, green: 0.02, blue: 0.04)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
                
                // Living Fluid Plasma Orb 1 (Top Left Drift)
                let orb1Center = CGPoint(
                    x: size.width * 0.35 + CGFloat(s1) * (size.width * 0.15),
                    y: size.height * 0.3 + CGFloat(c1) * (size.height * 0.12)
                )
                let orb1Radius = min(size.width, size.height) * 0.65
                let orb1Rect = CGRect(x: orb1Center.x - orb1Radius, y: orb1Center.y - orb1Radius, width: orb1Radius * 2, height: orb1Radius * 2)
                
                context.fill(
                    Path(ellipseIn: orb1Rect),
                    with: .radialGradient(
                        Gradient(colors: [primaryOrbColor.opacity(0.22), .clear]),
                        center: orb1Center,
                        startRadius: 0,
                        endRadius: orb1Radius
                    )
                )
                
                // Living Fluid Plasma Orb 2 (Bottom Right Drift)
                let orb2Center = CGPoint(
                    x: size.width * 0.75 - CGFloat(c1) * (size.width * 0.18),
                    y: size.height * 0.65 - CGFloat(s1) * (size.height * 0.15)
                )
                let orb2Radius = min(size.width, size.height) * 0.75
                let orb2Rect = CGRect(x: orb2Center.x - orb2Radius, y: orb2Center.y - orb2Radius, width: orb2Radius * 2, height: orb2Radius * 2)
                
                context.fill(
                    Path(ellipseIn: orb2Rect),
                    with: .radialGradient(
                        Gradient(colors: [secondaryOrbColor.opacity(0.18), .clear]),
                        center: orb2Center,
                        startRadius: 0,
                        endRadius: orb2Radius
                    )
                )
            }
            .blur(radius: 40)
        }
        .ignoresSafeArea()
    }
}
