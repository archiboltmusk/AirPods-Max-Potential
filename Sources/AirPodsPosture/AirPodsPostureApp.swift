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
        .defaultSize(width: 840, height: 620)

        MenuBarExtra {
            MenuBarView(motion: motion) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main-dashboard")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: motion.postureState.systemImage)
                if motion.isConnected && motion.postureState == .slouching {
                    Text("Slouch!")
                        .font(.caption2.bold())
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
