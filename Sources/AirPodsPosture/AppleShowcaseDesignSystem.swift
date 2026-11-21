import SwiftUI
import AppKit

// MARK: - Apple Glassmorphism & Specular Sheen Modifiers

public struct AppleGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var borderColor: Color
    
    public init(cornerRadius: CGFloat = 16, opacity: Double = 0.55, borderColor: Color = Color.white.opacity(0.18)) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.borderColor = borderColor
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(opacity)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.32),
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02),
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.65
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Spatial Perspective Card Tilt (Reacts to AirPods Head Angle)

public struct SpatialHeadParallaxModifier: ViewModifier {
    @ObservedObject var motion = MotionManager.shared
    var sensitivity: Double
    
    public init(sensitivity: Double = 0.08) {
        self.sensitivity = sensitivity
    }
    
    public func body(content: Content) -> some View {
        let pitchTilt = max(-6.0, min(6.0, -motion.deltaPitch * sensitivity))
        let rollTilt = max(-6.0, min(6.0, motion.deltaRoll * sensitivity))
        
        content
            .rotation3DEffect(
                .degrees(pitchTilt),
                axis: (x: 1.0, y: 0.0, z: 0.0),
                perspective: 0.8
            )
            .rotation3DEffect(
                .degrees(rollTilt),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                perspective: 0.8
            )
            .animation(.interpolatingSpring(stiffness: 140, damping: 18), value: motion.deltaPitch)
            .animation(.interpolatingSpring(stiffness: 140, damping: 18), value: motion.deltaRoll)
    }
}

// MARK: - View Extensions

public extension View {
    func appleGlass(cornerRadius: CGFloat = 16, opacity: Double = 0.6) -> some View {
        self.modifier(AppleGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
    
    func spatialHeadParallax(sensitivity: Double = 0.06) -> some View {
        self.modifier(SpatialHeadParallaxModifier(sensitivity: sensitivity))
    }
}

// MARK: - Apple Floating Pill Navigation Dock

public struct AppleFloatingPillDock<T: Hashable & Identifiable>: View {
    public let items: [T]
    @Binding public var selection: T
    public let titleKeyPath: KeyPath<T, String>
    public let iconKeyPath: KeyPath<T, String>
    
    @Namespace private var animationNamespace
    
    public init(
        items: [T],
        selection: Binding<T>,
        titleKeyPath: KeyPath<T, String>,
        iconKeyPath: KeyPath<T, String>
    ) {
        self.items = items
        self._selection = selection
        self.titleKeyPath = titleKeyPath
        self.iconKeyPath = iconKeyPath
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                let isSelected = item.id == selection.id
                Button(action: {
                    withAnimation(.interpolatingSpring(stiffness: 280, damping: 24)) {
                        selection = item
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: item[keyPath: iconKeyPath])
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        Text(item[keyPath: titleKeyPath])
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundColor(isSelected ? .white : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.accentColor.opacity(0.85),
                                                Color.accentColor.opacity(0.65)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .matchedGeometryEffect(id: "activePillTab", in: animationNamespace)
                                    .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 2)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            ZStack {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.88)
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}
