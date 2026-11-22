import SwiftUI
import AppKit

/// Pixel-Perfect Hergé Ligne Claire Posture Companion.
/// Renders the official, user-approved high-resolution Ligne Claire illustration with live kinematics.
/// Reacts dynamically to your AirPods' real-time head pitch and roll with smooth physical motion.
public struct HergePostureAvatarView: View {
    let pitch: Double
    let roll: Double
    let postureScore: Int
    let isCompact: Bool
    
    public init(pitch: Double, roll: Double, postureScore: Int, isCompact: Bool = false) {
        self.pitch = pitch
        self.roll = roll
        self.postureScore = postureScore
        self.isCompact = isCompact
    }
    
    private var statusColor: Color {
        if postureScore >= 80 {
            return .green
        } else if postureScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var postureDescription: String {
        if postureScore >= 80 {
            return "Optimal Alignment"
        } else if postureScore >= 60 {
            return "Slight Neck Flexion"
        } else {
            return "Slouching (\(Int(abs(pitch)))° Down)"
        }
    }
    
    /// Loads the crisp 1024x1024 Hergé artwork from bundle resources or local fallback
    private var avatarImage: NSImage? {
        if let bundleURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: bundleURL) {
            return img
        }
        let fallbackPath = "/Users/anupam/.gemini/antigravity/scratch/AirPodsMaxPotential/Sources/AirPodsPosture/Resources/AppIcon.png"
        if FileManager.default.fileExists(atPath: fallbackPath),
           let img = NSImage(contentsOfFile: fallbackPath) {
            return img
        }
        return nil
    }
    
    public var body: some View {
        let cardSize: CGFloat = isCompact ? 130 : 220
        
        ZStack {
            // Background Card: Apple Warm Paper with dynamic posture glow
            RoundedRectangle(cornerRadius: isCompact ? 22 : 28, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.93))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 22 : 28, style: .continuous)
                        .stroke(
                            statusColor.opacity(postureScore >= 80 ? 0.4 : 0.7),
                            lineWidth: isCompact ? 2.5 : 3.0
                        )
                )
                .shadow(
                    color: statusColor.opacity(postureScore < 60 ? 0.35 : 0.15),
                    radius: isCompact ? 8 : 14,
                    x: 0,
                    y: 4
                )
            
            // The Official High-Res Hergé Illustration with real-time head nod
            if let img = avatarImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cardSize * 0.92, height: cardSize * 0.92)
                    .clipShape(RoundedRectangle(cornerRadius: isCompact ? 18 : 22, style: .continuous))
                    // Lifelike physical pitch nod (subtle rotation anchored near neck)
                    .rotationEffect(.degrees(pitch * 0.35), anchor: .bottomLeading)
                    .rotationEffect(.degrees(roll * 0.2))
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: pitch)
            } else {
                // Fallback icon if image is loading
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: isCompact ? 32 : 54))
                        .foregroundColor(statusColor)
                    Text("\(postureScore)%")
                        .font(.headline)
                        .foregroundColor(statusColor)
                }
            }
            
            // Top Status Badge Pill
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: isCompact ? 5 : 7, height: isCompact ? 5 : 7)
                        Text("\(postureScore)%")
                            .font(.system(size: isCompact ? 10 : 12, weight: .bold, design: .rounded))
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, isCompact ? 6 : 8)
                    .padding(.vertical, isCompact ? 3 : 4)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                    .padding(isCompact ? 8 : 12)
                }
                Spacer()
            }
            
            // Bottom Description Banner (Full-size card only)
            if !isCompact {
                VStack {
                    Spacer()
                    HStack {
                        Text(postureDescription)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.88))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        Spacer()
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: cardSize, height: cardSize)
    }
}
