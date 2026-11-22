import SwiftUI
import AppKit

// MARK: - CRED Design System: Luxury Obsidian Neo-Skeuomorphism
public struct CREDPalette {
    // Canvas & Surface Hierarchy
    public static let canvasBg            = Color(red: 0.028, green: 0.032, blue: 0.040) // #07080A
    public static let cardSurface         = Color(red: 0.060, green: 0.065, blue: 0.080) // #0F1014
    public static let cardElevated        = Color(red: 0.090, green: 0.098, blue: 0.120) // #17191F
    public static let cardHighlight       = Color(red: 0.120, green: 0.130, blue: 0.160) // #1F2129
    public static let insetTrough         = Color(red: 0.020, green: 0.022, blue: 0.028) // #050607
    
    // Specular Bevel Gradients
    public static let specularRimStroke = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.24), location: 0.0),
            .init(color: Color.white.opacity(0.08), location: 0.25),
            .init(color: Color.white.opacity(0.02), location: 0.6),
            .init(color: Color.white.opacity(0.06), location: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let troughRimStroke = LinearGradient(
        stops: [
            .init(color: Color.black.opacity(0.7), location: 0.0),
            .init(color: Color.white.opacity(0.08), location: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Precious Metal & Luminous Accents
    public static let emeraldPlasma       = Color(red: 0.00, green: 0.96, blue: 0.63) // #00F5A0 (Luminary)
    public static let brushedPlatinum     = Color(red: 0.88, green: 0.90, blue: 0.94) // #E0E6F0 (Platinum)
    public static let platinumWhite       = Color(red: 0.92, green: 0.94, blue: 0.97) // #EBF0F8
    public static let champagneGold       = Color(red: 0.86, green: 0.73, blue: 0.32) // #DBBA52 (Titanium/Gold)
    public static let moltenRuby          = Color(red: 1.00, green: 0.24, blue: 0.24) // #FF3D3D (Deficit)
    public static let electricCyan        = Color(red: 0.05, green: 0.78, blue: 1.00) // #0DC7FF
    public static let phantomGray         = Color(red: 0.45, green: 0.48, blue: 0.55) // #737A8C
}

// MARK: - CRED Member Posture Tier
public enum CREDPostureTier: String {
    case obsidianLuminary = "OBSIDIAN LUMINARY"
    case platinumAligned  = "PLATINUM ALIGNED"
    case titaniumBalanced = "TITANIUM BALANCED"
    case cervicalDeficit  = "CERVICAL DEFICIT"
    
    public static func from(score: Int) -> CREDPostureTier {
        if score >= 90 { return .obsidianLuminary }
        if score >= 75 { return .platinumAligned }
        if score >= 55 { return .titaniumBalanced }
        return .cervicalDeficit
    }
    
    public var accentColor: Color {
        switch self {
        case .obsidianLuminary: return CREDPalette.emeraldPlasma
        case .platinumAligned:  return CREDPalette.brushedPlatinum
        case .titaniumBalanced: return CREDPalette.champagneGold
        case .cervicalDeficit:  return CREDPalette.moltenRuby
        }
    }
    
    public var badgeIcon: String {
        switch self {
        case .obsidianLuminary: return "sparkles"
        case .platinumAligned:  return "shield.checkered"
        case .titaniumBalanced: return "hourglass"
        case .cervicalDeficit:  return "exclamationmark.shield.fill"
        }
    }
    
    public var tierNumber: String {
        switch self {
        case .obsidianLuminary: return "TIER I · ELITE PRIVILEGE"
        case .platinumAligned:  return "TIER II · OPTIMAL ALIGNMENT"
        case .titaniumBalanced: return "TIER III · ELEVATED LOAD"
        case .cervicalDeficit:  return "TIER IV · COMPRESSION ALERT"
        }
    }
    
    public var rimGradient: LinearGradient {
        switch self {
        case .obsidianLuminary:
            return LinearGradient(
                colors: [CREDPalette.emeraldPlasma.opacity(0.8), CREDPalette.electricCyan.opacity(0.4), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .platinumAligned:
            return LinearGradient(
                colors: [CREDPalette.brushedPlatinum.opacity(0.7), Color.white.opacity(0.3), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .titaniumBalanced:
            return LinearGradient(
                colors: [CREDPalette.champagneGold.opacity(0.8), Color.orange.opacity(0.3), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cervicalDeficit:
            return LinearGradient(
                colors: [CREDPalette.moltenRuby.opacity(0.9), Color.red.opacity(0.4), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - CRED Obsidian Card Modifier
public struct CREDCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var elevation: CGFloat = 12
    var glowColor: Color = Color.clear

    public func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [CREDPalette.cardElevated, CREDPalette.cardSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(CREDPalette.specularRimStroke, lineWidth: 1.0)
            )
            .shadow(color: Color.black.opacity(0.85), radius: elevation, x: 0, y: elevation * 0.6)
            .shadow(color: glowColor.opacity(0.2), radius: 14, x: 0, y: 0)
    }
}

// MARK: - CRED Inset Sunken Trough Modifier (for Gauges & Readings)
public struct CREDInsetTroughModifier: ViewModifier {
    var cornerRadius: CGFloat = 14

    public func body(content: Content) -> some View {
        content
            .background(CREDPalette.insetTrough)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(CREDPalette.troughRimStroke, lineWidth: 1.0)
            )
            .shadow(color: Color.black.opacity(0.9), radius: 4, x: 0, y: 2)
    }
}

public extension View {
    func credCard(cornerRadius: CGFloat = 20, elevation: CGFloat = 12, glowColor: Color = .clear) -> some View {
        self.modifier(CREDCardModifier(cornerRadius: cornerRadius, elevation: elevation, glowColor: glowColor))
    }
    
    func credInsetTrough(cornerRadius: CGFloat = 14) -> some View {
        self.modifier(CREDInsetTroughModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - CRED Tactile Pressable Button with macOS Haptics
public struct CREDTactileButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    @State private var isPressed = false
    
    public init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    public var body: some View {
        Button(action: {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            action()
        }) {
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if isPressed {
                            CREDPalette.insetTrough
                        } else {
                            LinearGradient(
                                colors: [CREDPalette.cardElevated, CREDPalette.cardSurface],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: isPressed
                                    ? [Color.black.opacity(0.6), Color.white.opacity(0.08)]
                                    : [Color.white.opacity(0.25), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - CRED EMV Microchip View (Laser-Etched Gold Hologram)
public struct CREDEMVChipView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Gold Chip Plate
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.78, blue: 0.40),
                            Color(red: 0.72, green: 0.58, blue: 0.24),
                            Color(red: 0.88, green: 0.75, blue: 0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                )
            
            // Internal Etched Circuit Traces
            Path { path in
                path.move(to: CGPoint(x: 0, y: 12))
                path.addLine(to: CGPoint(x: 32, y: 12))
                path.move(to: CGPoint(x: 12, y: 0))
                path.addLine(to: CGPoint(x: 12, y: 24))
                path.move(to: CGPoint(x: 20, y: 0))
                path.addLine(to: CGPoint(x: 20, y: 24))
            }
            .stroke(Color.black.opacity(0.35), lineWidth: 0.8)
            .frame(width: 32, height: 24)
        }
    }
}

// MARK: - CRED Shimmering Metallic Sheen Sweep (Zero-CPU Static Specular Sheen)
public struct CREDSheenSweepView: View {
    public init() {}
    
    public var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .white.opacity(0.03), location: 0.35),
                        .init(color: .white.opacity(0.08), location: 0.40),
                        .init(color: .white.opacity(0.02), location: 0.45),
                        .init(color: .clear, location: 0.70)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .allowsHitTesting(false)
            .clipped()
    }
}
