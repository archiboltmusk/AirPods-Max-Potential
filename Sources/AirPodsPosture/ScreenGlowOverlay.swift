import SwiftUI
import AppKit

@MainActor
public final class ScreenGlowManager: ObservableObject {
    public static let shared = ScreenGlowManager()
    
    @Published public var isGlowEnabled: Bool = true
    private var overlayWindow: NSPanel? = nil
    
    private init() {}
    
    public func update(postureState: PostureState) {
        guard isGlowEnabled else {
            hideOverlay()
            return
        }
        
        if postureState == .slouching {
            showOverlay(color: .red)
        } else if postureState == .warning {
            showOverlay(color: .orange)
        } else {
            hideOverlay()
        }
    }
    
    private func showOverlay(color: Color) {
        guard let mainScreen = NSScreen.main else { return }
        
        if overlayWindow == nil {
            let panel = NSPanel(
                contentRect: mainScreen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hasShadow = false
            
            let hosting = NSHostingView(rootView: ScreenGlowView(color: color))
            panel.contentView = hosting
            overlayWindow = panel
        } else {
            if let hosting = overlayWindow?.contentView as? NSHostingView<ScreenGlowView> {
                hosting.rootView = ScreenGlowView(color: color)
            }
        }
        
        overlayWindow?.setFrame(mainScreen.frame, display: true)
        overlayWindow?.orderFrontRegardless()
    }
    
    public func hideOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}

struct ScreenGlowView: View {
    let color: Color
    @State private var pulse: Bool = false
    
    var body: some View {
        Rectangle()
            .strokeBorder(
                LinearGradient(
                    colors: [color.opacity(pulse ? 0.45 : 0.20), color.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 10
            )
            .shadow(color: color.opacity(0.6), radius: 14)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
