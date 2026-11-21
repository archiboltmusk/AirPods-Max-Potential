import SwiftUI
import AppKit

/// HUMAN.md Editorial & Cinematic Design System.
/// Inspired by https://www.human-md.ai — designed for warmth, tactile analog texture,
/// editorial serif typography, and human-first craftsmanship.
public enum HumanCinemaDesignSystem {
    // MARK: - Color Palette
    public struct Palette {
        /// Deep Obsidian Espresso Canvas (#201e1f)
        public static let obsidian = Color(red: 32.0/255.0, green: 30.0/255.0, blue: 31.0/255.0)
        
        /// Human Pulse Vermilion / International Orange (#fc4109)
        public static let vermilion = Color(red: 252.0/255.0, green: 65.0/255.0, blue: 9.0/255.0)
        
        /// Antique Cream Parchment Text (#ece4d8)
        public static let parchment = Color(red: 236.0/255.0, green: 228.0/255.0, blue: 216.0/255.0)
        
        /// Charcoal Surface Card (#282627)
        public static let charcoal = Color(red: 40.0/255.0, green: 38.0/255.0, blue: 39.0/255.0)
        
        /// Warm Ember Amber (#ff9f1c)
        public static let emberAmber = Color(red: 255.0/255.0, green: 159.0/255.0, blue: 28.0/255.0)
        
        /// Muted Filmstrip Sepia (#8c827a)
        public static let mutedSepia = Color(red: 140.0/255.0, green: 130.0/255.0, blue: 122.0/255.0)
    }
}

// MARK: - Human Editorial Card Modifier

public struct HumanFilmCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderGlow: Color
    
    public init(cornerRadius: CGFloat = 14, borderGlow: Color = HumanCinemaDesignSystem.Palette.vermilion.opacity(0.24)) {
        self.cornerRadius = cornerRadius
        self.borderGlow = borderGlow
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Deep warm charcoal base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(HumanCinemaDesignSystem.Palette.charcoal)
                    
                    // Subtle warm gradient sheen
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    HumanCinemaDesignSystem.Palette.vermilion.opacity(0.04),
                                    Color.clear,
                                    HumanCinemaDesignSystem.Palette.emberAmber.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Hairline edge border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    borderGlow,
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02),
                                    borderGlow.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Human Editorial Manifesto Quote Block

public struct HumanBlockquoteModifier: ViewModifier {
    public func body(content: Content) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(HumanCinemaDesignSystem.Palette.vermilion)
                .frame(width: 3)
            
            content
                .font(.system(size: 13, design: .serif).italic())
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.92))
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(HumanCinemaDesignSystem.Palette.charcoal.opacity(0.6))
        .cornerRadius(8)
    }
}

// MARK: - View Extension Shortcuts

public extension View {
    func humanFilmCard(cornerRadius: CGFloat = 14, borderGlow: Color = HumanCinemaDesignSystem.Palette.vermilion.opacity(0.24)) -> some View {
        self.modifier(HumanFilmCardModifier(cornerRadius: cornerRadius, borderGlow: borderGlow))
    }
    
    func humanBlockquote() -> some View {
        self.modifier(HumanBlockquoteModifier())
    }
}
