import SwiftUI
import AppKit

@MainActor
public final class FloatingMiniDeskCompanionManager: ObservableObject {
    public static let shared = FloatingMiniDeskCompanionManager()
    
    public enum AvatarStyle: String, CaseIterable {
        case hergeCompanion = "Ligne Claire Avatar"
        case human3DFace = "3D Cyber Mesh"
    }
    
    @Published public var isCompanionVisible: Bool = false
    @Published public var avatarStyle: AvatarStyle = .hergeCompanion
    
    private var companionPanel: NSPanel?
    
    private init() {}
    
    public func toggleAvatarStyle() {
        avatarStyle = (avatarStyle == .hergeCompanion) ? .human3DFace : .hergeCompanion
    }
    
    public func toggleCompanion() {
        if isCompanionVisible {
            companionPanel?.orderOut(nil)
            isCompanionVisible = false
        } else {
            showCompanion()
        }
    }
    
    public func showCompanion() {
        if companionPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 160, height: 160),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.isMovableByWindowBackground = true
            
            let contentView = MiniCompanionContentView()
            panel.contentView = NSHostingView(rootView: contentView)
            self.companionPanel = panel
        }
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            // Default position: Bottom-right corner above dock
            let x = screenRect.maxX - 190
            let y = screenRect.minY + 30
            companionPanel?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        companionPanel?.makeKeyAndOrderFront(nil)
        isCompanionVisible = true
        MotionManager.shared.playFeedbackSound("Hero")
    }
}

public struct MiniCompanionContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var companion = FloatingMiniDeskCompanionManager.shared
    
    @AppStorage("postureFaceEarwear") private var earwearStyle: EarwearStyle = .airPodsPro

    private var rimColor: Color {
        if motion.postureScore >= 80 {
            return .cyan
        } else if motion.postureScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    public var body: some View {
        ZStack {
            if companion.avatarStyle == .hergeCompanion {
                HergePostureAvatarView(
                    pitch: motion.deltaPitch,
                    roll: motion.deltaRoll,
                    postureScore: motion.postureScore,
                    isCompact: true
                )
                .frame(width: 140, height: 140)
            } else {
                // Glassmorphic Orb
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(rimColor.opacity(0.8), lineWidth: 2)
                            .shadow(color: rimColor.opacity(0.6), radius: 8)
                    )
                
                // Miniature 3D Human Face responding to live AirPods
                HumanFace3DView(
                    pitch: motion.deltaPitch,
                    roll: motion.deltaRoll,
                    yaw: motion.deltaYaw,
                    postureScore: motion.postureScore,
                    earwearStyle: earwearStyle
                )
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .accessibilityHidden(true)
                
                // Bottom Score Badge
                VStack {
                    Spacer()
                    Text("\(motion.postureScore)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(rimColor)
                        .clipShape(Capsule())
                        .padding(.bottom, 6)
                }
            }
        }
        .frame(width: 150, height: 150)
        .onTapGesture(count: 2) {
            motion.calibrateCurrentPosture()
        }
        .onTapGesture(count: 1) {
            companion.toggleAvatarStyle()
        }
    }
}
