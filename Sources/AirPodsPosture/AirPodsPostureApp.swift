import SwiftUI
import AppKit

@main
struct AirPodsPostureApp: App {
    @StateObject private var motion = MotionManager.shared
    @Environment(\.openWindow) private var openWindow

    init() {
        // Ensure standard macOS app activation policy
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup(id: "main-dashboard") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1080, height: 740)

        MenuBarExtra {
            MenuBarView(motion: motion) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main-dashboard")
            }
        } label: {
            HStack(spacing: 3) {
                let tone: LiveSpineMenuBarGlyph.Tone = !motion.isConnected ? .disconnected : (motion.postureState == .slouching ? .alert : .calm)
                let glyphImage = LiveSpineMenuBarGlyph.image(
                    pitchDegrees: motion.deltaPitch,
                    tone: tone,
                    height: 18,
                    label: motion.isConnected ? "\(Int(motion.deltaPitch))°" : nil
                )
                Image(nsImage: glyphImage)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
