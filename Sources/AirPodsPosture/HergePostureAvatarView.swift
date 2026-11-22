import SwiftUI

/// Hergé Ligne Claire Animated Posture Companion Avatar.
/// Inspired by Allen's open-source AirPosture avatar, styled in our beloved Hergé / Tintin Ligne Claire aesthetic.
/// Physically slumps in real-time when the user slouches, and beams with cheerful pride when upright.
public struct HergePostureAvatarView: View {
    let pitch: Double
    let roll: Double
    let postureScore: Int
    let isCompact: Bool
    
    @State private var breathePhase: Double = 0.0
    
    public init(pitch: Double, roll: Double, postureScore: Int, isCompact: Bool = false) {
        self.pitch = pitch
        self.roll = roll
        self.postureScore = postureScore
        self.isCompact = isCompact
    }
    
    private var stateTone: Color {
        if postureScore >= 80 {
            return .green
        } else if postureScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Slump factor from 0.0 (perfect) to 1.0 (slouched)
    private var slumpFactor: Double {
        let normalized = min(1.0, max(0.0, (80.0 - Double(postureScore)) / 50.0))
        return normalized
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let scale = min(w, h) / 140.0
            
            ZStack {
                // Background soft parchment aura
                RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                            .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 3.0 * scale)
                    )
                    .shadow(color: stateTone.opacity(0.35), radius: 10 * scale, x: 0, y: 4 * scale)
                
                // Character Group with real-time pitch tilt and roll
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    ZStack {
                        // 1. Torso & Slumping Spine Curve
                        Path { path in
                            // Shoulder base
                            let startX: CGFloat = 40 * scale
                            let startY: CGFloat = 135 * scale
                            let neckX: CGFloat = 62 * scale + CGFloat(slumpFactor * 14.0 * scale)
                            let neckY: CGFloat = 88 * scale + CGFloat(slumpFactor * 10.0 * scale)
                            let backX: CGFloat = 95 * scale
                            let backY: CGFloat = 135 * scale
                            
                            path.move(to: CGPoint(x: startX, y: startY))
                            path.addQuadCurve(
                                to: CGPoint(x: neckX, y: neckY),
                                control: CGPoint(x: startX + 5 * scale, y: 105 * scale)
                            )
                            path.addQuadCurve(
                                to: CGPoint(x: backX, y: backY),
                                control: CGPoint(x: (neckX + backX) / 2.0 + CGFloat(slumpFactor * 12.0 * scale), y: (neckY + backY) / 2.0)
                            )
                            path.closeSubpath()
                        }
                        .fill(Color(red: 0.95, green: 0.85, blue: 0.74))
                        .overlay(
                            Path { path in
                                let startX: CGFloat = 40 * scale
                                let startY: CGFloat = 135 * scale
                                let neckX: CGFloat = 62 * scale + CGFloat(slumpFactor * 14.0 * scale)
                                let neckY: CGFloat = 88 * scale + CGFloat(slumpFactor * 10.0 * scale)
                                let backX: CGFloat = 95 * scale
                                let backY: CGFloat = 135 * scale
                                
                                path.move(to: CGPoint(x: startX, y: startY))
                                path.addQuadCurve(
                                    to: CGPoint(x: neckX, y: neckY),
                                    control: CGPoint(x: startX + 5 * scale, y: 105 * scale)
                                )
                                path.addQuadCurve(
                                    to: CGPoint(x: backX, y: backY),
                                    control: CGPoint(x: (neckX + backX) / 2.0 + CGFloat(slumpFactor * 12.0 * scale), y: (neckY + backY) / 2.0)
                                )
                            }
                            .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 3.5 * scale)
                        )
                        
                        // 2. Animated Head with Pitch Tilt & Roll
                        VStack(spacing: 0) {
                            ZStack {
                                // Hair Back
                                Circle()
                                    .fill(Color(red: 0.32, green: 0.22, blue: 0.15))
                                    .frame(width: 52 * scale, height: 50 * scale)
                                    .offset(x: 2 * scale, y: -6 * scale)
                                
                                // Face
                                Circle()
                                    .fill(Color(red: 0.97, green: 0.88, blue: 0.78))
                                    .frame(width: 46 * scale, height: 46 * scale)
                                    .overlay(
                                        Circle().stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 3.0 * scale)
                                    )
                                
                                // Hair Quiff / Cowlick (Classic Hergé style)
                                Path { path in
                                    path.move(to: CGPoint(x: 10 * scale, y: 12 * scale))
                                    path.addQuadCurve(to: CGPoint(x: 34 * scale, y: 6 * scale), control: CGPoint(x: 18 * scale, y: 0))
                                    path.addQuadCurve(to: CGPoint(x: 42 * scale, y: 18 * scale), control: CGPoint(x: 40 * scale, y: 10 * scale))
                                    path.addQuadCurve(to: CGPoint(x: 10 * scale, y: 18 * scale), control: CGPoint(x: 26 * scale, y: 14 * scale))
                                    path.closeSubpath()
                                }
                                .fill(Color(red: 0.32, green: 0.22, blue: 0.15))
                                .overlay(
                                    Path { path in
                                        path.move(to: CGPoint(x: 10 * scale, y: 12 * scale))
                                        path.addQuadCurve(to: CGPoint(x: 34 * scale, y: 6 * scale), control: CGPoint(x: 18 * scale, y: 0))
                                        path.addQuadCurve(to: CGPoint(x: 42 * scale, y: 18 * scale), control: CGPoint(x: 40 * scale, y: 10 * scale))
                                    }
                                    .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 3.0 * scale)
                                )
                                .offset(x: -23 * scale, y: -23 * scale)
                                
                                // Face Details (Eyes, Nose, Mouth)
                                if postureScore >= 80 {
                                    // Happy / Upright: Eyes open, cheerful smile
                                    Circle()
                                        .fill(Color(red: 0.12, green: 0.16, blue: 0.28))
                                        .frame(width: 4 * scale, height: 4 * scale)
                                        .offset(x: -8 * scale, y: -2 * scale)
                                    
                                    // Nose
                                    Path { p in
                                        p.move(to: CGPoint(x: 16 * scale, y: 22 * scale))
                                        p.addLine(to: CGPoint(x: 12 * scale, y: 25 * scale))
                                        p.addLine(to: CGPoint(x: 16 * scale, y: 26 * scale))
                                    }
                                    .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 2.2 * scale)
                                    
                                    // Smile
                                    Path { p in
                                        p.move(to: CGPoint(x: 14 * scale, y: 31 * scale))
                                        p.addQuadCurve(to: CGPoint(x: 22 * scale, y: 31 * scale), control: CGPoint(x: 18 * scale, y: 36 * scale))
                                    }
                                    .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 2.2 * scale)
                                } else if postureScore >= 60 {
                                    // Warning: Focused / neutral mouth
                                    Circle()
                                        .fill(Color(red: 0.12, green: 0.16, blue: 0.28))
                                        .frame(width: 4 * scale, height: 4 * scale)
                                        .offset(x: -8 * scale, y: 0)
                                    
                                    // Neutral straight mouth
                                    Path { p in
                                        p.move(to: CGPoint(x: 14 * scale, y: 32 * scale))
                                        p.addLine(to: CGPoint(x: 21 * scale, y: 32 * scale))
                                    }
                                    .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 2.2 * scale)
                                } else {
                                    // Slouched: Drooped / closed sleepy curved eyes, frown
                                    Path { p in
                                        p.move(to: CGPoint(x: 12 * scale, y: 21 * scale))
                                        p.addQuadCurve(to: CGPoint(x: 18 * scale, y: 21 * scale), control: CGPoint(x: 15 * scale, y: 18 * scale))
                                    }
                                    .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 2.2 * scale)
                                    
                                    // Drooped mouth
                                    Path { p in
                                        p.move(to: CGPoint(x: 14 * scale, y: 34 * scale))
                                        p.addQuadCurve(to: CGPoint(x: 22 * scale, y: 34 * scale), control: CGPoint(x: 18 * scale, y: 30 * scale))
                                    }
                                    .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 2.2 * scale)
                                }
                                
                                // Ear with AirPods in Ear
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.97, green: 0.88, blue: 0.78))
                                        .frame(width: 14 * scale, height: 16 * scale)
                                        .overlay(
                                            Circle().stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 2.5 * scale)
                                        )
                                    
                                    // AirPods Pro Stem & Earbud
                                    Path { p in
                                        // Earbud capsule
                                        p.addEllipse(in: CGRect(x: 3 * scale, y: 3 * scale, width: 8 * scale, height: 7 * scale))
                                        // Stem pointing down
                                        p.move(to: CGPoint(x: 5 * scale, y: 8 * scale))
                                        p.addLine(to: CGPoint(x: 3 * scale, y: 16 * scale))
                                    }
                                    .fill(Color.white)
                                    .overlay(
                                        Path { p in
                                            p.addEllipse(in: CGRect(x: 3 * scale, y: 3 * scale, width: 8 * scale, height: 7 * scale))
                                            p.move(to: CGPoint(x: 5 * scale, y: 8 * scale))
                                            p.addLine(to: CGPoint(x: 3 * scale, y: 16 * scale))
                                        }
                                        .stroke(Color(red: 0.12, green: 0.16, blue: 0.28), lineWidth: 1.8 * scale)
                                    )
                                }
                                .offset(x: 12 * scale, y: 2 * scale)
                            }
                            .rotationEffect(.degrees(pitch * 0.75 + (postureScore < 60 ? 12.0 : 0.0)))
                            .rotationEffect(.degrees(roll * 0.4))
                            .offset(
                                x: CGFloat(slumpFactor * 16.0 * scale),
                                y: CGFloat(slumpFactor * 12.0 * scale)
                            )
                            
                            Spacer(minLength: 0)
                        }
                        .frame(height: 120 * scale)
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // Top-right Status Pill
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4 * scale) {
                            Circle()
                                .fill(stateTone)
                                .frame(width: 6 * scale, height: 6 * scale)
                            Text("\(postureScore)%")
                                .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                                .foregroundColor(stateTone)
                        }
                        .padding(.horizontal, 6 * scale)
                        .padding(.vertical, 3 * scale)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color(red: 0.12, green: 0.16, blue: 0.28).opacity(0.2), lineWidth: 1)
                        )
                        .padding(8 * scale)
                    }
                    Spacer()
                }
            }
        }
    }
}
